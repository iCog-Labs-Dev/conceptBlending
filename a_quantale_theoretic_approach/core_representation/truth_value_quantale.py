from __future__ import annotations
import math
from typing import Any
from .quantale_base import QuantaleValue

class TruthValueQuantale(QuantaleValue[float]):
    """
    Implementation of Q_tv: ([0,1], ×, +, 1, ≤)
    Handles the fuzzy, graded property values extracted by the LLM.
    """
    def __init__(self, value: float):
        value = float(value)
        if not math.isfinite(value):
            raise ValueError("TruthValueQuantale value must be finite.")
        if value < 0.0 or value > 1.0:
            raise ValueError("TruthValueQuantale value must be in [0, 1].")
        super().__init__(value)
     
    @classmethod
    def clamped(cls, value: float) -> "TruthValueQuantale":
        """Create a value by intentionally clipping an external score to [0,1]."""
        value = float(value)
        if not math.isfinite(value):
            raise ValueError("Cannot clamp a non-finite truth value.")
        return cls(max(0.0, min(value, 1.0)))

    @classmethod
    def unit(cls) -> "TruthValueQuantale":
        """Monoidal unit e for multiplication (1.0)."""
        return cls(1.0)

    @classmethod
    def bottom(cls) -> "TruthValueQuantale":
        """Bottom/zero value (0.0)."""
        return cls(0.0)

    zero = bottom

    def _require_compatible(self, other: "TruthValueQuantale") -> None:
        """Ensure we don't accidentally multiply a float by a logic set."""
        if not isinstance(other, TruthValueQuantale):
            raise TypeError(f"Expected TruthValueQuantale, got {type(other).__name__}.")
           
    def tensor(self, other: 'TruthValueQuantale') -> 'TruthValueQuantale':
        # ⊗ is standard multiplication for product logic
        self._require_compatible(other)
        return TruthValueQuantale(self.value * other.value)

    def join(self, other: 'TruthValueQuantale') -> 'TruthValueQuantale':
        # Under the standard order on [0, 1], the lattice join is maximum.
        self._require_compatible(other)
        return TruthValueQuantale(max(self.value, other.value))

    def residuation(self, other: 'TruthValueQuantale') -> 'TruthValueQuantale':
        self._require_compatible(other)
        a = self.value
        b = other.value
        if a == 0.0:
            return TruthValueQuantale(1.0)
        return TruthValueQuantale(min(b / a, 1.0))

    def less_eq(self, other: 'TruthValueQuantale') -> bool:
        # ≤ is standard numeric less-than-or-equal
        self._require_compatible(other)
        return self.value <= other.value
    
    def __eq__(self, other: Any) -> bool:
        return isinstance(other, TruthValueQuantale) and math.isclose(
            self.value, other.value, rel_tol=1e-12, abs_tol=1e-12
        )

    def __hash__(self) -> int:
        return hash((TruthValueQuantale, round(self.value, 12)))
