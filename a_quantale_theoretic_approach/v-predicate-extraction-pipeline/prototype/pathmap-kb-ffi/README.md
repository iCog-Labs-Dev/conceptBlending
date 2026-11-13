# PeTTa PathMap KB bridge

This optional foreign library exposes the adjacent perspective-sharded PathMap index to PeTTa
without routing queries through MORK's generic S-expression matcher.

Build it with:

```bash
bash build.sh
```

To make a PeTTa checkout discover the bridge, link this directory into the checkout and apply the
included loader patch:

```bash
ln -s /path/to/conceptBlending/a_quantale_theoretic_approach/v-predicate-extraction-pipeline/prototype/pathmap-kb-ffi /path/to/PeTTa/pathmap_kb_ffi
git -C /path/to/PeTTa apply /path/to/conceptBlending/a_quantale_theoretic_approach/v-predicate-extraction-pipeline/prototype/pathmap-kb-ffi/petta-integration.patch
```

The patch only makes the optional library discoverable and registers its six MeTTa functions; a
PeTTa checkout still works normally when the compiled library is absent.

PeTTa functions:

```metta
!(pathmap-open! spec-kb "/path/to/index")
!(pathmap-query-algebra spec-kb descriptive_property a2 sort)
!(pathmap-query-properties spec-kb descriptive_property a2)
!(pathmap-query-worlds spec-kb descriptive_property a2 cardiology)
!(pathmap-build-specification spec-kb descriptive_property a2)
!(pathmap-close! spec-kb)
```

The fused call can be used as the storage leaf of a PeTTa algorithm:

```metta
(= (build-indexed-algebraic-specification $concept $perspective)
   (pathmap-build-specification spec-kb $perspective $concept))
```

Use the fused operation on the hot path. The individual query operations are intended for
algorithms that need to customize or combine only part of the specification.

## Hot-path design

Queries use a typed Rust-to-SWI callback. Rust returns each row as borrowed byte slices and
numeric truth values, and the C shim constructs the PeTTa list directly. This avoids formatting
the full result as MeTTa text and parsing it again in Prolog. Predicate, axiom, and operation
payloads still require `sread/2`; their parsed terms are recorded in a process-wide cache keyed by
payload text, so a shared signature is parsed once even when it occurs in several perspective
shards.

Each open handle also owns one Rust `Index`. The first perspective loads the global symbol and
payload dictionaries; later perspectives attach only their PathMaps to that same index. This is
important for full builds because it prevents every perspective from holding another copy of the
global dictionaries.

On the 24-row `descriptive_property/a2` sample index, the warm fused query measured about 20 us,
versus about 1,276 us through the original text bridge and about 8 us for the Rust-only query.
These figures are machine-dependent. The first access to a perspective also pays the one-time
shard load, and the first occurrence of each structured payload pays its parse cost.

With the 1.4 GB full index, a five-perspective, 12-query workload dropped from about 42 seconds and
9.7 GiB peak memory to about 12 seconds and 3.1 GiB after sharing dictionaries per handle.

The index root must contain `manifest.tsv`, `symbols.tsv`, `payloads.tsv`, and the serialized
perspective shards produced by `perspective-pathmap-prototype build`.
