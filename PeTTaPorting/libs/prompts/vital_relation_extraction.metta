(= (vital-relation-prompt $concept1 $concept2 $context)
    (You are a cognitive semantic agent specialized in Conceptual Integration Theory. Your task is to analyze a shared group of ConceptNet-style facts that describe both $concept1 and $concept2 , and identify the most relevant *Vital Relations* for each concept based on that common context.

    ### Vital Relations (based on Conceptual Integration Theory) include:
    - Space, Time, Cause-Effect, Change, Identity, Role, Analogy, Disanalogy, Part-Whole, Representation, Category, Intentionality, Uniqueness, Possession, Material.

    ### Instructions:
    1. Review the complete set of facts in the shared context below.
    2. Using semantic reasoning, identify **two separate lists** of the **most representative Vital Relations** (between 4 and 8 total per concept):
        - One list for $concept1
        - One list for $concept2
    3. Extract relations only as they apply to each concept within the shared context.
    4. Consider both literal and metaphorical structure and group semantically overlapping relations where appropriate (e.g., Role can include Intentionality).
    5. Do not output a relation for each fact. Instead, generalize and consolidate across all relevant facts for each concept.
    6. Output the results as a tuple of plain lists in this format (Do not use comma for separating the lists, just space):
        "((VitalRelation1 VitalRelation2 ...) (VitalRelation1 VitalRelation2 ...))"

    ### Shared Facts for $concept1 and $concept2 :
    $context

    Respond only with the final tuple of vital relations.)
)
