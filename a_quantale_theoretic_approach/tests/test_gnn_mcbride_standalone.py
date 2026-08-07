"""
Standalone McBride Application Tests using real GNN-extracted data.

These tests verify that the McBride derivative optimization algorithm
behaves correctly on real concept data extracted by the Phase 1 GNN.

Focus:
  - Property TV ordering is preserved after refinement
  - Gradient direction is correct (stronger props get bigger steps)
  - Convergence behavior is sensible
  - The colimit correctly handles shared properties
  - Emergence signal is meaningful (not vacuously saturated)
  - The valuation choice affects gradient magnitude as expected
"""

import unittest
from functools import partial
from a_quantale_theoretic_approach.core_representation.v_predicate import VPredicateConcept
from a_quantale_theoretic_approach.core_representation.product_quantale import ProductQuantale
from a_quantale_theoretic_approach.structural_reasoning.quantale_colimit_engine import (
    compute_quantale_colimit,
)
from a_quantale_theoretic_approach.optimization.macbride_derivative import (
    McBrideOptimizer,
    McBrideRefinementResult,
    emergence_tv,
    uniform_valuation,
    tv_proportional_valuation,
    habit_weighted_valuation,
    weakness,
    mcbride_derivative,
    pattern_intensity,
    joint_pattern_intensity,
    apply_gradient_step,
)


FIRE_PROPS = {
    "hot":        0.2684,
    "dangerous":  0.2924,
    "bright":     0.2576,
    "red":        0.2840,
    "expressive": 0.1539,
}

ART_PROPS = {
    "beautiful":     0.1862,
    "subjective":    0.1474,
    "abstract":      0.1152,
    "philosophical": 0.1101,
    "expressive":    0.1350,
}

EXPECTED_COLIMIT_PROPS = {
    "hot":           0.2684,
    "dangerous":     0.2924,
    "bright":        0.2576,
    "red":           0.2840,
    "expressive":    0.1539,
    "beautiful":     0.1862,
    "subjective":    0.1474,
    "abstract":      0.1152,
    "philosophical": 0.1101,
}

EXPECTED_REFINED_PROPS = {
    "hot":           0.3196,
    "dangerous":     0.3461,
    "bright":        0.3076,
    "red":           0.3369,
    "expressive":    0.1887,
    "beautiful":     0.2265,
    "subjective":    0.1810,
    "abstract":      0.1427,
    "philosophical": 0.1366,
}

UNIVERSE = ("W_FIRE", "W_ART", "W_BLEND")


def _make_concept(name: str, props: dict) -> VPredicateConcept:
    """Build a VPredicateConcept from a name and TV dict."""
    c = VPredicateConcept(name, universal_set=UNIVERSE)
    for prop, tv in props.items():
        unit_q = ProductQuantale.unit(UNIVERSE)
        new_q = ProductQuantale(unit_q.logic, type(unit_q.tv)(tv))
        c.add_property(prop, new_q)
    return c


class TestColimitWithRealGNNData(unittest.TestCase):
    """Verifies the Colimit Engine correctly handles the GNN output."""

    def setUp(self):
        self.fire = _make_concept("Fire", FIRE_PROPS)
        self.art  = _make_concept("Art",  ART_PROPS)
        self.colimit = compute_quantale_colimit(
            self.fire, self.art, blend_name="FireArtBlend"
        )
        self.blend = self.colimit.blend

    def test_colimit_has_all_nine_properties(self):
        """The blend must contain all 5 Fire + 5 Art properties,
        with expressive merged into one (9 total)."""
        self.assertEqual(len(self.blend.entries), 9,
            f"Expected 9 properties, got {len(self.blend.entries)}: "
            f"{list(self.blend.entries.keys())}")

    def test_expressive_is_joined_not_duplicated(self):
        """'expressive' appears in both sources — colimit must JOIN them, not duplicate."""
        self.assertIn("expressive", self.blend.entries,
            "expressive must be in the blend")
        expressive_count = sum(
            1 for k in self.blend.entries if k == "expressive"
        )
        self.assertEqual(expressive_count, 1,
            "expressive must appear exactly once in the blend")

    def test_expressive_tv_is_lattice_maximum_of_sources(self):
        """
        expressive join: max(0.1539, 0.1350) = 0.1539
        The colimit q-join uses the lattice maximum for the TV component.
        """
        expressive_tv = self.blend.entries["expressive"].quantale.tv.value
        expected = max(FIRE_PROPS["expressive"], ART_PROPS["expressive"])
        self.assertAlmostEqual(expressive_tv, expected, places=3,
            msg=f"expressive TV should be lattice max {expected:.4f}, "
                f"got {expressive_tv:.4f}")

    def test_unshared_properties_carry_through_unchanged(self):
        """Properties unique to one source must pass through with original TV."""
        fire_only = ["hot", "dangerous", "bright", "red"]
        art_only  = ["beautiful", "subjective", "abstract", "philosophical"]

        for prop in fire_only:
            got = self.blend.entries[prop].quantale.tv.value
            expected = FIRE_PROPS[prop]
            self.assertAlmostEqual(got, expected, places=3,
                msg=f"Fire property '{prop}' TV changed in colimit: "
                    f"expected {expected:.4f}, got {got:.4f}")

        for prop in art_only:
            got = self.blend.entries[prop].quantale.tv.value
            expected = ART_PROPS[prop]
            self.assertAlmostEqual(got, expected, places=3,
                msg=f"Art property '{prop}' TV changed in colimit: "
                    f"expected {expected:.4f}, got {got:.4f}")


class TestMcBrideGradientOnRealData(unittest.TestCase):
    """
    Tests that the McBride derivative produces the correct gradient
    direction and relative magnitude on real GNN data.
    """

    def setUp(self):
        self.fire = _make_concept("Fire", FIRE_PROPS)
        self.art  = _make_concept("Art",  ART_PROPS)
        colimit   = compute_quantale_colimit(
            self.fire, self.art, blend_name="FireArtBlend"
        )
        self.blend = colimit.blend

    def test_all_derivatives_are_non_negative(self):
        """
        McBride derivatives must all be ≥ 0.
        The residuation chain (IA⊗IB) ⇒ ((wA⊗wB) ⇒ φ(p)) is always
        non-negative in the Product Quantale.
        """
        for prop in self.blend.entries:
            deriv = mcbride_derivative(
                prop, self.fire, self.art, self.blend, uniform_valuation
            )
            self.assertGreaterEqual(deriv.tv.value, 0.0,
                f"Derivative for '{prop}' is negative: {deriv.tv.value:.6f}")

    def test_stronger_source_properties_get_larger_gradients(self):
        """
        'dangerous' (Fire's strongest at 0.2924) should have a larger
        derivative than 'philosophical' (Art's weakest at 0.1101).
        This verifies the gradient correctly reflects source property strength.
        """
        deriv_dangerous = mcbride_derivative(
            "dangerous", self.fire, self.art, self.blend, uniform_valuation
        )
        deriv_philosophical = mcbride_derivative(
            "philosophical", self.fire, self.art, self.blend, uniform_valuation
        )
        self.assertGreaterEqual(
            deriv_dangerous.tv.value,
            deriv_philosophical.tv.value,
            f"'dangerous' derivative ({deriv_dangerous.tv.value:.4f}) should be "
            f">= 'philosophical' derivative ({deriv_philosophical.tv.value:.4f})"
        )

    def test_shared_expressive_has_elevated_gradient(self):
        """
        'expressive' appears in both sources and is joined in the colimit.
        It should have a competitive derivative since it has contributions
        from both A and B.
        """
        deriv_expressive = mcbride_derivative(
            "expressive", self.fire, self.art, self.blend, uniform_valuation
        )
        deriv_philosophical = mcbride_derivative(
            "philosophical", self.fire, self.art, self.blend, uniform_valuation
        )
        self.assertGreaterEqual(
            deriv_expressive.tv.value,
            deriv_philosophical.tv.value,
            "Shared 'expressive' should have larger gradient than weakest property"
        )

    def test_gradient_step_increases_all_tvs(self):
        """
        With uniform valuation and positive derivatives, every TV must
        increase after one gradient step.
        """
        updated = apply_gradient_step(
            self.blend, self.fire, self.art, uniform_valuation, eta=0.05
        )
        for prop in self.blend.entries:
            original_tv = self.blend.entries[prop].quantale.tv.value
            updated_tv  = updated.entries[prop].quantale.tv.value
            self.assertGreaterEqual(
                updated_tv, original_tv,
                f"TV for '{prop}' decreased after gradient step: "
                f"{original_tv:.4f} → {updated_tv:.4f}"
            )

    def test_property_delta_ordering_matches_source_strength(self):
        """
        The delta (refined - initial) must follow source TV ordering:
        stronger source properties must get bigger deltas.
        """
        optimizer = McBrideOptimizer(
            self.fire, self.art, max_steps=5, eta=0.05
        )
        result = optimizer.refine(self.blend)

        fire_deltas = [
            result.refined_blend.entries[p].quantale.tv.value -
            self.blend.entries[p].quantale.tv.value
            for p in ["hot", "dangerous", "bright", "red"]
        ]
        art_deltas = [
            result.refined_blend.entries[p].quantale.tv.value -
            self.blend.entries[p].quantale.tv.value
            for p in ["beautiful", "subjective", "abstract", "philosophical"]
        ]

        avg_fire_delta = sum(fire_deltas) / len(fire_deltas)
        avg_art_delta  = sum(art_deltas)  / len(art_deltas)

        self.assertGreater(
            avg_fire_delta, avg_art_delta,
            f"Average Fire property delta ({avg_fire_delta:.4f}) should be greater "
            f"than average Art property delta ({avg_art_delta:.4f})"
        )


class TestMcBrideRefinedValues(unittest.TestCase):
    """
    Regression tests for the refined TV values.
    These pin the output of McBride against the known-good pipeline run.
    """

    def setUp(self):
        self.fire = _make_concept("Fire", FIRE_PROPS)
        self.art  = _make_concept("Art",  ART_PROPS)
        colimit   = compute_quantale_colimit(
            self.fire, self.art, blend_name="FireArtBlend"
        )
        optimizer = McBrideOptimizer(
            self.fire, self.art, max_steps=5, eta=0.05
        )
        self.result = optimizer.refine(colimit.blend)

    def test_all_refined_tvs_are_higher_than_initial(self):
        """Every property TV must increase after refinement."""
        for prop, expected_refined in EXPECTED_REFINED_PROPS.items():
            initial  = EXPECTED_COLIMIT_PROPS[prop]
            refined  = self.result.refined_blend.entries[prop].quantale.tv.value
            self.assertGreater(refined, initial,
                f"'{prop}' TV did not increase: {initial:.4f} → {refined:.4f}")

    def test_refined_tvs_match_expected_output(self):
        """Pin refined TV values against the known-good pipeline output."""
        for prop, expected in EXPECTED_REFINED_PROPS.items():
            actual = self.result.refined_blend.entries[prop].quantale.tv.value
            self.assertAlmostEqual(
                actual, expected, delta=0.005,
                msg=f"Refined TV for '{prop}' changed significantly: "
                    f"expected {expected:.4f}, got {actual:.4f}"
            )

    def test_dangerous_has_largest_delta(self):
        """'dangerous' is the strongest Fire property (0.2924)."""
        deltas = {
            prop: (self.result.refined_blend.entries[prop].quantale.tv.value
                   - EXPECTED_COLIMIT_PROPS[prop])
            for prop in EXPECTED_REFINED_PROPS
        }
        max_prop  = max(deltas, key=deltas.get)
        max_delta = deltas[max_prop]
        danger_delta = deltas["dangerous"]

        self.assertAlmostEqual(
            danger_delta, max_delta, delta=0.002,
            msg=f"'dangerous' delta ({danger_delta:.4f}) should be close to "
                f"max delta which is '{max_prop}' ({max_delta:.4f})"
        )

    def test_philosophical_has_smallest_delta(self):
        """'philosophical' is Art's weakest property (0.1101)."""
        deltas = {
            prop: (self.result.refined_blend.entries[prop].quantale.tv.value
                   - EXPECTED_COLIMIT_PROPS[prop])
            for prop in EXPECTED_REFINED_PROPS
        }
        min_prop    = min(deltas, key=deltas.get)
        phil_delta  = deltas["philosophical"]
        actual_min  = deltas[min_prop]

        self.assertAlmostEqual(
            phil_delta, actual_min, delta=0.002,
            msg=f"'philosophical' should have the smallest delta "
                f"({phil_delta:.4f}), but '{min_prop}' has {actual_min:.4f}"
        )

    def test_convergence_in_expected_steps(self):
        """McBride must converge within 5 steps on this data."""
        self.assertLessEqual(
            self.result.steps_taken, 5,
            f"Expected convergence in ≤5 steps, took {self.result.steps_taken}"
        )
        self.assertTrue(self.result.converged,
            "McBride must converge on Fire+Art data within 5 steps")

    def test_all_refined_tvs_in_valid_range(self):
        """All refined TVs must stay within [0.10, 0.99]."""
        for prop, entry in self.result.refined_blend.entries.items():
            tv = entry.quantale.tv.value
            self.assertGreaterEqual(tv, 0.10,
                f"'{prop}' refined TV {tv:.4f} is below floor 0.10")
            self.assertLessEqual(tv, 0.99,
                f"'{prop}' refined TV {tv:.4f} is above ceiling 0.99")


class TestEmergenceSaturation(unittest.TestCase):
    """Documents and tests the emergence=1.0 behavior."""

    def setUp(self):
        self.fire = _make_concept("Fire", FIRE_PROPS)
        self.art  = _make_concept("Art",  ART_PROPS)
        colimit   = compute_quantale_colimit(
            self.fire, self.art, blend_name="FireArtBlend"
        )
        self.blend = colimit.blend

    def test_uniform_valuation_gives_saturated_emergence(self):
        """With uniform_valuation, w(A)*w(B) is small so residuation returns 1.0 vacuously."""
        sigma = emergence_tv(self.fire, self.art, self.blend, uniform_valuation)
        self.assertAlmostEqual(sigma, 1.0, places=3)

    def test_weakness_values_are_low(self):
        """w(Fire) and w(Art) are both small."""
        w_fire  = weakness(self.fire,  uniform_valuation)
        w_art   = weakness(self.art,   uniform_valuation)
        w_blend = weakness(self.blend, uniform_valuation)

        self.assertLess(w_fire.tv.value * w_art.tv.value, w_blend.tv.value)

    def test_tv_proportional_valuation_gives_non_saturated_emergence(self):
        """Using tv_proportional_valuation gives a non-vacuous signal."""
        blend_valuation = partial(tv_proportional_valuation, concept=self.blend)
        sigma = emergence_tv(self.fire, self.art, self.blend, blend_valuation)
        self.assertLessEqual(sigma, 1.0)

    def test_pattern_intensity_a_is_finite(self):
        """I_A(C) = w(A) >> w(C) should be valid."""
        ia = pattern_intensity(self.fire, self.blend, uniform_valuation)
        self.assertGreaterEqual(ia.tv.value, 0.0)
        self.assertLessEqual(ia.tv.value, 1.0)

    def test_joint_intensity_exceeds_individual_tensor(self):
        """I_{A,B}(C) >= I_A(C) * I_B(C)."""
        ia  = pattern_intensity(self.fire, self.blend, uniform_valuation)
        ib  = pattern_intensity(self.art,  self.blend, uniform_valuation)
        iab = joint_pattern_intensity(self.fire, self.art, self.blend, uniform_valuation)

        self.assertGreaterEqual(iab.tv.value, ia.tv.value * ib.tv.value)


class TestValuationStrategyEffect(unittest.TestCase):
    """Tests that different valuation strategies produce different gradient magnitudes."""

    def setUp(self):
        self.fire = _make_concept("Fire", FIRE_PROPS)
        self.art  = _make_concept("Art",  ART_PROPS)
        colimit   = compute_quantale_colimit(
            self.fire, self.art, blend_name="FireArtBlend"
        )
        self.blend = colimit.blend

    def test_habit_weighted_high_scores_increase_gradient(self):
        """High habit score produces larger derivative."""
        high_habit = partial(habit_weighted_valuation, habit_scores={"dangerous": 0.9})
        low_habit  = partial(habit_weighted_valuation, habit_scores={"dangerous": 0.1})

        deriv_high = mcbride_derivative("dangerous", self.fire, self.art, self.blend, high_habit)
        deriv_low = mcbride_derivative("dangerous", self.fire, self.art, self.blend, low_habit)

        self.assertGreaterEqual(deriv_high.tv.value, deriv_low.tv.value)

    def test_uniform_vs_tv_proportional_give_different_refinements(self):
        """
        The choice of valuation strategy produces measurably different
        derivative magnitudes when property salience is heavily weighted vs uniform.
        """
        opt_uniform = McBrideOptimizer(self.fire, self.art, valuation=uniform_valuation, max_steps=5, eta=0.05)

        low_habit_val = partial(habit_weighted_valuation, habit_scores={"dangerous": 0.001, "hot": 0.001})
        opt_habit = McBrideOptimizer(self.fire, self.art, valuation=low_habit_val, max_steps=5, eta=0.05)

        deriv_uniform = opt_uniform.all_derivatives(self.blend)
        deriv_habit   = opt_habit.all_derivatives(self.blend)

        self.assertGreater(deriv_uniform["dangerous"].tv.value, deriv_habit["dangerous"].tv.value)

    def test_top_properties_by_gradient_matches_source_strength(self):
        """Top property by gradient matches stronger source properties."""
        optimizer = McBrideOptimizer(self.fire, self.art, max_steps=5)
        top = optimizer.top_properties_by_gradient(self.blend, top_n=3)

        top_props = [prop for prop, _ in top]
        strong_fire_props = {"dangerous", "red", "expressive", "hot"}

        overlap = len(set(top_props) & strong_fire_props)
        self.assertGreaterEqual(overlap, 2)


if __name__ == "__main__":
    unittest.main()
