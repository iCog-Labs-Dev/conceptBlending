from __future__ import annotations

import itertools
import unittest

from a_quantale_theoretic_approach.core_representation.product_quantale import ProductQuantale
from a_quantale_theoretic_approach.core_representation.truth_value_quantale import TruthValueQuantale


class TruthValueQuantaleLawTests(unittest.TestCase):
    VALUES = tuple(TruthValueQuantale(value) for value in (0.0, 0.2, 0.5, 0.8, 1.0))

    def test_join_is_lattice_maximum(self):
        for left, right in itertools.product(self.VALUES, repeat=2):
            joined = left + right
            self.assertEqual(joined.value, max(left.value, right.value))
            self.assertTrue(left <= joined)
            self.assertTrue(right <= joined)
            for upper_bound in self.VALUES:
                if left <= upper_bound and right <= upper_bound:
                    self.assertTrue(joined <= upper_bound)

    def test_join_is_commutative_associative_and_idempotent(self):
        for a, b, c in itertools.product(self.VALUES, repeat=3):
            self.assertEqual(a + b, b + a)
            self.assertEqual((a + b) + c, a + (b + c))
            self.assertEqual(a + a, a)

    def test_tensor_is_commutative_associative_and_unital(self):
        unit = TruthValueQuantale.unit()
        for a, b, c in itertools.product(self.VALUES, repeat=3):
            self.assertEqual(a * b, b * a)
            self.assertEqual((a * b) * c, a * (b * c))
            self.assertEqual(a * unit, a)

    def test_tensor_distributes_over_join(self):
        for a, b, c in itertools.product(self.VALUES, repeat=3):
            self.assertEqual(a * (b + c), (a * b) + (a * c))

    def test_residuation_adjunction_in_both_directions(self):
        for a, x, b in itertools.product(self.VALUES, repeat=3):
            self.assertEqual((a * x) <= b, x <= (a >> b))


class ProductQuantaleLawTests(unittest.TestCase):
    UNIVERSE = ("W1", "W2")

    @classmethod
    def q(cls, worlds, degree):
        return ProductQuantale.from_worlds(worlds, degree, cls.UNIVERSE)

    def test_product_distributivity(self):
        a = self.q(("W1",), 0.5)
        b = self.q(("W1", "W2"), 0.8)
        c = self.q(("W2",), 0.3)
        self.assertEqual(a * (b + c), (a * b) + (a * c))

    def test_product_residuation_adjunction(self):
        values = (
            self.q((), 0.0),
            self.q(("W1",), 0.3),
            self.q(("W2",), 0.6),
            self.q(("W1", "W2"), 1.0),
        )
        for a, x, b in itertools.product(values, repeat=3):
            self.assertEqual((a * x) <= b, x <= (a >> b))


if __name__ == "__main__":
    unittest.main()
