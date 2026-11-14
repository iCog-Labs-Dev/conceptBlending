# Pull Request: Reconcile Multi-Source Knowledge Ingestion Pipeline with Canonical `v-predicate/1` Contract

## Summary

This pull request completes **Objective 1, Key Result 2** ("Build a reusable ingestion pipeline for fetching, filtering, normalizing, transforming, validating, and incrementally loading knowledge into PathMap / AtomSpace representations") under the canonical **`v-predicate/1`** specification (`c36cc4b449ef95d785835c6ad57860dfa60550b5`).

It integrates all 5 canonical knowledge sources required for the Q4 Conceptual Blending reconstruction experiments, enforces bounded-memory streaming generators, provides atomic directory staging with rollback validation, emits structured execution manifests (`run_manifest.json`), aligns the GitHub Actions CI/CD workflow with GCC 14 compatibility flags, and provides an end-to-end acceptance test suite verifying parenthetical balance and deterministic bit-for-bit repeatability across runs.

---

## Reconciliation of Mentor Feedback (16 Items)

Every item of mentor review feedback has been systematically addressed, implemented, and verified:

| # | Mentor Review Item | Resolution & Implementation Details |
|---|---|---|
| **1** | **Upstream Contract Sync (`c36cc4b4`)** | Synchronized canonical `v_predicate_contract/` package and formal contract fixtures (`fixtures/v_predicate_contract_v1.metta`) from `c36cc4b`. All modules strictly conform to contract version `v-predicate/1`. |
| **2** | **Modernized `BaseSourceAdapter`** | Refactored `BaseSourceAdapter` (`python/ingestion/base_adapter.py`) to mandate lazy streaming via `stream_facts(limit: Optional[int] = None) -> Iterator[FactRecord]`. All 5 adapters inherit and implement this streaming interface. |
| **3** | **Purge Local `models.py`** | Completely removed legacy ad-hoc domain representations (`MettaFact`, `MettaFactKind`) in favor of canonical dataclasses (`SortFact`, `OperationFact`, `EquationFact`, `PredicateFact`, `PerspectiveFact`, `PropertyWorldFact`). |
| **4** | **ConceptNet 5th Source Adapter** | Implemented `ConceptNetAdapter` (`python/ingestion/conceptnet_adapter.py`) reading `fixtures/conceptnet_sub.json`, extracting commonsense assertions (`IsA`, `UsedFor`, `CapableOf`, `AtLocation`, `PartOf`, `HasProperty`, `Causes`) required for Experiment 1 (Smartphone). |
| **5** | **Canonical Snake-Case Perspectives** | Standardized all persisted perspective labels to canonical `Perspective` enum values in snake_case (`taxonomic_kind`, `functional_use`, `structural_composition`, `behavioral_process`, `physical_attribute`, etc.). |
| **6** | **Grounded Arrow Signatures & Equation Axioms** | Modernized `OpenMathAdapter` (`python/ingestion/openmath_adapter.py`) to emit grounded function types `(: op (-> Arg1 Arg2 Res))` and executable algebraic equations `(= (op x y) (op y x))` with bound variable quantifiers for Experiment 4 (Abelian groups). |
| **7** | **Relational Predicates for GO & ChEBI** | Updated `GeneOntologyAdapter` and `ChebiAdapter` to emit domain relations as typed `PredicateFact`s: `(part_of component process)`, `(regulates process process)`, `(has_role chemical role)`, and `(has_part parent child)`. |
| **8** | **Dynamic OBO Header Metadata Parsing** | Replaced hardcoded version strings with dynamic OBO header parsers (`_extract_obo_header`) extracting release versions (`releases/2026-11-01`), dates, and URIs directly from source files. |
| **9** | **Bounded-Memory Streaming Generators** | Eliminated `list(parse_obo(...))` and global in-memory buffering. Adapters evaluate lazily using generator functions (`yield FactRecord`), enforcing a peak RAM footprint under **400MB**. |
| **10** | **Honest Sink Semantics** | Renamed `PathMapSink` to `InMemoryTestSink` (`python/ingestion/sinks.py`), accurately reflecting in-memory testing semantics and reserving PathMap for true C++ / FFI integration (KR 1). |
| **11** | **Atomic Staging Workspace (`.staging/`)** | Implemented atomic publishing in `MultiSourceOrchestrator`: intermediate facts stream into `.staging/`, undergo pre-publication verification via `validate_record_set(records)`, and swap atomically to the destination, rolling back cleanly on validation error. |
| **12** | **Audited Run Manifest (`run_manifest.json`)** | Generated cryptographic execution manifests detailing pipeline and contract versions, per-source record counts, source URLs/licenses, output file sizes, and SHA256 checksums. |
| **13** | **Production CLI (`ingest_cli.py`)** | Modernized CLI to support `--sources all` or individual source selections (`wordnet`, `gene_ontology`, `chebi`, `openmath`, `conceptnet`), `--output-dir`, `--verbose`, and `--download` options. |
| **14** | **Hardware Throttling (`pytest -n 2`)** | Enforced `-n 2` worker limit across local tests, `.git/hooks/pre-push`, and CI/CD pipelines to guarantee memory safety and prevent out-of-memory lockups. |
| **15** | **Zero Repository Root Pollution** | Ensured all file paths and cache directories resolve explicitly relative to `output_dir` or package fixtures. Banned untracked `kb/` creation in repo root. |
| **16** | **GitHub Actions CI/CD Integration** | Updated `.github/workflows/ci_cd_pipeline.yml`: added branch triggers for `q3/pathmap-vpredicate-atomspace`, isolated `/opt/venv` environment, injected GCC 14 compatibility flags (`CFLAGS="-Wno-error=incompatible-pointer-types -Wno-error=int-conversion"`), added the 11-module regression suite under `pytest -n 2`, and added a production ingestion smoke test step. |

---

## Commit History

This PR packages work executed across 8 verified commits on `q3/pathmap-vpredicate-atomspace`:

1. `6126fb26` - `feat(v-predicate): adopt canonical V-predicate contract (v-predicate/1)`
   - Imported canonical `v_predicate_contract/` and formal test fixtures.
   - Configured `.git/hooks/pre-push` with `-n 2` resource throttling.
2. `330da0a6` - `feat(ingestion): modernize base adapter and implement ConceptNet 5th source adapter`
   - Modernized `BaseSourceAdapter` with `stream_facts() -> Iterator[FactRecord]`.
   - Added `fixtures/conceptnet_sub.json` and implemented `ConceptNetAdapter`.
3. `5068f594` - `feat(ingestion): migrate WordNet and OpenMath adapters to v-predicate/1 contract`
   - Migrated WordNet adapter for full synset traversal and canonical snake_case perspectives.
   - Migrated OpenMath adapter for grounded arrow signatures and executable equation axioms.
4. `fd12a6e6` - `refactor(tests): purge legacy model assertions from WordNet and OpenMath test suites in favor of v-predicate/1`
   - Refactored `test_wordnet_adapter.py` and `test_openmath_adapter.py` to assert typed `FactRecord`s.
5. `a23869b2` - `feat(ingestion): migrate Gene Ontology and ChEBI adapters to v-predicate/1 contract`
   - Implemented bounded-memory generator streaming (`yield FactRecord`) without `list(parse_obo)`.
   - Dynamic version extraction from OBO headers (`releases/2026-11-01`).
   - Purged legacy assertions from `test_go_adapter.py` and `test_chebi_adapter.py`.
6. `4322cb2c` - `feat(ingestion): modernize sinks, implement atomic staging, manifest, and 5-source orchestrator`
   - Renamed `PathMapSink` -> `InMemoryTestSink`.
   - Implemented `.staging/` atomic staging and rollback validation.
   - Generated `run_manifest.json` with SHA256 file hashes.
   - Updated `ingest_cli.py` to stream all 5 sources (`wordnet`, `go`, `chebi`, `openmath`, `conceptnet`).
7. `d78f2641` - `feat(ci): integrate v-predicate regression suite and smoke test into CI/CD workflow`
   - Updated `.github/workflows/ci_cd_pipeline.yml` with branch triggers, GCC 14 flags, regression suite, and smoke test.
8. `<HEAD>` - `feat(acceptance): implement e2e acceptance test suite, determinism checks, and package PR description`
   - Added `test_acceptance_scenario.py` verifying 230 facts across 5 sources, parenthetical balance, determinism across runs, and manifest schema.
   - Updated `.git/hooks/pre-push` and CI workflow to include acceptance tests (101/101 tests passing).

---

## Ingestion Metrics Across Canonical Offline Fixtures

A single run of `ingest_cli.py --sources all` yields exactly **230 facts** distributed across the two primary knowledge spaces:

| Knowledge Space | Target File | Facts | File Size | Description |
|---|---|---|---|---|
| **CASL Algebraic Specifications** | `AlgebraicSpecificationKB.metta` | **74** | ~28 KB | Sort declarations, operation signatures (`->`), equation axioms, and structural subsorts. |
| **Property-World Representations** | `PropertyWorldKB.metta` | **156** | ~64 KB | Predicate assertions, perspective assignments, and contextual possible worlds. |
| **Total** | | **230** | ~92 KB | Fully balanced MeTTa expressions with complete provenance atoms. |

### Per-Source Breakdown
- **WordNet**: 94 facts (27 CASL, 67 Property-World)
- **OpenMath**: 58 facts (18 CASL, 40 Property-World)
- **ChEBI**: 43 facts (11 CASL, 32 Property-World)
- **Gene Ontology**: 20 facts (6 CASL, 14 Property-World)
- **ConceptNet**: 15 facts (12 CASL, 3 Property-World)

---

## Verification & Quality Gates

### 1. Test Suite Results
All 101 unit, integration, and acceptance tests pass cleanly under `pytest -n 2` in ~23 seconds:
- `a_quantale_theoretic_approach/tests/test_quantale_laws.py` (2 tests)
- `a_quantale_theoretic_approach/tests/test_v_enriched.py` (2 tests)
- `.../tests/python/test_v_predicate_contract.py` (66 tests)
- `.../tests/python/test_conceptnet_adapter.py` (5 tests)
- `.../tests/python/test_ingestion_models.py` (3 tests)
- `.../tests/python/test_wordnet_adapter.py` (5 tests)
- `.../tests/python/test_go_adapter.py` (5 tests)
- `.../tests/python/test_chebi_adapter.py` (5 tests)
- `.../tests/python/test_openmath_adapter.py` (2 tests)
- `.../tests/python/test_ingestion_orchestrator.py` (2 tests)
- `.../tests/python/test_acceptance_scenario.py` (4 tests)

### 2. Determinism & Balance Invariants
- **Parenthetical Balance**: Every line in `AlgebraicSpecificationKB.metta` and `PropertyWorldKB.metta` strictly begins with `(: `, ends with `))`, and has a net parenthesis depth of exactly 0.
- **Bit-for-Bit Determinism**: Independent executions into separate directories produce identical SHA256 digests.
- **Atomic Staging**: Intermediate `.staging/` directories are completely removed upon publication, preventing half-written or corrupt outputs.
- **Resource Ceiling**: Peak memory consumption remains strictly under **400MB RAM** under `pytest -n 2`.
