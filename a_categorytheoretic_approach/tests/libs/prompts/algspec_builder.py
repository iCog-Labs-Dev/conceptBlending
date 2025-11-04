SPEC_PROMPT = """
You are an expert in algebraic specification and conceptual modeling. Your task is to:
1. Analyze the structural composition of two given concepts.
2. Represent each concept as a clear, self-contained algebraic specification.
3. Use a parallel structure for both concepts so that they can later be compared, generalized, or blended.

## INPUT CONCEPTS:
- Concept 1: {concept1} (This is the concept name)
- Context 1: {context1} (This is a seed context phrase of {concept1} to guide disambiguation)
- Concept 2: {concept2} (This is the concept name)
- Context 2: {context2} (This is a seed context phrase of {concept2} to guide disambiguation)
### Instructions:
- For each concept, define a specification block using the structure below. 
- Use concise and meaningful names for sorts, operations, and predicates relevant to the concept based on the context provided.
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

Context_AGENT_PROMPT="""
You are an expert in conceptual analysis, semantic modeling, and conceptual blending.

Your task is to analyze two input concepts and generate structured context descriptions. The analysis must capture the essential semantic properties of each concept, guided by its provided seed context.

Your goal is to identify the specific, salient features that make these concepts coherent and structurally compatible, especially for potential conceptual blending.

**EXAMPLE:**
For `Concept 1: Man` (Context: 'a complex individual') and `Concept 2: Bat` (Context: 'a nocturnal creature of the night'), you must choose the **animal** sense of 'Bat', not the 'baseball bat' sense. This is because the 'animal' sense (nocturnal, stealthy, winged) has a high-quality semantic relationship with 'Man' (sentient, driven, masked) to create a blend like 'Batman'. Your output contexts should reflect these blend-compatible features.

## INPUT CONCEPTS:
- Concept 1: {concept1} (This is the concept name)
- Context 1: {context1} (This is a seed context phrase of {concept1} to guide disambiguation)
- Concept 2: {concept2} (This is the concept name)
- Context 2: {context2} (This is a seed context phrase of {concept2} to guide disambiguation)

## REQUIREMENTS:
1.  **Analyze Context:** Use the provided Contexts: `{context1}` and `{context2}` to disambiguate `{concept1}` and `{concept2}` and select the most semantically coherent interpretation to each other.
2.  **Generate Broad Contexts:** Internally generate a wide list of descriptive contexts for each concept based on the chosen interpretation.
3.  **Select Strictly Top 8 not below or above 8:** From your internal list, select **exactly 8** diverse, meaningful, and salient context descriptions which connects and makes the to concept coherant.
4.  **Capture Diverse Aspects:** The 8 descriptions must capture a mix of:
    * **Essential Semantic Properties:** (e.g., 'is a mammal', 'is sentient')
    * **Functional/Semantic Roles:** (e.g., 'navigates using echolocation', 'acts as a vigilante')
    * **Structural/Morphological Properties:** (e.g., 'has wings', 'wears a mask')
    * **Symbolic/Metaphorical Associations:** (e.g., 'symbolizes night and mystery', 'represents justice')
    * **Relational Characteristics:** (e.g., 'is a predator of insects', 'is an enemy of criminals')
    * **Usage/Contextual Patterns:** (e.g., 'emerges at dusk', 'operates in darkness')

## OUTPUT FORMAT:
Return ONLY the one S-expression structures.


(Context
  (descriptive context phrase 1)
  (descriptive context phrase 2)
  (descriptive context phrase 3)
  (descriptive context phrase 4)
  (descriptive context phrase 5)
  (descriptive context phrase 6)
  (descriptive context phrase 7)
  (descriptive context phrase 8)
)


## CRITICAL RULES:
- You MUST return ONLY the one (Context ...) S-expressions.
- Do NOT include any explanations, apologies, or markdown formatting (like ```) in your output.
- Each context phrase must be a complete, meaningful description.
- Ensure the output uses valid S-expression syntax.
"""

