# Perspective-sharded PathMap prototype

This is a deliberately small side-by-side compiler for the generated perspective-aware KBs.
It does not replace the current MeTTa files.

## Prerequisites & PathMap Dependency

This prototype builds against **PathMap 0.4** (`radix-256` prefix trie with path compression).
Because PathMap is developed in a separate repository, it is referenced as a path dependency:
`pathmap = { path = "../../../../../PathMap" }`

### Setup Instructions

Clone the PathMap repository as a sibling directory to your `conceptBlending` workspace root:

```bash
# From your workspace root (e.g., conceptBlending/):
git clone https://github.com/Adam-Vandervorst/PathMap.git ../PathMap
```

Ensure the directory structure matches:
```text
parent_dir/
├── conceptBlending/
│   └── a_quantale_theoretic_approach/
│       └── v-predicate-extraction-pipeline/
│           └── prototype/
│               ├── pathmap-kb/
│               └── pathmap-kb-ffi/
└── PathMap/
    ├── Cargo.toml
    └── src/
```

### Building and Verifying

```bash
cd a_quantale_theoretic_approach/v-predicate-extraction-pipeline/prototype/pathmap-kb
cargo build --release
cargo test
```

### CI Parity

In CI workflows (such as `.github/workflows/ci_cd_pipeline.yml`), PathMap is cloned directly into the parent workspace before building:

```bash
git clone https://github.com/Adam-Vandervorst/PathMap.git "$GITHUB_WORKSPACE/../PathMap"
cd a_quantale_theoretic_approach/v-predicate-extraction-pipeline/prototype/pathmap-kb
cargo build --release
```

## Layout

Each perspective is a separate radix-256 `PathMap` shard, so the perspective is selected before
trie traversal and is not repeated in every key. Stable IDs are deterministic FNV-1a hashes of
symbols; collisions are checked while building.

Primary keys (numbers are big-endian `u64` IDs):

```text
concept / 0x10 property / property / 0x00 fact  / evidence
concept / 0x10 property / property / 0x01 world / world / evidence
concept / 0x20 sort      / sort      / evidence
concept / 0x30 operation / operation / evidence
concept / 0x40 predicate / expression-id / evidence
concept / 0x50 axiom     / expression-id / evidence
```

Every shard also has the inverted index needed by global property-name queries:

```text
property / world / concept / evidence
```

Property declarations are stored in their declaration-perspective shard. Property-world mappings
remain reachable from that primary shard, while their inverted entry is stored in the mapping's
evaluation-perspective shard. This preserves valid cross-perspective statements such as a
`behavioral_process` property evaluated in a `spatial_context` world.

Each shard also contains a perspective-relation map for `classified_perspective`,
`subperspective`, and `perspective_match` records.

Truth values plus payload/evidence references are values, not path prefixes. Operation signatures
and their separate truth/provenance metadata are co-located as operation values. Nested predicates
and axioms live once in `payloads.tsv`.
Canonical `evidence_provenance` payloads and `asserted`, `inferred`, or `generated` origins are
stored with their facts. Declaration signatures retain their own truth values, evidence,
provenance, and origin alongside the declaration.
The `.paths` files are PathMap's compressed path serialization; fixed-width `.values` files are in
the exact same traversal order.

Compilation is order-independent without loading the entire input into memory: the compiler makes
bounded-memory passes for provenance, declarations, and dependent records. Worlds and signatures
therefore may appear before the records they reference. Indexes record both `v-predicate/1` and
`pathmap-kb/2`; older prototype indexes must be rebuilt.

## Try it

```bash
cargo run --release -- build \
  --property-kb ../../kb/generated/PropertyWorldKB.metta \
  --algebraic-kb ../../kb/generated/AlgebraicSpecificationKB.metta \
  --out ./index \
  --limit-per-kind 1000

cargo run --release -- worlds \
  --index ./index --perspective descriptive_property \
  --concept a2 --property cardiology

cargo run --release -- algebra \
  --index ./index --perspective descriptive_property \
  --concept a0 --family operation

cargo run --release -- benchmark \
  --index ./index --perspective descriptive_property \
  --concept a0 --iterations 20 --extensions 10000
```

Ingestion adapters can bypass manual file management by passing their canonical typed records to
`python/pathmap_kb_integration.py`:

```python
from pathmap_kb_integration import compile_records

result = compile_records(
    records,
    "/path/to/index",
    compiler="/path/to/perspective-pathmap-prototype",
)
```

The bridge validates the complete record set, renders the CASL and property-world documents,
invokes the real Rust compiler, checks all required index artifacts, and publishes the completed
index atomically. It never exposes a partially compiled index.

## Correctness and performance gate

The build records elapsed compilation time and Linux peak RSS in `build-stats.txt` (`0` denotes a
platform where process RSS accounting is unavailable). Evaluate the
five-source index with representative WordNet, GO, ChEBI, OpenMath, and ConceptNet queries using:

```bash
python ../../python/pathmap_kb_evaluation.py \
  --compiler ./target/release/perspective-pathmap-prototype \
  --index ./index \
  --cases ../../benchmarks/five_source_acceptance.json \
  --iterations 20 \
  --output ./evaluation.json
```

The evaluator rejects skipped worlds, incomplete provenance coverage, missing representative
results, and failed queries. A previous report can be supplied with `--baseline`; by default it
rejects query-latency regressions over 25% and peak-memory regressions over 15%.

Omit `--limit-per-kind` for a complete build. The option caps each indexed relation independently,
but still scans the source files because relation groups occur at different offsets.

This prototype uses PathMap's portable `.paths` serializer. A production version should dump the
finished immutable shards to ACT and memory-map them, while keeping mutable verified/session facts
in separate overlay maps.

The comparison harness in `benchmarks/metta_atomspace_bench.pl` applies the same specification
workload to the compiled SWI-Prolog QLF atomspaces generated from the MeTTa KBs. It is a benchmark
of the repository's available generic MeTTa-fact representation versus this indexed PathMap layout;
it is not a benchmark of every possible Hyperon implementation.
