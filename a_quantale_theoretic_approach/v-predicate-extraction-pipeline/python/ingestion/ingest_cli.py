#!/usr/bin/env python3
"""Unified Command-Line Interface for Knowledge Ingestion into Conceptual Blending AtomSpaces."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import List, Optional

from ingestion.models import KnowledgeSource
from ingestion.orchestrator import MultiSourceOrchestrator


def parse_sources(source_str: str) -> Optional[List[KnowledgeSource]]:
    """Parse comma-separated source tokens into KnowledgeSource enums."""
    tokens = [s.strip().lower() for s in source_str.split(",") if s.strip()]
    if "all" in tokens:
        return None

    sources: List[KnowledgeSource] = []
    mapping = {
        "wordnet": KnowledgeSource.WORDNET,
        "wn": KnowledgeSource.WORDNET,
        "go": KnowledgeSource.GENE_ONTOLOGY,
        "gene_ontology": KnowledgeSource.GENE_ONTOLOGY,
        "chebi": KnowledgeSource.CHEBI,
        "openmath": KnowledgeSource.OPENMATH,
        "om": KnowledgeSource.OPENMATH,
    }

    for tok in tokens:
        if tok in mapping:
            sources.append(mapping[tok])
        else:
            raise ValueError(f"Unknown knowledge source: '{tok}'. Valid options: {list(mapping.keys())} or 'all'")

    return sources


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Unified Knowledge Ingestion Pipeline for Conceptual Blending AtomSpaces."
    )
    parser.add_argument(
        "--sources",
        type=str,
        default="all",
        help="Comma-separated knowledge sources to ingest (e.g. 'wordnet,go,chebi,openmath' or 'all'). Default: all",
    )
    parser.add_argument(
        "--output-dir",
        type=str,
        default="kb/generated",
        help="Output directory for generated .metta knowledge bases. Default: kb/generated",
    )
    parser.add_argument(
        "--download",
        action="store_true",
        help="Download latest live source ontologies over network instead of bundled fixtures.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Limit number of raw records extracted per source (useful for smoke tests).",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable verbose progress output.",
    )
    return parser


def main(args: Optional[List[str]] = None) -> int:
    parser = build_parser()
    parsed_args = parser.parse_args(args)

    try:
        sources = parse_sources(parsed_args.sources)
    except ValueError as err:
        print(f"Error: {err}", file=sys.stderr)
        return 1

    output_dir = Path(parsed_args.output_dir)

    if parsed_args.verbose:
        src_names = [s.value for s in sources] if sources else "ALL"
        print(f"=== Starting Multi-Source Ingestion ===")
        print(f"Sources: {src_names}")
        print(f"Output Directory: {output_dir}")
        print(f"Download Live Data: {parsed_args.download}")
        print(f"Record Limit Per Source: {parsed_args.limit}")

    orchestrator = MultiSourceOrchestrator()
    summary = orchestrator.run_ingestion(
        sources=sources,
        limit_per_source=parsed_args.limit,
        download=parsed_args.download,
        output_dir=output_dir,
        verbose=parsed_args.verbose,
    )

    print("\n=== Ingestion Complete ===")
    print(f"Total Raw Records Extracted: {summary.total_raw_records}")
    print(f"Total Normalized Records:    {summary.total_normalized_records}")
    print(f"Total CASL Facts Written:     {summary.total_casl_facts}")
    print(f"Total Property-World Facts:   {summary.total_property_world_facts}")
    print("Generated Files:")
    for out_file in summary.output_files:
        print(f"  - {out_file} ({out_file.stat().st_size if out_file.exists() else 0} bytes)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
