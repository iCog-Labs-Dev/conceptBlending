# Structural integration

`structural-integration.metta` connects the perspective-aware V-predicate
extraction pipeline to Cartesian generic-space construction.

For two concept names and one perspective,
`prepare-structural-blend`:

1. builds both compact V-predicates;
2. retrieves each concept's separately stored algebraic specification by
   concept name and perspective;
3. invokes the generalization component through its public `main-lcg` entry
   point to construct the generic-space algebraic specification; and
4. returns a `structural-blend-preparation` bundle.

The result deliberately records two unfinished dependencies:

- property truth scalars remain pending the GNN assignment stage;
- enriched Hom values remain pending a dedicated Hom extraction/building
  pipeline.

Consequently, the V-enriched colimit check is marked `Blocked` rather than
using fabricated or bottom Hom values.

The stable component boundary accepts grounded MeTTa text. Freeze each
already-computed producer result with `repr (reduce ...)`:

```metta
!(import! &self structural-integration)
!(prepare-structural-blend-from-texts
    generic_name functional_use
    (repr (reduce (left-v-predicate-producer)))
    (repr (reduce (right-v-predicate-producer)))
    (repr (reduce (left-spec-producer)))
    (repr (reduce (right-spec-producer))))
```

`prepare-structural-blend-from-specs` is the typed convenience boundary for
producer expressions. The integration layer does not duplicate generic-space
cache lookup, Cartesian planning, pair resolution, or persistence; these remain
owned by `main-lcg` and the generalization component.

## Optimality handoff

After truth scalars, enriched Homs, vital relations, and a V-colimit certificate
are available, pass the already computed structural and colimit records to
`optimality/optimality-integration.metta`:

```metta
!(import! &self a_quantale_theoretic_approach/optimality/optimality-integration)
!(q-evaluate-integrated-optimality
    StructuralPreparation
    QuantaleVPredicateColimitResult
    OptimalityEnrichmentArtifacts)
```

The adapter verifies concept name, perspective, quantale universe, V-category,
and V-morphism endpoint compatibility. It builds one shared optimality context,
including the cached double-coend transports used by Topology and Web. If the Hom
extraction/building stage has not supplied `OptimalityEnrichmentArtifacts`, the
result is `Blocked` with bottom rather than a fabricated passing value.

Good Reason provenance is derived automatically from the colimit result's
`PropertyContributionMap` when the artifacts carry an empty property-evidence list.
An explicit list can still be supplied when generic-space or external provenance
must be included.

This boundary accepts inert producer records deliberately: importing all producer
engines into one PeTTa atomspace causes duplicate transitive imports and prevents
the stages from being independently cached or inspected.

## Executable complete pipeline

`complete-blend-pipeline.metta` is the executable orchestration facade. Its public
operation is:

```metta
(q-run-complete-blend-pipeline
   GenericName Perspective
   CompactSourceVPredicateA CompactSourceVPredicateB
   SourceAlgebraicSpecA SourceAlgebraicSpecB
   ScalarBearingSourceVPredicateA ScalarBearingSourceVPredicateB
   PropertyMappings WorldClusters WorldSpecRegistry
   OptimalityEnrichmentArtifacts)
```

One invocation performs, in order:

1. real cached Cartesian generic-space construction through `main-lcg`;
2. the real world-aware quantale V-predicate colimit;
3. structural/colimit identity and perspective checks;
4. shared optimality-context construction and cached double-coend transports;
5. all enriched optimality constraints and their aggregate score.

The two V-predicate forms are intentional. The compact values are exactly the
output contract of `v-predicate-extraction-pipeline`; the scalar-bearing values
are that output after the planned GNN assignment stage. Passing `()` for either
scalar-bearing value returns `CompleteBlendPipelineResult Pending` after the
structural stage. Passing `()` for enrichment artifacts runs through the colimit
and returns `Blocked` at optimality. Supplying both external boundaries returns
the complete `Evaluated` result.

Run the executable integration contract with:

```bash
GENERALIZATION_LLM_MODE=off \
GENERALIZATION_CACHE_MODE=on \
petta a_quantale_theoretic_approach/tests/quantale-petta-complete-pipeline-smoke.metta
```

The fixture checks all three outcomes—`Pending`, `Blocked`, and `Evaluated`—and
the evaluated example produces aggregate quantale degree `0.8`.

The facade consumes the compact extractor result rather than invoking the
extractor bootstrap internally. This is necessary today because PeTTa resolves
the extractor's static KB imports relative to the extractor process directory,
whereas the quantale/optimality modules resolve repository-root imports. The
data contract is integrated and tested; making both bootstraps share one process
requires first normalizing the extractor's static import paths.
