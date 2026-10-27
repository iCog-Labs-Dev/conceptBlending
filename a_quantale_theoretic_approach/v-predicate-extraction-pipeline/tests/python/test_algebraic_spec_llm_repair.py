"""Unit tests for optional LLM algebraic-spec repair plumbing."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from algebraic_spec_llm_repair import (
    JsonlRepairCache,
    StaticLLMRepairProvider,
    normalize_proposal,
    propose_with_cache,
    should_use_llm_repair,
)


class LLMRepairPlumbingTests(unittest.TestCase):
    def test_normalize_proposal_keeps_strict_sections(self):
        proposal = normalize_proposal(
            {
                "sense": {"selected_sense": "animal/bat"},
                "repairs": {
                    "sorts": [{"name": "bat", "confidence": 0.8}],
                    "operations": "bad",
                    "predicates": [],
                    "axioms": [],
                },
                "notes": ["ok"],
            }
        )
        self.assertEqual([{"name": "bat", "confidence": 0.8}], proposal["repairs"]["sorts"])
        self.assertEqual([], proposal["repairs"]["operations"])

    def test_missing_mode_uses_quality_gate(self):
        self.assertTrue(should_use_llm_repair("missing", {"quality": {"operation_count": 1}}))
        self.assertFalse(
            should_use_llm_repair(
                "missing",
                {"quality": {"operation_count": 3, "axiom_count": 3, "operation_axiom_coverage": 1.0}},
            )
        )

    def test_cache_prevents_repeated_provider_calls(self):
        class CountingProvider(StaticLLMRepairProvider):
            def __init__(self):
                super().__init__({"repairs": {"sorts": [], "operations": [], "predicates": [], "axioms": []}})
                self.calls = 0

            def propose(self, context):
                self.calls += 1
                return super().propose(context)

        with tempfile.TemporaryDirectory() as tmp:
            provider = CountingProvider()
            cache = JsonlRepairCache(Path(tmp) / "repair.jsonl")
            context = {"concept": "bat", "perspective": "behavioral_process"}
            propose_with_cache(provider, context, cache)
            propose_with_cache(provider, context, cache)
            self.assertEqual(1, provider.calls)


if __name__ == "__main__":
    unittest.main()
