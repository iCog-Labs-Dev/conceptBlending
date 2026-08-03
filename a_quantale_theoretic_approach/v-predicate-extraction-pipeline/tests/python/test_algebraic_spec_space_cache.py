import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import algebraic_spec_space_cache as cache
from algebraic_spec_verifier import PROMPT_VERSION


class AlgebraicSpecSpaceCacheTests(unittest.TestCase):
    def setUp(self):
        self.logger_environment = patch.dict(
            os.environ, {"PIPELINE_LOG_MODE": "off"}
        )
        self.logger_environment.start()

    def tearDown(self):
        self.logger_environment.stop()

    def test_persisted_entries_override_verifier_audit(self):
        with tempfile.TemporaryDirectory() as root:
            base = Path(root)
            cache_path = base / "cache.jsonl"
            audit_path = base / "verified.jsonl"
            audit_path.write_text(
                json.dumps(
                    {
                        "prompt_version": PROMPT_VERSION,
                        "record_type": "final",
                        "verdict": "correct",
                        "concept": "computer",
                        "perspective": "functional_use",
                        "verified_spec": (
                            "(Concept computer functional_use "
                            "(spec from_verifier))"
                        ),
                    }
                )
                + "\n",
                encoding="utf-8",
            )
            environment = {
                "ALGEBRAIC_SPEC_SPACE_CACHE": str(cache_path),
                "ALGEBRAIC_SPEC_VERIFIER_AUDIT": str(audit_path),
            }
            with patch.dict(os.environ, environment, clear=False):
                cache.persist_algebraic_spec(
                    "computer",
                    "functional_use",
                    "(Concept computer functional_use (spec from_space_cache))",
                )
                rendered = cache.load_persisted_algebraic_specs()

            self.assertIn("from_space_cache", rendered)
            self.assertNotIn("from_verifier", rendered)

    def test_latest_persisted_value_wins(self):
        with tempfile.TemporaryDirectory() as root:
            cache_path = Path(root) / "cache.jsonl"
            environment = {
                "ALGEBRAIC_SPEC_SPACE_CACHE": str(cache_path),
                "ALGEBRAIC_SPEC_SPACE_IMPORT_VERIFIED": "0",
            }
            with patch.dict(os.environ, environment, clear=False):
                cache.persist_algebraic_spec(
                    "server",
                    "functional_use",
                    "(Concept server functional_use (spec first))",
                )
                cache.persist_algebraic_spec(
                    "server",
                    "functional_use",
                    "(Concept server functional_use (spec replacement))",
                )
                rendered = cache.load_persisted_algebraic_specs()

            self.assertIn("replacement", rendered)
            self.assertNotIn("(spec first)", rendered)

    def test_cache_can_be_disabled(self):
        with tempfile.TemporaryDirectory() as root:
            cache_path = Path(root) / "cache.jsonl"
            environment = {
                "ALGEBRAIC_SPEC_SPACE_CACHE": str(cache_path),
                "ALGEBRAIC_SPEC_SPACE_CACHE_MODE": "off",
            }
            with patch.dict(os.environ, environment, clear=False):
                self.assertFalse(
                    cache.persist_algebraic_spec(
                        "computer",
                        "functional_use",
                        "(Concept computer functional_use (spec ignored))",
                    )
                )
                self.assertEqual(cache.load_persisted_algebraic_specs(), "()")
            self.assertFalse(cache_path.exists())


if __name__ == "__main__":
    unittest.main()
