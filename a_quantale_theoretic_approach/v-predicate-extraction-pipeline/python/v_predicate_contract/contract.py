"""Canonical records shared by ingestion, PeTTa rendering, and PathMap storage.

This module intentionally has no PeTTa or PathMap dependency.  Source adapters produce
these records; storage implementations consume them.
"""

from __future__ import annotations

import math
import re
import hashlib
from abc import ABC, abstractmethod
from dataclasses import dataclass
from enum import Enum
from typing import Sequence, TypeAlias


CONTRACT_VERSION = "v-predicate/1"
_SYMBOL = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


class ContractValidationError(ValueError):
    """Raised when records violate the shared V-predicate contract."""


class FactOrigin(str, Enum):
    ASSERTED = "asserted"
    INFERRED = "inferred"
    GENERATED = "generated"


class FactKind(str, Enum):
    PERSPECTIVE_DEFINITION = "classified_perspective"
    SUBPERSPECTIVE = "subperspective"
    PERSPECTIVE_MATCH = "perspective_match"
    SORT = "has_sort"
    OPERATION = "has_operation"
    OPERATION_SIGNATURE = "operation_signature"
    PREDICATE = "has_predicate"
    PREDICATE_SIGNATURE = "predicate_signature"
    AXIOM = "has_axiom"
    PROPERTY = "has_scoped_property"
    PROPERTY_WORLD = "scoped_property_holds_in"


class Perspective(str, Enum):
    ARTIFACT_KIND = "artifact_kind"
    BEHAVIORAL_PROCESS = "behavioral_process"
    CAUSAL_PREREQUISITE = "causal_prerequisite"
    DESCRIPTIVE_PROPERTY = "descriptive_property"
    ECONOMIC_OWNERSHIP = "economic_ownership"
    EVENT_COMPOSITION = "event_composition"
    FUNCTIONAL_USE = "functional_use"
    INFORMATION_COMPUTATIONAL = "information_computational"
    PHYSICAL_ATTRIBUTE = "physical_attribute"
    PREREQUISITE_ACTION = "prerequisite_action"
    QUANTITATIVE_COMPARATIVE = "quantitative_comparative"
    ROLE_KIND = "role_kind"
    SAFETY_RISK = "safety_risk"
    SOCIAL_NORMATIVE = "social_normative"
    SPATIAL_CONTEXT = "spatial_context"
    STATE_LIFECYCLE = "state_lifecycle"
    STRUCTURAL_COMPOSITION = "structural_composition"
    TAXONOMIC_CLASSIFICATION = "taxonomic_classification"
    TAXONOMIC_KIND = "taxonomic_kind"
    TEMPORAL_CONTEXT = "temporal_context"


PERSPECTIVE_ROLES = {
    Perspective.ARTIFACT_KIND: "artifact_kind_role",
    Perspective.BEHAVIORAL_PROCESS: "behavior_role",
    Perspective.CAUSAL_PREREQUISITE: "causal_precondition_role",
    Perspective.DESCRIPTIVE_PROPERTY: "property_role",
    Perspective.ECONOMIC_OWNERSHIP: "economic_role",
    Perspective.EVENT_COMPOSITION: "process_role",
    Perspective.FUNCTIONAL_USE: "function_role",
    Perspective.INFORMATION_COMPUTATIONAL: "information_role",
    Perspective.PHYSICAL_ATTRIBUTE: "physical_attribute_role",
    Perspective.PREREQUISITE_ACTION: "precondition_role",
    Perspective.QUANTITATIVE_COMPARATIVE: "comparative_role",
    Perspective.ROLE_KIND: "role_kind_role",
    Perspective.SAFETY_RISK: "risk_role",
    Perspective.SOCIAL_NORMATIVE: "social_role",
    Perspective.SPATIAL_CONTEXT: "spatial_role",
    Perspective.STATE_LIFECYCLE: "state_role",
    Perspective.STRUCTURAL_COMPOSITION: "structure_role",
    Perspective.TAXONOMIC_CLASSIFICATION: "ontological_role",
    Perspective.TAXONOMIC_KIND: "kind_role",
    Perspective.TEMPORAL_CONTEXT: "temporal_role",
}


def canonicalize_perspective(value: str | Perspective) -> Perspective:
    """Return a registered perspective, accepting hyphens only as input normalization."""
    if isinstance(value, Perspective):
        return value
    candidate = value.strip().lower().replace("-", "_")
    try:
        return Perspective(candidate)
    except ValueError as error:
        raise ContractValidationError(f"unknown perspective: {value!r}") from error


def stable_evidence_id(prefix: str, *components: str) -> str:
    """Create a deterministic evidence ID without collapsing evidence across sources."""
    _require_symbol(prefix, "prefix")
    if not components or any(not component for component in components):
        raise ContractValidationError("evidence ID components must not be empty")
    payload = "\x1f".join(components).encode("utf-8")
    return f"{prefix}_{hashlib.sha256(payload).hexdigest()[:16]}"


def _require_symbol(value: str, field: str) -> None:
    if not _SYMBOL.fullmatch(value):
        raise ContractValidationError(
            f"{field} must be a canonical MeTTa symbol, received {value!r}"
        )


def _require_expression(value: str, field: str) -> None:
    if not value.startswith("(") or not value.endswith(")"):
        raise ContractValidationError(f"{field} must be a parenthesized MeTTa expression")
    depth = 0
    quoted = False
    escaped = False
    for char in value:
        if quoted:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                quoted = False
            continue
        if char == '"':
            quoted = True
        elif char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth < 0:
                break
    if depth != 0 or quoted:
        raise ContractValidationError(f"{field} is not a balanced MeTTa expression")


def _quote(value: str) -> str:
    escaped = (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
        .replace("\r", "\\r")
        .replace("\t", "\\t")
    )
    return f'"{escaped}"'


@dataclass(frozen=True)
class TruthValue:
    strength: float
    confidence: float

    def __post_init__(self) -> None:
        for name, value in (
            ("strength", self.strength),
            ("confidence", self.confidence),
        ):
            if not math.isfinite(value) or not 0.0 <= value <= 1.0:
                raise ContractValidationError(f"{name} must be finite and in [0, 1]")

    def to_metta(self) -> str:
        return f"(stv {self.strength:.3f} {self.confidence:.3f})"


@dataclass(frozen=True)
class Provenance:
    source: str
    source_record_id: str
    source_uri: str
    source_version: str
    license: str
    transformation: str
    origin: FactOrigin

    def __post_init__(self) -> None:
        _require_symbol(self.source, "source")
        _require_symbol(self.transformation, "transformation")
        for name in (
            "source_record_id",
            "source_uri",
            "source_version",
            "license",
        ):
            if not getattr(self, name).strip():
                raise ContractValidationError(f"{name} must not be empty")

    def expression(self, evidence_id: str) -> str:
        _require_symbol(evidence_id, "evidence_id")
        return (
            f"(evidence_provenance {evidence_id} {self.source} "
            f"{_quote(self.source_record_id)} {_quote(self.source_uri)} "
            f"{_quote(self.source_version)} {_quote(self.license)} "
            f"{self.transformation} {self.origin.value})"
        )


@dataclass(frozen=True)
class VPredicateFact(ABC):
    evidence_id: str
    truth: TruthValue
    provenance: Provenance

    def __post_init__(self) -> None:
        _require_symbol(self.evidence_id, "evidence_id")

    @property
    @abstractmethod
    def kind(self) -> FactKind:
        raise NotImplementedError

    @abstractmethod
    def expression(self) -> str:
        raise NotImplementedError

    def to_metta(self) -> str:
        return f"(: {self.evidence_id} (≞ {self.expression()} {self.truth.to_metta()}))"

    def provenance_to_metta(self) -> str:
        provenance_id = f"{self.evidence_id}_provenance"
        return (
            f"(: {provenance_id} (≞ {self.provenance.expression(self.evidence_id)} "
            "(stv 1.000 1.000)))"
        )

    def to_metta_lines(self, include_provenance: bool = True) -> tuple[str, ...]:
        if include_provenance:
            return self.to_metta(), self.provenance_to_metta()
        return (self.to_metta(),)


@dataclass(frozen=True)
class EdgeFact(VPredicateFact, ABC):
    edge_id: str

    def __post_init__(self) -> None:
        super().__post_init__()
        _require_symbol(self.edge_id, "edge_id")


@dataclass(frozen=True)
class PerspectiveDefinitionFact(VPredicateFact):
    perspective: str | Perspective
    role: str

    def __post_init__(self) -> None:
        super().__post_init__()
        canonical = canonicalize_perspective(self.perspective)
        object.__setattr__(self, "perspective", canonical)
        _require_symbol(self.role, "role")
        if PERSPECTIVE_ROLES[canonical] != self.role:
            raise ContractValidationError(
                f"role {self.role!r} does not match perspective {canonical.value!r}"
            )

    @property
    def kind(self) -> FactKind:
        return FactKind.PERSPECTIVE_DEFINITION

    def expression(self) -> str:
        return f"(classified_perspective {self.perspective.value} {self.role})"


@dataclass(frozen=True)
class SubperspectiveFact(VPredicateFact):
    parent: str | Perspective
    child: str | Perspective

    def __post_init__(self) -> None:
        super().__post_init__()
        object.__setattr__(self, "parent", canonicalize_perspective(self.parent))
        object.__setattr__(self, "child", canonicalize_perspective(self.child))
        if self.parent == self.child:
            raise ContractValidationError("a perspective cannot be its own subperspective")

    @property
    def kind(self) -> FactKind:
        return FactKind.SUBPERSPECTIVE

    def expression(self) -> str:
        return f"(subperspective {self.parent.value} {self.child.value})"


@dataclass(frozen=True)
class PerspectiveMatchFact(VPredicateFact):
    requested: str | Perspective
    effective: str | Perspective
    role: str

    def __post_init__(self) -> None:
        super().__post_init__()
        requested = canonicalize_perspective(self.requested)
        effective = canonicalize_perspective(self.effective)
        object.__setattr__(self, "requested", requested)
        object.__setattr__(self, "effective", effective)
        _require_symbol(self.role, "role")
        if PERSPECTIVE_ROLES[effective] != self.role:
            raise ContractValidationError(
                f"role {self.role!r} does not match effective perspective {effective.value!r}"
            )

    @property
    def kind(self) -> FactKind:
        return FactKind.PERSPECTIVE_MATCH

    def expression(self) -> str:
        return f"(perspective_match {self.requested.value} {self.effective.value} {self.role})"


def _set_perspective(record: object, value: str | Perspective) -> None:
    object.__setattr__(record, "perspective", canonicalize_perspective(value))


def _require_primary_edge_identity(record: EdgeFact) -> None:
    if record.evidence_id != record.edge_id:
        raise ContractValidationError(
            "primary facts must use the same evidence_id and edge_id"
        )


@dataclass(frozen=True)
class SortFact(EdgeFact):
    concept: str
    perspective: str | Perspective
    sort: str

    def __post_init__(self) -> None:
        super().__post_init__()
        _require_primary_edge_identity(self)
        _require_symbol(self.concept, "concept")
        _require_symbol(self.sort, "sort")
        _set_perspective(self, self.perspective)

    @property
    def kind(self) -> FactKind:
        return FactKind.SORT

    def expression(self) -> str:
        return f"(has_sort {self.edge_id} {self.concept} {self.perspective.value} {self.sort})"


@dataclass(frozen=True)
class OperationFact(EdgeFact):
    concept: str
    perspective: str | Perspective
    operation: str

    def __post_init__(self) -> None:
        super().__post_init__()
        _require_primary_edge_identity(self)
        _require_symbol(self.concept, "concept")
        _require_symbol(self.operation, "operation")
        _set_perspective(self, self.perspective)

    @property
    def kind(self) -> FactKind:
        return FactKind.OPERATION

    def expression(self) -> str:
        return (
            f"(has_operation {self.edge_id} {self.concept} "
            f"{self.perspective.value} {self.operation})"
        )


@dataclass(frozen=True)
class OperationSignatureFact(EdgeFact):
    signature: str

    def __post_init__(self) -> None:
        super().__post_init__()
        _require_expression(self.signature, "signature")

    @property
    def kind(self) -> FactKind:
        return FactKind.OPERATION_SIGNATURE

    def expression(self) -> str:
        return f"(operation_signature {self.edge_id} {self.signature})"


@dataclass(frozen=True)
class PredicateFact(EdgeFact):
    concept: str
    perspective: str | Perspective
    predicate: str

    def __post_init__(self) -> None:
        super().__post_init__()
        _require_primary_edge_identity(self)
        _require_symbol(self.concept, "concept")
        _require_expression(self.predicate, "predicate")
        _set_perspective(self, self.perspective)

    @property
    def kind(self) -> FactKind:
        return FactKind.PREDICATE

    def expression(self) -> str:
        return (
            f"(has_predicate {self.edge_id} {self.concept} "
            f"{self.perspective.value} {self.predicate})"
        )


@dataclass(frozen=True)
class PredicateSignatureFact(EdgeFact):
    signature: str

    def __post_init__(self) -> None:
        super().__post_init__()
        _require_expression(self.signature, "signature")

    @property
    def kind(self) -> FactKind:
        return FactKind.PREDICATE_SIGNATURE

    def expression(self) -> str:
        return f"(predicate_signature {self.edge_id} {self.signature})"


@dataclass(frozen=True)
class AxiomFact(EdgeFact):
    concept: str
    perspective: str | Perspective
    axiom: str

    def __post_init__(self) -> None:
        super().__post_init__()
        _require_primary_edge_identity(self)
        _require_symbol(self.concept, "concept")
        _require_expression(self.axiom, "axiom")
        _set_perspective(self, self.perspective)

    @property
    def kind(self) -> FactKind:
        return FactKind.AXIOM

    def expression(self) -> str:
        return (
            f"(has_axiom {self.edge_id} {self.concept} "
            f"{self.perspective.value} {self.axiom})"
        )


@dataclass(frozen=True)
class PropertyFact(EdgeFact):
    concept: str
    perspective: str | Perspective
    property_id: str
    property_name: str

    def __post_init__(self) -> None:
        super().__post_init__()
        _require_primary_edge_identity(self)
        for value, field in (
            (self.concept, "concept"),
            (self.property_id, "property_id"),
            (self.property_name, "property_name"),
        ):
            _require_symbol(value, field)
        _set_perspective(self, self.perspective)

    @property
    def kind(self) -> FactKind:
        return FactKind.PROPERTY

    def expression(self) -> str:
        return (
            f"(has_scoped_property {self.edge_id} {self.concept} "
            f"{self.perspective.value} {self.property_id} {self.property_name})"
        )


@dataclass(frozen=True)
class PropertyWorldFact(EdgeFact):
    property_id: str
    perspective: str | Perspective
    world: str

    def __post_init__(self) -> None:
        super().__post_init__()
        _require_primary_edge_identity(self)
        _require_symbol(self.property_id, "property_id")
        _require_symbol(self.world, "world")
        _set_perspective(self, self.perspective)

    @property
    def kind(self) -> FactKind:
        return FactKind.PROPERTY_WORLD

    def expression(self) -> str:
        return (
            f"(scoped_property_holds_in {self.edge_id} {self.property_id} "
            f"{self.perspective.value} {self.world})"
        )


FactRecord: TypeAlias = (
    PerspectiveDefinitionFact
    | SubperspectiveFact
    | PerspectiveMatchFact
    | SortFact
    | OperationFact
    | OperationSignatureFact
    | PredicateFact
    | PredicateSignatureFact
    | AxiomFact
    | PropertyFact
    | PropertyWorldFact
)


def validate_record_set(records: Sequence[FactRecord]) -> None:
    """Validate references and uniqueness that cannot be checked per record."""
    errors: list[str] = []
    evidence_ids: set[str] = set()
    operation_edges: set[str] = set()
    predicate_edges: set[str] = set()
    property_ids: set[str] = set()

    for record in records:
        if record.evidence_id in evidence_ids:
            errors.append(f"duplicate evidence_id: {record.evidence_id}")
        evidence_ids.add(record.evidence_id)
        if isinstance(record, OperationFact):
            operation_edges.add(record.edge_id)
        elif isinstance(record, PredicateFact):
            predicate_edges.add(record.edge_id)
        elif isinstance(record, PropertyFact):
            property_ids.add(record.property_id)

    for record in records:
        if isinstance(record, OperationSignatureFact) and record.edge_id not in operation_edges:
            errors.append(f"operation signature references missing edge: {record.edge_id}")
        elif isinstance(record, PredicateSignatureFact) and record.edge_id not in predicate_edges:
            errors.append(f"predicate signature references missing edge: {record.edge_id}")
        elif isinstance(record, PropertyWorldFact) and record.property_id not in property_ids:
            errors.append(f"property world references missing property: {record.property_id}")

    if errors:
        raise ContractValidationError("; ".join(errors))


def render_document(
    records: Sequence[FactRecord], *, include_provenance: bool = True
) -> str:
    """Validate and render a deterministic canonical MeTTa document."""
    validate_record_set(records)
    lines = [f"; V-predicate contract: {CONTRACT_VERSION}"]
    for record in records:
        lines.extend(record.to_metta_lines(include_provenance=include_provenance))
    return "\n".join(lines) + "\n"
