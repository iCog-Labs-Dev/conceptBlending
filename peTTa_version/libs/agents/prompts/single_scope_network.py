SINGLE_SCOPE_PROMPT = """
You are an expert in conceptual blending. Your task is to:
1. Analyze two given concepts and blend them within a single dominant conceptual frame using the Single-Scope Network.
2. Expand each concept through that dominant frame while preserving coherence.
3. Enrich the result by integrating deeper meaning.

### INPUTS:
- Concept Pair: {concept_pair} (format: concept1@concept2)
- Property Vector: {property_vector} (list of 8 properties with degrees)

### Instructions:
- Parse concept1 and concept2 from the concept1@concept2 input.
- Use the property vector to understand conceptual relevance.
- Give more weight to properties with degree > 0, but consider all 8 for completeness.
- Ensure both expansions share a common conceptual frame.

### Method:
- Step 1: Composition — Identify the shared frame or organizational principle.
- Step 2: Completion — Strengthen links between concept and frame.
- Step 3: Elaboration — Deepen meaning to relate to broader or abstract concepts.

### **blendedConcept** Formation Rule (Single-Scope Network)

When generating the `blendedConcept` in a Single-Scope Network, **one concept dominates the frame** and the other is integrated as a secondary modifier. This works best when the dominant frame guides the meaning and produces a **clear, interpretable compound**, for example:  

- **birdhouse** — house dominates; bird modifies it.  
- **teacup** — cup dominates; tea modifies it.  
- **snowshoes** — shoes dominate; snow modifies them.  

If a dominant-frame combination does **not** yield a clear concept, apply **deeper frame/role integration**, creating a hybrid that merges functional, structural, or role-based features. For example:  
- **doctor + robot → “medical assistant robot”** — robot integrated into doctor’s role.  
- **library + cloud → “cloud-based digital library”** — library functions integrated into a cloud environment.  
- **horse + bird → “Pegasus”** — merges structural and role features into a mythic hybrid (equine body + avian wings).  

**Summary:** Prefer **dominant-frame compounds** when one concept clearly guides the blend; otherwise, generate a **structurally integrated hybrid** that preserves meaning and role relations.

### Output Format:
Return only:
(SingleScope (expand concept1 concept2) blendedconcept (extended Elaboration1))

### Examples:
(SingleScope (expand war Strategy) tacticaloperations (extended strategicWarfare))
(SingleScope (expand video Games) tacticalsimulation (extended interactiveWargaming))

### Output Rules:
- DO NOT use quotes, backticks, or additional text.
- Return only one valid MeTTa expression in the specified format.
"""
