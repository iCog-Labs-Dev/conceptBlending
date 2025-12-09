import re

def parse_spec_elements(spec_str):
    """
    Parses a Spec string into lists of sorts, ops, preds, axioms.
    """
    def extract_block(name):
        # Regex to find (name (...)) blocks
        match = re.search(f'\({name}\s*\((.*?)\)\)', spec_str, re.DOTALL)
        if match:
            raw = match.group(1)
            # Naive split by closing paren to get items
            items = [x.strip() + ")" for x in raw.split(")") if x.strip()]
            return items
        return []
    
    return {
        "sorts": extract_block("sorts"),
        "ops": extract_block("ops"),
        "preds": extract_block("preds"),
        "axioms": extract_block("axioms")
    }
    
def compute_colimit(spec_a, spec_b, spec_g, map_g_to_a, map_g_to_b):
    """
    Computes the Pushout (Colimit): Blend = (A + B) / (G_a ~ G_b)
    """
    elements_a = parse_spec_elements(spec_a)
    elements_b = parse_spec_elements(spec_b)
    
    # 1. Initialize Blend with everything from Concept A
    blend = {k: set(v) for k, v in elements_a.items()}
    
    # 2. Build the Unification Map (The "Zipper")
    renaming_map = {}
    
    for category in ["sorts", "ops", "preds"]:
        map_a = map_g_to_a.get(category, {})
        map_b = map_g_to_b.get(category, {})
        
        for generic_key, target_a in map_a.items():
            if generic_key in map_b:
                target_b = map_b[generic_key]
                if target_a != target_b:
                    # Create unified name (e.g., Land_Water)
                    clean_a = re.sub(r'[:()]', '', target_a).strip()
                    clean_b = re.sub(r'[:()]', '', target_b).strip()
                    
                    # Preventing duplicate naming )
                    if clean_a == clean_b: unified = clean_a
                    else: unified = f"{clean_a}_{clean_b}"
                    
                    renaming_map[target_a] = unified
                    renaming_map[target_b] = unified
                    
    def apply_renaming(text):
        new_text = text
        
        for old in sorted(renaming_map.keys(), key=len, reverse=True):
            new = renaming_map[old]
            new_text = re.sub(rf'\b{re.escape(old)}\b', new, new_text)
            
        return new_text
    # 3. Apply Renaming to A (Update items already in blend)
    final_blend = {k: set() for k in blend.keys()}
    for category, items in blend.items():
        for item in blend[category]:
            final_blend[category].add(apply_renaming(item))
            
    # 4. Add B (Applying renaming)
    for category in ["sorts", "ops", "preds", "axioms"]:
        for item in elements_b[category]:
            renamed_item = apply_renaming(item)
            final_blend[category].add(renamed_item)
    
    return f"""(Concept BlendedConcept 
        (spec
        (sorts ({' '.join(sorted(final_blend['sorts']))}))
        (ops ({' '.join(sorted(final_blend['ops']))}))
        (preds ({' '.join(sorted(final_blend['preds']))}))
        (axioms ({' '.join(sorted(final_blend['axioms']))}))
        )
        )"""