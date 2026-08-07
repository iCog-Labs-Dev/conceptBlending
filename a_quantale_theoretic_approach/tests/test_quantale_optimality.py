from __future__ import annotations

import math
import unittest

from a_quantale_theoretic_approach.core_representation.product_quantale import ProductQuantale
from a_quantale_theoretic_approach.core_representation.v_predicate import VPredicateConcept
from a_quantale_theoretic_approach.core_representation.v_predicate_parser import parse_v_predicate_document
from a_quantale_theoretic_approach.optimality import (
    CrossMapping,
    QuantaleConstraintManager,
    QuantaleRelation,
    RelationSet,
)
from a_quantale_theoretic_approach.structural_reasoning.quantale_colimit_engine import (
    compute_quantale_colimit,
)


def _boat_car_fixture():
    source = """
    (WorldSpec W_FERRY (independent-spec (sorts (Vessel))))
    (WorldSpec W_ROWBOAT (independent-spec (sorts (Boat))))
    (WorldSpec W_COMMUTE (independent-spec (sorts (Vehicle))))

    (Concept Boat
      (V-predicate
        (Property
          (floatsOnWater (WorldSpecSet (W_FERRY W_ROWBOAT)) 0.95)
          (providesTransport (WorldSpecSet (W_FERRY)) 0.80))))

    (Concept Car
      (V-predicate
        (Property
          (travelsOnRoad (WorldSpecSet (W_COMMUTE)) 0.90)
          (providesTransport (WorldSpecSet (W_COMMUTE)) 0.85))))
    """
    doc = parse_v_predicate_document(source)
    boat, car = doc.concepts
    colimit = compute_quantale_colimit(
        boat,
        car,
        map_g_to_a={"properties": {"TransportCapability": "providesTransport"}},
        map_g_to_b={"properties": {"TransportCapability": "providesTransport"}},
        blend_name="AmphibiousVehicle",
        world_specs=doc.world_specs,
    )
    relations = RelationSet(
        source_a=[QuantaleRelation("UsedFor", "floatsOnWater", "providesTransport")],
        source_b=[QuantaleRelation("UsedFor", "travelsOnRoad", "providesTransport")],
        blend=[
            QuantaleRelation("UsedFor", "floatsOnWater", "providesTransport"),
            QuantaleRelation("UsedFor", "travelsOnRoad", "providesTransport"),
        ],
        cross_mappings=[
            CrossMapping(
                QuantaleRelation("UsedFor", "floatsOnWater", "providesTransport"),
                QuantaleRelation("UsedFor", "travelsOnRoad", "providesTransport"),
            )
        ],
    )
    return boat, car, colimit, relations


def _world_labels(product: ProductQuantale) -> set[str]:
    return {atom.label for atom in product.logic.value}


class QuantaleOptimalityTests(unittest.TestCase):
    def test_property_colimit_joins_shared_v_predicate_values(self):
        _boat, _car, colimit, _relations = _boat_car_fixture()

        blend = colimit.blend
        self.assertEqual(set(blend.entries), {"floatsOnWater", "providesTransport", "travelsOnRoad"})
        self.assertTrue(math.isclose(blend.get_property("providesTransport").tv.value, 0.85))
        self.assertEqual(_world_labels(blend.get_property("providesTransport")), {"W_FERRY", "W_COMMUTE"})
        self.assertEqual(colimit.metrics["SharedPropertyCount"], 1)

    def test_happy_path_optimality_constraints_pass_with_relation_and_relevance_data(self):
        boat, car, colimit, relations = _boat_car_fixture()

        report = QuantaleConstraintManager().evaluate(
            boat,
            car,
            colimit,
            relations=relations,
            relevance={"providesTransport": 1.0, "floatsOnWater": 0.8},
        )

        self.assertTrue(math.isclose(report.scalar_score, 0.85))
        self.assertEqual(
            set(report.conditions),
            {
                "integration",
                "topology",
                "web",
                "unpacking",
                "good_reason",
                "metonymic_tightening",
                "relevance",
            },
        )
        for name, result in report.conditions.items():
            self.assertTrue(result.passed)
            self.assertFalse(result.skipped)
            expected = 0.85 if name == "relevance" else 1.0
            self.assertTrue(math.isclose(result.tv_score, expected))

    def test_relationless_property_only_evaluation_marks_relation_ops_skipped(self):
        boat, car, colimit, _relations = _boat_car_fixture()

        report = QuantaleConstraintManager().evaluate(boat, car, colimit)

        for name in ("topology", "web", "metonymic_tightening", "relevance"):
            self.assertTrue(report.conditions[name].skipped)
            self.assertTrue(report.conditions[name].passed)
            self.assertTrue(math.isclose(report.conditions[name].tv_score, 1.0))

        for name in ("integration", "unpacking", "good_reason"):
            self.assertFalse(report.conditions[name].skipped)
            self.assertTrue(report.conditions[name].passed)

    def test_integration_detects_candidate_that_is_not_the_property_colimit(self):
        boat, car, colimit, _relations = _boat_car_fixture()
        weak_candidate = VPredicateConcept("WeakAmphibiousVehicle", universal_set=("W_FERRY", "W_ROWBOAT", "W_COMMUTE"))
        weak_candidate.add_property(
            "floatsOnWater",
            ProductQuantale.from_worlds(("W_FERRY",), 0.1, ("W_FERRY", "W_ROWBOAT", "W_COMMUTE")),
        )

        report = QuantaleConstraintManager().evaluate(
            boat,
            car,
            colimit,
            candidate_blend=weak_candidate,
        )

        self.assertLess(report.conditions["integration"].tv_score, 1.0)
        self.assertFalse(report.conditions["integration"].passed)

    def test_good_reason_flags_unsupported_emergent_property(self):
        boat, car, colimit, _relations = _boat_car_fixture()
        candidate = VPredicateConcept("OddBlend", universal_set=("W_FERRY", "W_ROWBOAT", "W_COMMUTE", "W_MAGIC"))
        for prop_name, entry in colimit.blend.entries.items():
            candidate.add_property(prop_name, entry.quantale.with_universe(candidate.universal_set))
        candidate.add_property(
            "magicLevitation",
            ProductQuantale.from_worlds(("W_MAGIC",), 0.9, ("W_FERRY", "W_ROWBOAT", "W_COMMUTE", "W_MAGIC")),
        )

        report = QuantaleConstraintManager().evaluate(
            boat,
            car,
            colimit,
            candidate_blend=candidate,
        )

        good_reason = report.conditions["good_reason"]
        self.assertLess(good_reason.tv_score, 1.0)
        self.assertFalse(good_reason.passed)
        self.assertIn("magicLevitation", good_reason.details["unsupported_properties"])


if __name__ == "__main__":
    unittest.main()
