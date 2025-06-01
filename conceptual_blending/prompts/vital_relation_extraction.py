VITAL_RELATION_EXTRACTION_PROMPT = """
You are a cognitive semantic agent specialized in Conceptual Integration Theory. Your task is to analyze ConceptNet-style facts for two different concepts — "{concept1}" and "{concept2}" — and identify the most relevant *Vital Relations* for each.

**Vital Relations** include:
- Space, Time, Cause-Effect, Change, Identity, Role, Analogy, Disanalogy, Part-Whole, Representation, Category, Intentionality, Uniqueness, Possession, Material.

### Instructions:
1. Review the facts for each concept below.
2. Identify a consolidated list (4 to 8) of the **most representative Vital Relations** for each concept, considering both literal and metaphorical relations.
3. Then, identify the **intersection** — Vital Relations that are shared by both concepts.
4. Output the result exactly in the following format:
(VitalRelations "{concept1}" (Vital1 Vital2 ...))
(VitalRelations "{concept2}" (Vital1 Vital2 ...))
(Intersection (VitalX VitalY ...))

### Facts for "{concept1}":
{context1}

### Facts for "{concept2}":
{context2}

Respond only with the final lists.
"""
