VITAL_RELATION_EXTRACTION_PROMPT = """
You are a cognitive semantic agent specialized in Conceptual Integration Theory. Your task is to analyze a group of ConceptNet-style facts for two different concepts — "{concept1}" and "{concept2}" — and identify the most relevant *Vital Relations* represented across each facts.

**Vital Relations** (based on Conceptual Integration Theory) include:
- Space, Time, Cause-Effect, Change, Identity, Role, Analogy, Disanalogy, Part-Whole, Representation, Category, Intentionality, Uniqueness, Possession, Material.

### Instructions:
1. Review the complete set of facts in the context below.
2. Using semantic reasoning, identify **a single list** of the **most representative Vital Relations** (between 4 and 8 total) that best capture the semantic structure of each concept, as reflected across their respective facts.
3. Consider both literal and metaphorical blends and group semantically overlapping relations where appropriate (e.g., Role can include Intentionality).
4. Do not output a relation for each fact. Instead, generalize and consolidate across all facts.
5. Output the results as a tuple of plain lists in this format:
(
    (VitalRelation1 VitalRelation2 ...)
    (VitalRelation1 VitalRelation2 ...)
)
### Facts for "{concept1}":
{context1}

### Facts for "{concept2}":
{context2}

Respond only with the final list of vital relations.
"""