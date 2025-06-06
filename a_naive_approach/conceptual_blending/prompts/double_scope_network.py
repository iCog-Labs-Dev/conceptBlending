DOUBLE_SCOPE_PROMPT = """
    You are an expert in conceptual blending. Your task is to:
    1. **Expand two given concepts independently within their own cognitive scopes.**
    2. **Resolve conflicts between them to form a blended concept.**
    3. **Elaborate on the blend by integrating deeper insights.**

    ### **Given Concepts:**
    - **Concept 1:** "{concept1}"
    - **Concept 2:** "{concept2}"

    ### **Blending Methodology (Double Scope Network):**
    - **Composition:** Expand each concept within its own **independent** cognitive space.
    - **Completion:** Resolve conceptual conflicts between the two spaces.
    - **Elaboration:** Strengthen the blended concept by adding new conceptual insights.

    #### **Step 1: Composition (Independent Expansion)**
    - Expand **Concept 1** based on its **own internal logic**.
    - Expand **Concept 2** separately using its **unique properties**.
    - Ensure each concept **retains its distinct cognitive identity**.

    #### **Step 2: Completion (Resolving Conflicts)**
    - Identify **overlapping properties** between the two concepts.
    - Address **contradictions** by adjusting and refining their relationships.
    - Integrate a **cohesive mapping** between the two spaces.

    #### **Step 3: Elaboration (Deepening the Meaning)**
    - Extend the blended concept by introducing **a higher-level abstraction**.
    - Consider how this **new blend applies in real-world or theoretical contexts**.

    ### **Examples:**
    - `(doubleScope (expand gravity relativity) spacetimeFabric (extended unifiedPhysics))`
    - `(doubleScope (expand sound vibration) harmonicResonance (extended musicalPhysics))`
    - `(doubleScope (expand memory computation) neuralProcessing (extended cognitiveCybernetics))`
    - `(doubleScope (expand evolution adaptation) biologicalInnovation (extended geneticEngineering))`

    ### **Now, generate the double-scope blend:**
    - **Step 1:** Expand both concepts **independently**.
    - **Step 2:** Resolve contradictions and find **common links**.
    - **Step 3:** Enrich the final blended concept by **extending its depth**.
    - Represent the result in the format:
      `(doubleScope (expand concept1 concept2) blendedConcept (extended elaboratedConcept))`

    **Return only one line in the specified format.**
"""
