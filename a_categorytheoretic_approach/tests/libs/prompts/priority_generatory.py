PRIORITY_PROMPT = """
You are an expert in algebraic specification, formal concept blending, and category theory.
Your task is to assign priority values to every element inside a given specification, following the PCS (Prioritised CASL Specification) framework.

Priority values p ∈ [1, 3, 5, 10] reflect the cognitive and structural importance of each element and will guide anti-unification, colimit construction, pruning, and evaluation of blends.

────────────────────────────────────────────
PRIORITY RULES (STRICT, PCS FRAMEWORK)
────────────────────────────────────────────

**Priority Annotation Rules:**
   - Use integer values (p:1, p:3, p:5, p:10).
   - `p:10` → Core structural/functional axioms and operators (must always hold).
   - `p:5` → Medium importance roles, actions, or secondary features.
   - `p:3` → Supporting predicates, relations, or mechanisms.
   - `p:1` → Background sorts, general definitions, or conceptual scaffolding.

────────────────────────────────────────────
INSTRUCTIONS
────────────────────────────────────────────

Given TWO specifications in PCS-style S-expression format:

specifications: {specs}

Insert a priority annotation directly inside each element using the format: p:<value>

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
  (sorts (Object) (Solid (< Solid Object)) (Face (< Face Component)))
  (ops ((: cube Solid)) ((: six Nat)) ((: square Shape)))
  (preds ((hasCountOf Solid Component Nat)) ((hasShape Component Shape)))
  (axioms ((hasCountOf cube Face_six)) ((hasShape Face square)))
 )
)

Output:

(Concept Cube
 (spec
  (sorts (Object p:1) (Solid (< Solid Object) p:1) (Face (< Face Component) p:1))
  (ops ((: cube Solid) p:10) ((: six Nat) p:5) ((: square Shape) p:5))
  (preds ((hasCountOf Solid Component Nat) p:3) ((hasShape Component Shape) p:3))
  (axioms ((hasCountOf cube Face_six) p:10) ((hasShape Face square) p:10))
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
Do not add any explanations, comments, markdown, or extra text.
"""
