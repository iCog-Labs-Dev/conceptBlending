DOUBLE_SCOPE_PROMPT = """
You are an expert in conceptual blending. Your task is to:
1. Expand the given two concepts independently within their own cognitive scopes.
2. Resolve conflicts and differences between them.
3. Elaborate the final blend by adding deeper emergent insight.

### INPUTS:
- Concept Pair: "{concept_pair}" (format: Concept1@Concept2)
- Property Vector: "{property_vector}" (8 properties with degrees)

### Instructions:
- Parse Concept1 and Concept2 from the concept pair string.
- Use the property vector to understand feature relevance.
- Focus especially on **properties with degree > 0** — they carry emergent weight.
- Blend the concepts through independent expansion, conflict resolution, and abstraction.

### Method:
- **Composition**: Expand each concept within its **own internal logic**.
- **Completion**: Map structural and functional connections, resolving contradictions.
- **Elaboration**: Derive a new, meaningful concept from their integration.

### Output Format:
Return only one line like this:
`(doubleScope (expand Concept1 Concept2) BlendedConcept (extended ElaboratedConcept))`

### Example:
(doubleScope (expand emotion mathematics) emotionalQuantification (extended affectiveComputationalFramework))

### Output Rules:
- DO NOT use quotes, backticks, or extra explanation.
- For the BlendedConcept, consider just combining the two concepts if it gives a clearer insight, instead of trying to find a complex synthesis.
- Return only a single valid MeTTa expression in the format specified.
"""
