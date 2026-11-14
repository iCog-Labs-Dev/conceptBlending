"""End-to-End Acceptance Test Suite for Objective 1, Key Result 2 under canonical v-predicate/1."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from ingestion.orchestrator import IngestionSummary, MultiSourceOrchestrator
from v_predicate_contract import CONTRACT_VERSION

PIPELINE_ROOT = Path(__file__).resolve().parents[2]


def _sha256(path: Path) -> str:
    """Compute deterministic SHA256 digest of a file."""
    h = hashlib.sha256()
    with path.open("rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()


class TestAcceptanceScenario(unittest.TestCase):
    """Rigorous acceptance verification covering the 5-source pipeline, determinism, and balance."""

    def test_e2e_five_source_ingestion(self) -> None:
        """Verify full execution across all 5 canonical knowledge sources from offline fixtures."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            out_dir = Path(tmp_dir) / "kb_e2e"
            orchestrator = MultiSourceOrchestrator()
            summary = orchestrator.run_ingestion(
                sources=["wordnet", "gene_ontology", "chebi", "openmath", "conceptnet"],
                download=False,
                output_dir=out_dir,
            )

            self.assertIsInstance(summary, IngestionSummary)
            # Reconcile exact counts across the five canonical offline fixtures
            self.assertEqual(summary.total_raw_records, 230)
            self.assertEqual(summary.total_normalized_records, 230)
            self.assertEqual(summary.total_casl_facts, 74)
            self.assertEqual(summary.total_property_world_facts, 156)

            casl_kb = out_dir / "AlgebraicSpecificationKB.metta"
            pw_kb = out_dir / "PropertyWorldKB.metta"
            manifest = out_dir / "run_manifest.json"

            self.assertTrue(casl_kb.exists() and casl_kb.stat().st_size > 0)
            self.assertTrue(pw_kb.exists() and pw_kb.stat().st_size > 0)
            self.assertTrue(manifest.exists() and manifest.stat().st_size > 0)

            # Atomic staging directory must not be present
            self.assertFalse((out_dir / ".staging").exists())

    def test_metta_parenthetical_balance(self) -> None:
        """Verify parenthetical balance and syntax validity on all generated MeTTa knowledge bases."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            out_dir = Path(tmp_dir) / "kb_balance"
            orchestrator = MultiSourceOrchestrator()
            orchestrator.run_ingestion(
                sources=["wordnet", "gene_ontology", "chebi", "openmath", "conceptnet"],
                download=False,
                output_dir=out_dir,
            )

            for kb_file in [
                out_dir / "AlgebraicSpecificationKB.metta",
                out_dir / "PropertyWorldKB.metta",
            ]:
                lines = kb_file.read_text(encoding="utf-8").splitlines()
                self.assertGreater(len(lines), 0)

                for line_idx, line in enumerate(lines, 1):
                    line = line.strip()
                    if not line or line.startswith(";"):
                        continue

                    # Each assertion line must be balanced individually
                    open_count = line.count("(")
                    close_count = line.count(")")
                    self.assertEqual(
                        open_count,
                        close_count,
                        f"Unbalanced parentheses in {kb_file.name} line {line_idx}: {line}",
                    )

                    # Running depth must never go negative
                    depth = 0
                    for char in line:
                        if char == "(":
                            depth += 1
                        elif char == ")":
                            depth -= 1
                        self.assertGreaterEqual(
                            depth, 0, f"Negative parenthesis depth in {kb_file.name} line {line_idx}"
                        )
                    self.assertEqual(depth, 0)

                    # Canonical syntax verification
                    self.assertTrue(
                        line.startswith("(: "),
                        f"Line does not start with (: in {kb_file.name} line {line_idx}: {line}",
                    )
                    self.assertTrue(
                        line.endswith(")"),
                        f"Line does not end with ) in {kb_file.name} line {line_idx}: {line}",
                    )

    def test_strict_determinism_across_runs(self) -> None:
        """Verify bit-for-bit identical outputs across independent execution runs."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            dir_a = Path(tmp_dir) / "run_a"
            dir_b = Path(tmp_dir) / "run_b"

            orchestrator = MultiSourceOrchestrator()

            # Run A
            orchestrator.run_ingestion(
                sources=["wordnet", "gene_ontology", "chebi", "openmath", "conceptnet"],
                download=False,
                output_dir=dir_a,
            )

            # Run B
            orchestrator.run_ingestion(
                sources=["wordnet", "gene_ontology", "chebi", "openmath", "conceptnet"],
                download=False,
                output_dir=dir_b,
            )

            casl_hash_a = _sha256(dir_a / "AlgebraicSpecificationKB.metta")
            casl_hash_b = _sha256(dir_b / "AlgebraicSpecificationKB.metta")
            pw_hash_a = _sha256(dir_a / "PropertyWorldKB.metta")
            pw_hash_b = _sha256(dir_b / "PropertyWorldKB.metta")

            self.assertEqual(
                casl_hash_a,
                casl_hash_b,
                "AlgebraicSpecificationKB.metta is not deterministic across runs!",
            )
            self.assertEqual(
                pw_hash_a,
                pw_hash_b,
                "PropertyWorldKB.metta is not deterministic across runs!",
            )

    def test_manifest_schema_and_completeness(self) -> None:
        """Verify the schema, status, and metadata recorded in run_manifest.json."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            out_dir = Path(tmp_dir) / "kb_manifest"
            orchestrator = MultiSourceOrchestrator()
            orchestrator.run_ingestion(
                sources=["wordnet", "gene_ontology", "chebi", "openmath", "conceptnet"],
                download=False,
                output_dir=out_dir,
            )

            manifest_path = out_dir / "run_manifest.json"
            self.assertTrue(manifest_path.exists())

            data = json.loads(manifest_path.read_text(encoding="utf-8"))

            self.assertEqual(data["contract_version"], CONTRACT_VERSION)
            self.assertEqual(data["pipeline_version"], "1.0.0")
            self.assertEqual(data["validation"]["status"], "PASSED")
            self.assertEqual(data["validation"]["error_count"], 0)

            # Summary metrics
            summary = data["summary"]
            self.assertEqual(summary["total_facts_emitted"], 230)
            self.assertEqual(summary["total_casl_facts"], 74)
            self.assertEqual(summary["total_property_world_facts"], 156)
            self.assertEqual(summary["sources_count"], 5)

            # Sources metadata
            sources = data["sources"]
            for expected_source in ["wordnet", "gene_ontology", "chebi", "openmath", "conceptnet"]:
                self.assertIn(expected_source, sources)
                src_meta = sources[expected_source]
                self.assertTrue(len(src_meta["version"]) > 0)
                self.assertTrue(len(src_meta["license"]) > 0)
                self.assertTrue(len(src_meta["uri"]) > 0)
                self.assertGreater(src_meta["facts_emitted"], 0)

            # Output files metadata
            out_files = data["output_files"]
            self.assertEqual(len(out_files), 2)
            filenames = {f["filename"] for f in out_files}
            self.assertEqual(
                filenames,
                {"AlgebraicSpecificationKB.metta", "PropertyWorldKB.metta"},
            )
            for f_meta in out_files:
                self.assertGreater(f_meta["size_bytes"], 0)
                self.assertEqual(len(f_meta["sha256"]), 64)


if __name__ == "__main__":
    unittest.main()
