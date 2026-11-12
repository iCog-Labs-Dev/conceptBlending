"""End-to-end integration and unit tests for the unified multi-source ingestion orchestrator and CLI."""

from pathlib import Path
import pytest
import subprocess
import sys

from ingestion.models import KnowledgeSource
from ingestion.orchestrator import IngestionSummary, MultiSourceOrchestrator
from ingestion.sinks import PathMapSink


class TestIngestionOrchestrator:
    def test_orchestrator_initialization(self):
        orchestrator = MultiSourceOrchestrator()
        assert len(orchestrator.adapters) == 4
        adapter_sources = {a.source_type for a in orchestrator.adapters}
        assert KnowledgeSource.WORDNET in adapter_sources
        assert KnowledgeSource.GENE_ONTOLOGY in adapter_sources
        assert KnowledgeSource.CHEBI in adapter_sources
        assert KnowledgeSource.OPENMATH in adapter_sources

    def test_multisource_offline_run(self, tmp_path: Path):
        output_dir = tmp_path / "kb_generated"
        orchestrator = MultiSourceOrchestrator()
        summary = orchestrator.run_ingestion(
            limit_per_source=5,
            download=False,
            output_dir=output_dir,
        )

        assert isinstance(summary, IngestionSummary)
        assert summary.total_raw_records > 0
        assert summary.total_normalized_records > 0
        assert summary.total_casl_facts > 0
        assert summary.total_property_world_facts > 0

        # Verify output files exist and are populated
        casl_kb = output_dir / "AlgebraicSpecificationKB.metta"
        pw_kb = output_dir / "PropertyWorldKB.metta"
        assert casl_kb.exists()
        assert pw_kb.exists()
        assert casl_kb.stat().st_size > 0
        assert pw_kb.stat().st_size > 0

    def test_fact_deduplication(self, tmp_path: Path):
        output_dir = tmp_path / "dedup_test"
        orchestrator = MultiSourceOrchestrator()
        # Run twice into the same directory; deduplication should prevent duplicate lines
        summary1 = orchestrator.run_ingestion(
            sources=[KnowledgeSource.WORDNET],
            limit_per_source=5,
            output_dir=output_dir,
        )
        casl_kb = output_dir / "AlgebraicSpecificationKB.metta"
        pw_kb = output_dir / "PropertyWorldKB.metta"
        casl_pass1 = casl_kb.read_text(encoding="utf-8").splitlines()
        pw_pass1 = pw_kb.read_text(encoding="utf-8").splitlines()

        summary2 = orchestrator.run_ingestion(
            sources=[KnowledgeSource.WORDNET],
            limit_per_source=5,
            output_dir=output_dir,
        )
        casl_pass2 = casl_kb.read_text(encoding="utf-8").splitlines()
        pw_pass2 = pw_kb.read_text(encoding="utf-8").splitlines()

        assert len(casl_pass1) == len(casl_pass2)
        assert len(casl_pass2) == len(set(casl_pass2))
        assert len(pw_pass1) == len(pw_pass2)
        assert len(pw_pass2) == len(set(pw_pass2))

    def test_metta_syntax_and_balance(self, tmp_path: Path):
        output_dir = tmp_path / "balance_test"
        orchestrator = MultiSourceOrchestrator()
        orchestrator.run_ingestion(
            limit_per_source=10,
            output_dir=output_dir,
        )

        for metta_file in output_dir.glob("*.metta"):
            content = metta_file.read_text(encoding="utf-8")
            assert content.count("(") == content.count(")")
            for line in content.splitlines():
                line = line.strip()
                if line and not line.startswith(";"):
                    assert line.startswith("(")
                    assert line.endswith(")")

    def test_pathmap_sink_registration(self, tmp_path: Path):
        pathmap_sink = PathMapSink()
        orchestrator = MultiSourceOrchestrator(sinks=[pathmap_sink])
        summary = orchestrator.run_ingestion(
            limit_per_source=5,
            output_dir=tmp_path / "kb",
        )

        registered = pathmap_sink.get_registered_records()
        assert len(registered) == summary.total_normalized_records
        assert len(registered) > 0

    def test_cli_invocation(self, tmp_path: Path):
        output_dir = tmp_path / "cli_test"
        cli_path = (
            Path(__file__).resolve().parents[2] / "python" / "ingestion" / "ingest_cli.py"
        )
        cmd = [
            sys.executable,
            str(cli_path),
            "--sources",
            "wordnet,go,chebi,openmath",
            "--output-dir",
            str(output_dir),
            "--limit",
            "3",
            "--verbose",
        ]
        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=30,
        )

        assert result.returncode == 0
        assert (output_dir / "AlgebraicSpecificationKB.metta").exists()
        assert (output_dir / "PropertyWorldKB.metta").exists()
        assert "Ingestion Complete" in result.stdout
