"""Reproducible source acquisition data models and engine for v-predicate ingestion."""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Any, Dict, Optional


class ProvenanceType(str, Enum):
    """Categorization of acquired raw knowledge source provenance."""

    FIXTURE = "fixture"
    CACHED = "cached"
    DOWNLOADED = "downloaded"


@dataclass(frozen=True)
class SourceArtifact:
    """Immutable metadata and localization descriptor for an acquired knowledge source file."""

    local_path: Path
    source_uri: str
    source_version: str
    license: str
    retrieval_time: str
    byte_size: int
    sha256_checksum: str
    provenance_type: ProvenanceType

    def to_dict(self) -> Dict[str, Any]:
        """Convert artifact metadata to dictionary representation."""
        return {
            "local_path": str(self.local_path),
            "source_uri": self.source_uri,
            "source_version": self.source_version,
            "license": self.license,
            "retrieval_time": self.retrieval_time,
            "byte_size": self.byte_size,
            "sha256_checksum": self.sha256_checksum,
            "provenance_type": (
                self.provenance_type.value
                if isinstance(self.provenance_type, Enum)
                else str(self.provenance_type)
            ),
        }

    def to_sidecar_dict(self) -> Dict[str, Any]:
        """Generate sidecar metadata representation stored alongside cached files."""
        return {
            "source_uri": self.source_uri,
            "source_version": self.source_version,
            "version": self.source_version,
            "license": self.license,
            "retrieval_time": self.retrieval_time,
            "byte_size": self.byte_size,
            "sha256_checksum": self.sha256_checksum,
        }


@dataclass
class AcquisitionConfig:
    """Configuration options governing source artifact acquisition, retries, and caching."""

    cache_dir: Optional[Path] = None
    timeout: float = 30.0
    max_retries: int = 3
    backoff_factor: float = 1.5
    force_refresh: bool = False


class SourceAcquisitionError(Exception):
    """Exception raised when source acquisition fails."""

    def __init__(
        self,
        message: str,
        source_key: Optional[str] = None,
        uri: Optional[str] = None,
        cause: Optional[Exception] = None,
    ) -> None:
        super().__init__(message)
        self.source_key = source_key
        self.uri = uri
        self.cause = cause

    def __str__(self) -> str:
        parts = [super().__str__()]
        if self.source_key:
            parts.append(f"[source_key={self.source_key}]")
        if self.uri:
            parts.append(f"[uri={self.uri}]")
        if self.cause:
            parts.append(f"[cause={self.cause!r}]")
        return " ".join(parts)
