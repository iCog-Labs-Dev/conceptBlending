AMALGAM_PROMPT = """
You are an expert in algebraic specification, formal concept blending, and category theory.
Your role is to perform the **amalgam (pushout)** operation that combines two algebraic specifications (A and B)
along their **least common generalization (C)** into a single consistent, meaningful blended specification **P = A +_C B**.

---

### INPUTS:
- Specification A: {algspec_1}
- Specification B: {algspec_2}
- Generalized (LCG) Spec C: {lcg_spec}

---

### GOAL:
Construct a **blended specification** (Concept concept1@concept2_Blend (spec ...))
that represents the **pushout** of A and B over C — uniting their structures along shared components.

This means:
1. **Preserve** shared structure defined in C.
2. **Merge** corresponding sorts, operations, and predicates of A and B according to C’s mappings.
3. **Generalize** or **synthesize** new elements when both concepts contribute unique features.
4. **Maintain logical coherence** (no contradictions among axioms).
5. **Produce a minimal and interpretable blend** (no redundancy).

---

### RULES & HEURISTICS:

1. **Sorts:**
   - Identify sorts in A and B that correspond to the same generic sort in C and unify them.
   - Keep distinct sorts that have no correspondence.
   - If new super-sorts emerge, name them meaningfully (e.g., Structure, Entity, Medium).

2. **Operations:**
   - Merge operations that share the same arity and generic role in C.
   - Create new generalized operation names when needed (e.g., `gen_location`, `gen_attachment`).
   - Preserve argument positions and output sorts.

3. **Predicates:**
   - Retain predicates that appear in both A and B via C.
   - For unique predicates, include them in the blend if they do not conflict with others.
   - If two predicates differ but serve similar roles, generalize into a new predicate.

4. **Axioms:**
   - Combine consistent axioms from A and B, unifying terms that map through C.
   - If conflicting, produce a generalized version (e.g., conditional or parameterized).
   - Maintain minimality — no redundant or contradictory statements.

5. **Naming & Structure:**
   - Use a merged concept name like `concept1@concept2_Blend`.
   - Choose meaningful generalized operation/predicate names, guided by context.
   - Keep S-expression structure consistent with previous prompts.

6. **Output must be in valid algebraic specification syntax.**
   - Only one Concept spec should be returned.
   - Do not include commentary, explanations, or markdown.

---

### OUTPUT FORMAT:
Return only this structure (strictly, no extra text):

(Concept concept1@concept2_Blend
 (spec
  (sorts (...))
  (ops (...))
  (preds (...))
  (axioms (...))
 )
)

---

### EXAMPLE (from House + Boat):

Inputs:
Spec A = House
Spec B = Boat
Spec C = Generic (Habitable_Structure)

Output:
(Concept House@Boat_Blend
 (spec
  (sorts (Medium (< Boat Object) (< House Object)) (< Habitat Object)))
  (ops ((: boat Boat) (: house House) (: water Medium) (: land Medium)))
  (preds ((on Object Medium) (inhabits Object Habitat)))
  (axioms ((on (boat water)) (on (house land)) (inhabits (house habitat)) (inhabits (boat habitat))))
 )
)

---

### PROCESS:
1. Parse A, B, and C into their (sorts, ops, preds, axioms).
2. Identify the mappings from C → A and C → B.
3. Construct the merged signature: disjoint union of A and B modulo identifications from C.
4. Merge axioms that agree structurally.
5. Output a clean, logically coherent specification in the format above.

Return strictly one valid specification block for (Concept concept1@concept2_Blend).
"""
