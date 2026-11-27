"""Unit tests for WordNet source adapter under canonical v-predicate/1 contract."""

from __future__ import annotations

import hashlib
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import MagicMock, patch
import urllib.error
import zipfile

PIPELINE_ROOT = Path(__file__).resolve().parents[2]
if str(PIPELINE_ROOT / "python") not in sys.path:
    sys.path.insert(0, str(PIPELINE_ROOT / "python"))

from ingestion.acquisition import (
    ProvenanceType,
    SourceAcquisitionError,
    SourceArtifact,
    compute_file_sha256,
)
from ingestion.wordnet_adapter import WordNetAdapter, safe_metta_symbol
from v_predicate_contract import (
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


def _create_mock_wordnet_zip() -> bytes:
    """Create a minimal valid WordNet zip archive containing mock database files."""
    bio = io.BytesIO()
    with zipfile.ZipFile(bio, "w", zipfile.ZIP_DEFLATED) as zf:
        for fname in (
            "cntlist.rev", "index.sense",
            "index.adj", "index.adv", "index.verb",
            "data.adv", "data.verb",
            "adj.exc", "adv.exc", "noun.exc", "verb.exc",
        ):
            zf.writestr(f"wordnet/{fname}", "")
        zf.writestr("wordnet/index.noun", "phone n 1 0 1 0 00000000\n")
        zf.writestr("wordnet/data.noun", "00000000 00 n 01 phone 0 000 | an electronic device\n")
        zf.writestr("wordnet/lexnames", "00\tnoun.Tops\t1\n")
        zf.writestr("wordnet/data.adj", "  WordNet 3.0 Copyright 2006 by Princeton University\n")
    return bio.getvalue()


class TestWordNetAdapter(unittest.TestCase):
    def setUp(self) -> None:
        self.adapter = WordNetAdapter(max_props_per_concept=10, max_worlds_per_prop=5, use_nltk=False)

    def test_adapter_metadata(self) -> None:
        self.assertEqual(self.adapter.source_name, "wordnet")
        self.assertEqual(self.adapter.version, "3.0")
        self.assertEqual(self.adapter.license, "WordNet-3.0")

    def test_safe_metta_symbol(self) -> None:
        self.assertEqual(safe_metta_symbol("electronic equipment"), "electronic_equipment")
        self.assertEqual(safe_metta_symbol("phone (device)"), "phone_device")
        self.assertEqual(safe_metta_symbol("123-abc"), "c_123_abc")
        self.assertEqual(safe_metta_symbol(""), "c_empty")
        self.assertEqual(safe_metta_symbol("cellular-telephone"), "cellular_telephone")

    def test_fetch_initializes_marker(self) -> None:
        path = self.adapter.fetch(download=False)
        self.assertTrue(path.exists())
        self.assertIn("wordnet", str(path))

    def test_fetch_artifact_fixture(self) -> None:
        artifact = self.adapter.fetch_artifact(download=False)
        self.assertIsInstance(artifact, SourceArtifact)
        self.assertEqual(artifact.provenance_type, ProvenanceType.FIXTURE)
        self.assertTrue(artifact.local_path.exists())
        self.assertEqual(artifact.source_version, "3.0")
        self.assertEqual(artifact.license, "WordNet-3.0")
        self.assertGreater(artifact.byte_size, 0)
        self.assertEqual(len(artifact.sha256_checksum), 64)

    @patch("urllib.request.urlopen")
    def test_fetch_artifact_mock_download_and_cache(self, mock_urlopen: MagicMock) -> None:
        mock_zip_bytes = _create_mock_wordnet_zip()
        mock_urlopen.return_value = MockStreamingResponse(mock_zip_bytes)

        with tempfile.TemporaryDirectory() as tmp_dir:
            cache_path = Path(tmp_dir)
            adapter = WordNetAdapter(cache_dir=cache_path, use_nltk=False)
            adapter.expected_sha256 = hashlib.sha256(mock_zip_bytes).hexdigest()

            # 1. Cold download
            artifact = adapter.fetch_artifact(download=True)
            self.assertEqual(artifact.provenance_type, ProvenanceType.DOWNLOADED)
            self.assertTrue(artifact.local_path.exists())
            self.assertEqual(artifact.byte_size, len(mock_zip_bytes))

            sidecar = cache_path / "wordnet.zip.meta.json"
            self.assertTrue(sidecar.is_file())
            sidecar_data = json.loads(sidecar.read_text(encoding="utf-8"))
            self.assertEqual(sidecar_data["sha256_checksum"], artifact.sha256_checksum)

            # 2. Cache hit (second call does not trigger network)
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
            adapter = WordNetAdapter(cache_dir=cache_path, use_nltk=False)

            with self.assertRaises(SourceAcquisitionError) as ctx:
                adapter.fetch_artifact(download=True)

            self.assertIn("0 bytes", str(ctx.exception))
            tmp_files = list(cache_path.glob("*.tmp*"))
            self.assertEqual(len(tmp_files), 0, "No orphaned temporary files on failure")

    @patch("urllib.request.urlopen")
    def test_failed_download_preserves_valid_cache(self, mock_urlopen: MagicMock) -> None:
        mock_zip_bytes = _create_mock_wordnet_zip()
        with tempfile.TemporaryDirectory() as tmp_dir:
            cache_path = Path(tmp_dir)
            target_file = cache_path / "wordnet.zip"
            target_file.write_bytes(mock_zip_bytes)
            sha = compute_file_sha256(target_file)
            sidecar = cache_path / "wordnet.zip.meta.json"
            sidecar.write_text(
                json.dumps(
                    {
                        "source_uri": "https://example.org/wordnet.zip",
                        "source_version": "3.0",
                        "license": "WordNet-3.0",
                        "retrieval_time": "2026-11-27T00:00:00Z",
                        "byte_size": len(mock_zip_bytes),
                        "sha256_checksum": sha,
                    }
                ),
                encoding="utf-8",
            )

            # Simulate network failure during force_refresh
            mock_urlopen.side_effect = urllib.error.URLError("Connection refused")
            adapter = WordNetAdapter(cache_dir=cache_path, use_nltk=False)
            adapter.expected_sha256 = sha

            with self.assertRaises(SourceAcquisitionError):
                adapter.fetch_artifact(download=True, force_refresh=True)

            # When download fails, existing valid cache is strictly preserved
            self.assertTrue(target_file.exists())
            fallback_artifact = adapter.fetch_artifact(download=False)
            self.assertEqual(fallback_artifact.provenance_type, ProvenanceType.CACHED)
            self.assertEqual(fallback_artifact.sha256_checksum, sha)

    def test_concept_seed_filtering(self) -> None:
        stream = self.adapter.stream_facts(concepts=["battery"])
        facts = list(stream)
        self.assertGreater(len(facts), 0)
        # All facts must relate to battery
        for fact in facts:
            if hasattr(fact, "concept"):
                self.assertEqual(getattr(fact, "concept"), "battery")

    def test_adapter_init_concepts_filtering(self) -> None:
        adapter = WordNetAdapter(concepts=["display"], use_nltk=False)
        facts = list(adapter.stream_facts())
        self.assertGreater(len(facts), 0)
        for fact in facts:
            if hasattr(fact, "concept"):
                self.assertEqual(getattr(fact, "concept"), "display")

    def test_stream_facts_generator_and_limit(self) -> None:
        stream = self.adapter.stream_facts(limit=5)
        self.assertTrue(hasattr(stream, "__iter__"))
        self.assertTrue(hasattr(stream, "__next__"))
        facts = list(stream)
        self.assertEqual(len(facts), 5)

    def test_canonical_snake_case_perspectives(self) -> None:
        facts = list(self.adapter.stream_facts(limit=30))
        for f in facts:
            self.assertTrue(hasattr(f, "perspective"))
            perspective = getattr(f, "perspective", None)
            self.assertIsInstance(perspective, Perspective)
            if isinstance(perspective, Perspective):
                self.assertNotIn("-", perspective.value)
                self.assertIn(
                    perspective,
                    {
                        Perspective.TAXONOMIC_KIND,
                        Perspective.STRUCTURAL_COMPOSITION,
                        Perspective.FUNCTIONAL_USE,
                        Perspective.DESCRIPTIVE_PROPERTY,
                    },
                )

    def test_relational_mappings_and_fact_kinds(self) -> None:
        facts = list(self.adapter.stream_facts(limit=50))
        kinds = {f.kind for f in facts}
        self.assertIn(FactKind.SORT, kinds)
        self.assertIn(FactKind.PREDICATE, kinds)
        self.assertIn(FactKind.PROPERTY, kinds)
        self.assertIn(FactKind.PROPERTY_WORLD, kinds)

        # Hypernyms -> SortFact
        sort_facts = [f for f in facts if isinstance(f, SortFact)]
        phone_sorts = [f for f in sort_facts if f.concept == "phone"]
        self.assertTrue(len(phone_sorts) > 0)
        self.assertEqual(phone_sorts[0].perspective, Perspective.TAXONOMIC_KIND)

        # Meronyms -> PredicateFact (part_of target concept)
        pred_facts = [f for f in facts if isinstance(f, PredicateFact)]
        meronym_preds = [f for f in pred_facts if f.perspective == Perspective.STRUCTURAL_COMPOSITION]
        self.assertTrue(any(f.concept == "phone" and "(part_of " in f.predicate for f in meronym_preds))

        # Functional gloss properties -> PropertyFact
        prop_facts = [f for f in facts if isinstance(f, PropertyFact)]
        func_props = [f for f in prop_facts if f.perspective == Perspective.FUNCTIONAL_USE]
        self.assertTrue(len(func_props) > 0)

    def test_origin_distinction_asserted_vs_heuristic(self) -> None:
        facts = list(self.adapter.stream_facts(limit=60))

        asserted_facts = [f for f in facts if f.provenance.origin == FactOrigin.ASSERTED]
        self.assertGreater(len(asserted_facts), 0)

        generated_facts = [f for f in facts if f.provenance.origin == FactOrigin.GENERATED]
        self.assertGreater(len(generated_facts), 0)
        for gf in generated_facts:
            self.assertEqual(gf.provenance.transformation, "wordnet_heuristic_world_projection")
            self.assertLessEqual(gf.truth.confidence, 0.80)

    def test_full_traversal_flag_support(self) -> None:
        adapter = WordNetAdapter(full_traversal=True, use_nltk=False)
        self.assertTrue(adapter.full_traversal)
        facts = list(adapter.stream_facts(limit=10))
        self.assertGreater(len(facts), 0)
        validate_record_set(facts)

    def test_deterministic_reruns(self) -> None:
        facts1 = list(self.adapter.stream_facts(limit=15))
        facts2 = list(self.adapter.stream_facts(limit=15))
        self.assertEqual([f.evidence_id for f in facts1], [f.evidence_id for f in facts2])
        self.assertEqual([f.to_metta() for f in facts1], [f.to_metta() for f in facts2])

    def test_contract_validation_passes(self) -> None:
        facts = list(self.adapter.stream_facts())
        self.assertGreater(len(facts), 10)
        validate_record_set(facts)

    def test_render_document_compatibility(self) -> None:
        facts = list(self.adapter.stream_facts(limit=10))
        rendered = render_document(facts)
        self.assertIn(f"; V-predicate contract: {CONTRACT_VERSION}", rendered)
        for fact in facts:
            self.assertIn(f"(: {fact.evidence_id} (≞ ", rendered)
            self.assertIn(f"(: {fact.evidence_id}_provenance (≞ ", rendered)

    def test_wordnet_metadata_and_checksum_pinning(self) -> None:
        adapter = WordNetAdapter(use_nltk=False)
        self.assertEqual(adapter.source_name, "wordnet")
        self.assertEqual(adapter.version, "3.0")
        self.assertEqual(adapter.license, "WordNet-3.0")
        self.assertEqual(
            adapter.expected_sha256,
            "cbda5ea6eef7f36a97a43d4a75f85e07fccbb4f23657d27b4ccbc93e2646ab59",
        )
        self.assertEqual(
            adapter.source_uri,
            "https://raw.githubusercontent.com/nltk/nltk_data/gh-pages/packages/corpora/wordnet.zip",
        )

    @patch("urllib.request.urlopen")
    def test_production_download_parses_genuine_corpus(self, mock_urlopen: MagicMock) -> None:
        mock_zip_bytes = _create_mock_wordnet_zip()
        mock_urlopen.return_value = MockStreamingResponse(mock_zip_bytes)

        with tempfile.TemporaryDirectory() as tmp_dir:
            cache_path = Path(tmp_dir)
            adapter = WordNetAdapter(cache_dir=cache_path, use_nltk=True)
            mock_sha = hashlib.sha256(mock_zip_bytes).hexdigest()
            adapter.expected_sha256 = mock_sha

            artifact = adapter.fetch_artifact(download=True)
            self.assertEqual(artifact.provenance_type, ProvenanceType.DOWNLOADED)
            self.assertEqual(adapter._corpus_mode, "production")
            self.assertIsNotNone(adapter._wn)

            facts = list(adapter.stream_facts(concepts=["phone"]))
            self.assertGreater(len(facts), 0)
            for f in facts:
                self.assertEqual(f.provenance.source_uri, adapter.source_uri)
                self.assertEqual(f.provenance.source_version, "3.0")
                self.assertEqual(f.provenance.license, "WordNet-3.0")

            prop_facts = [f for f in facts if isinstance(f, PropertyFact)]
            self.assertTrue(any(pf.concept == "phone" for pf in prop_facts))

    def test_fixture_mode_ignores_ambient_nltk(self) -> None:
        mock_ambient_wn = MagicMock()
        with patch.dict("sys.modules", {"nltk.corpus": MagicMock(wordnet=mock_ambient_wn)}):
            adapter = WordNetAdapter(use_nltk=True)
            self.assertIsNone(adapter._wn)
            self.assertIsNone(adapter._corpus_mode)

            artifact = adapter.fetch_artifact(download=False)
            self.assertEqual(artifact.provenance_type, ProvenanceType.FIXTURE)
            self.assertEqual(adapter._corpus_mode, "fixture")
            self.assertIsNone(adapter._wn)

            facts = list(adapter.stream_facts(concepts=["phone"]))
            self.assertGreater(len(facts), 0)
            for f in facts:
                self.assertEqual(f.provenance.source_uri, "bundled://wordnet_offline")
                self.assertEqual(f.provenance.source_version, "3.0")
                self.assertEqual(f.provenance.license, "WordNet-3.0")

            mock_ambient_wn.synsets.assert_not_called()

    @patch("urllib.request.urlopen")
    def test_corrupt_extraction_fails_fast_without_fallback(self, mock_urlopen: MagicMock) -> None:
        corrupt_bytes = b"PK\x03\x04corrupted_payload_not_a_valid_zip"
        mock_urlopen.return_value = MockStreamingResponse(corrupt_bytes)

        with tempfile.TemporaryDirectory() as tmp_dir:
            cache_path = Path(tmp_dir)
            adapter = WordNetAdapter(cache_dir=cache_path, use_nltk=True)
            mock_sha = hashlib.sha256(corrupt_bytes).hexdigest()
            adapter.expected_sha256 = mock_sha

            with self.assertRaises(SourceAcquisitionError):
                adapter.fetch_artifact(download=True)

            self.assertIsNone(adapter._wn)
            # Ensure fail-fast in production mode with zero fallback to fixture
            adapter._corpus_mode = "production"
            with self.assertRaises(SourceAcquisitionError) as ctx:
                list(adapter.stream_facts(concepts=["phone"]))
            self.assertIn("not initialized", str(ctx.exception))

    @patch("urllib.request.urlopen")
    def test_archive_replacement_invalidates_stale_extraction(self, mock_urlopen: MagicMock) -> None:
        mock_zip_bytes = _create_mock_wordnet_zip()
        mock_urlopen.return_value = MockStreamingResponse(mock_zip_bytes)

        with tempfile.TemporaryDirectory() as tmp_dir:
            cache_path = Path(tmp_dir)
            stale_marker = cache_path / ".extracted_wordnet_oldsha12345678"
            stale_marker.write_text("old\n", encoding="utf-8")
            stale_file = cache_path / "wordnet" / "stale_file.txt"
            stale_file.parent.mkdir(parents=True, exist_ok=True)
            stale_file.write_text("stale data\n", encoding="utf-8")

            adapter = WordNetAdapter(cache_dir=cache_path, use_nltk=False)
            mock_sha = hashlib.sha256(mock_zip_bytes).hexdigest()
            adapter.expected_sha256 = mock_sha

            artifact = adapter.fetch_artifact(download=True)
            self.assertEqual(artifact.provenance_type, ProvenanceType.DOWNLOADED)

            self.assertFalse(stale_marker.exists())
            self.assertFalse(stale_file.exists())
            new_marker = cache_path / f".extracted_wordnet_{artifact.sha256_checksum[:16]}"
            self.assertTrue(new_marker.exists())


if __name__ == "__main__":
    unittest.main()
