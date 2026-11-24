# V-predicate ingestion contract v1

This contract is the boundary between source ingestion, PeTTa storage, and the custom PathMap KB.
Adapters produce typed records from `python/v_predicate_contract`; they do not invent storage-specific
forms. MeTTa and PathMap sinks consume the same records.

## Invariants

- Perspective identifiers use `snake_case` and must be members of the `Perspective` enum.
- Every knowledge fact has a unique evidence identifier, truth value, and provenance record.
- A primary fact uses its evidence identifier as its edge identifier. A signature has its own
  evidence identifier and references the declaration's edge identifier.
- Provenance classifies a fact as `asserted`, `inferred`, or `generated`.
- A generated possible world is never represented as a source assertion.
- Predicates and axioms retain structured MeTTa expressions; a relation is not reduced to its target.
- Operation and predicate signatures reference the edge identifier of their declaration.
- Property-world facts reference a declared property identifier.
- A property's declaration perspective and a property-world assertion's evaluation perspective are
  independent. Cross-perspective mappings are valid and both perspectives must be preserved.
- Canonical files use one annotated atom per line: `(: evidence (≞ fact (stv s c)))`.

The contract version is `v-predicate/1`. Persisted manifests and PathMap indexes must record this
version and reject incompatible major versions.

## Identity and deduplication

Adapters create deterministic identifiers with `stable_evidence_id`. Components must include the
source, source record identifier, fact family, and normalized semantic arguments. Reprocessing the
same source record therefore produces the same identifier.

Deduplication is by evidence identifier, not merely by the rendered domain expression. Equivalent
claims from different sources remain separate evidence and retain their individual truth values and
provenance. A duplicate identifier with different content is a hard error.

## Canonical perspectives

| Perspective | Role |
| --- | --- |
| `artifact_kind` | `artifact_kind_role` |
| `behavioral_process` | `behavior_role` |
| `causal_prerequisite` | `causal_precondition_role` |
| `descriptive_property` | `property_role` |
| `economic_ownership` | `economic_role` |
| `event_composition` | `process_role` |
| `functional_use` | `function_role` |
| `information_computational` | `information_role` |
| `physical_attribute` | `physical_attribute_role` |
| `prerequisite_action` | `precondition_role` |
| `quantitative_comparative` | `comparative_role` |
| `role_kind` | `role_kind_role` |
| `safety_risk` | `risk_role` |
| `social_normative` | `social_role` |
| `spatial_context` | `spatial_role` |
| `state_lifecycle` | `state_role` |
| `structural_composition` | `structure_role` |
| `taxonomic_classification` | `ontological_role` |
| `taxonomic_kind` | `kind_role` |
| `temporal_context` | `temporal_role` |

Hyphenated input can be normalized at the adapter boundary, but persisted output must use the
canonical underscore form. New perspectives require an explicit contract revision.

## Fact families

```text
classified_perspective(perspective, role)
subperspective(parent, child)
perspective_match(requested, effective, effective_role)
has_sort(edge, concept, perspective, sort)
has_operation(edge, concept, perspective, operation)
operation_signature(edge, signature_expression)
has_predicate(edge, concept, perspective, predicate_expression)
predicate_signature(edge, signature_expression)
has_axiom(edge, concept, perspective, axiom_expression)
has_scoped_property(edge, concept, perspective, property_id, property_name)
scoped_property_holds_in(edge, property_id, perspective, world)
```

For `has_scoped_property`, `perspective` is the **declaration perspective**: it classifies the
property itself. For `scoped_property_holds_in`, `perspective` is the **evaluation perspective**:
it identifies the contextual axis under which the property holds in `world`. These values may be
equal, but equality is not required. For example, a `behavioral_process` property may hold in a
`spatial_context` world. Storage backends must retain both values and must not reject, rewrite, or
silently drop cross-perspective mappings.

`predicate_expression` must preserve the source relation, for example `(hasRole phenol antiseptic)`.
An axiom is its executable formula, not an adapter-specific wrapper. Signature expressions use the
currently established `arrow` vocabulary unless a domain contract explicitly defines another form.

## Provenance

Each fact is accompanied by:

```text
evidence_provenance(
    evidence_id,
    source,
    source_record_id,
    source_uri,
    source_version,
    license,
    transformation,
    origin
)
```

String-valued source fields are quoted. `source` and `transformation` are canonical symbols. The
provenance atom has truth value `(stv 1.000 1.000)` because it records traceability, not the truth of
the domain assertion.

## Adapter and sink responsibilities

An adapter fetches and parses source data, assigns a canonical perspective, and returns typed
records. It must not write PathMap internals or manually concatenate MeTTa.

### Source Acquisition and Provenance Foundation

Starting with Issue #112 ([Ingestion 1/5]), source data localization is governed by the shared
`SourceAcquisitionEngine`:
- **Atomic Two-Phase Staging**: Downloads stream to temporary staging files (`.tmp.<uuid>`) and are
  promoted to the cache path via atomic swap only after stream completion and SHA-256 validation.
- **Sidecar Metadata**: Every cached file is accompanied by `<filename>.meta.json` recording
  `source_uri`, `source_version`, `retrieval_time`, `byte_size`, and `sha256_checksum`.
- **Cache Integrity & Recovery**: Cached files are verified against SHA-256 digests. Corrupted or
  tampered caches are automatically purged and cleanly re-acquired.
- **Fail-Fast Production Invariant**: When `download=True` is requested, failures fail fast via
  `SourceAcquisitionError`; adapters never silently fall back to offline fixtures in production mode.
- **Explicit Provenance Classification**: Downstream manifests record the provenance type:
  `fixture` (bundled offline fixture), `cached` (verified local cache), or `downloaded` (fresh network download).

A sink validates a complete record set before publication. A MeTTa sink calls `render_document`.
The PathMap sink uses the same record fields and must preserve evidence, provenance, fact origin,
declaration perspective, and evaluation perspective. Invalid references, duplicate evidence
identifiers, conflicting property declarations, unknown perspectives, and out-of-range truth
values are hard errors.

The authoritative example is `fixtures/v_predicate_contract_v1.metta`, and executable behavior is
covered by `tests/python/test_v_predicate_contract.py`.
