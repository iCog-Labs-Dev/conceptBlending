"""Atomic bridge from canonical V-predicate records to the PathMap KB compiler."""

from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Sequence

from v_predicate_contract import (
    AxiomFact,
    FactRecord,
    OperationFact,
    OperationSignatureFact,
    PredicateFact,
    PredicateSignatureFact,
    SortFact,
    render_document,
    validate_record_set,
)


class PathMapCompileError(RuntimeError):
    """Raised when canonical records cannot be compiled into a PathMap index."""


@dataclass(frozen=True)
class PathMapBuildResult:
    index_dir: Path
    property_records: int
    algebraic_records: int
    stats: dict[str, int]


_ALGEBRA_TYPES = (
    SortFact,
    OperationFact,
    OperationSignatureFact,
    PredicateFact,
    PredicateSignatureFact,
    AxiomFact,
)


def split_records(
    records: Sequence[FactRecord],
) -> tuple[list[FactRecord], list[FactRecord]]:
    """Split a validated record set into compiler inputs without losing metadata facts."""
    validate_record_set(records)
    property_records: list[FactRecord] = []
    algebraic_records: list[FactRecord] = []
    for record in records:
        if isinstance(record, _ALGEBRA_TYPES):
            algebraic_records.append(record)
        else:
            property_records.append(record)
    return property_records, algebraic_records


def _read_stats(path: Path) -> dict[str, int]:
    stats: dict[str, int] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        name, separator, value = line.partition("=")
        if not separator:
            raise PathMapCompileError(f"malformed PathMap build statistic: {line!r}")
        stats[name] = int(value)
    return stats


def compile_records(
    records: Sequence[FactRecord],
    output_dir: str | Path,
    *,
    compiler: str | Path,
) -> PathMapBuildResult:
    """Render and atomically compile canonical records with the real PathMap binary.

    The destination must not already exist. This keeps publication recoverable and prevents an
    integration run from silently replacing a verified index.
    """
    property_records, algebraic_records = split_records(records)
    destination = Path(output_dir).resolve()
    if destination.exists():
        raise PathMapCompileError(f"PathMap index destination already exists: {destination}")
    destination.parent.mkdir(parents=True, exist_ok=True)

    compiler_path = Path(compiler).resolve()
    if not compiler_path.is_file() or not os.access(compiler_path, os.X_OK):
        raise PathMapCompileError(f"PathMap compiler is not executable: {compiler_path}")

    staging_root = Path(
        tempfile.mkdtemp(prefix=f".{destination.name}.staging-", dir=destination.parent)
    )
    documents = staging_root / "canonical"
    index = staging_root / "index"
    documents.mkdir()
    property_kb = documents / "PropertyWorldKB.metta"
    algebraic_kb = documents / "AlgebraicSpecificationKB.metta"
    property_kb.write_text(render_document(property_records), encoding="utf-8")
    algebraic_kb.write_text(render_document(algebraic_records), encoding="utf-8")

    command = [
        str(compiler_path),
        "build",
        "--property-kb",
        str(property_kb),
        "--algebraic-kb",
        str(algebraic_kb),
        "--out",
        str(index),
    ]
    try:
        completed = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
        )
        if completed.returncode != 0:
            raise PathMapCompileError(
                "PathMap compilation failed: "
                + (completed.stderr.strip() or completed.stdout.strip())
            )
        required = (
            "manifest.tsv",
            "symbols.tsv",
            "payloads.tsv",
            "contract-version.txt",
            "index-format-version.txt",
            "build-stats.txt",
        )
        missing = [name for name in required if not (index / name).is_file()]
        if missing:
            raise PathMapCompileError(
                f"PathMap compiler omitted required artifacts: {', '.join(missing)}"
            )
        stats = _read_stats(index / "build-stats.txt")
        index.rename(destination)
    finally:
        shutil.rmtree(staging_root, ignore_errors=True)

    return PathMapBuildResult(
        index_dir=destination,
        property_records=len(property_records),
        algebraic_records=len(algebraic_records),
        stats=stats,
    )
