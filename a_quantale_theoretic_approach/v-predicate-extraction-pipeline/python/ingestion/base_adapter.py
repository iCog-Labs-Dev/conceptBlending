"""Abstract base adapter for knowledge source ingestion under v-predicate/1."""

from __future__ import annotations

from abc import ABC, abstractmethod
import datetime
from pathlib import Path
from typing import Iterator, Optional, Any

from v_predicate_contract import FactRecord
from .acquisition import (
    ProvenanceType,
    SourceAcquisitionEngine,
    SourceArtifact,
    compute_file_sha256,
)


class BaseSourceAdapter(ABC):
    """Abstract contract for knowledge source adapters in the ingestion pipeline."""

    source_name: str = ""
    last_artifact: Optional[SourceArtifact] = None
    _acquisition_engine: Optional[SourceAcquisitionEngine] = None

    @property
    def source_type(self) -> Any:
        """The specific external knowledge repository handled by this adapter."""
        return getattr(self, "_source_type", None)

    @property
    def provenance(self) -> Any:
        """Default provenance descriptor for records produced by this adapter."""
        return getattr(self, "_provenance", None)

    @property
    def acquisition_engine(self) -> SourceAcquisitionEngine:
        """Shared acquisition engine for retrieving and caching source artifacts."""
        if self._acquisition_engine is None:
            self._acquisition_engine = SourceAcquisitionEngine()
        return self._acquisition_engine

    @acquisition_engine.setter
    def acquisition_engine(self, engine: SourceAcquisitionEngine) -> None:
        self._acquisition_engine = engine

    def fetch_artifact(
        self,
        download: bool = False,
        cache_dir: Optional[Path] = None,
        force_refresh: bool = False,
    ) -> SourceArtifact:
        """Acquire the knowledge source artifact with verified provenance.

        Subclasses adopting the acquisition foundation should override this method.
        For legacy subclasses overriding fetch(), this wraps the result into a SourceArtifact.
        """
        if type(self).fetch is not BaseSourceAdapter.fetch:
            resolved = self.fetch(download=download, cache_dir=cache_dir)
            sha = compute_file_sha256(resolved) if resolved.exists() and resolved.is_file() else ""
            size = resolved.stat().st_size if resolved.exists() and resolved.is_file() else 0
            now_iso = datetime.datetime.now(datetime.timezone.utc).isoformat()
            ver = getattr(self, "version", getattr(self, "source_version", "unknown"))
            lic = getattr(self, "license", "unknown")
            uri = getattr(self, "source_uri", str(resolved))
            artifact = SourceArtifact(
                local_path=resolved,
                source_uri=uri,
                source_version=ver,
                license=lic,
                retrieval_time=now_iso,
                byte_size=size,
                sha256_checksum=sha,
                provenance_type=ProvenanceType.FIXTURE,
            )
            self.last_artifact = artifact
            return artifact

        raise NotImplementedError(
            f"{self.__class__.__name__} does not implement fetch_artifact() or fetch()."
        )

    def fetch(self, download: bool = False, cache_dir: Optional[Path] = None) -> Path:
        """Locate or retrieve the raw ontology file, utilizing local cache when available."""
        artifact = self.fetch_artifact(download=download, cache_dir=cache_dir)
        return artifact.local_path

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
