"""Index ConceptNet-style atomspace edges for existing habit-memory counts."""

from __future__ import annotations

import os
from pathlib import Path
import re
import sqlite3


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_EVIDENCE_ROOT = (
    REPO_ROOT / "a_quantale_theoretic_approach" /
    "v-predicate-extraction-pipeline" / "kb" / "evidence" / "concept-atomspace"
)
DEFAULT_INDEX = Path(__file__).resolve().parent / ".cache" / "atomspace_habits.sqlite3"
EDGE_RE = re.compile(
    r"^\(([A-Za-z][A-Za-z0-9_-]*)\s+([^\s()]+)\s+([^\s()]+)\)\s*$"
)
META_RELATIONS = {"source", "target", "weight", "surfaceText", "relation"}
SAFE_ATOM = re.compile(r"^[a-z_][A-Za-z0-9_@-]*$")


def _atom(value: object) -> str:
    text = str(value).strip().strip("'").strip('"')
    if not SAFE_ATOM.fullmatch(text):
        raise ValueError(f"unsafe habit property atom: {text!r}")
    return text


def _property_list(value: object) -> list[str]:
    text = str(value).strip()
    if text.startswith("(") and text.endswith(")"):
        text = text[1:-1]
    result = []
    for token in text.split():
        atom = _atom(token)
        if atom not in result:
            result.append(atom)
    return result


def _fingerprint(root: Path) -> str:
    files = sorted(root.glob("*.metta"))
    return "|".join(f"{p.name}:{p.stat().st_size}:{p.stat().st_mtime_ns}" for p in files)


def build_index(evidence_root: object = "", index_path: object = "") -> str:
    """Build an aggregated binary-edge index using constant Python memory."""
    root = Path(str(evidence_root)) if str(evidence_root) else DEFAULT_EVIDENCE_ROOT
    target = Path(str(index_path)) if str(index_path) else DEFAULT_INDEX
    if not root.is_dir():
        raise FileNotFoundError(f"atomspace evidence directory does not exist: {root}")
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = target.with_suffix(target.suffix + ".tmp")
    if temporary.exists():
        temporary.unlink()
    database = sqlite3.connect(temporary)
    try:
        database.execute("CREATE TABLE edges (a TEXT, b TEXT, n INTEGER, PRIMARY KEY(a,b))")
        database.execute("CREATE TABLE metadata (key TEXT PRIMARY KEY, value TEXT)")
        batch = []
        for path in sorted(root.glob("*.metta")):
            with path.open("r", encoding="utf-8", errors="replace") as source:
                for line in source:
                    match = EDGE_RE.match(line)
                    if not match or match.group(1) in META_RELATIONS:
                        continue
                    left, right = match.group(2).strip("'\""), match.group(3).strip("'\"")
                    if not SAFE_ATOM.fullmatch(left) or not SAFE_ATOM.fullmatch(right):
                        continue
                    a, b = sorted((left, right))
                    batch.append((a, b))
                    if len(batch) >= 10000:
                        database.executemany(
                            "INSERT INTO edges VALUES (?, ?, 1) ON CONFLICT(a,b) DO UPDATE SET n=n+1",
                            batch,
                        )
                        database.commit()
                        batch.clear()
        if batch:
            database.executemany(
                "INSERT INTO edges VALUES (?, ?, 1) ON CONFLICT(a,b) DO UPDATE SET n=n+1",
                batch,
            )
        database.execute("INSERT INTO metadata VALUES ('fingerprint', ?)", (_fingerprint(root),))
        database.commit()
    finally:
        database.close()
    os.replace(temporary, target)
    return str(target)


def ensure_index(evidence_root: object = "", index_path: object = "") -> Path:
    root = Path(str(evidence_root)) if str(evidence_root) else DEFAULT_EVIDENCE_ROOT
    target = Path(str(index_path)) if str(index_path) else DEFAULT_INDEX
    if target.exists():
        with sqlite3.connect(target) as database:
            row = database.execute(
                "SELECT value FROM metadata WHERE key='fingerprint'"
            ).fetchone()
        if row and row[0] == _fingerprint(root):
            return target
    return Path(build_index(root, target))


def load_evidence(properties: object, evidence_root: object = "", index_path: object = "") -> str:
    """Return compact counts for the requested properties only."""
    names = _property_list(properties)
    index = ensure_index(evidence_root, index_path)
    property_counts, pair_counts = [], []
    with sqlite3.connect(index) as database:
        total = database.execute("SELECT COALESCE(SUM(n),0) FROM edges").fetchone()[0]
        for name in names:
            count = database.execute(
                "SELECT COALESCE(SUM(n),0) FROM edges WHERE a=? OR b=?", (name, name)
            ).fetchone()[0]
            property_counts.append(f"(PropertyCount {name} {int(count)})")
        for offset, left in enumerate(names):
            for right in names[offset + 1:]:
                a, b = sorted((left, right))
                count = database.execute(
                    "SELECT COALESCE(n,0) FROM edges WHERE a=? AND b=?", (a, b)
                ).fetchone()
                pair_counts.append(f"(PairCount {left} {right} {int(count[0]) if count else 0})")
    return (
        "(AtomspaceHabitEvidence "
        f"(PropertyCounts ({' '.join(property_counts)})) "
        f"(PairCounts ({' '.join(pair_counts)})) "
        f"(EvidenceCount {int(total)}) (Index \"{index}\"))"
    )
