from typing import Any, FrozenSet
from collections.abc import Iterable
from .quantale_base import QuantaleValue
from .world_atom import WorldAtom, WorldLike, coerce_world_atom

class LogicQuantale(QuantaleValue[FrozenSet[WorldAtom]]):
    """
    Implementation of Q_logic: (P(W), ∩, ∪, W, ⊆)
    Handles the strict relational and topology-preserving structural information.
    """
    def __init__(self, value: Iterable[WorldLike], universal_set: Iterable[WorldLike]):
        # 1. Reject missing universes
        if universal_set is None:
            raise ValueError("LogicQuantale requires an explicit universal_set W.")

        # 2. Coerce to typed atoms and lock immutability
        universe = frozenset(coerce_world_atom(item) for item in universal_set)
        subset = frozenset(coerce_world_atom(item) for item in value)

        # 3. Validate that the logic is actually a subset of the known universe W
        if not subset.issubset(universe):
            missing = sorted((atom.label for atom in subset - universe))
            raise ValueError(
                "LogicQuantale value must be a subset of universal_set W. "
                f"Missing from W: {missing}"
            )

        self.universal_set: FrozenSet[WorldAtom] = universe
        super().__init__(subset)

    @classmethod
    def unit(cls, universal_set: Iterable[WorldLike]) -> "LogicQuantale":
        """Monoidal unit/top element W for intersection."""
        return cls(universal_set, universal_set)

    @classmethod
    def bottom(cls, universal_set: Iterable[WorldLike]) -> "LogicQuantale":
        """Bottom element, the empty set."""
        return cls((), universal_set)

    zero = bottom

    def with_universe(self, universal_set: Iterable[WorldLike]) -> "LogicQuantale":
        """Rebuild this value against a larger compatible universe."""
        return LogicQuantale(self.value, universal_set)

    def _require_compatible(self, other: 'LogicQuantale') -> None:
        if not isinstance(other, LogicQuantale):
            raise TypeError(f"Expected LogicQuantale, got {type(other).__name__}.")
        if self.universal_set != other.universal_set:
            raise ValueError("LogicQuantale operations require the same universe W.")
    def tensor(self, other: 'LogicQuantale') -> 'LogicQuantale':
        # ⊗ is set intersection (∩)
        self._require_compatible(other)
        return LogicQuantale(self.value.intersection(other.value), self.universal_set)

    def join(self, other: 'LogicQuantale') -> 'LogicQuantale':
        # ⊕ is set union (∪)
        self._require_compatible(other)
        return LogicQuantale(self.value.union(other.value), self.universal_set)

    def residuation(self, other: 'LogicQuantale') -> 'LogicQuantale':
        # ⇒ directly implements: B ∪ ~A
        # ~A is the complement of A relative to the universal set W
        self._require_compatible(other)
        not_a = self.universal_set.difference(self.value)
        return LogicQuantale(other.value.union(not_a), self.universal_set)

    def less_eq(self, other: 'LogicQuantale') -> bool:
        # ≤ is subset relation (⊆)
        self._require_compatible(other)
        return self.value.issubset(other.value)

    def __eq__(self, other: Any) -> bool:
        return (
            isinstance(other, LogicQuantale)
            and self.value == other.value
            and self.universal_set == other.universal_set
        )

    def __hash__(self) -> int:
        return hash((LogicQuantale, self.value, self.universal_set))
