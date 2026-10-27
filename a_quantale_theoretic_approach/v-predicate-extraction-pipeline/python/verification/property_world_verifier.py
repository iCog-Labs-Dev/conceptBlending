#!/usr/bin/env python3
"""Final LLM repair, verification, and persistence for properties and worlds."""

from __future__ import annotations

import hashlib
import json
import os
import re
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Protocol

from pipeline_event_logger import fail_pipeline, log_pipeline_event


PROMPT_VERSION = "property-world-final-verifier-v2"
DEFAULT_MODEL = os.environ.get(
    "PROPERTY_WORLD_VERIFIER_MODEL",
    os.environ.get("OPENAI_MODEL", "gpt-5.4"),
)
SCRIPT_DIR = Path(__file__).resolve().parent
PIPELINE_ROOT = SCRIPT_DIR.parents[1]
DEFAULT_AUDIT_PATH = (
    PIPELINE_ROOT / "kb" / "runtime" / "verified"
    / "PropertyWorldVerified.jsonl"
)
DEFAULT_METTA_STORE_PATH = (
    PIPELINE_ROOT / "kb" / "runtime" / "verified"
    / "PropertyWorldVerifiedKB.metta"
)
DEFAULT_KB_PATH = PIPELINE_ROOT / "kb" / "generated" / "PropertyWorldKB.metta"
SYMBOL_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
TOKEN_RE = re.compile(r"\(|\)|[^\s()]+")
KB_HASH_CHUNK_SIZE = 1024 * 1024
_KB_FINGERPRINT_CACHE: dict[Path, tuple[tuple[int, ...], str]] = {}

PERSPECTIVE_CONTEXTS = {
    "descriptive_property": "observable, attributed, or dispositional qualities",
    "physical_attribute": "physical form, material, dimensions, and condition",
    "functional_use": "capabilities, uses, goals, transformations, and outcomes",
    "behavioral_process": "actions, responses, processes, and state transitions",
    "causal_prerequisite": "causes, enabling conditions, prerequisites, and effects",
    "spatial_context": "location, containment, adjacency, and movement",
    "temporal_context": "ordering, duration, recurrence, and change over time",
    "quantitative_comparative": "measurements, quantities, comparisons, and bounds",
    "social_normative": "roles, norms, permissions, obligations, and evaluations",
    "economic_ownership": "ownership, value, cost, transfer, and exchange",
    "information_computational": "information, programs, computation, inputs, and outputs",
    "safety_risk": "hazards, vulnerabilities, protection, and failure outcomes",
    "state_lifecycle": "creation, activation, persistence, transitions, and termination",
    "structural_composition": "parts, materials, interfaces, assembly, and wholes",
    "taxonomic_kind": "kinds, supertypes, subtypes, and distinguishing features",
    "taxonomic_classification": "classification evidence, categories, and membership",
    "artifact_kind": "designed artifact classes, purposes, and identifying structure",
    "role_kind": "roles, bearers, contexts, eligibility, and assignment",
    "prerequisite_action": "actions and the preconditions required for occurrence",
    "event_composition": "events, subevents, participants, sequencing, and outcomes",
}


class PropertyWorldVerificationError(RuntimeError):
    pass


class VerificationProvider(Protocol):
    @property
    def model_id(self) -> str: ...

    def verify(
        self,
        instructions: str,
        candidate: str,
        schema_name: str,
        schema: dict[str, Any],
    ) -> dict[str, Any]: ...


@dataclass(frozen=True)
class VerificationConfig:
    mode: str = "auto"
    model: str = DEFAULT_MODEL
    api_key_env: str = "OPENAI_API_KEY"
    base_url: str | None = None
    timeout: float = 90.0
    max_output_tokens: int = 3000
    max_attempts: int = 2
    failure_policy: str = "fallback"
    audit_path: Path = DEFAULT_AUDIT_PATH
    metta_store_path: Path = DEFAULT_METTA_STORE_PATH
    kb_path: Path = DEFAULT_KB_PATH

    def __post_init__(self) -> None:
        if self.mode not in {"off", "auto", "verify"}:
            raise ValueError("mode must be off, auto, or verify")
        if self.max_attempts < 1:
            raise ValueError("max_attempts must be at least one")
        if self.failure_policy not in {"fallback", "error"}:
            raise ValueError("failure_policy must be fallback or error")


class OpenAIVerificationProvider:
    def __init__(
        self,
        api_key: str,
        model: str = DEFAULT_MODEL,
        base_url: str | None = None,
        timeout: float = 90.0,
        max_output_tokens: int = 3000,
        trace: bool = False,
    ) -> None:
        if not api_key:
            raise PropertyWorldVerificationError("OPENAI_API_KEY is required")
        try:
            from openai import OpenAI
        except ImportError:
            # PeTTa embeds system Python, so activating this repository's venv
            # does not necessarily put its site-packages on Janus' sys.path.
            # Prefer an explicit override, then discover the local venv.
            search_paths: list[Path] = []
            configured = os.environ.get("PROPERTY_WORLD_OPENAI_SITE_PACKAGES")
            if configured:
                search_paths.append(Path(configured))
            search_paths.extend(
                sorted((PIPELINE_ROOT / "venv" / "lib").glob("python*/site-packages"))
                + sorted(
                    (PIPELINE_ROOT.parent / "venv" / "lib").glob(
                        "python*/site-packages"
                    )
                )
            )
            for candidate in search_paths:
                if candidate.is_dir() and str(candidate) not in sys.path:
                    sys.path.insert(0, str(candidate))
            try:
                from openai import OpenAI
            except ImportError as exc:
                raise PropertyWorldVerificationError(
                    "The official openai package is required; install it in the "
                    "runtime environment or set PROPERTY_WORLD_OPENAI_SITE_PACKAGES"
                ) from exc
        kwargs: dict[str, Any] = {"api_key": api_key, "timeout": timeout}
        if base_url:
            kwargs["base_url"] = base_url
        self._client = OpenAI(**kwargs)
        self._model = model
        self._max_output_tokens = max_output_tokens
        self._trace = trace

    @property
    def model_id(self) -> str:
        return self._model

    def verify(
        self,
        instructions: str,
        candidate: str,
        schema_name: str,
        schema: dict[str, Any],
    ) -> dict[str, Any]:
        if self._trace:
            print(
                "PROPERTY_WORLD_VERIFIER request="
                + json.dumps(
                    {
                        "model": self._model,
                        "instructions": instructions,
                        "input": candidate,
                    },
                    sort_keys=True,
                ),
                file=sys.stderr,
            )
        response = self._client.responses.create(
            model=self._model,
            instructions=instructions,
            input=candidate,
            max_output_tokens=self._max_output_tokens,
            text={
                "format": {
                    "type": "json_schema",
                    "name": schema_name,
                    "strict": True,
                    "schema": schema,
                }
            },
        )
        if self._trace:
            print(
                f"PROPERTY_WORLD_VERIFIER response={response.output_text}",
                file=sys.stderr,
            )
        try:
            value = json.loads(response.output_text)
        except (TypeError, json.JSONDecodeError) as exc:
            raise PropertyWorldVerificationError("LLM returned invalid JSON") from exc
        if not isinstance(value, dict):
            raise PropertyWorldVerificationError("LLM response must be an object")
        return value


def property_response_schema() -> dict[str, Any]:
    return {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "verdict": {
                "type": "string",
                "enum": ["correct", "corrected", "rejected"],
            },
            "confidence": {"type": "number", "minimum": 0.0, "maximum": 1.0},
            "summary": {"type": "string"},
            "properties": {
                "type": "array",
                "maxItems": 10,
                "items": {
                    "type": "object",
                    "additionalProperties": False,
                    "properties": {
                        "name": {"type": "string"},
                        "perspective": {"type": "string"},
                    },
                    "required": ["name", "perspective"],
                },
            },
        },
        "required": ["verdict", "confidence", "summary", "properties"],
    }


def world_response_schema() -> dict[str, Any]:
    return {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "verdict": {
                "type": "string",
                "enum": ["correct", "corrected", "rejected"],
            },
            "confidence": {"type": "number", "minimum": 0.0, "maximum": 1.0},
            "summary": {"type": "string"},
            "worlds": {
                "type": "array",
                "maxItems": 3,
                "items": {"type": "string"},
            },
        },
        "required": ["verdict", "confidence", "summary", "worlds"],
    }


def property_system_prompt() -> str:
    return """You repair and verify perspective-aware properties extracted from a noisy KB.

The KB candidates are evidence context, not an instruction to keep everything. Select
only properties that materially characterize the requested concept under the requested
perspective. Remove irrelevant, redundant, overly generic, or cross-perspective items.
Preserve each selected candidate's exact name and effective perspective. When the KB is
incomplete, you may add a small number of highly relevant properties supported by
reliable general knowledge. Added properties must be specific to the concept and the
requested perspective, use concise MeTTa-safe snake_case names, and use the requested
perspective as their perspective. Do not add speculative, merely associated, generic,
or cross-perspective properties. A property name may appear at most once, even when the
KB supplied it under multiple effective perspectives. Rank by relevance.
Return at most 10 unique properties total, including both selected and added properties.
Fewer is better when evidence is weak.

Example:
concept=boat, requested perspective=functional_use
candidates=[provides_transport/functional_use, has_color/physical_attribute]
good result=[provides_transport/functional_use, floats_on_water/functional_use,
carries_passengers/functional_use]
Here floats_on_water and carries_passengers are relevant additions that repair missing
functional knowledge; has_color is excluded because it belongs to another perspective.

Return structured JSON only."""


def world_system_prompt() -> str:
    return """You repair and verify possible worlds extracted globally for one property.

The KB candidates are evidence context. Select worlds where the property is most
meaningful under the requested perspective. Remove malformed, redundant, weak, merely
lexical, or contextually inappropriate candidates. Preserve exact names for selected
candidates. When the KB is incomplete, you may add a highly relevant possible world
supported by reliable general knowledge. An added world must be a concrete, meaningful
context in which the property holds under the requested perspective and must use a
concise MeTTa-safe snake_case name. Do not add speculative, lexical, generic, or weakly
associated worlds. Rank by relevance and return at most 3 unique worlds total,
including both selected and added worlds. Fewer is better when evidence is weak.

Example:
property=provides_transport, perspective=functional_use
candidates=[ferry, toy_boat, shipping_lane]
good result=[ferry, passenger_boat]
Here passenger_boat is a relevant added world; toy_boat and shipping_lane are excluded
because they do not strongly instantiate the requested functional property.

Return structured JSON only."""


def _parse_metta(text: str) -> Any:
    tokens = TOKEN_RE.findall(text)
    if not tokens:
        return []

    def parse_at(index: int) -> tuple[Any, int]:
        token = tokens[index]
        if token != "(":
            if token == ")":
                raise PropertyWorldVerificationError("unexpected closing parenthesis")
            return token, index + 1
        result: list[Any] = []
        index += 1
        while index < len(tokens) and tokens[index] != ")":
            item, index = parse_at(index)
            result.append(item)
        if index >= len(tokens):
            raise PropertyWorldVerificationError("unclosed MeTTa expression")
        return result, index + 1

    parsed, end = parse_at(0)
    if end != len(tokens):
        raise PropertyWorldVerificationError("trailing MeTTa expressions")
    return parsed


def _coerce_nested(value: Any) -> Any:
    if isinstance(value, (list, tuple)):
        return [_coerce_nested(item) for item in value]
    return str(value)


def _coerce_candidate(value: Any) -> Any:
    if isinstance(value, (list, tuple)):
        return _coerce_nested(value)
    text = str(value).strip()
    return _parse_metta(text)


def parse_property_candidates(value: Any) -> list[tuple[str, str]]:
    parsed = _coerce_candidate(value)
    if not isinstance(parsed, list):
        raise PropertyWorldVerificationError("property candidate must be a list")
    result: list[tuple[str, str]] = []
    seen: set[tuple[str, str]] = set()
    for item in parsed:
        if not (
            isinstance(item, list)
            and len(item) == 2
            and all(isinstance(part, str) and SYMBOL_RE.fullmatch(part) for part in item)
        ):
            continue
        pair = (item[0], item[1])
        if pair not in seen:
            seen.add(pair)
            result.append(pair)
    return result


def parse_world_candidates(value: Any) -> list[str]:
    parsed = _coerce_candidate(value)
    if not isinstance(parsed, list):
        raise PropertyWorldVerificationError("world candidate must be a list")
    result: list[str] = []
    seen: set[str] = set()
    for item in parsed:
        if isinstance(item, str) and SYMBOL_RE.fullmatch(item) and item not in seen:
            seen.add(item)
            result.append(item)
    return result


def render_properties(items: list[tuple[str, str]]) -> str:
    return "(" + " ".join(f"({name} {perspective})" for name, perspective in items) + ")"


def render_worlds(items: list[str]) -> str:
    return "(" + " ".join(items) + ")"


def _kb_fingerprint(path: Path) -> str:
    try:
        resolved = path.resolve(strict=True)
        stat = resolved.stat()
    except OSError:
        return "missing"

    identity = (
        stat.st_dev,
        stat.st_ino,
        stat.st_size,
        stat.st_mtime_ns,
        stat.st_ctime_ns,
    )
    cached = _KB_FINGERPRINT_CACHE.get(resolved)
    if cached is not None and cached[0] == identity:
        return cached[1]

    digest = hashlib.sha256()
    try:
        with resolved.open("rb") as handle:
            for chunk in iter(lambda: handle.read(KB_HASH_CHUNK_SIZE), b""):
                digest.update(chunk)
    except OSError:
        return "missing"

    fingerprint = f"sha256:{digest.hexdigest()}"
    _KB_FINGERPRINT_CACHE[resolved] = (identity, fingerprint)
    return fingerprint


def _verification_key(
    kind: str,
    subject: str,
    perspective: str,
    candidates: Any,
    model: str,
    kb_fingerprint: str,
) -> str:
    payload = json.dumps(
        {
            "prompt_version": PROMPT_VERSION,
            "kind": kind,
            "subject": subject,
            "perspective": perspective,
            "candidates": candidates,
            "model": model,
            "kb_fingerprint": kb_fingerprint,
        },
        sort_keys=True,
        separators=(",", ":"),
    ).encode()
    return hashlib.sha256(payload).hexdigest()


def _cached_record(path: Path, key: str) -> dict[str, Any] | None:
    if not path.exists():
        return None
    found: dict[str, Any] | None = None
    with path.open(encoding="utf-8", errors="replace") as handle:
        for line in handle:
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            if (
                row.get("key") == key
                and row.get("record_type") == "final"
                and row.get("verdict") in {"correct", "corrected"}
            ):
                found = row
    return found


def _locked_append(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        try:
            import fcntl

            fcntl.flock(handle.fileno(), fcntl.LOCK_EX)
            handle.write(text)
            handle.flush()
            fcntl.flock(handle.fileno(), fcntl.LOCK_UN)
        except ImportError:
            handle.write(text)


def _append_jsonl(path: Path, row: dict[str, Any]) -> None:
    _locked_append(path, json.dumps(row, sort_keys=True) + "\n")


def _safe_atom(value: str) -> str:
    return value if SYMBOL_RE.fullmatch(value) else "invalid_atom"


def _append_metta(path: Path, row: dict[str, Any]) -> None:
    record_id = f"property_world_verification_{row['key'][:20]}"
    if row["kind"] == "concept_properties":
        payload = render_properties(
            [(item["name"], item["perspective"]) for item in row["result"]]
        )
        statement = (
            f"(llm_verified_concept_properties {record_id} "
            f"{_safe_atom(row['subject'])} {_safe_atom(row['perspective'])} "
            f"{row['verdict']} {row['confidence']:.6f} {payload})"
        )
    else:
        payload = render_worlds([str(item) for item in row["result"]])
        statement = (
            f"(llm_verified_property_worlds {record_id} "
            f"{_safe_atom(row['subject'])} {_safe_atom(row['perspective'])} "
            f"{row['verdict']} {row['confidence']:.6f} {payload})"
        )
    _locked_append(path, f"(: {record_id} {statement})\n")


def _validate_properties(
    raw: dict[str, Any],
    candidates: list[tuple[str, str]],
    requested_perspective: str,
) -> tuple[str, float, str, list[tuple[str, str]]]:
    verdict = str(raw.get("verdict", "rejected"))
    if verdict not in {"correct", "corrected"}:
        raise PropertyWorldVerificationError("LLM rejected the property candidates")
    confidence = float(raw.get("confidence", 0.0))
    if not 0.0 <= confidence <= 1.0:
        raise PropertyWorldVerificationError("confidence is outside [0,1]")
    items = raw.get("properties")
    if not isinstance(items, list) or len(items) > 10:
        raise PropertyWorldVerificationError("properties must contain at most 10 items")
    allowed = set(candidates)
    result: list[tuple[str, str]] = []
    seen: set[tuple[str, str]] = set()
    seen_names: set[str] = set()
    for item in items:
        if not isinstance(item, dict):
            raise PropertyWorldVerificationError("property item must be an object")
        pair = (str(item.get("name", "")), str(item.get("perspective", "")))
        if not SYMBOL_RE.fullmatch(pair[0]):
            raise PropertyWorldVerificationError(
                f"property name {pair[0]!r} is not a MeTTa-safe symbol"
            )
        if not SYMBOL_RE.fullmatch(pair[1]):
            raise PropertyWorldVerificationError(
                f"property perspective {pair[1]!r} is not a MeTTa-safe symbol"
            )
        if pair not in allowed and pair[1] != requested_perspective:
            raise PropertyWorldVerificationError(
                f"added property {pair!r} must use requested perspective "
                f"{requested_perspective!r}"
            )
        if pair in seen:
            raise PropertyWorldVerificationError(f"duplicate property {pair!r}")
        if pair[0] in seen_names:
            raise PropertyWorldVerificationError(
                f"duplicate property name {pair[0]!r}"
            )
        seen.add(pair)
        seen_names.add(pair[0])
        result.append(pair)
    return verdict, confidence, str(raw.get("summary", "")), result


def _validate_worlds(
    raw: dict[str, Any],
    candidates: list[str],
) -> tuple[str, float, str, list[str]]:
    verdict = str(raw.get("verdict", "rejected"))
    if verdict not in {"correct", "corrected"}:
        raise PropertyWorldVerificationError("LLM rejected the world candidates")
    confidence = float(raw.get("confidence", 0.0))
    if not 0.0 <= confidence <= 1.0:
        raise PropertyWorldVerificationError("confidence is outside [0,1]")
    items = raw.get("worlds")
    if not isinstance(items, list) or len(items) > 3:
        raise PropertyWorldVerificationError("worlds must contain at most 3 items")
    result: list[str] = []
    seen: set[str] = set()
    for item in items:
        world = str(item)
        if not SYMBOL_RE.fullmatch(world):
            raise PropertyWorldVerificationError(
                f"world {world!r} is not a MeTTa-safe symbol"
            )
        if world in seen:
            raise PropertyWorldVerificationError(f"duplicate world {world!r}")
        seen.add(world)
        result.append(world)
    return verdict, confidence, str(raw.get("summary", "")), result


def _candidate_prompt(
    kind: str,
    subject: str,
    perspective: str,
    candidates: Any,
    errors: list[str] | None = None,
) -> str:
    payload = {
        "task": kind,
        "subject": subject,
        "requested_perspective": perspective,
        "perspective_semantics": PERSPECTIVE_CONTEXTS.get(
            perspective, "the explicitly requested viewpoint"
        ),
        "kb_candidates": candidates,
    }
    if errors:
        payload["previous_validation_errors"] = errors
        payload["instruction"] = "Repair the previous response and obey every constraint."
    return json.dumps(payload, sort_keys=True)


def _verify(
    *,
    kind: str,
    subject: str,
    perspective: str,
    candidates: Any,
    provider: VerificationProvider,
    config: VerificationConfig,
) -> Any:
    fingerprint = _kb_fingerprint(config.kb_path)
    key = _verification_key(
        kind, subject, perspective, candidates, provider.model_id, fingerprint
    )
    cached = _cached_record(config.audit_path, key)
    if cached is not None:
        log_pipeline_event(
            "success",
            f"{kind}_cache_hit",
            subject,
            perspective,
            {"result_count": len(cached.get("result", []))},
        )
        return cached["result"]

    if kind == "concept_properties":
        instructions = property_system_prompt()
        schema = property_response_schema()
        schema_name = "verified_concept_properties"
        validate = lambda raw: _validate_properties(
            raw, candidates, perspective
        )
    else:
        instructions = world_system_prompt()
        schema = world_response_schema()
        schema_name = "verified_property_worlds"
        validate = lambda raw: _validate_worlds(raw, candidates)

    errors: list[str] = []
    for attempt in range(1, config.max_attempts + 1):
        raw: dict[str, Any] = {}
        try:
            raw = provider.verify(
                instructions,
                _candidate_prompt(kind, subject, perspective, candidates, errors),
                schema_name,
                schema,
            )
            verdict, confidence, summary, result = validate(raw)
            row = {
                "record_type": "final",
                "key": key,
                "prompt_version": PROMPT_VERSION,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "kind": kind,
                "model": provider.model_id,
                "kb_fingerprint": fingerprint,
                "subject": subject,
                "perspective": perspective,
                "verdict": verdict,
                "confidence": confidence,
                "summary": summary,
                "candidates": candidates,
                "result": (
                    [{"name": name, "perspective": item_perspective}
                     for name, item_perspective in result]
                    if kind == "concept_properties"
                    else result
                ),
            }
            _append_jsonl(config.audit_path, row)
            _append_metta(config.metta_store_path, row)
            log_pipeline_event(
                "success",
                f"{kind}_llm_verified",
                subject,
                perspective,
                {
                    "attempt": attempt,
                    "verdict": verdict,
                    "result_count": len(row["result"]),
                },
            )
            return row["result"]
        except Exception as exc:
            errors = [f"{type(exc).__name__}: {exc}"]
            log_pipeline_event(
                "error",
                f"{kind}_verification_attempt",
                subject,
                perspective,
                {"attempt": attempt, "errors": errors},
            )
            _append_jsonl(
                config.audit_path,
                {
                    "record_type": "attempt",
                    "key": key,
                    "prompt_version": PROMPT_VERSION,
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "kind": kind,
                    "model": provider.model_id,
                    "subject": subject,
                    "perspective": perspective,
                    "attempt": attempt,
                    "validation_errors": errors,
                    "raw_response": raw,
                },
            )

    log_pipeline_event(
        "error",
        f"{kind}_verification_failed",
        subject,
        perspective,
        {"attempts": config.max_attempts, "errors": errors},
    )
    if config.failure_policy == "error":
        raise PropertyWorldVerificationError(
            "verification failed after retries: " + "; ".join(errors)
        )
    fallback = (
        [{"name": name, "perspective": item_perspective}
         for name, item_perspective in candidates[:10]]
        if kind == "concept_properties"
        else candidates[:3]
    )
    log_pipeline_event(
        "success",
        f"{kind}_fallback_used",
        subject,
        perspective,
        {"result_count": len(fallback)},
    )
    return fallback


def verify_properties_with_provider(
    concept: str,
    perspective: str,
    candidate_value: Any,
    provider: VerificationProvider,
    config: VerificationConfig,
) -> str:
    candidates = parse_property_candidates(candidate_value)
    result = _verify(
        kind="concept_properties",
        subject=str(concept),
        perspective=str(perspective),
        candidates=candidates,
        provider=provider,
        config=config,
    )
    pairs = [(str(item["name"]), str(item["perspective"])) for item in result]
    return render_properties(pairs[:10])


def verify_worlds_with_provider(
    property_name: str,
    perspective: str,
    candidate_value: Any,
    provider: VerificationProvider,
    config: VerificationConfig,
) -> str:
    candidates = parse_world_candidates(candidate_value)
    result = _verify(
        kind="property_worlds",
        subject=str(property_name),
        perspective=str(perspective),
        candidates=candidates,
        provider=provider,
        config=config,
    )
    return render_worlds([str(item) for item in result[:3]])


def config_from_environment() -> VerificationConfig:
    return VerificationConfig(
        mode=os.environ.get("PROPERTY_WORLD_VERIFIER_MODE", "auto").lower(),
        model=os.environ.get("PROPERTY_WORLD_VERIFIER_MODEL", DEFAULT_MODEL),
        api_key_env=os.environ.get(
            "PROPERTY_WORLD_VERIFIER_API_KEY_ENV", "OPENAI_API_KEY"
        ),
        base_url=os.environ.get("OPENAI_BASE_URL") or None,
        timeout=float(os.environ.get("PROPERTY_WORLD_VERIFIER_TIMEOUT", "90")),
        max_output_tokens=int(
            os.environ.get("PROPERTY_WORLD_VERIFIER_MAX_OUTPUT_TOKENS", "3000")
        ),
        max_attempts=int(
            os.environ.get("PROPERTY_WORLD_VERIFIER_MAX_ATTEMPTS", "2")
        ),
        failure_policy=os.environ.get(
            "PROPERTY_WORLD_VERIFIER_FAILURE_POLICY", "fallback"
        ).lower(),
        audit_path=Path(
            os.environ.get("PROPERTY_WORLD_VERIFIER_AUDIT", DEFAULT_AUDIT_PATH)
        ),
        metta_store_path=Path(
            os.environ.get(
                "PROPERTY_WORLD_VERIFIER_METTA_STORE", DEFAULT_METTA_STORE_PATH
            )
        ),
        kb_path=Path(os.environ.get("PROPERTY_WORLD_KB_PATH", DEFAULT_KB_PATH)),
    )


def _provider_from_environment(config: VerificationConfig) -> OpenAIVerificationProvider:
    api_key = os.environ.get(config.api_key_env, "")
    if not api_key:
        raise PropertyWorldVerificationError(
            f"{config.api_key_env} is required in verify mode"
        )
    return OpenAIVerificationProvider(
        api_key=api_key,
        model=config.model,
        base_url=config.base_url,
        timeout=config.timeout,
        max_output_tokens=config.max_output_tokens,
        trace=os.environ.get("PROPERTY_WORLD_VERIFIER_TRACE") == "1",
    )


def verify_concept_properties(
    concept: Any, perspective: Any, candidate_value: Any
) -> str:
    candidates = parse_property_candidates(candidate_value)
    subject = str(concept)
    perspective_text = str(perspective)
    log_pipeline_event(
        "success",
        "concept_properties_verification_started",
        subject,
        perspective_text,
        {"candidate_count": len(candidates)},
    )
    try:
        config = config_from_environment()
        api_key = os.environ.get(config.api_key_env, "")
        if config.mode == "off" or (config.mode == "auto" and not api_key):
            result = render_properties(candidates[:10])
            log_pipeline_event(
                "success",
                "concept_properties_verification_skipped",
                subject,
                perspective_text,
                {"mode": config.mode, "result_count": min(len(candidates), 10)},
            )
            return result
        result = verify_properties_with_provider(
            subject,
            perspective_text,
            candidates,
            _provider_from_environment(config),
            config,
        )
        log_pipeline_event(
            "success",
            "concept_properties_verification_completed",
            subject,
            perspective_text,
            result,
        )
        return result
    except Exception as exc:
        fail_pipeline(
            "concept_properties_verification",
            subject,
            perspective_text,
            f"{type(exc).__name__}: {exc}",
        )
        raise


def verify_property_worlds(
    property_name: Any, perspective: Any, candidate_value: Any
) -> str:
    candidates = parse_world_candidates(candidate_value)
    subject = str(property_name)
    perspective_text = str(perspective)
    log_pipeline_event(
        "success",
        "property_worlds_verification_started",
        subject,
        perspective_text,
        {"candidate_count": len(candidates)},
    )
    try:
        config = config_from_environment()
        api_key = os.environ.get(config.api_key_env, "")
        if config.mode == "off" or (config.mode == "auto" and not api_key):
            result = render_worlds(candidates[:3])
            log_pipeline_event(
                "success",
                "property_worlds_verification_skipped",
                subject,
                perspective_text,
                {"mode": config.mode, "result_count": min(len(candidates), 3)},
            )
            return result
        result = verify_worlds_with_provider(
            subject,
            perspective_text,
            candidates,
            _provider_from_environment(config),
            config,
        )
        log_pipeline_event(
            "success",
            "property_worlds_verification_completed",
            subject,
            perspective_text,
            result,
        )
        return result
    except Exception as exc:
        fail_pipeline(
            "property_worlds_verification",
            subject,
            perspective_text,
            f"{type(exc).__name__}: {exc}",
        )
        raise
