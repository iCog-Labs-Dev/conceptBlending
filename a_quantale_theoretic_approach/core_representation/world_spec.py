"""CASL-like possible-world specifications used by V-predicate logic values."""

from __future__ import annotations

from collections.abc import Iterable, Mapping
from dataclasses import dataclass
from types import MappingProxyType

from .sexpr import AtomTree, atom_name, flatten_sexpr
from .world_atom import WorldAtom


@dataclass(frozen=True)
class WorldSpec:
    """One named possible world with a CASL-like specification body."""

    name: str
    body: AtomTree
    spec_kind: str = "independent-spec"

    @classmethod
    def from_tree(cls, tree: list[AtomTree]) -> "WorldSpec":
        if len(tree) < 3 or tree[0] != "WorldSpec":
            raise ValueError("WorldSpec tree must have shape (WorldSpec name body).")
        name = atom_name(tree[1])
        body = tree[2]
        spec_kind = atom_name(body[0]) if isinstance(body, list) and body else "independent-spec"
        return cls(name=name, body=body, spec_kind=spec_kind)

    @classmethod
    def placeholder(cls, name: str) -> "WorldSpec":
        return cls(
            name=name,
            body=["placeholder-spec", ["sorts"], ["ops"], ["preds"], ["axioms"]],
            spec_kind="placeholder-spec",
        )

    @property
    def is_placeholder(self) -> bool:
        return self.spec_kind == "placeholder-spec"

    @property
    def atom(self) -> WorldAtom:
        return WorldAtom(self.name, kind="world")

    def to_metta(self) -> str:
        return f"(WorldSpec {self.name}\n  {flatten_sexpr(self.body)})"


class WorldSpecRegistry:
    """Container for possible-world CASL specs keyed by world name."""

    def __init__(self, specs: Iterable[WorldSpec] | None = None):
        self._specs: dict[str, WorldSpec] = {}
        if specs:
            for spec in specs:
                self.add(spec)

    @property
    def specs(self) -> Mapping[str, WorldSpec]:
        return MappingProxyType(self._specs)

    @property
    def names(self) -> tuple[str, ...]:
        return tuple(sorted(self._specs))

    @property
    def universal_set(self) -> frozenset[WorldAtom]:
        return frozenset(self._specs[name].atom for name in self.names)

    def add(self, spec: WorldSpec, *, overwrite: bool = False) -> None:
        if spec.name in self._specs:
            existing = self._specs[spec.name]
            if spec.is_placeholder and not existing.is_placeholder:
                return
            if existing.is_placeholder and not spec.is_placeholder:
                self._specs[spec.name] = spec
                return
            if not overwrite:
                raise ValueError(f"WorldSpec {spec.name!r} already exists.")
        self._specs[spec.name] = spec

    def get(self, name: str) -> WorldSpec:
        return self._specs[name]

    def merge(self, other: "WorldSpecRegistry", *, overwrite: bool = False) -> "WorldSpecRegistry":
        merged = WorldSpecRegistry(self._specs.values())
        for spec in other._specs.values():
            merged.add(spec, overwrite=overwrite)
        return merged

    def ensure_worlds(self, names: Iterable[str]) -> "WorldSpecRegistry":
        """Return a registry also containing placeholder specs for missing worlds."""
        completed = WorldSpecRegistry(self._specs.values())
        for name in names:
            if name not in completed._specs:
                completed.add(WorldSpec.placeholder(name))
        return completed

    def to_metta(self) -> str:
        return "\n\n".join(self._specs[name].to_metta() for name in self.names)

    def __contains__(self, name: str) -> bool:
        return name in self._specs

    def __len__(self) -> int:
        return len(self._specs)

    def __repr__(self) -> str:
        return f"WorldSpecRegistry(names={list(self.names)!r})"
