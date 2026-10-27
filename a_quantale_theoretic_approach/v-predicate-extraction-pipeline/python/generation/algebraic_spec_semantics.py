"""Semantic IR, schema bundles, and validation for algebraic specifications.

This module deliberately has no dependency on the MeTTa emitter.  It turns a
set of already-classified ConceptNet records into a typed concept model and
then compiles that model into coherent, reusable algebraic schema bundles.

The central design constraint is semantic ownership:

* capabilities, transformations, observers, constants, and combinators are
  operations;
* non-transformational relations are predicates;
* types are sorts;
* laws constrain declared operations and predicates.

One evidence edge may support several declarations, but it must not be copied
as operation and predicate paraphrases.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Any, Iterable, Sequence


CAPABILITY_RELATIONS = frozenset({"UsedFor", "CapableOf"})
RELATIONAL_RELATIONS = frozenset(
    {
        "isA",
        "InstanceOf",
        "hasproperty",
        "hasPrerequisite",
        "hasSubevent",
        "ReceivesAction",
        "Causes",
        "Entails",
        "CausesDesire",
        "HasA",
        "PartOf",
        "MadeOf",
        "AtLocation",
        "LocatedNear",
        "HasContext",
        "CreatedBy",
        "RelatedTo",
    }
)

ACTION_ALIASES = {
    "cut": "slice",
    "cutting": "slice",
    "slice": "slice",
    "slicing": "slice",
    "stab": "pierce",
    "stabbing": "pierce",
    "pierce": "pierce",
    "piercing": "pierce",
    "chop": "chop",
    "chopping": "chop",
    "scrape": "scrape",
    "scraping": "scrape",
    "carry": "transport",
    "commute": "transport",
    "drive": "transport",
    "move": "move",
    "transport": "transport",
    "travel": "transport",
    "hold": "contain",
    "store": "contain",
    "contain": "contain",
    "calculate": "compute",
    "compute": "compute",
    "process": "compute",
    "reason": "reason",
    "think": "reason",
    "infer": "reason",
    "talk": "communicate",
    "speak": "communicate",
    "write": "communicate",
    "communicate": "communicate",
    "socialize": "communicate",
    "see": "perceive",
    "hear": "perceive",
    "observe": "perceive",
    "perceive": "perceive",
    "eat": "consume",
    "drink": "consume",
    "consume": "consume",
    "support": "support",
    "heat": "transform_material",
    "mix": "transform_material",
    "cook": "transform_material",
    "transform": "transform_material",
    "learn": "learn",
    "study": "learn",
    "create": "create",
    "make": "create",
    "build": "create",
}

NOUN_LIKE_TARGETS = frozenset(
    {
        "butter",
        "food",
        "kitchen",
        "money",
        "price",
        "school",
        "table",
        "water",
        "work",
    }
)

FAMILY_TRIGGERS = {
    "edge-application": frozenset(
        {
            "blade",
            "cut",
            "cutting",
            "edge",
            "knife",
            "pierce",
            "scrape",
            "sharp",
            "slice",
            "stab",
            "stabbing",
            "chop",
        }
    ),
    "transport": frozenset(
        {
            "car",
            "carry",
            "commute",
            "drive",
            "road",
            "ship",
            "train",
            "transport",
            "travel",
            "vehicle",
            "wheel",
        }
    ),
    "containment": frozenset(
        {"bag", "bottle", "box", "container", "contain", "hold", "room", "store"}
    ),
    "computation": frozenset(
        {
            "algorithm",
            "arithmetic",
            "calculate",
            "computation",
            "computer",
            "data",
            "digital",
            "number",
            "program",
            "software",
        }
    ),
    "communication": frozenset(
        {
            "communicate",
            "conversation",
            "language",
            "message",
            "social",
            "speak",
            "talk",
            "word",
            "write",
        }
    ),
    "perception": frozenset(
        {"ear", "eye", "hear", "observe", "perceive", "sense", "sound", "vision"}
    ),
    "consumption": frozenset({"drink", "eat", "food", "meal", "nutrition", "water"}),
    "material-transformation": frozenset(
        {"chemical", "cook", "heat", "liquid", "material", "mix", "substance"}
    ),
}


def _tokens(value: object) -> tuple[str, ...]:
    return tuple(
        token
        for token in re.split(r"[_\W]+", str(value).strip("'").lower())
        if token
    )


def _score(record: object, classification: object) -> float:
    weight = max(float(getattr(record, "weight", 1.0)), 0.1)
    return weight + float(getattr(classification, "score_bonus", 0.0))


@dataclass(frozen=True)
class Evidence:
    relation: str
    source: str
    target: str
    perspective: str
    target_type: str
    weight: float
    score: float
    order: int
    surface_text: str = ""


@dataclass
class CapabilityFrame:
    action: str
    targets: set[str] = field(default_factory=set)
    evidence: list[Evidence] = field(default_factory=list)

    @property
    def score(self) -> float:
        return max((item.score for item in self.evidence), default=0.0)


@dataclass
class RelationFrame:
    relation: str
    target: str
    object_sort: str
    evidence: list[Evidence] = field(default_factory=list)

    @property
    def semantic_key(self) -> str:
        return f"relation:{self.relation}:{self.target}"


@dataclass
class ConceptModel:
    concept: str
    perspective: str
    evidence: list[Evidence] = field(default_factory=list)
    capabilities: dict[str, CapabilityFrame] = field(default_factory=dict)
    relations: list[RelationFrame] = field(default_factory=list)
    tokens: set[str] = field(default_factory=set)

    @property
    def score(self) -> float:
        return max((item.score for item in self.evidence), default=0.0)

    @property
    def average_weight(self) -> float:
        if not self.evidence:
            return 1.0
        return sum(item.weight for item in self.evidence) / len(self.evidence)


@dataclass(frozen=True)
class Feature:
    part: str
    name: str
    value: str
    semantic_key: str
    required_sorts: tuple[str, ...] = ()
    referenced_operations: tuple[str, ...] = ()
    score_bonus: float = 0.0


@dataclass
class SchemaBundle:
    bundle_id: str
    concept: str
    perspective: str
    family: str
    score: float
    evidence_weight: float
    order: int
    features: list[Feature] = field(default_factory=list)


@dataclass(frozen=True)
class ValidationIssue:
    code: str
    bundle_id: str
    detail: str


def evidence_from(record: object, classification: object) -> Evidence:
    return Evidence(
        relation=str(getattr(record, "relation")),
        source=str(getattr(record, "source")),
        target=str(getattr(record, "target")),
        perspective=str(getattr(classification, "perspective")),
        target_type=str(getattr(classification, "target_type")),
        weight=float(getattr(record, "weight", 1.0)),
        score=_score(record, classification),
        order=int(getattr(record, "order", 0)),
        surface_text=str(getattr(record, "surface_text", "")),
    )


def normalize_action(evidence: Evidence) -> str | None:
    """Return a canonical action only when the target denotes a capability."""

    if evidence.relation not in CAPABILITY_RELATIONS:
        return None

    target_tokens = _tokens(evidence.target)
    for token in target_tokens:
        if token in ACTION_ALIASES:
            return ACTION_ALIASES[token]

    if any(token in NOUN_LIKE_TARGETS for token in target_tokens):
        return None

    # CapableOf is explicitly action-bearing.  Preserve an unknown concise verb
    # as a capability rather than fabricating a generic use_for operation.
    if evidence.relation == "CapableOf" and 1 <= len(target_tokens) <= 3:
        return "_".join(target_tokens)
    return None


def relation_name(evidence: Evidence) -> str:
    """Map source relations to non-capability predicate vocabulary."""

    relation_map = {
        "isA": "isA",
        "InstanceOf": "instanceOf",
        "hasproperty": "hasProperty",
        "hasPrerequisite": "Requires",
        "hasSubevent": "HasSubevent",
        "ReceivesAction": "ReceivesAction",
        "Causes": "MayCause",
        "Entails": "Entails",
        "CausesDesire": "CausesDesire",
        "HasA": "HasPart",
        "PartOf": "PartOf",
        "MadeOf": "MadeOf",
        "AtLocation": "AtLocation",
        "LocatedNear": "LocatedNear",
        "HasContext": "HasContext",
        "CreatedBy": "CreatedBy",
        "RelatedTo": "RelatedTo",
    }
    return relation_map.get(evidence.relation, evidence.relation)


def relation_object_sort(evidence: Evidence) -> str:
    by_relation = {
        "hasPrerequisite": "precondition",
        "hasSubevent": "event",
        "ReceivesAction": "action",
        "Causes": "risk",
        "Entails": "outcome",
        "CausesDesire": "desire",
        "HasA": "part",
        "PartOf": "whole",
        "MadeOf": "material",
        "AtLocation": "location",
        "LocatedNear": "location",
        "HasContext": "context",
        "CreatedBy": "agent",
    }
    return by_relation.get(evidence.relation, "related_entity")


def build_concept_model(
    concept: str,
    perspective: str,
    classified_evidence: Iterable[tuple[object, object]],
) -> ConceptModel:
    model = ConceptModel(concept=concept, perspective=perspective)
    relation_index: dict[tuple[str, str], RelationFrame] = {}

    for record, classification in classified_evidence:
        item = evidence_from(record, classification)
        model.evidence.append(item)
        model.tokens.update(_tokens(item.source))
        model.tokens.update(_tokens(item.target))
        model.tokens.update(_tokens(item.surface_text))

        action = normalize_action(item)
        if action:
            frame = model.capabilities.setdefault(action, CapabilityFrame(action=action))
            frame.targets.add(item.target)
            frame.evidence.append(item)
            continue

        # UsedFor with a noun-like target expresses application or task, not a
        # capability.  Keep it as a relational frame with a relational name.
        if item.relation == "UsedFor":
            key = ("ServesTask", item.target)
            frame = relation_index.setdefault(
                key,
                RelationFrame(
                    relation="ServesTask",
                    target=item.target,
                    object_sort="task",
                ),
            )
            frame.evidence.append(item)
            continue

        if item.relation in RELATIONAL_RELATIONS:
            name = relation_name(item)
            key = (name, item.target)
            frame = relation_index.setdefault(
                key,
                RelationFrame(
                    relation=name,
                    target=item.target,
                    object_sort=relation_object_sort(item),
                ),
            )
            frame.evidence.append(item)

    model.relations.extend(relation_index.values())
    return model


def _sort(name: str, bonus: float = 0.0) -> Feature:
    return Feature(
        part="sorts",
        name=name,
        value=name,
        semantic_key=f"sort:{name}",
        score_bonus=bonus,
    )


def _operation(
    name: str,
    signature: str,
    sorts: Sequence[str],
    semantic_key: str,
    bonus: float = 0.0,
) -> Feature:
    return Feature(
        part="operations",
        name=name,
        value=signature,
        semantic_key=semantic_key,
        required_sorts=tuple(sorts),
        score_bonus=bonus,
    )


def _predicate(
    name: str,
    expression: str,
    sorts: Sequence[str],
    semantic_key: str,
    bonus: float = 0.0,
) -> Feature:
    return Feature(
        part="predicates",
        name=name,
        value=expression,
        semantic_key=semantic_key,
        required_sorts=tuple(sorts),
        score_bonus=bonus,
    )


def _axiom(
    name: str,
    expression: str,
    operations: Sequence[str],
    semantic_key: str,
    bonus: float = 0.0,
) -> Feature:
    return Feature(
        part="axioms",
        name=name,
        value=expression,
        semantic_key=semantic_key,
        referenced_operations=tuple(operations),
        score_bonus=bonus,
    )


def _bundle(
    model: ConceptModel,
    family: str,
    features: Sequence[Feature],
    bonus: float,
) -> SchemaBundle:
    safe_family = family.replace("-", "_")
    return SchemaBundle(
        bundle_id=f"{model.concept}:{model.perspective}:{safe_family}",
        concept=model.concept,
        perspective=model.perspective,
        family=family,
        score=model.score + bonus,
        evidence_weight=model.average_weight,
        order=min((item.order for item in model.evidence), default=0),
        features=list(features),
    )


def _functional_interface(model: ConceptModel) -> SchemaBundle:
    c = model.concept
    features = [
        *(
            _sort(name, 0.08 if name == c else 0.0)
            for name in (
                c,
                "agent",
                "target",
                "use_path",
                "motion",
                "force",
                "use_configuration",
                "use_outcome",
                "task",
                "risk",
            )
        ),
        _operation(
            f"configure_{c}",
            f"(-> agent {c} target use_path use_configuration)",
            ("agent", c, "target", "use_path", "use_configuration"),
            "capability:configure",
            0.20,
        ),
        _operation(
            f"target_of_{c}",
            "(-> use_configuration target)",
            ("use_configuration", "target"),
            "observer:target",
            0.14,
        ),
        _operation(
            f"retarget_{c}",
            "(-> use_configuration target use_configuration)",
            ("use_configuration", "target"),
            "transformation:retarget",
            0.14,
        ),
        _operation(
            f"apply_{c}",
            "(-> use_configuration motion force use_outcome)",
            ("use_configuration", "motion", "force", "use_outcome"),
            "capability:apply",
            0.18,
        ),
        _operation(
            f"target_after_{c}",
            "(-> use_outcome target)",
            ("use_outcome", "target"),
            "observer:target_after",
            0.12,
        ),
        _operation(
            f"no_motion_{c}",
            "motion",
            ("motion",),
            "constant:no_motion",
        ),
        _operation(
            f"zero_force_{c}",
            "force",
            ("force",),
            "constant:zero_force",
        ),
        _operation(
            f"compose_motion_{c}",
            "(-> motion motion motion)",
            ("motion",),
            "combinator:motion",
            0.08,
        ),
        _predicate(
            "UsedBy",
            f"(UsedBy {c} agent)",
            (c, "agent"),
            "relation:UsedBy",
        ),
        _predicate(
            "AppliedTo",
            f"(AppliedTo {c} target)",
            (c, "target"),
            "relation:AppliedTo",
        ),
        _predicate(
            "GuidedAlong",
            f"(GuidedAlong {c} use_path)",
            (c, "use_path"),
            "relation:GuidedAlong",
        ),
        _predicate(
            "ServesTask",
            f"(ServesTask {c} task)",
            (c, "task"),
            "relation:ServesTask",
        ),
        _predicate(
            "Produces",
            f"(Produces {c} use_outcome)",
            (c, "use_outcome"),
            "relation:Produces",
        ),
        _predicate(
            "MayCause",
            f"(MayCause {c} risk)",
            (c, "risk"),
            "relation:MayCause",
        ),
        _predicate(
            "RequiresForce",
            f"(RequiresForce {c} force)",
            (c, "force"),
            "relation:RequiresForce",
        ),
        _predicate(
            "ControlledBy",
            f"(ControlledBy {c} agent)",
            (c, "agent"),
            "relation:ControlledBy",
        ),
        _axiom(
            "configure_target",
            f"(forall ((a agent) (k {c}) (t target) (p use_path)) "
            f"(= (target_of_{c} (configure_{c} a k t p)) t))",
            (f"target_of_{c}", f"configure_{c}"),
            "law:configure_target",
            0.10,
        ),
        _axiom(
            "retarget_target",
            f"(forall ((cfg use_configuration) (t target)) "
            f"(= (target_of_{c} (retarget_{c} cfg t)) t))",
            (f"target_of_{c}", f"retarget_{c}"),
            "law:retarget_target",
            0.10,
        ),
        _axiom(
            "no_motion_preserves_target",
            f"(forall ((cfg use_configuration) (f force)) "
            f"(= (target_after_{c} (apply_{c} cfg no_motion_{c} f)) "
            f"(target_of_{c} cfg)))",
            (f"target_after_{c}", f"apply_{c}", f"no_motion_{c}", f"target_of_{c}"),
            "law:no_motion",
        ),
        _axiom(
            "zero_force_preserves_target",
            f"(forall ((cfg use_configuration) (m motion)) "
            f"(= (target_after_{c} (apply_{c} cfg m zero_force_{c})) "
            f"(target_of_{c} cfg)))",
            (f"target_after_{c}", f"apply_{c}", f"zero_force_{c}", f"target_of_{c}"),
            "law:zero_force",
        ),
        _axiom(
            "motion_left_identity",
            f"(forall ((m motion)) (= (compose_motion_{c} no_motion_{c} m) m))",
            (f"compose_motion_{c}", f"no_motion_{c}"),
            "law:motion_left_identity",
        ),
        _axiom(
            "motion_right_identity",
            f"(forall ((m motion)) (= (compose_motion_{c} m no_motion_{c}) m))",
            (f"compose_motion_{c}", f"no_motion_{c}"),
            "law:motion_right_identity",
        ),
        _axiom(
            "sequential_motion",
            f"(forall ((cfg use_configuration) (m1 motion) (m2 motion) (f force)) "
            f"(= (target_after_{c} (apply_{c} cfg (compose_motion_{c} m1 m2) f)) "
            f"(target_after_{c} (apply_{c} "
            f"(retarget_{c} cfg (target_after_{c} (apply_{c} cfg m1 f))) m2 f))))",
            (
                f"target_after_{c}",
                f"apply_{c}",
                f"compose_motion_{c}",
                f"retarget_{c}",
            ),
            "law:sequential_motion",
            0.08,
        ),
    ]
    return _bundle(model, "functional-interface", features, 0.35)


def _edge_application(model: ConceptModel) -> SchemaBundle:
    c = model.concept
    features = [
        _operation(
            f"draw_motion_{c}",
            "motion",
            ("motion",),
            "constant:draw_motion",
        ),
        _operation(
            f"thrust_motion_{c}",
            "motion",
            ("motion",),
            "constant:thrust_motion",
        ),
        _operation(
            f"down_motion_{c}",
            "motion",
            ("motion",),
            "constant:down_motion",
        ),
        _operation(
            f"scrape_motion_{c}",
            "motion",
            ("motion",),
            "constant:scrape_motion",
        ),
    ]
    specializations = (
        ("slice", "draw_motion"),
        ("pierce", "thrust_motion"),
        ("chop", "down_motion"),
        ("scrape", "scrape_motion"),
    )
    for action, motion in specializations:
        op = f"{action}_{c}"
        features.append(
            _operation(
                op,
                "(-> use_configuration force use_outcome)",
                ("use_configuration", "force", "use_outcome"),
                f"capability:{action}",
                0.22 if action in model.capabilities else 0.08,
            )
        )
        features.append(
            _axiom(
                f"{action}_definition",
                f"(forall ((cfg use_configuration) (f force)) "
                f"(= ({op} cfg f) (apply_{c} cfg {motion}_{c} f)))",
                (op, f"apply_{c}", f"{motion}_{c}"),
                f"law:{action}_definition",
                0.12 if action in model.capabilities else 0.02,
            )
        )
    return _bundle(model, "edge-application", features, 0.50)


def _transport(model: ConceptModel) -> SchemaBundle:
    c = model.concept
    features = [
        *(_sort(name) for name in (c, "origin", "destination", "route", "cargo", "transport_state")),
        _operation(
            f"transport_{c}",
            f"(-> {c} origin destination route transport_state)",
            (c, "origin", "destination", "route", "transport_state"),
            "capability:transport",
            0.24,
        ),
        _operation(
            f"carry_{c}",
            f"(-> {c} cargo transport_state transport_state)",
            (c, "cargo", "transport_state"),
            "capability:carry",
            0.16,
        ),
        _predicate(
            "TravelsFrom",
            f"(TravelsFrom {c} origin)",
            (c, "origin"),
            "relation:TravelsFrom",
        ),
        _predicate(
            "TravelsTo",
            f"(TravelsTo {c} destination)",
            (c, "destination"),
            "relation:TravelsTo",
        ),
        _predicate(
            "Carries",
            f"(Carries {c} cargo)",
            (c, "cargo"),
            "relation:Carries",
        ),
        _axiom(
            "transport_closure",
            f"(forall ((x {c}) (o origin) (d destination) (r route)) "
            f"(closedUnder (transport_{c} x o d r) transport_state))",
            (f"transport_{c}",),
            "law:transport_closure",
        ),
    ]
    return _bundle(model, "transport", features, 0.42)


def _containment(model: ConceptModel) -> SchemaBundle:
    c = model.concept
    features = [
        *(_sort(name) for name in (c, "contained_object", "container_state")),
        _operation(
            f"insert_{c}",
            f"(-> {c} contained_object container_state container_state)",
            (c, "contained_object", "container_state"),
            "capability:insert",
            0.20,
        ),
        _operation(
            f"remove_{c}",
            f"(-> {c} contained_object container_state container_state)",
            (c, "contained_object", "container_state"),
            "capability:remove",
            0.16,
        ),
        _predicate(
            "Contains",
            f"(Contains {c} contained_object)",
            (c, "contained_object"),
            "relation:Contains",
        ),
        _axiom(
            "insert_remove",
            f"(forall ((x {c}) (o contained_object) (s container_state)) "
            f"(= (remove_{c} x o (insert_{c} x o s)) s))",
            (f"remove_{c}", f"insert_{c}"),
            "law:insert_remove",
        ),
    ]
    return _bundle(model, "containment", features, 0.40)


def _computation(model: ConceptModel) -> SchemaBundle:
    c = model.concept
    features = [
        *(
            _sort(name)
            for name in (
                c,
                "program",
                "input_data",
                "computation_state",
                "output_data",
            )
        ),
        _operation(
            f"initialize_{c}",
            f"(-> {c} program computation_state)",
            (c, "program", "computation_state"),
            "capability:initialize",
        ),
        _operation(
            f"compute_{c}",
            f"(-> {c} input_data computation_state computation_state)",
            (c, "input_data", "computation_state"),
            "capability:compute",
            0.24,
        ),
        _operation(
            f"observe_{c}",
            f"(-> {c} computation_state output_data)",
            (c, "computation_state", "output_data"),
            "observer:output",
        ),
        _predicate(
            "RunsProgram",
            f"(RunsProgram {c} program)",
            (c, "program"),
            "relation:RunsProgram",
        ),
        _predicate(
            "ReceivesInput",
            f"(ReceivesInput {c} input_data)",
            (c, "input_data"),
            "relation:ReceivesInput",
        ),
        _predicate(
            "ProducesOutput",
            f"(ProducesOutput {c} output_data)",
            (c, "output_data"),
            "relation:ProducesOutput",
        ),
        _axiom(
            "compute_closure",
            f"(forall ((x {c}) (i input_data) (s computation_state)) "
            f"(closedUnder (compute_{c} x i s) computation_state))",
            (f"compute_{c}",),
            "law:compute_closure",
        ),
    ]
    return _bundle(model, "computation", features, 0.46)


def _agent_action(model: ConceptModel) -> SchemaBundle:
    c = model.concept
    features = [
        *(_sort(name) for name in (c, "action", "process_state", "behavior_outcome", "context")),
        _operation(
            f"perform_{c}",
            f"(-> {c} action process_state process_state)",
            (c, "action", "process_state"),
            "capability:perform",
            0.20,
        ),
        _operation(
            f"observe_behavior_{c}",
            f"(-> {c} process_state behavior_outcome)",
            (c, "process_state", "behavior_outcome"),
            "observer:behavior",
        ),
        _predicate(
            "ActsIn",
            f"(ActsIn {c} context)",
            (c, "context"),
            "relation:ActsIn",
        ),
        _predicate(
            "ProducesBehavior",
            f"(ProducesBehavior {c} behavior_outcome)",
            (c, "behavior_outcome"),
            "relation:ProducesBehavior",
        ),
        _axiom(
            "perform_closure",
            f"(forall ((x {c}) (a action) (s process_state)) "
            f"(closedUnder (perform_{c} x a s) process_state))",
            (f"perform_{c}",),
            "law:perform_closure",
        ),
    ]
    return _bundle(model, "agent-action", features, 0.32)


def _taxonomic_interface(model: ConceptModel) -> SchemaBundle:
    c = model.concept
    features = [
        *(_sort(name) for name in (c, "taxonomic_kind", "classification_context", "evidence_state")),
        _operation(
            f"classify_{c}",
            f"(-> {c} classification_context taxonomic_kind)",
            (c, "classification_context", "taxonomic_kind"),
            "observer:classification",
            0.20,
        ),
        _operation(
            f"refine_kind_{c}",
            "(-> taxonomic_kind evidence_state taxonomic_kind)",
            ("taxonomic_kind", "evidence_state"),
            "transformation:refine_kind",
        ),
        _operation(
            f"empty_evidence_{c}",
            "evidence_state",
            ("evidence_state",),
            "constant:empty_evidence",
        ),
        _predicate(
            "ClassifiedIn",
            f"(ClassifiedIn {c} classification_context)",
            (c, "classification_context"),
            "relation:ClassifiedIn",
        ),
        _axiom(
            "empty_evidence_identity",
            f"(forall ((k taxonomic_kind)) (= (refine_kind_{c} k empty_evidence_{c}) k))",
            (f"refine_kind_{c}", f"empty_evidence_{c}"),
            "law:empty_evidence_identity",
        ),
    ]
    return _bundle(model, "taxonomic-interface", features, 0.32)


def _descriptive_interface(model: ConceptModel) -> SchemaBundle:
    c = model.concept
    features = [
        *(_sort(name) for name in (c, "property", "property_value", "observation_context")),
        _operation(
            f"observe_property_{c}",
            f"(-> {c} property observation_context property_value)",
            (c, "property", "observation_context", "property_value"),
            "observer:property",
            0.16,
        ),
        _predicate(
            "HasProperty",
            f"(HasProperty {c} property)",
            (c, "property"),
            "relation:HasProperty",
        ),
    ]
    return _bundle(model, "descriptive-interface", features, 0.24)


def _physical_interface(model: ConceptModel) -> SchemaBundle:
    c = model.concept
    features = [
        *(_sort(name) for name in (c, "physical_attribute", "measurement", "measurement_context")),
        _operation(
            f"measure_{c}",
            f"(-> {c} physical_attribute measurement_context measurement)",
            (c, "physical_attribute", "measurement_context", "measurement"),
            "observer:measurement",
            0.20,
        ),
        _predicate(
            "HasPhysicalAttribute",
            f"(HasPhysicalAttribute {c} physical_attribute)",
            (c, "physical_attribute"),
            "relation:HasPhysicalAttribute",
        ),
    ]
    return _bundle(model, "physical-observation", features, 0.30)


def _safety_interface(model: ConceptModel) -> SchemaBundle:
    c = model.concept
    features = [
        *(_sort(name) for name in (c, "risk", "hazard_context", "risk_state")),
        _operation(
            f"assess_risk_{c}",
            f"(-> {c} hazard_context risk_state)",
            (c, "hazard_context", "risk_state"),
            "observer:risk",
            0.20,
        ),
        _operation(
            f"mitigate_{c}",
            f"(-> {c} risk_state risk_state)",
            (c, "risk_state"),
            "transformation:mitigate",
        ),
        _predicate("MayCause", f"(MayCause {c} risk)", (c, "risk"), "relation:MayCause"),
        _axiom(
            "mitigation_closure",
            f"(forall ((x {c}) (r risk_state)) (closedUnder (mitigate_{c} x r) risk_state))",
            (f"mitigate_{c}",),
            "law:mitigation_closure",
        ),
    ]
    return _bundle(model, "safety-risk", features, 0.32)


def _spatial_interface(model: ConceptModel) -> SchemaBundle:
    c = model.concept
    features = [
        *(_sort(name) for name in (c, "location", "path", "spatial_context")),
        _operation(
            f"locate_{c}",
            f"(-> {c} spatial_context location)",
            (c, "spatial_context", "location"),
            "observer:location",
        ),
        _operation(
            f"relocate_{c}",
            f"(-> {c} location path location)",
            (c, "location", "path"),
            "transformation:relocate",
            0.16,
        ),
        _operation(f"empty_path_{c}", "path", ("path",), "constant:empty_path"),
        _predicate("LocatedAt", f"(LocatedAt {c} location)", (c, "location"), "relation:LocatedAt"),
        _axiom(
            "empty_path_identity",
            f"(forall ((x {c}) (l location)) (= (relocate_{c} x l empty_path_{c}) l))",
            (f"relocate_{c}", f"empty_path_{c}"),
            "law:empty_path_identity",
        ),
    ]
    return _bundle(model, "spatial-interface", features, 0.30)


def _state_interface(model: ConceptModel) -> SchemaBundle:
    c = model.concept
    features = [
        *(_sort(name) for name in (c, "state", "event", "time")),
        _operation(
            f"transition_{c}",
            f"(-> {c} state event state)",
            (c, "state", "event"),
            "transformation:state_transition",
            0.18,
        ),
        _operation(f"no_event_{c}", "event", ("event",), "constant:no_event"),
        _operation(
            f"observe_state_{c}",
            f"(-> {c} time state)",
            (c, "time", "state"),
            "observer:state",
        ),
        _predicate("HasStateAt", f"(HasStateAt {c} time)", (c, "time"), "relation:HasStateAt"),
        _axiom(
            "no_event_identity",
            f"(forall ((x {c}) (s state)) (= (transition_{c} x s no_event_{c}) s))",
            (f"transition_{c}", f"no_event_{c}"),
            "law:no_event_identity",
        ),
    ]
    return _bundle(model, "state-lifecycle", features, 0.30)


def _prerequisite_interface(model: ConceptModel) -> SchemaBundle:
    c = model.concept
    features = [
        *(_sort(name) for name in (c, "precondition", "action_state", "outcome_state")),
        _operation(
            f"enable_{c}",
            "(-> precondition action_state action_state)",
            ("precondition", "action_state"),
            "transformation:enable",
            0.16,
        ),
        _operation(
            f"perform_{c}",
            f"(-> {c} action_state outcome_state)",
            (c, "action_state", "outcome_state"),
            "capability:perform",
        ),
        _predicate("Requires", f"(Requires {c} precondition)", (c, "precondition"), "relation:Requires"),
        _axiom(
            "enable_closure",
            f"(forall ((p precondition) (s action_state)) (closedUnder (enable_{c} p s) action_state))",
            (f"enable_{c}",),
            "law:enable_closure",
        ),
    ]
    return _bundle(model, "prerequisite-interface", features, 0.30)


def _value_interface(model: ConceptModel, family: str, value_sort: str) -> SchemaBundle:
    c = model.concept
    context_sort = f"{family.replace('-', '_')}_context"
    features = [
        *(_sort(name) for name in (c, value_sort, context_sort)),
        _operation(
            f"assess_{family.replace('-', '_')}_{c}",
            f"(-> {c} {context_sort} {value_sort})",
            (c, context_sort, value_sort),
            f"observer:{family}",
            0.16,
        ),
        _predicate(
            f"Has{''.join(part.title() for part in family.split('-'))}Value",
            f"(Has{''.join(part.title() for part in family.split('-'))}Value {c} {value_sort})",
            (c, value_sort),
            f"relation:{family}_value",
        ),
    ]
    return _bundle(model, family, features, 0.26)


def _structural(model: ConceptModel) -> SchemaBundle:
    c = model.concept
    features = [
        *(_sort(name) for name in (c, "whole", "part", "material", "structure_state")),
        _operation(
            f"assemble_{c}",
            f"(-> {c} part structure_state structure_state)",
            (c, "part", "structure_state"),
            "transformation:assemble",
            0.18,
        ),
        _operation(
            f"detach_{c}",
            f"(-> {c} part structure_state structure_state)",
            (c, "part", "structure_state"),
            "transformation:detach",
            0.14,
        ),
        _predicate(
            "HasPart",
            f"(HasPart {c} part)",
            (c, "part"),
            "relation:HasPart",
        ),
        _predicate(
            "MadeOf",
            f"(MadeOf {c} material)",
            (c, "material"),
            "relation:MadeOf",
        ),
        _axiom(
            "assemble_detach",
            f"(forall ((x {c}) (p part) (s structure_state)) "
            f"(= (detach_{c} x p (assemble_{c} x p s)) s))",
            (f"detach_{c}", f"assemble_{c}"),
            "law:assemble_detach",
        ),
    ]
    return _bundle(model, "structural-composition", features, 0.34)


def _relation_bundle(model: ConceptModel) -> SchemaBundle | None:
    features: list[Feature] = []
    required_sorts = {model.concept}
    for frame in model.relations:
        required_sorts.add(frame.object_sort)
        features.append(
            _predicate(
                frame.relation,
                f"({frame.relation} {model.concept} {frame.target})",
                (model.concept, frame.object_sort),
                frame.semantic_key,
                0.08,
            )
        )
    if not features:
        return None
    features[0:0] = [_sort(name) for name in sorted(required_sorts)]
    return _bundle(model, "evidence-relations", features, 0.18)





def _operation_codomain(signature: str) -> str | None:
    atoms = re.findall(r"[A-Za-z_][A-Za-z0-9_]*", signature)
    return atoms[-1] if atoms else None


def _safe_symbol(value: Any) -> str | None:
    text = str(value).strip().replace("-", "_")
    if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", text):
        return text
    return None


def _sorts_from_signature(signature: str) -> tuple[str, ...]:
    atoms = tuple(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", signature))
    if not atoms:
        return ()
    if atoms[0] in {"arrow", "->"}:
        return atoms[1:]
    return atoms


def _sorts_from_predicate_expression(expression: str) -> tuple[str, ...]:
    atoms = tuple(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", expression))
    return atoms[1:] if len(atoms) > 1 else ()


def _llm_confidence_bonus(value: Any, ceiling: float = 0.18) -> float:
    try:
        confidence = float(value)
    except (TypeError, ValueError):
        confidence = 0.35
    return min(ceiling, max(0.0, confidence) * ceiling)


def _llm_repair_bundle(model: ConceptModel, proposal: dict[str, Any]) -> SchemaBundle | None:
    repairs = proposal.get("repairs") if isinstance(proposal, dict) else None
    if not isinstance(repairs, dict):
        return None

    features: list[Feature] = []
    operation_names: set[str] = set()

    for item in repairs.get("sorts", ()):
        if not isinstance(item, dict):
            continue
        name = _safe_symbol(item.get("name") or item.get("value"))
        if name:
            features.append(_sort(name, _llm_confidence_bonus(item.get("confidence"), 0.08)))

    for item in repairs.get("operations", ()):
        if not isinstance(item, dict):
            continue
        name = _safe_symbol(item.get("name"))
        signature = str(item.get("signature") or item.get("value") or "").strip()
        if not name or not signature:
            continue
        if not (signature.startswith("(") and signature.endswith(")")) and _safe_symbol(signature) is None:
            continue
        sorts = tuple(
            sort
            for raw in item.get("required_sorts", ())
            if (sort := _safe_symbol(raw))
        ) or _sorts_from_signature(signature)
        features.append(
            _operation(
                name,
                signature,
                sorts,
                f"llm-operation:{name}",
                _llm_confidence_bonus(item.get("confidence")),
            )
        )
        operation_names.add(name)

    for item in repairs.get("predicates", ()):
        if not isinstance(item, dict):
            continue
        name = _safe_symbol(item.get("name"))
        expression = str(item.get("expression") or item.get("value") or "").strip()
        if not name or not expression.startswith("(") or not expression.endswith(")"):
            continue
        lowered = name.lower()
        if lowered.startswith("can") or lowered in {"capableof", "usedfor", "usefor"}:
            continue
        sorts = tuple(
            sort
            for raw in item.get("required_sorts", ())
            if (sort := _safe_symbol(raw))
        ) or _sorts_from_predicate_expression(expression)
        features.append(
            _predicate(
                name,
                expression,
                sorts,
                f"llm-relation:{name}:{expression}",
                _llm_confidence_bonus(item.get("confidence"), 0.12),
            )
        )

    for item in repairs.get("axioms", ()):
        if not isinstance(item, dict):
            continue
        name = _safe_symbol(item.get("name"))
        expression = str(item.get("expression") or item.get("value") or "").strip()
        refs = tuple(
            ref
            for raw in item.get("referenced_operations", ())
            if (ref := _safe_symbol(raw))
        )
        if not name or not expression.startswith("(") or not expression.endswith(")") or not refs:
            continue
        features.append(
            _axiom(
                name,
                expression,
                refs,
                f"llm-law:{name}",
                _llm_confidence_bonus(item.get("confidence"), 0.14),
            )
        )

    if not features:
        return None

    sense = proposal.get("sense", {}) if isinstance(proposal.get("sense"), dict) else {}
    sense_bonus = _llm_confidence_bonus(sense.get("confidence"), 0.06)
    return _bundle(model, "llm-repair", features, 0.28 + sense_bonus)


def _repair_sort_closure(group: list[SchemaBundle]) -> None:
    """Declare sorts required by operation/predicate signatures."""

    existing = {
        feature.name
        for bundle in group
        for feature in bundle.features
        if feature.part == "sorts"
    }
    repair_bundle = group[0]
    for bundle in group:
        for feature in list(bundle.features):
            for sort_name in feature.required_sorts:
                if sort_name not in existing:
                    repair_bundle.features.append(_sort(sort_name, 0.02))
                    existing.add(sort_name)


def _repair_axiom_coverage(group: list[SchemaBundle]) -> None:
    """Add minimal algebraic laws for operations not yet constrained."""

    operations = {
        feature.name: feature
        for bundle in group
        for feature in bundle.features
        if feature.part == "operations"
    }
    referenced = {
        operation
        for bundle in group
        for feature in bundle.features
        if feature.part == "axioms"
        for operation in feature.referenced_operations
    }
    repair_bundle = group[0]
    for op_name, feature in sorted(operations.items()):
        if op_name in referenced:
            continue
        codomain = _operation_codomain(feature.value)
        if not codomain:
            continue
        repair_bundle.features.append(
            _axiom(
                f"{op_name}_closure",
                f"(closedUnder {op_name} {codomain})",
                (op_name,),
                f"law:repair_closure:{op_name}",
                0.01,
            )
        )


def _repair_section_separation(group: list[SchemaBundle]) -> None:
    """Keep capabilities out of predicates and relation facts out of ops."""

    predicate_keys = {
        feature.semantic_key
        for bundle in group
        for feature in bundle.features
        if feature.part == "predicates"
    }
    operation_keys = {
        feature.semantic_key
        for bundle in group
        for feature in bundle.features
        if feature.part == "operations"
    }
    overlapping = predicate_keys.intersection(operation_keys)
    if not overlapping:
        return
    for bundle in group:
        bundle.features = [
            feature
            for feature in bundle.features
            if not (
                feature.part == "predicates"
                and feature.semantic_key in overlapping
                and (
                    feature.semantic_key.startswith("capability:")
                    or feature.semantic_key.startswith("transformation:")
                    or feature.semantic_key.startswith("observer:")
                )
            )
        ]


def _repair_duplicate_features(group: list[SchemaBundle]) -> None:
    """Remove lower-scored duplicate declarations after repair."""

    seen: set[tuple[str, str, str]] = set()
    for bundle in sorted(group, key=lambda item: (-item.score, item.order, item.family)):
        kept = []
        for feature in sorted(
            bundle.features,
            key=lambda item: (-item.score_bonus, item.part, item.name, item.value),
        ):
            key = (feature.part, feature.name, feature.value)
            if key in seen:
                continue
            seen.add(key)
            kept.append(feature)
        bundle.features = kept


def _evidence_profile_bundle(model: ConceptModel) -> SchemaBundle | None:
    """Emit a compact evidence-grounded profile that stays relational."""

    relation_features: list[Feature] = []
    sort_names = {model.concept}
    for frame in sorted(
        model.relations,
        key=lambda item: (
            -max((e.score for e in item.evidence), default=0.0),
            min((e.order for e in item.evidence), default=0),
            item.relation,
            item.target,
        ),
    )[:8]:
        sort_names.add(frame.object_sort)
        relation_features.append(
            _predicate(
                frame.relation,
                f"({frame.relation} {model.concept} {frame.target})",
                (model.concept, frame.object_sort),
                f"evidence:{frame.semantic_key}",
                0.06,
            )
        )

    if not relation_features:
        return None

    return _bundle(
        model,
        "hybrid-repair-profile",
        [*(_sort(name) for name in sorted(sort_names)), *relation_features],
        0.22,
    )


def repair_schema_bundles(
    bundles: Iterable[SchemaBundle],
    models: Iterable[ConceptModel] = (),
    llm_proposals: dict[tuple[str, str], dict[str, Any]] | None = None,
) -> list[SchemaBundle]:
    """Repair semantic bundles before KB emission.

    The repair pass keeps the generated KB evidence-first: it normalizes section
    ownership, fills type closure gaps, and adds minimal laws for operations that
    would otherwise be unconstrained.
    """

    repaired = list(bundles)
    existing_groups = {(bundle.concept, bundle.perspective) for bundle in repaired}
    for model in models:
        if (model.concept, model.perspective) not in existing_groups:
            continue
        profile = _evidence_profile_bundle(model)
        if profile:
            repaired.append(profile)
        if llm_proposals:
            proposal = llm_proposals.get((model.concept, model.perspective))
            if proposal:
                llm_bundle = _llm_repair_bundle(model, proposal)
                if llm_bundle:
                    repaired.append(llm_bundle)

    grouped: dict[tuple[str, str], list[SchemaBundle]] = {}
    for bundle in repaired:
        grouped.setdefault((bundle.concept, bundle.perspective), []).append(bundle)

    for group in grouped.values():
        _repair_section_separation(group)
        _repair_sort_closure(group)
        _repair_axiom_coverage(group)
        _repair_duplicate_features(group)

    return sorted(
        repaired,
        key=lambda item: (item.concept, item.perspective, -item.score, item.order, item.family),
    )

def matched_families(model: ConceptModel) -> set[str]:
    matches = {
        family
        for family, triggers in FAMILY_TRIGGERS.items()
        if model.tokens.intersection(triggers)
    }
    actions = set(model.capabilities)
    if actions.intersection({"slice", "pierce", "chop", "scrape"}):
        matches.add("edge-application")
    if actions.intersection({"transport", "move"}):
        matches.add("transport")
    if "contain" in actions:
        matches.add("containment")
    if "compute" in actions:
        matches.add("computation")
    return matches


def compile_schema_bundles(model: ConceptModel) -> list[SchemaBundle]:
    """Compile a concept model into coherent schema-family bundles."""

    if not model.evidence:
        return []

    bundles: list[SchemaBundle] = []
    families = matched_families(model)

    if model.perspective == "functional-use":
        bundles.append(_functional_interface(model))
    if model.perspective == "behavioral-process":
        bundles.append(_agent_action(model))
    if model.perspective == "information-computational":
        bundles.append(_computation(model))
    if model.perspective == "structural-composition":
        bundles.append(_structural(model))
    if model.perspective in {"taxonomic-kind", "artifact-kind", "role-kind"}:
        bundles.append(_taxonomic_interface(model))
    if model.perspective == "descriptive-property":
        bundles.append(_descriptive_interface(model))
    if model.perspective == "physical-attribute":
        bundles.append(_physical_interface(model))
    if model.perspective == "safety-risk":
        bundles.append(_safety_interface(model))
    if model.perspective == "spatial-context":
        bundles.append(_spatial_interface(model))
    if model.perspective in {"state-lifecycle", "temporal-context"}:
        bundles.append(_state_interface(model))
    if model.perspective == "causal-prerequisite":
        bundles.append(_prerequisite_interface(model))
    if model.perspective == "quantitative-comparative":
        bundles.append(_value_interface(model, "quantitative-comparative", "comparative_value"))
    if model.perspective == "social-normative":
        bundles.append(_value_interface(model, "social-normative", "social_evaluation"))
    if model.perspective == "economic-ownership":
        bundles.append(_value_interface(model, "economic-ownership", "economic_value"))

    if "edge-application" in families and model.perspective in {
        "functional-use",
        "structural-composition",
    }:
        # The specialization depends on the functional interface declarations.
        if not any(bundle.family == "functional-interface" for bundle in bundles):
            bundles.append(_functional_interface(model))
        bundles.append(_edge_application(model))
    if "transport" in families and model.perspective in {
        "functional-use",
        "spatial-context",
        "behavioral-process",
    }:
        bundles.append(_transport(model))
    if "containment" in families and model.perspective in {
        "functional-use",
        "spatial-context",
        "structural-composition",
    }:
        bundles.append(_containment(model))
    if "computation" in families and model.perspective in {
        "functional-use",
        "information-computational",
    } and not any(bundle.family == "computation" for bundle in bundles):
        bundles.append(_computation(model))

    relations = _relation_bundle(model)
    if relations:
        bundles.append(relations)

    return bundles


def select_schema_bundles(
    bundles: Iterable[SchemaBundle],
    max_families: int | None = None,
) -> list[SchemaBundle]:
    """Select whole bundles; never truncate individual spec sections."""

    grouped: dict[tuple[str, str], list[SchemaBundle]] = {}
    for bundle in bundles:
        grouped.setdefault((bundle.concept, bundle.perspective), []).append(bundle)

    selected: list[SchemaBundle] = []
    for key in sorted(grouped):
        ranked = sorted(
            grouped[key],
            key=lambda item: (-item.score, item.order, item.family),
        )
        if max_families is not None:
            # Evidence relations are provenance-bearing and the base interface
            # provides closure. Preserve them outside the specialization budget.
            required = [
                item
                for item in ranked
                if item.family.endswith("interface")
                or item.family == "evidence-relations"
            ]
            optional = [item for item in ranked if item not in required]
            ranked = required + optional[:max_families]
        selected.extend(ranked)
    return selected


def validate_bundles(bundles: Iterable[SchemaBundle]) -> list[ValidationIssue]:
    """Validate joint type closure, symbol closure, and section separation."""

    issues: list[ValidationIssue] = []
    grouped: dict[tuple[str, str], list[SchemaBundle]] = {}
    for bundle in bundles:
        grouped.setdefault((bundle.concept, bundle.perspective), []).append(bundle)

    for key, group in grouped.items():
        sorts = {
            feature.name
            for bundle in group
            for feature in bundle.features
            if feature.part == "sorts"
        }
        operations = {
            feature.name
            for bundle in group
            for feature in bundle.features
            if feature.part == "operations"
        }
        operation_keys = {
            feature.semantic_key
            for bundle in group
            for feature in bundle.features
            if feature.part == "operations"
        }
        predicate_keys = {
            feature.semantic_key
            for bundle in group
            for feature in bundle.features
            if feature.part == "predicates"
        }

        overlap = sorted(operation_keys.intersection(predicate_keys))
        for semantic_key in overlap:
            issues.append(
                ValidationIssue(
                    "operation-predicate-overlap",
                    f"{key[0]}:{key[1]}",
                    semantic_key,
                )
            )

        for bundle in group:
            for feature in bundle.features:
                missing_sorts = sorted(set(feature.required_sorts) - sorts)
                if missing_sorts:
                    issues.append(
                        ValidationIssue(
                            "undeclared-sort",
                            bundle.bundle_id,
                            f"{feature.name}: {', '.join(missing_sorts)}",
                        )
                    )
                missing_operations = sorted(
                    set(feature.referenced_operations) - operations
                )
                if missing_operations:
                    issues.append(
                        ValidationIssue(
                            "dangling-axiom-operation",
                            bundle.bundle_id,
                            f"{feature.name}: {', '.join(missing_operations)}",
                        )
                    )

        capability_predicates = {
            key
            for key in predicate_keys
            if key.startswith("capability:")
            or key.startswith("transformation:")
            or key.startswith("observer:")
        }
        for semantic_key in sorted(capability_predicates):
            issues.append(
                ValidationIssue(
                    "capability-in-predicates",
                    f"{key[0]}:{key[1]}",
                    semantic_key,
                )
            )

    return issues


def bundle_metrics(bundles: Iterable[SchemaBundle]) -> dict[str, float]:
    bundle_list = list(bundles)
    features = [feature for bundle in bundle_list for feature in bundle.features]
    operations = [feature for feature in features if feature.part == "operations"]
    predicates = [feature for feature in features if feature.part == "predicates"]
    axioms = [feature for feature in features if feature.part == "axioms"]
    issues = validate_bundles(bundle_list)
    referenced = {
        operation
        for axiom in axioms
        for operation in axiom.referenced_operations
    }
    operation_names = {operation.name for operation in operations}
    covered = operation_names.intersection(referenced)

    return {
        "bundle_count": float(len(bundle_list)),
        "sort_count": float(
            len({feature.name for feature in features if feature.part == "sorts"})
        ),
        "operation_count": float(len({feature.name for feature in operations})),
        "predicate_count": float(len({feature.value for feature in predicates})),
        "axiom_count": float(len({feature.value for feature in axioms})),
        "operation_axiom_coverage": (
            len(covered) / len(operation_names) if operation_names else 1.0
        ),
        "validation_issue_count": float(len(issues)),
        "operation_predicate_overlap_count": float(
            sum(issue.code == "operation-predicate-overlap" for issue in issues)
        ),
        "undeclared_sort_count": float(
            sum(issue.code == "undeclared-sort" for issue in issues)
        ),
        "dangling_axiom_count": float(
            sum(issue.code == "dangling-axiom-operation" for issue in issues)
        ),
    }
