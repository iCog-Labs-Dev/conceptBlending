"""Gene Ontology (GO) Source Adapter for biological processes, molecular functions, and cellular components."""

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


class GeneOntologyAdapter(BaseSourceAdapter):
    """Adapter for parsing OBO 1.4 formatted Gene Ontology and emitting canonical v-predicate/1 facts."""

    def __init__(
        self,
        obo_path: Optional[Path] = None,
        cache_dir: Optional[Path] = None,
    ) -> None:
        if obo_path is not None:
            self.obo_path = Path(obo_path).resolve()
        else:
            self.obo_path = (PIPELINE_ROOT / "fixtures" / "bioenergetics_sub_go.obo").resolve()

        if cache_dir is not None:
            self.cache_dir = Path(cache_dir).resolve()
        else:
            self.cache_dir = (PIPELINE_ROOT / "data" / "cache" / "go").resolve()

        self.source_name = "gene_ontology"
        self.license = "CC-BY-4.0"
        self.source_uri = "http://current.geneontology.org/ontology/go.obo"
        self.transformation = "go_adapter_v1"
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
        return KnowledgeSource.GENE_ONTOLOGY

    @property
    def provenance(self) -> IngestionProvenance:
        return IngestionProvenance(
            source=KnowledgeSource.GENE_ONTOLOGY,
            source_uri_or_path=self.source_uri,
            source_version=self.version,
            license=self.license,
        )

    def fetch(self, download: bool = False, cache_dir: Optional[Path] = None) -> Path:
        cache = cache_dir.resolve() if cache_dir else self.cache_dir
        cached_file = cache / "go.obo"

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
        """Line-by-line streaming generator that yields non-obsolete term records."""
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
                    "namespace": "",
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
                # Hit another stanza (e.g. [Typedef])
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
                elif tag == "namespace":
                    current_term["namespace"] = val
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
            namespace = term.get("namespace", "")
            term_id = term["id"]

            # 1. is_a -> SortFact (taxonomic_kind)
            for parent_id, parent_name in term.get("is_a_details", []):
                parent_sym = safe_metta_symbol(parent_name).lower()
                if not parent_sym or parent_sym == "c_empty":
                    continue
                edge_id = stable_evidence_id("sort", "gene_ontology", concept, parent_sym)
                prov = Provenance(
                    source="gene_ontology",
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

            # 2. Relationships (part_of, regulates, etc.)
            for rel_type, target_id, target_name in term.get("relationship_details", []):
                target_sym = safe_metta_symbol(target_name).lower()
                if not target_sym or target_sym == "c_empty":
                    continue

                prov = Provenance(
                    source="gene_ontology",
                    source_record_id=f"{term_id}_{rel_type}_{target_id}",
                    source_uri=self.source_uri,
                    source_version=version,
                    license=self.license,
                    transformation=self.transformation,
                    origin=FactOrigin.ASSERTED,
                )

                if rel_type == "part_of":
                    persp = Perspective.STRUCTURAL_COMPOSITION
                    predicate_expr = f"(part_of {concept} {target_sym})"
                    edge_id = stable_evidence_id("predicate", "gene_ontology", concept, "part_of", target_sym)
                    yield PredicateFact(
                        evidence_id=edge_id,
                        edge_id=edge_id,
                        concept=concept,
                        perspective=persp,
                        predicate=predicate_expr,
                        truth=TruthValue(0.90, 0.95),
                        provenance=prov,
                    )
                elif rel_type in {"regulates", "positively_regulates", "negatively_regulates"}:
                    persp = Perspective.CAUSAL_PREREQUISITE
                    rel_sym = safe_metta_symbol(rel_type).lower()
                    predicate_expr = f"({rel_sym} {concept} {target_sym})"
                    edge_id = stable_evidence_id("predicate", "gene_ontology", concept, rel_sym, target_sym)
                    yield PredicateFact(
                        evidence_id=edge_id,
                        edge_id=edge_id,
                        concept=concept,
                        perspective=persp,
                        predicate=predicate_expr,
                        truth=TruthValue(0.85, 0.90),
                        provenance=prov,
                    )
                else:
                    persp = Perspective.BEHAVIORAL_PROCESS
                    rel_sym = safe_metta_symbol(rel_type).lower()
                    predicate_expr = f"({rel_sym} {concept} {target_sym})"
                    edge_id = stable_evidence_id("predicate", "gene_ontology", concept, rel_sym, target_sym)
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

            # 3. Intrinsic PropertyFact & Possible Worlds
            if namespace == "biological_process":
                persp = Perspective.BEHAVIORAL_PROCESS
                prop_id = f"prop_{concept}_process"
            elif namespace == "molecular_function":
                persp = Perspective.FUNCTIONAL_USE
                prop_id = f"prop_{concept}_function"
            elif namespace == "cellular_component":
                persp = Perspective.STRUCTURAL_COMPOSITION
                prop_id = f"prop_{concept}_component"
            else:
                persp = Perspective.DESCRIPTIVE_PROPERTY
                prop_id = f"prop_{concept}_property"

            p_edge = stable_evidence_id("property", "gene_ontology", concept, prop_id)
            prov_prop = Provenance(
                source="gene_ontology",
                source_record_id=f"{term_id}_prop",
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
                perspective=persp,
                property_id=prop_id,
                property_name=concept,
                truth=TruthValue(0.90, 0.90),
                provenance=prov_prop,
            )
            emitted += 1
            if limit is not None and emitted >= limit:
                return

            # Possible Worlds: cellular components
            if namespace == "cellular_component":
                world = concept
                w_edge = stable_evidence_id("world", "gene_ontology", prop_id, world)
                yield PropertyWorldFact(
                    evidence_id=w_edge,
                    edge_id=w_edge,
                    property_id=prop_id,
                    perspective=Perspective.SPATIAL_CONTEXT,
                    world=world,
                    truth=TruthValue(0.95, 0.95),
                    provenance=prov_prop,
                )
                emitted += 1
                if limit is not None and emitted >= limit:
                    return
            else:
                comp_targets = [
                    safe_metta_symbol(t_name).lower()
                    for r_type, _, t_name in term.get("relationship_details", [])
                    if r_type == "part_of" and "membrane" in t_name.lower()
                ]
                if not comp_targets:
                    comp_targets = ["mitochondrial_inner_membrane"]
                for comp in comp_targets[:1]:
                    w_edge = stable_evidence_id("world", "gene_ontology", prop_id, comp)
                    yield PropertyWorldFact(
                        evidence_id=w_edge,
                        edge_id=w_edge,
                        property_id=prop_id,
                        perspective=Perspective.SPATIAL_CONTEXT,
                        world=comp,
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
        cellular_worlds = ["mitochondrial_inner_membrane", "cellular_matrix"]

        count = 0
        for term in self.parse_obo(resolved_path):
            concept = term["name"]
            namespace = term.get("namespace", "")
            meta = {
                "go_id": term["id"],
                "namespace": namespace,
                "def": term.get("def", ""),
                "worlds": cellular_worlds,
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

            if namespace in {"molecular_function", "biological_process"}:
                yield RawRecord(
                    source_id=f"{term['id']}_attr",
                    concept_name=concept,
                    relation=namespace,
                    target_name=concept,
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

        namespace = record.metadata.get("namespace", "")
        relation = record.relation

        if namespace == "cellular_component" or relation == "cellular_component":
            perspective = "structural-composition"
            canonical_rel = "partOf" if relation == "part_of" else "isA"
            strength = 0.95
            confidence = 0.95
        elif namespace == "molecular_function" or relation == "molecular_function":
            perspective = "functional-use"
            canonical_rel = "usedFor"
            strength = 0.90
            confidence = 0.95
        elif namespace == "biological_process" or relation == "biological_process":
            if relation == "regulates":
                perspective = "causal-prerequisite"
                canonical_rel = "causes"
                strength = 0.85
                confidence = 0.90
            else:
                perspective = "behavioral-process"
                canonical_rel = "processOf"
                strength = 0.90
                confidence = 0.95
        else:
            perspective = "descriptive-property"
            canonical_rel = "hasProperty"
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
        edge_id = _edge_id("casl_go", record.concept, record.relation, record.property_or_target)
        stv = (record.strength, record.confidence)

        if record.perspective == "structural-composition":
            facts.append(
                MettaFact(
                    fact_type=FactType.HAS_SORT,
                    expression=f"(has_sort {edge_id} {record.concept} {record.perspective} {record.property_or_target})",
                    stv=stv,
                )
            )
        elif record.perspective == "functional-use":
            op_name = record.property_or_target
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
                    expression=f"(operation_signature {edge_id} (-> ({record.concept}) {op_name}_result))",
                    stv=stv,
                )
            )
        elif record.perspective == "behavioral-process":
            facts.append(
                MettaFact(
                    fact_type=FactType.HAS_PREDICATE,
                    expression=f"(has_predicate {edge_id} {record.concept} {record.perspective} {record.property_or_target})",
                    stv=stv,
                )
            )
        elif record.perspective == "causal-prerequisite":
            axiom_name = f"ax_{record.concept}_{record.property_or_target}"
            facts.append(
                MettaFact(
                    fact_type=FactType.HAS_AXIOM,
                    expression=f"(has_axiom {edge_id} {record.concept} {record.perspective} (axiom {axiom_name} (implies {record.concept} {record.property_or_target})))",
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
        edge_id = _edge_id("pw_go", record.concept, record.perspective, prop_id)

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

        candidate_worlds = [
            "mitochondrial_inner_membrane",
            "cellular_matrix",
            "inner_membrane_complex",
        ]
        for idx, world in enumerate(candidate_worlds[:3]):
            w_edge = _edge_id("world_go", prop_id, world, str(idx))
            facts.append(
                MettaFact(
                    fact_type=FactType.SCOPED_PROPERTY_HOLDS_IN,
                    expression=f"(scoped_property_holds_in {w_edge} {prop_id} {record.perspective} {world})",
                    stv=stv,
                )
            )

        return facts
