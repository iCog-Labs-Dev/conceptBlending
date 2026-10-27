"""Quantale/V-predicate colimit construction.

This module is the V-predicate counterpart of the older CASL-oriented
``a_categorytheoretic_approach.libs.colimit`` engine.  The old engine still has
an important role at the WorldSpec layer; this engine works one level up, where
concepts are maps ``Props -> ProductQuantale``.
"""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass, field
from typing import Any

from a_quantale_theoretic_approach.core_representation.product_quantale import ProductQuantale
from a_quantale_theoretic_approach.core_representation.v_predicate import VPredicateConcept
from a_quantale_theoretic_approach.core_representation.v_predicate_parser import (
    parse_v_predicate_document,
)
from a_quantale_theoretic_approach.core_representation.world_atom import WorldAtom
from a_quantale_theoretic_approach.core_representation.world_spec import WorldSpecRegistry


PropertyMap = Mapping[str, Mapping[str, str]] | Mapping[str, str] | None


@dataclass(frozen=True)
class PropertyContribution:
    """Where a blended property value came from."""

    source_concept: str
    source_property: str
    blend_property: str


@dataclass
class QuantaleColimitResult:
    """Result of a V-predicate colimit construction."""

    blend: VPredicateConcept
    world_specs: WorldSpecRegistry
    property_maps: dict[str, dict[str, str]]
    contributions: dict[str, list[PropertyContribution]] = field(default_factory=dict)
    generated_worlds: dict[str, str] = field(default_factory=dict)
    metrics: dict[str, Any] = field(default_factory=dict)

    def to_metta(self, *, include_world_specs: bool = False) -> str:
        parts = []
        if include_world_specs and len(self.world_specs) > 0:
            parts.append(self.world_specs.to_metta())
        parts.append(self.blend.to_metta())
        if self.metrics:
            metric_parts = []
            for name in sorted(self.metrics):
                value = self.metrics[name]
                if isinstance(value, ProductQuantale):
                    metric_parts.append(f"    ({name} {value.to_metta()})")
                else:
                    metric_parts.append(f"    ({name} {value})")
            parts.append("(QuantaleMetrics\n" + "\n".join(metric_parts) + ")")
        return "\n\n".join(parts)


def _clean_property_name(name: str) -> str:
    return str(name).replace(":", "").strip()


def _property_mapping(mapping: PropertyMap) -> dict[str, str]:
    if not mapping:
        return {}
    if "properties" in mapping:  # type: ignore[operator]
        return dict(mapping["properties"])  # type: ignore[index]
    if "Property" in mapping:  # type: ignore[operator]
        return dict(mapping["Property"])  # type: ignore[index]
    if "props" in mapping:  # type: ignore[operator]
        return dict(mapping["props"])  # type: ignore[index]
    return dict(mapping)  # type: ignore[arg-type]


def _unified_property_name(prop_a: str, prop_b: str) -> str:
    clean_a = _clean_property_name(prop_a)
    clean_b = _clean_property_name(prop_b)
    return clean_a if clean_a == clean_b else f"{clean_a}_{clean_b}"


def build_property_pushout_maps(
    map_g_to_a: PropertyMap = None,
    map_g_to_b: PropertyMap = None,
) -> dict[str, dict[str, str]]:
    """Build source-property -> blend-property maps from G->A and G->B morphisms."""
    prop_map_a = _property_mapping(map_g_to_a)
    prop_map_b = _property_mapping(map_g_to_b)
    source_a: dict[str, str] = {}
    source_b: dict[str, str] = {}

    for generic_prop, target_a in prop_map_a.items():
        if generic_prop not in prop_map_b:
            continue
        target_b = prop_map_b[generic_prop]
        unified = _unified_property_name(target_a, target_b)
        source_a[_clean_property_name(target_a)] = unified
        source_b[_clean_property_name(target_b)] = unified

    return {"A": source_a, "B": source_b}


def _world_labels(universe: frozenset[WorldAtom] | None) -> set[str]:
    if not universe:
        return set()
    return {atom.label for atom in universe}


def _combined_universe(
    concept_a: VPredicateConcept,
    concept_b: VPredicateConcept,
    concept_g: VPredicateConcept | None,
    world_specs: WorldSpecRegistry | None,
) -> tuple[str, ...]:
    names = set()
    names.update(_world_labels(concept_a.universal_set))
    names.update(_world_labels(concept_b.universal_set))
    if concept_g is not None:
        names.update(_world_labels(concept_g.universal_set))
    if world_specs is not None:
        names.update(world_specs.names)
    return tuple(sorted(names))


def _rebase_concept(concept: VPredicateConcept, universe: tuple[str, ...]) -> VPredicateConcept:
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


def _concept_weakness(concept: VPredicateConcept, universe: tuple[str, ...]) -> ProductQuantale:
    if not concept.entries:
        return ProductQuantale.bottom(universe)
    return concept.weakness(lambda _prop: ProductQuantale.unit(universe))


def _add_property_to_blend(
    blend: VPredicateConcept,
    prop_name: str,
    quantale: ProductQuantale,
) -> None:
    if prop_name in blend.entries:
        existing = blend.get_property(prop_name)
        blend.add_property(prop_name, existing + quantale, overwrite=True)
    else:
        blend.add_property(prop_name, quantale)


def compute_quantale_colimit(
    concept_a: VPredicateConcept,
    concept_b: VPredicateConcept,
    concept_g: VPredicateConcept | None = None,
    map_g_to_a: PropertyMap = None,
    map_g_to_b: PropertyMap = None,
    *,
    blend_name: str = "BlendedConcept",
    world_specs: WorldSpecRegistry | None = None,
) -> QuantaleColimitResult:
    """Compute the property-level V-predicate pushout/colimit.

    The quantale merge policy is:
    - mapped properties are identified by the G->A and G->B morphisms;
    - colliding property values are joined with ``⊕``;
    - independent properties are freely carried into the blend.
    """
    universe = _combined_universe(concept_a, concept_b, concept_g, world_specs)
    if not universe:
        raise ValueError("Cannot compute a quantale colimit without a known world universe W.")

    registry = world_specs or WorldSpecRegistry()
    registry = registry.ensure_worlds(universe)

    aligned_a = _rebase_concept(concept_a, universe)
    aligned_b = _rebase_concept(concept_b, universe)
    aligned_g = _rebase_concept(concept_g, universe) if concept_g is not None else None

    property_maps = build_property_pushout_maps(map_g_to_a, map_g_to_b)
    blend = VPredicateConcept(blend_name, universal_set=universe)
    contributions: dict[str, list[PropertyContribution]] = {}

    for source_label, concept, source_map in (
        ("A", aligned_a, property_maps["A"]),
        ("B", aligned_b, property_maps["B"]),
    ):
        for prop_name, entry in concept.entries.items():
            blend_prop = source_map.get(prop_name, prop_name)
            _add_property_to_blend(blend, blend_prop, entry.quantale)
            contributions.setdefault(blend_prop, []).append(
                PropertyContribution(concept.name, prop_name, blend_prop)
            )

    weakness_a = _concept_weakness(aligned_a, universe)
    weakness_b = _concept_weakness(aligned_b, universe)
    weakness_c = _concept_weakness(blend, universe)
    intensity_a = weakness_a >> weakness_c
    intensity_b = weakness_b >> weakness_c
    joint_intensity = (weakness_a * weakness_b) >> weakness_c
    synergy = (intensity_a * intensity_b) >> joint_intensity

    shared_properties = sum(1 for props in contributions.values() if len(props) > 1)
    metrics = {
        "WeaknessA": weakness_a,
        "WeaknessB": weakness_b,
        "WeaknessBlend": weakness_c,
        "PatternIntensityA": intensity_a,
        "PatternIntensityB": intensity_b,
        "JointPatternIntensity": joint_intensity,
        "Synergy": synergy,
        "RichnessTV": round(weakness_c.tv.value, 6),
        "SynergyTV": round(synergy.tv.value, 6),
        "PropertyCount": len(blend.entries),
        "SharedPropertyCount": shared_properties,
        "WorldCount": len(universe),
    }
    if aligned_g is not None:
        metrics["WeaknessGeneric"] = _concept_weakness(aligned_g, universe)

    return QuantaleColimitResult(
        blend=blend,
        world_specs=registry,
        property_maps=property_maps,
        contributions=contributions,
        metrics=metrics,
    )


def compute_quantale_colimit_from_strings(
    concept_a_source: str,
    concept_b_source: str,
    concept_g_source: str | None = None,
    *,
    world_specs_source: str = "",
    map_g_to_a: PropertyMap = None,
    map_g_to_b: PropertyMap = None,
    blend_name: str = "BlendedConcept",
) -> QuantaleColimitResult:
    """Parse V-predicate documents and compute their quantale colimit."""
    shared_doc = parse_v_predicate_document(world_specs_source) if world_specs_source.strip() else None
    doc_a = parse_v_predicate_document(concept_a_source)
    doc_b = parse_v_predicate_document(concept_b_source)
    doc_g = parse_v_predicate_document(concept_g_source) if concept_g_source else None

    if len(doc_a.concepts) != 1:
        raise ValueError("concept_a_source must contain exactly one V-predicate Concept.")
    if len(doc_b.concepts) != 1:
        raise ValueError("concept_b_source must contain exactly one V-predicate Concept.")
    if doc_g is not None and len(doc_g.concepts) != 1:
        raise ValueError("concept_g_source must contain exactly one V-predicate Concept when provided.")

    registry = WorldSpecRegistry()
    for doc in (shared_doc, doc_a, doc_b, doc_g):
        if doc is not None:
            registry = registry.merge(doc.world_specs, overwrite=True)

    return compute_quantale_colimit(
        doc_a.concepts[0],
        doc_b.concepts[0],
        doc_g.concepts[0] if doc_g is not None else None,
        map_g_to_a,
        map_g_to_b,
        blend_name=blend_name,
        world_specs=registry,
    )
