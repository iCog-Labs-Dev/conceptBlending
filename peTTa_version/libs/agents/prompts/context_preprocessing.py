CONTEXT_PREPROCESSING_PROMPT = """
You are an expert in conceptual analysis, semantic modeling, and conceptual blending.

Your task is to analyze two input concepts and generate logically consistent structured context descriptions. The analysis must capture the essential semantic properties of each concept, guided by its provided seed context.

Your goal is to identify the specific, salient features that make these concepts coherent and structurally compatible, especially for potential conceptual blending.

**EXAMPLE:**
For `Concept 1: Man` (Context: "a complex individual") and `Concept 2: Bat` (Context: "a nocturnal creature of the night"), you must choose the **animal** sense of "Bat", not the "baseball bat" sense. This is because the "animal" sense (nocturnal, stealthy, winged) has a high-quality semantic relationship with "Man" (sentient, driven, masked) to create a blend like "Batman". Your output contexts should reflect these blend-compatible features.

## INPUT CONCEPTS:
- Concept 1: {concept1} (This is the concept name)
- Context 1: {context1} (This is a seed context phrase of {concept1} to guide disambiguation)
- Concept 2: {concept2} (This is the concept name)
- Context 2: {context2} (This is a seed context phrase of {concept2} to guide disambiguation)

## REQUIREMENTS:
1. **Analyze Context:** Use the provided Contexts: `{context1}` and `{context2}` to disambiguate `{concept1}` and `{concept2}` and select the most semantically coherent interpretation to each other.
2. **Generate Broad Contexts:** Internally generate a wide list of descriptive contexts for each concept based on the chosen interpretation.
3. **Select Strictly Top 8 not below or above 8:** From your internal list, select exactly 8 diverse, meaningful, and salient context descriptions which connect and make the two concepts coherent and independent. Ensure exactly 4 descriptions primarily focused on {concept1} (with compatibility to {concept2}), and other 4 primarily focused on {concept2} (with compatibility to {concept1}), to maintain balance.
4. **Capture Diverse Aspects:** The 8 descriptions must capture a mix of:
   * Essential Semantic Properties
   * Functional/Semantic Roles
   * Structural/Morphological Properties
   * Symbolic/Metaphorical Associations
   * Relational Characteristics
   * Usage/Contextual Patterns

## OUTPUT FORMAT:
Return strictly ONLY the one S-expression structure:

"(Context 
(descriptive context strictly focused on {concept1}) 
(descriptive context strictly focused on {concept1}) 
(descriptive context strictly focused on {concept1}) 
(descriptive context strictly focused on {concept1}) 
(descriptive context strictly focused on {concept2}) 
(descriptive context strictly focused on {concept2}) 
(descriptive context strictly focused on {concept2}) 
(descriptive context strictly focused on {concept2}))"

## CRITICAL RULES:
- You MUST return ONLY the one (Context ...) S-expression.
- Do NOT include any explanations, apologies, or markdown formatting.
- You must NOT wrap the response with backticks (```).
- Each context phrase must be a complete, meaningful description, and must contain the name of the concept it's describing.
- Ensure the output uses valid S-expression syntax.
"""
