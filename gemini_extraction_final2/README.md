# gemini_extraction — V-Quantale Blending Pipeline

A unified Gemini-powered conceptual blending pipeline that combines the
**InfoTheoretic** and **Categoric** tracks into one output using
**V-quantale operators** (join, product, residuation).

## One input. One output.

```bash
python pipeline.py --concept1 "Bat" --concept2 "Man"
```

```lisp
(Concept BatMan
  (V-predicate
    (Property

      (flight
        (WorldSpecSet
          (WorldSpec-Biology
           WorldSpec-Physics))
        (quantale-strength 0.8712)
        degree-1)

      (nocturnal-hunting
        (WorldSpecSet
          (WorldSpec-Ecology
           WorldSpec-Biology))
        (quantale-strength 0.6340)
        degree-2)

      (abstract-duality
        (WorldSpecSet ())
        (quantale-strength 0.0821)
        degree-5)

    )))
```

## How it works

Three stages, one output:

### Stage 1 — InfoTheoretic extraction
A single Gemini call extracts 8 shared property dimensions across both
concepts. For each property:
- Same property name applies to both concepts (shared dimension)
- Per-concept centrality score (0.0–1.0): how strongly this property characterises each concept
- Per-concept confidence score (0.0–1.0): how reliable that centrality is
- Per-concept WorldSpecSet: the ontological domains the property is grounded in for that concept

### Stage 2 — Categoric algebraic grounding
For each of the 8 properties, Gemini extracts a formal algebraic structure
(Sorts, Ops, Predicates, Axioms) describing what that property means structurally.
Each item is scored by relevance and confidence, and the sections are filtered
and ranked to the top 5 items per section:
- Malformed or vague items (confidence < 0.2) are removed
- Items ranked by strength = relevance × confidence
- Only the top 5 per section survive into the output

### Stage 3 — V-Quantale engine (pure Python, no AI)
The quantale engine merges both tracks into one unified property per dimension:

| Operator | Formula | Purpose |
|----------|---------|---------|
| **join** | `max(c1_centrality, c2_centrality)` | Unified degree — strongest presence across either concept |
| **product** | `c1_confidence × c2_confidence` | Propagated confidence — how reliable the join is |
| **product** | `unified_degree × alg_confidence` | Quantale strength — combines semantic + algebraic quality |
| **residuation** | `strength < threshold → filter` | Optimality constraint — removes weak properties |

The WorldSpecSet for each property in the output is the union of both
concepts' WorldSpecs, ordered by how strongly each domain is referenced
in the algebraic grounding items.

## Output format

```lisp
(Concept BlendName
  (V-predicate
    (Property

      (property-name
        (WorldSpecSet
          (WorldSpec-X
           WorldSpec-Y))
        (quantale-strength 0.8712)   ← new: quantale-computed strength
        degree-1)                    ← derived from join(c1, c2)

    )))
```

The `quantale-strength` is the novel field — it captures the combined
semantic centrality and algebraic grounding quality of each property,
not just a raw degree score.

## Setup

```bash
cd gemini_extraction
pip install -r requirements.txt
export GEMINI_API_KEY="your_key"   # https://aistudio.google.com/app/apikey
```

## Usage

```bash
cd python
python pipeline.py --concept1 "Bat" --concept2 "Man"
python pipeline.py --concept1 "house" --concept2 "boat"
python pipeline.py --concept1 "Solar Energy" --concept2 "Water Purification"
```

Output files in `metta/generated/`:
- `BlendName.casl`  — CASL V-predicate output
- `BlendName.metta` — MeTTa atoms (WorldSpecSet, Degree, QuantaleStrength, AlgSpec)
- `BlendName.json`  — full structured output

## MeTTa integration

```lisp
!(import! &self gemini_extraction:python:gemini_atoms)
!(gemini:vq-blend house boat)
```

## Tests

```bash
cd gemini_extraction
python tests/test_pipeline.py
```

17 tests, all deterministic (no API key needed).

## File structure

```
gemini_extraction/
├── README.md
├── requirements.txt
├── python/
│   ├── config.py                  — shared config
│   ├── gemini_client.py            — Gemini API wrapper
│   ├── gemini_atoms.py             — MeTTa atom registration
│   ├── utils.py                    — shared helpers
│   ├── pipeline.py                 — master entry point
│   ├── info_theoretic/
│   │   └── extractor.py            — shared property vector extraction
│   ├── categoric/
│   │   └── extractor.py            — algebraic grounding per property
│   └── quantale/
│       ├── engine.py               — join / product / residuation
│       └── encoder.py              — CASL + MeTTa + JSON encoding
├── metta/
│   ├── gemini_extensions.metta
│   └── generated/
└── tests/
    └── test_pipeline.py
```
