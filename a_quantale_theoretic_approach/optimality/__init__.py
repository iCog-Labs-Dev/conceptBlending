"""Quantale adaptations of conceptual blending optimality constraints."""

from .constraint_manager import QuantaleConstraintManager, evaluate_quantale_optimality
from .constraint_types import CrossMapping, QuantaleRelation, RelationSet
from .semantic_oracle import SemanticOracle

__all__ = [
    "CrossMapping",
    "QuantaleConstraintManager",
    "QuantaleRelation",
    "RelationSet",
    "SemanticOracle",
    "evaluate_quantale_optimality",
]
