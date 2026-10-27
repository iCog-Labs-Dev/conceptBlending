"""Reusable V-predicate support computations for OP constraints."""

from __future__ import annotations

from collections.abc import Mapping

from a_quantale_theoretic_approach.core_representation.product_quantale import ProductQuantale
from a_quantale_theoretic_approach.core_representation.v_predicate import VPredicateConcept
from a_quantale_theoretic_approach.core_representation.world_atom import WorldAtom
from a_quantale_theoretic_approach.optimality.semantic_oracle import SemanticOracle


def universe_labels(concept: VPredicateConcept) -> tuple[str, ...]:
    return tuple(sorted(atom.label for atom in concept.universal_set))


def rebase_concept(concept: VPredicateConcept, universe: tuple[str, ...]) -> VPredicateConcept:
    rebased = VPredicateConcept(concept.name, universal_set=universe)
    for prop_name, entry in concept.entries.items():
        rebased.add_property(
            prop_name,
            entry.quantale.with_universe(universe),
            source=entry.source,
            extraction_method=entry.extraction_method,
            confidence=entry.confidence,
        )
    return rebased


def combined_universe(*concepts: VPredicateConcept) -> tuple[str, ...]:
    labels = set()
    for concept in concepts:
        labels.update(atom.label for atom in concept.universal_set)
    return tuple(sorted(labels))


def unit(universe: tuple[str, ...]) -> ProductQuantale:
    return ProductQuantale.unit(universe)


def bottom(universe: tuple[str, ...]) -> ProductQuantale:
    return ProductQuantale.bottom(universe)


def score_value(score: float, universe: tuple[str, ...]) -> ProductQuantale:
    return ProductQuantale.from_worlds(universe, max(0.0, min(float(score), 1.0)), universe)


def _bridge_value(similarity: float, universe: tuple[str, ...]) -> ProductQuantale:
    # Unit logic means the semantic bridge should scale degree but not erase
    # target world support by forcing a world intersection.
    return ProductQuantale.from_worlds(universe, similarity, universe)


def property_support(
    source_property: str,
    target: VPredicateConcept,
    *,
    universe: tuple[str, ...],
    explicit_target_property: str | None = None,
    oracle: SemanticOracle | None = None,
    semantic_threshold: float = 0.65,
) -> ProductQuantale:
    """Find quantale support for a source property in a target concept.

    Priority order mirrors the old+new hybrid design:
    explicit colimit map, exact property identity, semantic fallback.
    """
    oracle = oracle or SemanticOracle()
    support: ProductQuantale | None = None

    if explicit_target_property and explicit_target_property in target.entries:
        support = target.get_property(explicit_target_property).with_universe(universe)

    if source_property in target.entries:
        exact = target.get_property(source_property).with_universe(universe)
        support = exact if support is None else support + exact

    for target_property, entry in target.entries.items():
        if target_property == explicit_target_property or target_property == source_property:
            continue
        similarity = oracle.similarity(source_property, target_property)
        if similarity < semantic_threshold:
            continue
        candidate = entry.quantale.with_universe(universe) * _bridge_value(similarity, universe)
        support = candidate if support is None else support + candidate

    return support if support is not None else bottom(universe)


def hom_value(
    source: VPredicateConcept,
    target: VPredicateConcept,
    *,
    universe: tuple[str, ...],
    property_map: Mapping[str, str] | None = None,
    oracle: SemanticOracle | None = None,
    semantic_threshold: float = 0.65,
) -> ProductQuantale:
    """Approximate enriched Hom(source, target) from V-predicate support."""
    if not source.entries:
        return unit(universe)
    aggregate = unit(universe)
    mapping = property_map or {}

    for prop_name, entry in source.entries.items():
        source_q = entry.quantale.with_universe(universe)
        support = property_support(
            prop_name,
            target,
            universe=universe,
            explicit_target_property=mapping.get(prop_name),
            oracle=oracle,
            semantic_threshold=semantic_threshold,
        )
        aggregate = aggregate * (source_q >> support)
    return aggregate


def join_values(values: list[ProductQuantale], universe: tuple[str, ...]) -> ProductQuantale:
    aggregate = bottom(universe)
    for value in values:
        aggregate = aggregate + value.with_universe(universe)
    return aggregate


def source_support_for_blend_property(
    blend_property: str,
    source_a: VPredicateConcept,
    source_b: VPredicateConcept,
    contributions: Mapping[str, list],
    *,
    universe: tuple[str, ...],
    oracle: SemanticOracle | None = None,
    semantic_threshold: float = 0.65,
) -> ProductQuantale:
    """Find input support for one blend property, preferring colimit provenance."""
    support_values: list[ProductQuantale] = []
    for contribution in contributions.get(blend_property, []):
        source = None
        if contribution.source_concept == source_a.name:
            source = source_a
        elif contribution.source_concept == source_b.name:
            source = source_b
        if source is not None and contribution.source_property in source.entries:
            support_values.append(source.get_property(contribution.source_property).with_universe(universe))

    if support_values:
        return join_values(support_values, universe)

    support_a = property_support(
        blend_property,
        source_a,
        universe=universe,
        oracle=oracle,
        semantic_threshold=semantic_threshold,
    )
    support_b = property_support(
        blend_property,
        source_b,
        universe=universe,
        oracle=oracle,
        semantic_threshold=semantic_threshold,
    )
    return support_a + support_b
