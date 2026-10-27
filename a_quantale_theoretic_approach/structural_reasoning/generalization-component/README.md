# Generalization component

This folder contains the complete Cartesian algebraic-specification
generalization component in one standalone layout. For every compatible
section of two input specifications, it forms the Cartesian product of
entries, resolves a least common generalization (LCG) for each pair, removes
redundancy with the max lattice join, and assembles the generic-space
algebraic specification.

The public MeTTa entry point is `Generalization.metta`. The component checks
the completed generic-space cache first and pair-LCG cache entries second.
Uncached pairs are resolved through synthesis and KB graph search before an
optional validated LLM repair.

## Layout

```text
Generalization.metta             public MeTTa facade
GeneralizationExample.metta      executable house/cabin example
GeneralizationValidation.metta   deterministic integration validation
metta/                           local vocabulary, LCG rules, and synthesizers
python/                          planning, LCG selection/repair, assembly, cache
tests/python/                    Python unit and regression tests
kb/                              taxonomy evidence and runtime cache (ignored)
config/environment.example       runtime configuration reference
```

## Setup

From this directory:

```sh
python3 -m pip install -r requirements.txt
export OPENAI_API_KEY="..."
```

The defaults are cache mode `on`, LLM mode `verify`, failure policy
`error`, and three LLM attempts. If `OPENAI_API_KEY` is absent, LLM repair
is skipped and the component remains KB-only. See
`config/environment.example` for overrides.

The component is self-contained: its only filesystem import outside this
folder is PeTTa's `lib_import` bootstrap. The measured-proposition and
truth-value declarations needed by the LCG rules are defined locally in
`metta/Common.metta`.

## Logging

Logging uses the same JSONL schema, stderr rendering, and environment controls
as the V-predicate extraction pipeline. By default events are stored in
`kb/runtime/logs/GeneralizationEvents.jsonl`. Set the same
`PIPELINE_LOG_PATH` for multiple components to append their correlated event
records to one integration log.

`PIPELINE_LOG_VERBOSITY=default` records generalization milestones and every
error. `PIPELINE_LOG_VERBOSITY=verbose` also records cache bypasses, LLM
skips, repair details, and other intermediate events. Logging never changes a
pipeline result or masks its original exception.

## Run

```sh
petta GeneralizationExample.metta
```

For a caller-owned query, place the query beside `Generalization.metta`,
import it, and call:

```metta
!(import! &self Generalization)
!(main-lcg generic_name perspective input_spec_1 input_spec_2)
```

## Validate

```sh
PYTHONPATH=python \
python3 -B -m unittest discover -s tests/python -p 'test_*.py'

GENERALIZATION_CACHE_MODE=off \
GENERALIZATION_LLM_MODE=off \
GENERALIZATION_UNRESOLVED_POLICY=omit \
PIPELINE_LOG_MODE=off \
petta GeneralizationValidation.metta
```
