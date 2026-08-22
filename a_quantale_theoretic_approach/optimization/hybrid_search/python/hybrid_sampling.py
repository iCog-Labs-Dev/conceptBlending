"""Representation helpers for one-shot habit-biased population sampling."""

from __future__ import annotations

import functools
import hashlib
import math
import os
import random
import re
import time
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


_STAGE_STARTED = time.perf_counter()
_STAGE_LAST = _STAGE_STARTED
_STAGE_VISITS = {}


def stage_log(stage):
    """Emit bounded progress/timing output for PeTTa's relational lifecycle."""
    global _STAGE_STARTED, _STAGE_LAST
    name = str(stage).strip("'\"")
    now = time.perf_counter()
    if name == "initialization_started":
        _STAGE_STARTED = now
        _STAGE_LAST = now
        _STAGE_VISITS.clear()
    count = _STAGE_VISITS.get(name, 0) + 1
    _STAGE_VISITS[name] = count
    if count == 1 or count in (10, 100, 1000, 10000):
        print(
            f"[HYBRID][STAGE] {name} visit={count} "
            f"elapsed={now - _STAGE_STARTED:.3f}s delta={now - _STAGE_LAST:.3f}s",
            flush=True,
        )
        _STAGE_LAST = now
    return True


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
            f"(V-predicate (Property ({props}))))")


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
    entries = block[1:]
    if (len(entries) == 1 and isinstance(entries[0], list)
            and (not entries[0] or isinstance(entries[0][0], list))):
        entries = entries[0]
    properties = []
    for entry in entries:
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


@functools.lru_cache(maxsize=256)
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


@functools.lru_cache(maxsize=256)
def sampling_plan(generic_result, target, population_size=10,
                  sigma=0.15, betas="(0 0.25 0.5 0.75 1)"):
    """Describe five fixed CMA distributions without drawing any samples."""
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
    sigma = _float(sigma, "sigma")
    if sigma < 0:
        raise HybridInitializationError("sigma cannot be negative")
    covariance, subproblems = _covariance(len(schema)), []
    for subproblem, beta in enumerate(beta_values):
        mean = [(1-beta)*a + beta*h for a, h in zip(base, habit)]
        subproblems.append(f"(SamplingSubproblem {subproblem} (HabitBias {beta:.12g}) "
                           f"(Mean ({' '.join(f'{x:.12g}' for x in mean)})) "
                           f"(Covariance {covariance}) (StepSize {sigma:.12g}))")
    return (f"(HabitBiasedSamplingPlan Ready "
            f"(CandidateSchema {' '.join(map(_ma, schema))}) "
            f"(InitialMean ({' '.join(f'{x:.12g}' for x in base)})) "
            f"(HabitVector ({' '.join(f'{x:.12g}' for x in habit)})) "
            f"(Subproblems {' '.join(subproblems)}))")


def _sampling_plan(value):
    node = _one(value, "HabitBiasedSamplingPlan")
    schema = tuple(map(_atom, node[2][1:]))
    subproblems = node[5]
    if not schema or subproblems[0] != "Subproblems" or len(subproblems) != 6:
        raise HybridInitializationError("invalid five-subproblem sampling plan")
    return node, schema


def _cholesky(matrix):
    size = len(matrix)
    lower = [[0.0] * size for _ in range(size)]
    for row in range(size):
        for column in range(row + 1):
            residual = matrix[row][column] - sum(
                lower[row][k] * lower[column][k] for k in range(column)
            )
            if row == column:
                if residual <= 0:
                    raise HybridInitializationError("covariance must be positive definite")
                lower[row][column] = math.sqrt(residual)
            else:
                lower[row][column] = residual / lower[column][column]
    return lower


@functools.lru_cache(maxsize=256)
def sample_subproblems(plan, seed):
    """Draw exactly one seeded five-by-ten sample batch from a PeTTa plan."""
    plan_node, schema = _sampling_plan(plan)
    rng = random.Random(_int(seed, "seed"))
    sampled = []
    for subproblem in plan_node[5][1:]:
        index = _int(subproblem[1], "subproblem index")
        mean = [_float(value, "mean") for value in subproblem[3][1]]
        covariance = [
            [_float(value, "covariance") for value in row]
            for row in subproblem[4][1]
        ]
        step_size = _float(subproblem[5][1], "step size")
        if len(mean) != len(schema) or len(covariance) != len(schema):
            raise HybridInitializationError("sampling-plan dimension mismatch")
        if any(len(row) != len(schema) for row in covariance):
            raise HybridInitializationError("covariance must be square")
        lower = _cholesky(covariance)
        rows = []
        for _ in range(10):
            standard = [rng.gauss(0.0, 1.0) for _ in schema]
            vector = []
            for coordinate, center in enumerate(mean):
                noise = sum(
                    lower[coordinate][k] * standard[k]
                    for k in range(coordinate + 1)
                )
                vector.append(min(0.99, max(0.01, center + step_size * noise)))
            rows.append(vector)
        sampled.append(["SampledSubproblem", str(index), rows])
    return flatten_sexpr(["SampledSubproblems", sampled])


@functools.lru_cache(maxsize=256)
def sample_five_populations(generic_result, target, seed):
    """Build, draw, and materialize one deterministic five-population batch."""
    plan = sampling_plan(generic_result, target, 10, 0.15, "(0 0.25 0.5 0.75 1)")
    sampled = sample_subproblems(plan, seed)
    return materialize_populations(generic_result, plan, sampled)


def materialize_populations(generic_result, plan, sampled_subproblems):
    """Wrap vectors drawn from the PeTTa-authored sampling plan."""
    concept, _ = _generic_result(generic_result)
    plan_node, schema = _sampling_plan(plan)
    root = _one(sampled_subproblems, "SampledSubproblems")
    blocks = root[1:]
    if (len(blocks) == 1 and isinstance(blocks[0], list)
            and blocks[0] and isinstance(blocks[0][0], list)):
        blocks = blocks[0]
    samples_by_index = {}
    for block in blocks:
        if not isinstance(block, list) or len(block) != 3 or block[0] != "SampledSubproblem":
            raise HybridInitializationError("invalid sampled subproblem")
        index = _int(block[1], "subproblem index")
        rows = block[2]
        if not isinstance(rows, list) or len(rows) != 10:
            raise HybridInitializationError("each subproblem must contain ten samples")
        vectors = []
        for row in rows:
            if not isinstance(row, list) or len(row) != len(schema):
                raise HybridInitializationError("sample dimension differs from candidate schema")
            vector = tuple(_float(value, "sample coordinate") for value in row)
            if any(not 0 <= value <= 1 for value in vector):
                raise HybridInitializationError("PeTTa sample coordinate outside [0,1]")
            vectors.append(vector)
        samples_by_index[index] = vectors
    if set(samples_by_index) != set(range(5)):
        raise HybridInitializationError("expected samples for subproblems 0 through 4")
    worlds = {p.name: p.worlds for p in concept.properties}
    populations = []
    for subproblem in plan_node[5][1:]:
        index = _int(subproblem[1], "subproblem index")
        candidates = []
        for individual, vector in enumerate(samples_by_index[index]):
            predicate = _concept_text(Concept(
                f"{concept.name}_s{index}_i{individual}", concept.perspective,
                tuple(Property(name, worlds[name], value)
                      for name, value in zip(schema, vector))))
            candidates.append(f"(SampledCandidate {index} {individual} "
                              f"(Vector ({' '.join(f'{x:.12g}' for x in vector)})) {predicate})")
        populations.append(
            f"(SubproblemPopulation {index} {flatten_sexpr(subproblem[2])} "
            f"{flatten_sexpr(subproblem[3])} {flatten_sexpr(subproblem[4])} "
            f"{flatten_sexpr(subproblem[5])} (Population ({' '.join(candidates)})))"
        )
    return (f"(HabitBiasedPopulationInitialization Ready "
            f"{flatten_sexpr(plan_node[2])} {flatten_sexpr(plan_node[3])} "
            f"{flatten_sexpr(plan_node[4])} (Sampler random-multivariate) "
            f"(Subproblems ({' '.join(populations)})))")


def seed_multivariate_stream(seed):
    """Seed the scalar-normal stream consumed by PeTTa standard-normal."""
    random.seed(_int(seed, "seed"))
    return True


def population_count(value):
    node = _one(value, "HabitBiasedPopulationInitialization")
    block = next(x for x in node if isinstance(x, list) and x and x[0] == "Subproblems")
    subproblems = block[1]
    if not (len(block) == 2 and isinstance(subproblems, list)
            and (not subproblems or isinstance(subproblems[0], list))):
        subproblems = block[1:]
    return len(subproblems)


def individual_counts(value):
    node = _one(value, "HabitBiasedPopulationInitialization")
    block = next(x for x in node if isinstance(x, list) and x and x[0] == "Subproblems")
    subproblems = block[1]
    if not (len(block) == 2 and isinstance(subproblems, list)
            and (not subproblems or isinstance(subproblems[0], list))):
        subproblems = block[1:]
    counts = []
    for subproblem in subproblems:
        population = next(x for x in subproblem if isinstance(x, list) and x and x[0] == "Population")
        candidates = population[1]
        if not (len(population) == 2 and isinstance(candidates, list)
                and (not candidates or isinstance(candidates[0], list))):
            candidates = population[1:]
        counts.append(len(candidates))
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
        "hs_sampling_plan": sampling_plan,
        "hs_sample_subproblems": sample_subproblems,
        "hs_sample_five_populations": sample_five_populations,
        "hs_materialize_populations": materialize_populations,
        "hs_seed_multivariate_stream": seed_multivariate_stream,
        "hs_population_count": population_count,
        "hs_individual_counts": individual_counts,
        "hs_stage_log": stage_log,
        "habit_load_evidence": importlib.import_module("atomspace_evidence").load_evidence,
    }
    exports["apply_args"] = lambda function, args: function(*args)
    exports["cma_random_normal"] = lambda args: random.gauss(*args)
    for name, function in exports.items():
        setattr(builtins, name, function)
    return True
