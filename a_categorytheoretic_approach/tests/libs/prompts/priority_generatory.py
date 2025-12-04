PRIORITY_PROMPT = """
You are an expert in algebraic specification, formal concept blending, and category theory.
Your task is to assign priority values to every element inside a given specification, following the PCS (Prioritised CASL Specification) framework.

Priority values p ∈ [1, 3, 5, 10] reflect the cognitive and structural importance of each element and will guide anti-unification, colimit construction, pruning, and evaluation of blends.

────────────────────────────────────────────
PRIORITY RULES (PCS FRAMEWORK)
────────────────────────────────────────────

**Priority Annotation Rules (Generalized):**
   - Use integer values (1, 3, 5, 10).
   - `10` → Core structural/functional axioms and operators that **must always hold**. Assign to **all input specs** essential operators and axioms** to ensure balance.
   - `5` → Medium importance roles, actions, or secondary features. Assign consistently across specs to preserve **mirrored contribution**.
   - `3` → Supporting predicates, relations, or mechanisms. Assign to **all supporting predicates in both specs**, keeping parallel priorities.
   - `1` → Background sorts, general definitions, or conceptual scaffolding. Assign to all auxiliary sorts to **maintain structural context**.

**General Principles:**
   1. **Mirrored priority distribution:** Ensure similar elements in both input specs get the same priority based on their importance to their specific concept to **automatically minimize imbalance**.
   2. **Hierarchy-aware assignment:** Higher-priority values go to elements higher in the sort or functional hierarchy.
   3. **Compression support:** Shared or overlapping elements should retain their priority to maximize compression value in blends.
   4. **Normalization:** If specs differ in size, scale lower-priority elements proportionally to maintain total infoValue balance.
   5. **Domain-specific flexibility:** Adjust priorities slightly only if intentional imbalance is desired; otherwise stick to mirrored assignments.

────────────────────────────────────────────
INSTRUCTIONS
────────────────────────────────────────────

Given TWO specifications in PCS-style S-expression format:

specifications: {specs}

Insert a priority annotation directly inside each element using the format: <value>

Apply priorities to:
   - Every sort
   - Every operator
   - Every predicate
   - Every axiom

Do NOT change names, structure, ordering, indentation, or semantics.

Only add priorities.

Maintain the PCS S-expression structure exactly as in the input.

────────────────────────────────────────────
EXAMPLE (PCS-style)
────────────────────────────────────────────

Input:

(Concept Cube
 (spec
  (sorts (Object) ((< Solid Object)) ((< Face Component)))
  (ops ((: cube Solid)) ((: six Nat)) ((: square Shape)))
  (preds ((hasCountOf Solid Component Nat)) ((hasShape Component Shape)))
  (axioms ((hasCountOf cube Face_six)) ((hasShape Face square)))
 )
)

Output:

(Concept Cube
 (spec
  (sorts (Object 1) ((< Solid Object) 1) ((< Face Component) 1))
  (ops ((: cube Solid) 10) ((: six Nat) 5) ((: square Shape) 5))
  (preds ((hasCountOf Solid Component Nat) 3) ((hasShape Component Shape) 3))
  (axioms ((hasCountOf cube Face_six) 10) ((hasShape Face square) 10))
 )
)

────────────────────────────────────────────
OUTPUT FORMAT (STRICT)
────────────────────────────────────────────

Return only the two specifications in the following PCS-style S-expression structure:

(Concept Concept1
 (spec
  (sorts (...))
  (ops (...))
  (preds (...))
  (axioms (...))
 )
)

(Concept Concept2
 (spec
  (sorts (...))
  (ops (...))
  (preds (...))
  (axioms (...))
 )
)

Return only the same specifications with priority annotations added.
avoid (subsort (< subsort Object) p) generalstructure, it must be ((< subsort Object) p) structure.
Do not add any explanations, comments, markdown, or extra text.
"""
