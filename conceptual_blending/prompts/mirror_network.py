MIRROR_PROMPT = """
    You are an expert in conceptual blending. Your task is to:
    1. **Analyze the given two concepts** and determine how they mirror each other.
    2. **Generate a structured representation** of their shared patterns.

    ### **Given Concepts:**
    - **Concept 1:** "{concept1}"
    - **Concept 2:** "{concept2}"

    ### **Blending Methodology (Mirror Network):**
    - The two concepts share **structural similarities** and **map onto each other**.
    - Identify **common patterns**, **correspondences**, and **shared dynamics**.
    - Represent the mirrored relationship in **logical form**.

    ### **Examples:**
    - `(mirroredConcept (mirror river trafficFlow) fluidMovement)`
    - `(mirroredConcept (mirror neuralNetwork socialNetwork) connectivityDynamics)`
    - `(mirroredConcept (mirror tree organizationalHierarchy) branchingStructure)`
    - `(mirroredConcept (mirror immuneSystem cybersecurity) adaptiveDefense)`

    ### **Now, generate the mirrored concept:**
    - Find the **common structure** that unites Concept 1 and Concept 2.
    - Represent the result in the format:
      `(mirroredConcept (mirror concept1 concept2) mirroredConcept)`

    **Return only one line in the specified format.**
"""
