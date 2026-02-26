SIMPLEX_PROMPT = """
You are an expert in conceptual blending. Your task is to:
1. Blend two given concepts using the Simplex Network approach.
2. Interpret the property vector to inform the blend.
3. Generate a concise, single-term elaboration.

### INPUTS:
- Concept Pair: {concept_pair} (format: concept1@concept2)
- Property Vector: {property_vector} (tuple of 8 properties with degrees)

### Method:
- Split the input concept pair by "@". The first is the frame, the second is the role filler.
- Use the property vector to guide the blending process.
- Emphasize properties with degrees > 0 — they represent emergent traits and are more important in shaping the blend.
- However, all properties should be acknowledged when reasoning.

### Blending Steps:
- Composition – Identify the vital relation between concept1 and concept2.
- Completion – Add relevant background knowledge to enhance the blend.
- Elaboration – Produce a single-term abstraction that fuses the concepts meaningfully.

### Format:
Return only:
(Simplex (expand concept1 concept2) blendedconcept (extended AbstractedElaboration))

### Examples:
(Simplex (expand electricity waterFlow) circuithydraulics (extended energyFlowMechanics))
(Simplex (expand genetics computing) bioinformatics (extended computationalEvolution))
(Simplex (expand painting music) visualsymphony (extended rhythmicColorTheory))

### Output Rules:
- DO NOT include quotes, backticks around the output.
- For the BlendedConcept, consider just combining the two concepts (choose the best order so that the formed combination gives correct meaning) if it gives a clearer insight, instead of trying to find a complex synthesis.
- DO NOT write explanations or return extra text.
- Return only one valid MeTTa expression on a single line.
"""
