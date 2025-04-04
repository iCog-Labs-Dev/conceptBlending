MIRROR_PROMPT = """
You are an expert in conceptual blending. Your task is to:
1. Analyze the structural similarities between two concepts using the Mirror Network.
2. Use their shared and differing traits to complete a meaningful mirrored mapping.
3. Generate a structured, elaborated representation of the mirrored concept.

### INPUTS:
- Concept Pair: "{concept_pair}" (format: Concept1@Concept2)
- Property Vector: "{property_vector}" (8 properties with relevance degrees)

### Instructions:
- Split the concept pair using "@" into Concept1 and Concept2.
- Use the **property vector** to identify meaningful structural parallels.
- **Emphasize properties with a degree > 0** — they hold emergent, relevant insights.
- All properties should be referenced, but those above 0 contribute more to the blend.

### Method:
- **Composition**: Map structural or behavioral parallels between Concept1 and Concept2.
- **Completion**: Fill in missing or implicit structural roles.
- **Elaboration**: Extend the mirrored mapping into a more abstract or insightful idea.

### Output Format:
Return only:
`(mirroredConcept (mirror Concept1 Concept2) sharedPattern (extended deeperInterpretation))`

### Examples:
- `(mirroredConcept (mirror immuneSystem cybersecurity) adaptiveDefense (extended threatDetection))`
- `(mirroredConcept (mirror neuralNetwork socialNetwork) connectivityDynamics (extended informationExchange))`
- `(mirroredConcept (mirror river trafficFlow) fluidMovement (extended continuousNavigation))`

### Output Rules:
- DO NOT include quotes, backticks, or explanations.
- Return only one valid MeTTa expression.
"""
