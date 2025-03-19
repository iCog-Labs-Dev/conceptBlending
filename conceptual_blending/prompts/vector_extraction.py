VECTOR_EXTRACTION_PROMPT = """
    You are an expert in **conceptual analysis and knowledge representation**. Your task is to:
    
    1. **Extract exactly 8 key properties** of the given two concepts.
    2. **Assign a degree (0 to 1)** for each property based on its relevance to each concept.
    3. **Output structured property vectors** in the required format.

    ---
    
    ### **Given Concepts:**
    - **Concept 1:** "{concept1}"
    - **Concept 2:** "{concept2}"

    ### **Methodology for Property Extraction:**
    
    #### **Step 1: Identify 8 Shared or Relevant Properties**
    - Identify exactly **8 key features, behaviors, or characteristics** that describe both concepts.
    - Example: If **Concept 1** is "Bat" and **Concept 2** is "Man," potential properties include **flight, echolocation, nocturnality, intelligence, physical strength, reasoning, symbolism, and iconography**.

    #### **Step 2: Assign Degrees of Relevance**
    - Assign a **degree (0 to 1)** to each property based on its presence in the respective concept.
    - Example:  
      - A bat has high **flight ability (0.9)**, while a human has **none (0.0)**.
      - A human has **strong reasoning ability (0.9)**, whereas a bat has **limited reasoning (0.3)**.

    #### **Step 3: Structure the Output as Property Vectors**
    - Represent each concept in the structured format:
    ```
    (Concept Concept1@Concept2 (Property (Property1 Degree1) (Property2 Degree2) ... (Property8 Degree8)))
    (Concept Concept2@Concept1 (Property (Property1 Degree1) (Property2 Degree2) ... (Property8 Degree8)))
    ```
    - Ensure **each property is formatted as `(property-name degree)`**.

    ---
    
    ### **Example Output for "Bat" and "Man"**
    ```
    (Concept Bat@Man (Property (flight 0.9) (echolocation 0.9) (nocturnality 0.8) (intelligence 0.3) (physical-strength 0.2) (reasoning 0.3) (symbolism 0.8) (iconography 0.7)))
    (Concept Man@Bat (Property (flight 0.0) (echolocation 0.0) (nocturnality 0.2) (intelligence 0.9) (physical-strength 0.8) (reasoning 0.9) (symbolism 0.4) (iconography 0.3)))
    ```

    ---
    
    ### **Now, extract and return the property vectors:**
    - Identify **exactly 8 relevant properties** for both concepts.
    - Assign **degrees (0-1)** based on how strongly each concept possesses each property.
    - Return the **structured representation** in exactly the following format:
    ```
    (Concept Concept1@Concept2 (Property (Property1 Degree1) (Property2 Degree2) ... (Property8 Degree8)))
    (Concept Concept2@Concept1 (Property (Property1 Degree1) (Property2 Degree2) ... (Property8 Degree8)))
    ```
    - **Ensure exactly 8 properties are listed for each concept.**
    - **Return only two lines in this format. Avoid explanations.**
"""
