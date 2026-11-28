"""Unit tests for the ConceptNet adapter and canonical V-predicate mapping."""

from __future__ import annotations

import gzip
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import MagicMock, patch
import urllib.error

PIPELINE_ROOT = Path(__file__).resolve().parents[2]
if str(PIPELINE_ROOT / "python") not in sys.path:
    sys.path.insert(0, str(PIPELINE_ROOT / "python"))

from ingestion.acquisition import (  # noqa: E402
    ProvenanceType,
    SourceAcquisitionError,
    SourceArtifact,
)
from ingestion.conceptnet_adapter import ConceptNetAdapter, _sanitize_symbol  # noqa: E402
from v_predicate_contract import (  # noqa: E402
    CONTRACT_VERSION,
    FactKind,
    FactOrigin,
    Perspective,
    PredicateFact,
    PropertyFact,
    SortFact,
    render_document,
    validate_record_set,
)


class MockStreamingResponse:
    """Mock HTTP streaming response for deterministic offline acquisition tests."""

    def __init__(self, data: bytes) -> None:
        self.buffer = io.BytesIO(data)

    def read(self, amt: int = 65536) -> bytes:
        return self.buffer.read(amt)

    def __enter__(self) -> MockStreamingResponse:
        return self

    def __exit__(self, exc_type: object, exc_val: object, exc_tb: object) -> None:
        pass


def _create_mock_conceptnet_tsv_gz() -> bytes:
    """Create a minimal gzip-compressed ConceptNet assertions file."""
    lines = [
        "/a/[/r/IsA/,/c/en/computer/,/c/en/machine/]\t/r/IsA\t/c/en/computer\t/c/en/machine\t{\"weight\": 3.5}\n",
        "/a/[/r/UsedFor/,/c/en/computer/,/c/en/compute/]\t/r/UsedFor\t/c/en/computer\t/c/en/compute\t{\"weight\": 2.8}\n",
        "/a/[/r/CapableOf/,/c/en/computer/,/c/en/process/]\t/r/CapableOf\t/c/en/computer\t/c/en/process\t{\"weight\": 2.0}\n",
        "/a/[/r/IsA/,/c/fr/ordinateur/,/c/fr/machine/]\t/r/IsA\t/c/fr/ordinateur\t/c/fr/machine\t{\"weight\": 3.0}\n",
        "/a/[/r/HasProperty/,/c/en/computer/,/c/en/electronic/]\t/r/HasProperty\t/c/en/computer\t/c/en/electronic\t{\"weight\": 2.5}\n",
    ]
    raw = "".join(lines).encode("utf-8")
    return gzip.compress(raw)


class ConceptNetAdapterTests(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture_path = PIPELINE_ROOT / "fixtures" / "conceptnet_sub.json"
        self.adapter = ConceptNetAdapter(fixture_path=self.fixture_path)

    def test_adapter_initialization_and_metadata(self) -> None:
        self.assertEqual(self.adapter.source_name, "conceptnet")
        self.assertEqual(self.adapter.version, "5.7.0")
        self.assertEqual(self.adapter.license, "CC-BY-SA-4.0")

    def test_fetch_resolves_fixture_path(self) -> None:
        fetched = self.adapter.fetch(download=False)
        self.assertTrue(fetched.exists())
        self.assertEqual(fetched.resolve(), self.fixture_path.resolve())

    def test_fetch_artifact_fixture(self) -> None:
        artifact = self.adapter.fetch_artifact(download=False)
        self.assertIsInstance(artifact, SourceArtifact)
        self.assertEqual(artifact.provenance_type, ProvenanceType.FIXTURE)
        self.assertEqual(artifact.local_path.resolve(), self.fixture_path.resolve())
        self.assertEqual(artifact.source_version, "5.7.0")
        self.assertEqual(artifact.license, "CC-BY-SA-4.0")
        self.assertGreater(artifact.byte_size, 0)
        self.assertEqual(len(artifact.sha256_checksum), 64)

    @patch("urllib.request.urlopen")
    def test_fetch_artifact_mock_download_and_cache(self, mock_urlopen: MagicMock) -> None:
        mock_gz_bytes = _create_mock_conceptnet_tsv_gz()
        mock_urlopen.return_value = MockStreamingResponse(mock_gz_bytes)

        with tempfile.TemporaryDirectory() as tmp_dir:
            cache_path = Path(tmp_dir)
            adapter = ConceptNetAdapter(cache_dir=cache_path, fixture_path=self.fixture_path)

            # 1. Cold download
            artifact = adapter.fetch_artifact(download=True)
            self.assertEqual(artifact.provenance_type, ProvenanceType.DOWNLOADED)
            self.assertTrue(artifact.local_path.exists())
            self.assertEqual(artifact.byte_size, len(mock_gz_bytes))

            sidecar = cache_path / "conceptnet-assertions-5.7.0.csv.gz.meta.json"
            self.assertTrue(sidecar.is_file())
            sidecar_data = json.loads(sidecar.read_text(encoding="utf-8"))
            self.assertEqual(sidecar_data["sha256_checksum"], artifact.sha256_checksum)

            # 2. Cache hit
            mock_urlopen.reset_mock()
            cached_artifact = adapter.fetch_artifact(download=True, force_refresh=False)
            mock_urlopen.assert_not_called()
            self.assertEqual(cached_artifact.provenance_type, ProvenanceType.CACHED)
            self.assertEqual(cached_artifact.sha256_checksum, artifact.sha256_checksum)

    @patch("urllib.request.urlopen")
    def test_zero_byte_download_rejection(self, mock_urlopen: MagicMock) -> None:
        mock_urlopen.return_value = MockStreamingResponse(b"")

        with tempfile.TemporaryDirectory() as tmp_dir:
            cache_path = Path(tmp_dir)
            adapter = ConceptNetAdapter(cache_dir=cache_path, fixture_path=self.fixture_path)

            with self.assertRaises(SourceAcquisitionError) as ctx:
                adapter.fetch_artifact(download=True)

            self.assertIn("0 bytes", str(ctx.exception))
            tmp_files = list(cache_path.glob("*.tmp*"))
            self.assertEqual(len(tmp_files), 0, "No orphaned temporary files on failure")

    @patch("urllib.request.urlopen")
    def test_download_failure_raises_and_preserves_offline_mode(self, mock_urlopen: MagicMock) -> None:
        mock_urlopen.side_effect = urllib.error.URLError("Network unreachable")

        with tempfile.TemporaryDirectory() as tmp_dir:
            cache_path = Path(tmp_dir)
            adapter = ConceptNetAdapter(cache_dir=cache_path, fixture_path=self.fixture_path)

            # Fail-fast enforcement: download=True raises SourceAcquisitionError
            with self.assertRaises(SourceAcquisitionError):
                adapter.fetch_artifact(download=True)

            # Offline mode download=False cleanly falls back to bundled fixture
            fallback_art = adapter.fetch_artifact(download=False)
            self.assertEqual(fallback_art.provenance_type, ProvenanceType.FIXTURE)
            self.assertTrue(fallback_art.local_path.exists())

    def test_corrupt_compressed_stream_handling(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            cache_path = Path(tmp_dir)
            corrupt_file = cache_path / "conceptnet-assertions-5.7.0.csv.gz"
            corrupt_file.write_bytes(b"\x1f\x8b\x08\x00\x00\x00corrupted_non_gzip_data")

            # Seed sidecar to simulate cached corrupt archive
            sidecar = cache_path / "conceptnet-assertions-5.7.0.csv.gz.meta.json"
            sidecar.write_text(json.dumps({"sha256_checksum": "dummy"}), encoding="utf-8")

            adapter = ConceptNetAdapter(cache_dir=cache_path)
            adapter.last_artifact = SourceArtifact(
                local_path=corrupt_file,
                source_uri="mock://test",
                source_version="5.7.0",
                license="CC-BY-SA-4.0",
                retrieval_time="2026-11-27T00:00:00Z",
                byte_size=corrupt_file.stat().st_size,
                sha256_checksum="dummy",
                provenance_type=ProvenanceType.CACHED,
            )

            with self.assertRaises(ValueError) as ctx:
                list(adapter.stream_facts())
            self.assertIn("Corrupted compressed ConceptNet archive", str(ctx.exception))

    def test_compressed_gzip_streaming_and_parsing(self) -> None:
        mock_gz_bytes = _create_mock_conceptnet_tsv_gz()
        with tempfile.TemporaryDirectory() as tmp_dir:
            cache_path = Path(tmp_dir)
            gz_file = cache_path / "conceptnet-assertions-5.7.0.csv.gz"
            gz_file.write_bytes(mock_gz_bytes)

            adapter = ConceptNetAdapter(cache_dir=cache_path)
            adapter.last_artifact = SourceArtifact(
                local_path=gz_file,
                source_uri="mock://conceptnet",
                source_version="5.7.0",
                license="CC-BY-SA-4.0",
                retrieval_time="2026-11-27T00:00:00Z",
                byte_size=len(mock_gz_bytes),
                sha256_checksum="dummy",
                provenance_type=ProvenanceType.CACHED,
            )

            facts = list(adapter.stream_facts())
            self.assertGreater(len(facts), 0)
            # French assertion must be filtered out by default English language filter
            concepts = {getattr(f, "concept", "") for f in facts if hasattr(f, "concept")}
            self.assertIn("computer", concepts)
            self.assertNotIn("ordinateur", concepts)
            validate_record_set(facts)

    def test_language_filtering(self) -> None:
        mock_gz_bytes = _create_mock_conceptnet_tsv_gz()
        with tempfile.TemporaryDirectory() as tmp_dir:
            cache_path = Path(tmp_dir)
            gz_file = cache_path / "conceptnet-assertions-5.7.0.csv.gz"
            gz_file.write_bytes(mock_gz_bytes)

            # English only
            adapter_en = ConceptNetAdapter(cache_dir=cache_path, languages={"en"})
            adapter_en.last_artifact = SourceArtifact(
                local_path=gz_file,
                source_uri="mock://conceptnet",
                source_version="5.7.0",
                license="CC-BY-SA-4.0",
                retrieval_time="2026-11-27T00:00:00Z",
                byte_size=len(mock_gz_bytes),
                sha256_checksum="dummy",
                provenance_type=ProvenanceType.CACHED,
            )
            en_facts = list(adapter_en.stream_facts())
            self.assertTrue(all(getattr(f, "concept", None) == "computer" for f in en_facts))

            # French only
            adapter_fr = ConceptNetAdapter(cache_dir=cache_path, languages={"fr"})
            adapter_fr.last_artifact = adapter_en.last_artifact
            fr_facts = list(adapter_fr.stream_facts())
            self.assertEqual(len(fr_facts), 1)
            self.assertEqual(getattr(fr_facts[0], "concept", None), "ordinateur")

    def test_relation_filtering(self) -> None:
        # Filter for only IsA relations
        facts = list(self.adapter.stream_facts(relations={"/r/IsA"}))
        self.assertGreater(len(facts), 0)
        for f in facts:
            self.assertIsInstance(f, SortFact)
            if isinstance(f, SortFact):
                self.assertEqual(f.perspective, Perspective.TAXONOMIC_KIND)

    def test_concept_seed_filtering(self) -> None:
        # Filter for only computer
        facts = list(self.adapter.stream_facts(concepts={"computer"}))
        self.assertGreater(len(facts), 0)
        for f in facts:
            self.assertEqual(getattr(f, "concept", None), "computer")

    def test_stream_facts_returns_generator(self) -> None:
        stream = self.adapter.stream_facts()
        self.assertTrue(hasattr(stream, "__iter__"))
        self.assertTrue(hasattr(stream, "__next__"))
        first_five = [next(stream) for _ in range(5)]
        self.assertEqual(len(first_five), 5)

    def test_stream_facts_honors_limit(self) -> None:
        facts = list(self.adapter.stream_facts(limit=3))
        self.assertEqual(len(facts), 3)

    def test_relation_mappings(self) -> None:
        facts = list(self.adapter.stream_facts())
        kinds = {fact.kind for fact in facts}
        self.assertIn(FactKind.SORT, kinds)
        self.assertIn(FactKind.PREDICATE, kinds)
        self.assertIn(FactKind.PROPERTY, kinds)

        # Check /r/IsA -> SortFact (taxonomic_kind)
        sort_facts = [f for f in facts if isinstance(f, SortFact)]
        computer_sort = next((f for f in sort_facts if f.concept == "computer"), None)
        self.assertIsNotNone(computer_sort)
        assert computer_sort is not None
        self.assertEqual(computer_sort.perspective, Perspective.TAXONOMIC_KIND)
        self.assertEqual(computer_sort.sort, "machine")

        # Check /r/UsedFor -> PredicateFact (functional_use)
        pred_facts = [f for f in facts if isinstance(f, PredicateFact)]
        used_for_facts = [f for f in pred_facts if f.perspective == Perspective.FUNCTIONAL_USE]
        self.assertTrue(any(f.concept == "computer" and "(used_for computer compute)" in f.predicate for f in used_for_facts))

        # Check /r/CapableOf -> PredicateFact (behavioral_process)
        capable_facts = [f for f in pred_facts if f.perspective == Perspective.BEHAVIORAL_PROCESS]
        self.assertTrue(any(f.concept == "computer" for f in capable_facts))

        # Check /r/AtLocation -> PredicateFact (spatial_context)
        location_facts = [f for f in pred_facts if f.perspective == Perspective.SPATIAL_CONTEXT]
        self.assertTrue(any(f.concept == "computer" for f in location_facts))

        # Check /r/PartOf -> PredicateFact (structural_composition)
        part_facts = [f for f in pred_facts if f.perspective == Perspective.STRUCTURAL_COMPOSITION]
        self.assertTrue(len(part_facts) > 0)

        # Check /r/HasProperty -> PropertyFact (descriptive_property)
        prop_facts = [f for f in facts if isinstance(f, PropertyFact)]
        self.assertTrue(any(f.concept == "computer" and f.perspective == Perspective.DESCRIPTIVE_PROPERTY for f in prop_facts))

        # Check /r/Causes -> PredicateFact (causal_prerequisite)
        causes_facts = [f for f in pred_facts if f.perspective == Perspective.CAUSAL_PREREQUISITE]
        self.assertTrue(len(causes_facts) > 0)

    def test_truth_value_scaling(self) -> None:
        facts = list(self.adapter.stream_facts())
        for fact in facts:
            self.assertGreaterEqual(fact.truth.strength, 0.0)
            self.assertLessEqual(fact.truth.strength, 1.0)
            self.assertGreaterEqual(fact.truth.confidence, 0.1)
            self.assertLessEqual(fact.truth.confidence, 0.95)

    def test_provenance_and_origin(self) -> None:
        facts = list(self.adapter.stream_facts())
        for fact in facts:
            self.assertEqual(fact.provenance.source, "conceptnet")
            self.assertEqual(fact.provenance.license, "CC-BY-SA-4.0")
            self.assertEqual(fact.provenance.origin, FactOrigin.ASSERTED)
            self.assertEqual(fact.provenance.transformation, "conceptnet_adapter_v1")

    def test_all_facts_pass_contract_validation(self) -> None:
        facts = list(self.adapter.stream_facts())
        self.assertGreater(len(facts), 10)
        validate_record_set(facts)

    def test_render_document_compatibility(self) -> None:
        facts = list(self.adapter.stream_facts(limit=5))
        rendered = render_document(facts)
        self.assertIn(f"; V-predicate contract: {CONTRACT_VERSION}", rendered)
        for fact in facts:
            self.assertIn(f"(: {fact.evidence_id} (≞ ", rendered)
            self.assertIn(f"(: {fact.evidence_id}_provenance (≞ ", rendered)

    def test_deterministic_reruns(self) -> None:
        facts1 = list(self.adapter.stream_facts())
        facts2 = list(self.adapter.stream_facts())
        self.assertEqual([f.evidence_id for f in facts1], [f.evidence_id for f in facts2])
        self.assertEqual([f.to_metta() for f in facts1], [f.to_metta() for f in facts2])

    def test_symbol_sanitization(self) -> None:
        self.assertEqual(_sanitize_symbol("/c/en/computer/n"), "computer")
        self.assertEqual(_sanitize_symbol("3d-printer"), "n_3d_printer")
        self.assertEqual(_sanitize_symbol("personal computer"), "personal_computer")
        self.assertEqual(_sanitize_symbol(""), "unknown")


if __name__ == "__main__":
    unittest.main()
