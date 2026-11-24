"""Reproducible source acquisition data models and engine for v-predicate ingestion."""

from __future__ import annotations

from dataclasses import dataclass
import datetime
from enum import Enum
import hashlib
import json
from pathlib import Path
import socket
import time
from typing import Any, Callable, Dict, Optional
import urllib.error
import urllib.request
import uuid


class ProvenanceType(str, Enum):
    """Categorization of acquired raw knowledge source provenance."""

    FIXTURE = "fixture"
    CACHED = "cached"
    DOWNLOADED = "downloaded"


@dataclass(frozen=True)
class SourceArtifact:
    """Immutable metadata and localization descriptor for an acquired knowledge source file."""

    local_path: Path
    source_uri: str
    source_version: str
    license: str
    retrieval_time: str
    byte_size: int
    sha256_checksum: str
    provenance_type: ProvenanceType

    def to_dict(self) -> Dict[str, Any]:
        """Convert artifact metadata to dictionary representation."""
        return {
            "local_path": str(self.local_path),
            "source_uri": self.source_uri,
            "source_version": self.source_version,
            "license": self.license,
            "retrieval_time": self.retrieval_time,
            "byte_size": self.byte_size,
            "sha256_checksum": self.sha256_checksum,
            "provenance_type": (
                self.provenance_type.value
                if isinstance(self.provenance_type, Enum)
                else str(self.provenance_type)
            ),
        }

    def to_sidecar_dict(self) -> Dict[str, Any]:
        """Generate sidecar metadata representation stored alongside cached files."""
        return {
            "source_uri": self.source_uri,
            "source_version": self.source_version,
            "version": self.source_version,
            "license": self.license,
            "retrieval_time": self.retrieval_time,
            "byte_size": self.byte_size,
            "sha256_checksum": self.sha256_checksum,
        }


@dataclass
class AcquisitionConfig:
    """Configuration options governing source artifact acquisition, retries, and caching."""

    cache_dir: Optional[Path] = None
    timeout: float = 30.0
    max_retries: int = 3
    backoff_factor: float = 1.5
    force_refresh: bool = False


class SourceAcquisitionError(Exception):
    """Exception raised when source acquisition fails."""

    def __init__(
        self,
        message: str,
        source_key: Optional[str] = None,
        uri: Optional[str] = None,
        cause: Optional[Exception] = None,
    ) -> None:
        super().__init__(message)
        self.source_key = source_key
        self.uri = uri
        self.cause = cause

    def __str__(self) -> str:
        parts = [super().__str__()]
        if self.source_key:
            parts.append(f"[source_key={self.source_key}]")
        if self.uri:
            parts.append(f"[uri={self.uri}]")
        if self.cause:
            parts.append(f"[cause={self.cause!r}]")
        return " ".join(parts)


def compute_file_sha256(path: Path) -> str:
    """Compute the hex-encoded SHA-256 digest of a file in streaming chunks."""
    h = hashlib.sha256()
    with path.open("rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()


class SourceAcquisitionEngine:
    """Acquisition engine providing atomic downloads, checksum validation, and cache management."""

    def acquire(
        self,
        source_key: str,
        source_uri: str,
        target_filename: str,
        cache_dir: Optional[Path] = None,
        download: bool = False,
        force_refresh: bool = False,
        fixture_path: Optional[Path] = None,
        expected_sha256: Optional[str] = None,
        version: str = "unknown",
        license_str: str = "unknown",
        timeout: float = 30.0,
        max_retries: int = 3,
        backoff_factor: float = 1.5,
        version_extractor: Optional[Callable[[Path], str]] = None,
    ) -> SourceArtifact:
        """Acquire a knowledge source file with atomic staging, verification, and provenance tracking."""
        resolved_cache_dir = (
            Path(cache_dir).resolve()
            if cache_dir is not None
            else (Path.home() / ".cache" / "concept_blending" / source_key).resolve()
        )
        target_path = resolved_cache_dir / target_filename
        sidecar_path = resolved_cache_dir / f"{target_filename}.meta.json"

        # Check existing cache validity
        cache_is_valid = False
        cached_sha = ""
        sidecar_data: Dict[str, Any] = {}

        if target_path.exists() and target_path.is_file() and target_path.stat().st_size > 0:
            cached_sha = compute_file_sha256(target_path)
            # Read sidecar if available
            if sidecar_path.is_file():
                try:
                    with sidecar_path.open("r", encoding="utf-8") as sf:
                        loaded = json.load(sf)
                        if isinstance(loaded, dict):
                            sidecar_data = loaded
                except Exception:
                    sidecar_data = {}

            # Validate cache integrity against expected_sha256 or sidecar checksum
            expected_sidecar_sha = sidecar_data.get("sha256_checksum")
            if expected_sha256:
                cache_is_valid = cached_sha == expected_sha256
            elif expected_sidecar_sha:
                cache_is_valid = cached_sha == expected_sidecar_sha
            else:
                # No expected checksum provided and no sidecar checksum: existing file treated as valid cache
                cache_is_valid = True

        # Cache Hit Path:
        # If cache is valid and not force_refresh:
        # (Both download=True and download=False reuse valid cache)
        if cache_is_valid and not force_refresh:
            cached_version = (
                sidecar_data.get("source_version")
                or sidecar_data.get("version")
            )
            if (not cached_version or cached_version == "unknown") and version_extractor is not None:
                try:
                    extracted = version_extractor(target_path)
                    if extracted and extracted != "unknown":
                        cached_version = extracted
                except Exception:
                    pass
            if not cached_version:
                cached_version = version
            cached_license = sidecar_data.get("license") or license_str
            cached_time = (
                sidecar_data.get("retrieval_time")
                or datetime.datetime.now(datetime.timezone.utc).isoformat()
            )
            cached_uri = sidecar_data.get("source_uri") or source_uri

            # If sidecar was missing, generate it now for future cache checks
            if not sidecar_path.is_file():
                resolved_cache_dir.mkdir(parents=True, exist_ok=True)
                sidecar_payload = {
                    "source_uri": cached_uri,
                    "source_version": cached_version,
                    "version": cached_version,
                    "license": cached_license,
                    "retrieval_time": cached_time,
                    "byte_size": target_path.stat().st_size,
                    "sha256_checksum": cached_sha,
                }
                try:
                    with sidecar_path.open("w", encoding="utf-8") as sf:
                        json.dump(sidecar_payload, sf, indent=2)
                except Exception:
                    pass

            return SourceArtifact(
                local_path=target_path,
                source_uri=cached_uri,
                source_version=cached_version,
                license=cached_license,
                retrieval_time=cached_time,
                byte_size=target_path.stat().st_size,
                sha256_checksum=cached_sha,
                provenance_type=ProvenanceType.CACHED,
            )

        # Cache is invalid/corrupt or missing or force_refresh requested
        if target_path.exists() and not cache_is_valid:
            # Dirty/corrupt cache detected
            if download or force_refresh:
                target_path.unlink(missing_ok=True)
                sidecar_path.unlink(missing_ok=True)

        # Offline Fixture Fallback Path:
        # When download=False and cache is invalid/missing
        if not download:
            if fixture_path is not None and fixture_path.exists() and fixture_path.is_file():
                fixture_sha = compute_file_sha256(fixture_path)
                fixture_time = datetime.datetime.now(datetime.timezone.utc).isoformat()
                fixture_version = version
                if version_extractor is not None:
                    try:
                        extracted = version_extractor(fixture_path)
                        if extracted and extracted != "unknown":
                            fixture_version = extracted
                    except Exception:
                        pass
                return SourceArtifact(
                    local_path=fixture_path,
                    source_uri=source_uri,
                    source_version=fixture_version,
                    license=license_str,
                    retrieval_time=fixture_time,
                    byte_size=fixture_path.stat().st_size,
                    sha256_checksum=fixture_sha,
                    provenance_type=ProvenanceType.FIXTURE,
                )
            raise SourceAcquisitionError(
                f"No verified cached file found and no valid fixture provided for '{source_key}'",
                source_key=source_key,
                uri=source_uri,
            )

        # Network Download Path: download=True
        # Fail-fast production enforcement: NEVER fallback to fixture if download=True fails!
        resolved_cache_dir.mkdir(parents=True, exist_ok=True)
        req = urllib.request.Request(
            source_uri,
            headers={"User-Agent": "conceptBlending/1.0 (Linux x86_64)"},
        )

        last_error: Optional[Exception] = None
        for attempt in range(1, max_retries + 1):
            unique_token = uuid.uuid4().hex
            temp_file = resolved_cache_dir / f"{target_filename}.tmp.{unique_token}"
            temp_sidecar = resolved_cache_dir / f"{target_filename}.meta.json.tmp.{unique_token}"

            try:
                hasher = hashlib.sha256()
                with urllib.request.urlopen(req, timeout=timeout) as resp, temp_file.open("wb") as out:
                    while True:
                        chunk = resp.read(65536)
                        if not chunk:
                            break
                        out.write(chunk)
                        hasher.update(chunk)

                computed_sha = hasher.hexdigest()

                if expected_sha256 and computed_sha != expected_sha256:
                    raise SourceAcquisitionError(
                        f"Checksum verification failed for '{source_key}': "
                        f"expected {expected_sha256}, got {computed_sha}",
                        source_key=source_key,
                        uri=source_uri,
                    )

                byte_size = temp_file.stat().st_size
                if byte_size == 0:
                    temp_file.unlink(missing_ok=True)
                    temp_sidecar.unlink(missing_ok=True)
                    raise SourceAcquisitionError(
                        f"Acquired artifact for '{source_key}' is empty (0 bytes)",
                        source_key=source_key,
                        uri=source_uri,
                    )

                retrieval_time = datetime.datetime.now(datetime.timezone.utc).isoformat()

                effective_version = version
                if version_extractor is not None:
                    try:
                        extracted = version_extractor(temp_file)
                        if extracted and extracted != "unknown":
                            effective_version = extracted
                    except Exception:
                        pass

                # Write sidecar atomically
                sidecar_payload = {
                    "source_uri": source_uri,
                    "source_version": effective_version,
                    "version": effective_version,
                    "license": license_str,
                    "retrieval_time": retrieval_time,
                    "byte_size": byte_size,
                    "sha256_checksum": computed_sha,
                }
                with temp_sidecar.open("w", encoding="utf-8") as sf:
                    json.dump(sidecar_payload, sf, indent=2)

                # Atomically promote temp files to final paths
                temp_sidecar.replace(sidecar_path)
                temp_file.replace(target_path)

                return SourceArtifact(
                    local_path=target_path,
                    source_uri=source_uri,
                    source_version=effective_version,
                    license=license_str,
                    retrieval_time=retrieval_time,
                    byte_size=byte_size,
                    sha256_checksum=computed_sha,
                    provenance_type=ProvenanceType.DOWNLOADED,
                )

            except (
                urllib.error.URLError,
                TimeoutError,
                socket.timeout,
                ConnectionResetError,
                OSError,
            ) as exc:
                last_error = exc
                if attempt < max_retries:
                    if backoff_factor > 0:
                        time.sleep(backoff_factor * attempt)
            except SourceAcquisitionError:
                # Checksum, zero-byte or domain error: do not retry
                raise
            except Exception as exc:
                last_error = exc
                break
            finally:
                if temp_file.exists():
                    temp_file.unlink(missing_ok=True)
                if temp_sidecar.exists():
                    temp_sidecar.unlink(missing_ok=True)

        raise SourceAcquisitionError(
            f"Failed to acquire artifact for '{source_key}' from '{source_uri}' after {max_retries} attempts: {last_error}",
            source_key=source_key,
            uri=source_uri,
            cause=last_error,
        )
