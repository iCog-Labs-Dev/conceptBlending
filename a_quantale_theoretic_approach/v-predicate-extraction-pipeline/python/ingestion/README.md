# Knowledge Source Acquisition Architecture

## 1. Overview & Objective

The **Source Acquisition Subsystem** (`ingestion.acquisition`) provides a unified, deterministic, and crash-resilient mechanism for localizing raw knowledge source files across external biomedical, chemical, mathematical, and linguistic ontologies.

Implemented under **Issue #112** ([Ingestion 1/5] Reproducible Source-Acquisition Foundation), it replaces direct, unprotected downloads and silent fixture fallbacks with:
- **Atomic Two-Phase Staging**: Downloads stream to temporary uuid-staged files (`<filename>.tmp.<uuid>`) and are promoted to destination targets via atomic rename (`os.replace`) only after full stream consumption and cryptographic checksum verification.
- **Sidecar Metadata (`<filename>.meta.json`)**: Every localized source artifact maintains an adjacent JSON sidecar recording authoritative provenance, retrieval timestamp, byte length, and SHA-256 digest.
- **Integrity & Corruption Recovery**: Cached artifacts are verified via SHA-256 before reuse; corrupted or truncated files are automatically purged and cleanly re-downloaded.
- **Fail-Fast Production Invariant**: When `download=True` is requested, network failures or checksum discrepancies fail fast via `SourceAcquisitionError`, strictly banning silent fallbacks to bundled sample fixtures.
- **Offline Fixture Mode**: When `download=False`, the engine verifies whether a local cache exists; if not, it returns the bundled offline test fixture with explicit `ProvenanceType.FIXTURE` metadata.

---

## 2. Architecture & Control Flow

```
                      +---------------------------------------+
                      |         BaseSourceAdapter.fetch()      |
                      +---------------------------------------+
                                          |
                                          v
                      +---------------------------------------+
                      |       SourceAcquisitionEngine         |
                      |              acquire()                |
                      +---------------------------------------+
                                          |
                        +-----------------+-----------------+
                        |                                   |
             [download == False]                    [download == True]
                        |                                   |
                        v                                   v
             +----------------------+            +----------------------+
             | Check Local Cache &  |            | Check Local Cache &  |
             | Sidecar SHA-256      |            | Sidecar SHA-256      |
             +----------------------+            +----------------------+
                 /              \                    /              \
         [Valid]          [Corrupt/None]     [Valid & No     [Missing or
            |                    |             Refresh]     Force Refresh]
            v                    v                |                 |
     +-------------+      +-------------+         v                 v
     | Return      |      | Return      |  +-------------+   +---------------+
     | CACHED      |      | FIXTURE     |  | Return      |   | Atomic Staging|
     | Artifact    |      | Artifact    |  | CACHED      |   | Download to   |
     +-------------+      +-------------+  | Artifact    |   | .tmp.<uuid>   |
                                           +-------------+   +---------------+
                                                                    |
                                                            [Stream Complete
                                                            & SHA-256 Match]
                                                                    |
                                                                    v
                                                             +---------------+
                                                             | Atomic Swap:  |
                                                             | .tmp -> cache |
                                                             | Write sidecar |
                                                             +---------------+
                                                                    |
                                                                    v
                                                             +---------------+
                                                             | Return        |
                                                             | DOWNLOADED    |
                                                             | Artifact      |
                                                             +---------------+
```

---

## 3. Data Models & Sidecar Specification

### `ProvenanceType` Enum
- `ProvenanceType.FIXTURE = "fixture"`: Bundled static fixture (offline test fixture).
- `ProvenanceType.CACHED = "cached"`: Cryptographically verified local cache from a prior run.
- `ProvenanceType.DOWNLOADED = "downloaded"`: Fresh network retrieval verified against SHA-256.

### `SourceArtifact` Immutable Data Model
```python
@dataclass(frozen=True)
class SourceArtifact:
    local_path: Path
    source_uri: str
    source_version: str
    license: str
    retrieval_time: str      # ISO-8601 UTC string
    byte_size: int
    sha256_checksum: str
    provenance_type: ProvenanceType
```

### Sidecar Metadata Schema (`<filename>.meta.json`)
Adjacent to every cached file (e.g. `go.obo.meta.json` next to `go.obo`), the sidecar persists:
```json
{
  "source_uri": "http://purl.obolibrary.org/obo/go.obo",
  "source_version": "releases/2026-11-24",
  "version": "releases/2026-11-24",
  "license": "CC-BY-4.0",
  "retrieval_time": "2026-11-24T10:30:00.000000+00:00",
  "byte_size": 34125902,
  "sha256_checksum": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
}
```

---

## 4. Operational Guide: Offline vs. Production Modes

### Running Ingestion in Offline Fixture Mode (Default)
In CI and unit testing environments without external network access, adapters execute with `download=False`.
```bash
python3 a_quantale_theoretic_approach/v-predicate-extraction-pipeline/python/ingestion/ingest_cli.py \
  --sources all \
  --output-dir /tmp/offline_kb
```
- Each adapter acquires its bundled test fixture.
- Provenance is explicitly tagged as `FIXTURE`.
- Zero network socket requests are initiated.

### Running Ingestion in Production Download Mode
When downloading live ontologies for full-scale knowledge base construction:
```bash
python3 a_quantale_theoretic_approach/v-predicate-extraction-pipeline/python/ingestion/ingest_cli.py \
  --sources go,chebi,openmath \
  --output-dir /var/data/canonical_kb \
  --download
```
- First invocation downloads upstream ontologies via atomic staging and records `<filename>.meta.json`.
- Subsequent invocations verify SHA-256 checksums from cache; if unchanged, `ProvenanceType.CACHED` is returned with zero network calls.
- In case of network timeout, exponential backoff retries up to 3 times before raising `SourceAcquisitionError`.

---

## 5. Verification Checklist & Issue Traceability

- **Parent Issue:** [#111](https://github.com/iCog-Labs-Dev/conceptBlending/issues/111)
- **Task Issue:** [#112](https://github.com/iCog-Labs-Dev/conceptBlending/issues/112)
- **Unit Test Suite:** `tests/python/test_source_acquisition.py` (9 offline mock HTTP & cache tests).
- **Regression Invariance:** Full pre-push test suite (115+ items) runs throttled via `pytest -n 2` under 400MB RSS memory ceiling.
- **Static Typing:** Verified 0 errors under `npx pyright`.
