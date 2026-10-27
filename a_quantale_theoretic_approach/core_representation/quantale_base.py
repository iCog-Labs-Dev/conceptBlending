from abc import ABC, abstractmethod
from typing import TypeVar, Generic

T = TypeVar('T')

class QuantaleValue(ABC, Generic[T]):
    """
    Abstract Base Class for a Commutative Quantale.
    Enforces the mathematical operations required by the V-Predicate framework.
    """
    def __init__(self, value: T):
        self.value = value

    @abstractmethod
    def tensor(self, other: 'QuantaleValue') -> 'QuantaleValue':
        """The monoidal product (⊗). Represents conjunction."""
        pass

    @abstractmethod
    def join(self, other: 'QuantaleValue') -> 'QuantaleValue':
        """The supremum/join (⊕). Represents disjunction."""
        pass

    @abstractmethod
    def residuation(self, other: 'QuantaleValue') -> 'QuantaleValue':
        """The implication (⇒). The maximum 'x' such that (self ⊗ x) ≤ other."""
        pass
        
    @abstractmethod
    def less_eq(self, other: 'QuantaleValue') -> bool:
        """The partial order (≤). Checks subsumption."""
        pass

    # Python Magic Methods to allow natural mathematical syntax in our optimization loops
    def __mul__(self, other): return self.tensor(other)
    def __add__(self, other): return self.join(other)
    def __rshift__(self, other): return self.residuation(other)
    def __le__(self, other): return self.less_eq(other)
    
    def __repr__(self):
        return f"{self.__class__.__name__}({self.value})"
