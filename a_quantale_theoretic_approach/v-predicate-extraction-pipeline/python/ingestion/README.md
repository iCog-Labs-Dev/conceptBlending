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

## 5. Source Adapters Specification

### 5.1 Gene Ontology (`go_adapter.py`)
- Target: `http://purl.obolibrary.org/obo/go.obo`
- Format: Open Biomedical Ontologies (OBO) v1.2.
- Streaming: Line-by-line generator yielding non-obsolete term records.
- Canonical Perspectives: `taxonomic_kind` (`is_a`), `structural_composition` (`part_of`), `behavioral_process` (`regulates`).

### 5.2 ChEBI (`chebi_adapter.py`)
- Target: `https://ftp.ebi.ac.uk/pub/databases/chebi/ontology/chebi_lite.obo`
- Format: OBO Lite v1.2.
- Streaming: Line-by-line generator.
- Canonical Perspectives: `taxonomic_kind` (`is_a`), `structural_composition` (`has_part`).

### 5.3 OpenMath (`openmath_adapter.py`)
- Target: `https://www.openmath.org/cd/group1.ocd`
- Format: OpenMath 2.0 Content Dictionaries (XML).
- Canonical Perspectives: `functional_use` (operation signatures and properties), `causal_prerequisite` (axiomatic equations).

### 5.4 WordNet (`wordnet_adapter.py`)
- Target: `https://raw.githubusercontent.com/nltk/nltk_data/gh-pages/packages/corpora/wordnet.zip`
- Format: WordNet 3.0 Lexical Database archive.
- Acquisition: Downloaded via `SourceAcquisitionEngine`, extracted with safe permissions into cache directory, and configured with NLTK `WordNetCorpusReader`.
- Traversal & Filtering:
  - Controlled concept filtering via `concepts: Optional[Iterable[str]] = None`.
  - When `full_traversal=False`, defaults to Q4 target concepts (`phone`, `computer`, `battery`, `display`).
  - When `full_traversal=True`, streams all synsets incrementally via lazy generator (`yield`) without accumulating intermediate lists in memory (Rule 5).
- Offline Fallback: Deterministic offline fixture `fixtures/wordnet_sub.json` preserved for zero-network testing.
- Canonical Perspectives: `taxonomic_kind` (hypernyms), `structural_composition` (part meronyms), `functional_use` (hyponyms and gloss properties).

### 5.5 ConceptNet (`conceptnet_adapter.py`)
- Target: `https://s3.amazonaws.com/conceptnet/downloads/2019/edges/conceptnet-assertions-5.7.0.csv.gz`
- Format: Compressed tab-separated assertions (`URI \t relation \t start \t end \t metadata_json`).
- Streaming: Direct line-by-line decompression via `gzip.open` in text mode with bounded memory footprint (< 400MB RAM ceiling).
- Filtering:
  - Language filter: filters on-the-fly for English concepts (`/c/en/` prefix on start and end nodes, configurable via `languages`).
  - Relation filter: configurable subset filtering via `relations: Optional[Set[str]] = None`.
  - Concept filter: seed concept extraction via `concepts: Optional[Set[str]] = None`.
- Offline Fallback: Preserves `fixtures/conceptnet_sub.json` for deterministic offline testing.
- Canonical Perspectives: Maps all 7 canonical perspectives (`taxonomic_kind`, `structural_composition`, `functional_use`, `behavioral_process`, `spatial_context`, `descriptive_property`, `causal_prerequisite`).

---

## 6. Verification Checklist & Issue Traceability

- **Parent Issue:** [#111](https://github.com/iCog-Labs-Dev/conceptBlending/issues/111)
- **Acquisition Foundation Milestone:** [#112](https://github.com/iCog-Labs-Dev/conceptBlending/issues/112) (`[Ingestion 1/5]`)
- **WordNet & ConceptNet Production Milestone:** [#113](https://github.com/iCog-Labs-Dev/conceptBlending/issues/113) (`[Ingestion 2/5]`)
- **Unit Test Suites:**
  - `tests/python/test_source_acquisition.py` (offline mock HTTP & cache tests)
  - `tests/python/test_wordnet_adapter.py` (WordNet corpus acquisition, synset traversal, concept filtering, cache reuse)
  - `tests/python/test_conceptnet_adapter.py` (ConceptNet compressed streaming, language filtering, relation filtering, corrupt stream handling)
- **Regression Invariance:** Full pre-push test suite runs throttled via `pytest -n 2` under 400MB RSS memory ceiling.
- **Static Typing:** Verified 0 errors under `npx pyright`.
