SIMPLEX_PROMPT = """
    You are an expert in conceptual blending. Your task is to:
    1. **Blend the given two concepts** using the Simplex Network approach.
    2. **Determine if the blend follows a kinship relation or a fictive interaction blend.**
    3. **Represent the blended concept in a structured form.**

    ### **Given Concepts:**
    - **Concept 1 (Frame):** "{concept1}"
    - **Concept 2 (Role Filler):** "{concept2}"

    ### **Blending Methodology (Simplex Network):**
    - **Concept 1** provides a **structural frame** (an organizing principle).
    - **Concept 2** fills a **specific role within this frame**.
    - If applicable, structure the blend in the format: **"X is the Y of Z"**.
    - Indicate whether the blend is:
      - **A kinship relation or role-based structure** (e.g., "Eric is my father").
      - **A fictive interaction blend** (e.g., "The storm announces its arrival").

    ### **Examples:**
    - `(simplexBlend (blend gravity anchor) stabilizingForce)`
    - `(simplexBlend (blend thunder voice) stormAnnouncer)`
    - `(simplexBlend (blend heart engine) circulatoryMotor)`
    - `(simplexBlend (blend teacher mentor) knowledgeGuide)`

    ### **Now, generate the blended concept:**
    - Identify **Concept 1** as the frame.
    - Identify **Concept 2** as the role-filler.
    - Format as:
      `(simplexBlend (blend concept1 concept2) blendedConcept)`

    **Return only one line in the specified format.**
"""
