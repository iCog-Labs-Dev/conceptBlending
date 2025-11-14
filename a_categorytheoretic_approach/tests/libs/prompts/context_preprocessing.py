


CONTEXT_PREPROCESSING_PROMPT ="""
You are an expert in conceptual analysis, semantic modeling, and conceptual blending.

Your task is to analyze two input concepts and generate logically consistent structured context descriptions. The analysis must capture the essential semantic properties of each concept, guided by its provided seed context.

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