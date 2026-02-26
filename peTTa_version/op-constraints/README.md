# Optimality Constraints in PeTTa

This document explains the **optimality constraints** used to evaluate conceptual blends in this project’s **PeTTa** implementation.

The constraint modules are in this folder:
- `integration.metta`
- `metonymy.metta`
- `unpacking.metta`
- `web.metta`
- `topology.metta`
- `good-reason.metta`
- shared helpers in `common-utils.metta`
- Python helpers in `op-helper-codes.py`
- orchestrator in `op-evaluation.metta`

---

## 1) Purpose and Scope

The optimality constraints estimate how good a candidate blend is from multiple angles (consistency, recoverability, structural preservation, justification, etc.).

At runtime, `op-evaluater` in `op-evaluation.metta` computes a vector of scores:
1. Integration
2. Metonymy
3. Unpacking
4. Web
5. Topology
6. Good-reason

These are returned as separate values (not currently combined into one weighted scalar).

---

## 2) Blend and Concept Representation

Across constraints, concepts/blends are treated as 4-tuples:

`($blend-or-concept $name $properties $relations)`

Where:
- `$name`: concept/blend symbol
- `$properties`: list-like expression whose payload is accessed by `properties-list`
- `$relations`: relation key-value-like expression whose payload is accessed by `relations-key-value-list`

Helpers in `common-utils.metta`:
- `blend-name`
- `properties-list`
- `relations-key-value-list`
- `greater-than-threshold-props`
- `prop-names-or-degrees-extractor`
- `sum-op`, `to-float-op`, membership and list utilities

---

## 3) End-to-End Evaluation Flow

`op-evaluation.metta`:
1. loads large concept atomspace chunks into `&space`
2. imports Python helper module (`op-helper-codes.py`)
3. imports common utilities and each constraint module
4. runs each constraint in sequence via `op-evaluater`

Return shape from `op-evaluater`:

`($integration-res $metonymy-res $unpacking-res $web-res $topology-res $good-reason-res)`

Note: `good-reason-op` itself currently returns `(Conceptnet-score <x> LLM-score <y>)`, so the sixth element is a structured result rather than a single float.

---

## 4) Constraint Reference

## 4.1 Integration (`integration-op`)

File: `integration.metta`

### Intent
Measure semantic coherence by penalizing property conflicts and rewarding similarity among property names.

### Inputs
- blend (`$blend`)
- its property list from `properties-list`

### Core logic
1. Keep properties above threshold (`int-prop-degree-threshold`, default `0.3`)
2. Extract property names
3. Count conflicts among property-name pairs:
   - direct predefined conflicts (`predefined-conflicts`, expected to be defined upstream)
   - antonymy from `&space` via relation `(antonym a b)`
4. Compute conflict penalty:

$$
\text{conflict-ratio} = \frac{\text{conflicts}}{\sqrt{|P|}}, \quad
\text{conflict-res} = \max(0, 1 - \text{conflict-ratio})
$$

5. Compute semantic coherence of property names using Python embedding similarity
6. Final score:

$$
\text{integration} = \frac{\text{conflict-res} + \text{coherence}}{2}
$$

### Output
- scalar float (intended in `[0,1]`, depending on embedding output and conflict scaling)

### Edge cases
- If no filtered properties, denominator behavior depends on current runtime semantics; ensure non-empty filtered set before production use.

---

## 4.2 Metonymy (`metonymy-op`)

File: `metonymy.metta`

### Intent
Estimate semantic compression: whether blend relations point to targets strongly tied to the blend concept (or characteristic parts).

### Inputs
- blend relations
- blend properties
- blend name

### Core logic
1. Iterate blend relations
2. Keep only metonymy-indicator relation types:
   - `relatedTo`, `synonym`, `formOf`, `hasA`, `partOf`, `atLocation`
3. For each candidate relation target, mark as semantically compressed if either:
   - target is semantically similar to blend name (`met-sim-threshold`, default `0.2`), or
   - `detect-characteristic-parts` is enabled (`True`) and target appears among blend property names
4. Score is ratio:

$$
\text{metonymy} = \frac{\#\text{compressed-relations}}{\#\text{total-relations}}
$$

### Output
- scalar float in `[0,1]`

### Edge cases
- if blend has no relations, returns `0.0`

---

## 4.3 Unpacking (`unpacking-op`)

File: `unpacking.metta`

### Intent
Measure recoverability of source structure from the blend.

### Inputs
- blend, concept1, concept2

### Subscores
1. **Property recoverability**
   - compares high-degree properties above `prop-degree-threshold` (`0.3`)
   - ratio of blend filtered property count to unique source filtered property names

$$
\text{prop-recoverability} = \frac{|P_b^{\ge t}|}{|\text{unique}(P_{c1}^{\ge t} \cup P_{c2}^{\ge t})|}
$$

2. **Blend dominance**
   - for each aligned property index, checks if blend degree exceeds both source degrees
   - score is fraction of dominant properties

3. **Relations traceability**
   - each blend relation is checked against union of source relations using semantic similarity matching
   - similarity threshold: `min-similarity = 0.3`

### Final score

$$
\text{unpacking} = \frac{\text{prop-recoverability} + \text{blend-dominance} + \text{relations-traceability}}{3}
$$

### Output
- scalar float (nominally near `[0,1]`)

### Edge cases
- several divisions assume non-empty sets; guard at caller level if sparse blends are possible.

---

## 4.4 Web (`web-op`)

File: `web.metta`

### Intent
Evaluate integrity of cross-space mappings plus property dominance balance.

### Inputs
- blend relations/properties
- source relations/properties from concept1 and concept2

### Subscores
1. **Cross-space relation mapping**
   - each source relation gets:
     - `1.0` if exact relation exists in blend
     - `0.8` if semantically similar match exists above `semantic-threshold` (`0.25`)
     - `0.0` otherwise
   - average over source relation set

2. **Crucial-link integrity (CLI)**
   - uses dominance pattern over property degrees
   - implemented as `1 - dominance-ratio`

### Final score

$$
\text{web} = \frac{\text{CLI} + \text{cross-space-mapping}}{2}
$$

### Output
- scalar float

### Edge cases
- `relation-exists-in-blend` argument order should be kept consistent with call sites when extending code.

---

## 4.5 Topology (`topology-op`)

File: `topology.metta`

### Intent
Assess whether structural relations in the blend preserve source topology after semantic normalization.

### Inputs
- blend relations
- source relations from concept1 and concept2

### Core logic
1. Build source relation pool (`concept1 ∪ concept2`)
2. Normalize relation variants through semantic matching:
   - compare relation type similarity and target similarity
   - threshold `similarity-threshold = 0.4`
3. Count how many normalized blend relations are present in normalized source relations
4. Compute preservation ratio:

$$
\text{topology} = \frac{\#\text{preserved-relations}}{\#\text{blend-relations}}
$$

### Output
- scalar float in `[0,1]` when denominator is non-zero

### Edge cases
- if blend has no relations, denominator handling should be validated in runtime.

---

## 4.6 Good Reason (`good-reason-op`)

File: `good-reason.metta`

### Intent
Check whether strong blend properties are justifiable from source knowledge and/or LLM reasoning.

### Inputs
- blend, concept1, concept2
- concept graph space `&space`

### Core logic
1. Build provenance labels for each blend property via `provenance-helper` in `common-utils.metta`
2. Keep blend properties above `gd-threshold` (`0.5`)
3. Compute two justification channels:
   - **ConceptNet-style channel**: property justified by direct/source similarity checks over `hasProperty` graph relations (`gd-sim-threshold = 0.15`)
   - **LLM channel**: `gpt_agents.gpt_good_reason(...)` output parsed by Python helper `llm_result`
4. Normalize both counts by number of above-threshold properties

### Output
Structured pair:

`(Conceptnet-score <float> LLM-score <float>)`

### Edge cases
- if no properties above threshold, returns `0.0`
- JSON formatting from LLM output must match parser expectations in `llm_result`

---

## 5) Python Helper Functions (`op-helper-codes.py`)

### `compute_average_pairwise_similarity(properties)`
- Loads `SentenceTransformer('all-MiniLM-L6-v2')` lazily
- Encodes terms and computes mean pairwise cosine similarity
- Used by multiple constraints for semantic matching

### `llm_result(response)`
- strips markdown code fences
- parses JSON and converts `result` sequence into integer list

### `get_word_associations(word)`
- queries Datamuse API for related words
- utility for lexical expansion scenarios

### `split_at_symbol(text)`
- helper for parsing `a@b` style inputs into `(a b)`

### External dependencies
- `sentence-transformers`
- `scikit-learn`
- `numpy`
- `requests`
- `openai`

---

## 6) Thresholds and Parameters

| Parameter | Location | Default |
|---|---|---:|
| `int-prop-degree-threshold` | `integration.metta` | `0.3` |
| `met-sim-threshold` | `metonymy.metta` | `0.2` |
| `prop-degree-threshold` | `unpacking.metta` | `0.3` |
| `min-similarity` | `unpacking.metta` | `0.3` |
| `expansion-enabled` | `unpacking.metta` | `True` |
| `semantic-threshold` | `web.metta` | `0.25` |
| `similarity-threshold` | `topology.metta` | `0.4` |
| `gd-threshold` | `good-reason.metta` | `0.5` |
| `gd-sim-threshold` | `good-reason.metta` | `0.15` |
| `detect-characteristic-parts` | `common-utils.metta` | `True` |

---

## 7) Running and Testing

From project root (`conceptBlending/PeTTaPorting`), typical steps:
1. install Python requirements
2. ensure PeTTa runtime and imports are available
3. run `ep-evaluation.metta`
4. tests are included in `tests/cma-es-tests.metta`

For constraint-focused debugging:
- run one constraint op at a time (`integration-op`, `metonymy-op`, ...)
- inspect intermediate lists (filtered properties, normalized relations, provenance)
- verify `&space` graph imports in `op-evaluation.metta`

---

## 8) Troubleshooting

- **Slow first run**: sentence-transformer model download/loading is expected on first use.
- **Import failures**: verify relative import paths and concept-atomspace chunk files referenced in `op-evaluation.metta`.
- **LLM parsing errors**: ensure LLM output is valid JSON and includes a `result` field in expected format.
- **Network/API issues**: Datamuse/OpenAI-dependent calls may fail offline.

---

## 9) Extending with a New Optimality Constraint

When adding a new constraint module:
1. implement `<new-op>` in its own `.metta` file
2. keep output format explicit (scalar or structured)
3. import in `op-evaluation.metta`
4. call from `op-evaluater` and append to return tuple
5. document new thresholds and expected range in this README

Our next quarter design conventions:
- keep threshold constants as dedicated functions
- isolate reusable utilities in `common-utils.metta`
- keep Python bridge logic in `op-helper-codes.py` when embeddings/API calls are needed

---

## 10) Quick Reference: Output Semantics

- Higher is generally better for `integration`, `metonymy`, `unpacking`, `web`, `topology`
- `good-reason-op` returns two channels (`Conceptnet-score`, `LLM-score`)
- Interpret scores comparatively across candidate blends, not as absolute truth
