import math
import tempfile
from pathlib import Path
import unittest

from a_quantale_theoretic_approach.optimization.hybrid_search.python import hybrid_sampling
from habit_memory import atomspace_evidence


COMPACT_A = """(Concept boat functional_use
  (Properties ((move_on_water) ((boat) (ferry)))))"""
COMPACT_B = """(Concept car functional_use
  (Properties ((move_on_land) ((car) (bus)))))"""
PROPERTY_RESOLUTIONS = """(PairResolutions
  ((PairResolution (PropertyPairId move_on_water move_on_land)
                    locomotion (stv 0.8 0.7))))"""
WORLD_MAPPINGS = """(WorldMappings
  ((GenericWorldMapping vehicle locomotion move_on_water move_on_land boat car)
   (GenericWorldMapping transport locomotion move_on_water move_on_land ferry bus)))"""


class ScalarAndGenericTests(unittest.TestCase):
    def setUp(self):
        self.a = hybrid_sampling.enrich_compact_vpredicate(COMPACT_A, 11)
        self.b = hybrid_sampling.enrich_compact_vpredicate(COMPACT_B, 12)

    def test_enrichment_is_seeded_and_scalar(self):
        self.assertEqual(self.a, hybrid_sampling.enrich_compact_vpredicate(COMPACT_A, 11))
        concept = hybrid_sampling._concept(self.a)
        self.assertEqual(concept.perspective, "functional_use")
        self.assertIsInstance(concept.properties[0].degree, float)
        self.assertEqual(concept.properties[0].worlds, ("boat", "ferry"))

    def test_cartesian_requests_include_property_and_world_provenance(self):
        prop_requests = hybrid_sampling.property_pair_requests(self.a, self.b)
        self.assertIn("(PropertyPairId move_on_water move_on_land)", prop_requests)
        world_requests = hybrid_sampling.world_pair_requests(
            self.a, self.b, PROPERTY_RESOLUTIONS
        )
        self.assertEqual(world_requests.count("(PairRequest "), 4)
        self.assertIn("(WorldPairId locomotion move_on_water move_on_land boat car)", world_requests)

    def test_generic_predicate_contains_materialized_worlds(self):
        result = hybrid_sampling.generic_vpredicate_result(
            "vehicle", "functional_use", PROPERTY_RESOLUTIONS, WORLD_MAPPINGS, 13
        )
        concept, mappings = hybrid_sampling._generic_result(result)
        self.assertEqual(concept.properties[0].name, "locomotion")
        self.assertEqual(concept.properties[0].worlds, ("vehicle", "transport"))
        self.assertEqual(mappings, [("locomotion", "move_on_water", "move_on_land")])

    def test_target_and_five_by_ten_sampling(self):
        generic = hybrid_sampling.generic_vpredicate_result(
            "vehicle", "functional_use", PROPERTY_RESOLUTIONS, WORLD_MAPPINGS, 13
        )
        strengths = """(HabitStrengths
          ((HabitStrength locomotion move_on_water move_on_land 0.8)))"""
        target = hybrid_sampling.habit_target(self.a, self.b, generic, strengths, 0.5)
        entries = hybrid_sampling._target_entries(target)
        base, habit = entries[0][1], entries[0][2]
        self.assertTrue(math.isclose(habit, base + 0.5 * 0.8 * (1-base)))
        sampled = hybrid_sampling.sample_populations(generic, target, 19)
        self.assertEqual(hybrid_sampling.population_count(sampled), 5)
        self.assertEqual(hybrid_sampling.individual_counts(sampled), "(10 10 10 10 10)")
        self.assertEqual(sampled, hybrid_sampling.sample_populations(generic, target, 19))


class AtomspaceEvidenceTests(unittest.TestCase):
    def test_index_uses_all_binary_edges_and_returns_compact_counts(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / "evidence"
            root.mkdir()
            (root / "one.metta").write_text(
                "(relatedTo move_on_water move_on_land)\n"
                "(relatedTo move_on_water transport)\n"
                "(source (relatedTo move_on_water transport) move_on_water)\n",
                encoding="utf-8",
            )
            (root / "two.metta").write_text(
                "(usedFor move_on_land transport)\n", encoding="utf-8"
            )
            index = Path(temp) / "habits.sqlite3"
            atomspace_evidence.build_index(root, index)
            evidence = atomspace_evidence.load_evidence(
                "(move_on_water move_on_land)", root, index
            )
            self.assertIn("(PropertyCount move_on_water 2)", evidence)
            self.assertIn("(PropertyCount move_on_land 2)", evidence)
            self.assertIn("(PairCount move_on_water move_on_land 1)", evidence)
            self.assertIn("(EvidenceCount 3)", evidence)


if __name__ == "__main__":
    unittest.main()
