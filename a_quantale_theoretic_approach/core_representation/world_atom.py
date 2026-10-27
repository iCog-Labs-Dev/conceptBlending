"""Typed atoms for the logic/possible-world component of the product quantale.

The quantale paper uses Q_logic = (P(W), intersection, union, W, subset),
so every logic value must be a subset of a fixed universe W.  In early
prototypes these elements are often strings.  This module gives them a typed
wrapper so that later Objective-1 work can distinguish possible worlds,
relations, axioms, constraints, and provenance without changing the quantale
API.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Literal, Union
import re

WorldKind = Literal["world", "relation", "axiom", "constraint", "tag"]
WorldLike = Union["WorldAtom", str]

_SAFE_METTA_ATOM = re.compile(r"^[A-Za-z_][A-Za-z0-9_\-]*$")

@dataclass(frozen=True)
class WorldAtom:
    """One typed element of the logic universe W.

    Parameters
    ----------
    name:
        Human-readable symbolic name.
    kind:
        What the atom represents.  This keeps the logic component from
        becoming merely an untyped collection of tags.
    source:
        Optional provenance, e.g. "manual", "PLN", "CASL", "ConceptNet".
    """

    name: str
    kind: WorldKind = "world"
    source: str | None = None

    def __post_init__(self) -> None:
        if not isinstance(self.name, str) or not self.name.strip():
            raise ValueError("WorldAtom.name must be a non-empty string.")
        if self.kind not in {"world", "relation", "axiom", "constraint", "tag"}:
            raise ValueError(f"Unsupported WorldAtom kind: {self.kind!r}")
        if self.source is not None and not isinstance(self.source, str):
            raise TypeError("WorldAtom.source must be a string or None.")

    @property
    def label(self) -> str:
        """Stable label used for serialization and readable diagnostics."""
        return self.name.strip()

    def sort_key(self) -> tuple[str, str, str]:
        return (self.kind, self.label, self.source or "")

    def to_metta_atom(self) -> str:
        """Serialize as a deterministic PeTTa/MeTTa atom-like token.

        Simple names are emitted unchanged.  Names containing spaces or other
        punctuation are emitted as quoted strings.
        """
        label = self.label
        if _SAFE_METTA_ATOM.match(label):
            return label
        escaped = label.replace('\\', '\\\\').replace('"', '\\"')
        return f'"{escaped}"'

def coerce_world_atom(value: WorldLike) -> WorldAtom:
    """Coerce strings to WorldAtom while preserving existing WorldAtom values."""
    if isinstance(value, WorldAtom):
        return value
    if isinstance(value, str):
        return WorldAtom(value)
    raise TypeError(f"Expected WorldAtom or str, got {type(value).__name__}.")

def metta_atom(name: str) -> str:
    """Serialize concept/property names safely for PeTTa/MeTTa assertions."""
    if not isinstance(name, str) or not name.strip():
        raise ValueError("MeTTa atom names must be non-empty strings.")
    name = name.strip()
    if _SAFE_METTA_ATOM.match(name):
        return name
    escaped = name.replace('\\', '\\\\').replace('"', '\\"')
    return f'"{escaped}"'
