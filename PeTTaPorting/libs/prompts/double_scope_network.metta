
(= (double-scope-prompt $concept-pair $property-vector)
       (You are an expert in conceptual blending. Your task is to:\n\
1. Expand the given two concepts independently within their own cognitive scopes.\n\
2. Resolve conflicts and differences between them.\n\
3. Elaborate the final blend by adding deeper emergent insight.\n\
\n\
### INPUTS:\n\
- Concept Pair: $concept-pair (format: Concept1@Concept2)\n\
- Property Vector: $property-vector (8 properties with degrees)\n\
\n\
### Instructions:\n\
- Parse Concept1 and Concept2 from the concept pair string.\n\
- Use the property vector to understand feature relevance.\n\
- Focus especially on **properties with degree > 0** — they carry emergent weight.\n\
- Blend the concepts through independent expansion, conflict resolution, and abstraction.\n\
\n\
### Method:\n\
- **Composition**: Expand each concept within its **own internal logic**.\n\
- **Completion**: Map structural and functional connections, resolving contradictions.\n\
- **Elaboration**: Derive a new, meaningful concept from their integration.\n\
\n\
### Output Format:\n\
Return only one line like this:\n\
`(doubleScope (expand Concept1 Concept2) BlendedConcept (extended ElaboratedConcept))`\n\
\n\
### Example:\n\
(doubleScope (expand emotion mathematics) emotionalQuantification (extended affectiveComputationalFramework))\n\
\n\
### Output Rules:\n\
- DO NOT use quotes, backticks, or extra explanation.\n\
- For the BlendedConcept, consider just combining the two concepts if it gives a clearer insight, instead of trying to find a complex synthesis.\n\
- Return only a single valid MeTTa expression in the format specified.\n)
)

; !(double-scope-prompt bat@man (1 1 1 1 1 1 1 1))