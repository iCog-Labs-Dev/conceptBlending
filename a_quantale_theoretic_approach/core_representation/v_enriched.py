"""Explicit structures for categories enriched over ``ProductQuantale``.

The classes in this module provide the typed categorical layer needed by the
paper's colimit conditions.  They deliberately stop at cocone validation; the
universal mediating-property checker belongs to the later colimit-verification
step once generic-space morphisms are integrated.
"""

from __future__ import annotations

from collections.abc import Hashable, Iterable, Mapping
from dataclasses import dataclass
from types import MappingProxyType
from typing import TypeAlias

from .product_quantale import ProductQuantale
from .world_atom import WorldAtom, WorldLike, coerce_world_atom


VObject: TypeAlias = Hashable
HomKey: TypeAlias = tuple[VObject, VObject]


def _q_leq(left: ProductQuantale, right: ProductQuantale, *, tolerance: float) -> bool:
    """Product order with a small tolerance on the floating-point component."""
    left._require_compatible(right)
    return left.logic.value.issubset(right.logic.value) and left.tv.value <= right.tv.value + tolerance


class VCategory:
    """A small category enriched over the repository's product quantale.

    Missing Hom entries are interpreted as bottom.  Construction validates the
    enriched identity and composition axioms unless ``validate=False`` is used.
    """

    def __init__(
        self,
        name: str,
        objects: Iterable[VObject],
        homs: Mapping[HomKey, ProductQuantale],
        *,
        universe: Iterable[WorldLike],
        validate: bool = True,
        tolerance: float = 1e-12,
    ) -> None:
        if not str(name).strip():
            raise ValueError("VCategory.name must be non-empty.")
        object_tuple = tuple(objects)
        if len(set(object_tuple)) != len(object_tuple):
            raise ValueError("VCategory objects must be unique and hashable.")

        self.name = str(name).strip()
        self.objects = object_tuple
        self.object_set = frozenset(object_tuple)
        self.universe = frozenset(coerce_world_atom(item) for item in universe)
        self.tolerance = float(tolerance)

        copied_homs: dict[HomKey, ProductQuantale] = {}
        for key, value in homs.items():
            if not isinstance(key, tuple) or len(key) != 2:
                raise TypeError("VCategory Hom keys must be (source, target) pairs.")
            source, target = key
            if source not in self.object_set or target not in self.object_set:
                raise ValueError(f"Hom endpoint {key!r} is not an object of {self.name!r}.")
            if not isinstance(value, ProductQuantale):
                raise TypeError("VCategory Hom values must be ProductQuantale instances.")
            if value.universal_set != self.universe:
                raise ValueError("Every Hom value must use the VCategory universe.")
            copied_homs[key] = value
        self._homs = MappingProxyType(copied_homs)

        if validate:
            self.validate_axioms()

    @property
    def homs(self) -> Mapping[HomKey, ProductQuantale]:
        return self._homs

    def hom(self, source: VObject, target: VObject) -> ProductQuantale:
        if source not in self.object_set or target not in self.object_set:
            raise KeyError(f"Unknown Hom endpoint ({source!r}, {target!r}) in {self.name!r}.")
        return self._homs.get((source, target), ProductQuantale.bottom(self.universe))

    def validate_axioms(self) -> None:
        unit = ProductQuantale.unit(self.universe)
        for obj in self.objects:
            if not _q_leq(unit, self.hom(obj, obj), tolerance=self.tolerance):
                raise ValueError(f"Enriched identity axiom failed for {self.name}.{obj!r}.")

        for source in self.objects:
            for middle in self.objects:
                for target in self.objects:
                    composite_bound = self.hom(middle, target) * self.hom(source, middle)
                    if not _q_leq(
                        composite_bound,
                        self.hom(source, target),
                        tolerance=self.tolerance,
                    ):
                        raise ValueError(
                            "Enriched composition axiom failed for "
                            f"{source!r} -> {middle!r} -> {target!r} in {self.name!r}."
                        )

    def identity_morphism(self, *, name: str | None = None) -> "VMorphism":
        return VMorphism(name or f"id_{self.name}", self, self, {obj: obj for obj in self.objects})

    def __repr__(self) -> str:
        return f"VCategory(name={self.name!r}, objects={self.objects!r})"


class VMorphism:
    """A V-functor represented by its total map on objects."""

    def __init__(
        self,
        name: str,
        source: VCategory,
        target: VCategory,
        object_map: Mapping[VObject, VObject],
        *,
        validate: bool = True,
    ) -> None:
        if not str(name).strip():
            raise ValueError("VMorphism.name must be non-empty.")
        if source.universe != target.universe:
            raise ValueError("A VMorphism requires source and target to share one quantale universe.")

        copied_map = dict(object_map)
        missing = source.object_set.difference(copied_map)
        extra = set(copied_map).difference(source.object_set)
        if missing or extra:
            raise ValueError(f"VMorphism object map must be total and exact; missing={missing}, extra={extra}.")
        invalid_targets = {value for value in copied_map.values() if value not in target.object_set}
        if invalid_targets:
            raise ValueError(f"VMorphism maps to unknown target objects: {invalid_targets}.")

        self.name = str(name).strip()
        self.source = source
        self.target = target
        self._object_map = MappingProxyType(copied_map)
        if validate:
            self.validate_enrichment()

    @property
    def object_map(self) -> Mapping[VObject, VObject]:
        return self._object_map

    def map_object(self, obj: VObject) -> VObject:
        return self._object_map[obj]

    def validate_enrichment(self) -> None:
        for source_obj in self.source.objects:
            for target_obj in self.source.objects:
                source_hom = self.source.hom(source_obj, target_obj)
                target_hom = self.target.hom(
                    self.map_object(source_obj),
                    self.map_object(target_obj),
                )
                if not _q_leq(source_hom, target_hom, tolerance=self.source.tolerance):
                    raise ValueError(
                        f"VMorphism {self.name!r} does not preserve Hom({source_obj!r}, {target_obj!r})."
                    )

    def compose(self, after: "VMorphism", *, name: str | None = None) -> "VMorphism":
        """Return ``after ∘ self``."""
        if self.target is not after.source:
            raise ValueError("VMorphism composition requires self.target to be after.source.")
        composed_map = {
            obj: after.map_object(self.map_object(obj))
            for obj in self.source.objects
        }
        return VMorphism(name or f"{after.name}_after_{self.name}", self.source, after.target, composed_map)

    def then(self, after: "VMorphism", *, name: str | None = None) -> "VMorphism":
        return self.compose(after, name=name)

    def same_mapping_as(self, other: "VMorphism") -> bool:
        return (
            self.source is other.source
            and self.target is other.target
            and dict(self.object_map) == dict(other.object_map)
        )

    def __repr__(self) -> str:
        return f"VMorphism(name={self.name!r}, source={self.source.name!r}, target={self.target.name!r})"


@dataclass(frozen=True)
class VCocone:
    """A checked cocone over the pushout span ``A <- G -> B``."""

    generic_to_left: VMorphism
    generic_to_right: VMorphism
    left_to_apex: VMorphism
    right_to_apex: VMorphism
    name: str = "pushout_cocone"

    def __post_init__(self) -> None:
        if self.generic_to_left.source is not self.generic_to_right.source:
            raise ValueError("Cocone span legs must share the same generic-space source.")
        if self.generic_to_left.target is not self.left_to_apex.source:
            raise ValueError("The left span target must equal the left cocone-leg source.")
        if self.generic_to_right.target is not self.right_to_apex.source:
            raise ValueError("The right span target must equal the right cocone-leg source.")
        if self.left_to_apex.target is not self.right_to_apex.target:
            raise ValueError("Cocone legs must share an apex category.")
        if not self.commutes():
            raise ValueError("Cocone does not commute: i_A ∘ sigma_A != i_B ∘ sigma_B.")

    @property
    def generic(self) -> VCategory:
        return self.generic_to_left.source

    @property
    def left(self) -> VCategory:
        return self.generic_to_left.target

    @property
    def right(self) -> VCategory:
        return self.generic_to_right.target

    @property
    def apex(self) -> VCategory:
        return self.left_to_apex.target

    def commutes(self) -> bool:
        left_composite = self.generic_to_left.then(self.left_to_apex)
        right_composite = self.generic_to_right.then(self.right_to_apex)
        return left_composite.same_mapping_as(right_composite)


class VProfunctor:
    """A small Q-valued profunctor ``source^op ⊗ target -> Q``."""

    def __init__(
        self,
        name: str,
        source: VCategory,
        target: VCategory,
        values: Mapping[HomKey, ProductQuantale],
        *,
        validate: bool = True,
    ) -> None:
        if not str(name).strip():
            raise ValueError("VProfunctor.name must be non-empty.")
        if source.universe != target.universe:
            raise ValueError("A VProfunctor requires source and target to share one quantale universe.")

        copied_values: dict[HomKey, ProductQuantale] = {}
        for (source_obj, target_obj), value in values.items():
            if source_obj not in source.object_set or target_obj not in target.object_set:
                raise ValueError(f"Unknown profunctor endpoint ({source_obj!r}, {target_obj!r}).")
            if not isinstance(value, ProductQuantale):
                raise TypeError("VProfunctor values must be ProductQuantale instances.")
            if value.universal_set != source.universe:
                raise ValueError("Every VProfunctor value must use the shared universe.")
            copied_values[(source_obj, target_obj)] = value

        self.name = str(name).strip()
        self.source = source
        self.target = target
        self._values = MappingProxyType(copied_values)
        if validate:
            self.validate_actions()

    @property
    def values(self) -> Mapping[HomKey, ProductQuantale]:
        return self._values

    def value(self, source_obj: VObject, target_obj: VObject) -> ProductQuantale:
        if source_obj not in self.source.object_set or target_obj not in self.target.object_set:
            raise KeyError(f"Unknown profunctor endpoint ({source_obj!r}, {target_obj!r}).")
        return self._values.get((source_obj, target_obj), ProductQuantale.bottom(self.source.universe))

    def validate_actions(self) -> None:
        tolerance = max(self.source.tolerance, self.target.tolerance)
        for source_prime in self.source.objects:
            for source_obj in self.source.objects:
                for target_obj in self.target.objects:
                    left_action = self.source.hom(source_prime, source_obj) * self.value(source_obj, target_obj)
                    if not _q_leq(left_action, self.value(source_prime, target_obj), tolerance=tolerance):
                        raise ValueError(
                            f"Left profunctor action failed at ({source_prime!r}, {source_obj!r}, {target_obj!r})."
                        )

        for source_obj in self.source.objects:
            for target_obj in self.target.objects:
                for target_prime in self.target.objects:
                    right_action = self.value(source_obj, target_obj) * self.target.hom(target_obj, target_prime)
                    if not _q_leq(right_action, self.value(source_obj, target_prime), tolerance=tolerance):
                        raise ValueError(
                            f"Right profunctor action failed at ({source_obj!r}, {target_obj!r}, {target_prime!r})."
                        )

    def compose(self, after: "VProfunctor", *, name: str | None = None) -> "VProfunctor":
        """Compose by the enriched coend: ``(after ∘ self)(a,c) = ⊕_b self(a,b)⊗after(b,c)``."""
        if self.target is not after.source:
            raise ValueError("VProfunctor composition requires self.target to be after.source.")

        composed: dict[HomKey, ProductQuantale] = {}
        for source_obj in self.source.objects:
            for target_obj in after.target.objects:
                aggregate = ProductQuantale.bottom(self.source.universe)
                for middle_obj in self.target.objects:
                    aggregate = aggregate + (
                        self.value(source_obj, middle_obj) * after.value(middle_obj, target_obj)
                    )
                composed[(source_obj, target_obj)] = aggregate
        return VProfunctor(
            name or f"{after.name}_after_{self.name}",
            self.source,
            after.target,
            composed,
        )

    def then(self, after: "VProfunctor", *, name: str | None = None) -> "VProfunctor":
        return self.compose(after, name=name)

    @classmethod
    def identity(cls, category: VCategory, *, name: str | None = None) -> "VProfunctor":
        values = {
            (source, target): category.hom(source, target)
            for source in category.objects
            for target in category.objects
        }
        return cls(name or f"Hom_{category.name}", category, category, values)

    def __repr__(self) -> str:
        return f"VProfunctor(name={self.name!r}, source={self.source.name!r}, target={self.target.name!r})"
