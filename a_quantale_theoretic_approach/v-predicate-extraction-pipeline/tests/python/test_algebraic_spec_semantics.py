"""Regression and evaluation suite for semantic algebraic specifications."""

from __future__ import annotations

import unittest
from dataclasses import dataclass

from algebraic_spec_semantics import (
    bundle_metrics,
    build_concept_model,
    compile_schema_bundles,
    repair_schema_bundles,
    select_schema_bundles,
    validate_bundles,
)


@dataclass(frozen=True)
class Record:
    relation: str
    source: str
    target: str
    weight: float = 2.0
    surface_text: str = ""
    order: int = 0


@dataclass(frozen=True)
class Classification:
    perspective: str
    target_type: str
    score_bonus: float = 0.0


def evidence(concept, perspective, relations):
    return [
        (
            Record(relation, concept, target, order=index),
            Classification(perspective, target_type),
        )
        for index, (relation, target, target_type) in enumerate(relations)
    ]


STRATIFIED_CASES = {
    ("knife", "functional-use"): [
        ("isA", "cutting_tool", "kind"),
        ("UsedFor", "stabbing", "purpose-operation"),
        ("UsedFor", "butter", "purpose-operation"),
        ("hasproperty", "sharp", "physical-property"),
        ("Causes", "injury", "effect"),
    ],
    ("car", "functional-use"): [
        ("isA", "vehicle", "kind"),
        ("UsedFor", "transport", "purpose-operation"),
        ("CapableOf", "carry_people", "capability-operation"),
    ],
    ("box", "functional-use"): [
        ("isA", "container", "kind"),
        ("UsedFor", "store_objects", "purpose-operation"),
        ("hasproperty", "empty", "property"),
    ],
    ("computer", "information-computational"): [
        ("isA", "electronic_device", "kind"),
        ("CapableOf", "calculate", "capability-operation"),
        ("ReceivesAction", "program_input", "relation"),
    ],
    ("human", "behavioral-process"): [
        ("isA", "person", "kind"),
        ("CapableOf", "communicate", "capability-operation"),
        ("CapableOf", "learn", "capability-operation"),
    ],
    ("water", "functional-use"): [
        ("isA", "liquid", "kind"),
        ("UsedFor", "drink", "purpose-operation"),
        ("hasproperty", "clear", "physical-property"),
    ],
    ("school", "functional-use"): [
        ("isA", "building", "kind"),
        ("UsedFor", "learning", "purpose-operation"),
        ("AtLocation", "city", "location"),
    ],
    ("theorem", "structural-composition"): [
        ("HasA", "premise", "part"),
        ("HasA", "conclusion", "part"),
        ("RelatedTo", "proof", "relation"),
    ],
    ("dog", "taxonomic-kind"): [
        ("isA", "animal", "kind"),
        ("InstanceOf", "mammal", "kind"),
    ],
    ("apple", "physical-attribute"): [
        ("hasproperty", "round", "physical-property"),
        ("hasproperty", "red", "physical-property"),
    ],
    ("house", "safety-risk"): [
        ("hasproperty", "susceptible_to_fire", "risk-condition"),
        ("Causes", "injury", "effect"),
    ],
    ("building", "spatial-context"): [
        ("AtLocation", "city", "location"),
        ("LocatedNear", "road", "location"),
    ],
    ("socialize", "causal-prerequisite"): [
        ("hasPrerequisite", "meet_people", "precondition"),
        ("hasPrerequisite", "communication", "precondition"),
    ],
    ("machine", "state-lifecycle"): [
        ("hasproperty", "upgraded", "state-condition"),
        ("hasproperty", "old", "state-condition"),
    ],
    ("product", "economic-ownership"): [
        ("hasproperty", "expensive", "economic-property"),
        ("RelatedTo", "market", "relation"),
    ],
    ("decision", "social-normative"): [
        ("hasproperty", "wrong", "evaluation"),
        ("CausesDesire", "approval", "desire"),
    ],
    ("vehicle", "quantitative-comparative"): [
        ("hasproperty", "faster_than_bicycle", "comparative"),
    ],
}


def compile_case(concept, perspective, relations):
    model = build_concept_model(
        concept,
        perspective,
        evidence(concept, perspective, relations),
    )
    bundles = repair_schema_bundles(compile_schema_bundles(model), [model])
    return select_schema_bundles(bundles)


class SemanticSpecificationTests(unittest.TestCase):
    def test_stratified_suite_is_structurally_valid(self):
        for (concept, perspective), relations in STRATIFIED_CASES.items():
            with self.subTest(concept=concept, perspective=perspective):
                bundles = compile_case(concept, perspective, relations)
                self.assertTrue(bundles)
                self.assertEqual([], validate_bundles(bundles))

    def test_capabilities_are_not_duplicated_as_predicates(self):
        bundles = compile_case(
            "knife",
            "functional-use",
            STRATIFIED_CASES[("knife", "functional-use")],
        )
        metrics = bundle_metrics(bundles)
        self.assertEqual(0, metrics["operation_predicate_overlap_count"])
        predicates = {
            feature.value
            for bundle in bundles
            for feature in bundle.features
            if feature.part == "predicates"
        }
        self.assertFalse(any("stabbing" in predicate for predicate in predicates))

    def test_noun_used_for_becomes_relation_not_operation(self):
        bundles = compile_case(
            "knife",
            "functional-use",
            [("UsedFor", "butter", "purpose-operation")],
        )
        operations = {
            feature.name
            for bundle in bundles
            for feature in bundle.features
            if feature.part == "operations"
        }
        predicates = {
            feature.value
            for bundle in bundles
            for feature in bundle.features
            if feature.part == "predicates"
        }
        self.assertFalse(any("butter" in operation for operation in operations))
        self.assertIn("(ServesTask knife butter)", predicates)

    def test_knife_activates_rich_edge_application_schema(self):
        bundles = compile_case(
            "knife",
            "functional-use",
            STRATIFIED_CASES[("knife", "functional-use")],
        )
        metrics = bundle_metrics(bundles)
        operations = {
            feature.name
            for bundle in bundles
            for feature in bundle.features
            if feature.part == "operations"
        }
        self.assertGreaterEqual(metrics["sort_count"], 10)
        self.assertGreaterEqual(metrics["operation_count"], 12)
        self.assertGreaterEqual(metrics["predicate_count"], 8)
        self.assertGreaterEqual(metrics["axiom_count"], 10)
        self.assertTrue(
            {"slice_knife", "pierce_knife", "chop_knife", "scrape_knife"}
            <= operations
        )

    def test_llm_proposal_is_merged_and_validated(self):
        model = build_concept_model(
            "bat",
            "behavioral-process",
            evidence(
                "bat",
                "behavioral-process",
                [
                    ("isA", "mammal", "kind"),
                    ("HasA", "wing", "part"),
                    ("CapableOf", "fly", "capability-operation"),
                ],
            ),
        )
        proposal = {
            "sense": {"selected_sense": "animal/bat", "confidence": 0.9},
            "repairs": {
                "sorts": [
                    {"name": "sound_signal", "confidence": 0.8},
                    {"name": "environment", "confidence": 0.8},
                    {"name": "perceptual_map", "confidence": 0.8},
                ],
                "operations": [
                    {
                        "name": "echolocate_bat",
                        "signature": "(-> bat sound_signal environment perceptual_map)",
                        "required_sorts": ["bat", "sound_signal", "environment", "perceptual_map"],
                        "confidence": 0.82,
                    }
                ],
                "predicates": [
                    {
                        "name": "UsesEcholocation",
                        "expression": "(UsesEcholocation bat sound_signal)",
                        "required_sorts": ["bat", "sound_signal"],
                        "confidence": 0.75,
                    }
                ],
                "axioms": [
                    {
                        "name": "echolocation_closure",
                        "expression": "(forall ((b bat) (s sound_signal) (e environment)) (closedUnder (echolocate_bat b s e) perceptual_map))",
                        "referenced_operations": ["echolocate_bat"],
                        "confidence": 0.78,
                    }
                ],
            },
            "notes": [],
        }
        bundles = repair_schema_bundles(
            compile_schema_bundles(model),
            [model],
            {("bat", "behavioral-process"): proposal},
        )
        self.assertEqual([], validate_bundles(bundles))
        operations = {
            feature.name
            for bundle in bundles
            for feature in bundle.features
            if feature.part == "operations"
        }
        self.assertIn("echolocate_bat", operations)

    def test_repair_adds_constraints_for_uncovered_operations(self):
        bundles = compile_case(
            "computer",
            "information-computational",
            STRATIFIED_CASES[("computer", "information-computational")],
        )
        metrics = bundle_metrics(bundles)
        self.assertEqual(1.0, metrics["operation_axiom_coverage"])

    def test_repair_profile_keeps_relations_as_predicates(self):
        bundles = compile_case(
            "house",
            "functional-use",
            [
                ("isA", "building", "kind"),
                ("AtLocation", "city", "location"),
                ("HasA", "roof", "part"),
            ],
        )
        operations = {
            feature.semantic_key
            for bundle in bundles
            for feature in bundle.features
            if feature.part == "operations"
        }
        predicates = {
            feature.value
            for bundle in bundles
            for feature in bundle.features
            if feature.part == "predicates"
        }
        self.assertFalse(any(key.startswith("evidence:relation:") for key in operations))
        self.assertIn("(AtLocation house city)", predicates)
        self.assertIn("(HasPart house roof)", predicates)

    def test_bundle_limit_preserves_closure(self):
        bundles = compile_case(
            "car",
            "functional-use",
            STRATIFIED_CASES[("car", "functional-use")],
        )
        limited = select_schema_bundles(bundles, max_families=1)
        self.assertEqual([], validate_bundles(limited))

    def test_output_is_deterministic(self):
        case = STRATIFIED_CASES[("computer", "information-computational")]
        first = compile_case("computer", "information-computational", case)
        second = compile_case("computer", "information-computational", case)
        self.assertEqual(first, second)


if __name__ == "__main__":
    unittest.main()

KNIFE_FUNCTIONAL_USE_REFERENCE = r"""
spec KNIFE_FUNCTIONAL_USE =

  sorts
    Blade
    Handle
    Knife
    MaterialPortion
    PieceCount
    SharpnessState
    SpreadableSubstance
    knife

  ops
    dull : SharpnessState
    sharp : SharpnessState
    knife : Blade * Handle * SharpnessState -> Knife
    bladeOf : Knife -> Blade
    edgeState : Knife -> SharpnessState
    cut : Knife * MaterialPortion -> PieceCount
    sharpen : Knife -> Knife
    slice : Knife * MaterialPortion -> PieceCount
    spread : Knife * SpreadableSubstance * MaterialPortion -> MaterialPortion

  preds
 Dangerous : Knife
    EdgedTool : Knife
    Handheld : Knife
    StoredIn : Knife * MaterialPortion

  axioms
    (forall ((b Blade) (h Handle) (s SharpnessState)) (= (bladeOf (knife b h s)) b))
    (forall ((b Blade) (h Handle) (s SharpnessState)) (= (edgeState (knife b h s)) s))
    (forall ((k Knife)) (= (edgeState (sharpen k)) sharp))
    (forall ((k Knife) (m MaterialPortion)) (= (slice k m) (cut k m)))
"""
