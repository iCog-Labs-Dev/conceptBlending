"""Persistent content-addressed cache for generic-space construction."""
from __future__ import annotations

import fcntl
import hashlib
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

from generalization_event_logger import log_generalization_event

HERE = Path(__file__).resolve().parent
COMPONENT_ROOT = HERE.parent
DEFAULT_CACHE_PATH = COMPONENT_ROOT / "kb" / "runtime" / "generalization_cache.jsonl"
DEFAULT_KB_PATH = COMPONENT_ROOT / "kb" / "lcg_kb.metta"
CACHE_FORMAT_VERSION = 1
_KB_FINGERPRINT_CACHE: dict[str, tuple[int, int, str]] = {}


def mode() -> str:
    return os.getenv("GENERALIZATION_CACHE_MODE", "on").strip().lower()


def enabled() -> bool:
    return mode() not in {"off", "false", "0"}


def refreshing() -> bool:
    return mode() in {"refresh", "rebuild"}


def cache_path() -> Path:
    return Path(os.getenv("GENERALIZATION_CACHE_PATH", str(DEFAULT_CACHE_PATH)))


def _trace(event: str, record_type: str, key: str) -> None:
    if os.getenv("GENERALIZATION_CACHE_TRACE", "off").lower() in {
        "1", "on", "true", "yes"
    }:
        print(
            f"GENERALIZATION_CACHE {event} {record_type} {key}",
            file=sys.stderr,
        )


def kb_fingerprint() -> str:
    path = Path(os.getenv("GENERALIZATION_CACHE_KB", str(DEFAULT_KB_PATH)))
    try:
        stat = path.stat()
    except OSError:
        return "kb-unavailable"
    cache_key = str(path.resolve())
    cached = _KB_FINGERPRINT_CACHE.get(cache_key)
    if cached is not None and cached[:2] == (stat.st_mtime_ns, stat.st_size):
        return cached[2]
    digest = hashlib.sha256()
    try:
        with path.open("rb") as handle:
            for block in iter(lambda: handle.read(1024 * 1024), b""):
                digest.update(block)
    except OSError:
        return "kb-unavailable"
    result = digest.hexdigest()
    _KB_FINGERPRINT_CACHE[cache_key] = (stat.st_mtime_ns, stat.st_size, result)
    return result


def content_key(record_type: str, payload: dict[str, Any]) -> str:
    encoded = json.dumps(
        {"record_type": record_type, **payload},
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def _rows(path: Path) -> Iterable[dict[str, Any]]:
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


def lookup(record_type: str, key: str) -> Any | None:
    if not enabled() or refreshing():
        _trace("bypass", record_type, key)
        log_generalization_event(
            "success",
            f"{'generic_space' if record_type == 'generic_algebraic_spec' else 'pair_lcg'}_cache_bypassed",
            details={"record_type": record_type, "cache_key": key},
        )
        return None
    found = None
    for row in _rows(cache_path()):
        if (
            row.get("cache_format_version") == CACHE_FORMAT_VERSION
            and row.get("record_type") == record_type
            and row.get("key") == key
        ):
            found = row.get("value")
    _trace("hit" if found is not None else "miss", record_type, key)
    prefix = (
        "generic_space"
        if record_type == "generic_algebraic_spec"
        else "pair_lcg"
    )
    log_generalization_event(
        "success",
        f"{prefix}_cache_{'hit' if found is not None else 'miss'}",
        details={"record_type": record_type, "cache_key": key},
    )
    return found


def persist(
    record_type: str,
    key: str,
    value: Any,
    metadata: dict[str, Any] | None = None,
) -> bool:
    if not enabled():
        _trace("write-disabled", record_type, key)
        log_generalization_event(
            "success",
            "generalization_cache_write_skipped",
            details={"record_type": record_type, "cache_key": key},
        )
        return False
    path = cache_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    row = {
        "cache_format_version": CACHE_FORMAT_VERSION,
        "record_type": record_type,
        "key": key,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "value": value,
        "metadata": metadata or {},
    }
    encoded = json.dumps(
        row, sort_keys=True, separators=(",", ":"), ensure_ascii=False
    ) + "\n"
    with path.open("a", encoding="utf-8") as handle:
        fcntl.flock(handle.fileno(), fcntl.LOCK_EX)
        try:
            handle.write(encoded)
            handle.flush()
            os.fsync(handle.fileno())
        finally:
            fcntl.flock(handle.fileno(), fcntl.LOCK_UN)
    _trace("stored", record_type, key)
    stage = (
        "generic_space_cached"
        if record_type == "generic_algebraic_spec"
        else "pair_lcg_cached"
    )
    log_generalization_event(
        "success",
        stage,
        details={"record_type": record_type, "cache_key": key},
    )
    return True
