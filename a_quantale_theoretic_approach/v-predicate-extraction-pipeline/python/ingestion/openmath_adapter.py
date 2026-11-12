"""OpenMath Source Adapter for formal mathematical definitions, operations, and equational axioms."""

from __future__ import annotations

import hashlib
import re
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any, Dict, Iterator, List, Optional, Union

from .base_adapter import BaseSourceAdapter
from .models import FactType, IngestionProvenance, KnowledgeSource, MettaFact, NormalizedRecord, RawRecord
from .wordnet_adapter import safe_metta_symbol


def _edge_id(prefix: str, *parts: str) -> str:
    """Generate a deterministic, short edge identifier."""
    content = "_".join(str(p) for p in parts)
    digest = hashlib.sha256(content.encode("utf-8")).hexdigest()[:8]
    return f"{prefix}_{digest}"


def _clean_tag(elem: ET.Element) -> str:
    """Strip XML namespace prefix from tag name."""
    return elem.tag.split("}")[-1] if "}" in elem.tag else elem.tag


def _omobj_to_metta(elem: ET.Element) -> str:
    """Recursively translate an OpenMath OMOBJ XML tree into a MeTTa S-expression."""
    tag = _clean_tag(elem)

    if tag == "OMOBJ":
        if len(elem) > 0:
            return _omobj_to_metta(elem[0])
        return "()"

    if tag == "OMBIND":
        # Binding structure: child 0 is binder (e.g. forall), child 1 is OMBVAR, child 2 is body
        if len(elem) >= 3:
            binder = _omobj_to_metta(elem[0])
            bvar_elem = elem[1]
            vars_list = [_omobj_to_metta(v) for v in bvar_elem]
            body = _omobj_to_metta(elem[2])
            return f"({binder} ({' '.join(vars_list)}) {body})"
        elif len(elem) >= 1:
            return _omobj_to_metta(elem[-1])
        return "()"

    if tag == "OMBVAR":
        vars_list = [_omobj_to_metta(v) for v in elem]
        return f"({' '.join(vars_list)})"

    if tag == "OMA":
        if not len(elem):
            return "()"
        op_str = _omobj_to_metta(elem[0])
        args = [_omobj_to_metta(c) for c in elem[1:]]
        return f"({op_str} {' '.join(args)})"

    if tag == "OMS":
        name = elem.get("name", "")
        if name == "eq":
            return "="
        if name == "operation":
            return "*"
        if name == "inverse":
            return "inv"
        if name == "identity":
            return "identity"
        return safe_metta_symbol(name)

    if tag == "OMV":
        var_name = elem.get("name", "x")
        return f"${safe_metta_symbol(var_name)}"

    if tag == "OMI":
        return (elem.text or "0").strip()

    if tag == "OMF":
        return elem.get("dec", "0.0")

    # Fallback for nested children
    children = [_omobj_to_metta(c) for c in elem]
    return f"({' '.join(children)})" if children else safe_metta_symbol(elem.text or tag)


class OpenMathAdapter(BaseSourceAdapter):
    """Adapter for parsing OpenMath 2.0 Content Dictionaries and emitting CASL & Property-World facts."""

    def __init__(self, ocd_path: Optional[Path] = None) -> None:
        self._formula_cache: Dict[str, str] = {}
        if ocd_path is not None:
            self.ocd_path = Path(ocd_path)
        else:
            base_dir = Path(__file__).resolve().parents[2]
            self.ocd_path = base_dir / "fixtures" / "group_theory_sub_openmath.ocd"

    @property
    def source_type(self) -> KnowledgeSource:
        return KnowledgeSource.OPENMATH

    @property
    def provenance(self) -> IngestionProvenance:
        return IngestionProvenance(
            source=KnowledgeSource.OPENMATH,
            source_uri_or_path="https://www.openmath.org/cd/group1.ocd",
            source_version="2026-11",
            license="OpenMath-2.0",
        )

    def fetch(self, download: bool = False, cache_dir: Optional[Path] = None) -> Path:
        cache = cache_dir or Path("kb/raw_sources")
        cached_file = cache / "group1.ocd"

        if cached_file.exists():
            return cached_file

        if download:
            cache.mkdir(parents=True, exist_ok=True)
            import urllib.request

            url = "https://www.openmath.org/cd/group1.ocd"
            req = urllib.request.Request(
                url, headers={"User-Agent": "conceptBlending/1.0 (Linux x86_64)"}
            )
            with urllib.request.urlopen(req) as resp, cached_file.open("wb") as out:
                while chunk := resp.read(65536):
                    out.write(chunk)
            return cached_file

        return self.ocd_path

    def parse_ocd(self, stream_or_path: Union[str, Path]) -> Iterator[Dict[str, Any]]:
        """Parse an OpenMath Content Dictionary XML file and yield symbol definitions."""
        if isinstance(stream_or_path, (str, Path)):
            tree = ET.parse(Path(stream_or_path))
            root = tree.getroot()
        else:
            root = ET.fromstring(stream_or_path)

        for child in root:
            if _clean_tag(child) == "CDDefinition":
                definition: Dict[str, Any] = {
                    "name": "",
                    "role": "",
                    "description": "",
                    "cmp": "",
                    "fmp": None,
                }
                for prop in child:
                    tag = _clean_tag(prop)
                    if tag == "Name":
                        definition["name"] = (prop.text or "").strip()
                    elif tag == "Role":
                        definition["role"] = (prop.text or "").strip()
                    elif tag == "Description":
                        definition["description"] = (prop.text or "").strip()
                    elif tag == "CMP":
                        definition["cmp"] = (prop.text or "").strip()
                    elif tag == "FMP":
                        # Look for OMOBJ inside FMP
                        omobj = next((sub for sub in prop if _clean_tag(sub) == "OMOBJ"), None)
                        if omobj is not None:
                            definition["fmp"] = _omobj_to_metta(omobj)

                if definition["name"]:
                    yield definition

    def extract_raw_records(self, limit: Optional[int] = None) -> Iterator[RawRecord]:
        """Stream raw mathematical records from parsed OpenMath definitions."""
        definitions = list(self.parse_ocd(self.ocd_path))
        candidate_worlds = [
            "integers_under_addition",
            "abelian_group",
            "cyclic_group_z_n",
            "rotation_group_so2",
        ]

        count = 0
        concept = "group"

        for defn in definitions:
            name = defn["name"]
            role = defn.get("role", "")
            desc = defn.get("description", "")
            cmp_text = defn.get("cmp", "")
            fmp_formula = defn.get("fmp")

            meta = {
                "role": role,
                "description": desc,
                "cmp": cmp_text,
                "worlds": candidate_worlds,
            }
            if fmp_formula:
                meta["formula"] = fmp_formula
                self._formula_cache[name] = fmp_formula
                self._formula_cache[safe_metta_symbol(name)] = fmp_formula

            # 1. Structural/Taxonomic sort (constructors or carrier types)
            if role == "constructor" or name in {"group", "abelian_group", "carrier", "element"}:
                yield RawRecord(
                    source_id=f"om_sort_{name}",
                    concept_name=concept,
                    relation="has_sort",
                    target_name=name,
                    weight=1.0,
                    metadata=meta,
                    provenance=self.provenance,
                )
                count += 1
                if limit and count >= limit:
                    return

            # 2. Algebraic Operations
            if role == "application" or name in {"operation", "inverse", "identity"}:
                yield RawRecord(
                    source_id=f"om_op_{name}",
                    concept_name=concept,
                    relation="has_operation",
                    target_name=name,
                    weight=1.0,
                    metadata=meta,
                    provenance=self.provenance,
                )
                count += 1
                if limit and count >= limit:
                    return

            # 3. Structural Properties / Predicates
            if role == "predicate" or name.startswith("is_"):
                yield RawRecord(
                    source_id=f"om_pred_{name}",
                    concept_name=concept,
                    relation="has_predicate",
                    target_name=name,
                    weight=1.0,
                    metadata=meta,
                    provenance=self.provenance,
                )
                count += 1
                if limit and count >= limit:
                    return

            # 4. Formal Equational Axioms from FMP
            if fmp_formula:
                yield RawRecord(
                    source_id=f"om_ax_{name}",
                    concept_name=concept,
                    relation="has_axiom",
                    target_name=name,
                    weight=1.0,
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

        if relation == "has_sort":
            perspective = "taxonomic-classification"
            canonical_rel = "isA"
        elif relation == "has_operation":
            perspective = "structural-composition"
            canonical_rel = "hasOperation"
        elif relation == "has_predicate":
            perspective = "quantitative-comparative"
            canonical_rel = "satisfiesProperty"
        elif relation == "has_axiom":
            perspective = "structural-composition"
            canonical_rel = "satisfiesAxiom"
        else:
            perspective = "quantitative-comparative"
            canonical_rel = safe_metta_symbol(relation)

        return NormalizedRecord(
            concept=concept_sym,
            property_or_target=target_sym,
            relation=canonical_rel,
            perspective=perspective,
            strength=1.0,
            confidence=1.0,
            provenance=record.provenance or self.provenance,
        )

    def transform_to_casl(self, record: NormalizedRecord) -> List[MettaFact]:
        facts: List[MettaFact] = []
        edge_id = _edge_id("casl_om", record.concept, record.relation, record.property_or_target)
        stv = (record.strength, record.confidence)

        if record.perspective == "taxonomic-classification":
            facts.append(
                MettaFact(
                    fact_type=FactType.HAS_SORT,
                    expression=f"(has_sort {edge_id} {record.concept} {record.perspective} {record.property_or_target})",
                    stv=stv,
                )
            )
        elif record.perspective == "structural-composition" and record.relation == "hasOperation":
            op_name = record.property_or_target
            facts.append(
                MettaFact(
                    fact_type=FactType.HAS_OPERATION,
                    expression=f"(has_operation {edge_id} {record.concept} {record.perspective} {op_name})",
                    stv=stv,
                )
            )
            # Differentiate binary vs unary vs constant signatures
            if op_name in {"operation", "mult", "binary_op"}:
                sig = f"(-> ({record.concept} {record.concept}) {record.concept})"
            elif op_name in {"inverse", "inv"}:
                sig = f"(-> ({record.concept}) {record.concept})"
            else:
                sig = f"(-> () {record.concept})"

            facts.append(
                MettaFact(
                    fact_type=FactType.OPERATION_SIGNATURE,
                    expression=f"(operation_signature {edge_id} {sig})",
                    stv=stv,
                )
            )
        elif record.perspective == "structural-composition" and record.relation == "satisfiesAxiom":
            raw_target = record.property_or_target
            # Prefer extracted FMP formula from OpenMath XML if available
            formula = self._formula_cache.get(raw_target)
            if not formula:
                if "associative" in raw_target:
                    formula = "(= (* (* $a $b) $c) (* $a (* $b $c)))"
                elif "abelian" in raw_target:
                    formula = "(= (* $a $b) (* $b $a))"
                elif "identity" in raw_target:
                    formula = "(= (* $x identity) $x)"
                elif "inverse" in raw_target:
                    formula = "(= (* $x (inv $x)) identity)"
                else:
                    formula = f"(= ({raw_target} $x) $x)"

            axiom_name = f"ax_{raw_target}"
            facts.append(
                MettaFact(
                    fact_type=FactType.HAS_AXIOM,
                    expression=f"(has_axiom {edge_id} {record.concept} {record.perspective} (axiom {axiom_name} {formula}))",
                    stv=stv,
                )
            )
        elif record.perspective == "quantitative-comparative":
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
        edge_id = _edge_id("pw_om", record.concept, record.perspective, prop_id)

        # 1. Concept-Property assertion
        facts.append(
            MettaFact(
                fact_type=FactType.HAS_SCOPED_PROPERTY,
                expression=f"(has_scoped_property {edge_id} {record.concept} {record.perspective} {prop_id} {record.property_or_target})",
                stv=stv,
            )
        )

        # 2. Perspective Match assertion (arity 3 matching MeTTa rule contracts)
        facts.append(
            MettaFact(
                fact_type=FactType.PERSPECTIVE_MATCH,
                expression=f"(perspective_match {record.perspective} {record.perspective} exact-perspective)",
                stv=(1.0, 1.0),
            )
        )

        # 3. Possible Worlds assertions (mathematical structures / spaces)
        candidate_worlds = [
            "integers_under_addition",
            "abelian_group",
            "cyclic_group_z_n",
            "rotation_group_so2",
            "permutation_group_s_n",
        ]
        for idx, world in enumerate(candidate_worlds):
            w_edge = _edge_id("world_om", prop_id, world, str(idx))
            facts.append(
                MettaFact(
                    fact_type=FactType.SCOPED_PROPERTY_HOLDS_IN,
                    expression=f"(scoped_property_holds_in {w_edge} {prop_id} {record.perspective} {world})",
                    stv=stv,
                )
            )

        return facts

