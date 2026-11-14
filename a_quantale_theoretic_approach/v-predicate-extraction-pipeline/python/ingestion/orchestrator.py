"""Multi-Source Knowledge Ingestion Orchestrator for Conceptual Blending AtomSpaces."""

from __future__ import annotations

from dataclasses import dataclass, field
import datetime
import hashlib
import json
from pathlib import Path
import shutil
from typing import Any, Dict, Iterator, List, Optional, Set, Union

from .base_adapter import BaseSourceAdapter
from .chebi_adapter import ChebiAdapter
from .conceptnet_adapter import ConceptNetAdapter
from .go_adapter import GeneOntologyAdapter
from .models import FactType, KnowledgeSource, MettaFact, NormalizedRecord
from .openmath_adapter import OpenMathAdapter
from .sinks import BaseSink, InMemoryTestSink, MettaFileSink, PathMapSink
from .wordnet_adapter import WordNetAdapter
from v_predicate_contract import (
    CONTRACT_VERSION,
    ContractValidationError,
    FactKind,
    FactRecord,
    validate_record_set,
)

PIPELINE_ROOT = Path(__file__).resolve().parents[2]


def _file_sha256(path: Path) -> str:
    """Compute SHA256 checksum of a file."""
    if not path.exists():
        return ""
    h = hashlib.sha256()
    with path.open("rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()


@dataclass
class IngestionSummary:
    """Consolidated summary of an ingestion run across all sources."""

    total_raw_records: int
    total_normalized_records: int
    total_casl_facts: int
    total_property_world_facts: int
    source_summaries: Dict[str, Dict[str, Any]] = field(default_factory=dict)
    output_files: List[Path] = field(default_factory=list)
    manifest_path: Optional[Path] = None


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
                ConceptNetAdapter(),
            ]
        self.sinks = list(sinks) if sinks is not None else []

    def _resolve_source_token(self, adapter: BaseSourceAdapter) -> str:
        """Derive standard source key string for filtering and manifest generation."""
        if hasattr(adapter, "source_name") and adapter.source_name:
            return adapter.source_name
        if hasattr(adapter, "source_type") and adapter.source_type:
            st = adapter.source_type
            return st.value if hasattr(st, "value") else str(st).lower()
        return adapter.__class__.__name__.lower()

    def run_ingestion(
        self,
        sources: Optional[List[Union[KnowledgeSource, str]]] = None,
        limit_per_source: Optional[int] = None,
        download: bool = False,
        output_dir: Optional[Path] = None,
        verbose: bool = False,
    ) -> IngestionSummary:
        """Execute streaming ingestion across selected sources with atomic staging and validation."""
        target_dir = Path(output_dir or (PIPELINE_ROOT / "data" / "generated")).resolve()
        target_dir.mkdir(parents=True, exist_ok=True)

        # Atomic staging workspace (Rule 6)
        staging_dir = target_dir / ".staging"
        if staging_dir.exists():
            shutil.rmtree(staging_dir)
        staging_dir.mkdir(parents=True, exist_ok=True)

        staging_casl_path = staging_dir / "AlgebraicSpecificationKB.metta"
        staging_pw_path = staging_dir / "PropertyWorldKB.metta"

        final_casl_path = target_dir / "AlgebraicSpecificationKB.metta"
        final_pw_path = target_dir / "PropertyWorldKB.metta"

        # If destination files already exist, copy into staging workspace for incremental update & deduplication
        if final_casl_path.exists():
            shutil.copy2(final_casl_path, staging_casl_path)
        if final_pw_path.exists():
            shutil.copy2(final_pw_path, staging_pw_path)

        casl_sink = MettaFileSink(staging_casl_path)
        pw_sink = MettaFileSink(staging_pw_path)

        # Filter active adapters
        if sources:
            source_filter_keys = set()
            for s in sources:
                if hasattr(s, "value"):
                    source_filter_keys.add(s.value.lower())
                else:
                    tok = str(s).strip().lower()
                    if tok in {"go", "gene_ontology"}:
                        source_filter_keys.add("gene_ontology")
                    elif tok in {"wn", "wordnet"}:
                        source_filter_keys.add("wordnet")
                    elif tok in {"om", "openmath"}:
                        source_filter_keys.add("openmath")
                    else:
                        source_filter_keys.add(tok)

            active_adapters = [
                a for a in self.adapters
                if self._resolve_source_token(a) in source_filter_keys
                or (hasattr(a, "source_type") and a.source_type in sources)
            ]
        else:
            active_adapters = self.adapters

        total_raw = 0
        total_normalized = 0
        total_casl = 0
        total_pw = 0
        all_emitted_facts: List[Any] = []
        source_summaries: Dict[str, Dict[str, Any]] = {}

        try:
            for adapter in active_adapters:
                src_key = self._resolve_source_token(adapter)
                if verbose:
                    print(f"[Orchestrator] Processing knowledge source: {src_key}")

                # Ensure source data is localized
                resolved_file = adapter.fetch(download=download)

                src_raw = 0
                src_norm = 0
                src_casl = 0
                src_pw = 0
                src_facts: List[Any] = []

                # Stream via canonical v-predicate/1 stream_facts if supported
                if hasattr(adapter, "stream_facts") and callable(adapter.stream_facts):
                    for fact in adapter.stream_facts(limit=limit_per_source):
                        all_emitted_facts.append(fact)
                        src_facts.append(fact)
                        src_raw += 1
                        src_norm += 1
                        total_raw += 1
                        total_normalized += 1

                        kind = getattr(fact, "kind", None)
                        if kind in {
                            FactKind.SORT,
                            FactKind.OPERATION,
                            FactKind.OPERATION_SIGNATURE,
                            FactKind.PREDICATE,
                            FactKind.PREDICATE_SIGNATURE,
                            FactKind.AXIOM,
                            FactKind.PERSPECTIVE_DEFINITION,
                            FactKind.SUBPERSPECTIVE,
                            FactKind.PERSPECTIVE_MATCH,
                        }:
                            if casl_sink.write_fact(fact):
                                src_casl += 1
                                total_casl += 1

                        if kind in {
                            FactKind.PROPERTY,
                            FactKind.PROPERTY_WORLD,
                            FactKind.PERSPECTIVE_MATCH,
                        }:
                            if pw_sink.write_fact(fact):
                                src_pw += 1
                                total_pw += 1

                        # Deliver to caller-configured sinks
                        for s in self.sinks:
                            s.write_fact(fact)
                else:
                    # Legacy fallback
                    for raw in adapter.extract_raw_records(limit=limit_per_source):
                        src_raw += 1
                        total_raw += 1
                        norm = adapter.normalize_record(raw)
                        if not norm:
                            continue
                        src_norm += 1
                        total_normalized += 1

                        for sink in self.sinks:
                            if hasattr(sink, "register_atomspace_record"):
                                sink.register_atomspace_record(norm)

                        for fact in adapter.transform_to_casl(norm):
                            if casl_sink.write_fact(fact):
                                src_casl += 1
                                total_casl += 1
                            for s in self.sinks:
                                s.write_fact(fact)

                        for fact in adapter.transform_to_property_world(norm):
                            if pw_sink.write_fact(fact):
                                src_pw += 1
                                total_pw += 1
                            for s in self.sinks:
                                s.write_fact(fact)

                # Record source metadata
                version = getattr(adapter, "version", "unknown")
                license_str = getattr(adapter, "license", "unknown")
                uri = getattr(adapter, "source_uri", str(resolved_file))

                source_summaries[src_key] = {
                    "source_name": src_key,
                    "version": version,
                    "license": license_str,
                    "uri": uri,
                    "facts_emitted": len(src_facts) if src_facts else src_raw,
                    "casl_facts": src_casl,
                    "property_world_facts": src_pw,
                    "raw_records": src_raw,
                    "normalized_records": src_norm,
                }

                if verbose:
                    print(
                        f"[Orchestrator] {src_key} complete: "
                        f"{src_raw} raw, {src_casl} CASL, {src_pw} PW facts"
                    )

            # Flush sinks in staging directory
            casl_sink.flush()
            pw_sink.flush()
            for s in self.sinks:
                s.flush()

            # Validate complete emitted record set if any canonical facts emitted
            canonical_records = [f for f in all_emitted_facts if hasattr(f, "evidence_id")]
            if canonical_records:
                validate_record_set(canonical_records)

            # Atomic publication: swap staging files into final destination
            final_casl_path = target_dir / "AlgebraicSpecificationKB.metta"
            final_pw_path = target_dir / "PropertyWorldKB.metta"

            staging_casl_path.replace(final_casl_path)
            staging_pw_path.replace(final_pw_path)

            # Generate Run Manifest (run_manifest.json)
            manifest_data = {
                "contract_version": CONTRACT_VERSION,
                "pipeline_version": "1.0.0",
                "generated_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
                "validation": {
                    "status": "PASSED",
                    "error_count": 0,
                },
                "summary": {
                    "total_facts_emitted": len(all_emitted_facts),
                    "total_casl_facts": total_casl,
                    "total_property_world_facts": total_pw,
                    "sources_count": len(active_adapters),
                },
                "sources": source_summaries,
                "output_files": [
                    {
                        "filename": "AlgebraicSpecificationKB.metta",
                        "path": str(final_casl_path),
                        "size_bytes": final_casl_path.stat().st_size if final_casl_path.exists() else 0,
                        "sha256": _file_sha256(final_casl_path),
                    },
                    {
                        "filename": "PropertyWorldKB.metta",
                        "path": str(final_pw_path),
                        "size_bytes": final_pw_path.stat().st_size if final_pw_path.exists() else 0,
                        "sha256": _file_sha256(final_pw_path),
                    },
                ],
            }

            manifest_path = target_dir / "run_manifest.json"
            manifest_path.write_text(json.dumps(manifest_data, indent=2), encoding="utf-8")

        except Exception as err:
            # Rollback: delete staging workspace so no corrupted files are published
            if staging_dir.exists():
                shutil.rmtree(staging_dir, ignore_errors=True)
            raise err
        finally:
            # Clean up staging directory if still present
            if staging_dir.exists():
                shutil.rmtree(staging_dir, ignore_errors=True)

        return IngestionSummary(
            total_raw_records=total_raw,
            total_normalized_records=total_normalized,
            total_casl_facts=total_casl,
            total_property_world_facts=total_pw,
            source_summaries=source_summaries,
            output_files=[final_casl_path, final_pw_path],
            manifest_path=manifest_path,
        )
