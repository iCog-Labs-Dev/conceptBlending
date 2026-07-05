# gemini_extraction

Gemini-backed alternative backend for the conceptual blending pipeline,
providing parallel `gemini:` atoms alongside the existing `llm:` atoms.

## What this adds

The existing pipeline uses four Python-backed MeTTa atoms:

| Existing atom        | Stage                    | This module adds     |
|----------------------|--------------------------|----------------------|
| `llm:generate-spec`  | Algebraic spec builder   | `gemini:generate-spec` |
| `llm:generate-gen`   | Generalization builder   | `gemini:generate-gen`  |
| `llm:find-morph`     | Morphism finder          | `gemini:find-morph`    |
| `math:colimit`       | Blend / colimit          | `gemini:colimit`       |

All existing `llm:` atoms remain untouched. The `gemini:` atoms are purely
additive and can be used selectively (swap one stage) or wholesale
(replace all four by using `gemini:pipeline`).

## Output format

The terminal output of `gemini:colimit` / `gemini:pipeline` is the
CASL V-predicate format with WorldSpecSet and degree-N labels:

```lisp
(Concept HouseBoatBlend
  (V-predicate
    (Property

      (structural-containment
        (WorldSpecSet
          (WorldSpec-Engineering
           WorldSpec-Materials))
        degree-1)

      (medium-navigation
        (WorldSpecSet
          (WorldSpec-Physics
           WorldSpec-Ecology))
        degree-2)

      (inhabitant-relation
        (WorldSpecSet ())
        degree-4)

    )))
```

This is the colimit of the categorical blending diagram:
Spec A <- Generic Space -> Spec B, pushed out to the blended concept.

## Pipeline stages

### Stage 1 — Algebraic Spec Builder (`spec_builder.py`)
Mirrors `algspec_builder.metta` / `llm:generate-spec`.
Given two concepts and a context, produces two parallel algebraic
specifications in `(Concept X (spec (sorts...) (ops...) (preds...) (axioms...)))` form.

### Stage 2 — Generalization Builder (`generalization_builder.py`)
Mirrors `generalization_builder.metta` / `llm:generate-gen`.
Finds the least common generalization of both specs -- the generic space
(colimit base) in category-theoretic terms.

### Stage 3 — Morphism Finder (`morphism_finder.py`)
Mirrors `morphism_finder.metta` / `llm:find-morph`.
Finds the structure-preserving mapping from the generic space into each
target spec. Called once per concept (twice per blend).

### Stage 4 — Blend / Colimit (`blend_colimit.py`)
Mirrors `math:colimit`.
Computes the categorical pushout of the blending diagram and encodes
the result as the CASL V-predicate output format.

## Setup

```bash
cd gemini_extraction
pip install -r requirements.txt
export GEMINI_API_KEY="your_free_key"   # https://aistudio.google.com/app/apikey
```

## Usage

### Python pipeline (no MeTTa runtime needed)

```bash
cd python
python pipeline.py --concept1 house --concept2 boat
python pipeline.py --concept1 "Solar Energy" --concept2 "Water Purification" --context "energy transformation systems"
```

Outputs per stage are saved to `metta/generated/`:
- `ConceptA_ConceptB_spec_a.metta`
- `ConceptA_ConceptB_spec_b.metta`
- `ConceptA_ConceptB_generic.metta`
- `ConceptA_ConceptB_morph_a.metta`
- `ConceptA_ConceptB_morph_b.metta`
- `ConceptA_ConceptB_blend.casl`

### MeTTa integration (with Hyperon)

```lisp
!(import! &self gemini_extraction:metta:gemini_extensions)

; Run the full pipeline with Gemini
!(gemini:pipeline house boat)

; Or swap individual atoms in master_pipeline.metta:
; replace llm:generate-spec with gemini:generate-spec
; replace math:colimit with gemini:colimit
```

## Tests

```bash
cd gemini_extraction
python tests/test_pipeline.py
```

## File structure

```
gemini_extraction/
├── README.md
├── requirements.txt
├── python/
│   ├── config.py                -- Gemini config, WorldSpec vocab
│   ├── gemini_client.py          -- google-genai SDK wrapper
│   ├── prompts.py                -- all four stage prompts
│   ├── spec_builder.py           -- Stage 1: algebraic spec generation
│   ├── generalization_builder.py -- Stage 2: least generalization
│   ├── morphism_finder.py        -- Stage 3: structure-preserving morphism
│   ├── blend_colimit.py          -- Stage 4: colimit -> CASL V-predicate output
│   ├── gemini_atoms.py           -- MeTTa atom registration (gemini: namespace)
│   └── pipeline.py               -- Python master pipeline (mirrors master_pipeline.metta)
├── metta/
│   ├── gemini_extensions.metta   -- MeTTa wrappers registering gemini: atoms
│   └── generated/                -- output directory
└── tests/
    └── test_pipeline.py
```

## Notes for reviewers

- `gemini:generate-spec` and `gemini:generate-gen` use the same prompt
  structure as the existing `gpt-algspec-builder` and `gpt-generalization-helper`
  prompts, adapted for Gemini and structured output.
- The WorldSpecSet dimension in the colimit output is additive -- it does
  not exist in the existing pipeline's output but is the novel contribution
  of this module, providing ontological domain grounding per blended property.
- `gemini_atoms.py` registration uses `OperationAtom` from Hyperon. If the
  existing `extensions.py` uses a different registration pattern, only the
  `register_gemini_atoms` function needs to change; all underlying Python
  logic is independent of the registration mechanism.
