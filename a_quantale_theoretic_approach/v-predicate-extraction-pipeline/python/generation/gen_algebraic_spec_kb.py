#!/usr/bin/env python3
"""Build a perspective-tagged algebraic-specification KB.

The source data is ConceptNet-style MeTTa with raw relation atoms such as:

    (isA apartment building)
    (hasproperty house susceptible_to_fire)
    (hasPrerequisite socialize go_to_party)
    (hasSubevent start_fire light_match)

Raw relations are treated as evidence, not as perspectives. Each relation is
first semantically classified into a formal perspective and normalized into a
typed concept model. Reusable schema families are selected as coherent bundles;
only then do we emit algebraic-spec feature facts:

    has-sort
    has-operation
    operation-signature
    has-predicate
    has-axiom

Bundles are ranked and emitted without independently truncating spec sections,
which preserves type and axiom closure.
"""

import argparse
import math
import os
import re
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path

from algebraic_spec_semantics import (
    bundle_metrics,
    build_concept_model,
    compile_schema_bundles,
    repair_schema_bundles,
    select_schema_bundles,
    validate_bundles,
)
from algebraic_spec_llm_repair import (
    JsonlRepairCache,
    LLMRepairConfig,
    provider_from_config,
    propose_with_cache,
    should_use_llm_repair,
)


RELATION_ALIASES = {
    "isA": "isA",
    "IsA": "isA",
    "InstanceOf": "InstanceOf",
    "instanceOf": "InstanceOf",
    "hasproperty": "hasproperty",
    "Hasproperty": "hasproperty",
    "HasProperty": "hasproperty",
    "hasProperty": "hasproperty",
    "hasPrerequisite": "hasPrerequisite",
    "HasPrerequisite": "hasPrerequisite",
    "hasSubevent": "hasSubevent",
    "HasSubevent": "hasSubevent",
    "UsedFor": "UsedFor",
    "usedFor": "UsedFor",
    "CapableOf": "CapableOf",
    "capableOf": "CapableOf",
    "ReceivesAction": "ReceivesAction",
    "receivesAction": "ReceivesAction",
    "Causes": "Causes",
    "causes": "Causes",
    "Entails": "Entails",
    "entails": "Entails",
    "CausesDesire": "CausesDesire",
    "causesDesire": "CausesDesire",
    "HasA": "HasA",
    "hasA": "HasA",
    "PartOf": "PartOf",
    "partOf": "PartOf",
    "MadeOf": "MadeOf",
    "madeOf": "MadeOf",
    "AtLocation": "AtLocation",
    "atLocation": "AtLocation",
    "LocatedNear": "LocatedNear",
    "locatedNear": "LocatedNear",
    "HasContext": "HasContext",
    "hasContext": "HasContext",
    "CreatedBy": "CreatedBy",
    "createdBy": "CreatedBy",
    "RelatedTo": "RelatedTo",
    "relatedTo": "RelatedTo",
}
SUPPORTED_RELATIONS = set(RELATION_ALIASES.values())
SPEC_PARTS = ("sorts", "operations", "predicates", "axioms")


# A small formal ontology of reusable perspectives. The hierarchy is emitted as
# perspective-match facts, so the MeTTa builder can ask either for a narrow
# perspective (physical-attribute) or a broad one (descriptive-property).
PERSPECTIVES = {
    "descriptive-property": ("property-role", None),
    "taxonomic-classification": ("ontological-role", None),
    "prerequisite-action": ("precondition-role", None),
    "event-composition": ("process-role", None),
    "taxonomic-kind": ("kind-role", "taxonomic-classification"),
    "artifact-kind": ("artifact-kind-role", "taxonomic-kind"),
    "role-kind": ("role-kind-role", "taxonomic-kind"),
    "structural-composition": ("structure-role", None),
    "physical-attribute": ("physical-attribute-role", "descriptive-property"),
    "functional-use": ("function-role", "descriptive-property"),
    "behavioral-process": ("behavior-role", "event-composition"),
    "causal-prerequisite": ("causal-precondition-role", "prerequisite-action"),
    "spatial-context": ("spatial-role", "descriptive-property"),
    "temporal-context": ("temporal-role", "descriptive-property"),
    "quantitative-comparative": ("comparative-role", None),
    "social-normative": ("social-role", None),
    "economic-ownership": ("economic-role", "descriptive-property"),
    "information-computational": ("information-role", "descriptive-property"),
    "safety-risk": ("risk-role", "descriptive-property"),
    "state-lifecycle": ("state-role", "descriptive-property"),
}

PERSPECTIVE_SORTS = {
    "physical-attribute": ("concept_instance", "physical_attribute"),
    "functional-use": ("concept_instance", "function_role"),
    "behavioral-process": ("process_state", "behavior_state"),
    "causal-prerequisite": ("action_state", "precondition_state"),
    "spatial-context": ("concept_instance", "spatial_context"),
    "temporal-context": ("concept_instance", "temporal_context"),
    "quantitative-comparative": ("concept_instance", "comparative_measure"),
    "social-normative": ("concept_instance", "social_evaluation"),
    "economic-ownership": ("concept_instance", "economic_value"),
    "information-computational": ("concept_instance", "information_state"),
    "safety-risk": ("concept_instance", "risk_condition"),
    "state-lifecycle": ("concept_instance", "state_condition"),
    "structural-composition": ("whole", "part"),
}



CORE_SCHEMAS = {
    "functional-use": {
        "sorts": ("functional_goal", "functional_result", "context_state"),
        "operations": (
            ("use", "(-> {concept} functional_goal context_state functional_result)"),
            ("adapt_goal", "(-> {concept} functional_goal functional_goal)"),
            ("compose_goal", "(-> functional_goal functional_goal functional_goal)"),
            ("empty_goal", "functional_goal"),
            ("observe_result", "(-> {concept} functional_result context_state)"),
        ),
        "predicates": (
            "(hasFunctionRole {concept} functional_goal)",
            "(producesResult {concept} functional_result)",
            "(usedInContext {concept} context_state)",
            "(hasFunctionalGoal {concept} functional_goal)",
            "(hasUsableState {concept} context_state)",
        ),
        "axioms": (
            "(forall ((x {concept}) (g functional_goal) (c context_state)) (= (use_{concept} x (adapt_goal_{concept} x g) c) (use_{concept} x g c)))",
            "(forall ((g functional_goal)) (= (compose_goal_{concept} empty_goal_{concept} g) g))",
            "(forall ((g functional_goal)) (= (compose_goal_{concept} g empty_goal_{concept}) g))",
            "(forall ((g functional_goal) (h functional_goal) (k functional_goal)) (= (compose_goal_{concept} (compose_goal_{concept} g h) k) (compose_goal_{concept} g (compose_goal_{concept} h k))))",
            "(forall ((x {concept}) (g functional_goal) (c context_state)) (closedUnder (use_{concept} x g c) functional_result))",
        ),
    },
    "behavioral-process": {
        "sorts": ("action_state", "process_state", "behavior_state", "context_state"),
        "operations": (
            ("act", "(-> {concept} action_state process_state process_state)"),
            ("respond", "(-> {concept} context_state behavior_state)"),
            ("compose_action", "(-> action_state action_state action_state)"),
            ("idle_action", "action_state"),
            ("observe_behavior", "(-> {concept} process_state behavior_state)"),
        ),
        "predicates": (
            "(hasActionState {concept} action_state)",
            "(hasProcessState {concept} process_state)",
            "(hasBehaviorState {concept} behavior_state)",
            "(hasBehaviorContext {concept} context_state)",
            "(relatesActionToState action_state process_state)",
        ),
        "axioms": (
            "(forall ((x {concept}) (s process_state)) (= (act_{concept} x idle_action_{concept} s) s))",
            "(forall ((a action_state)) (= (compose_action_{concept} idle_action_{concept} a) a))",
            "(forall ((a action_state)) (= (compose_action_{concept} a idle_action_{concept}) a))",
            "(forall ((a action_state) (b action_state) (c action_state)) (= (compose_action_{concept} (compose_action_{concept} a b) c) (compose_action_{concept} a (compose_action_{concept} b c))))",
            "(forall ((x {concept}) (a action_state) (b action_state) (s process_state)) (= (act_{concept} x (compose_action_{concept} a b) s) (act_{concept} x b (act_{concept} x a s))))",
        ),
    },
    "information-computational": {
        "sorts": ("program", "input_data", "computation_state", "output_data"),
        "operations": (
            ("initialize", "(-> {concept} program computation_state)"),
            ("transform", "(-> {concept} input_data computation_state computation_state)"),
            ("observe", "(-> {concept} computation_state output_data)"),
            ("empty_input", "input_data"),
            ("sequence_input", "(-> input_data input_data input_data)"),
        ),
        "predicates": (
            "(runsProgram {concept} program)",
            "(receivesInput {concept} input_data)",
            "(hasComputationState {concept} computation_state)",
            "(producesOutput {concept} output_data)",
            "(transformsState input_data computation_state)",
        ),
        "axioms": (
            "(forall ((x {concept}) (s computation_state)) (= (transform_{concept} x empty_input_{concept} s) s))",
            "(forall ((i input_data)) (= (sequence_input_{concept} empty_input_{concept} i) i))",
            "(forall ((i input_data)) (= (sequence_input_{concept} i empty_input_{concept}) i))",
            "(forall ((i input_data) (j input_data) (k input_data)) (= (sequence_input_{concept} (sequence_input_{concept} i j) k) (sequence_input_{concept} i (sequence_input_{concept} j k))))",
            "(forall ((x {concept}) (i input_data) (j input_data) (s computation_state)) (= (transform_{concept} x (sequence_input_{concept} i j) s) (transform_{concept} x j (transform_{concept} x i s))))",
        ),
    },
    "structural-composition": {
        "sorts": ("whole", "part", "material", "structure_state"),
        "operations": (
            ("assemble", "(-> {concept} part structure_state structure_state)"),
            ("detach", "(-> {concept} part structure_state structure_state)"),
            ("combine_part", "(-> part part part)"),
            ("empty_part", "part"),
            ("materialize", "(-> {concept} material whole)"),
        ),
        "predicates": (
            "(hasStructuralPart {concept} part)",
            "(partOfWhole part whole)",
            "(madeOfMaterial {concept} material)",
            "(hasStructureState {concept} structure_state)",
            "(maintainsWhole {concept} whole)",
        ),
        "axioms": (
            "(forall ((x {concept}) (s structure_state)) (= (assemble_{concept} x empty_part_{concept} s) s))",
            "(forall ((p part)) (= (combine_part_{concept} empty_part_{concept} p) p))",
            "(forall ((p part)) (= (combine_part_{concept} p empty_part_{concept}) p))",
            "(forall ((p part) (q part) (r part)) (= (combine_part_{concept} (combine_part_{concept} p q) r) (combine_part_{concept} p (combine_part_{concept} q r))))",
            "(forall ((x {concept}) (p part) (s structure_state)) (closedUnder (assemble_{concept} x p s) structure_state))",
        ),
    },
    "taxonomic-kind": {
        "sorts": ("taxonomic_kind", "classification_context", "evidence_state"),
        "operations": (
            ("classify", "(-> {concept} classification_context taxonomic_kind)"),
            ("refine_kind", "(-> taxonomic_kind evidence_state taxonomic_kind)"),
            ("merge_evidence", "(-> evidence_state evidence_state evidence_state)"),
            ("empty_evidence", "evidence_state"),
            ("observe_kind", "(-> {concept} taxonomic_kind evidence_state)"),
        ),
        "predicates": (
            "(isKindOf {concept} taxonomic_kind)",
            "(classifiedIn {concept} classification_context)",
            "(hasEvidence {concept} evidence_state)",
            "(subsortOf {concept} taxonomic_kind)",
            "(kindStableUnderEvidence taxonomic_kind evidence_state)",
        ),
        "axioms": (
            "(forall ((k taxonomic_kind)) (= (refine_kind_{concept} k empty_evidence_{concept}) k))",
            "(forall ((e evidence_state)) (= (merge_evidence_{concept} empty_evidence_{concept} e) e))",
            "(forall ((e evidence_state)) (= (merge_evidence_{concept} e empty_evidence_{concept}) e))",
            "(forall ((e evidence_state) (f evidence_state) (g evidence_state)) (= (merge_evidence_{concept} (merge_evidence_{concept} e f) g) (merge_evidence_{concept} e (merge_evidence_{concept} f g))))",
            "(forall ((x {concept}) (c classification_context) (e evidence_state)) (= (refine_kind_{concept} (classify_{concept} x c) e) (classify_{concept} x c)))",
        ),
    },
}

CORE_SCHEMA_ALIASES = {
    "artifact-kind": "taxonomic-kind",
    "role-kind": "taxonomic-kind",
    "physical-attribute": "functional-use",
    "safety-risk": "functional-use",
    "state-lifecycle": "behavioral-process",
}


SEMANTIC_OPERATION_ROLES = (
    {
        "role": "learn",
        "words": {"learn", "learning", "study", "studying", "master", "understand", "understanding"},
        "operation": "learn",
        "signature": "(-> {concept} experience_state knowledge_state knowledge_state)",
        "sorts": ("experience_state", "knowledge_state"),
        "predicate": "(canLearn {concept} knowledge_state)",
        "law": "(closedUnder {op} knowledge_state)",
    },
    {
        "role": "communicate",
        "words": {"communicate", "talk", "speak", "say", "tell", "mail", "write", "meet", "interact", "socialize"},
        "requires_kind": True,
        "operation": "communicate",
        "signature": "(-> {concept} message_state social_state social_state)",
        "sorts": ("message_state", "social_state"),
        "predicate": "(communicatesWith {concept} social_state)",
        "law": "(closedUnder {op} social_state)",
    },
    {
        "role": "reason",
        "words": {"reason", "reasoning", "think", "thinking", "infer", "decide", "judge", "question"},
        "operation": "reason",
        "signature": "(-> {concept} belief_state belief_state)",
        "sorts": ("belief_state", "knowledge_state"),
        "predicate": "(hasBeliefState {concept} belief_state)",
        "law": "(idempotentOn {op} belief_state)",
    },
    {
        "role": "perceive",
        "words": {"perceive", "see", "hear", "feel", "sense", "observe", "watch", "notice"},
        "requires_kind": True,
        "operation": "perceive",
        "signature": "(-> {concept} sensory_input experience_state)",
        "sorts": ("sensory_input", "experience_state"),
        "predicate": "(hasExperience {concept} experience_state)",
        "law": "(closedUnder {op} experience_state)",
    },
    {
        "role": "move",
        "words": {"move", "go", "walk", "run", "drive", "travel", "commute", "carry", "transport", "back", "appear"},
        "operation": "move",
        "signature": "(-> {concept} spatial_context spatial_context)",
        "sorts": ("spatial_context", "motion_state"),
        "predicate": "(changesLocation {concept} spatial_context)",
        "law": "(closedUnder {op} spatial_context)",
    },
    {
        "role": "express",
        "words": {"express", "laugh", "cry", "smile", "show", "create", "make"},
        "operation": "express",
        "signature": "(-> {concept} internal_state expression_state)",
        "sorts": ("internal_state", "expression_state"),
        "predicate": "(expressesState {concept} expression_state)",
        "law": "(closedUnder {op} expression_state)",
    },
)


FUNCTIONAL_OPERATION_ROLES = (
    {
        "role": "transport",
        "words": {"drive", "commute", "carry", "transport", "travel", "get", "getting", "move"},
        "operation": "transport",
        "signature": "(-> {concept} origin_place destination_place transport_result)",
        "sorts": ("origin_place", "destination_place", "transport_result"),
        "predicate": "(supportsTransport {concept} destination_place)",
        "law": "(closedUnder {op} transport_result)",
    },
    {
        "role": "contain",
        "words": {"carry", "hold", "store", "contain"},
        "operation": "carry",
        "signature": "(-> {concept} carried_object transport_result)",
        "sorts": ("carried_object", "transport_result"),
        "predicate": "(carriesObject {concept} carried_object)",
        "law": "(closedUnder {op} transport_result)",
    },
    {
        "role": "enable_activity",
        "words": {"fun", "work", "school", "shop", "shopping"},
        "operation": "enable_activity",
        "signature": "(-> {concept} activity_goal functional_result)",
        "sorts": ("activity_goal", "functional_result"),
        "predicate": "(enablesActivity {concept} activity_goal)",
        "law": "(closedUnder {op} functional_result)",
    },
)


HARD_REJECT_MARKERS = {
    "another_name_for",
    "another_word_for",
    "another_way_to_say",
    "both_",
    "one_kind_of",
    "one_type_of",
    "one_form_of",
    "one_individual_of",
    "popular_word",
    "singular_for",
    "sometimes_called",
    "word_people",
    "stolen_every",
}

MALFORMED_MARKERS = {
    "caculator",
    "toolds",
    "usfull",
    "inate",
    "alot",
    "fro_transportation",
}

ANECDOTAL_SURFACE_PREFIXES = (
    "my_",
    "this_",
    "that_",
    "your_",
    "his_",
    "her_",
)

VALUE_JUDGMENT_WORDS = {
    "annoying",
    "bad",
    "boring",
    "cruel",
    "dumb",
    "evil",
    "frightening",
    "fun",
    "guilty",
    "ignorant",
    "junk",
    "selfish",
    "stupid",
    "ugly",
    "weird",
    "wrong",
}

ECONOMIC_WORDS = {
    "bought",
    "buy",
    "cheap",
    "cost",
    "expensive",
    "market",
    "own",
    "ownership",
    "price",
    "sold",
}

SAFETY_WORDS = {
    "crash",
    "dangerous",
    "deadly",
    "fire",
    "hazard",
    "prone",
    "risk",
    "susceptible",
    "unsafe",
}

PHYSICAL_WORDS = {
    "black",
    "blue",
    "circular",
    "clear",
    "cold",
    "colorless",
    "odorless",
    "green",
    "hairy",
    "hard",
    "heavy",
    "hot",
    "invisible",
    "large",
    "liquid",
    "opaque",
    "orange",
    "red",
    "round",
    "shiny",
    "solid",
    "soft",
    "strong",
    "thinner",
    "transparent",
    "translucent",
    "white",
}

SPATIAL_WORDS = {
    "behind",
    "between",
    "driveway",
    "inside",
    "into",
    "left",
    "line",
    "near",
    "on",
    "outside",
    "place",
    "standing",
    "turning",
}

TEMPORAL_WORDS = {
    "annual",
    "daily",
    "frequent",
    "morning",
    "new",
    "old",
    "recent",
    "regular",
    "regularly",
    "sometimes",
    "times",
    "upgraded",
}

FUNCTIONAL_WORDS = {
    "able",
    "capable",
    "convenient",
    "easy",
    "function",
    "good_at",
    "hard_to_use",
    "help",
    "powered",
    "purpose",
    "reduce",
    "tool_to",
    "use",
    "used",
    "way_to",
}

INFORMATION_WORDS = {
    "arithmetic",
    "calculate",
    "computational",
    "data",
    "digital",
    "electronic",
    "hardware",
    "information",
    "mathematics",
    "numbers",
    "recording",
    "software",
}

PROCESS_WORDS = {
    "getting",
    "hurrying",
    "learning",
    "passing",
    "pushing",
    "reducing",
    "rolling",
    "standing",
    "turning",
}

STRUCTURAL_WORDS = {
    "component",
    "composed",
    "contains",
    "part",
    "portion",
    "structure",
    "within",
}

ARTIFACT_KIND_WORDS = {
    "appliance",
    "appliances",
    "artifact",
    "artifacts",
    "building",
    "buildings",
    "device",
    "devices",
    "equipment",
    "hardware",
    "instrument",
    "instruments",
    "machine",
    "machines",
    "structure",
    "structures",
    "system",
    "systems",
    "tool",
    "tools",
    "vehicle",
    "vehicles",
}

TAXONOMIC_KIND_WORDS = {
    "accommodation",
    "artifact",
    "building",
    "device",
    "electronic_device",
    "equipment",
    "event",
    "gas",
    "housing",
    "machine",
    "medium",
    "motor_vehicle",
    "place_to_live",
    "place_to_live_in",
    "process",
    "quality",
    "region",
    "structure",
    "tool",
    "vehicle",
    "wheeled_vehicle",
}


AGENT_KIND_WORDS = {
    "agent", "animal", "animals", "being", "bird", "birds", "child", "creature",
    "human", "humans", "mammal", "mammals", "organism", "person", "people",
    "worker", "student", "teacher", "doctor", "lawyer", "parent", "friend",
}

PLACE_KIND_WORDS = {
    "area", "building", "city", "country", "home", "house", "location", "place",
    "region", "room", "school", "store", "world",
}

SUBSTANCE_KIND_WORDS = {
    "chemical", "food", "gas", "liquid", "material", "metal", "solid", "substance", "water",
}

INFO_OBJECT_KIND_WORDS = {
    "book", "document", "file", "image", "information", "language", "message", "record",
    "signal", "software", "story", "symbol", "text", "word",
}

FRAME_OPERATION_ROLES = (
    {
        "role": "communicate",
        "perspectives": {"behavioral-process", "social-normative"},
        "words": {"conversation", "friend", "language", "message", "speech", "social", "society", "talk", "word"},
        "kind_words": AGENT_KIND_WORDS,
        "operation": "communicate",
        "signature": "(-> {concept} message_state social_state social_state)",
        "sorts": ("message_state", "social_state"),
        "law": "(closedUnder {op} social_state)",
        "bonus": 0.24,
    },
    {
        "role": "move",
        "perspectives": {"behavioral-process", "spatial-context"},
        "words": {"leg", "legs", "motion", "place", "run", "spatial", "travel", "walk", "wing", "wings"},
        "kind_words": AGENT_KIND_WORDS | {"vehicle", "vehicles"},
        "operation": "move",
        "signature": "(-> {concept} spatial_context spatial_context)",
        "sorts": ("spatial_context", "motion_state"),
        "law": "(closedUnder {op} spatial_context)",
        "bonus": 0.22,
    },
    {
        "role": "perceive",
        "perspectives": {"behavioral-process", "information-computational"},
        "words": {"eye", "eyes", "ear", "ears", "sense", "sound", "vision", "visual"},
        "kind_words": AGENT_KIND_WORDS,
        "operation": "perceive",
        "signature": "(-> {concept} sensory_input experience_state)",
        "sorts": ("sensory_input", "experience_state"),
        "law": "(closedUnder {op} experience_state)",
        "bonus": 0.20,
    },
    {
        "role": "consume",
        "perspectives": {"behavioral-process", "functional-use"},
        "words": {"drink", "eat", "food", "meal", "nutrition", "water"},
        "kind_words": AGENT_KIND_WORDS,
        "requires_kind": True,
        "operation": "consume",
        "signature": "(-> {concept} resource_state body_state body_state)",
        "sorts": ("resource_state", "body_state"),
        "law": "(closedUnder {op} body_state)",
        "bonus": 0.18,
    },
    {
        "role": "cut",
        "perspectives": {"functional-use", "structural-composition"},
        "words": {"blade", "cut", "cutting", "edge", "knife", "sharp", "slice"},
        "kind_words": {"instrument", "tool", "tools", "utensil"},
        "operation": "cut",
        "signature": "(-> {concept} material_state material_state)",
        "sorts": ("material_state",),
        "law": "(closedUnder {op} material_state)",
        "bonus": 0.30,
    },
    {
        "role": "contain",
        "perspectives": {"functional-use", "structural-composition", "spatial-context"},
        "words": {"bag", "bottle", "box", "container", "inside", "room", "space", "store", "storage"},
        "kind_words": PLACE_KIND_WORDS | {"container", "vessel"},
        "operation": "contain",
        "signature": "(-> {concept} contained_object container_state container_state)",
        "sorts": ("contained_object", "container_state"),
        "law": "(closedUnder {op} container_state)",
        "bonus": 0.24,
    },
    {
        "role": "transport",
        "perspectives": {"functional-use", "spatial-context"},
        "words": {"car", "road", "ship", "train", "transport", "travel", "vehicle", "wheel", "wheels"},
        "kind_words": {"vehicle", "vehicles", "motor_vehicle", "wheeled_vehicle"},
        "operation": "transport",
        "signature": "(-> {concept} origin_place destination_place transport_result)",
        "sorts": ("origin_place", "destination_place", "transport_result"),
        "law": "(closedUnder {op} transport_result)",
        "bonus": 0.28,
    },
    {
        "role": "compute",
        "perspectives": {"information-computational", "functional-use"},
        "words": {"algorithm", "arithmetic", "calculate", "computer", "data", "digital", "number", "numbers", "program", "software"},
        "kind_words": INFORMATION_WORDS | {"computer", "device", "machine"},
        "operation": "compute",
        "signature": "(-> {concept} input_data computation_state computation_state)",
        "sorts": ("input_data", "computation_state", "output_data"),
        "law": "(closedUnder {op} computation_state)",
        "bonus": 0.30,
    },
    {
        "role": "encode",
        "perspectives": {"information-computational", "descriptive-property"},
        "words": {"book", "document", "file", "information", "language", "message", "record", "symbol", "text", "word"},
        "kind_words": INFO_OBJECT_KIND_WORDS,
        "operation": "encode",
        "signature": "(-> {concept} meaning_state information_state)",
        "sorts": ("meaning_state", "information_state"),
        "law": "(closedUnder {op} information_state)",
        "bonus": 0.22,
    },
    {
        "role": "support",
        "perspectives": {"functional-use", "structural-composition"},
        "words": {"base", "building", "floor", "foundation", "hold", "leg", "support", "table"},
        "kind_words": {"building", "structure", "tool"},
        "operation": "support",
        "signature": "(-> {concept} load_state structure_state structure_state)",
        "sorts": ("load_state", "structure_state"),
        "law": "(closedUnder {op} structure_state)",
        "bonus": 0.20,
    },
    {
        "role": "transform_material",
        "perspectives": {"functional-use", "structural-composition"},
        "words": {"change", "chemical", "cook", "heat", "liquid", "material", "mix", "produce", "substance", "water"},
        "kind_words": SUBSTANCE_KIND_WORDS,
        "operation": "transform",
        "signature": "(-> {concept} material_state material_state)",
        "sorts": ("material_state",),
        "law": "(closedUnder {op} material_state)",
        "bonus": 0.18,
    },
)

RELATION_ONLY_PREDICATES = {
    "hasPrerequisite", "hasSubevent", "UsedFor", "ReceivesAction", "Causes", "Entails",
    "CausesDesire", "HasA", "PartOf", "MadeOf", "AtLocation", "LocatedNear",
    "HasContext", "CreatedBy", "RelatedTo", "isA", "InstanceOf", "hasproperty",
}

CAPABILITY_PREDICATE_RELATIONS = {"CapableOf"}

ACTION_TARGET_WORDS = {
    "act", "appear", "become", "break", "bring", "build", "burn", "carry", "change",
    "clean", "close", "compose", "connect", "create", "cut", "develop", "drive",
    "eat", "flow", "form", "generate", "go", "grow", "heat", "hold", "keep",
    "learn", "make", "move", "open", "produce", "protect", "receive", "reduce",
    "respond", "run", "serve", "store", "support", "take", "transform", "turn",
    "use", "walk", "work",
}

NON_OPERATION_TARGET_WORDS = ECONOMIC_WORDS | SPATIAL_WORDS | VALUE_JUDGMENT_WORDS | {
    "cost", "price", "south", "street", "storm", "tall", "weather", "year", "years",
}


@dataclass(frozen=True)
class Record:
    relation: str
    source: str
    target: str
    weight: float
    surface_text: str
    source_file: str
    order: int


@dataclass(frozen=True)
class Classification:
    perspective: str
    target_type: str
    score_bonus: float = 0.0
    reject_reason: str | None = None


@dataclass(frozen=True)
class Candidate:
    group: tuple
    key: tuple
    score: float
    order: int
    lines: tuple


def tokenize_metta_atom(line):
    text = line.strip()
    if not (text.startswith("(") and text.endswith(")")):
        return None

    text = text[1:-1].strip()
    tokens = []
    i = 0

    while i < len(text):
        while i < len(text) and text[i].isspace():
            i += 1
        if i >= len(text):
            break

        if text[i] == "'":
            start = i
            i += 1
            escaped = False
            while i < len(text):
                ch = text[i]
                if ch == "'" and not escaped:
                    i += 1
                    break
                escaped = ch == "\\" and not escaped
                if ch != "\\":
                    escaped = False
                i += 1
            tokens.append(text[start:i])
            continue

        if text[i] == "(":
            start = i
            depth = 0
            while i < len(text):
                if text[i] == "(":
                    depth += 1
                elif text[i] == ")":
                    depth -= 1
                    if depth == 0:
                        i += 1
                        break
                i += 1
            tokens.append(text[start:i])
            continue

        start = i
        while i < len(text) and not text[i].isspace():
            i += 1
        tokens.append(text[start:i])

    return tokens


def parse_float(value, default=1.0):
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def safe_metta_symbol(atom):
    text = atom[1:-1] if atom[:1] == chr(39) and atom[-1:] == chr(39) else atom
    text = text.strip("()")
    text = re.sub(r"\s+", "_", text)
    text = re.sub(r"[^A-Za-z0-9_]", "_", text)
    text = re.sub(r"_+", "_", text).strip("_")
    if not text or not re.match(r"^[A-Za-z_]", text):
        text = f"c_{text}"
    return text


def iter_input_paths(inputs):
    for raw in inputs:
        path = Path(raw)
        if path.is_dir():
            yield from sorted(path.rglob("*.metta"))
        elif path.exists():
            yield path


def iter_records_from_file(path):
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
            canonical_relation = RELATION_ALIASES.get(head)
            if canonical_relation and len(tokens) >= 3:
                record = flush()
                if record:
                    yield record
                current = {
                    "relation": canonical_relation,
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


def iter_records(inputs):
    for path in iter_input_paths(inputs):
        yield from iter_records_from_file(path)


def stv_from_weight(weight, confidence_floor=0.4):
    evidence = max(weight, 0.1)
    score = math.log1p(evidence)
    strength = min(0.98, max(0.55, 0.55 + (score / 7.0)))
    confidence = min(0.94, max(confidence_floor, confidence_floor + (score / 9.0)))
    return f"(stv {strength:.3f} {confidence:.3f})"


def strip_quotes(atom):
    return atom[1:-1] if atom.startswith("'") and atom.endswith("'") else atom


def plain_name(atom):
    text = strip_quotes(atom)
    text = text.strip("()")
    text = re.sub(r"\s+", "_", text)
    return text


def word_tokens(atom):
    text = plain_name(atom).lower()
    return tuple(token for token in re.split(r"[_\W]+", text) if token)


def joined(atom):
    return "_".join(word_tokens(atom))


def atom_id(*parts):
    raw = "-".join(plain_name(str(part)) for part in parts)
    normalized = re.sub(r"[^A-Za-z0-9_]+", "_", raw)
    normalized = re.sub(r"_+", "_", normalized).strip("_")
    return normalized or "feature"


def operation_name(prefix, target):
    name = atom_id(prefix, target).replace("-", "_")
    if not re.match(r"^[A-Za-z_]", name):
        name = f"{prefix}_{name}"
    return name


RELATION_HEAD_RE = re.compile(r"(\(\s*)([A-Z])")


def lowercase_relation_heads(text):
    """Keep emitted relation heads valid as unquoted PeTTa/Prolog atoms."""

    return RELATION_HEAD_RE.sub(
        lambda match: f"{match.group(1)}{match.group(2).lower()}",
        text,
    )


def static_safe_text(text):
    text = text.replace("->", "arrow")
    text = re.sub(r"(?<=[A-Za-z0-9_])[-+](?=[A-Za-z0-9_])", "_", text)
    text = re.sub(r"(?<![A-Za-z0-9_])[-+](?=[A-Za-z0-9_])", "_", text)
    return lowercase_relation_heads(text)


def fact(proof, statement, tv):
    return f"(: {static_safe_text(proof)} (≞ {static_safe_text(statement)} {tv}))"


def has_any_marker(text, markers):
    return any(marker in text for marker in markers)


def has_any_word(tokens, words):
    token_set = set(tokens)
    return bool(token_set.intersection(words))


def is_comparative_target(text, tokens):
    if "_than_" in text or "different_from" in text:
        return True
    comparative_words = {
        "better",
        "bigger",
        "cheaper",
        "faster",
        "heavier",
        "larger",
        "less",
        "lighter",
        "more",
        "slower",
        "smaller",
    }
    return has_any_word(tokens, comparative_words)


def surface_is_anecdotal(record):
    surface = joined(record.surface_text)
    return surface.startswith(ANECDOTAL_SURFACE_PREFIXES)


def reject_reason(record):
    target = joined(record.target)
    surface = joined(record.surface_text)

    if has_any_marker(target, HARD_REJECT_MARKERS):
        return "lexical-alias-or-metalinguistic-target"
    if has_any_marker(target, MALFORMED_MARKERS):
        return "malformed-target"
    if surface and surface_is_anecdotal(record):
        return "anecdotal-surface-text"
    return None


def classify_is_a(record):
    target = joined(record.target)
    tokens = word_tokens(record.target)

    if is_comparative_target(target, tokens):
        return Classification("quantitative-comparative", "comparative", -0.3)
    if has_any_word(tokens, VALUE_JUDGMENT_WORDS) or target.startswith("not_"):
        return Classification("social-normative", "evaluation", -0.2)
    if has_any_word(tokens, SPATIAL_WORDS) or target.startswith("in_"):
        return Classification("spatial-context", "spatial-context", -0.1)
    if has_any_word(tokens, TEMPORAL_WORDS):
        return Classification("temporal-context", "temporal-context", -0.1)
    if has_any_word(tokens, PROCESS_WORDS):
        return Classification("behavioral-process", "process", -0.1)
    if has_any_word(tokens, STRUCTURAL_WORDS):
        return Classification("structural-composition", "structural-relation", 0.08)
    if has_any_marker(target, FUNCTIONAL_WORDS) or has_any_word(tokens, FUNCTIONAL_WORDS):
        return Classification("functional-use", "function", 0.05)
    if has_any_word(tokens, ECONOMIC_WORDS):
        return Classification("economic-ownership", "economic-property", 0.08)
    if has_any_word(tokens, SAFETY_WORDS):
        return Classification("safety-risk", "risk-condition", 0.08)
    if target in TAXONOMIC_KIND_WORDS or has_any_word(tokens, ARTIFACT_KIND_WORDS):
        perspective = "artifact-kind" if has_any_word(tokens, ARTIFACT_KIND_WORDS) else "taxonomic-kind"
        return Classification(perspective, "kind", 0.35)
    if has_any_word(tokens, INFORMATION_WORDS):
        return Classification("information-computational", "information-kind", 0.18)
    if len(tokens) <= 3 and not has_any_word(tokens, PROCESS_WORDS | VALUE_JUDGMENT_WORDS):
        return Classification("taxonomic-kind", "kind", 0.05)

    return Classification("descriptive-property", "weak-description", -0.25)


def classify_has_property(record):
    target = joined(record.target)
    tokens = word_tokens(record.target)

    if is_comparative_target(target, tokens):
        return Classification("quantitative-comparative", "comparative", -0.25)
    if has_any_word(tokens, SAFETY_WORDS):
        return Classification("safety-risk", "risk-condition", 0.22)
    if has_any_marker(target, INFORMATION_WORDS) or has_any_word(tokens, INFORMATION_WORDS):
        return Classification("information-computational", "information-property", 0.25)
    if has_any_marker(target, FUNCTIONAL_WORDS) or has_any_word(tokens, FUNCTIONAL_WORDS):
        return Classification("functional-use", "capability", 0.2)
    if has_any_word(tokens, ECONOMIC_WORDS):
        return Classification("economic-ownership", "economic-property", 0.18)
    if has_any_word(tokens, PHYSICAL_WORDS):
        return Classification("physical-attribute", "physical-property", 0.18)
    if target in TAXONOMIC_KIND_WORDS or has_any_word(tokens, ARTIFACT_KIND_WORDS):
        return Classification(
            "taxonomic-kind",
            "kind-as-property",
            reject_reason="property-relation-targets-kind",
        )
    if has_any_word(tokens, TEMPORAL_WORDS):
        return Classification("state-lifecycle", "state-condition", 0.05)
    if has_any_word(tokens, SPATIAL_WORDS) or target.startswith("in_"):
        return Classification("spatial-context", "spatial-state", -0.05)
    if has_any_word(tokens, PROCESS_WORDS):
        return Classification("behavioral-process", "process-state", -0.05)
    if has_any_word(tokens, VALUE_JUDGMENT_WORDS):
        return Classification("social-normative", "evaluation", -0.2)
    if len(tokens) > 5:
        return Classification("descriptive-property", "weak-description", -0.15)

    return Classification("descriptive-property", "property", 0.0)


def classify_record(record, keep_noisy_targets=False):
    reason = reject_reason(record)
    if reason and not keep_noisy_targets:
        return Classification("descriptive-property", "rejected", reject_reason=reason)

    if record.relation in {"isA", "InstanceOf"}:
        return classify_is_a(record)
    if record.relation == "hasproperty":
        return classify_has_property(record)
    if record.relation == "hasPrerequisite":
        return Classification("causal-prerequisite", "precondition", 0.2)
    if record.relation == "hasSubevent":
        return Classification("behavioral-process", "subevent", 0.2)
    if record.relation == "UsedFor":
        return Classification("functional-use", "purpose-operation", 0.32)
    if record.relation == "CapableOf":
        return Classification("behavioral-process", "capability-operation", 0.28)
    if record.relation == "ReceivesAction":
        return Classification("behavioral-process", "received-action-operation", 0.18)
    if record.relation in {"Causes", "Entails"}:
        return Classification("behavioral-process", "effect-operation", 0.22)
    if record.relation == "CausesDesire":
        return Classification("social-normative", "desire-effect-operation", 0.16)
    if record.relation in {"HasA", "PartOf", "MadeOf"}:
        return Classification("structural-composition", "composition-operation", 0.26)
    if record.relation in {"AtLocation", "LocatedNear"}:
        return Classification("spatial-context", "location-operation", 0.16)
    if record.relation == "HasContext":
        return Classification("descriptive-property", "contextual-domain", 0.08)
    if record.relation == "CreatedBy":
        return Classification("causal-prerequisite", "creator-operation", 0.14)
    if record.relation == "RelatedTo":
        tokens = word_tokens(record.target)
        if has_any_word(tokens, PROCESS_WORDS) or semantic_role_for(record, SEMANTIC_OPERATION_ROLES):
            return Classification("behavioral-process", "related-process", 0.06)
        if has_any_word(tokens, FUNCTIONAL_WORDS) or semantic_role_for(record, FUNCTIONAL_OPERATION_ROLES):
            return Classification("functional-use", "related-function", 0.04)
        return Classification("descriptive-property", "related-context", -0.08)

    return Classification("descriptive-property", "unknown", reject_reason="unsupported-relation")


def surface_quality(record):
    surface = joined(record.surface_text)
    quality = 0.0
    if not surface or surface == "na":
        return quality
    if "_is_a_" in surface or "_is_an_" in surface or "_is_type_of_" in surface:
        quality += 0.2
    if "_can_be_" in surface or surface.startswith("some_"):
        quality -= 0.12
    if "_generally_" in surface:
        quality += 0.06
    return quality


def target_quality(record, classification):
    target = joined(record.target)
    tokens = word_tokens(record.target)
    quality = classification.score_bonus

    if 1 <= len(tokens) <= 3:
        quality += 0.12
    elif len(tokens) >= 6:
        quality -= 0.2
    if target in TAXONOMIC_KIND_WORDS:
        quality += 0.25
    if classification.target_type in {"weak-description", "evaluation", "spatial-state"}:
        quality -= 0.18

    return quality


def base_score(record, classification):
    return math.log1p(max(record.weight, 0.1)) + target_quality(record, classification) + surface_quality(record)


def candidate(group, key, score, order, *lines):
    return Candidate(group=group, key=key, score=score, order=order, lines=tuple(lines))



def core_schema_for(perspective):
    return CORE_SCHEMAS.get(CORE_SCHEMA_ALIASES.get(perspective, perspective))



def source_implied_core_perspectives(record):
    source_tokens = set(word_tokens(record.source))
    source_name = joined(record.source)
    implied = []

    if source_name == "computer" or source_tokens.intersection(INFORMATION_WORDS):
        implied.append(Classification("information-computational", "source-information-role", 0.3))
    if source_tokens.intersection(ARTIFACT_KIND_WORDS):
        implied.append(Classification("artifact-kind", "source-artifact-role", 0.2))

    return implied



def source_implied_frame_perspectives(record):
    source_tokens = set(word_tokens(record.source))
    taxonomy_tokens = set()
    if record.relation in {"isA", "InstanceOf"}:
        target_tokens = word_tokens(record.target)
        taxonomy_tokens.add(joined(record.target))
        if len(target_tokens) == 1:
            taxonomy_tokens.update(target_tokens)
    tokens = source_tokens | taxonomy_tokens
    implied = []

    if tokens.intersection(AGENT_KIND_WORDS):
        implied.append(Classification("behavioral-process", "frame-agent-role", 0.18))
    if tokens.intersection(ARTIFACT_KIND_WORDS | {"tool", "vehicle", "machine", "instrument"}):
        implied.append(Classification("functional-use", "frame-artifact-role", 0.18))
    if tokens.intersection(INFORMATION_WORDS | INFO_OBJECT_KIND_WORDS):
        implied.append(Classification("information-computational", "frame-information-role", 0.18))
    if tokens.intersection(PLACE_KIND_WORDS):
        implied.append(Classification("spatial-context", "frame-place-role", 0.12))
        implied.append(Classification("functional-use", "frame-place-function-role", 0.08))
    if tokens.intersection(SUBSTANCE_KIND_WORDS):
        implied.append(Classification("functional-use", "frame-substance-role", 0.10))

    return implied



def inverse_core_evidence(record, classification):
    if record.relation == "PartOf":
        return ((record.target, Classification("structural-composition", "inverse-part-whole", 0.24)),)
    return ()



def format_core_template(template, concept):
    return template.format(concept=concept)



def core_operation_name(prefix, concept):
    return operation_name(prefix, concept)



def core_schema_candidates(source, perspective, evidence):
    schema = core_schema_for(perspective)
    if not schema or not evidence:
        return []

    rep_record, rep_classification = min(evidence, key=lambda item: item[0].order)
    evidence_score = max(base_score(record, classification) for record, classification in evidence)
    score = evidence_score + min(0.25, 0.08 * math.log1p(len(evidence))) - 0.18
    tv = stv_from_weight(sum(max(record.weight, 0.1) for record, _classification in evidence) / len(evidence), 0.62)
    sort_tv = "(stv 0.900 0.860)"
    signature_tv = "(stv 0.900 0.860)"
    items = []

    sort_names = (source,) + tuple(schema["sorts"])
    for sort_name in sort_names:
        proof = atom_id("core", "sort", source, perspective, sort_name)
        items.append(
            candidate(
                (source, perspective, "sorts"),
                ("sort", source, perspective, sort_name),
                score + (0.08 if sort_name == source else -0.04),
                rep_record.order,
                fact(proof, f"(has-sort {proof} {source} {perspective} {sort_name})", sort_tv),
            )
        )

    operation_names = {}
    for op_prefix, signature_template in schema["operations"]:
        op = core_operation_name(op_prefix, source)
        operation_names[op_prefix] = op
        signature = format_core_template(signature_template, source)
        stem = atom_id("core", "operation", source, perspective, op_prefix)
        items.append(
            candidate(
                (source, perspective, "operations"),
                ("operation", source, perspective, op),
                score - 0.30,
                rep_record.order,
                fact(f"{stem}-operation", f"(has-operation {stem}-operation {source} {perspective} {op})", tv),
                fact(f"{stem}-signature", f"(operation-signature {stem}-operation {signature})", signature_tv),
            )
        )

    for index, predicate_template in enumerate(schema["predicates"]):
        predicate = format_core_template(predicate_template, source)
        stem = atom_id("core", "predicate", source, perspective, index)
        items.append(
            candidate(
                (source, perspective, "predicates"),
                ("predicate", source, perspective, predicate),
                score - 0.36,
                rep_record.order,
                fact(f"{stem}-predicate", f"(has-predicate {stem}-predicate {source} {perspective} {predicate})", tv),
            )
        )

    for index, axiom_template in enumerate(schema["axioms"]):
        axiom = format_core_template(axiom_template, source)
        stem = atom_id("core", "axiom", source, perspective, index)
        items.append(
            candidate(
                (source, perspective, "axioms"),
                ("axiom", source, perspective, "core", index),
                score - 0.18,
                rep_record.order,
                fact(f"{stem}-axiom", f"(has-axiom {stem}-axiom {source} {perspective} {axiom})", tv),
            )
        )

    return items



def generic_sort_candidate(record, perspective, sort_name, classification, confidence=0.72, bonus=0.0):
    proof = atom_id("alg", "sort", record.source, perspective, sort_name)
    tv = f"(stv 0.760 {confidence:.3f})"
    return candidate(
        (record.source, perspective, "sorts"),
        ("sort", record.source, perspective, sort_name),
        base_score(record, classification) + bonus,
        record.order,
        fact(proof, f"(has-sort {proof} {record.source} {perspective} {sort_name})", tv),
    )


def predicate_for(record, classification):
    source, target = record.source, record.target
    if classification.perspective == "functional-use":
        return f"(hasFunction {source} {target})"
    if classification.perspective == "safety-risk":
        return f"(hasRisk {source} {target})"
    if classification.perspective == "economic-ownership":
        return f"(hasEconomicproperty {source} {target})"
    if classification.perspective == "information-computational":
        return f"(hasInformationproperty {source} {target})"
    if classification.perspective == "spatial-context":
        return f"(hasSpatialContext {source} {target})"
    if classification.perspective == "temporal-context":
        return f"(hasTemporalContext {source} {target})"
    if classification.perspective == "state-lifecycle":
        return f"(hasstate_condition {source} {target})"
    if classification.perspective == "quantitative-comparative":
        return f"(hasComparison {source} {target})"
    if classification.perspective == "social-normative":
        return f"(hasSocialEvaluation {source} {target})"
    if classification.perspective == "behavioral-process" and record.relation == "hasproperty":
        return f"(hasbehavior_state {source} {target})"
    if record.relation == "hasproperty":
        return f"(hasproperty {source} {target})"
    if record.relation == "InstanceOf":
        return f"(instanceOf {source} {target})"
    return f"({record.relation} {source} {target})"


def axiom_for(record, classification, predicate):
    source, target = record.source, record.target
    if classification.perspective == "functional-use":
        return f"(=> {predicate} (hasRole {target} {source}))"
    if classification.perspective == "safety-risk":
        return f"(=> {predicate} (riskOf {target} {source}))"
    if classification.perspective == "economic-ownership":
        return f"(=> {predicate} (economicFeatureOf {target} {source}))"
    if classification.perspective == "information-computational":
        return f"(=> {predicate} (informationFeatureOf {target} {source}))"
    if classification.perspective == "spatial-context":
        return f"(=> {predicate} (spatialContextOf {target} {source}))"
    if classification.perspective == "temporal-context":
        return f"(=> {predicate} (temporalContextOf {target} {source}))"
    if classification.perspective == "state-lifecycle":
        return f"(=> {predicate} (stateConditionOf {target} {source}))"
    if classification.perspective == "quantitative-comparative":
        return f"(=> {predicate} (comparisonOf {target} {source}))"
    if classification.perspective == "social-normative":
        return f"(=> {predicate} (socialEvaluationOf {target} {source}))"
    return f"(=> {predicate} (propertyOf {target} {source}))"


def operation_for_property(record, classification):
    target = joined(record.target)
    if classification.perspective == "physical-attribute":
        return operation_name("measure", target), "(-> concept_instance physical_attribute)"
    if classification.perspective == "functional-use":
        return operation_name("use_for", target), "(-> concept_instance functional_result)"
    if classification.perspective == "economic-ownership":
        return operation_name("assess", target), "(-> concept_instance economic_value)"
    if classification.perspective == "information-computational":
        if "arithmetic" in target:
            return "compute_arithmetic", "(-> concept_instance information_state)"
        if "numbers" in target:
            return "compute_numbers", "(-> concept_instance information_state)"
        return operation_name("process", target), "(-> concept_instance information_state)"
    if classification.perspective == "safety-risk":
        return operation_name("assess_risk", target), "(-> concept_instance risk_condition)"
    if classification.perspective == "state-lifecycle":
        return operation_name("observe_state", target), "(-> concept_instance state_condition)"
    if classification.perspective == "behavioral-process":
        return operation_name("behavior", target), "(-> process_state process_state)"
    return None, None


def signature_codomain(signature):
    atoms = re.findall(r"[A-Za-z_][A-Za-z0-9_]*", signature)
    return atoms[-1] if atoms else "concept_instance"


def operation_law(op, law):
    return f"(operationLaw {op} {law})"


def closed_under_law(op, signature):
    return operation_law(op, f"(closedUnder {op} {signature_codomain(signature)})")


def operation_candidate(record, perspective, stem, op, signature, score, tv, bonus=0.0):
    return candidate(
        (record.source, perspective, "operations"),
        ("operation", record.source, perspective, op),
        score + bonus,
        record.order,
        fact(f"{stem}-operation", f"(has-operation {stem}-operation {record.source} {perspective} {op})", tv),
        fact(f"{stem}-signature", f"(operation-signature {stem}-operation {signature})", "(stv 0.880 0.820)"),
    )


def axiom_candidate(record, perspective, stem, key, axiom, score, tv, bonus=0.0):
    return candidate(
        (record.source, perspective, "axioms"),
        ("axiom", record.source, perspective, key, record.target),
        score + bonus,
        record.order,
        fact(f"{stem}-axiom", f"(has-axiom {stem}-axiom {record.source} {perspective} {axiom})", tv),
    )


def operation_relation_candidates(record, classification, op_prefix, signature, predicate_name, law_body, extra_sorts=(), emit_predicate=True):
    perspective = classification.perspective
    source, target = record.source, record.target
    score = base_score(record, classification)
    tv = stv_from_weight(record.weight)
    stem = atom_id("alg", record.relation.lower(), source, target, perspective)
    op = atom_id(op_prefix, source, target).replace("-", "_")
    predicate = f"({predicate_name} {source} {target})"
    items = []

    for sort_name in PERSPECTIVE_SORTS.get(perspective, ("concept_instance", "context_feature")) + tuple(extra_sorts):
        items.append(generic_sort_candidate(record, perspective, sort_name, classification))

    items.append(operation_candidate(record, perspective, stem, op, signature, score, tv, bonus=0.08))
    if emit_predicate:
        items.append(
            candidate(
                (source, perspective, "predicates"),
                ("predicate", source, perspective, predicate),
                score,
                record.order,
                fact(f"{stem}-predicate", f"(has-predicate {stem}-predicate {source} {perspective} {predicate})", tv),
            )
        )
    items.append(
        axiom_candidate(
            record,
            perspective,
            stem,
            "operationLaw",
            operation_law(op, law_body.format(op=op, source=source, target=target, signature=signature)),
            score,
            tv,
        )
    )
    return items


def semantic_role_for(record, role_specs):
    tokens = set(word_tokens(record.target))
    target_name = joined(record.target)
    for role in role_specs:
        if target_name == role["role"] or tokens.intersection(role["words"]):
            return role
    return None



def semantic_operation_candidates(record, classification, role, predicate_name):
    perspective = classification.perspective
    source, target = record.source, record.target
    score = base_score(record, classification) + 0.42
    tv = stv_from_weight(record.weight)
    stem = atom_id("semantic", role["role"], source, perspective)
    op = operation_name(role["operation"], source)
    signature = role["signature"].format(concept=source)
    predicate = role["predicate"].format(concept=source, target=target)
    law = role["law"].format(op=op, concept=source, target=target, signature=signature)
    items = []

    for sort_name in tuple(role.get("sorts", ())) + PERSPECTIVE_SORTS.get(perspective, ()):
        items.append(generic_sort_candidate(record, perspective, sort_name, classification, confidence=0.78, bonus=0.18))

    items.append(operation_candidate(record, perspective, stem, op, signature, score, tv, bonus=0.22))
    if record.relation not in CAPABILITY_PREDICATE_RELATIONS and predicate_name in RELATION_ONLY_PREDICATES:
        items.append(
            candidate(
                (source, perspective, "predicates"),
                ("predicate", source, perspective, predicate_name, target),
                score - 0.06,
                record.order,
                fact(f"{stem}-evidence-predicate", f"(has-predicate {stem}-evidence-predicate {source} {perspective} ({predicate_name} {source} {target}))", tv),
            )
        )
    items.append(
        axiom_candidate(
            record,
            perspective,
            stem,
            role["role"],
            operation_law(op, law),
            score + 0.06,
            tv,
        )
    )
    return items


def candidates_for_taxonomic(record, classification):
    perspective = classification.perspective
    source, target = record.source, record.target
    score = base_score(record, classification)
    tv = stv_from_weight(record.weight)
    stem = atom_id("alg", "isa", source, target)
    return [
        candidate(
            (source, perspective, "sorts"),
            ("sort", source, perspective, target),
            score + 0.35,
            record.order,
            fact(f"{stem}-sort", f"(has-sort {stem}-sort {source} {perspective} {target})", tv),
        ),
        candidate(
            (source, perspective, "predicates"),
            ("predicate", source, perspective, "isA", target),
            score,
            record.order,
            fact(f"{stem}-predicate", f"(has-predicate {stem}-predicate {source} {perspective} (isA {source} {target}))", tv),
        ),
        candidate(
            (source, perspective, "axioms"),
            ("axiom", source, perspective, "subsort", target),
            score,
            record.order,
            fact(
                f"{stem}-axiom",
                f"(has-axiom {stem}-axiom {source} {perspective} (=> (isA {source} {target}) (subsort {source} {target})))",
                tv,
            ),
        ),
    ]


def candidates_for_is_a(record, classification):
    if classification.perspective in {"taxonomic-kind", "artifact-kind", "role-kind"}:
        return candidates_for_taxonomic(record, classification)

    perspective = classification.perspective
    source, target = record.source, record.target
    score = base_score(record, classification)
    tv = stv_from_weight(record.weight)
    stem = atom_id("alg", "isa", source, target, perspective)
    predicate = predicate_for(record, classification)
    axiom = axiom_for(record, classification, predicate)
    items = []

    for sort_name in PERSPECTIVE_SORTS.get(perspective, ("concept_instance", "context_feature")):
        items.append(generic_sort_candidate(record, perspective, sort_name, classification))

    items.extend(
        [
            candidate(
                (source, perspective, "predicates"),
                ("predicate", source, perspective, predicate),
                score,
                record.order,
                fact(f"{stem}-predicate", f"(has-predicate {stem}-predicate {source} {perspective} {predicate})", tv),
            ),
            candidate(
                (source, perspective, "axioms"),
                ("axiom", source, perspective, axiom),
                score,
                record.order,
                fact(f"{stem}-axiom", f"(has-axiom {stem}-axiom {source} {perspective} {axiom})", tv),
            ),
        ]
    )
    return items


def candidates_for_has_property(record, classification):
    perspective = classification.perspective
    source, target = record.source, record.target
    score = base_score(record, classification)
    tv = stv_from_weight(record.weight)
    stem = atom_id("alg", "property", source, target, perspective)
    predicate = predicate_for(record, classification)
    axiom = axiom_for(record, classification, predicate)
    items = []

    for sort_name in PERSPECTIVE_SORTS.get(perspective, ("concept_instance", "property")):
        items.append(generic_sort_candidate(record, perspective, sort_name, classification))

    items.extend(
        [
            candidate(
                (source, perspective, "predicates"),
                ("predicate", source, perspective, predicate),
                score,
                record.order,
                fact(f"{stem}-predicate", f"(has-predicate {stem}-predicate {source} {perspective} {predicate})", tv),
            ),
            candidate(
                (source, perspective, "axioms"),
                ("axiom", source, perspective, axiom),
                score,
                record.order,
                fact(f"{stem}-axiom", f"(has-axiom {stem}-axiom {source} {perspective} {axiom})", tv),
            ),
        ]
    )
    return items


def candidates_for_has_prerequisite(record, classification):
    perspective = classification.perspective
    source, target = record.source, record.target
    score = base_score(record, classification)
    tv = stv_from_weight(record.weight)
    stem = atom_id("alg", "prerequisite", source, target)
    operation_stem = atom_id("alg", "prerequisite", source, target, perspective)
    op = atom_id("establish_precondition", source, target).replace("-", "_")

    return [
        generic_sort_candidate(record, perspective, "action_state", classification, bonus=0.1),
        generic_sort_candidate(record, perspective, "precondition_state", classification, bonus=0.1),
        candidate(
            (source, perspective, "operations"),
            ("operation", source, perspective, op),
            score,
            record.order,
            fact(f"{operation_stem}-operation", f"(has-operation {operation_stem}-operation {source} {perspective} {op})", tv),
            fact(
                f"{operation_stem}-signature",
                f"(operation-signature {operation_stem}-operation (-> precondition_state action_state action_state))",
                "(stv 0.880 0.820)",
            ),
        ),
        candidate(
            (source, perspective, "predicates"),
            ("predicate", source, perspective, "requires", target),
            score,
            record.order,
            fact(f"{stem}-predicate", f"(has-predicate {stem}-predicate {source} {perspective} (requires {source} {target}))", tv),
        ),
        axiom_candidate(
            record,
            perspective,
            stem,
            "requiresInput",
            operation_law(op, f"(requiresInput {op} {target})"),
            score,
            tv,
        ),
        axiom_candidate(
            record,
            perspective,
            f"{stem}-closure",
            "closedUnder",
            operation_law(op, f"(closedUnder {op} action_state)"),
            score - 0.02,
            tv,
        ),
    ]


def candidates_for_has_subevent(record, classification):
    perspective = classification.perspective
    source, target = record.source, record.target
    score = base_score(record, classification)
    tv = stv_from_weight(record.weight)
    stem = atom_id("alg", "subevent", source, target)
    operation_stem = atom_id("alg", "subevent", source, target, perspective)
    op = atom_id("compose_process", source, target).replace("-", "_")

    return [
        generic_sort_candidate(record, perspective, "process_state", classification, bonus=0.1),
        generic_sort_candidate(record, perspective, "behavior_state", classification, bonus=0.1),
        candidate(
            (source, perspective, "operations"),
            ("operation", source, perspective, op),
            score,
            record.order,
            fact(f"{operation_stem}-operation", f"(has-operation {operation_stem}-operation {source} {perspective} {op})", tv),
            fact(
                f"{operation_stem}-signature",
                f"(operation-signature {operation_stem}-operation (-> process_state behavior_state process_state))",
                "(stv 0.880 0.820)",
            ),
        ),
        candidate(
            (source, perspective, "predicates"),
            ("predicate", source, perspective, "hasSubevent", target),
            score,
            record.order,
            fact(f"{stem}-predicate", f"(has-predicate {stem}-predicate {source} {perspective} (hasSubevent {source} {target}))", tv),
        ),
        axiom_candidate(
            record,
            perspective,
            stem,
            "composes",
            operation_law(op, f"(composes {op} {target})"),
            score,
            tv,
        ),
        axiom_candidate(
            record,
            perspective,
            f"{stem}-closure",
            "closedUnder",
            operation_law(op, f"(closedUnder {op} process_state)"),
            score - 0.02,
            tv,
        ),
    ]


def candidates_for_used_for(record, classification):
    role = semantic_role_for(record, FUNCTIONAL_OPERATION_ROLES)
    if role:
        return semantic_operation_candidates(record, classification, role, "usedFor")
    return operation_relation_candidates(
        record,
        classification,
        "use_for",
        "(-> concept_instance functional_goal functional_result)",
        "usedFor",
        "(purposeClosedUnder {op} {target} functional_result)",
        extra_sorts=("functional_goal", "functional_result"),
    )


def is_action_like_target(record):
    tokens = set(word_tokens(record.target))
    if tokens.intersection(NON_OPERATION_TARGET_WORDS) and not tokens.intersection(ACTION_TARGET_WORDS):
        return False
    return bool(tokens.intersection(ACTION_TARGET_WORDS | PROCESS_WORDS))


def candidates_for_capable_of(record, classification):
    role = semantic_role_for(record, SEMANTIC_OPERATION_ROLES)
    if role:
        return semantic_operation_candidates(record, classification, role, "capableOf")
    if not is_action_like_target(record):
        return []
    return operation_relation_candidates(
        record,
        classification,
        joined(record.target),
        "(-> process_state action_state behavior_state)",
        "capableOf",
        "(closedUnder {op} behavior_state)",
        extra_sorts=("action_state",),
        emit_predicate=False,
    )


def candidates_for_receives_action(record, classification):
    return operation_relation_candidates(
        record,
        classification,
        "receive_action",
        "(-> concept_instance action_state behavior_state)",
        "receivesAction",
        "(actionPreserving {op} {source} {target})",
        extra_sorts=("concept_instance", "action_state"),
    )


def candidates_for_effect(record, classification):
    role = semantic_role_for(record, SEMANTIC_OPERATION_ROLES)
    if role:
        return semantic_operation_candidates(record, classification, role, "entails" if record.relation == "Entails" else "causes")
    relation = "entails" if record.relation == "Entails" else "causes"
    prefix = "entail_effect" if record.relation == "Entails" else "cause_effect"
    return operation_relation_candidates(
        record,
        classification,
        prefix,
        "(-> process_state behavior_state process_state)",
        relation,
        "(effectClosedUnder {op} {target} process_state)",
        extra_sorts=("effect_state",),
    )


def candidates_for_causes_desire(record, classification):
    return operation_relation_candidates(
        record,
        classification,
        "induce_desire",
        "(-> concept_instance social_evaluation social_evaluation)",
        "causesDesire",
        "(desireClosedUnder {op} {target} social_evaluation)",
        extra_sorts=("desire_state",),
    )


def candidates_for_structural(record, classification):
    if record.relation == "HasA":
        prefix = "compose_with_part"
        signature = "(-> whole part whole)"
        predicate = "hasPart"
        law = "(partWholeClosedUnder {op} {source} {target})"
    elif record.relation == "PartOf":
        prefix = "embed_in_whole"
        signature = "(-> part whole whole)"
        predicate = "partOf"
        law = "(embeddingClosedUnder {op} {source} {target})"
    else:
        prefix = "materialize_from"
        signature = "(-> concept_instance material whole)"
        predicate = "madeOf"
        law = "(materialClosedUnder {op} {target} whole)"

    return operation_relation_candidates(
        record,
        classification,
        prefix,
        signature,
        predicate,
        law,
        extra_sorts=("material",),
    )


def candidates_for_spatial(record, classification):
    prefix = "locate_near" if record.relation == "LocatedNear" else "locate_at"
    predicate = "locatedNear" if record.relation == "LocatedNear" else "atLocation"
    return operation_relation_candidates(
        record,
        classification,
        prefix,
        "(-> concept_instance spatial_context spatial_context)",
        predicate,
        "(spatialClosure {op} {target} spatial_context)",
    )


def candidates_for_has_context(record, classification):
    return operation_relation_candidates(
        record,
        classification,
        "contextualize",
        "(-> concept_instance context_feature context_feature)",
        "hasContext",
        "(contextClosedUnder {op} {target} context_feature)",
        extra_sorts=("context_feature",),
    )


def candidates_for_created_by(record, classification):
    return operation_relation_candidates(
        record,
        classification,
        "create_from",
        "(-> precondition_state concept_instance concept_instance)",
        "createdBy",
        "(creationClosedUnder {op} {source} {target})",
        extra_sorts=("creator_role", "concept_instance"),
    )



def candidates_for_related_to(record, classification):
    role_specs = SEMANTIC_OPERATION_ROLES if classification.perspective == "behavioral-process" else FUNCTIONAL_OPERATION_ROLES
    role = semantic_role_for(record, role_specs)
    if role:
        return semantic_operation_candidates(record, classification, role, "relatedTo")
    proof = atom_id("alg", "related", record.source, record.target, classification.perspective)
    return [
        generic_sort_candidate(record, classification.perspective, "context_feature", classification, bonus=0.02),
        candidate(
            (record.source, classification.perspective, "predicates"),
            ("predicate", record.source, classification.perspective, "relatedTo", record.target),
            base_score(record, classification),
            record.order,
            fact(
                proof,
                f"(has-predicate {proof} {record.source} {classification.perspective} (relatedTo {record.source} {record.target}))",
                stv_from_weight(record.weight),
            ),
        ),
    ]


def frame_relation_tokens(evidence):
    tokens = []
    relations = set()
    for record, _classification in evidence:
        tokens.extend(word_tokens(record.source))
        tokens.extend(word_tokens(record.target))
        tokens.extend(word_tokens(record.surface_text))
        relations.add(record.relation)
    return set(tokens), relations


def frame_kind_tokens(evidence):
    tokens = set()
    for record, _classification in evidence:
        tokens.update(word_tokens(record.source))
        if record.relation in {"isA", "InstanceOf"}:
            target_tokens = word_tokens(record.target)
            tokens.add(joined(record.target))
            if len(target_tokens) == 1:
                tokens.update(target_tokens)
    return tokens


def frame_best_score(evidence):
    return max(base_score(record, classification) for record, classification in evidence)


def frame_average_weight(evidence):
    return sum(max(record.weight, 0.1) for record, _classification in evidence) / len(evidence)


def frame_role_matches(role, perspective, all_tokens, kind_tokens):
    if perspective not in role["perspectives"]:
        return False, 0.0
    token_match = bool(all_tokens.intersection(role["words"]))
    kind_match = bool(kind_tokens.intersection(role["kind_words"]))
    if role.get("requires_kind") and not kind_match:
        return False, 0.0
    if token_match and kind_match:
        return True, 0.16
    if token_match:
        return True, 0.08
    if kind_match:
        return True, -0.06
    return False, 0.0


def semantic_frame_candidates(source, perspective, evidence):
    if not evidence:
        return []

    rep_record, rep_classification = min(evidence, key=lambda item: item[0].order)
    all_tokens, relations = frame_relation_tokens(evidence)
    kind_tokens = frame_kind_tokens(evidence)
    base = frame_best_score(evidence)
    tv = stv_from_weight(frame_average_weight(evidence), 0.56)
    items = []

    for role in FRAME_OPERATION_ROLES:
        matches, match_bonus = frame_role_matches(role, perspective, all_tokens, kind_tokens)
        if not matches:
            continue

        op = operation_name(role["operation"], source)
        signature = role["signature"].format(concept=source)
        stem = atom_id("frame", role["role"], source, perspective)
        score = base + role["bonus"] + match_bonus + min(0.18, 0.035 * math.log1p(len(evidence)))

        for sort_name in tuple(role.get("sorts", ())) + PERSPECTIVE_SORTS.get(perspective, ()):
            items.append(generic_sort_candidate(rep_record, perspective, sort_name, rep_classification, confidence=0.74, bonus=0.08 + match_bonus))

        items.append(operation_candidate(rep_record, perspective, stem, op, signature, score, tv, bonus=0.18))
        law = role["law"].format(op=op, concept=source, signature=signature)
        items.append(
            axiom_candidate(
                rep_record,
                perspective,
                stem,
                role["role"],
                operation_law(op, law),
                score,
                tv,
                bonus=0.04,
            )
        )

    return items




def horn_antecedent(concept, perspective, referenced_operations):
    atoms = [f"(inPerspective {concept} {perspective})"]
    atoms.extend(
        f"(declaredOperation {concept} {perspective} {operation})"
        for operation in referenced_operations
    )
    if len(atoms) == 1:
        return atoms[0]
    return f"(and {' '.join(atoms)})"


def horn_axiom(concept, perspective, feature):
    expression = feature.value.strip()
    if expression.startswith("(=>"):
        return expression
    return f"(=> {horn_antecedent(concept, perspective, feature.referenced_operations)} {expression})"


def schema_bundle_candidates(bundle, evidence):
    """Adapt one validated semantic bundle to the legacy MeTTa fact format."""

    rep_record, _rep_classification = min(evidence, key=lambda item: item[0].order)
    tv = stv_from_weight(bundle.evidence_weight, 0.62)
    signature_tv = "(stv 0.900 0.860)"
    items = []

    for index, feature in enumerate(bundle.features):
        stem = atom_id("bundle", bundle.family, bundle.concept, bundle.perspective, feature.name, index)
        score = bundle.score + feature.score_bonus
        semantic_key = (feature.semantic_key, feature.name)

        if feature.part == "sorts":
            items.append(
                candidate(
                    (bundle.concept, bundle.perspective, "sorts"),
                    ("bundle-sort", bundle.concept, bundle.perspective, semantic_key),
                    score,
                    rep_record.order,
                    fact(stem, f"(has-sort {stem} {bundle.concept} {bundle.perspective} {feature.name})", signature_tv),
                )
            )
        elif feature.part == "operations":
            items.append(
                candidate(
                    (bundle.concept, bundle.perspective, "operations"),
                    ("bundle-operation", bundle.concept, bundle.perspective, semantic_key),
                    score,
                    rep_record.order,
                    fact(f"{stem}-operation", f"(has-operation {stem}-operation {bundle.concept} {bundle.perspective} {feature.name})", tv),
                    fact(f"{stem}-signature", f"(operation-signature {stem}-operation {feature.value})", signature_tv),
                )
            )
        elif feature.part == "predicates":
            items.append(
                candidate(
                    (bundle.concept, bundle.perspective, "predicates"),
                    ("bundle-predicate", bundle.concept, bundle.perspective, semantic_key),
                    score,
                    rep_record.order,
                    fact(stem, f"(has-predicate {stem} {bundle.concept} {bundle.perspective} {feature.value})", tv),
                )
            )
        elif feature.part == "axioms":
            axiom = horn_axiom(bundle.concept, bundle.perspective, feature)
            items.append(
                candidate(
                    (bundle.concept, bundle.perspective, "axioms"),
                    ("bundle-axiom", bundle.concept, bundle.perspective, semantic_key),
                    score,
                    rep_record.order,
                    fact(stem, f"(has-axiom {stem} {bundle.concept} {bundle.perspective} {axiom})", tv),
                )
            )

    return items


CANDIDATE_BUILDERS = {
    "isA": candidates_for_is_a,
    "InstanceOf": candidates_for_is_a,
    "hasproperty": candidates_for_has_property,
    "hasPrerequisite": candidates_for_has_prerequisite,
    "hasSubevent": candidates_for_has_subevent,
    "UsedFor": candidates_for_used_for,
    "CapableOf": candidates_for_capable_of,
    "ReceivesAction": candidates_for_receives_action,
    "Causes": candidates_for_effect,
    "Entails": candidates_for_effect,
    "CausesDesire": candidates_for_causes_desire,
    "HasA": candidates_for_structural,
    "PartOf": candidates_for_structural,
    "MadeOf": candidates_for_structural,
    "AtLocation": candidates_for_spatial,
    "LocatedNear": candidates_for_spatial,
    "HasContext": candidates_for_has_context,
    "CreatedBy": candidates_for_created_by,
    "RelatedTo": candidates_for_related_to,
}



def feature_context(bundle):
    return [
        {
            "part": feature.part,
            "name": feature.name,
            "value": feature.value,
            "semantic_key": feature.semantic_key,
        }
        for feature in bundle.features
    ]


def llm_repair_context(model, bundles, evidence):
    evidence_rows = []
    for record, classification in sorted(evidence, key=lambda item: item[0].order)[:40]:
        evidence_rows.append(
            {
                "relation": record.relation,
                "source": record.source,
                "target": record.target,
                "weight": record.weight,
                "surface_text": record.surface_text,
                "perspective": classification.perspective,
                "target_type": classification.target_type,
            }
        )
    metrics = bundle_metrics(bundles)
    targets_by_relation = defaultdict(list)
    for record, _classification in evidence:
        targets_by_relation[record.relation].append(record.target)
    ambiguous_sense = len(
        set(targets_by_relation.get("isA", ()) + targets_by_relation.get("InstanceOf", ()))
    ) > 3
    metrics["ambiguous_sense"] = ambiguous_sense
    return {
        "prompt_version": "algebraic-spec-llm-repair-v1",
        "concept": model.concept,
        "perspective": model.perspective,
        "quality": metrics,
        "raw_evidence": evidence_rows,
        "draft_bundles": [
            {
                "family": bundle.family,
                "score": bundle.score,
                "features": feature_context(bundle),
            }
            for bundle in bundles
        ],
        "requirements": {
            "operations": "capabilities, transformations, observers, constants, or combinators only",
            "predicates": "relations, properties, or states only; no capability duplicates",
            "axioms": "must constrain declared operations and reference at least one operation",
        },
    }


def select_candidates(records, concepts, max_per_part, max_per_concept_relation, keep_noisy_targets, llm_repair_config=None):
    best_by_key = {}
    relation_counts = defaultdict(int)
    seen_records = 0
    rejected = Counter()
    classified = Counter()
    model_evidence = defaultdict(list)

    def keep_best(item):
        previous = best_by_key.get(item.key)
        if previous is None or (item.score, -item.order) > (previous.score, -previous.order):
            best_by_key[item.key] = item

    for record in records:
        seen_records += 1
        if concepts and record.source not in concepts:
            continue

        classification = classify_record(record, keep_noisy_targets=keep_noisy_targets)
        if classification.reject_reason:
            rejected[classification.reject_reason] += 1
            continue
        classified[classification.perspective] += 1

        relation_key = (record.source, record.relation)
        if max_per_concept_relation is not None:
            if relation_counts[relation_key] >= max_per_concept_relation:
                continue
            relation_counts[relation_key] += 1

        model_evidence[(record.source, classification.perspective)].append((record, classification))
        for implied_classification in source_implied_core_perspectives(record):
            model_evidence[(record.source, implied_classification.perspective)].append((record, implied_classification))
        for implied_classification in source_implied_frame_perspectives(record):
            model_evidence[(record.source, implied_classification.perspective)].append((record, implied_classification))

    bundles = []
    models = []
    bundles_by_key = defaultdict(list)
    evidence_by_key = {}
    for (source, perspective), evidence in model_evidence.items():
        model = build_concept_model(source, perspective, evidence)
        models.append(model)
        compiled = compile_schema_bundles(model)
        bundles.extend(compiled)
        bundles_by_key[(source, perspective)].extend(compiled)
        evidence_by_key[(source, perspective)] = evidence

    llm_proposals = {}
    if llm_repair_config and llm_repair_config.mode != "off":
        provider = provider_from_config(llm_repair_config)
        cache = JsonlRepairCache(llm_repair_config.cache_path) if llm_repair_config.cache_path else None
        requested = 0
        for model in models:
            key = (model.concept, model.perspective)
            context = llm_repair_context(model, bundles_by_key[key], evidence_by_key[key])
            if not should_use_llm_repair(llm_repair_config.mode, context):
                continue
            if llm_repair_config.max_concepts is not None and requested >= llm_repair_config.max_concepts:
                continue
            llm_proposals[key] = propose_with_cache(provider, context, cache)
            requested += 1

    bundles = repair_schema_bundles(bundles, models, llm_proposals)

    # The legacy option name remains compatible, but the value now limits
    # optional schema families.  Individual sections are never truncated.
    selected_bundles = select_schema_bundles(bundles, max_families=max_per_part)
    issues = validate_bundles(selected_bundles)
    if issues:
        preview = "; ".join(
            f"{issue.code} in {issue.bundle_id}: {issue.detail}"
            for issue in issues[:8]
        )
        raise ValueError(f"Invalid algebraic specification bundles: {preview}")

    for bundle in selected_bundles:
        for item in schema_bundle_candidates(
            bundle,
            evidence_by_key[(bundle.concept, bundle.perspective)],
        ):
            keep_best(item)

    grouped = defaultdict(list)
    for item in best_by_key.values():
        grouped[item.group].append(item)

    selected = []
    for group in sorted(grouped):
        ranked = sorted(grouped[group], key=lambda item: (-item.score, item.order, item.key))
        selected.extend(ranked)

    return selected, seen_records, rejected, classified


def perspective_ancestors(perspective):
    current = perspective
    while current:
        yield current
        current = PERSPECTIVES[current][1]



def perspective_lines():
    lines = []

    for perspective, (perspective_class, parent) in sorted(PERSPECTIVES.items()):
        proof = atom_id(perspective, "perspective")
        lines.append(
            fact(
                proof,
                f"(classified-perspective {perspective} {perspective_class})",
                "(stv 1.000 1.000)",
            )
        )
        if parent:
            lines.append(
                fact(
                    atom_id(perspective, "subperspective", parent),
                    f"(subperspective {perspective} {parent})",
                    "(stv 1.000 1.000)",
                )
            )

    for actual, (perspective_class, _parent) in sorted(PERSPECTIVES.items()):
        for requested in perspective_ancestors(actual):
            tv = "(stv 1.000 1.000)" if requested == actual else "(stv 0.970 1.000)"
            lines.append(
                fact(
                    atom_id(requested, "matches", actual),
                    f"(perspective-match {requested} {actual} {perspective_class})",
                    tv,
                )
            )

    return lines


def build_output_lines(records, concepts, max_per_part, max_per_concept_relation, keep_noisy_targets, llm_repair_config=None):
    selected, seen_records, rejected, classified = select_candidates(
        records=records,
        concepts=concepts,
        max_per_part=max_per_part,
        max_per_concept_relation=max_per_concept_relation,
        keep_noisy_targets=keep_noisy_targets,
        llm_repair_config=llm_repair_config,
    )

    lines = perspective_lines()
    seen_lines = set(lines)
    for item in selected:
        for line in item.lines:
            if line in seen_lines:
                continue
            seen_lines.add(line)
            lines.append(line)

    return lines, selected, seen_records, rejected, classified


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("inputs", nargs="+", help="Raw MeTTa relation files or directories")
    parser.add_argument("output", help="Output normalized algebraic spec KB")
    parser.add_argument(
        "--concept",
        action="append",
        default=[],
        help="Only emit facts whose source concept matches this atom. Repeatable.",
    )
    parser.add_argument(
        "--top-concepts",
        type=int,
        default=None,
        help="Also emit facts for the N source concepts with the most raw relation records.",
    )
    parser.add_argument(
        "--max-per-part",
        type=int,
        default=None,
        help=(
            "Compatibility option: maximum optional schema families per "
            "concept/perspective. Whole bundles are retained for closure."
        ),
    )
    parser.add_argument(
        "--max-per-concept-relation",
        type=int,
        default=None,
        help="Optional prefilter limit for raw edges per source concept and relation.",
    )
    parser.add_argument(
        "--keep-noisy-targets",
        action="store_true",
        help="Keep alias-like, anecdotal, or malformed target facts instead of filtering them.",
    )
    parser.add_argument("--llm-repair", choices=("off", "missing", "always"), default="off")
    parser.add_argument("--llm-model", default=os.environ.get("OPENAI_MODEL", "gpt-5.4"))
    parser.add_argument("--llm-cache", default=None)
    parser.add_argument("--llm-api-key-env", default="OPENAI_API_KEY")
    parser.add_argument("--openai-base-url", default=os.environ.get("OPENAI_BASE_URL"))
    parser.add_argument("--llm-timeout", type=float, default=45.0)
    parser.add_argument("--llm-max-concepts", type=int, default=None)
    args = parser.parse_args()

    concepts = set(args.concept)
    records = iter_records(args.inputs)
    if args.top_concepts is not None:
        records = list(records)
        top_sources = [
            source
            for source, _count in Counter(record.source for record in records).most_common(args.top_concepts)
        ]
        concepts.update(top_sources)

    llm_repair_config = LLMRepairConfig(
        mode=args.llm_repair,
        model=args.llm_model,
        cache_path=args.llm_cache,
        api_key_env=args.llm_api_key_env,
        base_url=args.openai_base_url,
        timeout=args.llm_timeout,
        max_concepts=args.llm_max_concepts,
    )

    lines, selected, seen_records, rejected, classified = build_output_lines(
        records=records,
        concepts=concepts,
        max_per_part=args.max_per_part,
        max_per_concept_relation=args.max_per_concept_relation,
        keep_noisy_targets=args.keep_noisy_targets,
        llm_repair_config=llm_repair_config,
    )

    Path(args.output).write_text("\n".join(lines) + "\n", encoding="utf-8")

    grouped = defaultdict(int)
    for item in selected:
        grouped[item.group[2]] += 1

    print(f"Read {seen_records} raw relation records")
    print(f"Rejected {sum(rejected.values())} raw records")
    for reason, count in rejected.most_common(5):
        print(f"  rejected {reason}: {count}")
    print(f"Classified {sum(classified.values())} raw records")
    for perspective, count in classified.most_common(10):
        print(f"  perspective {perspective}: {count}")
    print(f"Selected {len(selected)} ranked feature candidates")
    for part in SPEC_PARTS:
        print(f"  {part}: {grouped[part]}")
    print(f"Wrote {len(lines)} facts to {args.output}")


if __name__ == "__main__":
    main()


# (Concept socialize (perspective prerequisite-action)
# (spec (sorts ((:
