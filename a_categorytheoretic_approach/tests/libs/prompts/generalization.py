
GENERALIZATION_PROMPT = """
You are an expert in algebraic specification, formal methods, and computational logic, specializing in **anti-unification (Least Common Generalization - LCG)**.

Your task is to compute the precise Least Common Generalization (LCG) of two given algebraic specifications. The LCG must preserve only the structural and semantic components shared between both concepts, while generalizing all differing components as minimally as possible.

## INPUT CONCEPTS:
- Concept 1: {concept1}
- Concept 2: {concept2}
- Context:   {context}   (A coherent semantic phrase applying to both concepts)

## INPUT SPECIFICATIONS:
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

### Instructions:

- define a specification block using the structure below. 
- Use concise and meaningful names for sorts, operations, and predicates relevant to the concept based on the context provided.
- Maintain **comparable structure** between the two specifications to facilitate later structural mapping.
- Each specification must include:
  - Use the context {context} provided to guide the selection of sorts, operations, and predicates.
  - (sorts ...)  → sorts and subsort declarations ((< SubSort SuperSort))
  - (ops ...)    → object-level constants ((: name Sort))
  - (preds ...)  → predicates with argument types ((predicate Type1 Type2))
  - (axioms ...) → statements relating operations and predicates ((predicate (arg1 arg2)))

Apply structure-preserving anti-unification across Concepts components:

1. Sort Anti-Unification:
   - For each pair of corresponding sorts, select the least common super-sort.
   - Retain shared global sorts.

2. Operation (Constant) Anti-Unification:
   - For each pair of corresponding constants, introduce a generalized constant whose sort is the LCG of the original sorts.
   - Retain constants identical across both specifications.

3. Predicate Anti-Unification:
   - Only retain predicates that appear in both specifications with the same arity.
   - Generalize predicate argument sorts using the LCG of their respective sorts.

4. Axiom Anti-Unification:
   - Recursively generalize axiom expressions by replacing constants and sorts with their generalized counterparts.

## OUTPUT FORMAT:
Return only one generalized specification named GenericConcept:

(Concept GenericConcept
 (spec
  (sorts (...))
  (ops (...))
  (preds (...))
  (axioms (...))
 )
)

## OUTPUT RULES:
- Do not output the original two specifications.
- Do not explain or comment.
- Do not include markdown formatting or quotes.
- Return only the final (Concept GenericConcept ...) expression.
"""
