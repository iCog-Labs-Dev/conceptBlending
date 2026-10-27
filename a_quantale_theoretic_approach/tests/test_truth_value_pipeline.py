import unittest
import torch
from a_quantale_theoretic_approach.extractor.concept_extractor import ConceptEmbedder
from a_quantale_theoretic_approach.core_representation.truth_value_quantale import TruthValueQuantale

class TestTruthValuePipeline(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Initialize embedder once for all tests to save time
        cls.embedder = ConceptEmbedder(model_name="all-MiniLM-L6-v2") # Use smaller model for faster tests

    def test_ordering_sanity(self):
        """
        Verify that typical truth values satisfy semantic intuition.
        """
        test_cases = [
            ("Fire", "hot", "expensive", "hot should be more central to Fire than expensive"),
            ("Diamond", "expensive", "hot", "expensive should be more central to Diamond than hot"),
            ("Bird", "flies", "swims", "flies should be more central to Bird than swims"),
        ]
        
        for concept, prop_high, prop_low, message in test_cases:
            tv_high = self.embedder.compute_baseline_truth_value(concept, prop_high)
            tv_low = self.embedder.compute_baseline_truth_value(concept, prop_low)
            self.assertGreater(tv_high, tv_low, f"Failed for {concept}: {message} ({tv_high:.3f} vs {tv_low:.3f})")

    def test_quantale_axioms(self):
        """
        Verify that truth values work correctly with Quantale operations.
        (Commutativity, Residuation Adjunction)
        """
        val_a = self.embedder.compute_baseline_truth_value("House", "expensive")
        val_b = self.embedder.compute_baseline_truth_value("House", "safe")
        
        a = TruthValueQuantale(val_a)
        b = TruthValueQuantale(val_b)
        
        # 1. Commutativity of tensorProduct (*)
        # Note: tensor returns a NEW TruthValueQuantale object
        self.assertAlmostEqual((a * b).value, (b * a).value, places=7)
        
        # 2. Residuation Adjunction: (a ⊗ x ≤ b) iff (x ≤ a ⇒ b)
        # Residuation (>>) returns the maximum x
        residual = (a >> b)
        self.assertLessEqual((a * residual).value, b.value + 1e-7)
        
        # 3. Identity and Bounds
        zero = TruthValueQuantale(0.0)
        one = TruthValueQuantale(1.0)
        self.assertAlmostEqual((a * one).value, a.value, places=7)
        self.assertAlmostEqual((a * zero).value, 0.0, places=7)

    def test_reproducibility(self):
        """
        Verify that the same input produces exactly the same truth value.
        """
        concept = "Justice"
        prop = "fair"
        
        val1 = self.embedder.compute_baseline_truth_value(concept, prop)
        val2 = self.embedder.compute_baseline_truth_value(concept, prop)
        
        self.assertEqual(val1, val2)

if __name__ == "__main__":
    unittest.main()
