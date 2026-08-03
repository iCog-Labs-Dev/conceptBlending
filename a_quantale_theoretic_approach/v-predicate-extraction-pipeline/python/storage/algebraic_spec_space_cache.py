#!/usr/bin/env python3
"""Disk-backed cache used to repopulate ``&algspecspace`` across PeTTa runs."""

from __future__ import annotations

import fcntl
import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

from pipeline_event_logger import fail_pipeline, log_pipeline_event


SCRIPT_DIR = Path(__file__).resolve().parent
PIPELINE_ROOT = SCRIPT_DIR.parents[1]
DEFAULT_CACHE_PATH = (
    PIPELINE_ROOT / "kb" / "runtime" / "cache"
    / "AlgebraicSpecificationSpaceCache.jsonl"
)
DEFAULT_VERIFIER_AUDIT_PATH = (
    PIPELINE_ROOT / "kb" / "runtime" / "verified"
    / "AlgebraicSpecificationVerified.jsonl"
)
SAFE_ATOM = re.compile(r"^[A-Za-z_][A-Za-z0-9_-]*$")
CACHE_RECORD_TYPE = "algebraic_spec_space_cache"
CACHE_VERSION = 1


def _enabled() -> bool:
    return os.environ.get("ALGEBRAIC_SPEC_SPACE_CACHE_MODE", "on").lower() not in {
        "off",
        "false",
        "0",
    }


def _cache_path() -> Path:
    return Path(
        os.environ.get("ALGEBRAIC_SPEC_SPACE_CACHE", DEFAULT_CACHE_PATH)
    )


def _verifier_audit_path() -> Path:
    return Path(
        os.environ.get(
            "ALGEBRAIC_SPEC_VERIFIER_AUDIT", DEFAULT_VERIFIER_AUDIT_PATH
        )
    )


def _iter_jsonl(path: Path) -> Iterable[dict[str, Any]]:
    if not path.exists():
        return
    with path.open(encoding="utf-8", errors="replace") as handle:
        for line in handle:
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(row, dict):
                yield row


def _valid_entry(concept: Any, perspective: Any, specification: Any) -> bool:
    return (
        isinstance(concept, str)
        and SAFE_ATOM.fullmatch(concept) is not None
        and isinstance(perspective, str)
        and SAFE_ATOM.fullmatch(perspective) is not None
        and isinstance(specification, str)
        and specification.strip().startswith("(Concept ")
    )


def _metta_text(value: Any) -> str:
    """Render the nested Python value supplied by PeTTa as MeTTa text."""

    if isinstance(value, (list, tuple)):
        return f"({' '.join(_metta_text(item) for item in value)})"
    if isinstance(value, str):
        return value
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value)


def _verified_entries() -> dict[tuple[str, str], str]:
    """Read the latest specifications accepted by the current verifier prompt."""

    if os.environ.get(
        "ALGEBRAIC_SPEC_SPACE_IMPORT_VERIFIED", "1"
    ).lower() in {"off", "false", "0"}:
        return {}

    try:
        from algebraic_spec_verifier import PROMPT_VERSION
    except ImportError:
        return {}

    result: dict[tuple[str, str], str] = {}
    for row in _iter_jsonl(_verifier_audit_path()):
        concept = row.get("concept")
        perspective = row.get("perspective")
        specification = row.get("verified_spec")
        if (
            row.get("prompt_version") == PROMPT_VERSION
            and row.get("record_type", "final") == "final"
            and row.get("verdict") in {"correct", "corrected"}
            and _valid_entry(concept, perspective, specification)
        ):
            result[(concept, perspective)] = specification.strip()
    return result


def _cached_entries() -> dict[tuple[str, str], str]:
    result: dict[tuple[str, str], str] = {}
    for row in _iter_jsonl(_cache_path()):
        concept = row.get("concept")
        perspective = row.get("perspective")
        specification = row.get("specification")
        if (
            row.get("record_type") == CACHE_RECORD_TYPE
            and row.get("version") == CACHE_VERSION
            and _valid_entry(concept, perspective, specification)
        ):
            result[(concept, perspective)] = specification.strip()
    return result


def load_persisted_algebraic_specs() -> str:
    """Return persisted entries as one MeTTa list for startup hydration."""

    if not _enabled():
        return "()"

    # The dedicated cache is authoritative over an older verifier-audit entry.
    entries = _verified_entries()
    entries.update(_cached_entries())
    rendered = [
        f"(CachedAlgebraicSpec {concept} {perspective} {specification})"
        for (concept, perspective), specification in sorted(entries.items())
    ]
    return f"({' '.join(rendered)})"


def persist_algebraic_spec(
    concept: Any, perspective: Any, specification: Any
) -> bool:
    """Append a completed specification under its perspective-aware key."""

    concept_text = str(concept)
    perspective_text = str(perspective)
    try:
        if not _enabled():
            return False

        specification_text = _metta_text(specification).strip()
        if not _valid_entry(concept_text, perspective_text, specification_text):
            raise ValueError(
                "persistent algebraic specifications require safe concept and "
                "perspective atoms and a complete (Concept ...) expression; got "
                f"concept={concept_text!r}, perspective={perspective_text!r}, "
                f"specification={specification_text[:80]!r}"
            )

        path = _cache_path()
        path.parent.mkdir(parents=True, exist_ok=True)
        row = {
            "record_type": CACHE_RECORD_TYPE,
            "version": CACHE_VERSION,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "concept": concept_text,
            "perspective": perspective_text,
            "specification": specification_text,
        }
        encoded = json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n"
        with path.open("a", encoding="utf-8") as handle:
            fcntl.flock(handle.fileno(), fcntl.LOCK_EX)
            try:
                handle.write(encoded)
                handle.flush()
                os.fsync(handle.fileno())
            finally:
                fcntl.flock(handle.fileno(), fcntl.LOCK_UN)
        log_pipeline_event(
            "success",
            "algebraic_spec_persisted",
            concept_text,
            perspective_text,
            str(path),
        )
        return True
    except Exception as exc:
        fail_pipeline(
            "algebraic_spec_persistence",
            concept_text,
            perspective_text,
            f"{type(exc).__name__}: {exc}",
        )
        raise
