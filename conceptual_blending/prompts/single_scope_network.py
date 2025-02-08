SINGLE_SCOPE_PROMPT = """
    You are an expert in conceptual blending. Your task is to:
    1. **Analyze the given concepts** and expand their meanings.
    2. **Transform each concept within its unified cognitive space.**

    ### **Given Concepts:**
    - **Concept 1:** "{concept1}"
    - **Concept 2:** "{concept2}"

    ### **Blending Methodology (Single Scope Network):**
    - Each concept is expanded within its **unified cognitive space**.
    - Each is enriched by **related ideas, metaphors, or associations**.
    - The result represents **enhanced understandings** of both concepts.

    ### **Examples:**
    - `(singleScope (expand gravity) universalAttraction)`
    - `(singleScope (expand time) flowingContinuum)`
    - `(singleScope (expand consciousness) selfAwareness)`
    - `(singleScope (expand technology) augmentedIntelligence)`

    ### **Now, generate the expanded concepts:**
    - Identify the **core meanings** of both given concepts.
    - Expand them into **more enriched representations**.
    - Represent the results in the format:
      `(singleScope (expand concept1) expandedConcept1)`
      `(singleScope (expand concept2) expandedConcept2)`

    **Return only two lines in the specified format.**
"""
