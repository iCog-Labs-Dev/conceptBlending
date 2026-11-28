"""Unit tests for reproducible source acquisition foundation, atomic caching, and mock HTTP."""

from __future__ import annotations

import hashlib
import io
import json
from pathlib import Path
import socket
import sys
import tempfile
import unittest
from unittest.mock import MagicMock, call, patch
import urllib.error

PIPELINE_ROOT = Path(__file__).resolve().parents[2]
if str(PIPELINE_ROOT / "python") not in sys.path:
    sys.path.insert(0, str(PIPELINE_ROOT / "python"))

from ingestion.acquisition import (
    ProvenanceType,
    SourceAcquisitionEngine,
    SourceAcquisitionError,
    compute_file_sha256,
)
from ingestion.chebi_adapter import ChebiAdapter
from ingestion.go_adapter import GeneOntologyAdapter
from ingestion.openmath_adapter import OpenMathAdapter


class MockStreamingResponse:
    """Mock HTTP response providing chunked streaming reads and context manager support."""

    def __init__(self, data: bytes) -> None:
        self.buffer = io.BytesIO(data)

    def read(self, amt: int = 65536) -> bytes:
        return self.buffer.read(amt)

    def __enter__(self) -> MockStreamingResponse:
        return self

    def __exit__(self, exc_type: object, exc_val: object, exc_tb: object) -> None:
        pass


class TestSourceAcquisition(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.cache_dir = Path(self.temp_dir.name)
        self.engine = SourceAcquisitionEngine()
        self.sample_obo_content = (
            b"format-version: 1.2\n"
            b"data-version: releases/2026-11-24\n"
            b"[Term]\n"
            b"id: GO:0008150\n"
            b"name: biological_process\n"
            b"namespace: biological_process\n"
        )
        self.sample_sha = hashlib.sha256(self.sample_obo_content).hexdigest()

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    @patch("urllib.request.urlopen")
    def test_cold_download_creates_artifact_and_sidecar(self, mock_urlopen: MagicMock) -> None:
        mock_urlopen.return_value = MockStreamingResponse(self.sample_obo_content)

        artifact = self.engine.acquire(
            source_key="gene_ontology",
            source_uri="http://example.org/go.obo",
            target_filename="go.obo",
            cache_dir=self.cache_dir,
            download=True,
            version="releases/2026-11-24",
            license_str="CC-BY-4.0",
        )

        self.assertEqual(artifact.provenance_type, ProvenanceType.DOWNLOADED)
        self.assertTrue(artifact.local_path.exists())
        self.assertEqual(artifact.local_path.name, "go.obo")
        self.assertEqual(artifact.sha256_checksum, self.sample_sha)
        self.assertEqual(artifact.byte_size, len(self.sample_obo_content))
        self.assertEqual(artifact.source_version, "releases/2026-11-24")

        # Verify sidecar metadata existence and content
        sidecar_path = self.cache_dir / "go.obo.meta.json"
        self.assertTrue(sidecar_path.is_file(), "Sidecar metadata JSON must be created")
        sidecar_data = json.loads(sidecar_path.read_text(encoding="utf-8"))
        self.assertEqual(sidecar_data["sha256_checksum"], self.sample_sha)
        self.assertEqual(sidecar_data["byte_size"], len(self.sample_obo_content))
        self.assertEqual(sidecar_data["source_version"], "releases/2026-11-24")

        # Verify no orphaned temp files
        tmp_files = list(self.cache_dir.glob("*.tmp*"))
        self.assertEqual(len(tmp_files), 0, "All temporary staging files must be cleaned up")

    @patch("urllib.request.urlopen")
    def test_cache_hit_avoids_network_call(self, mock_urlopen: MagicMock) -> None:
        # Pre-seed cache with verified file and sidecar
        target_file = self.cache_dir / "go.obo"
        target_file.write_bytes(self.sample_obo_content)
        sidecar_file = self.cache_dir / "go.obo.meta.json"
        sidecar_file.write_text(
            json.dumps(
                {
                    "source_uri": "http://example.org/go.obo",
                    "source_version": "releases/2026-11-24",
                    "license": "CC-BY-4.0",
                    "retrieval_time": "2026-11-24T00:00:00Z",
                    "byte_size": len(self.sample_obo_content),
                    "sha256_checksum": self.sample_sha,
                }
            ),
            encoding="utf-8",
        )

        artifact = self.engine.acquire(
            source_key="gene_ontology",
            source_uri="http://example.org/go.obo",
            target_filename="go.obo",
            cache_dir=self.cache_dir,
            download=True,
            force_refresh=False,
        )

        mock_urlopen.assert_not_called()
        self.assertEqual(artifact.provenance_type, ProvenanceType.CACHED)
        self.assertEqual(artifact.sha256_checksum, self.sample_sha)
        self.assertEqual(artifact.local_path, target_file)

    @patch("urllib.request.urlopen")
    def test_checksum_mismatch_triggers_refresh(self, mock_urlopen: MagicMock) -> None:
        # Setup corrupted cache (content does not match sidecar)
        target_file = self.cache_dir / "go.obo"
        target_file.write_bytes(b"tampered or truncated data")
        sidecar_file = self.cache_dir / "go.obo.meta.json"
        sidecar_file.write_text(
            json.dumps(
                {
                    "source_uri": "http://example.org/go.obo",
                    "source_version": "releases/2026-11-24",
                    "license": "CC-BY-4.0",
                    "retrieval_time": "2026-11-24T00:00:00Z",
                    "byte_size": 100,
                    "sha256_checksum": self.sample_sha,
                }
            ),
            encoding="utf-8",
        )

        fresh_content = b"fresh non-corrupted data"
        fresh_sha = hashlib.sha256(fresh_content).hexdigest()
        mock_urlopen.return_value = MockStreamingResponse(fresh_content)

        artifact = self.engine.acquire(
            source_key="gene_ontology",
            source_uri="http://example.org/go.obo",
            target_filename="go.obo",
            cache_dir=self.cache_dir,
            download=True,
        )

        self.assertEqual(mock_urlopen.call_count, 1)
        self.assertEqual(artifact.provenance_type, ProvenanceType.DOWNLOADED)
        self.assertEqual(artifact.sha256_checksum, fresh_sha)
        self.assertEqual(target_file.read_bytes(), fresh_content)

    @patch("urllib.request.urlopen")
    def test_interrupted_download_preserves_valid_cache(self, mock_urlopen: MagicMock) -> None:
        # Pre-seed valid cache
        target_file = self.cache_dir / "go.obo"
        target_file.write_bytes(self.sample_obo_content)
        sidecar_file = self.cache_dir / "go.obo.meta.json"
        sidecar_file.write_text(
            json.dumps(
                {
                    "source_uri": "http://example.org/go.obo",
                    "source_version": "releases/2026-11-24",
                    "license": "CC-BY-4.0",
                    "retrieval_time": "2026-11-24T00:00:00Z",
                    "byte_size": len(self.sample_obo_content),
                    "sha256_checksum": self.sample_sha,
                }
            ),
            encoding="utf-8",
        )

        class InterruptedStreamingResponse:
            def __init__(self) -> None:
                self.has_read = False

            def read(self, amt: int = 65536) -> bytes:
                if not self.has_read:
                    self.has_read = True
                    return b"partial bytes"
                raise socket.timeout("Network connection timed out mid-transfer")

            def __enter__(self) -> InterruptedStreamingResponse:
                return self

            def __exit__(self, exc_type: object, exc_val: object, exc_tb: object) -> None:
                pass

        mock_urlopen.return_value = InterruptedStreamingResponse()

        with self.assertRaises(SourceAcquisitionError):
            self.engine.acquire(
                source_key="gene_ontology",
                source_uri="http://example.org/go.obo",
                target_filename="go.obo",
                cache_dir=self.cache_dir,
                download=True,
                force_refresh=True,
                max_retries=1,
                backoff_factor=0.0,
            )

        # Existing valid cache must remain intact and unmodified
        self.assertEqual(target_file.read_bytes(), self.sample_obo_content)
        # Sibling tmp files must be purged
        tmp_files = list(self.cache_dir.glob("*.tmp*"))
        self.assertEqual(len(tmp_files), 0, "Staging files must be purged on interruption")

    @patch("time.sleep")
    @patch("urllib.request.urlopen")
    def test_bounded_retries_and_exponential_backoff(
        self, mock_urlopen: MagicMock, mock_sleep: MagicMock
    ) -> None:
        mock_urlopen.side_effect = urllib.error.URLError("Network unreachable")

        with self.assertRaises(SourceAcquisitionError) as ctx:
            self.engine.acquire(
                source_key="gene_ontology",
                source_uri="http://example.org/go.obo",
                target_filename="go.obo",
                cache_dir=self.cache_dir,
                download=True,
                max_retries=3,
                backoff_factor=1.5,
            )

        self.assertEqual(mock_urlopen.call_count, 3)
        self.assertEqual(mock_sleep.call_count, 2)
        mock_sleep.assert_has_calls([call(1.5), call(3.0)])
        self.assertIn("gene_ontology", str(ctx.exception))
        self.assertIsInstance(ctx.exception.cause, urllib.error.URLError)

    @patch("urllib.request.urlopen")
    def test_force_refresh_bypasses_cache(self, mock_urlopen: MagicMock) -> None:
        # Pre-seed valid cache
        target_file = self.cache_dir / "go.obo"
        target_file.write_bytes(self.sample_obo_content)
        sidecar_file = self.cache_dir / "go.obo.meta.json"
        sidecar_file.write_text(
            json.dumps({"sha256_checksum": self.sample_sha}),
            encoding="utf-8",
        )

        refreshed_content = b"updated content version 2"
        refreshed_sha = hashlib.sha256(refreshed_content).hexdigest()
        mock_urlopen.return_value = MockStreamingResponse(refreshed_content)

        artifact = self.engine.acquire(
            source_key="gene_ontology",
            source_uri="http://example.org/go.obo",
            target_filename="go.obo",
            cache_dir=self.cache_dir,
            download=True,
            force_refresh=True,
        )

        self.assertEqual(mock_urlopen.call_count, 1)
        self.assertEqual(artifact.provenance_type, ProvenanceType.DOWNLOADED)
        self.assertEqual(artifact.sha256_checksum, refreshed_sha)
        self.assertEqual(target_file.read_bytes(), refreshed_content)

    @patch("urllib.request.urlopen")
    def test_production_download_fails_without_silent_fixture_masking(
        self, mock_urlopen: MagicMock
    ) -> None:
        mock_urlopen.side_effect = urllib.error.URLError("Connection refused")
        fixture_path = PIPELINE_ROOT / "fixtures" / "bioenergetics_sub_go.obo"

        with self.assertRaises(SourceAcquisitionError):
            self.engine.acquire(
                source_key="gene_ontology",
                source_uri="http://example.org/go.obo",
                target_filename="go.obo",
                cache_dir=self.cache_dir,
                download=True,
                fixture_path=fixture_path,
                max_retries=1,
                backoff_factor=0.0,
            )

    def test_offline_fixture_mode_returns_fixture_provenance(self) -> None:
        fixture_path = PIPELINE_ROOT / "fixtures" / "bioenergetics_sub_go.obo"
        self.assertTrue(fixture_path.exists())

        artifact = self.engine.acquire(
            source_key="gene_ontology",
            source_uri="http://example.org/go.obo",
            target_filename="go.obo",
            cache_dir=self.cache_dir,
            download=False,
            fixture_path=fixture_path,
            version="releases/2026-11-01",
            license_str="CC-BY-4.0",
        )

        self.assertEqual(artifact.provenance_type, ProvenanceType.FIXTURE)
        self.assertEqual(artifact.local_path, fixture_path)
        self.assertEqual(artifact.byte_size, fixture_path.stat().st_size)
        self.assertEqual(artifact.sha256_checksum, compute_file_sha256(fixture_path))

    def test_adapter_backward_compatibility(self) -> None:
        go_adapter = GeneOntologyAdapter()
        chebi_adapter = ChebiAdapter()
        openmath_adapter = OpenMathAdapter()

        go_path = go_adapter.fetch(download=False)
        self.assertIsInstance(go_path, Path)
        self.assertTrue(go_path.exists())
        self.assertIsNotNone(go_adapter.last_artifact)
        assert go_adapter.last_artifact is not None
        self.assertEqual(go_adapter.last_artifact.provenance_type, ProvenanceType.FIXTURE)

        chebi_path = chebi_adapter.fetch(download=False)
        self.assertIsInstance(chebi_path, Path)
        self.assertTrue(chebi_path.exists())
        self.assertIsNotNone(chebi_adapter.last_artifact)
        assert chebi_adapter.last_artifact is not None
        self.assertEqual(chebi_adapter.last_artifact.provenance_type, ProvenanceType.FIXTURE)

        openmath_path = openmath_adapter.fetch(download=False)
        self.assertIsInstance(openmath_path, Path)
        self.assertTrue(openmath_path.exists())
        self.assertIsNotNone(openmath_adapter.last_artifact)
        assert openmath_adapter.last_artifact is not None
        self.assertEqual(openmath_adapter.last_artifact.provenance_type, ProvenanceType.FIXTURE)

    @patch("urllib.request.urlopen")
    def test_zero_byte_download_rejects_and_preserves_valid_cache(
        self, mock_urlopen: MagicMock
    ) -> None:
        # Pre-seed valid cache
        target_file = self.cache_dir / "go.obo"
        target_file.write_bytes(self.sample_obo_content)
        sidecar_file = self.cache_dir / "go.obo.meta.json"
        sidecar_file.write_text(
            json.dumps(
                {
                    "source_uri": "http://example.org/go.obo",
                    "source_version": "releases/2026-11-24",
                    "license": "CC-BY-4.0",
                    "retrieval_time": "2026-11-24T00:00:00Z",
                    "byte_size": len(self.sample_obo_content),
                    "sha256_checksum": self.sample_sha,
                }
            ),
            encoding="utf-8",
        )

        # Mock HTTP 200 with 0 bytes
        mock_urlopen.return_value = MockStreamingResponse(b"")

        with self.assertRaises(SourceAcquisitionError) as ctx:
            self.engine.acquire(
                source_key="gene_ontology",
                source_uri="http://example.org/go.obo",
                target_filename="go.obo",
                cache_dir=self.cache_dir,
                download=True,
                force_refresh=True,
            )

        self.assertIn("empty (0 bytes)", str(ctx.exception))
        # Cache must remain completely untouched
        self.assertEqual(target_file.read_bytes(), self.sample_obo_content)
        self.assertEqual(compute_file_sha256(target_file), self.sample_sha)
        sidecar_data = json.loads(sidecar_file.read_text(encoding="utf-8"))
        self.assertEqual(sidecar_data["sha256_checksum"], self.sample_sha)
        # Staging files must be purged
        tmp_files = list(self.cache_dir.glob("*.tmp*"))
        self.assertEqual(len(tmp_files), 0, "All temporary staging files must be cleaned up")

    @patch("urllib.request.urlopen")
    def test_downloaded_version_diverges_from_fixture(
        self, mock_urlopen: MagicMock
    ) -> None:
        divergent_obo = (
            b"format-version: 1.2\n"
            b"data-version: releases/2026-11-24\n"
            b"[Term]\n"
            b"id: GO:0015986\n"
            b"name: ATP synthesis\n"
        )
        mock_urlopen.return_value = MockStreamingResponse(divergent_obo)

        adapter = GeneOntologyAdapter(cache_dir=self.cache_dir)
        # Fixture version is releases/2026-11-01
        self.assertEqual(adapter.version, "releases/2026-11-01")

        artifact = adapter.fetch_artifact(download=True, force_refresh=True)

        self.assertEqual(artifact.provenance_type, ProvenanceType.DOWNLOADED)
        self.assertEqual(artifact.source_version, "releases/2026-11-24")
        self.assertEqual(adapter.version, "releases/2026-11-24")
        self.assertEqual(adapter.provenance.source_version, "releases/2026-11-24")

        sidecar_path = self.cache_dir / "go.obo.meta.json"
        self.assertTrue(sidecar_path.is_file())
        sidecar_data = json.loads(sidecar_path.read_text(encoding="utf-8"))
        self.assertEqual(sidecar_data["source_version"], "releases/2026-11-24")
        self.assertEqual(sidecar_data["version"], "releases/2026-11-24")


if __name__ == "__main__":
    unittest.main()
