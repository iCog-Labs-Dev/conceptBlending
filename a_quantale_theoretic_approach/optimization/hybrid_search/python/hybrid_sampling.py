"""Representation helpers for one-shot habit-biased population sampling."""

from __future__ import annotations

import hashlib
import math
import os
import random
import re
from dataclasses import dataclass
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[4]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from a_quantale_theoretic_approach.core_representation.sexpr import (  # noqa: E402
    atom_name, flatten_sexpr, parse_s_expr,
)


class HybridInitializationError(ValueError):
    pass


SAFE = re.compile(r"^[a-z_][a-zA-Z0-9_@-]*$")


@dataclass(frozen=True)
class Property:
    name: str
    worlds: tuple[str, ...]
    degree: float


@dataclass(frozen=True)
class Concept:
    name: str
    perspective: str
    properties: tuple[Property, ...]


def _one(value, tag=None):
    parsed = parse_s_expr(str(value).strip())
    if len(parsed) != 1 or not isinstance(parsed[0], list):
        raise HybridInitializationError("expected one S-expression")
    node = parsed[0]
    if tag and (not node or atom_name(node[0]) != tag):
        raise HybridInitializationError(f"expected {tag}")
    return node


def _atom(value, label="value"):
    try:
        return atom_name(value)
    except TypeError as exc:
        raise HybridInitializationError(f"{label} must be an atom") from exc


def _float(value, label):
    try:
        result = float(str(value))
    except (TypeError, ValueError) as exc:
        raise HybridInitializationError(f"{label} must be scalar") from exc
    if not math.isfinite(result):
        raise HybridInitializationError(f"{label} must be finite")
    return result


def _int(value, label):
    result = _float(value, label)
    if not result.is_integer():
        raise HybridInitializationError(f"{label} must be integral")
    return int(result)


def _ma(value):
    value = str(value)
    if SAFE.fullmatch(value):
        return value
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def _stable_scalar(seed, *parts, low, high):
    digest = hashlib.sha256("\x1f".join((str(seed), *parts)).encode()).digest()
    unit = int.from_bytes(digest[:8], "big") / ((1 << 64) - 1)
    return low + (high - low) * unit


def _concept_text(concept):
    props = " ".join(
        f"({_ma(p.name)} (WorldSpecSet ({' '.join(_ma(w) for w in p.worlds)})) {p.degree:.12g})"
        for p in concept.properties
    )
    return (f"(Concept {_ma(concept.name)} {_ma(concept.perspective)} "
            f"(V-predicate (Property {props})))")


def _compact(value):
    node = _one(value, "Concept")
    if len(node) != 4 or not isinstance(node[3], list) or node[3][0] != "Properties":
        raise HybridInitializationError("invalid compact V-predicate")
    result = []
    for entry in node[3][1:]:
        if not isinstance(entry, list) or len(entry) != 2:
            raise HybridInitializationError("invalid compact property")
        prop, worlds = entry
        if not isinstance(prop, list) or len(prop) != 1 or not isinstance(worlds, list):
            raise HybridInitializationError("invalid compact property/world wrapper")
        names = []
        for world in worlds:
            if not isinstance(world, list) or len(world) != 1:
                raise HybridInitializationError("invalid compact world")
            name = _atom(world[0], "world")
            if name not in names:
                names.append(name)
        result.append((_atom(prop[0], "property"), names))
    return _atom(node[1]), _atom(node[2]), result


def _concept(value):
    node = _one(value, "Concept")
    if len(node) != 4:
        raise HybridInitializationError("V-predicate must retain perspective")
    body = node[3]
    if not isinstance(body, list) or len(body) != 2 or body[0] != "V-predicate":
        raise HybridInitializationError("missing V-predicate")
    block = body[1]
    if not isinstance(block, list) or not block or block[0] != "Property":
        raise HybridInitializationError("missing Property block")
    properties = []
    for entry in block[1:]:
        if not isinstance(entry, list) or len(entry) != 3:
            raise HybridInitializationError("property degree must be one scalar")
        world_set = entry[1]
        if not isinstance(world_set, list) or len(world_set) != 2 or world_set[0] != "WorldSpecSet":
            raise HybridInitializationError("invalid WorldSpecSet")
        degree = _float(entry[2], "property degree")
        if not 0 <= degree <= 1:
            raise HybridInitializationError("property degree outside [0,1]")
        properties.append(Property(_atom(entry[0]), tuple(map(_atom, world_set[1])), degree))
    return Concept(_atom(node[1]), _atom(node[2]), tuple(properties))


def enrich_compact_vpredicate(compact, seed=0, low=0.05, high=0.95):
    seed, low, high = _int(seed, "seed"), _float(low, "low"), _float(high, "high")
    if not 0 <= low < high <= 1:
        raise HybridInitializationError("require 0 <= low < high <= 1")
    name, perspective, properties = _compact(compact)
    decorated = tuple(Property(prop, tuple(worlds), _stable_scalar(
        seed, name, perspective, prop, low=low, high=high
    )) for prop, worlds in properties)
    return _concept_text(Concept(name, perspective, decorated))


def source_property_names(source_a, source_b):
    names = []
    for prop in (*_concept(source_a).properties, *_concept(source_b).properties):
        if prop.name not in names:
            names.append(prop.name)
    return f"({' '.join(map(_ma, names))})"


def property_pair_requests(source_a, source_b):
    left, right = _concept(source_a), _concept(source_b)
    if left.perspective != right.perspective:
        raise HybridInitializationError("source perspectives differ")
    requests = [["PairRequest", ["PropertyPairId", a.name, b.name], a.name, b.name]
                for a in left.properties for b in right.properties]
    return f"(PairRequests {' '.join(map(flatten_sexpr, requests))})"


def _resolution_nodes(value):
    root = _one(value)
    raw = root[1:] if root and root[0] in {
        "PairResolutions", "PropertyResolutions", "WorldResolutions"
    } else root
    if len(raw) == 1 and isinstance(raw[0], list) and raw[0] and isinstance(raw[0][0], list):
        raw = raw[0]
    return [x for x in raw if isinstance(x, list) and x and x[0] == "PairResolution"]


def _property_resolutions(value):
    result = []
    for item in _resolution_nodes(value):
        request = item[1] if len(item) >= 3 else None
        if not isinstance(request, list) or len(request) != 3 or request[0] != "PropertyPairId":
            continue
        row = (_atom(item[2]), _atom(request[1]), _atom(request[2]))
        if row not in result:
            result.append(row)
    return result


def world_pair_requests(source_a, source_b, property_resolutions):
    left, right = _concept(source_a), _concept(source_b)
    by_a = {p.name: p for p in left.properties}
    by_b = {p.name: p for p in right.properties}
    requests, seen = [], set()
    for generic, name_a, name_b in _property_resolutions(property_resolutions):
        if name_a not in by_a or name_b not in by_b:
            raise HybridInitializationError("property resolution/source mismatch")
        for world_a in by_a[name_a].worlds:
            for world_b in by_b[name_b].worlds:
                key = (generic, name_a, name_b, world_a, world_b)
                if key not in seen:
                    seen.add(key)
                    requests.append(["PairRequest", ["WorldPairId", *key], world_a, world_b])
    return f"(PairRequests {' '.join(map(flatten_sexpr, requests))})"


def generic_vpredicate_result(generic_name, perspective, property_resolutions,
                              world_mappings, seed=0, low=0.05, high=0.95):
    """Build a generic predicate only from worlds with materialized specs."""
    name, view = str(generic_name), str(perspective)
    seed, low, high = _int(seed, "seed"), _float(low, "low"), _float(high, "high")
    mappings = _property_resolutions(property_resolutions)
    root = _one(world_mappings)
    raw = root[1:] if root and root[0] == "WorldMappings" else root
    if len(raw) == 1 and isinstance(raw[0], list) and (not raw[0] or isinstance(raw[0][0], list)):
        raw = raw[0]
    worlds, valid = {}, []
    for item in raw:
        if isinstance(item, list) and len(item) == 7 and item[0] == "GenericWorldMapping":
            generic_world, generic_property = _atom(item[1]), _atom(item[2])
            worlds.setdefault(generic_property, [])
            if generic_world not in worlds[generic_property]:
                worlds[generic_property].append(generic_world)
            valid.append(item)
    properties, unresolved, seen = [], [], set()
    for generic, _, _ in mappings:
        if generic in seen:
            continue
        seen.add(generic)
        if not worlds.get(generic):
            unresolved.append(["GenericPropertyWithoutWorld", generic])
            continue
        properties.append(Property(generic, tuple(worlds[generic]), _stable_scalar(
            seed, name, view, generic, low=low, high=high)))
    concept = _concept_text(Concept(name, view, tuple(properties)))
    prop_maps = [["GenericPropertyMapping", *row] for row in mappings]
    status = "Ready" if properties and not unresolved else "Partial"
    return (f"(GenericVPredicateResult {concept} "
            f"(PropertyMappings {' '.join(map(flatten_sexpr, prop_maps))}) "
            f"(WorldMappings {' '.join(map(flatten_sexpr, valid))}) "
            f"(Unresolved {' '.join(map(flatten_sexpr, unresolved))}) {status})")


def _generic_result(value):
    node = _one(value, "GenericVPredicateResult")
    concept, mappings = _concept(flatten_sexpr(node[1])), []
    for item in node[2][1:]:
        if isinstance(item, list) and len(item) == 4 and item[0] == "GenericPropertyMapping":
            mappings.append(tuple(map(_atom, item[1:])))
    return concept, mappings


def habit_target(source_a, source_b, generic_result, strengths, kappa=0.5):
    """Construct h_i = s_i + kappa M_i (1-s_i), all scalar-valued."""
    left, right = _concept(source_a), _concept(source_b)
    _, mappings = _generic_result(generic_result)
    degrees_a = {p.name: p.degree for p in left.properties}
    degrees_b = {p.name: p.degree for p in right.properties}
    kappa = _float(kappa, "kappa")
    if not 0 <= kappa <= 1:
        raise HybridInitializationError("kappa outside [0,1]")
    root = _one(strengths)
    raw = root[1:] if root and root[0] == "HabitStrengths" else root
    if len(raw) == 1 and isinstance(raw[0], list) and (not raw[0] or isinstance(raw[0][0], list)):
        raw = raw[0]
    values = {}
    for item in raw:
        if isinstance(item, list) and len(item) == 5 and item[0] == "HabitStrength":
            values[tuple(map(_atom, item[1:4]))] = max(0.0, min(1.0, _float(item[4], "M_P")))
    aggregate, evidence = {}, []
    for generic, prop_a, prop_b in mappings:
        support = max(degrees_a[prop_a], degrees_b[prop_b])
        strength = values.get((generic, prop_a, prop_b), 0.0)
        target = support + kappa * strength * (1.0 - support)
        evidence.append(["HabitTargetEvidence", generic, prop_a, prop_b,
                         f"{support:.12g}", f"{strength:.12g}", f"{target:.12g}"])
        old = aggregate.get(generic, (0.0, 0.0))
        aggregate[generic] = (max(old[0], support), max(old[1], target))
    entries = [["HabitTargetEntry", name, f"{base:.12g}", f"{target:.12g}"]
               for name, (base, target) in aggregate.items()]
    return (f"(HabitTarget (Entries {' '.join(map(flatten_sexpr, entries))}) "
            f"(Evidence {' '.join(map(flatten_sexpr, evidence))}))")


def _target_entries(value):
    node = _one(value, "HabitTarget")
    if len(node) < 2 or node[1][0] != "Entries":
        raise HybridInitializationError("HabitTarget has no Entries")
    return [(_atom(x[1]), _float(x[2], "support"), _float(x[3], "target"))
            for x in node[1][1:] if isinstance(x, list) and len(x) == 4]


def _covariance(size):
    rows = [f"({' '.join('1' if i == j else '0' for j in range(size))})"
            for i in range(size)]
    return f"({' '.join(rows)})"


def sample_populations(generic_result, target, seed=0, population_size=10,
                       sigma=0.15, betas="(0 0.25 0.5 0.75 1)"):
    """Sample five populations once; this function mutates no CMA state."""
    concept, _ = _generic_result(generic_result)
    target_map = {name: (base, habit) for name, base, habit in _target_entries(target)}
    schema = [p.name for p in concept.properties if p.name in target_map]
    if not schema:
        raise HybridInitializationError("generic predicate and target do not overlap")
    base = [target_map[name][0] for name in schema]
    habit = [target_map[name][1] for name in schema]
    beta_values = [_float(x, "beta") for x in _one(betas)]
    if len(beta_values) != 5 or any(not 0 <= x <= 1 for x in beta_values):
        raise HybridInitializationError("exactly five beta values are required")
    if _int(population_size, "population_size") != 10:
        raise HybridInitializationError("exactly ten individuals are required")
    sigma, seed = _float(sigma, "sigma"), _int(seed, "seed")
    if sigma < 0:
        raise HybridInitializationError("sigma cannot be negative")
    worlds = {p.name: p.worlds for p in concept.properties}
    covariance, subproblems = _covariance(len(schema)), []
    for subproblem, beta in enumerate(beta_values):
        mean = [(1-beta)*a + beta*h for a, h in zip(base, habit)]
        stream_seed = int.from_bytes(hashlib.sha256(
            f"{seed}:subproblem:{subproblem}".encode()).digest()[:8], "big")
        rng, candidates = random.Random(stream_seed), []
        for individual in range(10):
            vector = [max(0.01, min(0.99, rng.gauss(x, sigma))) for x in mean]
            predicate = _concept_text(Concept(
                f"{concept.name}_s{subproblem}_i{individual}", concept.perspective,
                tuple(Property(name, worlds[name], value)
                      for name, value in zip(schema, vector))))
            candidates.append(f"(SampledCandidate {subproblem} {individual} "
                              f"(Vector ({' '.join(f'{x:.12g}' for x in vector)})) {predicate})")
        subproblems.append(f"(SubproblemPopulation {subproblem} (HabitBias {beta:.12g}) "
                           f"(Mean ({' '.join(f'{x:.12g}' for x in mean)})) "
                           f"(Covariance {covariance}) (StepSize {sigma:.12g}) "
                           f"(Population {' '.join(candidates)}))")
    return (f"(HabitBiasedPopulationInitialization Ready "
            f"(CandidateSchema {' '.join(map(_ma, schema))}) "
            f"(InitialMean ({' '.join(f'{x:.12g}' for x in base)})) "
            f"(HabitVector ({' '.join(f'{x:.12g}' for x in habit)})) "
            f"(Subproblems {' '.join(subproblems)}))")


def population_count(value):
    node = _one(value, "HabitBiasedPopulationInitialization")
    block = next(x for x in node if isinstance(x, list) and x and x[0] == "Subproblems")
    return len(block) - 1


def individual_counts(value):
    node = _one(value, "HabitBiasedPopulationInitialization")
    block = next(x for x in node if isinstance(x, list) and x and x[0] == "Subproblems")
    counts = []
    for subproblem in block[1:]:
        population = next(x for x in subproblem if isinstance(x, list) and x and x[0] == "Population")
        counts.append(len(population) - 1)
    return f"({' '.join(map(str, counts))})"


def register_petta_builtins():
    """Register the complete Python bridge used by the PeTTa component."""
    import builtins
    import importlib

    habit_root = ROOT / "habit_memory"
    os.environ.setdefault(
        "V_PREDICATE_PIPELINE_ROOT",
        str(ROOT / "a_quantale_theoretic_approach" / "v-predicate-extraction-pipeline"),
    )
    if str(habit_root) not in sys.path:
        sys.path.insert(0, str(habit_root))
    exports = {
        "hs_enrich_compact_vpredicate": enrich_compact_vpredicate,
        "hs_property_pair_requests": property_pair_requests,
        "hs_world_pair_requests": world_pair_requests,
        "hs_generic_vpredicate_result": generic_vpredicate_result,
        "hs_habit_target": habit_target,
        "hs_source_property_names": source_property_names,
        "hs_sample_populations": sample_populations,
        "hs_population_count": population_count,
        "hs_individual_counts": individual_counts,
        "habit_load_evidence": importlib.import_module("atomspace_evidence").load_evidence,
    }
    for name, function in exports.items():
        setattr(builtins, name, function)
    return True
