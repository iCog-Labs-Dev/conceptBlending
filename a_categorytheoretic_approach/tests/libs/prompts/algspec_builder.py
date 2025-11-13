
SPEC_PROMPT = """
You are an expert in algebraic specification and conceptual modeling. Your task is to:
1. Analyze the structural composition of two given concepts.
2. Represent each concept as a clear, self-contained,and logically-consistent algebraic specification.
3. Use a parallel structure for both concepts so that they can later be compared, generalized, or blended.

## INPUT CONCEPTS:
- Concept 1: {concept1} (This is the concept name)
- Concept 2: {concept2} (This is the concept name)
- Context 2: {context} (This is a seed choherant context phrase of both {concept1} and {concept2} to guide disambiguation)
### Instructions:
- For each concept, define a specification block using the structure below. 
- Use concise, logically consistent, and meaningful names for sorts, operations, and predicates relevant to the concept based on the context provided.
- Maintain **comparable structure** between the two specifications to facilitate later structural mapping.
- Each specification must include:
  - Use the context provided to guide the selection of sorts, operations, and predicates.
  - (sorts ...)  → sorts and subsort declarations ((< SubSort SuperSort))
  - (ops ...)    → object-level constants ((: name Sort))
  - (preds ...)  → predicates with argument types ((predicate Type1 Type2))
  - (axioms ...) → statements relating operations and predicates ((predicate (arg1 arg2)))

### Output Format:
Return only the two specifications in the following S-expression structure:

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

### Example:
Input:
- Concept 1: House
- Concept 2: Boat

Expected Output:
(Concept House
 (spec
  (sorts (Medium (< House Object) (< Person Object)))
  (ops ((: house House) (: resident Person) (: land Medium)))
  (preds ((livein Person House) (on Object Medium)))
  (axioms ((livein (resident house)) (on (house land))))
  )
)
(Concept Boat
 (spec
  (sorts (Medium (< Boat Object) (< Person Object)))
  (ops ((: boat Boat) (: passenger Person) (: water Medium)))
  (preds ((ride Person Boat) (on Object Medium)))
  (axioms ((ride (passenger boat)) (on (boat water))))
  )
)

### Output Rules:
- DO NOT include quotes, backticks, explanations, or markdown.
- Return strictly only the two (Concept ...) expressions.
"""
