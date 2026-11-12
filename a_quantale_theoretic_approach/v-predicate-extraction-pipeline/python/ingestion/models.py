"""Typed, immutable data models and provenance records for knowledge ingestion."""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Mapping


class KnowledgeSource(str, Enum):
    """External knowledge repositories supported by the ingestion pipeline."""

    WORDNET = "WORDNET"
    GENE_ONTOLOGY = "GENE_ONTOLOGY"
    CHEBI = "CHEBI"
    OPENMATH = "OPENMATH"
    CONCEPTNET = "CONCEPTNET"


class FactType(str, Enum):
    """Canonical categories of MeTTa assertions in our AtomSpaces."""

    # CASL Algebraic Specification types
    HAS_SORT = "has_sort"
    HAS_OPERATION = "has_operation"
    OPERATION_SIGNATURE = "operation_signature"
    HAS_PREDICATE = "has_predicate"
    PREDICATE_SIGNATURE = "predicate_signature"
    HAS_AXIOM = "has_axiom"

    # Property-World mapping types
    HAS_SCOPED_PROPERTY = "has_scoped_property"
    SCOPED_PROPERTY_HOLDS_IN = "scoped_property_holds_in"
    PERSPECTIVE_MATCH = "perspective_match"


@dataclass(frozen=True)
class IngestionProvenance:
    """Immutable provenance tracking origin, path, version, and license."""

    source: KnowledgeSource
    source_uri_or_path: str
    source_version: str
    license: str


@dataclass(frozen=True)
class RawRecord:
    """Raw, un-normalized record extracted directly from an external ontology."""

    source_id: str
    concept_name: str
    relation: str
    target_name: str
    weight: float
    metadata: Mapping[str, Any] = field(default_factory=dict)
    provenance: IngestionProvenance = field(default=None)  # type: ignore[assignment]


@dataclass(frozen=True)
class NormalizedRecord:
    """Normalized, perspective-aware record with validated numeric bounds."""

    concept: str
    property_or_target: str
    relation: str
    perspective: str
    strength: float
    confidence: float
    provenance: IngestionProvenance

    def __post_init__(self) -> None:
        if not (0.0 <= self.strength <= 1.0):
            raise ValueError(
                f"STV strength must be in [0.0, 1.0], got {self.strength}"
            )
        if not (0.0 <= self.confidence <= 1.0):
            raise ValueError(
                f"STV confidence must be in [0.0, 1.0], got {self.confidence}"
            )


@dataclass(frozen=True)
class MettaFact:
    """Executable MeTTa fact ready for persistence in an AtomSpace knowledge base."""

    fact_type: FactType
    expression: str
    stv: tuple[float, float]

    def to_metta_line(self) -> str:
        """Render balanced MeTTa fact with Simple Truth Value annotation."""
        s, c = self.stv
        # Format floats cleanly without unnecessary trailing decimals
        s_str = f"{s:.4f}".rstrip("0").rstrip(".") if "." in f"{s:.4f}" else str(s)
        c_str = f"{c:.4f}".rstrip("0").rstrip(".") if "." in f"{c:.4f}" else str(c)
        return f"{self.expression} (stv {s_str} {c_str})"

