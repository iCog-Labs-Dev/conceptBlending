# gemini_extraction

A Gemini-backed shared-property extraction module producing CASL algebraic
representations, for the conceptBlending pipeline.

## What this is

This implements a standalone extraction-and-encoding pipeline that, given a
pair of concepts, produces a CASL S-expression for each concept describing
8 shared property dimensions, each with a degree (centrality) and a
WorldSpecSet (the ontological domains the property is grounded in for
that concept).

It is **additive and standalone**:
- Lives entirely in `/gemini_extraction`
- Does not modify, import, or depend on any existing `.metta` or Python file
- Produces its own output files; does not write into existing pipeline files

## Relationship to the existing pipeline

The existing pipeline has (at least) two extraction/representation tracks:

1. **CategoricTheory track** -- `gpt-algspec-builder` produces
   `(Concept X (spec (sorts...) (ops...) (preds...) (axioms...)))`,
   a CASL-style Sorts/Ops/Preds/Axioms specification with no numeric degrees.
2. **InfoTheoretic track** -- `gpt_vector` produces
   `(Concept Concept1@Concept2 (Property (P1 D1) (P2 D2) ...))`,
   where both concepts in a pair share the same property names, scored
   independently per concept (0.0-1.0), so the two concepts remain directly
   comparable.

This module follows the design principle of the InfoTheoretic track
(shared property names across a concept pair, independently scored) and
extends it with a WorldSpecSet per property per concept -- the ontological
domain(s) that property is grounded in for that specific concept. This
WorldSpecSet dimension does not exist in either existing track; it is the
novel contribution of this module.

The output format matches the CASL specification this module was designed
against from the outset:

```lisp
(Concept Bat
  (V-predicate
    (Property

      (flight
        (WorldSpecSet
          (WorldSpec-Biology
           WorldSpec-Physics))
        degree-1)

      (reasoning
        (WorldSpecSet ())
        degree-4))))
```

```lisp
(Concept Man
  (V-predicate
    (Property

      (flight
        (WorldSpecSet ())
        degree-5)

      (reasoning
        (WorldSpecSet
          (WorldSpec-Cognition
           WorldSpec-Philosophy))
        degree-1))))
```

Note `flight` and `reasoning` are the same property names in both blocks
(the shared-property invariant), with independently varying degrees and
WorldSpecSets.

## Setup

```bash
cd gemini_extraction
pip install -r requirements.txt
export GEMINI_API_KEY="your_free_key"   # https://aistudio.google.com/app/apikey
```

## Usage

```bash
cd python
python run_extraction.py --concept1 "Bat" --concept2 "Man"
```

Output is written to:
- `metta/generated/Bat_Man.casl` -- both CASL blocks
- `metta/generated/Bat_Man.metta` -- MeTTa atoms, with a `(SharedProperty ...)`
  atom linking each property name to both concepts

## Tests

```bash
cd gemini_extraction
python tests/test_pair_extraction.py
```

Tests cover deterministic logic only: name sanitization, degree-label
boundaries, the shared-property-names invariant, and CASL/MeTTa formatting.
`extractor.extract_pair()` requires `GEMINI_API_KEY` and network access, so
it is excluded from automated tests -- use `run_extraction.py` to verify
that path manually.

## File structure

```
gemini_extraction/
├── README.md
├── requirements.txt
├── python/
│   ├── config.py            -- Gemini config, WorldSpec vocab, degree labels
│   ├── gemini_client.py      -- thin Gemini API wrapper
│   ├── prompts.py            -- shared-property extraction prompt
│   ├── extractor.py          -- concept pair -> shared properties w/ degree + WorldSpecSet
│   ├── casl_encoder.py        -- PairExtraction -> CASL S-expression + MeTTa atoms
│   └── run_extraction.py     -- CLI entry point
├── metta/
│   └── generated/             -- output directory
└── tests/
    └── test_pair_extraction.py
```

## Notes for reviewers

- Property names are generated fresh per concept pair (not drawn from a
  fixed global schema), matching `gpt_vector`'s apparent design as best
  I could determine from its prompt.
- The fixed `WORLDSPEC_VOCAB` list in `config.py` is a controlled vocabulary
  to prevent domain-name drift across runs; happy to align it with any
  existing domain/ontology vocabulary already used elsewhere in the
  pipeline if one exists.
- `degree-N` labels are derived by bucketing the 0.0-1.0 centrality score
  (see `DEGREE_LABELS` in `config.py`) rather than reusing raw floats, to
  match the CASL spec's symbolic degree convention. The underlying float
  is also preserved in the `.metta` output (`CentralityValue` atom) for
  any downstream code that wants the unrounded value.
