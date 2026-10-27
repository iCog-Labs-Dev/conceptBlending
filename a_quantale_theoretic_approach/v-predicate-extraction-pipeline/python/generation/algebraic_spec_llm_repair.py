#!/usr/bin/env python3
"""Optional LLM proposal stage for algebraic-spec repair.

The LLM is deliberately treated as a proposal engine.  It receives a compact
concept/perspective context and must return strict JSON.  The semantic repair
module later normalizes, validates, and may reject every proposed feature.
"""

from __future__ import annotations

import hashlib
import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Protocol


PROMPT_VERSION = "algebraic-spec-llm-repair-v1"
DEFAULT_MODEL = os.environ.get("OPENAI_MODEL", "gpt-5.4")


class LLMRepairError(RuntimeError):
    pass


class LLMRepairProvider(Protocol):
    @property
    def model_id(self) -> str: ...

    def propose(self, context: dict[str, Any]) -> dict[str, Any]: ...


@dataclass(frozen=True)
class LLMRepairConfig:
    mode: str = "off"
    model: str = DEFAULT_MODEL
    cache_path: str | None = None
    api_key_env: str = "OPENAI_API_KEY"
    base_url: str | None = None
    timeout: float = 45.0
    max_concepts: int | None = None

    def __post_init__(self):
        if self.mode not in {"off", "missing", "always"}:
            raise ValueError("llm repair mode must be off, missing, or always")


class NullLLMRepairProvider:
    model_id = "none"

    def propose(self, context: dict[str, Any]) -> dict[str, Any]:
        return {}


class StaticLLMRepairProvider:
    def __init__(self, proposal: dict[str, Any], model_id: str = "static"):
        self._proposal = proposal
        self._model_id = model_id

    @property
    def model_id(self) -> str:
        return self._model_id

    def propose(self, context: dict[str, Any]) -> dict[str, Any]:
        return dict(self._proposal)


class JsonlRepairCache:
    def __init__(self, path: str | Path):
        self.path = Path(path)
        self._entries: dict[str, dict[str, Any]] | None = None

    def _load(self) -> dict[str, dict[str, Any]]:
        if self._entries is not None:
            return self._entries
        entries: dict[str, dict[str, Any]] = {}
        if self.path.exists():
            with self.path.open(encoding="utf-8", errors="replace") as handle:
                for line in handle:
                    try:
                        row = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    key = row.get("key")
                    proposal = row.get("proposal")
                    if isinstance(key, str) and isinstance(proposal, dict):
                        entries[key] = proposal
        self._entries = entries
        return entries

    def get(self, key: str) -> dict[str, Any] | None:
        value = self._load().get(key)
        return dict(value) if value is not None else None

    def put(self, key: str, proposal: dict[str, Any]) -> None:
        self._load()[key] = dict(proposal)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with self.path.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps({"key": key, "proposal": proposal}, sort_keys=True) + "\n")


def context_hash(context: dict[str, Any], model_id: str) -> str:
    payload = {
        "prompt_version": PROMPT_VERSION,
        "model_id": model_id,
        "context": context,
    }
    raw = json.dumps(payload, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(raw).hexdigest()


def should_use_llm_repair(mode: str, context: dict[str, Any]) -> bool:
    if mode == "off":
        return False
    if mode == "always":
        return True
    quality = context.get("quality", {})
    return bool(
        quality.get("operation_count", 0) < 2
        or quality.get("axiom_count", 0) < quality.get("operation_count", 0)
        or quality.get("operation_axiom_coverage", 1.0) < 0.85
        or quality.get("ambiguous_sense", False)
    )


def normalize_proposal(value: Any) -> dict[str, Any]:
    if not isinstance(value, dict):
        return {}
    repairs = value.get("repairs")
    if not isinstance(repairs, dict):
        repairs = value
    return {
        "sense": value.get("sense", {}),
        "ontology": value.get("ontology", {}),
        "repairs": {
            "sorts": list(repairs.get("sorts", ())) if isinstance(repairs.get("sorts", ()), list) else [],
            "operations": list(repairs.get("operations", ())) if isinstance(repairs.get("operations", ()), list) else [],
            "predicates": list(repairs.get("predicates", ())) if isinstance(repairs.get("predicates", ()), list) else [],
            "axioms": list(repairs.get("axioms", ())) if isinstance(repairs.get("axioms", ()), list) else [],
        },
        "notes": list(value.get("notes", ())) if isinstance(value.get("notes", ()), list) else [],
    }


class OpenAIRepairProvider:
    def __init__(
        self,
        api_key: str,
        model: str = DEFAULT_MODEL,
        base_url: str | None = None,
        timeout: float = 45.0,
    ):
        if not api_key:
            raise LLMRepairError("OpenAI API key is required for LLM repair")
        self._model = model
        self._timeout = timeout
        try:
            from openai import OpenAI
        except ImportError as exc:
            raise LLMRepairError("The openai package is required for LLM repair") from exc
        kwargs: dict[str, Any] = {"api_key": api_key, "timeout": timeout}
        if base_url:
            kwargs["base_url"] = base_url
        self._client = OpenAI(**kwargs)

    @property
    def model_id(self) -> str:
        return self._model

    def propose(self, context: dict[str, Any]) -> dict[str, Any]:
        schema = _response_schema()
        response = self._client.responses.create(
            model=self._model,
            input=[
                {"role": "system", "content": _system_prompt()},
                {"role": "user", "content": json.dumps(context, sort_keys=True)},
            ],
            text={
                "format": {
                    "type": "json_schema",
                    "name": "algebraic_spec_repair",
                    "schema": schema,
                    "strict": True,
                }
            },
        )
        raw = response.output_text
        return normalize_proposal(json.loads(raw))


def provider_from_config(config: LLMRepairConfig) -> LLMRepairProvider:
    if config.mode == "off":
        return NullLLMRepairProvider()
    api_key = os.environ.get(config.api_key_env, "")
    return OpenAIRepairProvider(
        api_key=api_key,
        model=config.model,
        base_url=config.base_url,
        timeout=config.timeout,
    )


def propose_with_cache(
    provider: LLMRepairProvider,
    context: dict[str, Any],
    cache: JsonlRepairCache | None = None,
) -> dict[str, Any]:
    key = context_hash(context, provider.model_id)
    if cache:
        cached = cache.get(key)
        if cached is not None:
            return cached
    proposal = normalize_proposal(provider.propose(context))
    if cache and proposal:
        cache.put(key, proposal)
    return proposal


def _system_prompt() -> str:
    return (
        "You repair algebraic specifications for concept-centered knowledge bases. "
        "Given one concept, one perspective, raw evidence, and a draft spec, choose the intended sense, "
        "ground terms in useful ontology roles, and propose concept-specific sorts, operations, predicates, and axioms. "
        "Operations must be capabilities, transformations, observers, constants, or combinators. "
        "Predicates must be static relations/properties/states and must not restate capabilities. "
        "Axioms must constrain declared operations and reference at least one operation. "
        "Prefer concise MeTTa-safe snake_case symbols. Return only JSON matching the schema."
    )


def _response_schema() -> dict[str, Any]:
    feature = {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "name": {"type": "string"},
            "value": {"type": "string"},
            "expression": {"type": "string"},
            "signature": {"type": "string"},
            "required_sorts": {"type": "array", "items": {"type": "string"}},
            "referenced_operations": {"type": "array", "items": {"type": "string"}},
            "confidence": {"type": "number"},
            "evidence": {"type": "array", "items": {"type": "string"}},
        },
        "required": ["name", "confidence"],
    }
    return {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "sense": {
                "type": "object",
                "additionalProperties": False,
                "properties": {
                    "selected_sense": {"type": "string"},
                    "sense_label": {"type": "string"},
                    "confidence": {"type": "number"},
                    "evidence_used": {"type": "array", "items": {"type": "string"}},
                },
                "required": ["selected_sense", "sense_label", "confidence", "evidence_used"],
            },
            "ontology": {
                "type": "object",
                "additionalProperties": False,
                "properties": {
                    "concept_type": {"type": "string"},
                    "sort_mappings": {"type": "object", "additionalProperties": {"type": "string"}},
                },
                "required": ["concept_type", "sort_mappings"],
            },
            "repairs": {
                "type": "object",
                "additionalProperties": False,
                "properties": {
                    "sorts": {"type": "array", "items": feature},
                    "operations": {"type": "array", "items": feature},
                    "predicates": {"type": "array", "items": feature},
                    "axioms": {"type": "array", "items": feature},
                },
                "required": ["sorts", "operations", "predicates", "axioms"],
            },
            "notes": {"type": "array", "items": {"type": "string"}},
        },
        "required": ["sense", "ontology", "repairs", "notes"],
    }
