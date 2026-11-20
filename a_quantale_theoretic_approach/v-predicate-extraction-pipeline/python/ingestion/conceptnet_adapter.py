"""ConceptNet 5th knowledge source adapter producing canonical v-predicate/1 records."""

from __future__ import annotations

import json
import logging
from pathlib import Path
import re
from typing import Iterator, Optional
import urllib.request

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

from .base_adapter import BaseSourceAdapter

logger = logging.getLogger(__name__)

PIPELINE_ROOT = Path(__file__).resolve().parents[2]
_SYMBOL_CLEANER = re.compile(r"[^A-Za-z0-9_]")


def _sanitize_symbol(raw: str) -> str:
    """Normalize raw concept labels or relation names into canonical MeTTa symbols."""
    # Strip ConceptNet URI prefix like /c/en/
    cleaned = raw.strip()
    if cleaned.startswith("/c/en/"):
        cleaned = cleaned[len("/c/en/"):]
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


class ConceptNetAdapter(BaseSourceAdapter):
    """Adapter for ConceptNet commonsense assertions under the v-predicate/1 contract."""

    def __init__(
        self,
        fixture_path: Optional[Path] = None,
        cache_dir: Optional[Path] = None,
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
        self.source_name = "conceptnet"
        self.version = "5.7.0"
        self.license = "CC-BY-SA-4.0"
        self.transformation = "conceptnet_adapter_v1"
        self.source_uri = "https://api.conceptnet.io"

    def fetch(self, download: bool = False, cache_dir: Optional[Path] = None) -> Path:
        """Locate local fixture or atomically retrieve and cache ConceptNet source data."""
        target_dir = cache_dir.resolve() if cache_dir else self.cache_dir
        target_file = target_dir / "conceptnet_assertions.json"

        if download:
            target_dir.mkdir(parents=True, exist_ok=True)
            tmp_file = target_dir / "conceptnet_assertions.json.tmp"
            logger.info("Downloading ConceptNet assertions from %s...", self.source_uri)
            try:
                with urllib.request.urlopen(self.source_uri, timeout=15) as response:
                    content = response.read()
                    with open(tmp_file, "wb") as f:
                        f.write(content)
                tmp_file.replace(target_file)
                return target_file
            except Exception as e:
                logger.warning(
                    "ConceptNet live download failed (%s). Falling back to fixture.", e
                )
                if tmp_file.exists():
                    tmp_file.unlink()

        if target_file.exists():
            return target_file

        if self.fixture_path.exists():
            return self.fixture_path

        raise FileNotFoundError(
            f"ConceptNet source file not found at {target_file} or {self.fixture_path}"
        )

    def stream_facts(self, limit: Optional[int] = None) -> Iterator[FactRecord]:
        """Stream canonical typed V-predicate fact records from ConceptNet assertions."""
        source_file = self.fetch(download=False)
        with open(source_file, "r", encoding="utf-8") as f:
            data = json.load(f)

        edges = data.get("edges", [])
        emitted_count = 0

        for edge in edges:
            if limit is not None and emitted_count >= limit:
                break

            start_raw = edge.get("start", "")
            rel_raw = edge.get("relation", "")
            end_raw = edge.get("end", "")
            weight = float(edge.get("weight", 1.0))

            start = _sanitize_symbol(start_raw)
            end = _sanitize_symbol(end_raw)

            if not start or not end or not rel_raw:
                continue

            # Scale weight to strength and confidence
            strength = round(min(1.0, max(0.0, weight / 5.0)), 3)
            confidence = round(min(0.95, max(0.1, 0.5 + 0.1 * min(weight, 4.0))), 3)
            truth = TruthValue(strength=strength, confidence=confidence)

            rel_symbol = _sanitize_symbol(rel_raw)
            provenance = Provenance(
                source=self.source_name,
                source_record_id=f"{start}_{rel_symbol}_{end}",
                source_uri=self.source_uri,
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
