import re
import sys
import os

# 1. IMPORT THE ROBUST PARSER
# We add the parent directory to path so we can import 'libs.validation'
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)) + "/../")
from libs.validation import parse_s_expr

def extract_block_items(parsed_structure, block_name):
    """
    Navigates the Python List (AST) to find blocks like (sorts ...)
    instead of using Regex.
    """
    # Safety Check: Is this a valid Concept list?
    if not parsed_structure or not isinstance(parsed_structure, list):
        return []
    
    # Unwrap outer list if needed
    concept = parsed_structure[0]
    if not concept or concept[0] != 'Concept':
        return []

    # 2. NAVIGATE THE TREE
    # Find (spec ...) inside the concept
    spec = next((x for x in concept[2:] if isinstance(x, list) and x[0] == 'spec'), None)
    if not spec: return []

    # Find the target block (e.g., 'sorts') inside spec
    block = next((x for x in spec[1:] if isinstance(x, list) and x[0] == block_name), None)
    if not block: return []

    # 3. RECONSTRUCT STRINGS
    # Convert the Python lists back into MeTTa code strings
    items = []
    for item in block[1:]:
        if isinstance(item, list):
            # Recursively build nested expressions: (on h Land)
            inner = flatten_sexpr(item)
            items.append(inner)
        else:
            items.append(str(item))
            
    return items

def flatten_sexpr(item_list):
    """
    Recursive helper: ['a', ['b', 'c']] -> "(a (b c))"
    """
    if not isinstance(item_list, list):
        return str(item_list)
    
    elements = [flatten_sexpr(x) for x in item_list]
    return f"({' '.join(elements)})"

def compute_colimit(spec_a, spec_b, spec_g, map_g_to_a, map_g_to_b):
    """
    Computes the Pushout (Colimit): Blend = (A + B) / (G_a ~ G_b)
    """
    # 1. PARSE INPUTS SAFELY
    try:
        tree_a = parse_s_expr(spec_a)
        tree_b = parse_s_expr(spec_b)
    except Exception as e:
        return f"(Error \"Parsing Failed: {str(e)}\")"
    
    # 2. EXTRACT ELEMENTS (Using Tree Navigation)
    categories = ["sorts", "ops", "preds", "axioms"]
    elements_a = {cat: extract_block_items(tree_a, cat) for cat in categories}
    elements_b = {cat: extract_block_items(tree_b, cat) for cat in categories}

    # 3. INITIALIZE BLEND
    blend = {k: set(v) for k, v in elements_a.items()}

    # 4. BUILD UNIFICATION MAP
    renaming_map = {}
    
    for category in ["sorts", "ops", "preds"]:
        map_a = map_g_to_a.get(category, {})
        map_b = map_g_to_b.get(category, {})
        
        for generic_key, target_a in map_a.items():
            if generic_key in map_b:
                target_b = map_b[generic_key]
                if target_a != target_b:
                    # Clean keys for map lookups
                    clean_key_a = target_a.replace("(", "").replace(")", "").replace(":", "").strip()
                    clean_key_b = target_b.replace("(", "").replace(")", "").replace(":", "").strip()
                    
                    if clean_key_a == clean_key_b: unified = clean_key_a
                    else: unified = f"{clean_key_a}_{clean_key_b}"
                    
                    renaming_map[clean_key_a] = unified
                    renaming_map[clean_key_b] = unified

    def apply_renaming(text):
        new_text = text
        # Regex Fix: Use raw strings (fr) to avoid SyntaxWarnings
        for old, new in renaming_map.items():
            pattern = fr"(?<=[\s():]){re.escape(old)}(?=[\s():])"
            new_text = re.sub(pattern, new, new_text)
            
            # Simple fallback for single words
            if old == new_text: new_text = new
            
        return new_text

    # 5. APPLY RENAMING
    final_blend = {k: set() for k in blend}
    
    # Update A items
    for category in blend:
        for item in blend[category]:
            final_blend[category].add(apply_renaming(item))

    # Add B items
    for category in categories:
        for item in elements_b[category]:
            final_blend[category].add(apply_renaming(item))

    # 6. FORMAT OUTPUT
    return f"""(Concept BlendedConcept 
 (spec
  (sorts ({' '.join(sorted(final_blend['sorts']))}))
  (ops ({' '.join(sorted(final_blend['ops']))}))
  (preds ({' '.join(sorted(final_blend['preds']))}))
  (axioms ({' '.join(sorted(final_blend['axioms']))}))
 )
)"""