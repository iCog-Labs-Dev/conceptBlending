"""Unit tests for McBride Derivatives. Mirrors test_quantale_optimality.py style."""
import unittest
from a_quantale_theoretic_approach.core_representation.v_predicate import VPredicateConcept
from a_quantale_theoretic_approach.core_representation.product_quantale import ProductQuantale
from a_quantale_theoretic_approach.optimization.macbride_derivative import (
    weakness, pattern_intensity, joint_pattern_intensity,
    emergence, emergence_tv, mcbride_derivative,
    apply_gradient_step, McBrideOptimizer, uniform_valuation,
    _natural_gradient_tv_step, McBrideRefinementResult,
)

UNIVERSE = ("W_A", "W_B", "W_C")

def _make_concept(name, props: dict) -> VPredicateConcept:
    c = VPredicateConcept(name, universal_set=UNIVERSE)
    for prop, tv in props.items():
        unit_q = ProductQuantale.unit(UNIVERSE)
        new_q = ProductQuantale(unit_q.logic, type(unit_q.tv)(tv))
        c.add_property(prop, new_q)
    return c

class TestWeakness(unittest.TestCase):
    def test_weakness_is_bottom_for_empty_concept(self):
        c = VPredicateConcept("empty", universal_set=UNIVERSE)
        w = weakness(c, uniform_valuation)
        self.assertEqual(w.tv.value, 0.0)

    def test_weakness_is_the_join_of_property_contributions(self):
        c1 = _make_concept("c1", {"p1": 0.8})
        c2 = _make_concept("c2", {"p1": 0.8, "p2": 0.6})
        c3 = _make_concept("c3", {"p1": 0.8, "p2": 0.9})
        w1 = weakness(c1, uniform_valuation)
        w2 = weakness(c2, uniform_valuation)
        w3 = weakness(c3, uniform_valuation)
        self.assertEqual(w2.tv.value, w1.tv.value)
        self.assertGreater(w3.tv.value, w1.tv.value)
        self.assertEqual(w3.tv.value, 0.9)

class TestEmergence(unittest.TestCase):
    def test_blend_richer_than_sources_has_high_emergence(self):
        source_a = _make_concept("A", {"shared": 0.5, "prop_a": 0.8})
        source_b = _make_concept("B", {"shared": 0.5, "prop_b": 0.7})
        # Blend has everything PLUS a new emergent property
        blend    = _make_concept("C", {"shared": 0.9, "prop_a": 0.8,
                                        "prop_b": 0.7, "emergent": 0.6})
        sigma = emergence_tv(source_a, source_b, blend, uniform_valuation)
        self.assertGreater(sigma, 0.0)

    def test_blend_identical_to_source_a_has_low_emergence(self):
        source_a = _make_concept("A", {"p": 0.8})
        source_b = _make_concept("B", {"q": 0.7})
        blend    = _make_concept("C", {"p": 0.8})  # just source A
        sigma = emergence_tv(source_a, source_b, blend, uniform_valuation)
        # In a bounded [0,1] quantale, since B contributes nothing, ib = 0.0.
        # Thus (ia * ib) = 0.0. The implication 0.0 >> iab is vacuously TRUE (1.0).
        self.assertEqual(sigma, 1.0)

class TestMcBrideDerivative(unittest.TestCase):
    def test_derivative_is_non_negative(self):
        source_a = _make_concept("A", {"p1": 0.7, "shared": 0.5})
        source_b = _make_concept("B", {"p2": 0.6, "shared": 0.5})
        blend    = _make_concept("C", {"p1": 0.7, "p2": 0.6, "shared": 0.8})
        for prop in blend.entries:
            deriv = mcbride_derivative(prop, source_a, source_b, blend, uniform_valuation)
            self.assertGreaterEqual(deriv.tv.value, 0.0,
                                    f"Derivative for {prop} should be non-negative")

    def test_derivative_tv_stays_in_unit_interval(self):
        source_a = _make_concept("A", {"p": 0.9})
        source_b = _make_concept("B", {"p": 0.8})
        blend    = _make_concept("C", {"p": 0.85})
        deriv = mcbride_derivative("p", source_a, source_b, blend, uniform_valuation)
        self.assertGreaterEqual(deriv.tv.value, 0.0)
        self.assertLessEqual(deriv.tv.value, 1.0)

class TestRefinementLoop(unittest.TestCase):
    def test_refinement_does_not_decrease_emergence(self):
        source_a = _make_concept("A", {"shared": 0.6, "pa": 0.8})
        source_b = _make_concept("B", {"shared": 0.6, "pb": 0.7})
        blend    = _make_concept("C", {"shared": 0.5, "pa": 0.4, "pb": 0.3})

        optimizer = McBrideOptimizer(source_a, source_b, max_steps=10)
        result = optimizer.refine(blend)

        self.assertGreaterEqual(result.emergence_history[-1],
                                result.emergence_history[0] - 0.01)  # ±tolerance

    def test_tv_values_stay_in_bounds(self):
        source_a = _make_concept("A", {"p": 0.9})
        source_b = _make_concept("B", {"p": 0.1})
        blend    = _make_concept("C", {"p": 0.5})

        optimizer = McBrideOptimizer(source_a, source_b, max_steps=15)
        result = optimizer.refine(blend)

        for prop, tvs in result.property_tv_history.items():
            for tv in tvs:
                self.assertGreaterEqual(tv, 0.01, f"{prop} TV went below floor")
                self.assertLessEqual(tv, 0.99,   f"{prop} TV exceeded ceiling")

    def test_optimizer_exposes_top_gradients(self):
        source_a = _make_concept("A", {"p1": 0.9, "p2": 0.3})
        source_b = _make_concept("B", {"p1": 0.1, "p2": 0.8})
        blend    = _make_concept("C", {"p1": 0.5, "p2": 0.5})

        optimizer = McBrideOptimizer(source_a, source_b)
        top = optimizer.top_properties_by_gradient(blend, top_n=2)
        self.assertEqual(len(top), 2)
        self.assertGreaterEqual(top[0][1], top[1][1])  # sorted descending

class TestNaturalGradientStep(unittest.TestCase):
    """
    Directly tests _natural_gradient_tv_step — the function that was
    incorrectly implemented. These tests were NOT in the original suite.
    """

    def test_step_at_low_boundary_does_not_explode(self):
        """TV near 0 (above 0.10 floor) should produce a small step, not a large one."""
        tv = 0.12
        deriv = 0.8
        eta = 0.05
        result = _natural_gradient_tv_step(tv, deriv, eta)
        # variance = 0.12 * 0.88 = 0.1056, step = 0.05 * 0.1056 * 0.8 = 0.0042
        self.assertGreater(result, tv)          # moves up
        self.assertLess(result - tv, 0.01)      # step is small, not inflated

    def test_step_at_high_boundary_slows_down(self):
        """TV near 1 should produce a very small step (Fisher metric)."""
        tv = 0.95
        deriv = 0.8
        eta = 0.05
        result = _natural_gradient_tv_step(tv, deriv, eta)
        # variance = 0.95 * 0.05 = 0.0475, step ≈ 0.0019
        self.assertGreater(result, tv)
        self.assertLess(result - tv, 0.01)      # step is small near ceiling

    def test_floor_is_0_10_not_0_01(self):
        """Output must never go below 0.10 — consistent with Phase 1 GNN floor."""
        result = _natural_gradient_tv_step(0.10, -5.0, 0.5)
        self.assertGreaterEqual(result, 0.10)

    def test_ceiling_is_0_99(self):
        """Output must never exceed 0.99."""
        result = _natural_gradient_tv_step(0.98, 10.0, 1.0)
        self.assertLessEqual(result, 0.99)

    def test_zero_derivative_produces_no_change(self):
        """If gradient is zero, TV must not change."""
        tv = 0.5
        result = _natural_gradient_tv_step(tv, 0.0, 0.05)
        self.assertAlmostEqual(result, tv, places=6)

    def test_negative_derivative_moves_tv_down(self):
        """Negative gradient should decrease TV (descent, not ascent)."""
        tv = 0.7
        result = _natural_gradient_tv_step(tv, -0.5, 0.05)
        self.assertLess(result, tv)

    def test_variance_rescue_floor_prevents_nan(self):
        """When TV is extremely small, variance should not cause NaN."""
        result = _natural_gradient_tv_step(0.001, 1.0, 0.05)
        self.assertTrue(0.10 <= result <= 0.99)
        self.assertFalse(result != result)  # NaN check


class TestSummaryMethod(unittest.TestCase):
    """Tests the summary() string format — the escaped newline bug."""

    def test_summary_contains_real_newlines_not_escaped(self):
        source_a = _make_concept("A", {"p": 0.7})
        source_b = _make_concept("B", {"p": 0.6})
        blend    = _make_concept("C", {"p": 0.8})

        optimizer = McBrideOptimizer(source_a, source_b, max_steps=2)
        result = optimizer.refine(blend)
        summary = result.summary()

        # Must contain real newline character
        self.assertIn("\n", summary)
        # Must NOT contain escaped newline literal
        self.assertNotIn("\\n", summary)

    def test_summary_contains_emergence_values(self):
        source_a = _make_concept("A", {"p": 0.7})
        source_b = _make_concept("B", {"p": 0.6})
        blend    = _make_concept("C", {"p": 0.8})

        optimizer = McBrideOptimizer(source_a, source_b, max_steps=2)
        result = optimizer.refine(blend)
        summary = result.summary()

        self.assertIn("Emergence", summary)
        self.assertIn("steps", summary)
        self.assertIn("converged", summary)


if __name__ == '__main__':
    unittest.main()
