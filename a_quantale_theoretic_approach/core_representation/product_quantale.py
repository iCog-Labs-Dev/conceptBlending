from __future__ import annotations
from collections.abc import Iterable
from typing import Any

from .quantale_base import QuantaleValue
from .logic_quantale import LogicQuantale
from .truth_value_quantale import TruthValueQuantale
from .world_atom import WorldLike

class ProductQuantale(QuantaleValue):
    """
    Implementation of Q = Q_logic × Q_tv.
    Fuses structural possible-worlds with fuzzy truth values.
    """
    def __init__(self, logic_val: LogicQuantale, tv_val: TruthValueQuantale):
        if not isinstance(logic_val, LogicQuantale):
            raise TypeError("ProductQuantale.logic_val must be a LogicQuantale.")
        if not isinstance(tv_val, TruthValueQuantale):
            raise TypeError("ProductQuantale.tv_val must be a TruthValueQuantale.")
        self.logic = logic_val
        self.tv = tv_val
        super().__init__((self.logic.value, self.tv.value))

    @classmethod
    def from_worlds(
        cls,
        logic_worlds: Iterable[WorldLike],
        truth_value: float,
        universal_set: Iterable[WorldLike],
    ) -> "ProductQuantale":
        return cls(LogicQuantale(logic_worlds, universal_set), TruthValueQuantale(truth_value))

    @classmethod
    def unit(cls, universal_set: Iterable[WorldLike]) -> "ProductQuantale":
        return cls(LogicQuantale.unit(universal_set), TruthValueQuantale.unit())

    @classmethod
    def bottom(cls, universal_set: Iterable[WorldLike]) -> "ProductQuantale":
        return cls(LogicQuantale.bottom(universal_set), TruthValueQuantale.bottom())

    @property
    def universal_set(self):
        return self.logic.universal_set

    def with_universe(self, universal_set: Iterable[WorldLike]) -> "ProductQuantale":
        """Rebuild this product value against a larger compatible logic universe."""
        return ProductQuantale(self.logic.with_universe(universal_set), self.tv)
    
    def _require_compatible(self, other: "ProductQuantale") -> None:
        if not isinstance(other, ProductQuantale):
            raise TypeError(f"Expected ProductQuantale, got {type(other).__name__}.")
        # Ensure they share the exact same structural universe (W)
        if self.logic.universal_set != other.logic.universal_set:
            raise ValueError("ProductQuantale operations require the same logic universe W.")
    
    def tensor(self, other: 'ProductQuantale') -> 'ProductQuantale':
        # Component-wise conjunction (⊗)
        self._require_compatible(other)
        return ProductQuantale(self.logic * other.logic, self.tv * other.tv)

    def join(self, other: 'ProductQuantale') -> 'ProductQuantale':
        # Component-wise disjunction (⊕)
        self._require_compatible(other)
        return ProductQuantale(self.logic + other.logic, self.tv + other.tv)

    def residuation(self, other: 'ProductQuantale') -> 'ProductQuantale':
        # Component-wise implication (⇒)
        self._require_compatible(other)
        return ProductQuantale(self.logic >> other.logic, self.tv >> other.tv)

    def less_eq(self, other: 'ProductQuantale') -> bool:
        # Partial order holds ONLY if it holds for both components
        self._require_compatible(other) 
        return (self.logic <= other.logic) and (self.tv <= other.tv)

    def to_metta(self) -> str:
        """Serialize deterministically into a PeTTa/MeTTa-compatible form."""
        atoms = sorted(self.logic.value, key=lambda atom: atom.sort_key())
        logic_str = " ".join(atom.to_metta_atom() for atom in atoms) if atoms else "EmptyLogic"
        return f"(ProductQuantale ({logic_str}) {self.tv.value:g})"

    def to_worldspec_value_metta(self) -> str:
        """Serialize as the paper-style ``(WorldSpecSet (...)) degree`` pair."""
        atoms = sorted(self.logic.value, key=lambda atom: atom.sort_key())
        worlds = "\n           ".join(atom.to_metta_atom() for atom in atoms)
        if worlds:
            return f"(WorldSpecSet\n          ({worlds}))\n        {self.tv.value:g}"
        return f"(WorldSpecSet ())\n        {self.tv.value:g}"
    
    def __eq__(self, other: Any) -> bool:
        return isinstance(other, ProductQuantale) and self.logic == other.logic and self.tv == other.tv

    def __hash__(self) -> int:
        return hash((ProductQuantale, self.logic, self.tv))
