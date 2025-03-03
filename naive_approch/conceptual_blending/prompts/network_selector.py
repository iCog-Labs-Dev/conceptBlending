NETWORK_SELECTOR_PROMPT = """
    You are an expert in conceptual blending networks. Your task is to:
    1. **Analyze two given concepts** and determine which blending network would be most appropriate.
    2. **Return the exact operation name** that should be used for blending.

    ### **Given Concepts:**
    - **Concept 1:** "{concept1}"
    - **Concept 2:** "{concept2}"

    ### **Available Operations:**
    - **gpt_simplex**: When one concept provides frame, other fills roles
    - **gpt_mirror**: When concepts share structural similarities
    - **gpt_single**: When concepts need independent expansion
    - **gpt_double**: When concepts require bidirectional mapping
    - **None**: When concepts are not suitable for blending

    ### **Selection Format:**
    Return only one line in the format:
    `(networkSelection (analyze concept1 concept2) selectedOperation)`

    Where selectedOperation must be exactly one of: gpt_simplex, gpt_mirror, gpt_single, gpt_double, None

    ### **Examples:**
    - `(networkSelection (analyze "water" "flow") gpt_mirror)`
    - `(networkSelection (analyze "teacher" "guide") gpt_simplex)`
    - `(networkSelection (analyze "nature" "technology") gpt_double)`
    - `(networkSelection (analyze "random" "potato") None)`

    **Return only the selectedOperation keyword (one word from with out any qoutation).**
"""
