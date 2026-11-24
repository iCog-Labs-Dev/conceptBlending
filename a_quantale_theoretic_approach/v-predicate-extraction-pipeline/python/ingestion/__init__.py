"""Knowledge Ingestion Framework for Conceptual Blending AtomSpaces."""

from __future__ import annotations

from .acquisition import (
    AcquisitionConfig,
    ProvenanceType,
    SourceAcquisitionError,
    SourceArtifact,
)
from .base_adapter import BaseSourceAdapter
from .chebi_adapter import ChebiAdapter
from .conceptnet_adapter import ConceptNetAdapter
from .go_adapter import GeneOntologyAdapter
from .openmath_adapter import OpenMathAdapter
from .models import (
    FactType,
    IngestionProvenance,
    KnowledgeSource,
    MettaFact,
    NormalizedRecord,
    RawRecord,
)
from .orchestrator import IngestionSummary, MultiSourceOrchestrator
from .sinks import BaseSink, InMemoryTestSink, MettaFileSink, PathMapSink
from .wordnet_adapter import WordNetAdapter, safe_metta_symbol

__all__ = [
    "AcquisitionConfig",
    "BaseSink",
    "BaseSourceAdapter",
    "ChebiAdapter",
    "ConceptNetAdapter",
    "FactType",
    "GeneOntologyAdapter",
    "InMemoryTestSink",
    "IngestionProvenance",
    "IngestionSummary",
    "KnowledgeSource",
    "MettaFact",
    "MettaFileSink",
    "MultiSourceOrchestrator",
    "NormalizedRecord",
    "OpenMathAdapter",
    "PathMapSink",
    "ProvenanceType",
    "RawRecord",
    "SourceAcquisitionError",
    "SourceArtifact",
    "WordNetAdapter",
    "safe_metta_symbol",
]
