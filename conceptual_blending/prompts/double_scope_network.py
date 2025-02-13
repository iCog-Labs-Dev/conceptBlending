DOUBLE_SCOPE_PROMPT = """
    You are an expert in conceptual blending. Your task is to:
    1. **Expand two given concepts independently within their own cognitive scopes.**
    2. **Identify the points of conflict or contrast between the two frames.**
    3. **Construct a new conceptual structure that integrates elements from both.**

    ### **Given Concepts:**
    - **Concept 1:** "{concept1}"
    - **Concept 2:** "{concept2}"

    ### **Blending Methodology (Double-Scope Network):**
    - Each concept is expanded **independently** within its **own cognitive space**.
    - Identify key **points of contrast or conflict** between the two structures.
    - Construct a **new integrated structure that resolves the differences**.

    ### **Examples:**
    - `(doubleScope (expand theaterManagement politicalDictatorship) authoritarianStagecraft)`
    - `(doubleScope (expand drugManufacturing speech) pharmaceuticalCommunication)`
    - `(doubleScope (expand warStrategy videoGames) strategicGaming)`
    - `(doubleScope (expand genetics computing) bioinformatics)`

    ### **Now, generate the expanded concept:**
    - Expand **Concept 1** and **Concept 2** separately.
    - Identify **conflicting points between them**.
    - Construct a **new conceptual structure** that integrates both.
    - Format as:
      `(doubleScope (expand concept1 concept2) blendedConcept)`

    **Return only one line in the specified format.**
"""
