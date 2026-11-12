"""Multi-Source Knowledge Ingestion Orchestrator for Conceptual Blending AtomSpaces."""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, Iterator, List, Optional, Set

from .base_adapter import BaseSourceAdapter
from .chebi_adapter import ChebiAdapter
from .go_adapter import GeneOntologyAdapter
from .models import FactType, KnowledgeSource, MettaFact, NormalizedRecord
from .openmath_adapter import OpenMathAdapter
from .sinks import BaseSink, MettaFileSink, PathMapSink
from .wordnet_adapter import WordNetAdapter


@dataclass
class IngestionSummary:
    """Consolidated summary of an ingestion run across all sources."""

    total_raw_records: int
    total_normalized_records: int
    total_casl_facts: int
    total_property_world_facts: int
    source_summaries: Dict[KnowledgeSource, Dict[str, int]] = field(default_factory=dict)
    output_files: List[Path] = field(default_factory=list)


class MultiSourceOrchestrator:
    """Coordinates streaming ingestion across multi-source knowledge adapters into AtomSpace sinks."""

    def __init__(
        self,
        adapters: Optional[List[BaseSourceAdapter]] = None,
        sinks: Optional[List[BaseSink]] = None,
    ) -> None:
        if adapters is not None:
            self.adapters = list(adapters)
        else:
            self.adapters = [
                WordNetAdapter(),
                GeneOntologyAdapter(),
                ChebiAdapter(),
                OpenMathAdapter(),
            ]
        self.sinks = list(sinks) if sinks is not None else []

    def run_ingestion(
        self,
        sources: Optional[List[KnowledgeSource]] = None,
        limit_per_source: Optional[int] = None,
        download: bool = False,
        output_dir: Optional[Path] = None,
        verbose: bool = False,
    ) -> IngestionSummary:
        """Execute streaming ingestion across selected sources and persist to sinks."""
        target_dir = Path(output_dir or "kb/generated")
        target_dir.mkdir(parents=True, exist_ok=True)

        casl_path = target_dir / "AlgebraicSpecificationKB.metta"
        pw_path = target_dir / "PropertyWorldKB.metta"

        casl_sink = MettaFileSink(casl_path)
        pw_sink = MettaFileSink(pw_path)

        active_adapters = (
            [a for a in self.adapters if a.source_type in sources]
            if sources
            else self.adapters
        )

        pathmap_sinks = [s for s in self.sinks if isinstance(s, PathMapSink)]
        other_sinks = [s for s in self.sinks if not isinstance(s, (MettaFileSink, PathMapSink))]

        total_raw = 0
        total_normalized = 0
        total_casl = 0
        total_pw = 0
        source_summaries: Dict[KnowledgeSource, Dict[str, int]] = {}

        # Global fact deduplication sets (by expression)
        seen_casl_exprs: Set[str] = set()
        seen_pw_exprs: Set[str] = set()

        for adapter in active_adapters:
            src = adapter.source_type
            if verbose:
                print(f"[Orchestrator] Processing knowledge source: {src.value}")

            # Ensure data source is ready
            adapter.fetch(download=download)

            src_raw = 0
            src_norm = 0
            src_casl = 0
            src_pw = 0

            for raw in adapter.extract_raw_records(limit=limit_per_source):
                src_raw += 1
                total_raw += 1

                norm = adapter.normalize_record(raw)
                if not norm:
                    continue

                src_norm += 1
                total_normalized += 1

                # Register with PathMap sinks
                for pm_sink in pathmap_sinks:
                    pm_sink.register_atomspace_record(norm)

                # Transform & route CASL facts
                for fact in adapter.transform_to_casl(norm):
                    if fact.expression not in seen_casl_exprs:
                        seen_casl_exprs.add(fact.expression)
                        if casl_sink.write_fact(fact):
                            src_casl += 1
                            total_casl += 1
                        for o_sink in other_sinks:
                            o_sink.write_fact(fact)

                # Transform & route Property-World facts
                for fact in adapter.transform_to_property_world(norm):
                    if fact.expression not in seen_pw_exprs:
                        seen_pw_exprs.add(fact.expression)
                        if pw_sink.write_fact(fact):
                            src_pw += 1
                            total_pw += 1
                        for o_sink in other_sinks:
                            o_sink.write_fact(fact)

            source_summaries[src] = {
                "raw_records": src_raw,
                "normalized_records": src_norm,
                "casl_facts": src_casl,
                "property_world_facts": src_pw,
            }

            if verbose:
                print(
                    f"[Orchestrator] {src.value} complete: "
                    f"{src_raw} raw, {src_norm} normalized, {src_casl} CASL, {src_pw} PW facts"
                )

        # Flush all sinks
        casl_sink.flush()
        pw_sink.flush()
        for s in self.sinks:
            s.flush()

        return IngestionSummary(
            total_raw_records=total_raw,
            total_normalized_records=total_normalized,
            total_casl_facts=total_casl,
            total_property_world_facts=total_pw,
            source_summaries=source_summaries,
            output_files=[casl_path, pw_path],
        )
