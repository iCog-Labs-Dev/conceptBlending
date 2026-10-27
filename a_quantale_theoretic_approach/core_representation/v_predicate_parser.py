"""Parser for paper-style V-predicate concepts and WorldSpec declarations."""

from __future__ import annotations

from dataclasses import dataclass

from .product_quantale import ProductQuantale
from .sexpr import AtomTree, atom_name, find_tagged, parse_s_expr
from .v_predicate import VPredicateConcept
from .world_spec import WorldSpec, WorldSpecRegistry


@dataclass(frozen=True)
class VPredicateDocument:
    """Parsed quantale representation document."""

    concepts: tuple[VPredicateConcept, ...]
    world_specs: WorldSpecRegistry


def _as_list(node: AtomTree, context: str) -> list[AtomTree]:
    if not isinstance(node, list):
        raise ValueError(f"Expected list for {context}.")
    return node


def _find_child(tree: list[AtomTree], tag: str) -> list[AtomTree] | None:
    for child in tree:
        if isinstance(child, list) and child and child[0] == tag:
            return child
    return None


def _world_names_from_set(node: list[AtomTree]) -> tuple[str, ...]:
    if not node or node[0] != "WorldSpecSet":
        raise ValueError("Expected (WorldSpecSet (...)).")
    if len(node) == 1:
        return ()
    raw_worlds = node[1]
    if raw_worlds == []:
        return ()
    worlds = _as_list(raw_worlds, "WorldSpecSet contents")
    return tuple(atom_name(world) for world in worlds)


def _property_nodes(concept_tree: list[AtomTree]) -> list[list[AtomTree]]:
    v_predicate = _find_child(concept_tree, "V-predicate")
    if v_predicate is None:
        raise ValueError("Concept does not contain a V-predicate block.")
    property_block = _find_child(v_predicate, "Property")
    if property_block is None:
        raise ValueError("V-predicate does not contain a Property block.")
    return [_as_list(node, "property entry") for node in property_block[1:]]


def parse_world_specs(source: str) -> WorldSpecRegistry:
    expressions = parse_s_expr(source)
    specs = [WorldSpec.from_tree(tree) for tree in find_tagged(expressions, "WorldSpec")]
    return WorldSpecRegistry(specs)


def parse_v_predicate_concept(
    source: str | list[AtomTree],
    *,
    world_specs: WorldSpecRegistry | None = None,
    universal_set: tuple[str, ...] | list[str] | set[str] | None = None,
) -> VPredicateConcept:
    """Parse one ``(Concept ... (V-predicate ...))`` expression."""
    if isinstance(source, str):
        expressions = parse_s_expr(source)
        concepts = find_tagged(expressions, "Concept")
        if len(concepts) != 1:
            raise ValueError(f"Expected exactly one Concept expression, found {len(concepts)}.")
        concept_tree = concepts[0]
    else:
        concept_tree = source

    if len(concept_tree) < 3 or concept_tree[0] != "Concept":
        raise ValueError("Concept tree must have shape (Concept name (V-predicate ...)).")

    property_nodes = _property_nodes(concept_tree)
    referenced_worlds: set[str] = set()
    parsed_entries: list[tuple[str, tuple[str, ...], float]] = []

    for prop_node in property_nodes:
        if len(prop_node) != 3:
            raise ValueError("Property entry must have shape (property (WorldSpecSet (...)) degree).")
        prop_name = atom_name(prop_node[0])
        worlds = _world_names_from_set(_as_list(prop_node[1], "WorldSpecSet"))
        degree = float(atom_name(prop_node[2]))
        referenced_worlds.update(worlds)
        parsed_entries.append((prop_name, worlds, degree))

    if universal_set is not None:
        universe = tuple(universal_set)
    elif world_specs is not None and len(world_specs) > 0:
        universe = world_specs.names
    else:
        universe = tuple(sorted(referenced_worlds))

    concept = VPredicateConcept(atom_name(concept_tree[1]), universal_set=universe)
    for prop_name, worlds, degree in parsed_entries:
        concept.add_property(
            prop_name,
            ProductQuantale.from_worlds(worlds, degree, universe),
        )
    return concept


def parse_v_predicate_document(source: str) -> VPredicateDocument:
    """Parse a mixed document containing WorldSpec and V-predicate Concept forms."""
    expressions = parse_s_expr(source)
    world_specs = WorldSpecRegistry(
        WorldSpec.from_tree(tree) for tree in find_tagged(expressions, "WorldSpec")
    )
    concept_trees = [
        tree
        for tree in find_tagged(expressions, "Concept")
        if _find_child(tree, "V-predicate") is not None
    ]

    all_worlds = set(world_specs.names)
    for concept_tree in concept_trees:
        for prop_node in _property_nodes(concept_tree):
            all_worlds.update(_world_names_from_set(_as_list(prop_node[1], "WorldSpecSet")))

    completed_registry = world_specs.ensure_worlds(all_worlds)
    concepts = tuple(
        parse_v_predicate_concept(
            concept_tree,
            world_specs=completed_registry,
            universal_set=completed_registry.names,
        )
        for concept_tree in concept_trees
    )
    return VPredicateDocument(concepts=concepts, world_specs=completed_registry)
