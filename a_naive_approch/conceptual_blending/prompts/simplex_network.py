SIMPLEX_PROMPT = """
    You are an expert in conceptual blending. Your task is to:
    1. **Blend the given two concepts** using the Simplex Network approach.
    2. **Identify the core relation between them.**
    3. **Generate a concise, single-term elaboration.**

    ### **Given Concepts:**
    - **Concept 1 (Frame):** "{concept1}"
    - **Concept 2 (Role Filler):** "{concept2}"

    ### **Blending Methodology (Simplex Network):**
    - **Step 1: Composition (Vital Relation Selection)**
      - Identify the **essential relation** linking Concept 1 and Concept 2.
      - Example: If "Electricity" is the frame and "Water Flow" is the filler, the vital relation is **"fluid energy transmission"**.

    - **Step 2: Completion (Implicit Knowledge)**
      - Integrate additional **background knowledge** that enhances the blend.
      - Example: If "Painting" is the frame and "Music" is the filler, the blend **inherits ideas of rhythm, color, and composition**.

    - **Step 3: Elaboration (Single-Word Concept)**
      - Extend the meaning into **a concise, single-term abstraction**.
      - Example: Instead of **“harmony and contrast in music parallel visual composition”**, return **"rhythmicColorTheory"**.

    ### **Examples:**
    - `(simplexBlend (blend electricity waterFlow) circuitHydraulics (extended energyFlowMechanics))`
    - `(simplexBlend (blend painting music) visualSymphony (extended rhythmicColorTheory))`
    - `(simplexBlend (blend language math) symbolicReasoning (extended linguisticAbstraction))`
    - `(simplexBlend (blend genetics computing) bioinformatics (extended computationalEvolution))`

    ### **Now, generate the blended concept:**
    - Identify the **vital relation** between Concept 1 and Concept 2.
    - Add **completion details** that enhance the blend.
    - Extend the concept using **a concise, single-term elaboration** (avoid long phrases).
    - Represent the result in the format:
      `(simplexBlend (blend concept1 concept2) blendedConcept (extended elaboratedConcept))`

    **Return only one line in the specified format. Avoid long phrases or explanations.**
"""
