#!/usr/bin/env python3
"""Generate a perspective-aware MeTTa property/possible-world KB.

The raw Concept Atomspace is interpreted in two passes:

1. ``hasProperty(concept, property)`` establishes a concept property.
2. Every supported semantic edge whose *target* is that property contributes
   its source as a possible world in which the property is relevant.

The generated KB contains only MeTTa facts.  Python is a streaming build tool,
not a query-time database.
"""

from __future__ import annotations

import argparse
import math
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Iterable

from gen_algebraic_spec_kb import (
    RELATION_ALIASES,
    Record,
    atom_id,
    classify_has_property,
    classify_record,
    fact,
    iter_input_paths,
    parse_float,
    perspective_lines,
    safe_metta_symbol,
    stv_from_weight,
    tokenize_metta_atom,
)


RECORD_METADATA_HEADS = {"source", "target", "relation", "weight", "surfaceText"}


def iter_all_records_from_file(path: Path) -> Iterable[Record]:
    """Read every Concept Atomspace relation, not only algebraic ones."""

    current = None
    order = 0

    def flush():
        if current is None:
            return None
        return Record(
            relation=current["relation"],
            source=safe_metta_symbol(current["source"]),
            target=safe_metta_symbol(current["target"]),
            weight=current["weight"],
            surface_text=current["surface_text"],
            source_file=str(path),
            order=current["order"],
        )

    with Path(path).open(encoding="utf-8", errors="replace") as handle:
        for line in handle:
            tokens = tokenize_metta_atom(line)
            if not tokens:
                continue
            head = tokens[0]
            if head not in RECORD_METADATA_HEADS and len(tokens) >= 3:
                record = flush()
                if record:
                    yield record
                current = {
                    "relation": RELATION_ALIASES.get(head, safe_metta_symbol(head)),
                    "source": tokens[1],
                    "target": tokens[2],
                    "weight": 1.0,
                    "surface_text": "",
                    "order": order,
                }
                order += 1
                continue
            if current is None:
                continue
            if head == "weight" and len(tokens) >= 3:
                current["weight"] = parse_float(tokens[-1], current["weight"])
            elif head == "surfaceText" and len(tokens) >= 3:
                current["surface_text"] = tokens[-1]

    record = flush()
    if record:
        yield record


def iter_all_records(inputs: Iterable[str]) -> Iterable[Record]:
    for path in iter_input_paths(inputs):
        yield from iter_all_records_from_file(path)


@dataclass(frozen=True)
class PropertyEvidence:
    concept: str
    property_name: str
    property_id: str
    perspective: str
    record: Record
    score: float


@dataclass(frozen=True)
class WorldCandidate:
    evidence: PropertyEvidence
    record: Record
    score: float


@dataclass(frozen=True)
class ScoredWorldRecord:
    record: Record
    score: float


MAX_PROPERTIES_PER_PERSPECTIVE = 24
MAX_WORLDS_PER_PROPERTY = 8
MAX_SHARED_PROPERTY_SUPPORT = 64
PROPERTY_CANDIDATE_BUFFER = MAX_PROPERTIES_PER_PERSPECTIVE * 4
WORLD_CANDIDATE_BUFFER = MAX_WORLDS_PER_PROPERTY * 4

PERSPECTIVE_PRIORITY = {
    "functional-use": 0,
    "information-computational": 1,
    "behavioral-process": 2,
    "structural-composition": 3,
    "physical-attribute": 4,
    "safety-risk": 5,
    "state-lifecycle": 6,
    "spatial-context": 7,
    "temporal-context": 8,
    "economic-ownership": 9,
    "social-normative": 10,
    "descriptive-property": 11,
}

PROPERTY_RELATION_PERSPECTIVES = {
    "UsedFor": ("functional-use",),
    "CapableOf": ("behavioral-process", "functional-use"),
    "ReceivesAction": ("behavioral-process",),
    "HasA": ("structural-composition",),
    "PartOf": ("structural-composition",),
    "MadeOf": ("structural-composition", "physical-attribute"),
    "AtLocation": ("spatial-context",),
    "LocatedNear": ("spatial-context",),
    "hasPrerequisite": ("causal-prerequisite",),
    "hasSubevent": ("behavioral-process",),
    "Causes": ("behavioral-process",),
    "Entails": ("behavioral-process",),
    "CreatedBy": ("causal-prerequisite",),
    "isA": ("taxonomic-kind",),
    "InstanceOf": ("taxonomic-classification",),
}

PROPERTY_RELATION_PRIOR = {
    "hasproperty": 1.00,
    "UsedFor": 1.00,
    "CapableOf": 0.92,
    "ReceivesAction": 0.78,
    "HasA": 0.94,
    "PartOf": 0.92,
    "MadeOf": 0.94,
    "AtLocation": 0.86,
    "LocatedNear": 0.78,
    "hasPrerequisite": 0.90,
    "hasSubevent": 0.92,
    "Causes": 0.84,
    "Entails": 0.84,
    "CreatedBy": 0.82,
    "isA": 0.96,
    "InstanceOf": 0.98,
    "HasContext": 0.72,
    "RelatedTo": 0.50,
}

WORLD_RELATIONS = {
    "descriptive-property": {"hasproperty", "HasContext"},
    "physical-attribute": {"hasproperty", "MadeOf", "HasContext"},
    "functional-use": {"hasproperty", "UsedFor", "CapableOf", "ReceivesAction", "HasContext"},
    "behavioral-process": {"CapableOf", "ReceivesAction", "hasSubevent", "Causes", "Entails"},
    "structural-composition": {"HasA", "PartOf", "MadeOf"},
    "spatial-context": {"AtLocation", "LocatedNear", "HasContext"},
    "causal-prerequisite": {"hasPrerequisite", "Causes", "Entails", "CreatedBy"},
    "taxonomic-classification": {"isA", "InstanceOf"},
    "taxonomic-kind": {"isA", "InstanceOf"},
    "artifact-kind": {"isA", "InstanceOf"},
    "role-kind": {"isA", "InstanceOf"},
    "information-computational": {"UsedFor", "CapableOf", "HasContext"},
    "safety-risk": {"hasproperty", "Causes", "ReceivesAction"},
    "state-lifecycle": {"hasproperty", "Causes", "Entails"},
    "temporal-context": {"hasproperty", "HasContext"},
    "quantitative-comparative": {"hasproperty", "RelatedTo"},
    "social-normative": {"hasproperty", "HasContext", "Causes"},
    "economic-ownership": {"hasproperty", "HasA", "RelatedTo"},
}

LEXICAL_WORLD_RELATIONS = {
    "Synonym", "synonym", "Antonym", "antonym", "FormOf", "formOf",
    "DerivedFrom", "derivedFrom", "EtymologicallyRelatedTo",
    "EtymologicallyDerivedFrom", "DefinedBy", "definedBy", "DistinctFrom",
}

GENERIC_PROPERTY_TARGETS = {
    "be", "being", "do", "doing", "get", "go", "have", "make",
    "something", "thing", "use", "work",
}

NOISY_NAME_MARKERS = {
    "another_word_for", "another_name_for", "sometimes_called", "word_for",
    "one_kind_of", "one_type_of", "plural_of", "singular_of", "spelling",
}

ACTION_LEMMA = {
    "acces": "access",
    "accessing": "access",
    "calculating": "calculate",
    "checking": "check",
    "collecting": "collect",
    "communicating": "communicate",
    "computing": "compute",
    "creating": "create",
    "finding": "find",
    "getting": "get",
    "making": "make",
    "playing": "play",
    "processing": "process",
    "running": "run",
    "storing": "store",
    "surfing": "surf",
    "using": "use",
    "writing": "write",
}

INFORMATION_TARGET_WORDS = {
    "access", "arithmetic", "calculate", "calculation", "communicate",
    "compute", "data", "document", "email", "file", "information",
    "internet", "math", "program", "process", "run", "software", "store",
    "storage", "web", "word",
}

HARMFUL_FUNCTION_TARGETS = {
    "be_destructive", "cause_harm", "do_bad_things", "do_evil",
    "harm_people", "hurt_people",
}


def normalized_relation(record: Record) -> str:
    return RELATION_ALIASES.get(record.relation, record.relation)


def canonical_target(target: str) -> str:
    """Collapse common ConceptNet action spelling/inflection variants."""

    normalized = safe_metta_symbol(target).lower()
    tokens = [token for token in normalized.split("_") if token]
    if not tokens:
        return normalized
    if tokens[0] == "doing" and len(tokens) > 1:
        tokens = tokens[1:]
    tokens[0] = ACTION_LEMMA.get(tokens[0], tokens[0])
    return "_".join(tokens)


def public_property_name(record: Record, perspective: str) -> str:
    target = canonical_target(record.target)
    prefixes = {
        "HasA": "has",
        "PartOf": "part_of",
        "MadeOf": "made_of",
        "AtLocation": "located_at",
        "LocatedNear": "located_near",
        "hasPrerequisite": "requires",
        "hasSubevent": "has_subevent",
        "Causes": "causes",
        "Entails": "entails",
        "CreatedBy": "created_by",
    }
    prefix = prefixes.get(normalized_relation(record))
    return atom_id(prefix, target) if prefix else target


def target_quality(record: Record) -> float:
    target = canonical_target(record.target)
    tokens = tuple(token for token in target.split("_") if token)
    if not target or target in GENERIC_PROPERTY_TARGETS:
        return -1.0
    if any(marker in target for marker in NOISY_NAME_MARKERS):
        return -1.0
    if normalized_relation(record) in {"UsedFor", "CapableOf"}:
        if target in HARMFUL_FUNCTION_TARGETS:
            return -1.0
    if len(tokens) > 7:
        return -0.5
    quality = 0.16 if 1 < len(tokens) <= 4 else 0.0
    if record.relation in {"UsedFor", "CapableOf"} and len(tokens) >= 2:
        quality += 0.12
    return quality


def property_perspectives(record: Record, keep_noisy_targets: bool) -> tuple[str, ...]:
    relation = normalized_relation(record)
    if relation == "hasproperty":
        classification = classify_has_property(record)
        if classification.reject_reason and not keep_noisy_targets:
            return ()
        return (classification.perspective,)
    if relation == "HasContext":
        classification = classify_record(record, keep_noisy_targets=keep_noisy_targets)
        return () if classification.reject_reason else (classification.perspective,)
    if relation == "RelatedTo":
        classification = classify_record(record, keep_noisy_targets=keep_noisy_targets)
        if classification.reject_reason or classification.perspective == "descriptive-property":
            return ()
        return (classification.perspective,)
    perspectives = list(PROPERTY_RELATION_PERSPECTIVES.get(relation, ()))
    if relation in {"UsedFor", "CapableOf"}:
        target_words = set(canonical_target(record.target).split("_"))
        if target_words & INFORMATION_TARGET_WORDS:
            perspectives.append("information-computational")
    return tuple(dict.fromkeys(perspectives))


def prune_ranked_bucket(bucket: dict[str, object], limit: int) -> None:
    """Keep memory bounded while preserving the strongest deterministic entries."""

    if len(bucket) <= limit:
        return
    ranked = sorted(
        bucket.items(),
        key=lambda pair: (-pair[1].score, pair[0]),
    )[: limit // 2]
    bucket.clear()
    bucket.update(ranked)


def collect_properties(records: Iterable[Record], concepts: set[str] | None = None,
                       keep_noisy_targets: bool = False) -> dict[str, list[PropertyEvidence]]:
    grouped: dict[tuple[str, str], dict[str, PropertyEvidence]] = defaultdict(dict)
    for record in records:
        if concepts is not None and record.source not in concepts:
            continue
        quality = target_quality(record)
        if quality < 0 and not keep_noisy_targets:
            continue
        relation = normalized_relation(record)
        for perspective in property_perspectives(record, keep_noisy_targets):
            name = public_property_name(record, perspective)
            property_id = atom_id("property_key", record.source, perspective, name)
            score = (
                PROPERTY_RELATION_PRIOR.get(relation, 0.45)
                + math.log1p(max(record.weight, 0.1)) / 8.0
                + quality
            )
            evidence = PropertyEvidence(record.source, name, property_id, perspective, record, score)
            old = grouped[(record.source, perspective)].get(name)
            if old is None or evidence.score > old.score:
                grouped[(record.source, perspective)][name] = evidence
                prune_ranked_bucket(
                    grouped[(record.source, perspective)],
                    PROPERTY_CANDIDATE_BUFFER,
                )

    by_target: dict[str, list[PropertyEvidence]] = defaultdict(list)
    for group in sorted(grouped):
        ranked = sorted(grouped[group].values(), key=lambda item: (-item.score, item.property_name))
        for evidence in ranked[:MAX_PROPERTIES_PER_PERSPECTIVE]:
            by_target[canonical_target(evidence.record.target)].append(evidence)
    return by_target


def lexical_variant(source: str, property_name: str) -> bool:
    source = source.lower()
    prop = property_name.lower()
    if source == prop:
        return True
    compact_source = source.replace("_", "")
    compact_prop = prop.replace("_", "")
    suffixes = ("er", "est", "ing", "ed", "ly", "ness", "ful", "less", "ship", "s")
    return any(compact_source == compact_prop + suffix for suffix in suffixes)


def world_admissible(evidence: PropertyEvidence, record: Record,
                     include_self_worlds: bool) -> bool:
    relation = normalized_relation(record)
    if relation in LEXICAL_WORLD_RELATIONS:
        return False
    if relation not in WORLD_RELATIONS.get(evidence.perspective, set()):
        return False
    if not include_self_worlds and record.source == evidence.concept:
        return False
    source = safe_metta_symbol(record.source).lower()
    if lexical_variant(source, evidence.property_name):
        return False
    if any(marker in source for marker in NOISY_NAME_MARKERS):
        return False
    tokens = tuple(token for token in source.split("_") if token)
    return 0 < len(tokens) <= 7


def world_score(evidence: PropertyEvidence, record: Record) -> float:
    relation = normalized_relation(record)
    score = PROPERTY_RELATION_PRIOR.get(relation, 0.0)
    score += math.log1p(max(record.weight, 0.1)) / 7.0
    if record.source == evidence.concept:
        score += 0.55
    if relation == normalized_relation(evidence.record):
        score += 0.18
    if 1 < len(record.source.split("_")) <= 4:
        score += 0.08
    return score


def shared_world_admissible(target: str, perspective: str, record: Record) -> bool:
    """Cheap admissibility check independent of a concept-scoped property."""

    relation = normalized_relation(record)
    if relation in LEXICAL_WORLD_RELATIONS:
        return False
    if relation not in WORLD_RELATIONS.get(perspective, set()):
        return False
    source = safe_metta_symbol(record.source).lower()
    if lexical_variant(source, target):
        return False
    if any(marker in source for marker in NOISY_NAME_MARKERS):
        return False
    tokens = tuple(token for token in source.split("_") if token)
    return 0 < len(tokens) <= 7


def shared_world_score(record: Record) -> float:
    relation = normalized_relation(record)
    score = PROPERTY_RELATION_PRIOR.get(relation, 0.0)
    score += math.log1p(max(record.weight, 0.1)) / 7.0
    if 1 < len(record.source.split("_")) <= 4:
        score += 0.08
    return score


def combined_world_tv(property_record: Record, world_record: Record) -> str:
    reliability = PROPERTY_RELATION_PRIOR.get(normalized_relation(world_record), 0.55)
    combined_weight = min(property_record.weight, world_record.weight) * reliability
    return stv_from_weight(combined_weight, confidence_floor=0.42)


def build_output_lines(property_records: Iterable[Record], world_records: Iterable[Record] | None = None,
                       concepts: set[str] | None = None, keep_noisy_targets: bool = False,
                       include_self_worlds: bool = True,
                       include_provenance: bool = False) -> tuple[list[str], dict[str, int]]:
    if world_records is None:
        materialized = list(property_records)
        property_records = materialized
        world_records = materialized

    properties = collect_properties(property_records, concepts, keep_noisy_targets)
    all_properties = [item for values in properties.values() for item in values]
    property_scopes: dict[str, set[str]] = defaultdict(set)
    for evidence in all_properties:
        property_scopes[canonical_target(evidence.record.target)].add(evidence.perspective)

    shared_candidates: dict[
        tuple[str, str], dict[str, ScoredWorldRecord]
    ] = defaultdict(dict)
    rejected_world_edges = 0

    for record in world_records:
        target = canonical_target(record.target)
        for perspective in property_scopes.get(target, ()):
            if not shared_world_admissible(target, perspective, record):
                rejected_world_edges += 1
                continue
            candidate = ScoredWorldRecord(record, shared_world_score(record))
            bucket = shared_candidates[(target, perspective)]
            old = bucket.get(record.source)
            if old is None or candidate.score > old.score:
                bucket[record.source] = candidate
                prune_ranked_bucket(bucket, WORLD_CANDIDATE_BUFFER)

    property_facts = {}
    provenance_facts = {}
    scoped_world_facts = {}
    world_provenance = {}
    selected_world_count = 0

    for evidence in sorted(all_properties, key=lambda item: (item.concept, item.perspective, item.property_name)):
        edge = atom_id("property", evidence.property_id)
        key = (evidence.concept, evidence.perspective, evidence.property_name)
        property_facts[key] = fact(
            edge,
            f"(has-scoped-property {edge} {evidence.concept} {evidence.perspective} "
            f"{evidence.property_id} {evidence.property_name})",
            stv_from_weight(evidence.record.weight),
        )
        if include_provenance:
            relation = safe_metta_symbol(normalized_relation(evidence.record)).lower()
            provenance_facts[key] = fact(
                atom_id(edge, "provenance"),
                f"(property-evidence {edge} {relation} {evidence.record.source} {evidence.record.target})",
                stv_from_weight(evidence.record.weight),
            )

        target = canonical_target(evidence.record.target)
        # Very frequent targets are semantically ambiguous (for example broad
        # evaluatives). Without concept-specific similarity evidence, sharing
        # their arbitrary worlds would add noise, so retain direct evidence only.
        if len(properties[target]) > MAX_SHARED_PROPERTY_SUPPORT:
            candidate_records = {}
        else:
            candidate_records = {
                item.record.source: item.record
                for item in shared_candidates.get(
                    (target, evidence.perspective), {}
                ).values()
            }
        # A frequent property can have more than the shared candidate cap.
        # Always retain its own direct evidence as a possible self-world.
        candidate_records[evidence.record.source] = evidence.record
        ranked_worlds = sorted(
            (
                WorldCandidate(evidence, record, world_score(evidence, record))
                for record in candidate_records.values()
                if world_admissible(evidence, record, include_self_worlds)
            ),
            key=lambda item: (-item.score, item.record.source),
        )[:MAX_WORLDS_PER_PROPERTY]
        selected_world_count += len(ranked_worlds)
        for candidate in ranked_worlds:
            world = candidate.record.source
            world_key = (evidence.property_id, evidence.perspective, world)
            world_edge = atom_id("scoped_world", *world_key)
            scoped_world_facts[world_key] = fact(
                world_edge,
                f"(scoped-property-holds-in {world_edge} {evidence.property_id} "
                f"{evidence.perspective} {world})",
                combined_world_tv(evidence.record, candidate.record),
            )
            if include_provenance:
                relation = safe_metta_symbol(normalized_relation(candidate.record)).lower()
                provenance_key = (evidence.property_id, world, relation)
                world_provenance[provenance_key] = fact(
                    atom_id("world_evidence", *provenance_key),
                    f"(world-evidence {evidence.property_id} {relation} {world} {candidate.record.target})",
                    stv_from_weight(candidate.record.weight),
                )

    lines = [
        *perspective_lines(),
        *[property_facts[key] for key in sorted(
            property_facts,
            key=lambda item: (item[0], PERSPECTIVE_PRIORITY.get(item[1], 20), item[2]),
        )],
        *(
            [provenance_facts[key] for key in sorted(
                provenance_facts,
                key=lambda item: (item[0], PERSPECTIVE_PRIORITY.get(item[1], 20), item[2]),
            )]
            if include_provenance else []
        ),
        *[scoped_world_facts[key] for key in sorted(scoped_world_facts)],
        *(
            [world_provenance[key] for key in sorted(world_provenance)]
            if include_provenance else []
        ),
    ]
    stats = {
        "properties": len(property_facts),
        "holds_in": selected_world_count,
        "property_holds_in": len(scoped_world_facts),
        "unique_worlds": len({key[2] for key in scoped_world_facts}),
        "rejected_world_edges": rejected_world_edges,
        "incompatible_world_edges": 0,
    }
    return lines, stats


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate a perspective-aware MeTTa property/world KB."
    )
    parser.add_argument("inputs", nargs="+", help="Raw MeTTa files or directories")
    parser.add_argument("output", help="Output PropertyWorldKB.metta path")
    parser.add_argument(
        "--concept",
        action="append",
        default=[],
        help="Restrict direct properties to a concept; repeatable",
    )
    parser.add_argument(
        "--keep-noisy-targets",
        action="store_true",
        help="Keep records rejected by the shared semantic quality filter",
    )
    parser.add_argument(
        "--exclude-self-worlds",
        action="store_true",
        help="Do not use the queried concept itself as a possible world",
    )
    parser.add_argument(
        "--include-provenance",
        action="store_true",
        help="Emit property_evidence and world_evidence audit facts",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    concepts = (
        {safe_metta_symbol(concept) for concept in args.concept}
        if args.concept
        else None
    )

    # iter_records is called twice intentionally: this keeps the full Concept
    # Atomspace build streaming and bounded by the selected property targets.
    records_factory: Callable[[], Iterable[Record]] = lambda: iter_all_records(args.inputs)
    lines, stats = build_output_lines(
        records_factory(),
        records_factory(),
        concepts=concepts,
        keep_noisy_targets=args.keep_noisy_targets,
        include_self_worlds=not args.exclude_self_worlds,
        include_provenance=args.include_provenance,
    )

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
    print(
        "generated "
        f"{stats['properties']} properties, "
        f"{stats['holds_in']} property/world links, and "
        f"{stats['property_holds_in']} property-level holds-in links, and "
        f"{stats['unique_worlds']} unique concept worlds -> {output}"
    )


if __name__ == "__main__":
    main()
