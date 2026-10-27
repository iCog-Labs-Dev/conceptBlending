"""Tests for scoped perspective properties and filtered possible worlds."""

from __future__ import annotations

import unittest

from gen_algebraic_spec_kb import Record
from gen_property_world_kb import MAX_WORLDS_PER_PROPERTY, build_output_lines


class PropertyWorldGeneratorTests(unittest.TestCase):
    def test_functional_properties_are_derived_from_use_and_capability(self):
        records = [
            Record("UsedFor", "computer", "process_information", 3.0, "", "fixture", 0),
            Record("CapableOf", "computer", "run_programs", 2.0, "", "fixture", 1),
            Record("hasproperty", "computer", "expensive", 1.0, "", "fixture", 2),
        ]

        lines, stats = build_output_lines(records, concepts={"computer"})
        text = "\n".join(lines)

        self.assertIn("computer functional_use property_key_computer_functional_use_process_information", text)
        self.assertIn("computer functional_use property_key_computer_functional_use_run_programs", text)
        self.assertIn(
            "computer information_computational "
            "property_key_computer_information_computational_process_information",
            text,
        )
        self.assertIn("computer economic_ownership property_key_computer_economic_ownership_expensive", text)
        self.assertGreaterEqual(stats["properties"], 3)

    def test_action_variants_share_one_canonical_property(self):
        records = [
            Record("UsedFor", "computer", "acces_internet", 1.0, "", "fixture", 0),
            Record("UsedFor", "computer", "accessing_internet", 3.0, "", "fixture", 1),
            Record("UsedFor", "laptop", "access_internet", 2.0, "", "fixture", 2),
        ]

        lines, stats = build_output_lines(records, concepts={"computer"})
        text = "\n".join(lines)

        self.assertIn("property_key_computer_functional_use_access_internet", text)
        self.assertNotIn("functional_use_acces_internet", text)
        self.assertNotIn("functional_use_accessing_internet", text)
        self.assertIn("functional_use laptop", text)
        self.assertEqual(2, stats["properties"])

    def test_property_handles_are_scoped_by_concept_and_perspective(self):
        records = [
            Record("hasproperty", "boat", "red", 2.0, "", "fixture", 0),
            Record("hasproperty", "car", "red", 2.0, "", "fixture", 1),
        ]
        lines, _stats = build_output_lines(records)
        text = "\n".join(lines)

        self.assertIn("property_key_boat_physical_attribute_red", text)
        self.assertIn("property_key_car_physical_attribute_red", text)

    def test_lexical_and_unapproved_relations_are_not_worlds(self):
        records = [
            Record("hasproperty", "person", "helpful", 3.0, "", "fixture", 0),
            Record("hasproperty", "friend", "helpful", 2.0, "", "fixture", 1),
            Record("Synonym", "beneficial", "helpful", 5.0, "", "fixture", 2),
            Record("DerivedFrom", "helpfulness", "helpful", 5.0, "", "fixture", 3),
            Record("RelatedTo", "random_phrase", "helpful", 5.0, "", "fixture", 4),
        ]
        lines, _stats = build_output_lines(records, concepts={"person"})
        text = "\n".join(lines)

        self.assertIn("functional_use friend", text)
        self.assertNotIn("beneficial", text)
        self.assertNotIn("helpfulness", text)
        self.assertNotIn("random_phrase", text)

    def test_good_worlds_require_semantic_evidence_not_any_incoming_edge(self):
        records = [
            Record("hasproperty", "moral_action", "good", 3.0, "", "fixture", 0),
            Record("hasproperty", "kind_deed", "good", 2.0, "", "fixture", 1),
            Record("Synonym", "gooder", "good", 9.0, "", "fixture", 2),
            Record("DerivedFrom", "goodness", "good", 9.0, "", "fixture", 3),
            Record("RelatedTo", "apple", "good", 9.0, "", "fixture", 4),
            Record("Antonym", "bad", "good", 9.0, "", "fixture", 5),
        ]

        lines, stats = build_output_lines(records, concepts={"moral_action"})
        text = "\n".join(lines)

        self.assertIn("kind_deed", text)
        self.assertNotIn("gooder", text)
        self.assertNotIn("goodness", text)
        self.assertNotIn("apple", text)
        self.assertNotIn(" bad good", text)
        self.assertEqual(2, stats["holds_in"])

    def test_harmful_capability_is_not_promoted_as_functional_property(self):
        records = [
            Record("CapableOf", "computer", "do_bad_things", 4.0, "", "fixture", 0),
            Record("CapableOf", "computer", "run_programs", 2.0, "", "fixture", 1),
        ]

        lines, _stats = build_output_lines(records, concepts={"computer"})
        text = "\n".join(lines)

        self.assertNotIn("do_bad_things", text)
        self.assertIn("run_programs", text)

    def test_high_frequency_property_does_not_share_arbitrary_worlds(self):
        records = [
            Record("hasproperty", f"candidate_{index}", "generic_quality", 2.0,
                   "", "fixture", index)
            for index in range(70)
        ]

        lines, stats = build_output_lines(records)
        candidate_zero_worlds = [
            line for line in lines
            if "scoped_property_holds_in" in line
            and "property_key_candidate_0_descriptive_property_generic_quality " in line
        ]

        self.assertEqual(1, len(candidate_zero_worlds))
        self.assertIn("descriptive_property candidate_0", candidate_zero_worlds[0])
        self.assertEqual(70, stats["holds_in"])

    def test_worlds_are_ranked_capped_and_deduplicated(self):
        records = [Record("hasproperty", "person", "helpful", 3.0, "", "fixture", 0)]
        records.extend(
            Record("hasproperty", f"candidate_{index}", "helpful", float(index + 1), "", "fixture", index + 1)
            for index in range(MAX_WORLDS_PER_PROPERTY + 8)
        )
        records.append(Record("hasproperty", "candidate_27", "helpful", 99.0, "", "fixture", 100))

        lines, stats = build_output_lines(
            records, concepts={"person"}, include_provenance=True
        )
        text = "\n".join(lines)

        self.assertEqual(MAX_WORLDS_PER_PROPERTY, stats["holds_in"])
        duplicate_evidence_count = sum(
            "world_evidence property_key_person_functional_use_helpful "
            "hasproperty candidate_27 helpful" in line
            for line in lines
        )
        self.assertEqual(1, duplicate_evidence_count)

    def test_self_worlds_are_configurable(self):
        records = [Record("UsedFor", "computer", "calculate", 2.0, "", "fixture", 0)]

        _lines, with_self = build_output_lines(records, concepts={"computer"})
        _lines, without_self = build_output_lines(
            records, concepts={"computer"}, include_self_worlds=False
        )

        self.assertGreater(with_self["holds_in"], 0)
        self.assertEqual(0, without_self["holds_in"])


if __name__ == "__main__":
    unittest.main()
