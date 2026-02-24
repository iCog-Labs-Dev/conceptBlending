GOOD_REASON = """
Evaluate the properties {properties} in the blend concept {blend}.

**Context:**  
{context}

The context contains:
- Properties: a list of candidate properties.
- Relations: mappings or structural correspondences.
- Sources: the input spaces from which the blend is constructed.

Treat the listed Sources as the input spaces of the blend.

**Evaluation Principle (Relevance Principle):**  
A property should be included in the blend only if it is relevant.

Relevance means:

1. The property helps establish meaningful links between the input spaces (the Sources listed in the context).
2. The property contributes to running or maintaining the internal logic of the blend.
3. The property supports the coherence, structure, or functionality of the blended concept.

If a property does not contribute in at least one of these ways, it should not be justified.

When evaluating, explicitly consider:
- Whether the property connects elements across the listed Sources.
- Whether the property depends on or strengthens the Relations between Sources.
- Whether removing the property would weaken the blend’s internal coherence.

**Instructions:**  
Please respond only in JSON format with the following fields:

result: a space-separated list of 1's and 0's enclosed in parentheses. Each position corresponds exactly to the properties listed in the first sentence above (the {properties} list), not the ones in the context.
    - 1 = the property is justified in the blend according to the Relevance Principle.
    - 0 = the property is not justified.

reason: a brief explanation supporting the justification pattern in result.  
The explanation must explicitly reflect how the properties relate to the Sources and Relations.

**Formatting rules:**
1. The result must be exactly in the form: "(1 0 1 0 ...)" — No Python lists, commas, or other formats.
2. The number of entries in result must exactly match the number of properties in {properties}.
3. The justification in reason must align with the pattern in result.
4. Do not include any text outside the dict.
5. Output must be valid JSON with double quotes.

**Example**
{{
    "result": "(1 0 1 0 1 1 1 0)",
    "reason": "The first, third, fifth, sixth, and seventh properties establish cross-space links between the listed Sources and reinforce the mapped Relations."
}}
"""