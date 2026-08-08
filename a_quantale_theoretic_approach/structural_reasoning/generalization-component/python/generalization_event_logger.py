#!/usr/bin/env python3
"""Structured events compatible with the integrated pipeline logger."""

from __future__ import annotations

import fcntl
import json
import os
import sys
import uuid
from contextvars import ContextVar
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


COMPONENT_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_LOG_PATH = (
    COMPONENT_ROOT / "kb" / "runtime" / "logs" / "GeneralizationEvents.jsonl"
)
DEFAULT_MILESTONE_STAGES = frozenset(
    {
        "generalization_started",
        "generic_space_cache_hit",
        "generic_space_cache_miss",
        "cartesian_plan_built",
        "pair_lcg_cache_hit",
        "pair_lcg_resolved",
        "generic_space_assembled",
        "generic_space_cached",
        "generalization_completed",
    }
)
_RUN_ID: ContextVar[str] = ContextVar("generalization_run_id", default="")
_ROOT_SUBJECT: ContextVar[str] = ContextVar(
    "generalization_root_subject", default=""
)
_ROOT_PERSPECTIVE: ContextVar[str] = ContextVar(
    "generalization_root_perspective", default=""
)


def _enabled() -> bool:
    return os.environ.get("PIPELINE_LOG_MODE", "on").lower() not in {
        "off",
        "false",
        "0",
    }


def _stderr_enabled() -> bool:
    return os.environ.get("PIPELINE_LOG_STDERR", "1").lower() not in {
        "off",
        "false",
        "0",
    }


def _verbosity() -> str:
    value = os.environ.get("PIPELINE_LOG_VERBOSITY", "default").lower()
    return "verbose" if value == "verbose" else "default"


def _should_log(status: str, stage: str) -> bool:
    if status == "error" or _verbosity() == "verbose":
        return True
    return (
        stage in DEFAULT_MILESTONE_STAGES
        or stage.endswith("_fallback_used")
    )


def _log_path() -> Path:
    return Path(os.environ.get("PIPELINE_LOG_PATH", DEFAULT_LOG_PATH))


def _metta_text(value: Any) -> str:
    if isinstance(value, (list, tuple)):
        return f"({' '.join(_metta_text(item) for item in value)})"
    if isinstance(value, dict):
        return json.dumps(value, sort_keys=True, default=str)
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value)


def _bounded_detail(value: Any) -> str:
    text = _metta_text(value)
    try:
        limit = int(os.environ.get("PIPELINE_LOG_MAX_DETAIL_CHARS", "2000"))
    except ValueError:
        limit = 2000
    if limit > 0 and len(text) > limit:
        return text[:limit] + f"...<truncated {len(text) - limit} chars>"
    return text


def _append(row: dict[str, Any]) -> None:
    path = _log_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    encoded = json.dumps(row, sort_keys=True, default=str) + "\n"
    with path.open("a", encoding="utf-8") as handle:
        fcntl.flock(handle.fileno(), fcntl.LOCK_EX)
        try:
            handle.write(encoded)
            handle.flush()
        finally:
            fcntl.flock(handle.fileno(), fcntl.LOCK_UN)


def log_generalization_event(
    status: Any,
    stage: Any,
    subject: Any = "",
    perspective: Any = "",
    details: Any = "",
) -> bool:
    """Write one correlated event without allowing logging to break work."""

    if not _enabled():
        return False
    status_text = str(status).lower()
    stage_text = str(stage)
    if not _should_log(status_text, stage_text):
        return False
    subject_text = str(subject) or _ROOT_SUBJECT.get()
    perspective_text = str(perspective) or _ROOT_PERSPECTIVE.get()
    run_id = _RUN_ID.get() or "standalone"
    row = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "run_id": run_id,
        "status": status_text,
        "stage": stage_text,
        "subject": subject_text,
        "perspective": perspective_text,
        "details": _bounded_detail(details),
        "pid": os.getpid(),
    }
    try:
        _append(row)
        if _stderr_enabled():
            detail = row["details"]
            suffix = f" details={detail}" if detail else ""
            print(
                f"[PIPELINE][{status_text.upper()}][{run_id}] "
                f"{stage_text} {subject_text}/{perspective_text}{suffix}",
                file=sys.stderr,
            )
        return True
    except Exception as exc:
        print(
            f"[PIPELINE][LOGGER_ERROR] {type(exc).__name__}: {exc}",
            file=sys.stderr,
        )
        return False


def start_generalization(subject: Any, perspective: Any) -> str:
    run_id = uuid.uuid4().hex
    _RUN_ID.set(run_id)
    _ROOT_SUBJECT.set(str(subject))
    _ROOT_PERSPECTIVE.set(str(perspective))
    log_generalization_event(
        "success",
        "generalization_started",
        subject,
        perspective,
        "generic-space construction started",
    )
    return run_id


def finish_generalization(
    status: Any,
    subject: Any,
    perspective: Any,
    details: Any = "",
) -> bool:
    try:
        return log_generalization_event(
            status,
            "generalization_completed",
            subject,
            perspective,
            details,
        )
    finally:
        _RUN_ID.set("")
        _ROOT_SUBJECT.set("")
        _ROOT_PERSPECTIVE.set("")


def fail_generalization(
    stage: Any,
    subject: Any,
    perspective: Any,
    details: Any,
) -> bool:
    logged = log_generalization_event(
        "error", stage, subject, perspective, details
    )
    if _RUN_ID.get():
        finish_generalization(
            "error",
            _ROOT_SUBJECT.get() or subject,
            _ROOT_PERSPECTIVE.get() or perspective,
            f"{stage}: {_bounded_detail(details)}",
        )
    return logged
