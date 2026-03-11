MIRROR_PROMPT = """
You are an expert in conceptual blending. Your task is to:
1. Analyze the structural similarities between two concepts using the Mirror Network.
2. Use their shared and differing traits to complete a meaningful mirrored mapping.
3. Generate a structured, elaborated representation of the mirrored concept.

### INPUTS:
- Concept Pair: {concept_pair} (format: concept1@concept2)
- Property Vector: {property_vector} (8 properties with relevance degrees)

### Instructions:
- Split the concept pair using '@' into concept1 and concept2.
- Use the property vector to identify meaningful structural parallels.
- Emphasize properties with a degree > 0 — they hold emergent, relevant insights.
- All properties should be referenced, but those above 0 contribute more to the blend.

### Method:
- Composition: Map structural or behavioral parallels between concept1 and concept2.
- Completion: Fill in missing or implicit structural roles.
- Elaboration: Extend the mirrored mapping into a more abstract or insightful idea.

### **blendedConcept** Formation Rule (Mirror Network)

When generating the `blendedConcept`, first consider a **mirror-style combination** where both concepts contribute symmetrically, highlighting **shared structure or reversed roles**. This works best when it produces a **balanced, interpretable hybrid**, for example:  
- **houseboat ↔ boathouse** — both elements are reflected; the focus can shift naturally between house-on-boat or boat-on-house interpretations.  
- **catdog ↔ dogcat** — a symmetric animal blend emphasizing traits of both species equally.  
- **sunmoon ↔ moonsun** — combines celestial concepts in a mirrored way, capturing properties of both.  

If a mirror-style combination does **not** yield a clear or meaningful concept, apply **deeper frame/role integration**, creating a hybrid that merges functional, structural, or role-based features. For example:  
- **doctor + robot → “medical assistant robot”** — integrates the robot into the role of a doctor.  
- **library + cloud → “cloud-based digital library”** — merges functional frames: library access/storage in the cloud.  
- **horse + bird → “Pegasus”** — combines structural and role features into a mythic hybrid (equine body + avian wings).  

**Summary:** Prefer **symmetrically interpretable blends** when using Mirror Networks; otherwise, generate a **structurally integrated blend** that preserves meaning and frame relations.

### Output Format:
Return only:
(Mirror (expand concept1 concept2) blendedconcept (extended deeperInterpretation))

### Examples:
(Mirror (expand immuneSystem cybersecurity) adaptivedefense (extended threatDetection))
(Mirror (expand neuralNetwork socialNetwork) connectivitydynamics (extended informationExchange))
(Mirror (expand river trafficFlow) fluidmovement (extended continuousNavigation))

### Output Rules:
- DO NOT include quotes, backticks, or explanations.
- Return only one valid MeTTa expression.
"""
