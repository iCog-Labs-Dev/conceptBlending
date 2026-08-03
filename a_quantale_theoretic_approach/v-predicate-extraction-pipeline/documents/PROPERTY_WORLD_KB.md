# Perspective-aware property/world KB

`PropertyWorldKB.metta` is generated directly from the raw Concept Atomspace.
It is queried by `PropertyWorldDataLayer.metta` through the same `synthesize`
mechanism used by `AlgebraicSpecificationDataLayer.metta`; no SQLite index is
used.

Properties are inferred from perspective-specific relation families, not only
`hasProperty`: for example, `UsedFor` and `CapableOf` provide functional-use
properties, structural relations provide structural properties, and
information-related capabilities also provide information-computational
properties. Property identities include concept and effective perspective, so
two concepts can use the same public property name without sharing evidence.

Possible worlds are built only from incoming relations licensed for the
property's effective perspective. Lexical edges such as `Synonym`,
`DerivedFrom`, and `Antonym` cannot become worlds. Candidates are ranked,
deduplicated, and capped at eight per property; common action inflections are
canonicalized. Each effective-perspective world fact is stored once. Broader
perspective matching happens at query time rather than duplicating facts.
Highly frequent property targets are treated as ambiguous: cross-concept
world sharing is suppressed unless stronger concept-specific evidence exists,
so generic qualities do not acquire arbitrary world lists.

Generate the full KB from the standalone pipeline directory:

```sh
PYTHONPATH=python/generation \
python3 -B python/generation/gen_property_world_kb.py \
  kb/evidence/concept-atomspace \
  kb/generated/PropertyWorldKB.metta
```

Add `--include-provenance` when an audit build also needs the larger
`property_evidence` and `world_evidence` fact sets.

Restrict the build while iterating by repeating `--concept`:

```sh
PYTHONPATH=python/generation \
python3 -B python/generation/gen_property_world_kb.py \
  kb/evidence/concept-atomspace \
  kb/generated/PropertyWorldKB.metta \
  --concept boat --concept knife
```

Create the query file beside `Pipeline.metta` and import the public bootstrap:

```metta
!(import! &self Pipeline)
!(query-concept-properties computer functional_use)
!(query-property-worlds process_information functional_use)
!(query-property-worlds-by-ref
    (PropertyRef property_key_computer_functional_use_process_information
                 process_information functional_use)
    functional_use)
!(filter-unique-possible-worlds
    (((WorldRef computer functional_use)
      (WorldRef server functional_use))
     ((WorldRef server functional_use)
      (WorldRef data_center functional_use))))
```

The public concept query returns only property names and their effective
perspectives after final LLM repair and verification. It contains at most 10
unique, evidence-backed property names:

```metta
((access_internet functional_use)
 (process_information functional_use)
 ...)
```

`query-property-worlds` is global: it resolves every scoped property with the
requested public name, combines existing KB truth values with perspective
compatibility, removes duplicate worlds, adds a small capped multi-source
support bonus, then sends those KB candidates through final LLM repair and
verification. It returns at most 3 evidence-backed names. Use
`query-property-worlds-by-ref` only when low-level scoped inspection is needed.

The pre-verification ranked candidates remain available for debugging:

```metta
!(query-concept-properties-from-kb computer functional_use)
!(query-property-worlds-from-kb process_information functional_use)
```

The verifier uses the official OpenAI SDK and defaults to `gpt-5.4`. The KB
candidates are evidence context rather than a closed vocabulary. The verifier
may add highly relevant missing properties or possible worlds using reliable
general knowledge, while removing noisy candidates. A response contains at
most 10 unique properties and at most 3 unique worlds per property. Added
properties use the requested perspective, and all additions must use
MeTTa-safe snake_case names.

Accepted results are appended to `PropertyWorldVerified.jsonl` and
`PropertyWorldVerifiedKB.metta`; an exact repeated query is served from that
cache without another model call. The cache key includes the candidate set,
model, prompt version, and KB fingerprint, so changed evidence is reverified.

Runtime configuration:

```sh
export OPENAI_API_KEY=...
export PROPERTY_WORLD_VERIFIER_MODE=auto       # off | auto | verify
export PROPERTY_WORLD_VERIFIER_FAILURE_POLICY=fallback  # fallback | error
export PROPERTY_WORLD_VERIFIER_MODEL=gpt-5.4
export PROPERTY_WORLD_VERIFIER_TRACE=1         # optional request/response trace
# Only needed when the SDK is outside the local dependent-types/venv:
export PROPERTY_WORLD_OPENAI_SITE_PACKAGES=/path/to/site-packages
```

`auto` verifies when the API key is present and otherwise uses a deterministic
bounded fallback. `verify` requires the key. `off` disables model calls while
still enforcing the 10-property and 3-world output caps.

`PROPERTY_WORLD_VERIFIER_FAILURE_POLICY=fallback` is the default. After all
verification attempts fail, it returns the bounded KB candidates: at most 10
properties or 3 worlds. This keeps the pipeline running but can hide an LLM,
authentication, or validation failure. Set the policy to `error` during strict
or diagnostic runs to raise `PropertyWorldVerificationError` after the final
failed attempt.

`PROPERTY_WORLD_VERIFIER_TRACE=1` prints the complete structured request and
raw LLM response to standard error. Redirect it separately when needed:

```sh
petta your-query.metta 2> /tmp/property-world-verifier.log
```

The trace can contain substantial KB context. A matching verifier-cache entry
does not make a new model request and therefore produces no request/response
trace.

For a strict diagnostic run:

```sh
export PROPERTY_WORLD_VERIFIER_MODE=verify
export PROPERTY_WORLD_VERIFIER_FAILURE_POLICY=error
export PROPERTY_WORLD_VERIFIER_TRACE=1
```

## Complete pipeline event log

The integrated
`build-concept-property-world-specifications` call reports structured success
and error events from property extraction through final result return. Events
are appended to `PipelineEvents.jsonl` and are also printed in a concise form
to standard error. Every integrated build receives a run ID that correlates its
property, world, algebraic-generation, cache, verification, persistence, and
completion events.

Runtime configuration:

```sh
export PIPELINE_LOG_MODE=on                 # on | off; default: on
export PIPELINE_LOG_VERBOSITY=default       # default | verbose
export PIPELINE_LOG_PATH=/path/to/events.jsonl
export PIPELINE_LOG_STDERR=1                # 1 prints concise events
export PIPELINE_LOG_MAX_DETAIL_CHARS=2000   # bound event payload size
```

Representative success stages include:

- `pipeline_started`
- `properties_extracted` and `properties_verified`
- `worlds_extracted` and `worlds_verified`
- `worlds_deduplicated`
- `algebraic_spec_cache_hit` or `algebraic_spec_cache_miss`
- `algebraic_spec_generated` and `algebraic_spec_verified`
- `algebraic_spec_persisted` and `algebraic_spec_stored`
- `pipeline_completed`

`PIPELINE_LOG_VERBOSITY=default` reports milestone events only: pipeline
start/completion, completed property and world stages, unique worlds,
algebraic-spec cache decisions, generation/verification milestones, and final
storage. It suppresses fine-grained successful events such as each individual
property-world verifier call. Error events are always reported.

`PIPELINE_LOG_VERBOSITY=verbose` enables the complete event stream, including
every property/world extraction and verification call, provider/cache details,
algebraic verifier activity, fallback selection, and persistence events.

Provider, validation, and persistence exceptions produce events with
`"status": "error"` before the exception is re-raised. When a verifier uses
its configured fallback policy, the failed attempts remain error events and a
separate success event records that fallback was used. Logger failures never
replace or terminate the pipeline's real result.

For example:

```sh
petta tests/metta/PipelineLoggerIntegrationValidation.metta \
  2> /tmp/pipeline-events.log
```

The combined result contains only the requested nested property/world
structure:

```metta
(Concept computer functional_use
  (Properties
    ((process_information) ((computer) (server)))))
```

The builder also generates one real algebraic specification per unique
world/perspective pair and stores it as a nullary method in the session-local
`&algspecspace`. Import the integration entry point and call:

```metta
!(import! &self Pipeline)
!(build-concept-property-world-specifications computer functional_use)
```

The stored definitions are perspective-qualified:

```metta
(= (computer-functional_use-spec)
   (Concept computer functional_use (spec ...)))
```

Retrieve one specification or inspect the dedicated space:

```metta
!(get-world-algebraic-spec computer functional_use)
!(match &algspecspace
    (= (computer-functional_use-spec) $specification)
    $specification)
!(list-world-algebraic-spec-methods)
```

Rebuilding the same world and perspective replaces its previous definition
instead of adding another method body. Different perspectives are stored under
different method names.

Normal concept/property builds are cache-aware: if the perspective-qualified
method already exists in `&algspecspace`, `build-algebraic-spec` is not called
again. The space is hydrated at import from
`AlgebraicSpecificationSpaceCache.jsonl` and from specifications accepted by
the current verifier in `AlgebraicSpecificationVerified.jsonl`. Consequently,
cache hits work across separate `petta` processes, not only within one process.
Every successful store or rebuild appends the completed specification to the
disk cache before updating `&algspecspace`.

The cache is keyed by both world and perspective. Its path can be overridden
with `ALGEBRAIC_SPEC_SPACE_CACHE`; set
`ALGEBRAIC_SPEC_SPACE_CACHE_MODE=off` to disable loading and writing, or
`ALGEBRAIC_SPEC_SPACE_IMPORT_VERIFIED=0` to skip importing the verifier audit.
Explicit refresh remains available:

```metta
!(ensure-world-algebraic-spec computer functional_use)
!(rebuild-world-algebraic-spec computer functional_use)
!(rebuild-world-algebraic-specifications
    ((WorldRef computer functional_use)
     (WorldRef server functional_use)))
```

Possible worlds are evidence-backed source concepts; the generator never
invents scenario labels. A broad request may return properties from child
perspectives, but each world's algebraic specification is generated with the
property's effective child perspective rather than the broad request label.
