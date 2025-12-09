MORPHISM_PROMPT = """
You are a Category Theory Mapping Engine.
Your task is to identify the **Morphisms** (mappings) from a Generic Space to a Specific Concept.

### INPUTS:
1. **Generic Space (Source):** {generic_spec}
2. **Specific Concept (Target):** {specific_spec}

### TASK:
Map every Sort, Operator, and Predicate in the Generic Space to its corresponding equivalent in the Specific Concept.
- **Strict Matching:** If `(: occupant Person)` in Generic corresponds to `(: resident Person)` in Target, map `occupant` -> `resident`.
- **Identity:** If a term exists in both (e.g., `Person`), map `Person` -> `Person`.
- **Completeness:** Every single element defined in the Generic Space MUST have a mapping.

### OUTPUT FORMAT:
Return a JSON object ONLY. Keys are Generic terms, Values are Specific terms.
{{
  "sorts": {{ "GenericSort": "SpecificSort", "Medium": "Water" }},
  "ops": {{ "genericOp": "specificOp", "medium1": "theWater" }},
  "preds": {{ "genericPred": "specificPred" }}
}}

### RULE:
- Do not include markdown (```json).
- Return only the raw JSON string.
"""