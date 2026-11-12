"""ChEBI (Chemical Entities of Biological Interest) Source Adapter for chemical structures, roles, and reactions."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path
from typing import Any, Dict, Iterator, List, Optional, Tuple, Union

from .base_adapter import BaseSourceAdapter
from .models import FactType, IngestionProvenance, KnowledgeSource, MettaFact, NormalizedRecord, RawRecord
from .wordnet_adapter import safe_metta_symbol


def _edge_id(prefix: str, *parts: str) -> str:
    """Generate a deterministic, short edge identifier."""
    content = "_".join(str(p) for p in parts)
    digest = hashlib.sha256(content.encode("utf-8")).hexdigest()[:8]
    return f"{prefix}_{digest}"


class ChebiAdapter(BaseSourceAdapter):
    """Adapter for parsing OBO 1.4 formatted ChEBI and emitting CASL & Property-World facts."""

    def __init__(self, obo_path: Optional[Path] = None) -> None:
        if obo_path is not None:
            self.obo_path = Path(obo_path)
        else:
            base_dir = Path(__file__).resolve().parents[2]
            self.obo_path = base_dir / "fixtures" / "phenol_sub_chebi.obo"

    @property
    def source_type(self) -> KnowledgeSource:
        return KnowledgeSource.CHEBI

    @property
    def provenance(self) -> IngestionProvenance:
        return IngestionProvenance(
            source=KnowledgeSource.CHEBI,
            source_uri_or_path="https://ftp.ebi.ac.uk/pub/databases/chebi/ontology/chebi_lite.obo",
            source_version="2026-11",
            license="CC-BY-4.0",
        )

    def fetch(self, download: bool = False, cache_dir: Optional[Path] = None) -> Path:
        cache = cache_dir or Path("kb/raw_sources")
        cached_file = cache / "chebi_lite.obo"

        if cached_file.exists():
            return cached_file

        if download:
            cache.mkdir(parents=True, exist_ok=True)
            import urllib.request

            url = "https://ftp.ebi.ac.uk/pub/databases/chebi/ontology/chebi_lite.obo"
            req = urllib.request.Request(
                url, headers={"User-Agent": "conceptBlending/1.0 (Linux x86_64)"}
            )
            with urllib.request.urlopen(req) as resp, cached_file.open("wb") as out:
                while chunk := resp.read(65536):
                    out.write(chunk)
            return cached_file

        return self.obo_path

    def parse_obo(self, stream_or_path: Union[str, Path, Iterator[str]]) -> Iterator[Dict[str, Any]]:
        """Line-by-line streaming generator that yields non-obsolete chemical term records."""
        if isinstance(stream_or_path, (str, Path)):
            path = Path(stream_or_path)
            with path.open("r", encoding="utf-8", errors="replace") as f:
                yield from self._parse_obo_lines(f)
        else:
            yield from self._parse_obo_lines(stream_or_path)

    def _parse_obo_lines(self, lines: Iterator[str]) -> Iterator[Dict[str, Any]]:
        in_term = False
        current_term: Dict[str, Any] = {}

        for line in lines:
            line = line.strip()
            if not line or line.startswith("!"):
                continue

            if line == "[Term]":
                if in_term and current_term.get("id"):
                    if not current_term.get("is_obsolete", False):
                        yield current_term
                in_term = True
                current_term = {
                    "id": "",
                    "name": "",
                    "def": "",
                    "is_a": [],
                    "relationships": [],
                    "is_obsolete": False,
                    "alt_ids": [],
                }
                continue

            if line.startswith("[") and line.endswith("]"):
                # Non-term stanza (e.g. [Typedef])
                if in_term and current_term.get("id"):
                    if not current_term.get("is_obsolete", False):
                        yield current_term
                in_term = False
                current_term = {}
                continue

            if in_term and ":" in line:
                tag, val = line.split(":", 1)
                tag = tag.strip()
                val = val.strip()

                if tag == "id":
                    current_term["id"] = val
                elif tag == "name":
                    current_term["name"] = val
                elif tag == "def":
                    m = re.match(r'^"([^"]*)"', val)
                    current_term["def"] = m.group(1) if m else val
                elif tag == "is_obsolete":
                    current_term["is_obsolete"] = val.lower() in {"true", "1"}
                elif tag == "alt_id":
                    clean_alt = val.split("!")[0].strip()
                    if clean_alt:
                        current_term["alt_ids"].append(clean_alt)
                elif tag == "is_a":
                    clean_val = re.sub(r"\{.*?\}", "", val).split("!")[0].strip()
                    if clean_val:
                        current_term["is_a"].append(clean_val)
                elif tag == "relationship":
                    clean_val = re.sub(r"\{.*?\}", "", val).split("!")[0].strip()
                    parts = clean_val.split()
                    if len(parts) >= 2:
                        rel_type = parts[0].strip()
                        target_id = parts[1].strip()
                        current_term["relationships"].append((rel_type, target_id))

        if in_term and current_term.get("id"):
            if not current_term.get("is_obsolete", False):
                yield current_term

    def extract_raw_records(self, limit: Optional[int] = None) -> Iterator[RawRecord]:
        """Stream raw records from parsed ChEBI terms with primary and alt_id resolution."""
        terms = list(self.parse_obo(self.obo_path))
        id_to_term: Dict[str, Dict[str, Any]] = {}
        for t in terms:
            id_to_term[t["id"]] = t
            for alt in t.get("alt_ids", []):
                id_to_term[alt] = t

        # Chemical solvent/medium worlds
        chemical_worlds = ["water", "aqueous_solution", "organic_phase", "lipid_bilayer"]

        count = 0
        for term in terms:
            concept = term["name"]
            meta = {
                "chebi_id": term["id"],
                "def": term.get("def", ""),
                "worlds": chemical_worlds,
            }

            # 1. is_a taxonomic relations
            for parent_id in term.get("is_a", []):
                parent_term = id_to_term.get(parent_id)
                parent_name = parent_term["name"] if parent_term else parent_id
                yield RawRecord(
                    source_id=f"{term['id']}_is_a_{parent_id}",
                    concept_name=concept,
                    relation="is_a",
                    target_name=parent_name,
                    weight=0.95,
                    metadata=meta,
                    provenance=self.provenance,
                )
                count += 1
                if limit and count >= limit:
                    return

            # 2. explicit relationship edges (has_part, has_role, is_conjugate_acid_of)
            for rel_type, target_id in term.get("relationships", []):
                target_term = id_to_term.get(target_id)
                target_name = target_term["name"] if target_term else target_id
                yield RawRecord(
                    source_id=f"{term['id']}_{rel_type}_{target_id}",
                    concept_name=concept,
                    relation=rel_type,
                    target_name=target_name,
                    weight=0.90,
                    metadata=meta,
                    provenance=self.provenance,
                )
                count += 1
                if limit and count >= limit:
                    return

    def normalize_record(self, record: RawRecord) -> Optional[NormalizedRecord]:
        concept_sym = safe_metta_symbol(record.concept_name)
        target_sym = safe_metta_symbol(record.target_name)

        if not concept_sym or not target_sym:
            return None

        relation = record.relation

        # Chemical relationship routing
        if relation == "is_a":
            perspective = "taxonomic-kind"
            canonical_rel = "isA"
            strength = 0.95
            confidence = 0.95
        elif relation == "has_part":
            perspective = "structural-composition"
            canonical_rel = "hasPart"
            strength = 0.95
            confidence = 0.95
        elif relation == "has_role":
            perspective = "functional-use"
            canonical_rel = "hasRole"
            strength = 0.90
            confidence = 0.95
        elif relation == "is_conjugate_acid_of":
            perspective = "state-lifecycle"
            canonical_rel = "dissociatesTo"
            strength = 0.90
            confidence = 0.95
        else:
            perspective = "descriptive-property"
            canonical_rel = safe_metta_symbol(relation)
            strength = 0.80
            confidence = 0.85

        return NormalizedRecord(
            concept=concept_sym,
            property_or_target=target_sym,
            relation=canonical_rel,
            perspective=perspective,
            strength=strength,
            confidence=confidence,
            provenance=record.provenance or self.provenance,
        )

    def transform_to_casl(self, record: NormalizedRecord) -> List[MettaFact]:
        facts: List[MettaFact] = []
        edge_id = _edge_id("casl_chebi", record.concept, record.relation, record.property_or_target)
        stv = (record.strength, record.confidence)

        if record.perspective in {"taxonomic-kind", "structural-composition"}:
            facts.append(
                MettaFact(
                    fact_type=FactType.HAS_SORT,
                    expression=f"(has_sort {edge_id} {record.concept} {record.perspective} {record.property_or_target})",
                    stv=stv,
                )
            )
        elif record.perspective == "functional-use":
            facts.append(
                MettaFact(
                    fact_type=FactType.HAS_PREDICATE,
                    expression=f"(has_predicate {edge_id} {record.concept} {record.perspective} {record.property_or_target})",
                    stv=stv,
                )
            )
            facts.append(
                MettaFact(
                    fact_type=FactType.PREDICATE_SIGNATURE,
                    expression=f"(predicate_signature {edge_id} (-> ({record.concept}) Boolean))",
                    stv=stv,
                )
            )
        elif record.perspective == "state-lifecycle":
            op_name = f"dissociate_{record.concept}"
            facts.append(
                MettaFact(
                    fact_type=FactType.HAS_OPERATION,
                    expression=f"(has_operation {edge_id} {record.concept} {record.perspective} {op_name})",
                    stv=stv,
                )
            )
            facts.append(
                MettaFact(
                    fact_type=FactType.OPERATION_SIGNATURE,
                    expression=f"(operation_signature {edge_id} (-> ({record.concept}) ({record.property_or_target} proton)))",
                    stv=stv,
                )
            )
            # Equational axiom representing reversible dissociation
            axiom_name = f"ax_dissociation_{record.concept}"
            facts.append(
                MettaFact(
                    fact_type=FactType.HAS_AXIOM,
                    expression=f"(has_axiom {edge_id} {record.concept} {record.perspective} {axiom_name} (reversible-equilibrium {record.concept} ({record.property_or_target} proton)))",
                    stv=stv,
                )
            )
        else:
            facts.append(
                MettaFact(
                    fact_type=FactType.HAS_PREDICATE,
                    expression=f"(has_predicate {edge_id} {record.concept} {record.perspective} {record.property_or_target})",
                    stv=stv,
                )
            )

        return facts

    def transform_to_property_world(self, record: NormalizedRecord) -> List[MettaFact]:
        facts: List[MettaFact] = []
        stv = (record.strength, record.confidence)
        prop_id = f"prop_{record.concept}_{record.property_or_target}"
        edge_id = _edge_id("pw_chebi", record.concept, record.perspective, prop_id)

        # 1. Concept-Property assertion
        facts.append(
            MettaFact(
                fact_type=FactType.HAS_SCOPED_PROPERTY,
                expression=f"(has_scoped_property {edge_id} {record.concept} {record.perspective} {prop_id} {record.property_or_target})",
                stv=stv,
            )
        )

        # 2. Perspective Match assertion
        pm_edge = _edge_id("pm_chebi", record.perspective)
        facts.append(
            MettaFact(
                fact_type=FactType.PERSPECTIVE_MATCH,
                expression=f"(perspective_match {pm_edge} {record.perspective} {record.perspective} exact-perspective)",
                stv=(1.0, 1.0),
            )
        )

        # 3. Possible Worlds assertions (chemical solvents / environments)
        chemical_worlds = [
            "water",
            "aqueous_solution",
            "organic_solvent",
        ]
        for idx, world in enumerate(chemical_worlds[:3]):
            w_edge = _edge_id("world_chebi", prop_id, world, str(idx))
            facts.append(
                MettaFact(
                    fact_type=FactType.SCOPED_PROPERTY_HOLDS_IN,
                    expression=f"(scoped_property_holds_in {w_edge} {prop_id} {record.perspective} {world})",
                    stv=stv,
                )
            )

        return facts
