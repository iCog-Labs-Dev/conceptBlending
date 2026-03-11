DOUBLE_SCOPE_PROMPT = """
You are an expert in conceptual blending. Your task is to:
1. Expand the given two concepts independently within their own cognitive scopes.
2. Resolve conflicts and differences between them.
3. Elaborate the final blend by adding deeper emergent insight.

### INPUTS:
- Concept Pair: {concept_pair} (format: concept1@concept2)
- Property Vector: {property_vector} (8 properties with degrees)

### Instructions:
- Parse concept1 and concept2 from the concept pair string.
- Use the property vector to understand feature relevance.
- Focus especially on properties with degree > 0 — they carry emergent weight.
- Blend the concepts through independent expansion, conflict resolution, and abstraction.

### Method:
- Composition: Expand each concept within its own internal logic.
- Completion: Map structural and functional connections, resolving contradictions.
- Elaboration: Derive a new, meaningful concept from their integration.

### **blendedconcept** Formation Rule

When generating the `blendedConcept`, first try a **simple lexical concatenation** of the two input concepts, choosing the **most semantically natural order** (modifier → head). This works best when it produces a **clear, conventional, and cognitively easy-to-understand compound**, for example:  
    - **batman** over *manbat* — emphasizes the dominant frame (bat) while following familiar naming patterns.  
    - **bedroom** over *roombed* — conveys function immediately and reads naturally.  
    - **houseboat** over *boathouse* — preserves the expected meaning of a boat designed as a house.  

If no straightforward combination yields a clear concept, apply **deeper frame/role integration**, creating a coherent hybrid that combines functional or structural roles. For example:
    - **doctor + robot → “medical assistant robot”** — integrates the robot into the role of a doctor rather than a literal concatenation.  
    - **library + cloud → “cloud-based digital library”** — combines functional frames: library storage/access in a cloud environment.  
    - **horse + bird → “Pegasus”** — merges structural and role features into a mythic hybrid (equine body + avian wings).  

**Summary:** Prefer **natural, interpretable compounds** when possible; otherwise, generate a **structurally integrated blend** that preserves meaning and frame relations.

### Output Format:
Return only one line like this:
(doubleScope (expand Concept1 Concept2) blendedconcept (extended ElaboratedConcept))

### Example:
(doubleScope (expand emotion mathematics) emotionalquantification (extended affectiveComputationalFramework))

### Output Rules:
- DO NOT use quotes, backticks, or extra explanation.
- Return only a single valid MeTTa expression in the format specified.

"""
