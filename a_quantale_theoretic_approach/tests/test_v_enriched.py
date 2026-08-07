from __future__ import annotations

import unittest

from a_quantale_theoretic_approach.core_representation.product_quantale import ProductQuantale
from a_quantale_theoretic_approach.core_representation.v_enriched import (
    VCocone,
    VCategory,
    VMorphism,
    VProfunctor,
)


UNIVERSE = ("W1", "W2")


def q(worlds=UNIVERSE, degree=1.0):
    return ProductQuantale.from_worlds(worlds, degree, UNIVERSE)


def discrete(name, *objects):
    return VCategory(
        name,
        objects,
        {(obj, obj): ProductQuantale.unit(UNIVERSE) for obj in objects},
        universe=UNIVERSE,
    )


class VCategoryTests(unittest.TestCase):
    def test_valid_enriched_category_and_identity_morphism(self):
        category = VCategory(
            "Chain",
            ("x", "y", "z"),
            {
                ("x", "x"): q(),
                ("y", "y"): q(),
                ("z", "z"): q(),
                ("x", "y"): q(("W1",), 0.8),
                ("y", "z"): q(("W1",), 0.5),
                ("x", "z"): q(("W1",), 0.5),
            },
            universe=UNIVERSE,
        )
        identity = category.identity_morphism()
        self.assertEqual(identity.map_object("y"), "y")

    def test_composition_axiom_is_checked(self):
        with self.assertRaisesRegex(ValueError, "composition axiom"):
            VCategory(
                "BrokenChain",
                ("x", "y", "z"),
                {
                    ("x", "x"): q(),
                    ("y", "y"): q(),
                    ("z", "z"): q(),
                    ("x", "y"): q(("W1",), 0.8),
                    ("y", "z"): q(("W1",), 0.5),
                    ("x", "z"): q(("W1",), 0.3),
                },
                universe=UNIVERSE,
            )

    def test_identity_axiom_is_checked(self):
        with self.assertRaisesRegex(ValueError, "identity axiom"):
            VCategory("NoIdentity", ("x",), {}, universe=UNIVERSE)


class VMorphismAndCoconeTests(unittest.TestCase):
    def test_morphism_preservation_and_composition(self):
        source = VCategory(
            "Source",
            ("a", "b"),
            {("a", "a"): q(), ("b", "b"): q(), ("a", "b"): q(("W1",), 0.5)},
            universe=UNIVERSE,
        )
        middle = VCategory(
            "Middle",
            ("u", "v"),
            {("u", "u"): q(), ("v", "v"): q(), ("u", "v"): q(("W1",), 0.7)},
            universe=UNIVERSE,
        )
        target = discrete("Target", "t")
        first = VMorphism("F", source, middle, {"a": "u", "b": "v"})
        second = VMorphism("G", middle, target, {"u": "t", "v": "t"})
        composite = first.then(second)
        self.assertEqual(dict(composite.object_map), {"a": "t", "b": "t"})

        with self.assertRaisesRegex(ValueError, "does not preserve"):
            VMorphism("Bad", middle, source, {"u": "a", "v": "b"})

    def test_pushout_cocone_checks_commutativity(self):
        generic = discrete("G", "g")
        left = discrete("A", "a")
        right = discrete("B", "b")
        apex = discrete("C", "c", "other")
        sigma_a = VMorphism("sigma_A", generic, left, {"g": "a"})
        sigma_b = VMorphism("sigma_B", generic, right, {"g": "b"})
        i_a = VMorphism("i_A", left, apex, {"a": "c"})
        i_b = VMorphism("i_B", right, apex, {"b": "c"})

        cocone = VCocone(sigma_a, sigma_b, i_a, i_b)
        self.assertTrue(cocone.commutes())
        self.assertIs(cocone.apex, apex)

        bad_i_b = VMorphism("bad_i_B", right, apex, {"b": "other"})
        with self.assertRaisesRegex(ValueError, "does not commute"):
            VCocone(sigma_a, sigma_b, i_a, bad_i_b)


class VProfunctorTests(unittest.TestCase):
    def test_coend_composition_uses_quantale_join(self):
        source = discrete("A", "a")
        middle = discrete("B", "b1", "b2")
        target = discrete("C", "c")
        first = VProfunctor(
            "P",
            source,
            middle,
            {("a", "b1"): q(("W1",), 0.4), ("a", "b2"): q(("W2",), 0.7)},
        )
        second = VProfunctor(
            "Q",
            middle,
            target,
            {("b1", "c"): q(("W1",), 0.9), ("b2", "c"): q(("W2",), 0.5)},
        )

        composite = first.then(second)
        value = composite.value("a", "c")
        self.assertAlmostEqual(value.tv.value, 0.36)
        self.assertEqual({atom.label for atom in value.logic.value}, {"W1", "W2"})

    def test_identity_profunctor_is_composition_identity_for_discrete_category(self):
        source = discrete("A", "a")
        target = discrete("B", "b")
        profunctor = VProfunctor("P", source, target, {("a", "b"): q(("W1",), 0.6)})
        left_identity = VProfunctor.identity(source)
        right_identity = VProfunctor.identity(target)

        self.assertEqual(left_identity.then(profunctor).value("a", "b"), profunctor.value("a", "b"))
        self.assertEqual(profunctor.then(right_identity).value("a", "b"), profunctor.value("a", "b"))

    def test_profunctor_action_laws_are_checked(self):
        source = VCategory(
            "A",
            ("a1", "a2"),
            {("a1", "a1"): q(), ("a2", "a2"): q(), ("a1", "a2"): q(("W1",), 0.8)},
            universe=UNIVERSE,
        )
        target = discrete("B", "b")
        with self.assertRaisesRegex(ValueError, "Left profunctor action"):
            VProfunctor(
                "BrokenP",
                source,
                target,
                {("a2", "b"): q(("W1",), 0.8), ("a1", "b"): q(("W1",), 0.5)},
            )


if __name__ == "__main__":
    unittest.main()
