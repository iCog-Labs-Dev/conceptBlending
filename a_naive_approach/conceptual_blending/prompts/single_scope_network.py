SINGLE_SCOPE_PROMPT = """
    You are an expert in conceptual blending. Your task is to:
    1. **Analyze the given concepts** and determine how they integrate within a **single dominant conceptual frame**.
    2. **Expand both concepts** within this unified frame, ensuring conceptual coherence.
    3. **Enhance the blend** by adding deeper insights.

    ### **Given Concepts:**
    - **Concept 1:** "{concept1}"
    - **Concept 2:** "{concept2}"

    ### **Blending Methodology (Single-Scope Network):**
    - **Composition:** Identify a **dominant frame** that governs both concepts.
    - **Completion:** Integrate any **missing links** to reinforce their connection.
    - **Elaboration:** Extend the blend by **enriching the meaning**.

    #### **Step 1: Composition (Identifying the Dominant Frame)**
    - Find a **single unifying structure** that both concepts fit into.
    - Ensure **no conflicting mental spaces exist**.
    - Assign a **shared category or organizational principle**.

    #### **Step 2: Completion (Enhancing the Conceptual Relationship)**
    - Ensure the blend is **logically structured** and **coherent**.
    - Integrate **additional missing attributes** that strengthen the link.

    #### **Step 3: Elaboration (Deepening the Meaning)**
    - Extend the meaning by **relating the blend to broader concepts**.
    - Highlight how this blend **evolves conceptually or has real-world significance**.

    ### **Examples:**
    - `(singleScope (expand warStrategy) tacticalOperations (extended strategicWarfare))`
    - `(singleScope (expand videoGames) tacticalSimulation (extended interactiveWargaming))`
    - `(singleScope (expand theaterManagement) authoritarianLeadership (extended politicalStaging))`
    - `(singleScope (expand financialMarkets) economicEcosystem (extended globalTradeDynamics))`

    ### **Now, generate the single-scope blend:**
    - **Step 1:** Identify the **dominant frame** that applies to both.
    - **Step 2:** Integrate any **missing attributes** that improve the coherence.
    - **Step 3:** Elaborate on the blend by expanding its conceptual depth.
    - Represent the result in the format:
      `(singleScope (expand concept1) dominantFrame1 (extended elaboratedConcept1))`
      `(singleScope (expand concept2) dominantFrame2 (extended elaboratedConcept2))`

    **Return only two lines in the specified format.**
"""
