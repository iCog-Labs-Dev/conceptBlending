# V-predicate extraction pipeline

This folder contains the complete perspective-aware pipeline in one standalone
layout. It extracts and verifies a concept's properties, retrieves and verifies
possible worlds for those properties, deduplicates the worlds, builds one
algebraic specification for every unique world/perspective pair, persists those
specifications across runs, and returns the compact concept/property/world
representation.

The public MeTTa entry point is `Pipeline.metta`. Pipeline implementations,
tests, fixtures, and documentation live only in this folder. The parent `dependent-types` directory retains only shared dependencies. All
pipeline KB paths live under this folder and are ignored by Git.

## Layout

```text
Pipeline.metta                     public MeTTa facade
metta/property_world/             property and possible-world data layer
metta/algebraic_spec/             algebraic builder and persistent &algspecspace
metta/logging/                    MeTTa event-logger facade
python/verification/             OpenAI repair and verification layers
python/storage/                  disk cache and structured event logger
python/generation/               KB generators and semantic compiler
kb/evidence/                     raw Concept Atomspace input (ignored)
kb/generated/                    generated MeTTa KBs (ignored)
kb/runtime/                      verified records, cache, and logs (ignored)
fixtures/                        prompt reference example
documents/                       design, verification, and evaluation guides
tests/python/                    Python unit/evaluation tests
tests/metta/                     MeTTa integration validations
config/environment.example       runtime configuration template
```

## Documentation

- [Algebraic-specification evaluation](documents/ALGEBRAIC_SPEC_EVALUATION.md)
- [Algebraic-specification verification](documents/ALGEBRAIC_SPEC_VERIFICATION.md)
- [Property and possible-world KB](documents/PROPERTY_WORLD_KB.md)

## Setup

From this directory:

```sh
export V_PREDICATE_PIPELINE_ROOT="$PWD"
export OPENAI_API_KEY="..."
export PROPERTY_WORLD_VERIFIER_MODE=verify
export PROPERTY_WORLD_VERIFIER_FAILURE_POLICY=error
export ALGEBRAIC_SPEC_VERIFIER_MODE=verify
export ALGEBRAIC_SPEC_VERIFIER_FAILURE_POLICY=error
```

Both verifiers use the official OpenAI SDK and default to `gpt-5.4`. Use
`config/environment.example` for the complete common configuration. `auto`
uses the model when a key exists and otherwise falls back deterministically;
`verify` requires a working model call. Set either `*_TRACE=1` to print the
complete LLM request and response to standard error.

## Build the generated KBs

The checked-out runtime data is placed under `kb/` and is deliberately ignored
by Git. Regenerate it with:

```sh
PYTHONPATH=python/generation \
python3 -B python/generation/gen_algebraic_spec_kb.py \
  kb/evidence/concept-atomspace kb/generated/AlgebraicSpecificationKB.metta

PYTHONPATH=python/generation \
python3 -B python/generation/gen_property_world_kb.py \
  kb/evidence/concept-atomspace kb/generated/PropertyWorldKB.metta
```

## Query the pipeline

Create a small MeTTa query next to `Pipeline.metta`:

```metta
!(import! &self Pipeline)
!(build-concept-property-world-specifications computer functional_use)
```

Then run `petta your-query.metta`. The returned value has no embedded
algebraic-specification payload:

```metta
(Concept computer functional_use
  (Properties
    ((process_information) ((computer) (server)))))
```

Generated world specifications are stored separately in `&algspecspace` as
perspective-qualified nullary methods such as
`(= (computer-functional_use-spec) (Concept ...))`. Query one with:

```metta
!(get-world-algebraic-spec computer functional_use)
```

The disk-backed cache in `kb/runtime/cache/` hydrates `&algspecspace` on the
next PeTTa run, preventing repeated builds for the same world and perspective.

## Logging

`PIPELINE_LOG_VERBOSITY=default` reports main milestones and every error.
`PIPELINE_LOG_VERBOSITY=verbose` reports the full property, world, verifier,
generation, persistence, and completion stream. JSONL events are written to
`kb/runtime/logs/PipelineEvents.jsonl` unless `PIPELINE_LOG_PATH` overrides it.

## Tests

```sh
PYTHONPATH=python/generation:python/verification:python/storage:tests/python \
python3 -B -m unittest discover -s tests/python -p 'test_*.py'

PYTHONPATH=python/generation:tests/python \
python3 -B python/generation/evaluate_algebraic_specs.py

PROPERTY_WORLD_VERIFIER_MODE=off \
ALGEBRAIC_SPEC_VERIFIER_MODE=off \
ALGEBRAIC_SPEC_SPACE_CACHE_MODE=off \
PIPELINE_LOG_MODE=off \
petta PipelineValidation.metta
```

Additional MeTTa validations live in `tests/metta/`. Because PeTTa resolves
static-import paths from each top-level validation file, full-stack tests bind
the two KB spaces explicitly and exactly once; production query files should
instead sit beside and import `Pipeline.metta`.
