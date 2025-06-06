MIRROR_PROMPT = """
    You are an expert in conceptual blending. Your task is to:
    1. **Analyze the given two concepts** and determine how they mirror each other structurally.
    2. **Identify missing knowledge that completes the mirroring relationship.**
    3. **Generate a structured representation** of their shared patterns, including an elaborated interpretation.

    ### **Given Concepts:**
    - **Concept 1:** "{concept1}"
    - **Concept 2:** "{concept2}"

    ### **Blending Methodology (Mirror Network)**
    - The two concepts share **structural similarities** and **map onto each other**.
    - Follow the three steps of conceptual blending: **Composition, Completion, and Elaboration**.

    #### **Step 1: Composition (Identifying the Structural Parallel)**
    - Analyze how **Concept 1** and **Concept 2** structurally resemble each other.
    - Identify **key features, roles, or behaviors** that map onto one another.
    - Construct a **preliminary mirrored representation** of their common structure.

    #### **Step 2: Completion (Filling in Missing Information)**
    - Identify any **gaps in the mirroring relationship**.
    - Add missing **roles, functions, or inferred similarities** that strengthen the mapping.
    - Ensure the final blend captures a **well-aligned mirrored relationship**.

    #### **Step 3: Elaboration (Expanding the Interpretation)**
    - Go beyond simple mirroring—**extend the interpretation**.
    - Provide a **deeper insight** into how this mirroring relationship impacts broader understanding.
    - Formulate a **meaningful extension** that enhances the concept's relevance.

    ### **Examples:**
    - `(mirroredConcept (mirror river trafficFlow) fluidMovement (extended continuousNavigation))`
    - `(mirroredConcept (mirror neuralNetwork socialNetwork) connectivityDynamics (extended informationExchange))`
    - `(mirroredConcept (mirror tree organizationalHierarchy) branchingStructure (extended hierarchicalControl))`
    - `(mirroredConcept (mirror immuneSystem cybersecurity) adaptiveDefense (extended threatDetection))`

    ### **Now, generate the mirrored concept:**
    - **Step 1:** Find the **common structure** that unites Concept 1 and Concept 2.
    - **Step 2:** Identify **missing or implicit knowledge** that completes their relationship.
    - **Step 3:** Provide an **elaborated insight** into the deeper meaning of their mirroring.
    - Represent the result in the format:
      `(mirroredConcept (mirror concept1 concept2) mirroredConcept (extended elaboratedConcept))`

    **Return only one line in the specified format.**
"""
