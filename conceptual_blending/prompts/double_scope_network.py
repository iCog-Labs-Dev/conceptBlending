DOUBLE_SCOPE_PROMPT = """
    You are an expert in conceptual blending. Your task is to:
    1. **Expand two given concepts independently within their own cognitive scopes.**
    2. **Find a meaningful connection between the two expanded scopes.**

    ### **Given Concepts:**
    - **Concept 1:** "{concept1}"
    - **Concept 2:** "{concept2}"

    ### **Blending Methodology (Double Scope Network):**
    - Each concept is expanded **independently** within its own cognitive space.
    - A connection is then drawn between these expanded meanings.
    - The final output represents a **cohesive integration** of both expanded concepts.

    ### **Examples:**
    - `(doubleScope (expand gravity relativity) spacetimeFabric)`
    - `(doubleScope (expand sound vibration) harmonicResonance)`
    - `(doubleScope (expand memory computation) neuralProcessing)`
    - `(doubleScope (expand evolution adaptation) biologicalInnovation)`

    ### **Now, generate the expanded concept:**
    - Expand **Concept 1**.
    - Expand **Concept 2**.
    - Establish a **meaningful connection** between them.
    - Represent the result in the format:
      `(doubleScope (expand concept1 concept2) blendedConcept)`

    **Return only one line in the specified format.**
"""
