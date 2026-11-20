"""End-to-End Storage Boundary Acceptance Test Suite for PathMap Compilation & Queries."""

from __future__ import annotations

import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

PIPELINE_ROOT = Path(__file__).resolve().parents[2]
if str(PIPELINE_ROOT / "python") not in sys.path:
    sys.path.insert(0, str(PIPELINE_ROOT / "python"))

from ingestion.orchestrator import IngestionSummary, MultiSourceOrchestrator

PIPELINE_ROOT = Path(__file__).resolve().parents[2]
PATHMAP_DIR = PIPELINE_ROOT / "prototype" / "pathmap-kb"
PATHMAP_BIN = PATHMAP_DIR / "target" / "release" / "perspective-pathmap-prototype"


class TestPathMapStorageBoundary(unittest.TestCase):
    """Verifies that 5-source ingestion output compiles cleanly into PathMap and responds to queries."""

    @classmethod
    def setUpClass(cls) -> None:
        """Ensure the PathMap release binary is compiled."""
        if not PATHMAP_BIN.exists():
            res = subprocess.run(
                ["cargo", "build", "--release"],
                cwd=str(PATHMAP_DIR),
                capture_output=True,
                text=True,
            )
            if res.returncode != 0:
                raise RuntimeError(
                    f"Failed to build PathMap prototype binary:\nSTDOUT:\n{res.stdout}\nSTDERR:\n{res.stderr}"
                )
        assert PATHMAP_BIN.exists(), f"PathMap binary not found at {PATHMAP_BIN}"

    def setUp(self) -> None:
        self.tmp_dir = tempfile.TemporaryDirectory()
        self.tmp_path = Path(self.tmp_dir.name)
        self.kb_dir = self.tmp_path / "kb"
        self.index_dir = self.tmp_path / "index"

        # 1. Run 5-source ingestion
        orchestrator = MultiSourceOrchestrator()
        self.summary = orchestrator.run_ingestion(
            sources=["wordnet", "gene_ontology", "chebi", "openmath", "conceptnet"],
            download=False,
            output_dir=self.kb_dir,
        )

        self.pw_kb = self.kb_dir / "PropertyWorldKB.metta"
        self.casl_kb = self.kb_dir / "AlgebraicSpecificationKB.metta"

    def tearDown(self) -> None:
        self.tmp_dir.cleanup()

    def _compile_shards(self) -> subprocess.CompletedProcess[str]:
        """Compile generated MeTTa KBs into PathMap radix-256 shards."""
        cmd = [
            str(PATHMAP_BIN),
            "build",
            "--property-kb",
            str(self.pw_kb),
            "--algebraic-kb",
            str(self.casl_kb),
            "--out",
            str(self.index_dir),
        ]
        return subprocess.run(cmd, capture_output=True, text=True)

    def test_five_source_pathmap_compilation_succeeds_without_skipped_worlds(self) -> None:
        """Verify 5-source MeTTa output compiles into 9 perspective shards with zero skipped worlds."""
        res = self._compile_shards()
        self.assertEqual(res.returncode, 0, f"Compilation failed: {res.stderr}\n{res.stdout}")

        # Stderr reports shard summary
        self.assertIn("built 9 perspective shards", res.stderr)
        self.assertIn("skipped_worlds: 0", res.stderr)
        self.assertIn("world_facts: 119", res.stderr)
        self.assertIn("property_facts: 37", res.stderr)

        # Index directory contains expected shard files
        self.assertTrue(self.index_dir.exists())
        self.assertTrue((self.index_dir / "manifest.tsv").exists())
        self.assertTrue((self.index_dir / "payloads.tsv").exists())
        self.assertTrue((self.index_dir / "symbols.tsv").exists())
        self.assertTrue((self.index_dir / "shards").is_dir())

    def test_representative_casl_algebra_queries(self) -> None:
        """Verify CASL algebraic queries for OpenMath operations and signatures."""
        res_build = self._compile_shards()
        self.assertEqual(res_build.returncode, 0)

        # Query OpenMath group operations
        cmd = [
            str(PATHMAP_BIN),
            "algebra",
            "--index",
            str(self.index_dir),
            "--perspective",
            "structural_composition",
            "--concept",
            "group",
            "--family",
            "operation",
        ]
        res = subprocess.run(cmd, capture_output=True, text=True)
        self.assertEqual(res.returncode, 0, f"Query failed: {res.stderr}")

        output = res.stdout
        self.assertIn("concept=group", output)
        self.assertIn("family=operation", output)
        self.assertIn("feature=operation", output)
        self.assertIn("(arrow group group group)", output)
        self.assertIn("feature=inverse", output)
        self.assertIn("(arrow group group)", output)
        self.assertIn("feature=identity", output)

    def test_representative_property_world_queries(self) -> None:
        """Verify Property-to-World queries for Gene Ontology, ChEBI, and WordNet."""
        res_build = self._compile_shards()
        self.assertEqual(res_build.returncode, 0)

        # 1. Gene Ontology: ATP synthesis in behavioral_process -> mitochondrial_inner_membrane
        cmd_go = [
            str(PATHMAP_BIN),
            "worlds",
            "--index",
            str(self.index_dir),
            "--perspective",
            "behavioral_process",
            "--concept",
            "atp_synthesis_coupled_proton_transport",
            "--property",
            "atp_synthesis_coupled_proton_transport",
        ]
        res_go = subprocess.run(cmd_go, capture_output=True, text=True)
        self.assertEqual(res_go.returncode, 0, f"GO query failed: {res_go.stderr}")
        self.assertIn("concept=atp_synthesis_coupled_proton_transport", res_go.stdout)
        self.assertIn("world=mitochondrial_inner_membrane", res_go.stdout)

        # 2. ChEBI: phenol chemical_state in state_lifecycle -> aqueous_solution
        cmd_chebi = [
            str(PATHMAP_BIN),
            "worlds",
            "--index",
            str(self.index_dir),
            "--perspective",
            "state_lifecycle",
            "--concept",
            "phenol",
            "--property",
            "chemical_state",
        ]
        res_chebi = subprocess.run(cmd_chebi, capture_output=True, text=True)
        self.assertEqual(res_chebi.returncode, 0, f"ChEBI query failed: {res_chebi.stderr}")
        self.assertIn("concept=phenol", res_chebi.stdout)
        self.assertIn("world=aqueous_solution", res_chebi.stdout)
        self.assertIn("world=organic_phase", res_chebi.stdout)


if __name__ == "__main__":
    unittest.main()
