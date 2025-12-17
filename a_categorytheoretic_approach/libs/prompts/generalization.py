GENERALIZATION_PROMPT = """
You are an expert in algebraic specification, formal methods, conceptual integration, and anti-unification (Least Common Generalization - LCG).
Given two algebraic specs, produce a single concise, logically-coherent,a tightly integrated scene that can be manipulated as a unit, and consistent least common generalized spec that preserves shared structure and minimally generalizes differences.

INPUTS:
- Concept1:{concept1}
- Concept2:{concept2}
- specification1: {algspec_1}
- specification2: {algspec_2}

GOAL:
Return exactly one spec for (Concept GenericConcept (spec ...)) that is the LCG of the two input specs:
- Preserve identical sorts, ops, preds, axioms.
- Where components differ, replace with minimally more general element names or least-common super-sort.
- Maintain arities and structural positions.

RULES / HEURISTICS:
1. Sorts:
   - Keep identical sorts.
   - For differing sorts, choose a descriptive super-sort (e.g., Object, Entity, Resource).
   - Preserve declared subsort relations (< Sub Super>) where possible.

2. Ops / Constants:
   - If op names and sorts match, keep them.
   - If names differ but roles align, create a generalized op name (e.g., handheld_tool) and generalize its sort.
   - Represent ops as (: name Sort).

3. Predicates:
   - Preserve predicates with identical arity and intent.
   - Generalize argument sorts consistently (use generalized sorts chosen above).

4. Axioms:
   - Translate axioms by substituting concrete names with generalized names.
   - Preserve logical structure; if an axiom exists in both specs with different arguments, generalize arguments.

5. Naming:
   - Use the algebric specification {algspec_1} and {algspec_2} strings to choose meaningful generalized names.
   - Prefer human-readable, descriptive names (e.g., vertical_structure, GeneralizedPart).

6. Minimality:
   - Only generalize when necessary. Do not invent unrelated structure.
   - If unsure, favor a conservative generalization (keep structure, generalize names/sorts).

OUTPUT FORMAT:
Return ONLY in the following way nothing else (no explanations, no quotes, no markdown):

(Concept {concept1}@{concept2}_Generic
 (spec
  (sorts (...))
  (ops (...))
  (preds (...))
  (axioms (...))
 )
)

FEW-SHOT GUIDANCE (apply same transformation style):
- Pocketknife + Toothbrush -> handheld_tool with shared sorts entity/part/functionality; keep has_part/has_functionality preds; generalize specific parts/functions.
- Signpost + Forest -> vertical_structure with sorts entity/part/attachment; generalize post/trunk -> stem, panel/crown -> top, ground/root -> base.

PROCESS:
1. Parse both specs into sorts/ops/preds/axioms.
2. Align components by role and arity.
3. Compute minimal generalization for each aligned pair.
4. Synthesize the final (Concept GenericConcept (spec ...)) using chosen names and relations.

Strict: output must be a single valid S Expression Concept spec as above.
"""