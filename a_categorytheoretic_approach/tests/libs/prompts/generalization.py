GENERALIZATION_PROMPT = """
You are an expert in algebraic specification, formal methods, and anti-unification (Least Common Generalization - LCG).
Given two algebraic specs containing PRIORITY WEIGHTS (floats 0.0-1.0), produce a single concise, logically-coherent, and consistent least common generalized spec.

INPUTS:
- Concept 1: {concept1}
- Concept 2: {concept2}
- specification1: {algspec_1}
- specification2: {algspec_2}

GOAL:
Return exactly one spec for (Concept GenericConcept (spec ...)) that is the LCG of the two input specs.
You MUST calculate the new Priority Weight for every generalized element by AVERAGING the weights of the corresponding input elements.

RULES / HEURISTICS:
1. Sorts:
   - Identify shared structures (e.g., Spec A has (Wall 0.9), Spec B has (Hull 0.8)).
   - Generalize to a super-sort (e.g., Enclosure).
   - WEIGHT CALCULATION: (0.9 + 0.8) / 2 = 0.85. Output: (Enclosure 0.85).

2. Ops / Constants:
   - If op names differ but roles align, create a generalized op name.
   - Generalize the sort and AVERAGE the weights.
   - Format: ((: name Sort) Weight).

3. Predicates & Axioms:
   - Preserve logical structure.
   - Average the weights of the corresponding axioms from the inputs.

4. Minimality:
   - Only generalize when necessary. Do not invent unrelated structure.

OUTPUT FORMAT:
Return ONLY the single S-expression (no markdown, no quotes):

(Concept {concept1}@{concept2}
 (spec
  (sorts (
    (GeneralizedSort Weight)
    ((< Sub Super) Weight)
  ))
  (ops (
    ((: opName Sort) Weight)
  ))
  (preds (
    ((predName Type) Weight)
  ))
  (axioms (
    ((predName (arg)) Weight)
  ))
 )
)

FEW-SHOT GUIDANCE (apply same transformation style):
Input A: (sorts ((Wall 0.9)))
Input B: (sorts ((Hull 0.8)))
-> Output: (sorts ((Enclosure 0.85)))

Input A: (ops (((: build Wall) 1.0)))
Input B: (ops (((: construct Hull) 0.8)))
-> Output: (ops (((: make Enclosure) 0.9)))

FEW-SHOT GUIDANCE (apply same transformation style):
- Pocketknife + Toothbrush -> handheld_tool with shared sorts entity/part/functionality; keep has_part/has_functionality preds; generalize specific parts/functions.
- Signpost + Forest -> vertical_structure with sorts entity/part/attachment; generalize post/trunk -> stem, panel/crown -> top, ground/root -> base.

PROCESS:
1. Parse both specs into sorts/ops/preds/axioms.
2. Align components by role and arity.
3. Compute minimal generalization for each aligned pair.
4. Synthesize the final (Concept GenericConcept (spec ...)) using chosen names and relations.

Strict: output must be a single valid MeTTa Concept spec as above.
"""