"""Integration and unit tests for 5-source ingestion orchestrator, staging, manifest, and CLI under v-predicate/1."""

from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys
import unittest

from ingestion.orchestrator import IngestionSummary, MultiSourceOrchestrator
from ingestion.sinks import InMemoryTestSink, MettaFileSink, PathMapSink
from v_predicate_contract import (
    CONTRACT_VERSION,
    ContractValidationError,
    FactOrigin,
    Perspective,
    SortFact,
    TruthValue,
    stable_evidence_id,
)

PIPELINE_ROOT = Path(__file__).resolve().parents[2]


class TestIngestionOrchestrator(unittest.TestCase):
    def test_orchestrator_initialization_5_sources(self) -> None:
        orchestrator = MultiSourceOrchestrator()
        self.assertEqual(len(orchestrator.adapters), 5)
        source_names = {a.source_name for a in orchestrator.adapters}
        self.assertEqual(
            source_names,
            {"wordnet", "gene_ontology", "chebi", "openmath", "conceptnet"},
        )

    def test_multisource_offline_run_and_manifest(self) -> None:
        import tempfile
        with tempfile.TemporaryDirectory() as tmp_dir:
            out_dir = Path(tmp_dir) / "output"
            orchestrator = MultiSourceOrchestrator()
            summary = orchestrator.run_ingestion(
                limit_per_source=3,
                download=False,
                output_dir=out_dir,
            )

            self.assertIsInstance(summary, IngestionSummary)
            self.assertGreater(summary.total_casl_facts, 0)
            self.assertGreater(summary.total_property_world_facts, 0)

            # Check generated KB files
            casl_kb = out_dir / "AlgebraicSpecificationKB.metta"
            pw_kb = out_dir / "PropertyWorldKB.metta"
            manifest_file = out_dir / "run_manifest.json"

            self.assertTrue(casl_kb.exists())
            self.assertTrue(pw_kb.exists())
            self.assertTrue(manifest_file.exists())
            self.assertGreater(casl_kb.stat().st_size, 0)
            self.assertGreater(pw_kb.stat().st_size, 0)

            # Atomic staging directory must NOT be left over
            self.assertFalse((out_dir / ".staging").exists())

            # Verify manifest content
            manifest = json.loads(manifest_file.read_text(encoding="utf-8"))
            self.assertEqual(manifest["contract_version"], CONTRACT_VERSION)
            self.assertEqual(manifest["validation"]["status"], "PASSED")
            self.assertEqual(manifest["validation"]["error_count"], 0)
            self.assertIn("sources", manifest)
            self.assertIn("conceptnet", manifest["sources"])
            self.assertIn("wordnet", manifest["sources"])
            self.assertIn("output_files", manifest)
            self.assertEqual(len(manifest["output_files"]), 2)

    def test_in_memory_test_sink_and_alias(self) -> None:
        # Rule 9: PathMapSink is an alias of InMemoryTestSink
        self.assertIs(PathMapSink, InMemoryTestSink)
        sink = InMemoryTestSink()
        orchestrator = MultiSourceOrchestrator(sinks=[sink])

        import tempfile
        with tempfile.TemporaryDirectory() as tmp_dir:
            summary = orchestrator.run_ingestion(
                sources=["conceptnet"],
                limit_per_source=3,
                output_dir=Path(tmp_dir),
            )
            facts = sink.get_written_facts()
            self.assertGreater(len(facts), 0)

    def test_fact_deduplication_and_idempotence(self) -> None:
        import tempfile
        with tempfile.TemporaryDirectory() as tmp_dir:
            out_dir = Path(tmp_dir) / "dedup"
            orchestrator = MultiSourceOrchestrator()

            # First run
            orchestrator.run_ingestion(
                sources=["conceptnet"],
                limit_per_source=4,
                output_dir=out_dir,
            )
            casl_kb = out_dir / "AlgebraicSpecificationKB.metta"
            pw_kb = out_dir / "PropertyWorldKB.metta"
            casl_lines_1 = casl_kb.read_text(encoding="utf-8").splitlines()
            pw_lines_1 = pw_kb.read_text(encoding="utf-8").splitlines()

            # Second run into same output dir
            orchestrator.run_ingestion(
                sources=["conceptnet"],
                limit_per_source=4,
                output_dir=out_dir,
            )
            casl_lines_2 = casl_kb.read_text(encoding="utf-8").splitlines()
            pw_lines_2 = pw_kb.read_text(encoding="utf-8").splitlines()

            self.assertEqual(len(casl_lines_1), len(casl_lines_2))
            self.assertEqual(len(pw_lines_1), len(pw_lines_2))

    def test_metta_syntax_and_balancing(self) -> None:
        import tempfile
        with tempfile.TemporaryDirectory() as tmp_dir:
            out_dir = Path(tmp_dir) / "syntax_check"
            orchestrator = MultiSourceOrchestrator()
            orchestrator.run_ingestion(
                limit_per_source=5,
                output_dir=out_dir,
            )

            for metta_file in out_dir.glob("*.metta"):
                content = metta_file.read_text(encoding="utf-8")
                self.assertEqual(content.count("("), content.count(")"))
                for line in content.splitlines():
                    line = line.strip()
                    if line and not line.startswith(";"):
                        self.assertTrue(line.startswith("(") and line.endswith(")"))

    def test_validation_rollback_cleans_staging(self) -> None:
        import tempfile
        from unittest.mock import MagicMock

        with tempfile.TemporaryDirectory() as tmp_dir:
            out_dir = Path(tmp_dir) / "staging_rollback"

            # Create an adapter that yields an invalid fact violating symbol rules
            mock_adapter = MagicMock()
            mock_adapter.source_name = "mock_bad"
            mock_adapter.fetch.return_value = Path("dummy")

            # Yield a SortFact with illegal symbol characters (violating _SYMBOL)
            from v_predicate_contract import Provenance
            prov = Provenance(
                source="mock",
                source_record_id="bad_1",
                source_uri="http://bad.org",
                source_version="1.0",
                license="MIT",
                transformation="test",
                origin=FactOrigin.ASSERTED,
            )

            class BadRecord:
                evidence_id = "bad evidence id with spaces"  # illegal symbol!
                kind = None

            mock_adapter.stream_facts.return_value = iter([BadRecord()])

            orchestrator = MultiSourceOrchestrator(adapters=[mock_adapter])

            with self.assertRaises(Exception):
                orchestrator.run_ingestion(output_dir=out_dir)

            # Staging directory must be cleaned up on failure
            self.assertFalse((out_dir / ".staging").exists())

    def test_cli_invocation_all_sources(self) -> None:
        import tempfile
        with tempfile.TemporaryDirectory() as tmp_dir:
            out_dir = Path(tmp_dir) / "cli_out"
            cli_path = PIPELINE_ROOT / "python" / "ingestion" / "ingest_cli.py"

            cmd = [
                sys.executable,
                str(cli_path),
                "--sources",
                "all",
                "--output-dir",
                str(out_dir),
                "--limit",
                "2",
                "--verbose",
            ]
            result = subprocess.run(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=30,
                env={"PYTHONPATH": f"{PIPELINE_ROOT}/python:{PIPELINE_ROOT.parents[1]}"},
            )

            self.assertEqual(result.returncode, 0, f"CLI stderr: {result.stderr}")
            self.assertTrue((out_dir / "AlgebraicSpecificationKB.metta").exists())
            self.assertTrue((out_dir / "PropertyWorldKB.metta").exists())
            self.assertTrue((out_dir / "run_manifest.json").exists())
            self.assertIn("Ingestion Complete", result.stdout)

    def test_cli_invocation_conceptnet(self) -> None:
        import tempfile
        with tempfile.TemporaryDirectory() as tmp_dir:
            out_dir = Path(tmp_dir) / "cli_cnet"
            cli_path = PIPELINE_ROOT / "python" / "ingestion" / "ingest_cli.py"

            cmd = [
                sys.executable,
                str(cli_path),
                "--sources",
                "conceptnet",
                "--output-dir",
                str(out_dir),
                "--limit",
                "3",
            ]
            result = subprocess.run(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=30,
                env={"PYTHONPATH": f"{PIPELINE_ROOT}/python:{PIPELINE_ROOT.parents[1]}"},
            )

            self.assertEqual(result.returncode, 0, f"CLI stderr: {result.stderr}")
            self.assertTrue((out_dir / "run_manifest.json").exists())


if __name__ == "__main__":
    unittest.main()
