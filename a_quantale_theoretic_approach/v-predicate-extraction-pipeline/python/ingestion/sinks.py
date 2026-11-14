"""Sinks for persisting transformed MeTTa facts into files and test memory buffers."""

from __future__ import annotations

import fcntl
from abc import ABC, abstractmethod
from pathlib import Path
from typing import Any, List, Optional, Sequence, Set, Union

from v_predicate_contract import CONTRACT_VERSION, FactRecord


class BaseSink(ABC):
    """Abstract interface for writing knowledge facts and records into storage sinks."""

    @abstractmethod
    def write_fact(self, fact: Any) -> bool:
        """Write a single fact record to the sink."""

    @abstractmethod
    def flush(self) -> None:
        """Flush buffered facts to underlying storage."""


class MettaFileSink(BaseSink):
    """Persists canonical v-predicate/1 or legacy MeTTa facts to a .metta knowledge base file."""

    def __init__(self, target_path: Union[str, Path], header: Optional[str] = None) -> None:
        self.target_path = Path(target_path).resolve()
        self.target_path.parent.mkdir(parents=True, exist_ok=True)
        self._seen_keys: Set[str] = set()
        self._buffer: List[str] = []
        self._header = header or f"; V-predicate contract: {CONTRACT_VERSION}"
        self._load_existing_keys()

    def _load_existing_keys(self) -> None:
        """Load pre-existing fact expressions / evidence IDs to ensure idempotence across runs."""
        if not self.target_path.exists():
            return
        try:
            with self.target_path.open("r", encoding="utf-8", errors="replace") as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith(";"):
                        continue
                    # Canonical format: (: <evidence_id> ...)
                    if line.startswith("(: ") and " (≞ " in line:
                        evidence_id = line.split()[1]
                        self._seen_keys.add(evidence_id)
                    else:
                        # Legacy format: expression up to (stv ...)
                        parts = line.rsplit("(stv", 1)
                        self._seen_keys.add(parts[0].strip())
        except Exception:
            pass

    def write_fact(self, fact: Any) -> bool:
        """Accept either a canonical FactRecord or a legacy MettaFact."""
        if hasattr(fact, "evidence_id") and hasattr(fact, "to_metta_lines"):
            # Canonical FactRecord
            ev_id = fact.evidence_id
            if ev_id in self._seen_keys:
                return False
            self._seen_keys.add(ev_id)
            lines = fact.to_metta_lines(include_provenance=True)
            self._buffer.extend(lines)
            return True
        elif hasattr(fact, "expression") and hasattr(fact, "to_metta_line"):
            # Legacy MettaFact
            expr = fact.expression
            if expr in self._seen_keys:
                return False
            self._seen_keys.add(expr)
            self._buffer.append(fact.to_metta_line())
            return True
        else:
            # Fallback for raw string or unknown fact
            text = str(fact)
            if text in self._seen_keys:
                return False
            self._seen_keys.add(text)
            self._buffer.append(text)
            return True

    def flush(self) -> None:
        """Persist buffered lines to the target .metta file with file locking."""
        is_new = not self.target_path.exists()
        if not is_new and not self._buffer:
            return

        payload_lines: List[str] = []
        if is_new:
            payload_lines.append(self._header)
        payload_lines.extend(self._buffer)
        payload = "\n".join(payload_lines) + "\n"

        with self.target_path.open("a", encoding="utf-8") as f:
            fcntl.flock(f.fileno(), fcntl.LOCK_EX)
            try:
                f.write(payload)
                f.flush()
            finally:
                fcntl.flock(f.fileno(), fcntl.LOCK_UN)

        self._buffer.clear()


class InMemoryTestSink(BaseSink):
    """In-memory test sink for collecting facts and records during verification runs.

    Renamed from PathMapSink in accordance with Rule 9 (Honest Sink Semantics),
    as genuine PathMap shard generation and C++ compilation occur in Objective 1, KR 1.
    """

    def __init__(self) -> None:
        self._registered_records: List[Any] = []
        self._buffered_facts: List[Any] = []

    def register_atomspace_record(self, record: Any) -> bool:
        """Accept a normalized or raw record for in-memory inspection."""
        self._registered_records.append(record)
        return True

    def get_registered_records(self) -> List[Any]:
        return list(self._registered_records)

    def write_fact(self, fact: Any) -> bool:
        self._buffered_facts.append(fact)
        return True

    def get_written_facts(self) -> List[Any]:
        return list(self._buffered_facts)

    def flush(self) -> None:
        pass


# Backward compatibility alias (Rule 9)
PathMapSink = InMemoryTestSink
