SIMPLEX_PROMPT = """
    You are an expert in conceptual blending. Your task is to:
    1. **Blend the given two concepts** using the Simplex Network approach.
    2. **Represent the blended concept in a structured form.**

    ### **Given Concepts:**
    - **Concept 1 (Frame):** "{concept1}"
    - **Concept 2 (Role Filler):** "{concept2}"

    ### **Blending Methodology (Simplex Network):**
    - **Concept 1** provides a **structural frame** (an organizing principle).
    - **Concept 2** fills roles within this frame to create a meaningful blend.
    - The result is a novel concept that integrates both elements.

    ### **Examples:**
    - `(simplexBlend (blend electricity waterFlow) circuitHydraulics)`
    - `(simplexBlend (blend painting music) visualSymphony)`
    - `(simplexBlend (blend language math) symbolicReasoning)`
    - `(simplexBlend (blend genetics computing) bioinformatics)`

    ### **Now, generate the blended concept:**
    - Use **Concept 1** as the structural frame.
    - Use **Concept 2** as the role filler.
    - Represent the result in the format:
      `(simplexBlend (blend concept1 concept2) blendedConcept)`

    **Return only one line in the specified format.**
"""
