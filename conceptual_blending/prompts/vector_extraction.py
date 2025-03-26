VECTOR_EXTRACTION_PROMPT = """
You are an expert in **conceptual analysis and knowledge representation**. Your task is to:

1. **Extract exactly 8 key properties** of the given two concepts.
2. **Assign a degree (0 to 1)** for each property based on its relevance to each concept.
3. **Return both property vectors wrapped inside a single (InputSpaces ...) expression.**

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

#### **Step 3: Structure the Output in the Following Format**
- Wrap both property vectors inside an outer `(InputSpaces ...)` container.
- Return exactly two concept representations in this structure:
  (InputSpaces 
    (Concept Concept1@Concept2 (Property (Property1 Degree1) (Property2 Degree2) ... (Property8 Degree8)))
    (Concept Concept2@Concept1 (Property (Property1 Degree1) (Property2 Degree2) ... (Property8 Degree8)))
  )

---

### **Important Output Instructions:**
- **Return only one line starting with (InputSpaces ...)** with no extra formatting.
- Do **not** return explanations or backticks (```).
- **Ensure exactly 8 properties** are listed for each concept.
- Maintain MeTTa-style syntax and spacing.
"""
