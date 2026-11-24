# Perspective-sharded PathMap prototype

This is a deliberately small side-by-side compiler for the generated perspective-aware KBs.
It does not replace the current MeTTa files.

## Prerequisites & PathMap Dependency

This prototype builds against **PathMap 0.4** (`radix-256` prefix trie with path compression),
pinned to upstream revision
`72ebdba08095d01ac31bb609190589436efd6854`. The Cargo lockfile records the same revision,
so normal local and CI builds use identical PathMap code and do not depend on a sibling checkout.

### Optional local PathMap development

Ordinary builds require no manual PathMap setup. To test unpublished PathMap changes, clone it and
temporarily opt into a Cargo source override without changing the committed dependency:

```bash
git clone https://github.com/Adam-Vandervorst/PathMap.git ../PathMap
git -C ../PathMap checkout 72ebdba08095d01ac31bb609190589436efd6854

# Put this in .cargo/config.toml for the local experiment only:
# [patch."https://github.com/Adam-Vandervorst/PathMap.git"]
# pathmap = { path = "../PathMap" }
```

### Building and Verifying

```bash
cd a_quantale_theoretic_approach/v-predicate-extraction-pipeline/prototype/pathmap-kb
cargo build --release
cargo test
```

Do not commit a local override. `cargo build --locked` is the reproducibility check used by CI.
The compatibility script also enables the AES and SSE2 target features required by PathMap's
`gxhash` backend on generic x86 CI runners; non-x86 targets are left unchanged.

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
Each immutable map is written in two forms. `.paths` plus fixed-width `.values` retain the portable
PathMap serialization used by the compatibility loader. `.act` plus `.act-values` are the compact
arena trie and adjacent fixed-width values used by the production mmap loader. The ACT trie and
values stay file-backed while queries traverse the selected perspective.

Compilation is order-independent without loading the entire input into memory: the compiler makes
bounded-memory passes for provenance, declarations, and dependent records. Worlds and signatures
therefore may appear before the records they reference. Indexes record both `v-predicate/1` and
`pathmap-kb/2`; older prototype indexes must be rebuilt.

## Canonical JSONL input

The production ingestion boundary is one typed `v-predicate/1` record per JSON line. Every record
contains `contract_version`, `kind`, `evidence_id`, `truth`, `provenance`, and the fields required by
its kind. The compiler parses one line at a time and makes dependency-ordered passes over the file;
input order does not affect the index and source-record memory is bounded by the largest line.

```json
{"contract_version":"v-predicate/1","kind":"has_sort","evidence_id":"sort_ev","truth":{"strength":0.9,"confidence":0.8},"provenance":{"source":"wordnet","source_record_id":"n:1","source_uri":"https://wordnet.example/n:1","source_version":"3.1","license":"WordNet","transformation":"wordnet_to_sort","origin":"asserted"},"edge_id":"sort_ev","concept":"computer","perspective":"taxonomic_kind","sort":"artifact"}
```

Compile a published JSONL snapshot directly:

```bash
cargo run --release -- build-jsonl \
  --input ./canonical_records.jsonl \
  --out ./index
```

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

Every snapshot contains `index-metadata.json` and one `shard-metadata.json` per perspective. The
metadata records format versions, record width, counts, sizes, and SHA-256 digests. Opening a store
validates the shared dictionaries; loading a perspective validates all of that shard's files before
mapping them. `ImmutableShardStore` maps perspectives only when requested and retains them in a
bounded LRU cache (eight perspectives by default, configurable with `open_with_capacity`). Mutable
verified or session facts remain future overlay work and are not written into immutable snapshots.

The comparison harness in `benchmarks/metta_atomspace_bench.pl` applies the same specification
workload to the compiled SWI-Prolog QLF atomspaces generated from the MeTTa KBs. It is a benchmark
of the repository's available generic MeTTa-fact representation versus this indexed PathMap layout;
it is not a benchmark of every possible Hyperon implementation.
