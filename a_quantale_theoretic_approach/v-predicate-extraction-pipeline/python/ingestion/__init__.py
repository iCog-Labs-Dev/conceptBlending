"""Knowledge Ingestion Framework for Conceptual Blending AtomSpaces."""

from __future__ import annotations

from .base_adapter import BaseSourceAdapter
from .chebi_adapter import ChebiAdapter
from .go_adapter import GeneOntologyAdapter
from .models import (
    FactType,
    IngestionProvenance,
    KnowledgeSource,
    MettaFact,
    NormalizedRecord,
    RawRecord,
)
from .sinks import BaseSink, MettaFileSink, PathMapSink
from .wordnet_adapter import WordNetAdapter, safe_metta_symbol

__all__ = [
    "BaseSink",
    "BaseSourceAdapter",
    "ChebiAdapter",
    "FactType",
    "GeneOntologyAdapter",
    "IngestionProvenance",
    "KnowledgeSource",
    "MettaFact",
    "MettaFileSink",
    "NormalizedRecord",
    "PathMapSink",
    "RawRecord",
    "WordNetAdapter",
    "safe_metta_symbol",
]
