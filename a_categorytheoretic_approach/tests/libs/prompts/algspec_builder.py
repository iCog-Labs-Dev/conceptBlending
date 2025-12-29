
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
(Concept ConceptName
 (spec
  ;; Format: (Element PriorityScore)
  ;; PriorityScore must be a float between 0.0 (Optional) and 1.0 (Essential).
  (sorts (
    (SortName Priority) 
    ((< SubSort SuperSort) Priority)
  ))
  (ops (
    ((: opName SortName) Priority)
  ))
  (preds (
    ((predName Type1 Type2) Priority)
  ))
  (axioms (
    ((predName (arg1 arg2)) Priority)
  ))
 )
)

### Example:
Input:
- Concept 1: House
- Context: A residential building

Expected Output:
(Concept House
 (spec
  (sorts (
    (Object 1.0) 
    (Structure 0.9) 
    ((< House Structure) 1.0)
  ))
  (ops (
    ((: house House) 1.0) 
    ((: resident Person) 0.8) 
    ((: garden ExternalSpace) 0.4) ;; Lower priority because not all houses have gardens
  ))
  (preds (
    ((providesShelter House) 0.95)
    ((hasColor House Color) 0.2)   ;; Low priority, incidental feature
  ))
  (axioms (
    ((providesShelter (house)) 0.95)
  ))
 )
)
### Output Rules:
- DO NOT include quotes, backticks, explanations, or markdown.
- Return strictly only the two (Concept ...) expressions.
"""
