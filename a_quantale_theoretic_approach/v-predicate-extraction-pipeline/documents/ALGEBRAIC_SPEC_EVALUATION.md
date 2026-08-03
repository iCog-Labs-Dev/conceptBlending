# Semantic algebraic-specification generator

The generator uses a typed semantic intermediate representation rather than
projecting each raw ConceptNet edge independently into every specification
section.

## Semantic ownership

- Sorts declare concept, participant, state, and outcome types.
- Operations represent constructors, transformations, observers, constants,
  and combinators.
- Predicates represent non-transformational relations.
- Axioms constrain declared operations and predicates.

`UsedFor` and `CapableOf` evidence is normalized into capability frames when
the target denotes an action. Noun-like `UsedFor` targets become relations such
as `ServesTask`. Capability evidence is not duplicated as a predicate.

## Schema bundles

Reusable schema families currently include:

- functional interface
- edge application
- transport
- containment
- computation
- agent action
- structural composition
- evidence relations

Bundles are selected jointly. Required sorts, operations, and axioms remain
together, so limiting optional families cannot leave dangling signatures or
axioms. `--max-per-part` is retained for CLI compatibility but now means the
maximum number of optional schema families per concept and perspective.

The MeTTa data layer no longer truncates every section to five entries. It
retrieves the complete validated bundle.

## Tests

Run the semantic and end-to-end generator tests:

```bash
PYTHONPATH=python/generation:python/verification:python/storage:tests/python \
python3 -B -m unittest discover \
  -s tests/python \
  -p 'test_*algebraic_spec*.py' -v
```

The suite covers artifacts, agents, substances, information objects, places,
process-like capabilities, and abstract/structural concepts. It checks:

- operation/predicate separation;
- noun-versus-action handling for `UsedFor`;
- type closure;
- axiom symbol closure;
- coherent family limiting;
- deterministic output;
- rich edge-application specialization;
- end-to-end MeTTa fact emission.

## Evaluation report

Run:

```bash
PYTHONPATH=python/generation:tests/python \
python3 -B python/generation/evaluate_algebraic_specs.py
```

Use `--json` for a machine-readable report. The required quality gates are:

- zero operation/predicate semantic overlaps;
- zero undeclared sorts;
- zero dangling axiom references;
- zero validation issues.
- at least 75% operation/axiom coverage across the stratified suite.

The report also measures operation/axiom coverage and feature counts for every
stratified concept/perspective case.

## Small end-to-end fixture

The committed fixture avoids rebuilding the multi-gigabyte production KB:

```bash
PYTHONPATH=python/generation \
python3 -B python/generation/gen_algebraic_spec_kb.py \
  fixtures/stratified_relations.metta \
  /tmp/algebraic-spec-eval-kb.metta
```

After the fixture, tests, and evaluation pass, regenerate the production KB
using the same raw input paths used by the existing deployment workflow.
