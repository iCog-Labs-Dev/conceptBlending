"""Abstract base adapter for knowledge source ingestion."""

from __future__ import annotations

from abc import ABC, abstractmethod
from pathlib import Path
from typing import Iterator, List, Optional

from .models import IngestionProvenance, KnowledgeSource, MettaFact, NormalizedRecord, RawRecord


class BaseSourceAdapter(ABC):
    """Abstract contract for knowledge source adapters in the ingestion pipeline."""

    @property
    @abstractmethod
    def source_type(self) -> KnowledgeSource:
        """The specific external knowledge repository handled by this adapter."""

    @property
    @abstractmethod
    def provenance(self) -> IngestionProvenance:
        """Default provenance descriptor for records produced by this adapter."""

    @abstractmethod
    def fetch(self, download: bool = False, cache_dir: Optional[Path] = None) -> Path:
        """Locate or retrieve the raw ontology file, utilizing local cache when available."""

    @abstractmethod
    def extract_raw_records(self, limit: Optional[int] = None) -> Iterator[RawRecord]:
        """Stream raw records from the underlying knowledge source."""

    @abstractmethod
    def normalize_record(self, record: RawRecord) -> Optional[NormalizedRecord]:
        """Convert a raw record into canonical MeTTa symbols and a validated perspective."""

    @abstractmethod
    def transform_to_casl(self, record: NormalizedRecord) -> List[MettaFact]:
        """Generate CASL Algebraic Specification facts from a normalized record."""

    @abstractmethod
    def transform_to_property_world(self, record: NormalizedRecord) -> List[MettaFact]:
        """Generate Property-to-Possible-World mapping facts from a normalized record."""

