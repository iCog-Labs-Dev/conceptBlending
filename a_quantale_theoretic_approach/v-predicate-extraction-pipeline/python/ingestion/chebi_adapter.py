"""ChEBI (Chemical Entities of Biological Interest) Source Adapter for chemical structures, roles, and reactions."""

from __future__ import annotations

import hashlib
from pathlib import Path
import re
from typing import Any, Dict, Iterable, Iterator, List, Optional, Tuple, Union

from .base_adapter import BaseSourceAdapter
from .models import FactType, IngestionProvenance, KnowledgeSource, MettaFact, NormalizedRecord, RawRecord
from .wordnet_adapter import safe_metta_symbol
from v_predicate_contract import (
    FactKind,
    FactOrigin,
    FactRecord,
    Perspective,
    PredicateFact,
    PropertyFact,
    PropertyWorldFact,
    Provenance,
    SortFact,
    TruthValue,
    stable_evidence_id,
)

PIPELINE_ROOT = Path(__file__).resolve().parents[2]


def _edge_id(prefix: str, *parts: str) -> str:
    """Generate a deterministic, short edge identifier for legacy CASL facts."""
    content = "_".join(str(p) for p in parts)
    digest = hashlib.sha256(content.encode("utf-8")).hexdigest()[:8]
    return f"{prefix}_{digest}"


class ChebiAdapter(BaseSourceAdapter):
    """Adapter for parsing OBO 1.4 formatted ChEBI and emitting canonical v-predicate/1 facts."""

    def __init__(
        self,
        obo_path: Optional[Path] = None,
        cache_dir: Optional[Path] = None,
    ) -> None:
        if obo_path is not None:
            self.obo_path = Path(obo_path).resolve()
        else:
            self.obo_path = (PIPELINE_ROOT / "fixtures" / "phenol_sub_chebi.obo").resolve()

        if cache_dir is not None:
            self.cache_dir = Path(cache_dir).resolve()
        else:
            self.cache_dir = (PIPELINE_ROOT / "data" / "cache" / "chebi").resolve()

        self.source_name = "chebi"
        self.license = "CC-BY-4.0"
        self.source_uri = "https://ftp.ebi.ac.uk/pub/databases/chebi/ontology/chebi_lite.obo"
        self.transformation = "chebi_adapter_v1"
        self.version = self._get_file_version(self.obo_path)

    @staticmethod
    def _extract_obo_header(lines: Union[Iterator[str], Iterable[str]]) -> Dict[str, str]:
        """Extract header key-value pairs before any stanza marker."""
        header: Dict[str, str] = {}
        for line in lines:
            line = line.strip()
            if not line or line.startswith("!"):
                continue
            if line.startswith("[") and line.endswith("]"):
                break
            if ":" in line:
                k, v = line.split(":", 1)
                header[k.strip().lower()] = v.strip()
        return header

    def _get_file_version(self, path: Path) -> str:
        """Derive dynamic version from OBO data-version or date header."""
        if not path.exists():
            return "unknown"
        try:
            with path.open("r", encoding="utf-8", errors="replace") as f:
                header = self._extract_obo_header(f)
                return header.get("data-version") or header.get("date") or "unknown"
        except Exception:
            return "unknown"

    @property
    def source_type(self) -> KnowledgeSource:
        return KnowledgeSource.CHEBI

    @property
    def provenance(self) -> IngestionProvenance:
        return IngestionProvenance(
            source=KnowledgeSource.CHEBI,
            source_uri_or_path=self.source_uri,
            source_version=self.version,
            license=self.license,
        )

    def fetch(self, download: bool = False, cache_dir: Optional[Path] = None) -> Path:
        cache = cache_dir.resolve() if cache_dir else self.cache_dir
        cached_file = cache / "chebi_lite.obo"

        if cached_file.exists():
            self.version = self._get_file_version(cached_file)
            return cached_file

        if download:
            cache.mkdir(parents=True, exist_ok=True)
            import urllib.request

            req = urllib.request.Request(
                self.source_uri, headers={"User-Agent": "conceptBlending/1.0 (Linux x86_64)"}
            )
            with urllib.request.urlopen(req) as resp, cached_file.open("wb") as out:
                while chunk := resp.read(65536):
                    out.write(chunk)
            self.version = self._get_file_version(cached_file)
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
                    "is_a_details": [],
                    "relationships": [],
                    "relationship_details": [],
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
                    if "!" in val:
                        val_part, comment_part = val.split("!", 1)
                        target_name = comment_part.strip()
                    else:
                        val_part = val
                        target_name = ""
                    target_id = re.sub(r"\{.*?\}", "", val_part).strip()
                    if not target_name:
                        target_name = target_id
                    if target_id:
                        current_term["is_a"].append(target_id)
                        current_term["is_a_details"].append((target_id, target_name))
                elif tag == "relationship":
                    if "!" in val:
                        val_part, comment_part = val.split("!", 1)
                        target_name = comment_part.strip()
                    else:
                        val_part = val
                        target_name = ""
                    clean_rel = re.sub(r"\{.*?\}", "", val_part).strip()
                    parts = clean_rel.split()
                    if len(parts) >= 2:
                        rel_type = parts[0].strip()
                        target_id = parts[1].strip()
                        if not target_name:
                            target_name = target_id
                        current_term["relationships"].append((rel_type, target_id))
                        current_term["relationship_details"].append((rel_type, target_id, target_name))

        if in_term and current_term.get("id"):
            if not current_term.get("is_obsolete", False):
                yield current_term

    def stream_facts(self, limit: Optional[int] = None) -> Iterator[FactRecord]:
        """Stream canonical typed V-predicate fact records under v-predicate/1 in bounded memory."""
        resolved_path = self.fetch(download=False)
        version = self._get_file_version(resolved_path)
        emitted = 0

        for term in self.parse_obo(resolved_path):
            concept = safe_metta_symbol(term["name"]).lower()
            if not concept or concept == "c_empty":
                continue
            term_id = term["id"]

            # 1. is_a -> SortFact (taxonomic_kind)
            for parent_id, parent_name in term.get("is_a_details", []):
                parent_sym = safe_metta_symbol(parent_name).lower()
                if not parent_sym or parent_sym == "c_empty":
                    continue
                edge_id = stable_evidence_id("sort", "chebi", concept, parent_sym)
                prov = Provenance(
                    source="chebi",
                    source_record_id=f"{term_id}_is_a_{parent_id}",
                    source_uri=self.source_uri,
                    source_version=version,
                    license=self.license,
                    transformation=self.transformation,
                    origin=FactOrigin.ASSERTED,
                )
                yield SortFact(
                    evidence_id=edge_id,
                    edge_id=edge_id,
                    concept=concept,
                    perspective=Perspective.TAXONOMIC_KIND,
                    sort=parent_sym,
                    truth=TruthValue(0.95, 0.95),
                    provenance=prov,
                )
                emitted += 1
                if limit is not None and emitted >= limit:
                    return

            # 2. Chemical relationships (has_part, has_role, is_conjugate_acid_of)
            for rel_type, target_id, target_name in term.get("relationship_details", []):
                target_sym = safe_metta_symbol(target_name).lower()
                if not target_sym or target_sym == "c_empty":
                    continue

                prov = Provenance(
                    source="chebi",
                    source_record_id=f"{term_id}_{rel_type}_{target_id}",
                    source_uri=self.source_uri,
                    source_version=version,
                    license=self.license,
                    transformation=self.transformation,
                    origin=FactOrigin.ASSERTED,
                )

                if rel_type == "has_part":
                    persp = Perspective.STRUCTURAL_COMPOSITION
                    predicate_expr = f"(has_part {concept} {target_sym})"
                    edge_id = stable_evidence_id("predicate", "chebi", concept, "has_part", target_sym)
                    yield PredicateFact(
                        evidence_id=edge_id,
                        edge_id=edge_id,
                        concept=concept,
                        perspective=persp,
                        predicate=predicate_expr,
                        truth=TruthValue(0.95, 0.95),
                        provenance=prov,
                    )
                elif rel_type == "has_role":
                    persp = Perspective.FUNCTIONAL_USE
                    predicate_expr = f"(has_role {concept} {target_sym})"
                    edge_id = stable_evidence_id("predicate", "chebi", concept, "has_role", target_sym)
                    yield PredicateFact(
                        evidence_id=edge_id,
                        edge_id=edge_id,
                        concept=concept,
                        perspective=persp,
                        predicate=predicate_expr,
                        truth=TruthValue(0.90, 0.95),
                        provenance=prov,
                    )
                elif rel_type in {"is_conjugate_acid_of", "is_conjugate_base_of"}:
                    persp = Perspective.STATE_LIFECYCLE
                    rel_sym = safe_metta_symbol(rel_type).lower()
                    predicate_expr = f"({rel_sym} {concept} {target_sym})"
                    edge_id = stable_evidence_id("predicate", "chebi", concept, rel_sym, target_sym)
                    yield PredicateFact(
                        evidence_id=edge_id,
                        edge_id=edge_id,
                        concept=concept,
                        perspective=persp,
                        predicate=predicate_expr,
                        truth=TruthValue(0.90, 0.95),
                        provenance=prov,
                    )
                else:
                    persp = Perspective.DESCRIPTIVE_PROPERTY
                    rel_sym = safe_metta_symbol(rel_type).lower()
                    predicate_expr = f"({rel_sym} {concept} {target_sym})"
                    edge_id = stable_evidence_id("predicate", "chebi", concept, rel_sym, target_sym)
                    yield PredicateFact(
                        evidence_id=edge_id,
                        edge_id=edge_id,
                        concept=concept,
                        perspective=persp,
                        predicate=predicate_expr,
                        truth=TruthValue(0.85, 0.85),
                        provenance=prov,
                    )

                emitted += 1
                if limit is not None and emitted >= limit:
                    return

            # 3. Possible Worlds for chemical states / solvation environments
            prop_id = f"prop_{concept}_chemical_state"
            p_edge = stable_evidence_id("property", "chebi", concept, prop_id)
            prov_prop = Provenance(
                source="chebi",
                source_record_id=f"{term_id}_state",
                source_uri=self.source_uri,
                source_version=version,
                license=self.license,
                transformation=self.transformation,
                origin=FactOrigin.ASSERTED,
            )
            yield PropertyFact(
                evidence_id=p_edge,
                edge_id=p_edge,
                concept=concept,
                perspective=Perspective.STATE_LIFECYCLE,
                property_id=prop_id,
                property_name="chemical_state",
                truth=TruthValue(0.90, 0.90),
                provenance=prov_prop,
            )
            emitted += 1
            if limit is not None and emitted >= limit:
                return

            candidate_worlds = ["aqueous_solution", "water", "organic_phase"]
            for world in candidate_worlds:
                w_edge = stable_evidence_id("world", "chebi", prop_id, world)
                yield PropertyWorldFact(
                    evidence_id=w_edge,
                    edge_id=w_edge,
                    property_id=prop_id,
                    perspective=Perspective.STATE_LIFECYCLE,
                    world=world,
                    truth=TruthValue(0.85, 0.90),
                    provenance=prov_prop,
                )
                emitted += 1
                if limit is not None and emitted >= limit:
                    return

    # -------------------------------------------------------------------------
    # Legacy interfaces for backward compatibility with orchestrator / sinks
    # -------------------------------------------------------------------------
    def extract_raw_records(self, limit: Optional[int] = None) -> Iterator[RawRecord]:
        """Stream raw records lazily term-by-term in bounded memory."""
        resolved_path = self.fetch(download=False)
        chemical_worlds = ["water", "aqueous_solution", "organic_phase", "lipid_bilayer"]

        count = 0
        for term in self.parse_obo(resolved_path):
            concept = term["name"]
            meta = {
                "chebi_id": term["id"],
                "def": term.get("def", ""),
                "worlds": chemical_worlds,
            }

            for parent_id, parent_name in term.get("is_a_details", []):
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

            for rel_type, target_id, target_name in term.get("relationship_details", []):
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
            axiom_name = f"ax_dissociation_{record.concept}"
            facts.append(
                MettaFact(
                    fact_type=FactType.HAS_AXIOM,
                    expression=f"(has_axiom {edge_id} {record.concept} {record.perspective} (axiom {axiom_name} (reversible-equilibrium {record.concept} ({record.property_or_target} proton))))",
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

        facts.append(
            MettaFact(
                fact_type=FactType.HAS_SCOPED_PROPERTY,
                expression=f"(has_scoped_property {edge_id} {record.concept} {record.perspective} {prop_id} {record.property_or_target})",
                stv=stv,
            )
        )
        facts.append(
            MettaFact(
                fact_type=FactType.PERSPECTIVE_MATCH,
                expression=f"(perspective_match {record.perspective} {record.perspective} exact-perspective)",
                stv=(1.0, 1.0),
            )
        )

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
