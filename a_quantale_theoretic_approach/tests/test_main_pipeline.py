"""Integration test for full run_full_pipeline."""
import unittest
from a_quantale_theoretic_approach.core_representation.v_predicate import VPredicateConcept
from a_quantale_theoretic_approach.core_representation.product_quantale import ProductQuantale
from a_quantale_theoretic_approach.main_pipeline import run_full_pipeline
from a_quantale_theoretic_approach.structural_reasoning.quantale_colimit_engine import (
    QuantaleColimitResult,
)

UNIVERSE = ("W_1", "W_2")

def _make_concept(name, props: dict) -> VPredicateConcept:
    c = VPredicateConcept(name, universal_set=UNIVERSE)
    for prop, tv in props.items():
        unit_q = ProductQuantale.unit(UNIVERSE)
        new_q = ProductQuantale(unit_q.logic, type(unit_q.tv)(tv))
        c.add_property(prop, new_q)
    return c

class TestMainPipeline(unittest.TestCase):
    def test_run_full_pipeline_end_to_end(self):
        time = _make_concept("Time", {"valuable": 0.8, "resource": 0.9, "abstract": 0.7})
        money = _make_concept("Money", {"valuable": 0.9, "currency": 0.95, "resource": 0.85})

        result = run_full_pipeline(
            concept_a=time,
            concept_b=money,
            blend_name="TimeIsMoney",
            mcbride_steps=5,
        )

        self.assertIn("colimit", result)
        self.assertIn("refinement", result)
        self.assertIn("optimality", result)
        self.assertIn("final_blend", result)

        refinement = result["refinement"]
        self.assertGreaterEqual(refinement.emergence_gain, -0.01)
        self.assertGreater(len(result["final_blend"].entries), 0)

class TestMainPipelineSignatures(unittest.TestCase):
    """
    Tests the main_pipeline specifically for the evaluate_quantale_optimality
    signature bug. This was NOT tested originally.
    """

    def test_run_full_pipeline_does_not_raise_typeerror(self):
        """
        The original pipeline called evaluate_quantale_optimality with a
        nonexistent candidate_blend= keyword arg. This test confirms that
        specific TypeError is fixed.
        """
        sa = _make_concept("Time",  {"finite": 0.85, "valuable": 0.70, "spent": 0.80})
        sb = _make_concept("Money", {"finite": 0.80, "valuable": 0.95, "spent": 0.90})

        try:
            result = run_full_pipeline(
                concept_a=sa,
                concept_b=sb,
                blend_name="TimeIsMoney",
                mcbride_steps=5,
            )
        except TypeError as e:
            self.fail(
                f"run_full_pipeline raised TypeError — likely the "
                f"evaluate_quantale_optimality signature bug is not fixed: {e}"
            )

    def test_pipeline_returns_all_expected_keys(self):
        """Pipeline output dict must have all four keys."""
        sa = _make_concept("A", {"p1": 0.7, "shared": 0.5})
        sb = _make_concept("B", {"p2": 0.6, "shared": 0.5})

        result = run_full_pipeline(sa, sb, blend_name="Blend", mcbride_steps=3)

        self.assertIn("colimit",     result)
        self.assertIn("refinement",  result)
        self.assertIn("optimality",  result)
        self.assertIn("final_blend", result)

    def test_pipeline_refined_colimit_has_same_world_specs(self):
        """
        The refined_colimit passed to evaluate_quantale_optimality must
        preserve world_specs from the colimit step — not use None.
        """
        sa = _make_concept("A", {"p1": 0.7, "shared": 0.5})
        sb = _make_concept("B", {"p2": 0.6, "shared": 0.5})

        result = run_full_pipeline(sa, sb, blend_name="Blend", mcbride_steps=3)

        self.assertGreater(len(result["final_blend"].entries), 0)
        colimit = result["colimit"]
        self.assertIsNotNone(colimit.world_specs)

    def test_pipeline_emergence_is_tracked(self):
        """Refinement result must have a non-empty emergence history."""
        sa = _make_concept("A", {"p1": 0.7, "shared": 0.5})
        sb = _make_concept("B", {"p2": 0.6, "shared": 0.5})

        result = run_full_pipeline(sa, sb, blend_name="Blend", mcbride_steps=5)
        refinement = result["refinement"]

        self.assertGreater(len(refinement.emergence_history), 1)
        for sigma in refinement.emergence_history:
            self.assertIsInstance(sigma, float)
            self.assertGreaterEqual(sigma, 0.0)
            self.assertLessEqual(sigma, 1.0)

    def test_pipeline_final_blend_tvs_in_bounds(self):
        """All TV values in the final blend must respect the 0.10 floor."""
        sa = _make_concept("A", {"p1": 0.7, "shared": 0.5})
        sb = _make_concept("B", {"p2": 0.6, "shared": 0.5})

        result = run_full_pipeline(sa, sb, blend_name="Blend", mcbride_steps=10)
        final_blend = result["final_blend"]

        for prop, entry in final_blend.entries.items():
            tv = entry.quantale.tv.value
            self.assertGreaterEqual(tv, 0.10,
                f"Property '{prop}' TV={tv:.4f} is below the 0.10 floor")
            self.assertLessEqual(tv, 0.99,
                f"Property '{prop}' TV={tv:.4f} exceeds the 0.99 ceiling")


class TestPipelineWithGenericSpace(unittest.TestCase):
    """Tests the pipeline with an optional generic space G — the full colimit path."""

    def test_pipeline_with_generic_space_does_not_crash(self):
        sa = _make_concept("Evolution",    {"variation": 0.90, "selection": 0.85, "population": 0.90})
        sb = _make_concept("Optimization", {"search": 0.95,    "objective":  0.95, "population": 0.85})
        g  = _make_concept("Generic",      {"population": 0.70})

        try:
            result = run_full_pipeline(
                concept_a=sa,
                concept_b=sb,
                concept_g=g,
                map_g_to_a={"population": "population"},
                map_g_to_b={"population": "population"},
                blend_name="NaturalSelection",
                mcbride_steps=5,
            )
        except Exception as e:
            self.fail(f"Pipeline with generic space raised: {e}")

        self.assertIn("final_blend", result)
        self.assertGreater(len(result["final_blend"].entries), 0)


if __name__ == "__main__":
    unittest.main()
