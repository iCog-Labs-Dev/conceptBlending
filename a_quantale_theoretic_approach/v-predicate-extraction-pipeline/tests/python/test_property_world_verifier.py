"""Tests for final property/world LLM repair and persistence."""

from __future__ import annotations

import json
import os
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path
from unittest.mock import patch

from property_world_verifier import (
    PROMPT_VERSION,
    PropertyWorldVerificationError,
    VerificationConfig,
    _kb_fingerprint,
    parse_property_candidates,
    parse_world_candidates,
    property_response_schema,
    property_system_prompt,
    render_properties,
    render_worlds,
    verify_properties_with_provider,
    verify_worlds_with_provider,
    world_response_schema,
    world_system_prompt,
)


class StaticProvider:
    model_id = "static-property-world-verifier"

    def __init__(self, responses):
        self.responses = (
            list(responses) if isinstance(responses, list) else [responses]
        )
        self.calls = 0
        self.requests = []

    def verify(self, instructions, candidate, schema_name, schema):
        self.calls += 1
        self.requests.append((instructions, candidate, schema_name, schema))
        return deepcopy(self.responses[min(self.calls - 1, len(self.responses) - 1)])


def property_response(items):
    return {
        "verdict": "corrected",
        "confidence": 0.94,
        "summary": "Selected perspective-relevant properties.",
        "properties": [
            {"name": name, "perspective": perspective}
            for name, perspective in items
        ],
    }


def world_response(items):
    return {
        "verdict": "corrected",
        "confidence": 0.92,
        "summary": "Selected the strongest possible worlds.",
        "worlds": list(items),
    }


class PropertyWorldVerifierTests(unittest.TestCase):
    def setUp(self):
        self.logger_environment = patch.dict(
            os.environ, {"PIPELINE_LOG_MODE": "off"}
        )
        self.logger_environment.start()

    def tearDown(self):
        self.logger_environment.stop()

    def config(self, root: str, *, attempts: int = 2, policy: str = "fallback"):
        base = Path(root)
        kb = base / "PropertyWorldKB.metta"
        kb.write_text("(: fixture fixture)\n", encoding="utf-8")
        return VerificationConfig(
            mode="verify",
            model="static-property-world-verifier",
            max_attempts=attempts,
            failure_policy=policy,
            audit_path=base / "verified.jsonl",
            metta_store_path=base / "VerifiedKB.metta",
            kb_path=kb,
        )

    def test_candidate_parsing_cleans_malformed_and_duplicates(self):
        self.assertEqual(
            [
                ("process_information", "functional_use"),
                ("store_information", "functional_use"),
            ],
            parse_property_candidates(
                "((process_information functional_use) "
                "(process_information functional_use) malformed "
                "(store_information functional_use))"
            ),
        )
        self.assertEqual(
            ["computer", "software"],
            parse_world_candidates("(computer (malformed world) software computer)"),
        )

    def test_kb_fingerprint_depends_on_content_not_mtime(self):
        with tempfile.TemporaryDirectory() as tmp:
            kb = Path(tmp) / "PropertyWorldKB.metta"
            kb.write_text("(: fixture fixture)\n", encoding="utf-8")
            original = _kb_fingerprint(kb)

            stat = kb.stat()
            os.utime(kb, ns=(stat.st_atime_ns, stat.st_mtime_ns + 1_000_000))

            self.assertEqual(original, _kb_fingerprint(kb))
            self.assertTrue(original.startswith("sha256:"))

            kb.write_text("(: fixture changed)\n", encoding="utf-8")
            self.assertNotEqual(original, _kb_fingerprint(kb))

    def test_schemas_enforce_requested_limits(self):
        self.assertEqual(
            10,
            property_response_schema()["properties"]["properties"]["maxItems"],
        )
        self.assertEqual(
            3,
            world_response_schema()["properties"]["worlds"]["maxItems"],
        )
        json.dumps(property_response_schema())
        json.dumps(world_response_schema())

    def test_prompts_contain_limits_and_examples(self):
        property_prompt = property_system_prompt()
        world_prompt = world_system_prompt()
        self.assertIn("at most 10", property_prompt)
        self.assertIn("you may add", property_prompt)
        self.assertIn("floats_on_water", property_prompt)
        self.assertIn("concept=boat", property_prompt)
        self.assertIn("at most 3", world_prompt)
        self.assertIn("you may add", world_prompt)
        self.assertIn("passenger_boat", world_prompt)
        self.assertIn("property=provides_transport", world_prompt)

    def test_property_verification_persists_and_reuses_cache(self):
        candidates = (
            "(process_information functional_use) "
            "(store_information functional_use) "
            "(expensive economic_ownership)"
        )
        provider = StaticProvider(
            property_response(
                [
                    ("process_information", "functional_use"),
                    ("store_information", "functional_use"),
                ]
            )
        )
        with tempfile.TemporaryDirectory() as tmp:
            config = self.config(tmp)
            first = verify_properties_with_provider(
                "computer", "descriptive_property", f"({candidates})", provider, config
            )
            second = verify_properties_with_provider(
                "computer", "descriptive_property", f"({candidates})", provider, config
            )
            self.assertEqual(first, second)
            self.assertEqual(1, provider.calls)
            self.assertEqual(
                "((process_information functional_use) "
                "(store_information functional_use))",
                first,
            )
            rows = [
                json.loads(line)
                for line in config.audit_path.read_text(encoding="utf-8").splitlines()
            ]
            self.assertEqual(PROMPT_VERSION, rows[-1]["prompt_version"])
            self.assertEqual("concept_properties", rows[-1]["kind"])
            self.assertIn(
                "llm_verified_concept_properties",
                config.metta_store_path.read_text(encoding="utf-8"),
            )

    def test_world_verification_accepts_relevant_addition(self):
        provider = StaticProvider(
            world_response(["computer", "data_center"])
        )
        with tempfile.TemporaryDirectory() as tmp:
            config = self.config(tmp)
            result = verify_worlds_with_provider(
                "process_information",
                "functional_use",
                "(computer software thinking)",
                provider,
                config,
            )
            self.assertEqual("(computer data_center)", result)
            self.assertEqual(1, provider.calls)
            self.assertIn(
                "llm_verified_property_worlds",
                config.metta_store_path.read_text(encoding="utf-8"),
            )

    def test_property_verification_accepts_relevant_addition(self):
        provider = StaticProvider(
            property_response(
                [
                    ("process_information", "functional_use"),
                    ("run_software", "functional_use"),
                ]
            )
        )
        with tempfile.TemporaryDirectory() as tmp:
            config = self.config(tmp)
            result = verify_properties_with_provider(
                "computer",
                "functional_use",
                "((process_information functional_use))",
                provider,
                config,
            )
            self.assertEqual(
                "((process_information functional_use) "
                "(run_software functional_use))",
                result,
            )

    def test_added_property_must_use_requested_perspective(self):
        provider = StaticProvider(
            property_response(
                [("run_software", "information_computational")]
            )
        )
        with tempfile.TemporaryDirectory() as tmp:
            config = self.config(tmp, attempts=1, policy="error")
            with self.assertRaises(PropertyWorldVerificationError):
                verify_properties_with_provider(
                    "computer",
                    "functional_use",
                    "()",
                    provider,
                    config,
                )

    def test_hard_limits_and_uniqueness_are_enforced(self):
        properties = [(f"p{index}", "functional_use") for index in range(11)]
        provider = StaticProvider(property_response(properties))
        with tempfile.TemporaryDirectory() as tmp:
            config = self.config(tmp, attempts=1, policy="error")
            with self.assertRaises(PropertyWorldVerificationError):
                verify_properties_with_provider(
                    "computer",
                    "functional_use",
                    render_properties(properties),
                    provider,
                    config,
                )

        provider = StaticProvider(
            property_response(
                [
                    ("shared", "functional_use"),
                    ("shared", "information_computational"),
                ]
            )
        )
        with tempfile.TemporaryDirectory() as tmp:
            config = self.config(tmp, attempts=1, policy="error")
            with self.assertRaises(PropertyWorldVerificationError):
                verify_properties_with_provider(
                    "computer",
                    "descriptive_property",
                    "((shared functional_use) "
                    "(shared information_computational))",
                    provider,
                    config,
                )

        provider = StaticProvider(world_response(["a", "b", "c", "d"]))
        with tempfile.TemporaryDirectory() as tmp:
            config = self.config(tmp, attempts=1, policy="error")
            with self.assertRaises(PropertyWorldVerificationError):
                verify_worlds_with_provider(
                    "property",
                    "functional_use",
                    render_worlds(["a", "b", "c", "d"]),
                    provider,
                    config,
                )

    def test_failure_fallback_remains_bounded(self):
        provider = StaticProvider({"verdict": "rejected"})
        candidates = [(f"p{index}", "functional_use") for index in range(12)]
        with tempfile.TemporaryDirectory() as tmp:
            config = self.config(tmp, attempts=1)
            rendered = verify_properties_with_provider(
                "computer",
                "functional_use",
                render_properties(candidates),
                provider,
                config,
            )
            self.assertEqual(10, len(parse_property_candidates(rendered)))

        provider = StaticProvider({"verdict": "rejected"})
        with tempfile.TemporaryDirectory() as tmp:
            config = self.config(tmp, attempts=1)
            rendered = verify_worlds_with_provider(
                "property",
                "functional_use",
                "(a b c d e)",
                provider,
                config,
            )
            self.assertEqual(["a", "b", "c"], parse_world_candidates(rendered))


if __name__ == "__main__":
    unittest.main()
