"""End-to-end generator adapter tests for semantic schema bundles."""

from __future__ import annotations

import unittest

from gen_algebraic_spec_kb import (
    Record,
    build_output_lines,
    lowercase_relation_heads,
)


class GeneratorBundleTests(unittest.TestCase):
    def test_generator_emits_rich_separated_knife_spec(self):
        records = [
            Record("isA", "knife", "cutting_tool", 2.0, "", "fixture", 0),
            Record("UsedFor", "knife", "stabbing", 3.0, "", "fixture", 1),
            Record("UsedFor", "knife", "butter", 1.5, "", "fixture", 2),
            Record("hasproperty", "knife", "sharp", 2.0, "", "fixture", 3),
            Record("Causes", "knife", "injury", 1.2, "", "fixture", 4),
        ]
        lines, selected, seen, rejected, classified = build_output_lines(
            records,
            concepts={"knife"},
            max_per_part=None,
            max_per_concept_relation=None,
            keep_noisy_targets=False,
        )
        text = "\n".join(lines)

        self.assertEqual(5, seen)
        self.assertFalse(rejected)
        self.assertEqual(5, sum(classified.values()))
        self.assertTrue(selected)
        self.assertIn("slice_knife", text)
        self.assertIn("pierce_knife", text)
        self.assertIn("(servesTask knife butter)", text)
        self.assertNotIn("use_for_knife_stabbing", text)
        self.assertNotIn("(usedFor knife stabbing)", text)

    def test_emitted_relation_heads_start_with_lowercase(self):
        expression = (
            "(=> (RelatedTo writing output_data) "
            "(forall ((x writing)) (HasProperty x legible)))"
        )

        self.assertEqual(
            "(=> (relatedTo writing output_data) "
            "(forall ((x writing)) (hasProperty x legible)))",
            lowercase_relation_heads(expression),
        )

    def test_family_limit_does_not_truncate_sections(self):
        records = [
            Record("isA", "car", "vehicle", 3.0, "", "fixture", 0),
            Record("UsedFor", "car", "transport", 3.0, "", "fixture", 1),
        ]
        _lines, selected, *_stats = build_output_lines(
            records,
            concepts={"car"},
            max_per_part=1,
            max_per_concept_relation=None,
            keep_noisy_targets=False,
        )
        counts = {}
        for item in selected:
            counts[item.group[2]] = counts.get(item.group[2], 0) + 1

        # The legacy value of one now means one optional schema family. It must
        # not reduce every section to one independently.
        self.assertGreater(counts["sorts"], 1)
        self.assertGreater(counts["operations"], 1)
        self.assertGreater(counts["predicates"], 1)


if __name__ == "__main__":
    unittest.main()
