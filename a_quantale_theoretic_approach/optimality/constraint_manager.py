"""Manager for quantale OP constraint evaluation."""

from __future__ import annotations

from collections.abc import Iterable, Mapping

from a_quantale_theoretic_approach.core_representation.product_quantale import ProductQuantale
from a_quantale_theoretic_approach.core_representation.v_predicate import VPredicateConcept
from a_quantale_theoretic_approach.optimality.constraint_types import (
    QuantaleConditionResult,
    QuantaleOptimalityReport,
    RelationSet,
)
from a_quantale_theoretic_approach.optimality.constraints import (
    GoodReasonCondition,
    IntegrationCondition,
    MetonymicTighteningCondition,
    QuantaleConstraint,
    QuantaleOptimalityContext,
    RelevanceCondition,
    TopologyCondition,
    UnpackingCondition,
    WebCondition,
)
from a_quantale_theoretic_approach.optimality.quantale_helpers import combined_universe, unit
from a_quantale_theoretic_approach.optimality.semantic_oracle import SemanticOracle
from a_quantale_theoretic_approach.structural_reasoning.quantale_colimit_engine import QuantaleColimitResult


class QuantaleConstraintManager:
    """Run the quantale adaptations of the old OP constraints."""

    def __init__(
        self,
        constraints: Iterable[QuantaleConstraint] | None = None,
        *,
        oracle: SemanticOracle | None = None,
        semantic_threshold: float = 0.65,
    ):
        self.constraints = list(
            constraints
            if constraints is not None
            else (
                IntegrationCondition(),
                TopologyCondition(),
                WebCondition(),
                UnpackingCondition(),
                GoodReasonCondition(),
                MetonymicTighteningCondition(),
                RelevanceCondition(),
            )
        )
        self.oracle = oracle or SemanticOracle()
        self.semantic_threshold = semantic_threshold

    def evaluate(
        self,
        source_a: VPredicateConcept,
        source_b: VPredicateConcept,
        colimit: QuantaleColimitResult,
        *,
        candidate_blend: VPredicateConcept | None = None,
        canonical_colimit: QuantaleColimitResult | None = None,
        relations: RelationSet | None = None,
        relevance: Mapping[str, ProductQuantale | float] | None = None,
    ) -> QuantaleOptimalityReport:
        context = QuantaleOptimalityContext(
            source_a=source_a,
            source_b=source_b,
            colimit=colimit,
            candidate_blend=candidate_blend,
            canonical_colimit=canonical_colimit,
            relations=relations or RelationSet(),
            relevance=relevance,
            oracle=self.oracle,
            semantic_threshold=self.semantic_threshold,
        )
        results = {constraint.name: constraint.evaluate(context) for constraint in self.constraints}
        universe = combined_universe(source_a, source_b, context.blend, context.canonical_blend)
        opt_value = unit(universe)
        for result in results.values():
            opt_value = opt_value * result.value

        return QuantaleOptimalityReport(
            conditions=results,
            opt_value=opt_value,
            opt_vector={name: result.value for name, result in results.items()},
            scalar_score=opt_value.tv.value,
        )


def evaluate_quantale_optimality(
    source_a: VPredicateConcept,
    source_b: VPredicateConcept,
    colimit: QuantaleColimitResult,
    **kwargs,
) -> QuantaleOptimalityReport:
    """Convenience wrapper matching the old one-call OP evaluator style."""
    manager = QuantaleConstraintManager()
    return manager.evaluate(source_a, source_b, colimit, **kwargs)
