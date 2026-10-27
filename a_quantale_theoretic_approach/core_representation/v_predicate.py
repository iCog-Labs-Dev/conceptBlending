"""V-predicate concept representation m_A : Props -> Q."""

from __future__ import annotations

from collections.abc import Callable, Mapping
from dataclasses import dataclass
from types import MappingProxyType

from .product_quantale import ProductQuantale
from .world_atom import WorldLike, coerce_world_atom, metta_atom

@dataclass(frozen=True)
class VPredicateEntry:
    """One property-level V-predicate entry with lightweight provenance."""

    property_name: str
    quantale: ProductQuantale
    source: str | None = None
    extraction_method: str | None = None
    confidence: float | None = None

    def __post_init__(self) -> None:
        if not isinstance(self.property_name, str) or not self.property_name.strip():
            raise ValueError("property_name must be a non-empty string.")
        if not isinstance(self.quantale, ProductQuantale):
            raise TypeError("quantale must be a ProductQuantale.")
        if self.confidence is not None and not (0.0 <= float(self.confidence) <= 1.0):
            raise ValueError("confidence must be in [0,1] when provided.")

class VPredicateConcept:
    """A concept represented as a V-predicate m_A : Props -> Q.

    The object deliberately stores product-quantale values, not raw floats.  This
    preserves the paper's intended unification: structural/possible-world
    semantics and graded truth values remain coupled at every property.
    """

    def __init__(self, concept_name: str, universal_set: list[WorldLike] | set[WorldLike] | tuple[WorldLike, ...] | None = None):
        if not isinstance(concept_name, str) or not concept_name.strip():
            raise ValueError("concept_name must be a non-empty string.")
        self.name = concept_name.strip()
        self._entries: dict[str, VPredicateEntry] = {}
        self._universal_set = (
            frozenset(coerce_world_atom(item) for item in universal_set)
            if universal_set is not None
            else None
        )

    @property
    def entries(self) -> Mapping[str, VPredicateEntry]:
        """Read-only view of the full entries including provenance."""
        return MappingProxyType(self._entries)

    @property
    def properties(self) -> Mapping[str, ProductQuantale]:
        """Read-only property -> ProductQuantale view."""
        return MappingProxyType({name: entry.quantale for name, entry in self._entries.items()})

    def add_property(
        self,
        property_name: str,
        quantale: ProductQuantale,
        *,
        source: str | None = None,
        extraction_method: str | None = None,
        confidence: float | None = None,
        overwrite: bool = False,
    ) -> None:
        property_name = property_name.strip()
        if property_name in self._entries and not overwrite:
            raise ValueError(
                f"Property {property_name!r} already exists for concept {self.name!r}. "
                "Pass overwrite=True to replace it intentionally."
            )
        if self._universal_set is None:
            self._universal_set = quantale.universal_set
        elif quantale.universal_set != self._universal_set:
            raise ValueError("Property quantale must share the concept's universal_set W.")
        entry = VPredicateEntry(
            property_name=property_name,
            quantale=quantale,
            source=source,
            extraction_method=extraction_method,
            confidence=confidence,
        )
        self._entries[property_name] = entry
        self.validate_same_universe()

    def get_property(self, property_name: str) -> ProductQuantale:
        """Helper to quickly retrieve a specific quantale."""
        return self._entries[property_name].quantale

    def validate_same_universe(self) -> None:
        """Ensure all property values live in the same Q_logic universe W."""
        universes = {entry.quantale.logic.universal_set for entry in self._entries.values()}
        if self._universal_set is not None:
            universes.add(self._universal_set)
        if len(universes) > 1:
            raise ValueError("All V-predicate properties for one concept must share the same universe W.")

    @property
    def universal_set(self):
        """Returns the shared logical universe for this concept, if any properties exist."""
        if self._universal_set is not None:
            return self._universal_set
        if not self._entries:
            return frozenset()
        return next(iter(self._entries.values())).quantale.logic.universal_set

    def weakness(
        self,
        valuation: Mapping[str, ProductQuantale] | Callable[[str], ProductQuantale],
    ) -> ProductQuantale:
        """Compute w(A) = ⊕_p φ(p) ⊗ m_A(p).
            V-predicate structure is really quantale-valued rather than a
        plain fuzzy property vector.
        """
        if not self._entries:
            raise ValueError("Cannot compute weakness for a concept with no properties; W is unknown.")

        aggregate: ProductQuantale | None = None
        for prop_name in sorted(self._entries):
            entry = self._entries[prop_name]
            phi = valuation(prop_name) if callable(valuation) else valuation[prop_name]
            if not isinstance(phi, ProductQuantale):
                raise TypeError("Valuation must return ProductQuantale values.")
            
            # This triggers the `__mul__` and `__add__` magic methods
            term = phi * entry.quantale
            aggregate = term if aggregate is None else aggregate + term
            
        assert aggregate is not None
        return aggregate

    def to_metta_assertions(self) -> list[str]:
        """Generate deterministic assertions for loading into PeTTa."""
        assertions = []
        for prop in sorted(self._entries):
            quantale = self._entries[prop].quantale
            assertions.append(
                f"(= (VPredicate {metta_atom(self.name)} {metta_atom(prop)}) {quantale.to_metta()})"
            )
        return assertions

    def to_metta(self) -> str:
        """Serialize in the paper-style V-predicate concept form."""
        property_blocks = []
        for prop in sorted(self._entries):
            quantale = self._entries[prop].quantale
            property_blocks.append(
                f"      ({metta_atom(prop)}\n"
                f"        {quantale.to_worldspec_value_metta()})"
            )
        body = "\n\n".join(property_blocks)
        if not body:
            body = "      ; empty V-predicate"
        return (
            f"(Concept {metta_atom(self.name)}\n"
            "  (V-predicate\n"
            "    (Property\n\n"
            f"{body})))"
        )

    def __repr__(self) -> str:
        return f"VPredicateConcept(name={self.name!r}, properties={list(self._entries)!r})"
