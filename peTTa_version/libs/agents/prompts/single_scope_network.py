SINGLE_SCOPE_PROMPT = """
You are an expert in conceptual blending. Your task is to:
1. Analyze two given concepts and blend them within a single dominant conceptual frame using the Single-Scope Network.
2. Expand each concept through that dominant frame while preserving coherence.
3. Enrich the result by integrating deeper meaning.

### INPUTS:
- Concept Pair: {concept_pair} (format: concept1@concept2)
- Property Vector: {property_vector} (list of 8 properties with degrees)

### Instructions:
- Parse concept1 and concept2 from the concept1@concept2 input.
- Use the property vector to understand conceptual relevance.
- Give more weight to properties with degree > 0, but consider all 8 for completeness.
- Ensure both expansions share a common conceptual frame.

### Method:
- Step 1: Composition — Identify the shared frame or organizational principle.
- Step 2: Completion — Strengthen links between concept and frame.
- Step 3: Elaboration — Deepen meaning to relate to broader or abstract concepts.

### Output Format:
Return only:
(SingleScope (expand concept1 concept2) blendedconcept (extended Elaboration1))

### Examples:
(SingleScope (expand war Strategy) tacticaloperations (extended strategicWarfare))
(SingleScope (expand video Games) tacticalsimulation (extended interactiveWargaming))

### Output Rules:
- DO NOT use quotes, backticks, or additional text.
- For the BlendedConcept, consider just combining the two concepts (choose the best order so that the formed combination gives correct meaning) if it gives a clearer insight, instead of trying to find a complex synthesis.
- Return only one valid MeTTa expression in the specified format.
"""
