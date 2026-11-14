"""WordNet Source Adapter for lexical taxonomy, meronymy, and property extraction."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path
from typing import Any, Dict, Iterator, List, Optional, Set, Tuple

from .base_adapter import BaseSourceAdapter
from .models import FactType, IngestionProvenance, KnowledgeSource, MettaFact, NormalizedRecord, RawRecord
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


def safe_metta_symbol(token: str) -> str:
    """Sanitize any arbitrary string into a valid, balanced MeTTa identifier."""
    if not token or not token.strip():
        return "c_empty"

    text = token.strip()
    if text.startswith("'") and text.endswith("'"):
        text = text[1:-1]

    # Replace parenthesized content or punctuation
    text = re.sub(r"[\(\)\[\]\{\}\"']", "", text)
    text = re.sub(r"[\s\-\./\\]+", "_", text)
    text = re.sub(r"[^A-Za-z0-9_]", "_", text)
    text = re.sub(r"_+", "_", text).strip("_")

    if not text:
        return "c_empty"

    # Must start with a letter or underscore
    if not re.match(r"^[A-Za-z_]", text):
        text = f"c_{text}"

    return text


def _edge_id(prefix: str, *parts: str) -> str:
    """Generate a deterministic, short edge identifier."""
    content = "_".join(str(p) for p in parts)
    digest = hashlib.sha256(content.encode("utf-8")).hexdigest()[:8]
    return f"{prefix}_{digest}"


# Bundled offline lexical knowledge base providing deterministic, network-free
# access for common commonsense and hardware concepts.
OFFLINE_LEXICON: Dict[str, Dict[str, Any]] = {
    "phone": {
        "hypernyms": ["electronic_equipment", "communicator", "device"],
        "part_meronyms": ["dial", "mouthpiece", "transceiver", "battery", "display"],
        "gloss_attributes": ["transmit_voice", "convert_sound", "telecommunication"],
        "worlds": ["cellphone", "landline", "smartphone", "office", "home"],
    },
    "computer": {
        "hypernyms": ["machine", "electronic_equipment", "device"],
        "part_meronyms": ["processor", "memory", "keyboard", "display"],
        "gloss_attributes": ["process_data", "store_information", "compute"],
        "worlds": ["laptop", "desktop", "server", "workstation"],
    },
    "battery": {
        "hypernyms": ["power_source", "device", "energy_accumulator"],
        "part_meronyms": ["cell", "electrode", "electrolyte", "terminal"],
        "gloss_attributes": ["store_energy", "supply_electricity", "portable_power"],
        "worlds": ["cellphone", "laptop", "flashlight", "electric_vehicle"],
    },
    "display": {
        "hypernyms": ["electronic_device", "interface"],
        "part_meronyms": ["screen", "pixel", "backlight"],
        "gloss_attributes": ["render_image", "visual_output"],
        "worlds": ["phone", "computer", "television"],
    },
}


class WordNetAdapter(BaseSourceAdapter):
    """Extracts lexical taxonomy, compositional meronyms, and gloss properties from WordNet."""

    def __init__(
        self,
        max_props_per_concept: int = 10,
        max_worlds_per_prop: int = 5,
        use_nltk: bool = True,
        full_traversal: bool = False,
        cache_dir: Optional[Path] = None,
    ) -> None:
        self.max_props_per_concept = max_props_per_concept
        self.max_worlds_per_prop = max_worlds_per_prop
        self.use_nltk = use_nltk
        self.full_traversal = full_traversal
        self.cache_dir = (
            cache_dir.resolve()
            if cache_dir
            else (PIPELINE_ROOT / "data" / "cache" / "wordnet").resolve()
        )
        self.source_name = "wordnet"
        self.version = "3.1"
        self.license = "WordNet-3.0"
        self.transformation = "wordnet_adapter_v1"
        self._wn: Any = None
        if self.use_nltk:
            self._try_init_nltk()
        self.source_uri = "nltk://wordnet-3.1" if self._wn else "bundled://wordnet_offline"

    def _try_init_nltk(self) -> None:
        try:
            import nltk
            from nltk.corpus import wordnet as wn
            # Check if synsets method is callable and corpus is available
            wn.synsets("phone")
            self._wn = wn
        except Exception:
            self._wn = None

    @property
    def source_type(self) -> KnowledgeSource:
        return KnowledgeSource.WORDNET

    @property
    def provenance(self) -> IngestionProvenance:
        return IngestionProvenance(
            source=KnowledgeSource.WORDNET,
            source_uri_or_path="nltk://wordnet-3.1" if self._wn else "bundled://wordnet_offline",
            source_version="3.1",
            license="WordNet-3.0",
        )

    def fetch(self, download: bool = False, cache_dir: Optional[Path] = None) -> Path:
        target_dir = cache_dir.resolve() if cache_dir else self.cache_dir
        target_dir.mkdir(parents=True, exist_ok=True)
        local_marker = target_dir / "wordnet_ready.txt"
        if not local_marker.exists():
            local_marker.write_text("WordNet adapter initialized.\n", encoding="utf-8")
        return local_marker

    def stream_facts(self, limit: Optional[int] = None) -> Iterator[FactRecord]:
        """Stream canonical typed V-predicate fact records under v-predicate/1."""
        self.fetch(download=False)
        emitted_count = 0

        # Determine concepts stream
        concepts_to_process: Iterator[str]
        if self.full_traversal and self._wn is not None:
            def _synset_concepts() -> Iterator[str]:
                seen: Set[str] = set()
                for syn in self._wn.all_synsets(pos=self._wn.NOUN):
                    name = safe_metta_symbol(syn.lemmas()[0].name())
                    if name not in seen:
                        seen.add(name)
                        yield name
            concepts_to_process = _synset_concepts()
        else:
            concepts_to_process = iter(OFFLINE_LEXICON.keys())

        for concept in concepts_to_process:
            c_sym = safe_metta_symbol(concept)
            if not c_sym:
                continue

            # Check if NLTK synset available
            if self._wn is not None and self.use_nltk:
                synsets = self._wn.synsets(concept, pos=self._wn.NOUN)
            else:
                synsets = []

            if synsets:
                primary_syn = synsets[0]
                # 1. Hypernyms -> SortFact (taxonomic_kind)
                for h in primary_syn.hypernyms()[: self.max_props_per_concept]:
                    h_sym = safe_metta_symbol(h.lemmas()[0].name())
                    edge_id = stable_evidence_id("sort", "wordnet", c_sym, h_sym)
                    prov = Provenance(
                        source="wordnet",
                        source_record_id=f"{c_sym}_{h_sym}",
                        source_uri="nltk://wordnet-3.1",
                        source_version="3.1",
                        license="WordNet-3.0",
                        transformation="wordnet_adapter_v1",
                        origin=FactOrigin.ASSERTED,
                    )
                    yield SortFact(
                        evidence_id=edge_id,
                        edge_id=edge_id,
                        concept=c_sym,
                        perspective=Perspective.TAXONOMIC_KIND,
                        sort=h_sym,
                        truth=TruthValue(0.95, 0.90),
                        provenance=prov,
                    )
                    emitted_count += 1
                    if limit is not None and emitted_count >= limit:
                        return

                # 2. Meronyms -> PredicateFact (structural_composition)
                for m in primary_syn.part_meronyms()[: self.max_props_per_concept]:
                    m_sym = safe_metta_symbol(m.lemmas()[0].name())
                    edge_id = stable_evidence_id("predicate", "wordnet", c_sym, "part_of", m_sym)
                    prov = Provenance(
                        source="wordnet",
                        source_record_id=f"{c_sym}_part_{m_sym}",
                        source_uri="nltk://wordnet-3.1",
                        source_version="3.1",
                        license="WordNet-3.0",
                        transformation="wordnet_adapter_v1",
                        origin=FactOrigin.ASSERTED,
                    )
                    yield PredicateFact(
                        evidence_id=edge_id,
                        edge_id=edge_id,
                        concept=c_sym,
                        perspective=Perspective.STRUCTURAL_COMPOSITION,
                        predicate=f"(part_of {m_sym} {c_sym})",
                        truth=TruthValue(0.90, 0.85),
                        provenance=prov,
                    )
                    emitted_count += 1
                    if limit is not None and emitted_count >= limit:
                        return

                # 3. Functional properties and worlds
                hyponyms = primary_syn.hyponyms()
                source_worlds = [
                    safe_metta_symbol(hyp.lemmas()[0].name())
                    for hyp in hyponyms[: self.max_worlds_per_prop]
                ]
                gloss_words = re.findall(r"\b[A-Za-z]{4,}\b", primary_syn.definition())
                heuristic_props = [safe_metta_symbol(gw) for gw in gloss_words[:3]]

                for prop in heuristic_props:
                    prop_id = stable_evidence_id("prop", "wordnet", c_sym, prop)
                    edge_id = stable_evidence_id("property", "wordnet", c_sym, prop)
                    prov = Provenance(
                        source="wordnet",
                        source_record_id=f"{c_sym}_{prop}",
                        source_uri="nltk://wordnet-3.1",
                        source_version="3.1",
                        license="WordNet-3.0",
                        transformation="wordnet_adapter_v1",
                        origin=FactOrigin.ASSERTED,
                    )
                    yield PropertyFact(
                        evidence_id=edge_id,
                        edge_id=edge_id,
                        concept=c_sym,
                        perspective=Perspective.FUNCTIONAL_USE,
                        property_id=prop_id,
                        property_name=prop,
                        truth=TruthValue(0.85, 0.80),
                        provenance=prov,
                    )
                    emitted_count += 1
                    if limit is not None and emitted_count >= limit:
                        return

                    for sw in source_worlds:
                        w_edge = stable_evidence_id("world", "wordnet", prop_id, sw)
                        w_prov = Provenance(
                            source="wordnet",
                            source_record_id=f"{prop_id}_{sw}",
                            source_uri="nltk://wordnet-3.1",
                            source_version="3.1",
                            license="WordNet-3.0",
                            transformation="wordnet_adapter_v1",
                            origin=FactOrigin.ASSERTED,
                        )
                        yield PropertyWorldFact(
                            evidence_id=w_edge,
                            edge_id=w_edge,
                            property_id=prop_id,
                            perspective=Perspective.FUNCTIONAL_USE,
                            world=sw,
                            truth=TruthValue(0.85, 0.85),
                            provenance=w_prov,
                        )
                        emitted_count += 1
                        if limit is not None and emitted_count >= limit:
                            return

                    # Heuristic generated world
                    h_world = f"{c_sym}_world"
                    h_edge = stable_evidence_id("world", "wordnet", prop_id, h_world)
                    h_prov = Provenance(
                        source="wordnet",
                        source_record_id=f"{prop_id}_{h_world}",
                        source_uri="nltk://wordnet-3.1",
                        source_version="3.1",
                        license="WordNet-3.0",
                        transformation="wordnet_heuristic_world_projection",
                        origin=FactOrigin.GENERATED,
                    )
                    yield PropertyWorldFact(
                        evidence_id=h_edge,
                        edge_id=h_edge,
                        property_id=prop_id,
                        perspective=Perspective.FUNCTIONAL_USE,
                        world=h_world,
                        truth=TruthValue(0.70, 0.65),
                        provenance=h_prov,
                    )
                    emitted_count += 1
                    if limit is not None and emitted_count >= limit:
                        return

            else:
                # Fallback to bundled OFFLINE_LEXICON
                lex_data = OFFLINE_LEXICON.get(concept, {})
                for h in lex_data.get("hypernyms", [])[: self.max_props_per_concept]:
                    h_sym = safe_metta_symbol(h)
                    edge_id = stable_evidence_id("sort", "wordnet", c_sym, h_sym)
                    prov = Provenance(
                        source="wordnet",
                        source_record_id=f"{c_sym}_{h_sym}",
                        source_uri="bundled://wordnet_offline",
                        source_version="3.1",
                        license="WordNet-3.0",
                        transformation="wordnet_adapter_v1",
                        origin=FactOrigin.ASSERTED,
                    )
                    yield SortFact(
                        evidence_id=edge_id,
                        edge_id=edge_id,
                        concept=c_sym,
                        perspective=Perspective.TAXONOMIC_KIND,
                        sort=h_sym,
                        truth=TruthValue(0.95, 0.90),
                        provenance=prov,
                    )
                    emitted_count += 1
                    if limit is not None and emitted_count >= limit:
                        return

                for m in lex_data.get("part_meronyms", [])[: self.max_props_per_concept]:
                    m_sym = safe_metta_symbol(m)
                    edge_id = stable_evidence_id("predicate", "wordnet", c_sym, "part_of", m_sym)
                    prov = Provenance(
                        source="wordnet",
                        source_record_id=f"{c_sym}_part_{m_sym}",
                        source_uri="bundled://wordnet_offline",
                        source_version="3.1",
                        license="WordNet-3.0",
                        transformation="wordnet_adapter_v1",
                        origin=FactOrigin.ASSERTED,
                    )
                    yield PredicateFact(
                        evidence_id=edge_id,
                        edge_id=edge_id,
                        concept=c_sym,
                        perspective=Perspective.STRUCTURAL_COMPOSITION,
                        predicate=f"(part_of {m_sym} {c_sym})",
                        truth=TruthValue(0.90, 0.85),
                        provenance=prov,
                    )
                    emitted_count += 1
                    if limit is not None and emitted_count >= limit:
                        return

                lex_worlds = [safe_metta_symbol(w) for w in lex_data.get("worlds", [])[: self.max_worlds_per_prop]]
                for g in lex_data.get("gloss_attributes", [])[: self.max_props_per_concept]:
                    g_sym = safe_metta_symbol(g)
                    prop_id = stable_evidence_id("prop", "wordnet", c_sym, g_sym)
                    edge_id = stable_evidence_id("property", "wordnet", c_sym, g_sym)
                    prov = Provenance(
                        source="wordnet",
                        source_record_id=f"{c_sym}_{g_sym}",
                        source_uri="bundled://wordnet_offline",
                        source_version="3.1",
                        license="WordNet-3.0",
                        transformation="wordnet_adapter_v1",
                        origin=FactOrigin.ASSERTED,
                    )
                    yield PropertyFact(
                        evidence_id=edge_id,
                        edge_id=edge_id,
                        concept=c_sym,
                        perspective=Perspective.FUNCTIONAL_USE,
                        property_id=prop_id,
                        property_name=g_sym,
                        truth=TruthValue(0.85, 0.80),
                        provenance=prov,
                    )
                    emitted_count += 1
                    if limit is not None and emitted_count >= limit:
                        return

                    for lw in lex_worlds:
                        w_edge = stable_evidence_id("world", "wordnet", prop_id, lw)
                        w_prov = Provenance(
                            source="wordnet",
                            source_record_id=f"{prop_id}_{lw}",
                            source_uri="bundled://wordnet_offline",
                            source_version="3.1",
                            license="WordNet-3.0",
                            transformation="wordnet_adapter_v1",
                            origin=FactOrigin.ASSERTED,
                        )
                        yield PropertyWorldFact(
                            evidence_id=w_edge,
                            edge_id=w_edge,
                            property_id=prop_id,
                            perspective=Perspective.FUNCTIONAL_USE,
                            world=lw,
                            truth=TruthValue(0.85, 0.80),
                            provenance=w_prov,
                        )
                        emitted_count += 1
                        if limit is not None and emitted_count >= limit:
                            return

                    # Heuristic generated world
                    h_world = f"{c_sym}_heuristic_world"
                    h_edge = stable_evidence_id("world", "wordnet", prop_id, h_world)
                    h_prov = Provenance(
                        source="wordnet",
                        source_record_id=f"{prop_id}_{h_world}",
                        source_uri="bundled://wordnet_offline",
                        source_version="3.1",
                        license="WordNet-3.0",
                        transformation="wordnet_heuristic_world_projection",
                        origin=FactOrigin.GENERATED,
                    )
                    yield PropertyWorldFact(
                        evidence_id=h_edge,
                        edge_id=h_edge,
                        property_id=prop_id,
                        perspective=Perspective.FUNCTIONAL_USE,
                        world=h_world,
                        truth=TruthValue(0.70, 0.65),
                        provenance=h_prov,
                    )
                    emitted_count += 1
                    if limit is not None and emitted_count >= limit:
                        return

    def extract_raw_records(self, limit: Optional[int] = None) -> Iterator[RawRecord]:
        count = 0
        for concept in OFFLINE_LEXICON:
            for record in self.extract_concept_records(concept):
                yield record
                count += 1
                if limit and count >= limit:
                    return

    def extract_concept_records(self, concept: str) -> Iterator[RawRecord]:
        """Extract lexical properties for a given concept string."""
        concept_clean = concept.strip().lower()

        if self._wn is not None:
            yield from self._extract_nltk_records(concept_clean)
        else:
            yield from self._extract_offline_records(concept_clean)

    def _extract_offline_records(self, concept: str) -> Iterator[RawRecord]:
        data = OFFLINE_LEXICON.get(concept)
        if not data:
            # Fallback for arbitrary words: generate base hypernym and property
            yield RawRecord(
                source_id=f"{concept}.n.01",
                concept_name=concept,
                relation="hypernym",
                target_name="entity",
                weight=1.0,
                metadata={"worlds": ["physical_world", "domain_context"]},
                provenance=self.provenance,
            )
            return

        emitted = 0
        worlds = data.get("worlds", [])[: self.max_worlds_per_prop]

        # 1. Hypernyms
        for h in data.get("hypernyms", []):
            if emitted >= self.max_props_per_concept:
                return
            yield RawRecord(
                source_id=f"{concept}.hypernym.{h}",
                concept_name=concept,
                relation="hypernym",
                target_name=h,
                weight=0.95,
                metadata={"worlds": worlds},
                provenance=self.provenance,
            )
            emitted += 1

        # 2. Part Meronyms
        for m in data.get("part_meronyms", []):
            if emitted >= self.max_props_per_concept:
                return
            yield RawRecord(
                source_id=f"{concept}.part_meronym.{m}",
                concept_name=concept,
                relation="part_meronym",
                target_name=m,
                weight=0.90,
                metadata={"worlds": worlds},
                provenance=self.provenance,
            )
            emitted += 1

        # 3. Gloss Attributes
        for g in data.get("gloss_attributes", []):
            if emitted >= self.max_props_per_concept:
                return
            yield RawRecord(
                source_id=f"{concept}.gloss_attribute.{g}",
                concept_name=concept,
                relation="gloss_attribute",
                target_name=g,
                weight=0.85,
                metadata={"worlds": worlds},
                provenance=self.provenance,
            )
            emitted += 1

    def _extract_nltk_records(self, concept: str) -> Iterator[RawRecord]:
        synsets = self._wn.synsets(concept, pos=self._wn.NOUN)
        if not synsets:
            yield from self._extract_offline_records(concept)
            return

        primary_syn = synsets[0]
        emitted = 0

        # Worlds from hyponyms
        hyponyms = primary_syn.hyponyms()
        worlds = [
            safe_metta_symbol(h.lemmas()[0].name())
            for h in hyponyms[: self.max_worlds_per_prop]
        ]
        if not worlds:
            worlds = [safe_metta_symbol(concept)]

        # Hypernyms
        for h in primary_syn.hypernyms():
            if emitted >= self.max_props_per_concept:
                return
            target = safe_metta_symbol(h.lemmas()[0].name())
            yield RawRecord(
                source_id=h.name(),
                concept_name=concept,
                relation="hypernym",
                target_name=target,
                weight=0.95,
                metadata={"worlds": worlds, "gloss": h.definition()},
                provenance=self.provenance,
            )
            emitted += 1

        # Part Meronyms
        for m in primary_syn.part_meronyms():
            if emitted >= self.max_props_per_concept:
                return
            target = safe_metta_symbol(m.lemmas()[0].name())
            yield RawRecord(
                source_id=m.name(),
                concept_name=concept,
                relation="part_meronym",
                target_name=target,
                weight=0.90,
                metadata={"worlds": worlds},
                provenance=self.provenance,
            )
            emitted += 1

        # Gloss words as functional attributes
        gloss_words = re.findall(r"\b[A-Za-z]{4,}\b", primary_syn.definition())
        for gw in gloss_words[:3]:
            if emitted >= self.max_props_per_concept:
                return
            yield RawRecord(
                source_id=f"{primary_syn.name()}.gloss.{gw}",
                concept_name=concept,
                relation="gloss_attribute",
                target_name=safe_metta_symbol(gw),
                weight=0.80,
                metadata={"worlds": worlds},
                provenance=self.provenance,
            )
            emitted += 1

    def normalize_record(self, record: RawRecord) -> Optional[NormalizedRecord]:
        concept_sym = safe_metta_symbol(record.concept_name)
        target_sym = safe_metta_symbol(record.target_name)

        if not concept_sym or not target_sym:
            return None

        # Determine canonical perspective and relation
        if record.relation in {"hypernym", "isA"}:
            perspective = "taxonomic-kind"
            relation = "isA"
            strength = min(max(record.weight, 0.1), 1.0)
            confidence = 0.90
        elif record.relation in {"part_meronym", "member_meronym", "substance_meronym", "partOf"}:
            perspective = "structural-composition"
            relation = "partOf"
            strength = min(max(record.weight, 0.1), 1.0)
            confidence = 0.85
        elif record.relation in {"gloss_attribute", "capableOf", "usedFor"}:
            perspective = "functional-use"
            relation = "usedFor"
            strength = min(max(record.weight, 0.1), 1.0)
            confidence = 0.80
        else:
            perspective = "descriptive-property"
            relation = "hasProperty"
            strength = min(max(record.weight, 0.1), 1.0)
            confidence = 0.75

        return NormalizedRecord(
            concept=concept_sym,
            property_or_target=target_sym,
            relation=relation,
            perspective=perspective,
            strength=strength,
            confidence=confidence,
            provenance=record.provenance or self.provenance,
        )

    def transform_to_casl(self, record: NormalizedRecord) -> List[MettaFact]:
        facts: List[MettaFact] = []
        edge_id = _edge_id("casl", record.concept, record.relation, record.property_or_target)
        stv = (record.strength, record.confidence)

        if record.perspective == "taxonomic-kind":
            facts.append(
                MettaFact(
                    fact_type=FactType.HAS_SORT,
                    expression=f"(has_sort {edge_id} {record.concept} {record.perspective} {record.property_or_target})",
                    stv=stv,
                )
            )
        elif record.perspective == "structural-composition":
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
            # operation_signature shares the same edge_id as has_operation for MeTTa spec-operation-rule unification
            facts.append(
                MettaFact(
                    fact_type=FactType.OPERATION_SIGNATURE,
                    expression=f"(operation_signature {edge_id} (-> ({record.concept}) {op_name}_result))",
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
        edge_id = _edge_id("pw", record.concept, record.perspective, prop_id)

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

        # 3. Worlds relevance
        # Retrieve candidate worlds from lexicon or concept context
        raw_concept = record.concept
        worlds_pool: List[str] = []
        if raw_concept in OFFLINE_LEXICON:
            worlds_pool = [
                safe_metta_symbol(w)
                for w in OFFLINE_LEXICON[raw_concept].get("worlds", [])
            ]
        if not worlds_pool:
            worlds_pool = [record.concept, f"{record.concept}_domain"]

        for idx, w in enumerate(worlds_pool[: self.max_worlds_per_prop]):
            w_edge = _edge_id("world", prop_id, w, str(idx))
            facts.append(
                MettaFact(
                    fact_type=FactType.SCOPED_PROPERTY_HOLDS_IN,
                    expression=f"(scoped_property_holds_in {w_edge} {prop_id} {record.perspective} {w})",
                    stv=stv,
                )
            )

        return facts

