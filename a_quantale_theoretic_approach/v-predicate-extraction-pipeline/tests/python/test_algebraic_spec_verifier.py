"""Tests for final algebraic-specification verification."""

from __future__ import annotations

import json
import os
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path
from unittest.mock import patch

from algebraic_spec_verifier import (
    PROMPT_VERSION,
    VerificationConfig,
    VerificationError,
    axiom_operation_dependencies,
    candidate_prompt,
    coerce_spec_text,
    load_verified_algebraic_spec,
    parse_metta,
    repair_prompt,
    render_structured_specification,
    system_prompt,
    structured_spec_errors,
    validate_spec_text,
    verification_response_schema,
    verify_with_provider,
)


CANDIDATE = """(Concept computer information_computational
  (spec
    (sorts ((computer (stv 0.9 0.8)) (input (stv 0.9 0.8)) (state (stv 0.9 0.8))))
    (ops (((operation step (arrow computer input state state)) (stv 0.8 0.7))))
    (preds (((hasState computer state) (stv 0.8 0.7))))
    (axioms (((forall ((c computer) (i input) (s state))
      (=> true (closedUnder (step c i s) state))) (stv 0.8 0.7))))))"""


ASSESSMENTS = {
    section: {"status": "correct", "rationale": "valid"}
    for section in ("perspective", "sorts", "operations", "predicates", "axioms", "cross_section")
}


def term(kind, symbol, arguments=None):
    return {"kind": kind, "symbol": symbol, "arguments": list(arguments or [])}


STRUCTURED_SPEC = {
    "concept": "computer",
    "perspective": "information_computational",
    "sorts": [
        {"name": "computer", "stv": {"strength": 0.9, "confidence": 0.8}},
        {"name": "input", "stv": {"strength": 0.9, "confidence": 0.8}},
        {"name": "state", "stv": {"strength": 0.9, "confidence": 0.8}},
    ],
    "operations": [{
        "name": "step",
        "inputs": ["computer", "input", "state"],
        "output": "state",
        "partial": False,
        "role": "transformation",
        "stv": {"strength": 0.8, "confidence": 0.7},
    }],
    "predicates": [{
        "name": "hasState",
        "argument_sorts": ["computer", "state"],
        "stv": {"strength": 0.8, "confidence": 0.7},
    }],
    "axioms": [{
        "name": "step_closure",
        "law_kind": "closure_law",
        "variables": [
            {"name": "c", "sort": "computer"},
            {"name": "i", "sort": "input"},
            {"name": "s", "sort": "state"},
        ],
        "antecedent": [],
        "consequent": {
            "kind": "atom",
            "predicate": "closedUnder",
            "arguments": [
                term("application", "step", [term("variable", "c"), term("variable", "i"), term("variable", "s")]),
                term("constant", "state"),
            ],
            "left": term("constant", "_unused"),
            "right": term("constant", "_unused"),
        },
        "stv": {"strength": 0.8, "confidence": 0.7},
    }],
}


def response_for(specification=None, verdict="correct"):
    return {
        "verdict": verdict,
        "confidence": 0.96,
        "summary": "The specification is coherent.",
        "issues": [],
        "section_assessments": ASSESSMENTS,
        "specification": deepcopy(specification or STRUCTURED_SPEC),
    }


class StaticProvider:
    model_id = "static-verifier"

    def __init__(self, response):
        self.responses = list(response) if isinstance(response, list) else [response]
        self.calls = 0

    def verify(self, instructions, candidate):
        self.calls += 1
        response = self.responses[min(self.calls - 1, len(self.responses) - 1)]
        return deepcopy(response)


class AlgebraicSpecVerifierTests(unittest.TestCase):
    def setUp(self):
        self.logger_environment = patch.dict(
            os.environ, {"PIPELINE_LOG_MODE": "off"}
        )
        self.logger_environment.start()

    def tearDown(self):
        self.logger_environment.stop()

    def test_petta_nested_list_is_rendered_as_metta(self):
        nested = parse_metta(CANDIDATE)
        self.assertEqual(parse_metta(CANDIDATE), parse_metta(coerce_spec_text(nested)))

    def test_structured_ir_renders_balanced_original_spec(self):
        self.assertFalse(
            structured_spec_errors(
                STRUCTURED_SPEC, "computer", "information_computational"
            )
        )
        rendered = render_structured_specification(STRUCTURED_SPEC)
        self.assertEqual(parse_metta(CANDIDATE), parse_metta(rendered))

    def test_response_schema_enforces_strict_objects_and_section_limits(self):
        schema = verification_response_schema()

        def check(node):
            if isinstance(node, dict):
                if node.get("type") == "object":
                    self.assertFalse(node.get("additionalProperties", True))
                    self.assertEqual(
                        set(node.get("properties", {})), set(node.get("required", []))
                    )
                for value in node.values():
                    check(value)
            elif isinstance(node, list):
                for value in node:
                    check(value)

        check(schema)
        sections = schema["properties"]["specification"]["properties"]
        for section in ("sorts", "operations", "predicates", "axioms"):
            self.assertEqual(15, sections[section]["maxItems"])
        json.dumps(schema)

    def test_structured_validation_rejects_cross_section_type_errors(self):
        invalid = deepcopy(STRUCTURED_SPEC)
        invalid["axioms"][0]["variables"][1]["sort"] = "state"
        errors = structured_spec_errors(
            invalid, "computer", "information_computational"
        )
        self.assertTrue(any("expected sort input, got state" in error for error in errors))

    def test_operation_dependencies_are_derived_locally(self):
        self.assertEqual(
            {"step_closure": ["step"]},
            axiom_operation_dependencies(STRUCTURED_SPEC),
        )

    def test_temporal_axiom_quantifies_the_complete_horn_clause(self):
        specification = {
            "concept": "human",
            "perspective": "temporal_context",
            "sorts": [
                {"name": "human", "stv": {"strength": 0.9, "confidence": 0.8}},
                {"name": "time_point", "stv": {"strength": 0.9, "confidence": 0.8}},
            ],
            "operations": [{
                "name": "birth_time",
                "inputs": ["human"],
                "output": "time_point",
                "partial": False,
                "role": "observer",
                "stv": {"strength": 0.9, "confidence": 0.8},
            }],
            "predicates": [
                {"name": "alive_at", "argument_sorts": ["human", "time_point"], "stv": {"strength": 0.9, "confidence": 0.8}},
                {"name": "before", "argument_sorts": ["time_point", "time_point"], "stv": {"strength": 0.9, "confidence": 0.8}},
            ],
            "axioms": [{
                "name": "living_follows_birth",
                "law_kind": "predicate_implication",
                "variables": [
                    {"name": "h", "sort": "human"},
                    {"name": "t", "sort": "time_point"},
                ],
                "antecedent": [{
                    "predicate": "alive_at",
                    "arguments": [term("variable", "h"), term("variable", "t")],
                }],
                "consequent": {
                    "kind": "atom",
                    "predicate": "before",
                    "arguments": [
                        term("application", "birth_time", [term("variable", "h")]),
                        term("variable", "t"),
                    ],
                    "left": term("constant", "_unused"),
                    "right": term("constant", "_unused"),
                },
                "stv": {"strength": 0.84, "confidence": 0.77},
            }],
        }
        self.assertFalse(
            structured_spec_errors(specification, "human", "temporal_context")
        )
        rendered = render_structured_specification(specification)
        self.assertIn(
            "(forall ((h human) (t time_point)) (=> (alive_at h t) ", rendered
        )
        self.assertNotIn("inPerspective", rendered)
        self.assertNotIn("declaredOperation", rendered)
        self.assertNotIn("view_as_human", rendered)
        validate_spec_text(
            rendered, "human", "temporal_context", normalized_axioms=True
        )

    def test_structured_validation_rejects_tautological_axiom(self):
        invalid = deepcopy(STRUCTURED_SPEC)
        application = term(
            "application",
            "step",
            [term("variable", "c"), term("variable", "i"), term("variable", "s")],
        )
        invalid["axioms"][0]["law_kind"] = "equational_law"
        invalid["axioms"][0]["consequent"] = {
            "kind": "equality",
            "predicate": "",
            "arguments": [],
            "left": application,
            "right": deepcopy(application),
        }
        errors = structured_spec_errors(
            invalid, "computer", "information_computational"
        )
        self.assertTrue(any("tautological self-equality" in error for error in errors))

    def test_partial_operation_requires_definedness_premise(self):
        invalid = deepcopy(STRUCTURED_SPEC)
        invalid["operations"][0]["partial"] = True
        errors = structured_spec_errors(
            invalid, "computer", "information_computational"
        )
        self.assertTrue(any("requires a matching defined premise" in error for error in errors))

    def test_perspective_plumbing_operation_is_rejected(self):
        invalid = deepcopy(STRUCTURED_SPEC)
        invalid["operations"][0]["name"] = "information_computational"
        errors = structured_spec_errors(
            invalid, "computer", "information_computational"
        )
        self.assertTrue(any("perspective-plumbing operation" in error for error in errors))

    def test_prompt_is_compact_and_explains_section_contracts(self):
        prompt = system_prompt()
        self.assertIn("sorts: domain-relevant carrier types", prompt)
        self.assertIn("operations: typed capabilities", prompt)
        self.assertIn("predicates: typed relations", prompt)
        self.assertIn("first-order Horn laws", prompt)
        self.assertIn("Concept human cognitive_agency", prompt)
        self.assertIn("perspective is semantically binding", prompt.lower())
        self.assertIn("NOT authoritative", prompt)
        self.assertIn("no minimum section size", prompt)
        self.assertNotIn("10 to 15 meaningful items", prompt)
        self.assertLess(len(prompt), 7000)
        self.assertEqual("algebraic-spec-final-verifier-v4", PROMPT_VERSION)

    def test_candidate_prompt_includes_requested_perspective_context(self):
        prompt = candidate_prompt("human", "descriptive_property", CANDIDATE)
        self.assertIn("Perspective context:", prompt)
        self.assertIn("observable, measurable, dispositional", prompt)
        self.assertIn("draft is incomplete and non-authoritative", prompt)

    def test_repair_prompt_does_not_resend_previous_full_response(self):
        prompt = repair_prompt(
            "computer",
            "information_computational",
            CANDIDATE,
            {"large_previous_payload": "DO_NOT_RESEND"},
            ["axioms[0]: tautological self-equality"],
        )
        self.assertIn("tautological self-equality", prompt)
        self.assertNotIn("DO_NOT_RESEND", prompt)

    def test_cost_control_defaults(self):
        config = VerificationConfig()
        self.assertEqual(2, config.max_attempts)
        self.assertEqual(10000, config.max_output_tokens)
        self.assertEqual(3600, config.failure_cache_seconds)

    def test_local_validation_rejects_wrong_perspective(self):
        with self.assertRaisesRegex(VerificationError, "changed the requested"):
            validate_spec_text(CANDIDATE, "computer", "functional_use")

    def test_local_validation_rejects_capitalized_relation(self):
        invalid = CANDIDATE.replace("hasState", "HasState")
        with self.assertRaisesRegex(VerificationError, "must start lowercase"):
            validate_spec_text(invalid, "computer", "information_computational")

    def test_local_validation_enforces_section_limit(self):
        sort_item = "(state (stv 0.9 0.8))"
        invalid = CANDIDATE.replace(
            "(computer (stv 0.9 0.8)) (input (stv 0.9 0.8)) (state (stv 0.9 0.8))",
            " ".join([sort_item] * 16),
        )
        with self.assertRaisesRegex(VerificationError, "15-item limit"):
            validate_spec_text(invalid, "computer", "information_computational")

    def test_verified_spec_is_stored_and_cache_prevents_repeat_call(self):
        provider = StaticProvider(response_for())
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = VerificationConfig(
                mode="verify",
                audit_path=root / "audit.jsonl",
                metta_store_path=root / "verified.metta",
            )
            first = verify_with_provider(
                "computer", "information_computational", CANDIDATE, provider, config
            )
            second = verify_with_provider(
                "computer", "information_computational", CANDIDATE, provider, config
            )

            self.assertEqual(parse_metta(CANDIDATE), parse_metta(first))
            self.assertEqual(parse_metta(first), parse_metta(second))
            self.assertEqual(1, provider.calls)
            self.assertIn('"verdict": "correct"', config.audit_path.read_text())
            stored = config.metta_store_path.read_text()
            self.assertIn("llm_verified_algebraic_spec", stored)
            self.assertIn(first, stored)
            loaded = load_verified_algebraic_spec(
                "computer", "information_computational", config.audit_path
            )
            self.assertEqual(parse_metta(CANDIDATE), parse_metta(loaded))

    def test_invalid_first_attempt_is_repaired_and_audited(self):
        invalid = deepcopy(STRUCTURED_SPEC)
        invalid["sorts"] = invalid["sorts"] + [deepcopy(invalid["sorts"][0])] * 13
        provider = StaticProvider([response_for(invalid, "corrected"), response_for()])
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = VerificationConfig(
                mode="verify",
                max_attempts=3,
                audit_path=root / "audit.jsonl",
                metta_store_path=root / "verified.metta",
            )
            verified = verify_with_provider(
                "computer", "information_computational", CANDIDATE, provider, config
            )
            rows = [json.loads(line) for line in config.audit_path.read_text().splitlines()]
            self.assertEqual(parse_metta(CANDIDATE), parse_metta(verified))
            self.assertEqual(2, provider.calls)
            self.assertEqual("invalid", rows[0]["status"])
            self.assertIn("15-item limit", " ".join(rows[0]["validation_errors"]))
            self.assertEqual("valid", rows[1]["status"])

    def test_exhausted_retries_fall_back_to_draft(self):
        invalid = deepcopy(STRUCTURED_SPEC)
        invalid["concept"] = "wrong_concept"
        provider = StaticProvider(response_for(invalid, "corrected"))
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = VerificationConfig(
                mode="verify",
                max_attempts=2,
                failure_policy="fallback",
                audit_path=root / "audit.jsonl",
                metta_store_path=root / "verified.metta",
            )
            verified = verify_with_provider(
                "computer", "information_computational", CANDIDATE, provider, config
            )
            cached_failure = verify_with_provider(
                "computer", "information_computational", CANDIDATE, provider, config
            )
            self.assertEqual(CANDIDATE, verified)
            self.assertEqual(CANDIDATE, cached_failure)
            self.assertEqual(2, provider.calls)
            self.assertIn('"record_type": "fallback"', config.audit_path.read_text())

    def test_strict_failure_policy_raises_after_retries(self):
        invalid = deepcopy(STRUCTURED_SPEC)
        invalid["concept"] = "wrong_concept"
        provider = StaticProvider(response_for(invalid, "corrected"))
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = VerificationConfig(
                mode="verify",
                max_attempts=1,
                failure_policy="error",
                audit_path=root / "audit.jsonl",
                metta_store_path=root / "verified.metta",
            )
            with self.assertRaisesRegex(VerificationError, "failed after retries"):
                verify_with_provider(
                    "computer", "information_computational", CANDIDATE, provider, config
                )



if __name__ == "__main__":
    unittest.main()
