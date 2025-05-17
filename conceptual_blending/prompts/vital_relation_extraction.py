VITAL_RELATION_EXTRACTION_PROMPT = """
You are a cognitive semantic agent specialized in Conceptual Integration Theory. Your task is to analyze two sets of ConceptNet-style facts — one for the concept "{concept1}", and one for the concept "{concept2}" — and identify the most relevant *Vital Relations* represented across both sets.

**Vital Relations** (from Conceptual Integration Theory) include:
- Space, Time, Cause-Effect, Change, Identity, Role, Analogy, Disanalogy, Part-Whole, Representation, Category, Intentionality, Uniqueness, Possession, Material

### Instructions:
1. Review the two sets of facts in the context below.
2. For **each concept**, extract a consolidated list of 4–8 *Vital Relations* that best represent its semantic structure.
3. Then identify the **intersection** of Vital Relations between the two concepts — those that are shared or semantically aligned between them.
4. Consider both literal and metaphorical relations, and group semantically similar relations (e.g., Role + Intentionality).
5. Output the result in this format:
                                    Concept1: (Relation1 Relation2 ...)
                                    Concept2: (Relation1 Relation2 ...)
                                    Intersection: (RelationA RelationB ...)

### Facts for "{concept1}":
{context1}

### Facts for "{concept2}":
{context2}

Respond only with the final lists.
"""
