MIRROR_PROMPT = """
    You are an expert in conceptual blending. Your task is to:
    1. **Analyze the given two concepts** and determine how they mirror each other.
    2. **Ensure the concepts share the same structural organization but differ in function, domain, or scale.**
    3. **Generate a structured representation** of their shared patterns.

    ### **Given Concepts:**
    - **Concept 1:** "{concept1}"
    - **Concept 2:** "{concept2}"

    ### **Blending Methodology (Mirror Network):**
    - The two concepts must have **structural similarity** and **map onto each other in all key respects**.
    - Identify **common patterns**, **correspondences**, and **shared dynamics**.
    - Ensure they **mirror each other across time, function, or representation**.

    ### **Examples:**
    - `(mirroredConcept (mirror river trafficFlow) fluidMovement)`
    - `(mirroredConcept (mirror neuralNetwork socialNetwork) connectivityDynamics)`
    - `(mirroredConcept (mirror tree organizationalHierarchy) branchingStructure)`
    - `(mirroredConcept (mirror immuneSystem cybersecurity) adaptiveDefense)`

    ### **Now, generate the mirrored concept:**
    - Identify the **common organizing frame**.
    - Check whether **one concept mirrors the other in a different domain or function**.
    - Represent the result as:
      `(mirroredConcept (mirror concept1 concept2) mirroredConcept)`

    **Return only one line in the specified format.**
"""
