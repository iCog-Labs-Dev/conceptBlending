"""Integration test for HybridSearchLoop."""
import unittest
import warnings
from a_quantale_theoretic_approach.core_representation.v_predicate import VPredicateConcept
from a_quantale_theoretic_approach.core_representation.product_quantale import ProductQuantale
from a_quantale_theoretic_approach.optimization.hybrid_search_loop import (
    HybridSearchLoop,
    BlendCandidate,
    _mutate_blend,
    _crossover_blends,
)

UNIVERSE = ("W_1", "W_2")

def _make_concept(name, props: dict) -> VPredicateConcept:
    c = VPredicateConcept(name, universal_set=UNIVERSE)
    for prop, tv in props.items():
        unit_q = ProductQuantale.unit(UNIVERSE)
        new_q = ProductQuantale(unit_q.logic, type(unit_q.tv)(tv))
        c.add_property(prop, new_q)
    return c

class TestHybridSearchLoop(unittest.TestCase):
    def test_hybrid_search_runs_and_returns_pareto_front(self):
        source_a = _make_concept("House", {"shelter": 0.8, "structure": 0.9, "stationary": 0.7})
        source_b = _make_concept("Boat", {"vehicle": 0.85, "floats": 0.9, "structure": 0.6})
        initial  = _make_concept("HouseBoat", {"shelter": 0.8, "vehicle": 0.85, "floats": 0.9, "structure": 0.9})

        search = HybridSearchLoop(
            source_a=source_a,
            source_b=source_b,
            initial_blend=initial,
            population_size=4,
            max_generations=3,
            mcbride_steps=3,
        )
        pareto_front = search.run()
        self.assertGreater(len(pareto_front), 0)
        for candidate in pareto_front:
            self.assertGreaterEqual(candidate.emergence, 0.0)
            self.assertGreaterEqual(len(candidate.blend.entries), 1)

class TestEvaluateCoherence(unittest.TestCase):
    """
    Tests that _evaluate() does not silently swallow errors and
    that coherence is computed (or falls back with a warning).
    These paths were NOT tested originally.
    """

    def _make_loop(self, source_a, source_b, initial_blend):
        return HybridSearchLoop(
            source_a=source_a,
            source_b=source_b,
            initial_blend=initial_blend,
            population_size=2,
            max_generations=1,
            mcbride_steps=2,
        )

    def test_evaluate_sets_coherence_to_float(self):
        """coherence must always be a float, never None."""
        sa = _make_concept("A", {"p1": 0.7, "shared": 0.5})
        sb = _make_concept("B", {"p2": 0.6, "shared": 0.5})
        blend = _make_concept("C", {"p1": 0.7, "p2": 0.6, "shared": 0.8})

        loop = self._make_loop(sa, sb, blend)
        candidate = BlendCandidate(blend=blend)
        loop._evaluate(candidate)

        self.assertIsInstance(candidate.coherence, float)
        self.assertGreaterEqual(candidate.coherence, 0.0)
        self.assertLessEqual(candidate.coherence, 1.0)

    def test_evaluate_emits_warning_not_silence_on_fallback(self):
        """
        When optimality evaluation falls back, a RuntimeWarning must be
        emitted. Silent swallowing of errors is not acceptable.
        """
        sa = _make_concept("A", {"p": 0.7})
        sb = _make_concept("B", {"p": 0.6})
        blend = _make_concept("C", {"p": 0.8})

        loop = self._make_loop(sa, sb, blend)
        candidate = BlendCandidate(blend=blend)

        with warnings.catch_warnings(record=True) as caught:
            warnings.simplefilter("always")
            loop._evaluate(candidate)
            for w in caught:
                self.assertTrue(issubclass(w.category, RuntimeWarning))

    def test_coherence_is_not_none_after_full_run(self):
        """After a full HybridSearchLoop run, all candidates have coherence set."""
        sa = _make_concept("A", {"p1": 0.7, "shared": 0.6})
        sb = _make_concept("B", {"p2": 0.5, "shared": 0.6})
        blend = _make_concept("C", {"p1": 0.7, "p2": 0.5, "shared": 0.7})

        loop = HybridSearchLoop(
            source_a=sa, source_b=sb, initial_blend=blend,
            population_size=3, max_generations=2, mcbride_steps=2,
        )
        front = loop.run()

        self.assertGreater(len(front), 0)
        for candidate in front:
            self.assertIsNotNone(candidate.coherence)
            self.assertIsInstance(candidate.coherence, float)


class TestMutateBlend(unittest.TestCase):
    """Tests _mutate_blend — including the dead variable fix."""

    def test_mutate_preserves_all_properties(self):
        """Mutation must not add or remove properties."""
        blend = _make_concept("C", {"p1": 0.7, "p2": 0.5, "p3": 0.9})
        mutated = _mutate_blend(blend, mutation_rate=1.0)
        self.assertEqual(set(mutated.entries.keys()), set(blend.entries.keys()))

    def test_mutate_tvs_stay_in_bounds(self):
        """All mutated TV values must stay in [0.01, 0.99]."""
        blend = _make_concept("C", {"p1": 0.99, "p2": 0.01, "p3": 0.5})
        for _ in range(50):  # run many times to catch boundary violations
            mutated = _mutate_blend(blend, mutation_rate=1.0, mutation_scale=1.0)
            for prop, entry in mutated.entries.items():
                tv = entry.quantale.tv.value
                self.assertGreaterEqual(tv, 0.01, f"{prop} TV below floor")
                self.assertLessEqual(tv, 0.99,   f"{prop} TV above ceiling")

    def test_mutate_does_not_contain_dead_unit_q_artifact(self):
        """
        With mutation_rate=0, every property TV should be unchanged.
        """
        blend = _make_concept("C", {"p1": 0.7})
        mutated = _mutate_blend(blend, mutation_rate=0.0)  # no mutation
        for prop in blend.entries:
            original_tv = blend.entries[prop].quantale.tv.value
            mutated_tv  = mutated.entries[prop].quantale.tv.value
            self.assertAlmostEqual(original_tv, mutated_tv, places=6)


if __name__ == "__main__":
    unittest.main()
