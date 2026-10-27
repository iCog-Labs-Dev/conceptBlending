"""Shared types for quantale optimality constraints."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from a_quantale_theoretic_approach.core_representation.product_quantale import ProductQuantale


@dataclass(frozen=True)
class QuantaleRelation:
    """A quantale-valued relation between V-predicate properties."""

    relation_type: str
    source_property: str
    target_property: str
    value: ProductQuantale | None = None


@dataclass(frozen=True)
class CrossMapping:
    """Old Web-OP style relation pair between source concepts."""

    concept_a_relation: QuantaleRelation
    concept_b_relation: QuantaleRelation
    confidence: float = 1.0


@dataclass
class RelationSet:
    """Optional relation data used by topology, web, and metonymic tightening."""

    source_a: list[QuantaleRelation] = field(default_factory=list)
    source_b: list[QuantaleRelation] = field(default_factory=list)
    blend: list[QuantaleRelation] = field(default_factory=list)
    cross_mappings: list[CrossMapping] = field(default_factory=list)


@dataclass(frozen=True)
class QuantaleConditionResult:
    """One OP condition value and diagnostics."""

    name: str
    value: ProductQuantale
    tv_score: float
    passed: bool
    skipped: bool = False
    details: dict[str, Any] = field(default_factory=dict)


@dataclass
class QuantaleOptimalityReport:
    """Aggregate optimality result."""

    conditions: dict[str, QuantaleConditionResult]
    opt_value: ProductQuantale
    opt_vector: dict[str, ProductQuantale]
    scalar_score: float

    def to_dict(self) -> dict[str, Any]:
        return {
            "scalar_score": self.scalar_score,
            "opt_value": self.opt_value.to_metta(),
            "conditions": {
                name: {
                    "value": result.value.to_metta(),
                    "tv_score": result.tv_score,
                    "passed": result.passed,
                    "skipped": result.skipped,
                    "details": result.details,
                }
                for name, result in self.conditions.items()
            },
        }
