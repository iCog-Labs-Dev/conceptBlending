#!/usr/bin/env python3
"""Structured success/error event logging for the integrated build pipeline."""

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


SCRIPT_DIR = Path(__file__).resolve().parent
PIPELINE_ROOT = SCRIPT_DIR.parents[1]
DEFAULT_LOG_PATH = (
    PIPELINE_ROOT / "kb" / "runtime" / "logs" / "PipelineEvents.jsonl"
)
DEFAULT_MILESTONE_STAGES = frozenset(
    {
        "pipeline_started",
        "properties_extracted",
        "properties_verified",
        "property_world_pairs_built",
        "worlds_deduplicated",
        "algebraic_spec_cache_hit",
        "algebraic_spec_cache_miss",
        "algebraic_spec_generated",
        "algebraic_spec_verified",
        "algebraic_spec_stored",
        "pipeline_completed",
    }
)
_RUN_ID: ContextVar[str] = ContextVar("pipeline_run_id", default="")
_ROOT_SUBJECT: ContextVar[str] = ContextVar("pipeline_root_subject", default="")
_ROOT_PERSPECTIVE: ContextVar[str] = ContextVar(
    "pipeline_root_perspective", default=""
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
    limit = int(os.environ.get("PIPELINE_LOG_MAX_DETAIL_CHARS", "2000"))
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


def log_pipeline_event(
    status: Any,
    stage: Any,
    subject: Any = "",
    perspective: Any = "",
    details: Any = "",
) -> bool:
    """Write one correlated event without allowing logger failure to break work."""

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
    except Exception as exc:  # Logging must never mask the pipeline's real result.
        print(
            f"[PIPELINE][LOGGER_ERROR] {type(exc).__name__}: {exc}",
            file=sys.stderr,
        )
        return False


def start_pipeline(subject: Any, perspective: Any) -> str:
    run_id = uuid.uuid4().hex
    _RUN_ID.set(run_id)
    _ROOT_SUBJECT.set(str(subject))
    _ROOT_PERSPECTIVE.set(str(perspective))
    log_pipeline_event(
        "success", "pipeline_started", subject, perspective, "integrated build started"
    )
    return run_id


def finish_pipeline(
    status: Any,
    subject: Any,
    perspective: Any,
    details: Any = "",
) -> bool:
    try:
        return log_pipeline_event(
            status, "pipeline_completed", subject, perspective, details
        )
    finally:
        _RUN_ID.set("")
        _ROOT_SUBJECT.set("")
        _ROOT_PERSPECTIVE.set("")


def fail_pipeline(
    stage: Any,
    subject: Any,
    perspective: Any,
    details: Any,
) -> bool:
    """Record a fatal stage error and close an active integrated run."""

    logged = log_pipeline_event(
        "error", stage, subject, perspective, details
    )
    if _RUN_ID.get():
        finish_pipeline(
            "error",
            _ROOT_SUBJECT.get() or subject,
            _ROOT_PERSPECTIVE.get() or perspective,
            f"{stage}: {_bounded_detail(details)}",
        )
    return logged
