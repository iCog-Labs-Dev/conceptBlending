"""Abstract base adapter for knowledge source ingestion under v-predicate/1."""

from __future__ import annotations

from abc import ABC, abstractmethod
from pathlib import Path
from typing import Iterator, Optional, Any

from v_predicate_contract import FactRecord


class BaseSourceAdapter(ABC):
    """Abstract contract for knowledge source adapters in the ingestion pipeline."""

    @property
    def source_type(self) -> Any:
        """The specific external knowledge repository handled by this adapter."""
        return getattr(self, "_source_type", None)

    @property
    def provenance(self) -> Any:
        """Default provenance descriptor for records produced by this adapter."""
        return getattr(self, "_provenance", None)

    @abstractmethod
    def fetch(self, download: bool = False, cache_dir: Optional[Path] = None) -> Path:
        """Locate or retrieve the raw ontology file, utilizing local cache when available."""

    def stream_facts(self, limit: Optional[int] = None) -> Iterator[FactRecord]:
        """Stream canonical typed V-predicate fact records.

        Subclasses adopting v-predicate/1 should override this method to yield FactRecord
        instances directly.
        """
        raise NotImplementedError(
            f"{self.__class__.__name__} does not implement canonical stream_facts() yet."
        )

    def extract_raw_records(self, limit: Optional[int] = None) -> Iterator[Any]:
        """Stream raw records from the underlying knowledge source (legacy interface)."""
        raise NotImplementedError(
            f"{self.__class__.__name__} does not implement extract_raw_records()."
        )
