"""ConceptNet 5th knowledge source adapter producing canonical v-predicate/1 records."""

from __future__ import annotations

import gzip
import json
import logging
from pathlib import Path
import re
from typing import Iterator, Optional, Set, Tuple
import zlib

from .acquisition import (
    ProvenanceType,
    SourceArtifact,
)
from .base_adapter import BaseSourceAdapter
from v_predicate_contract import (
    FactOrigin,
    FactRecord,
    Perspective,
    PredicateFact,
    PropertyFact,
    Provenance,
    SortFact,
    TruthValue,
    stable_evidence_id,
)

logger = logging.getLogger(__name__)

PIPELINE_ROOT = Path(__file__).resolve().parents[2]
_SYMBOL_CLEANER = re.compile(r"[^A-Za-z0-9_]")


def _sanitize_symbol(raw: str) -> str:
    """Normalize raw concept labels or relation names into canonical MeTTa symbols."""
    cleaned = raw.strip()
    if cleaned.startswith("/c/"):
        # Strip language prefix e.g. /c/en/
        parts = cleaned.split("/")
        if len(parts) > 3:
            cleaned = parts[3]
        elif len(parts) == 3:
            cleaned = parts[2]
        else:
            cleaned = cleaned.lstrip("/c/")
    elif cleaned.startswith("/r/"):
        cleaned = cleaned[len("/r/"):]

    # Remove trailing language or POS tags like /n, /v
    if "/" in cleaned:
        cleaned = cleaned.split("/")[0]

    # Replace spaces and hyphens with underscores
    cleaned = cleaned.replace(" ", "_").replace("-", "_")
    cleaned = _SYMBOL_CLEANER.sub("", cleaned).lower().strip("_")

    if not cleaned:
        cleaned = "unknown"
    if cleaned[0].isdigit():
        cleaned = f"n_{cleaned}"
    return cleaned


def _extract_language(concept_uri: str) -> Optional[str]:
    """Extract language code from ConceptNet concept URI (e.g. '/c/en/dog' -> 'en')."""
    if concept_uri.startswith("/c/"):
        parts = concept_uri.split("/")
        if len(parts) > 2 and parts[2]:
            return parts[2].lower()
    return None


def _check_language(concept_uri: str, allowed_languages: Set[str]) -> bool:
    """Check if concept matches allowed languages. Fixture bare concepts match by default."""
    lang = _extract_language(concept_uri)
    if lang is not None:
        return lang in allowed_languages
    return True


class ConceptNetAdapter(BaseSourceAdapter):
    """Adapter for ConceptNet commonsense assertions under the v-predicate/1 contract."""

    def __init__(
        self,
        fixture_path: Optional[Path] = None,
        cache_dir: Optional[Path] = None,
        languages: Optional[Set[str]] = None,
        relations: Optional[Set[str]] = None,
        concepts: Optional[Set[str]] = None,
    ) -> None:
        self.fixture_path = (
            fixture_path.resolve()
            if fixture_path
            else (PIPELINE_ROOT / "fixtures" / "conceptnet_sub.json").resolve()
        )
        self.cache_dir = (
            cache_dir.resolve()
            if cache_dir
            else (PIPELINE_ROOT / "data" / "cache" / "conceptnet").resolve()
        )
        self.languages = set(languages) if languages is not None else {"en"}
        self.relations = set(relations) if relations is not None else None
        self.concepts = set(concepts) if concepts is not None else None

        self.source_name = "conceptnet"
        self.version = "5.7.0"
        self.license = "CC-BY-SA-4.0"
        self.transformation = "conceptnet_adapter_v1"
        self.source_uri = "https://s3.amazonaws.com/conceptnet/downloads/2019/edges/conceptnet-assertions-5.7.0.csv.gz"
        self.target_filename = "conceptnet-assertions-5.7.0.csv.gz"

    def fetch_artifact(
        self,
        download: bool = False,
        cache_dir: Optional[Path] = None,
        force_refresh: bool = False,
    ) -> SourceArtifact:
        """Acquire ConceptNet assertion dataset using the unified acquisition engine."""
        cache = cache_dir.resolve() if cache_dir else self.cache_dir
        cache.mkdir(parents=True, exist_ok=True)

        artifact = self.acquisition_engine.acquire(
            source_key="conceptnet",
            source_uri=self.source_uri,
            target_filename=self.target_filename,
            cache_dir=cache,
            download=download,
            force_refresh=force_refresh,
            fixture_path=self.fixture_path,
            version=self.version,
            license_str=self.license,
        )
        self.last_artifact = artifact
        return artifact

    def fetch(self, download: bool = False, cache_dir: Optional[Path] = None) -> Path:
        """Locate or retrieve raw ConceptNet file path (backward compatible wrapper)."""
        return self.fetch_artifact(download=download, cache_dir=cache_dir).local_path

    def _stream_raw_entries(self, source_file: Path) -> Iterator[Tuple[str, str, str, float]]:
        """Stream raw (rel_raw, start_raw, end_raw, weight) tuples from source file."""
        if str(source_file).endswith(".gz"):
            try:
                with gzip.open(source_file, "rt", encoding="utf-8", errors="replace") as f:
                    for line in f:
                        line = line.strip()
                        if not line or line.startswith("#"):
                            continue
                        parts = line.split("\t")
                        if len(parts) < 4:
                            continue
                        rel_raw = parts[1]
                        start_raw = parts[2]
                        end_raw = parts[3]
                        meta_raw = parts[4] if len(parts) > 4 else "{}"

                        weight = 1.0
                        if meta_raw:
                            try:
                                meta = json.loads(meta_raw)
                                if isinstance(meta, dict):
                                    weight = float(meta.get("weight", 1.0))
                                elif isinstance(meta, (int, float)):
                                    weight = float(meta)
                            except Exception:
                                try:
                                    weight = float(meta_raw)
                                except Exception:
                                    weight = 1.0

                        yield rel_raw, start_raw, end_raw, weight
            except (gzip.BadGzipFile, EOFError, zlib.error) as err:
                logger.error("Corrupted compressed ConceptNet archive at %s: %s", source_file, err)
                raise ValueError(f"Corrupted compressed ConceptNet archive at {source_file}: {err}") from err

        elif str(source_file).endswith(".json"):
            with open(source_file, "r", encoding="utf-8") as f:
                data = json.load(f)
            edges = data.get("edges", [])
            for edge in edges:
                rel_raw = edge.get("relation", "")
                start_raw = edge.get("start", "")
                end_raw = edge.get("end", "")
                weight = float(edge.get("weight", 1.0))
                yield rel_raw, start_raw, end_raw, weight
        else:
            with open(source_file, "r", encoding="utf-8", errors="replace") as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#"):
                        continue
                    parts = line.split("\t")
                    if len(parts) < 4:
                        continue
                    rel_raw = parts[1]
                    start_raw = parts[2]
                    end_raw = parts[3]
                    meta_raw = parts[4] if len(parts) > 4 else "{}"
                    weight = 1.0
                    if meta_raw:
                        try:
                            meta = json.loads(meta_raw)
                            if isinstance(meta, dict):
                                weight = float(meta.get("weight", 1.0))
                            elif isinstance(meta, (int, float)):
                                weight = float(meta)
                        except Exception:
                            try:
                                weight = float(meta_raw)
                            except Exception:
                                weight = 1.0
                    yield rel_raw, start_raw, end_raw, weight

    def stream_facts(
        self,
        limit: Optional[int] = None,
        relations: Optional[Set[str]] = None,
        concepts: Optional[Set[str]] = None,
        languages: Optional[Set[str]] = None,
    ) -> Iterator[FactRecord]:
        """Stream canonical typed V-predicate fact records from ConceptNet assertions."""
        artifact = self.last_artifact if self.last_artifact is not None else self.fetch_artifact(download=False)
        source_file = artifact.local_path

        active_languages = set(languages) if languages is not None else self.languages
        active_relations = set(relations) if relations is not None else self.relations
        active_concepts = set(concepts) if concepts is not None else self.concepts

        normalized_relations = (
            {_sanitize_symbol(r) for r in active_relations}
            if active_relations is not None
            else None
        )
        normalized_concepts = (
            {_sanitize_symbol(c) for c in active_concepts}
            if active_concepts is not None
            else None
        )

        emitted_count = 0
        prov_uri = artifact.source_uri if artifact.provenance_type != ProvenanceType.FIXTURE else self.source_uri

        for rel_raw, start_raw, end_raw, weight in self._stream_raw_entries(source_file):
            if not rel_raw or not start_raw or not end_raw:
                continue

            # 1. Language filter
            if active_languages:
                if not _check_language(start_raw, active_languages) or not _check_language(end_raw, active_languages):
                    continue

            start = _sanitize_symbol(start_raw)
            end = _sanitize_symbol(end_raw)
            rel_symbol = _sanitize_symbol(rel_raw)

            if not start or not end:
                continue

            # 2. Concept seed filter
            if normalized_concepts is not None and start not in normalized_concepts:
                continue

            # 3. Relation filter
            if normalized_relations is not None:
                if rel_symbol not in normalized_relations and (active_relations is None or rel_raw not in active_relations):
                    continue

            # Scale weight to strength and confidence
            strength = round(min(1.0, max(0.0, weight / 5.0)), 3)
            confidence = round(min(0.95, max(0.1, 0.5 + 0.1 * min(weight, 4.0))), 3)
            truth = TruthValue(strength=strength, confidence=confidence)

            provenance = Provenance(
                source=self.source_name,
                source_record_id=f"{start}_{rel_symbol}_{end}",
                source_uri=prov_uri,
                source_version=self.version,
                license=self.license,
                transformation=self.transformation,
                origin=FactOrigin.ASSERTED,
            )

            rel_lower = rel_raw.lower()
            fact: Optional[FactRecord] = None

            if "/r/isa" in rel_lower or rel_lower == "isa":
                edge_id = stable_evidence_id("sort", "conceptnet", start, end)
                fact = SortFact(
                    evidence_id=edge_id,
                    edge_id=edge_id,
                    concept=start,
                    perspective=Perspective.TAXONOMIC_KIND,
                    sort=end,
                    truth=truth,
                    provenance=provenance,
                )

            elif "/r/usedfor" in rel_lower or rel_lower == "usedfor":
                edge_id = stable_evidence_id("predicate", "conceptnet", start, "used_for", end)
                fact = PredicateFact(
                    evidence_id=edge_id,
                    edge_id=edge_id,
                    concept=start,
                    perspective=Perspective.FUNCTIONAL_USE,
                    predicate=f"(used_for {start} {end})",
                    truth=truth,
                    provenance=provenance,
                )

            elif "/r/capableof" in rel_lower or rel_lower == "capableof":
                edge_id = stable_evidence_id("predicate", "conceptnet", start, "capable_of", end)
                fact = PredicateFact(
                    evidence_id=edge_id,
                    edge_id=edge_id,
                    concept=start,
                    perspective=Perspective.BEHAVIORAL_PROCESS,
                    predicate=f"(capable_of {start} {end})",
                    truth=truth,
                    provenance=provenance,
                )

            elif "/r/atlocation" in rel_lower or rel_lower == "atlocation":
                edge_id = stable_evidence_id("predicate", "conceptnet", start, "at_location", end)
                fact = PredicateFact(
                    evidence_id=edge_id,
                    edge_id=edge_id,
                    concept=start,
                    perspective=Perspective.SPATIAL_CONTEXT,
                    predicate=f"(at_location {start} {end})",
                    truth=truth,
                    provenance=provenance,
                )

            elif "/r/partof" in rel_lower or rel_lower == "partof":
                edge_id = stable_evidence_id("predicate", "conceptnet", start, "part_of", end)
                fact = PredicateFact(
                    evidence_id=edge_id,
                    edge_id=edge_id,
                    concept=start,
                    perspective=Perspective.STRUCTURAL_COMPOSITION,
                    predicate=f"(part_of {start} {end})",
                    truth=truth,
                    provenance=provenance,
                )

            elif "/r/hasproperty" in rel_lower or rel_lower == "hasproperty":
                prop_id = stable_evidence_id("prop", "conceptnet", start, end)
                edge_id = stable_evidence_id("property", "conceptnet", start, end)
                fact = PropertyFact(
                    evidence_id=edge_id,
                    edge_id=edge_id,
                    concept=start,
                    perspective=Perspective.DESCRIPTIVE_PROPERTY,
                    property_id=prop_id,
                    property_name=end,
                    truth=truth,
                    provenance=provenance,
                )

            elif "/r/causes" in rel_lower or rel_lower == "causes":
                edge_id = stable_evidence_id("predicate", "conceptnet", start, "causes", end)
                fact = PredicateFact(
                    evidence_id=edge_id,
                    edge_id=edge_id,
                    concept=start,
                    perspective=Perspective.CAUSAL_PREREQUISITE,
                    predicate=f"(causes {start} {end})",
                    truth=truth,
                    provenance=provenance,
                )

            if fact is not None:
                yield fact
                emitted_count += 1
                if limit is not None and emitted_count >= limit:
                    return
