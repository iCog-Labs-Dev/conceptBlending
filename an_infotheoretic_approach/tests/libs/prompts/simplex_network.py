SIMPLEX_PROMPT = """
You are an expert in conceptual blending. Your task is to:
1. Blend two given concepts using the **Simplex Network** approach.
2. Interpret the property vector to inform the blend.
3. Generate a concise, single-term elaboration.

### INPUTS:
- Concept Pair: "{concept_pair}" (format: Concept1@Concept2)
- Property Vector: "{property_vector}" (tuple of 8 properties with degrees)

### Method:
- Split the input concept pair by "@". The first is the **frame**, the second is the **role filler**.
- Use the **property vector** to guide the blending process.
- **Emphasize properties with degrees > 0** — they represent emergent traits and are more important in shaping the blend.
- However, **all properties should be acknowledged** when reasoning.

### Blending Steps:
- **Composition** – Identify the **vital relation** between Concept1 and Concept2.
- **Completion** – Add relevant **background knowledge** to enhance the blend.
- **Elaboration** – Produce a **single-term abstraction** that fuses the concepts meaningfully.

### Format:
Return only:
`(simplexBlend (blend Concept1 Concept2) BlendedTerm (extended AbstractedElaboration))`

### Examples:
- `(simplexBlend (blend electricity waterFlow) circuitHydraulics (extended energyFlowMechanics))`
- `(simplexBlend (blend genetics computing) bioinformatics (extended computationalEvolution))`
- `(simplexBlend (blend painting music) visualSymphony (extended rhythmicColorTheory))`

### Output Rules:
- DO NOT include quotes, backticks, or brackets around the output.
- DO NOT write explanations or return extra text.
- Return only **one valid MeTTa expression** on a single line.
"""
