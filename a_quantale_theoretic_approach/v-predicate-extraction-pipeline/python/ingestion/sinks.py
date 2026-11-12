"""Sinks for persisting transformed MeTTa facts into files and PathMap AtomSpaces."""

from __future__ import annotations

import fcntl
from abc import ABC, abstractmethod
from pathlib import Path
from typing import List, Set

from .models import FactType, MettaFact, NormalizedRecord


class BaseSink(ABC):
    """Abstract interface for writing transformed facts into target storage."""

    @abstractmethod
    def write_fact(self, fact: MettaFact) -> bool:
        """Write a single MeTTa fact to the sink."""

    @abstractmethod
    def flush(self) -> None:
        """Ensure all buffered facts are persisted to underlying storage."""


class MettaFileSink(BaseSink):
    """Persists MeTTa facts to a .metta knowledge base file with deduplication."""

    def __init__(self, target_path: Path) -> None:
        self.target_path = Path(target_path)
        self.target_path.parent.mkdir(parents=True, exist_ok=True)
        self._seen_keys: Set[str] = set()
        self._buffer: List[str] = []
        self._load_existing_keys()

    def _load_existing_keys(self) -> None:
        """Load pre-existing fact expressions to maintain idempotence across runs."""
        if not self.target_path.exists():
            return
        try:
            with self.target_path.open("r", encoding="utf-8", errors="replace") as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith(";"):
                        # Extract the expression up to the trailing (stv ...)
                        parts = line.rsplit("(stv", 1)
                        expr = parts[0].strip()
                        self._seen_keys.add(expr)
        except Exception:
            pass

    def write_fact(self, fact: MettaFact) -> bool:
        if fact.expression in self._seen_keys:
            return False

        self._seen_keys.add(fact.expression)
        self._buffer.append(fact.to_metta_line())
        return True

    def flush(self) -> None:
        if not self._buffer:
            return

        payload = "\n".join(self._buffer) + "\n"
        with self.target_path.open("a", encoding="utf-8") as f:
            fcntl.flock(f.fileno(), fcntl.LOCK_EX)
            try:
                f.write(payload)
                f.flush()
            finally:
                fcntl.flock(f.fileno(), fcntl.LOCK_UN)
        self._buffer.clear()


class PathMapSink(BaseSink):
    """Stubbed sink providing the interface for direct PathMap AtomSpace hydration."""

    def __init__(self) -> None:
        self._registered_records: List[NormalizedRecord] = []
        self._buffered_facts: List[MettaFact] = []

    def register_atomspace_record(self, record: NormalizedRecord) -> bool:
        """Accept a normalized record for direct registration in a PathMap shard."""
        self._registered_records.append(record)
        return True

    def get_registered_records(self) -> List[NormalizedRecord]:
        return list(self._registered_records)

    def write_fact(self, fact: MettaFact) -> bool:
        self._buffered_facts.append(fact)
        return True

    def flush(self) -> None:
        # In-memory stub: facts remain available for query/inspection
        pass

