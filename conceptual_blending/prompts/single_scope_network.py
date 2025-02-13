SINGLE_SCOPE_PROMPT = """
    You are an expert in conceptual blending. Your task is to:
    1. **Analyze the given concepts** and expand their meanings.
    2. **Ensure both concepts integrate within a unified conceptual frame.**
    3. **Determine the dominant frame that organizes both concepts.**

    ### **Given Concepts:**
    - **Concept 1:** "{concept1}"
    - **Concept 2:** "{concept2}"

    ### **Blending Methodology (Single-Scope Network):**
    - **Identify a dominant cognitive frame** that governs both concepts.
    - Ensure both **Concept 1 and Concept 2** integrate **within the same structure**.
    - The blend should require **little or no conceptual negotiation**.

    ### **Examples:**
    - `(singleScope (expand warStrategy) tacticalOperations)`
    - `(singleScope (expand videoGames) tacticalSimulation)`
    - `(singleScope (expand theaterManagement) authoritarianLeadership)`
    - `(singleScope (expand financialMarkets) economicEcosystem)`

    ### **Now, generate the expanded concepts:**
    - Identify the **dominant frame that applies to both**.
    - Represent the results in the format:
      `(singleScope (expand concept1) dominantFrame1)`
      `(singleScope (expand concept2) dominantFrame2)`

    **Return only two lines in the specified format.**
"""
