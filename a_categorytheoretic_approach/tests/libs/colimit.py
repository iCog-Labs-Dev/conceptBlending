import sys
import os

# 1. IMPORT PARSING UTILITIES
current_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(current_dir, '../../'))
if project_root not in sys.path:
    sys.path.insert(0, project_root)
    
# sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)) + "/../")
# Try importing from libs.validation
try:
    from libs.validation import parse_s_expr
except ImportError:
    # If running from inside tests/ folder
    try:
        from tests.libs.validation import parse_s_expr
    except ImportError:
        # Last resort: absolute import assuming standard structure
        sys.path.append(os.path.join(current_dir, "../"))
        from validation import parse_s_expr



def parse_s_expr(s):
    # A very simple recursive parser for testing
    s = s.replace('(', ' ( ').replace(')', ' ) ')
    tokens = s.split()
    if not tokens: return []
    
    def read_from_tokens(tokens):
        if len(tokens) == 0: raise SyntaxError("Unexpected EOF")
        token = tokens.pop(0)
        if token == '(':
            L = []
            while tokens[0] != ')':
                L.append(read_from_tokens(tokens))
            tokens.pop(0) # pop ')'
            return L
        elif token == ')':
            raise SyntaxError("Unexpected )")
        else:
            return token
            
    return [read_from_tokens(tokens)]

def flatten_sexpr(item_list):
    """
    Recursive helper: ['a', ['b', 'c']] -> "(a (b c))"
    """
    if not isinstance(item_list, list):
        return str(item_list)
    
    elements = [flatten_sexpr(x) for x in item_list]
    return f"({' '.join(elements)})"

def recursive_rename(node, mapping):
    """
    Traverses the Python List (AST) and renames atoms based on the mapping.
    """
    if isinstance(node, list):
        return [recursive_rename(x, mapping) for x in node]
    
    # If it's a string (atom), check if it needs renaming
    token = str(node).strip()
    
    # Check strict match first
    if token in mapping:
        return mapping[token]
    
    # Check match without colon (e.g., ":house" -> "house")
    clean_token = token.replace(":", "")
    if clean_token in mapping:
        # If we map "house" -> "house_boat", we want ":house" -> ":house_boat"
        mapped_val = mapping[clean_token]
        if token.startswith(":"):
            return f":{mapped_val}"
        return mapped_val
    return token

# def extract_block_items_from_tree(concept_tree, block_name):
#     """
#     Extracts specific blocks (like sorts/axioms) from the ALREADY RENAMED tree.
#     """
#     if not concept_tree or concept_tree[0] != 'Concept':
#         return []
    
#     # Find (spec ...)
#     spec = next((x for x in concept_tree[2:] if isinstance(x, list) and x[0] == 'spec'), None)
#     if not spec: return []

#     # Find the target block
#     block = next((x for x in spec[1:] if isinstance(x, list) and x[0] == block_name), None)
#     if not block: return []

#     # Flatten items to strings for Set operations
#     items = []
#     for item in block[1:]:
#         items.append(flatten_sexpr(item))
#     return items

def extract_block_items_from_tree(concept_tree, block_name):
    """
    Extracts atoms from a block like (sorts a b c) or (sorts (a b c)).
    Fixes the 'Nested List' bug by flattening the content.
    """
    if not concept_tree or concept_tree[0] != 'Concept':
        return []
    
    # Find (spec)
    spec = next((x for x in concept_tree[2:] if isinstance(x, list) and x[0] == 'spec'), None)
    if not spec: return []

    # Find the target block (ex: 'sorts')
    block = next((x for x in spec[1:] if isinstance(x, list) and x[0] == block_name), None)
    if not block: return []

    # 1. IDENTIFY CONTENT
    # block looks like: ['sorts', 'a', 'b'] OR ['sorts', ['a', 'b']]
    raw_content = block[1:]
    
    # If the first item is a list, we assume it's a wrapper: (sorts (a b c))
    if len(raw_content) == 1 and isinstance(raw_content[0], list):
        items_to_process = raw_content[0]
    else:
        items_to_process = raw_content

    # 2. FLATTEN
    items = []
    for item in items_to_process:
        items.append(flatten_sexpr(item))
    return items


def compute_colimit(spec_a, spec_b, spec_g, map_g_to_a, map_g_to_b):    
    """
    Computes the Pushout (Colimit): Blend = (A + B) / (G_a ~ G_b)
    """
    # 1. PARSE INPUTS (Get the Trees)
    try:
        tree_a = parse_s_expr(spec_a)[0] # Get first concept
        tree_b = parse_s_expr(spec_b)[0]
    except Exception as e:
        return f"(Error \"Parsing Failed: {str(e)}\")"
    
    # 2. BUILD UNIFICATION MAP
    renaming_map = {}
    
    for category in ["sorts", "ops", "preds"]:
        map_a = map_g_to_a.get(category, {})
        map_b = map_g_to_b.get(category, {})
        
        for generic_key, target_a in map_a.items():
            if generic_key in map_b:
                target_b = map_b[generic_key]
                
                # If they map to different things, UNIFY THEM
                if target_a != target_b:
                    # Clean keys
                    clean_a = target_a.replace(":", "").strip()
                    clean_b = target_b.replace(":", "").strip()
                    
                    if clean_a == clean_b: unified = clean_a
                    else: unified = f"{clean_a}_{clean_b}"
                    
                    if clean_a == clean_b: unified = clean_a
                    else: unified = f"{clean_a}_{clean_b}"
                    
                    # Store mappings
                    renaming_map[clean_a] = unified
                    renaming_map[clean_b] = unified
                    renaming_map[target_a] = unified
                    renaming_map[target_b] = unified
                    
    # 3. APPLY RENAMING TO TREES
    renamed_tree_a = recursive_rename(tree_a, renaming_map)
    renamed_tree_b = recursive_rename(tree_b, renaming_map)

    # 4. EXTRACT & MERGE
    categories = ["sorts", "ops", "preds", "axioms"]
    
    final_blend = {}
    for cat in categories:
        items_a = set(extract_block_items_from_tree(renamed_tree_a, cat))
        items_b = set(extract_block_items_from_tree(renamed_tree_b, cat))
        
        # Union the sets
        final_blend[cat] = items_a.union(items_b)
    
    # 5. FORMAT OUTPUT
    # Get the Concept Name (usually derived from inputs, here fixed for simplicity)
    return f"""(Concept BlendedConcept 
 (spec
  (sorts ({' '.join(sorted(final_blend['sorts']))}))
  (ops ({' '.join(sorted(final_blend['ops']))}))
  (preds ({' '.join(sorted(final_blend['preds']))}))
  (axioms ({' '.join(sorted(final_blend['axioms']))}))
 )
)"""

#     """
#     Computes the Pushout (Colimit): Blend = (A + B) / (G_a ~ G_b)
#     """
#     # 1. PARSE INPUTS SAFELY
#     try:
#         tree_a = parse_s_expr(spec_a)
#         tree_b = parse_s_expr(spec_b)
#     except Exception as e:
#         return f"(Error \"Parsing Failed: {str(e)}\")"
    
#     # 2. EXTRACT ELEMENTS (Using Tree Navigation)
#     categories = ["sorts", "ops", "preds", "axioms"]
#     elements_a = {cat: extract_block_items(tree_a, cat) for cat in categories}
#     elements_b = {cat: extract_block_items(tree_b, cat) for cat in categories}

#     # 3. INITIALIZE BLEND
#     blend = {k: set(v) for k, v in elements_a.items()}

#     # 4. BUILD UNIFICATION MAP
#     renaming_map = {}
    
#     for category in ["sorts", "ops", "preds"]:
#         map_a = map_g_to_a.get(category, {})
#         map_b = map_g_to_b.get(category, {})
        
#         for generic_key, target_a in map_a.items():
#             if generic_key in map_b:
#                 target_b = map_b[generic_key]
#                 if target_a != target_b:
#                     # Clean keys for map lookups
#                     clean_key_a = target_a.replace("(", "").replace(")", "").replace(":", "").strip()
#                     clean_key_b = target_b.replace("(", "").replace(")", "").replace(":", "").strip()
                    
#                     if clean_key_a == clean_key_b: unified = clean_key_a
#                     else: unified = f"{clean_key_a}_{clean_key_b}"
                    
#                     renaming_map[clean_key_a] = unified
#                     renaming_map[clean_key_b] = unified

#     def apply_renaming(text):
#         new_text = text
#         # Regex Fix: Use raw strings (fr) to avoid SyntaxWarnings
#         for old, new in renaming_map.items():
#             pattern = fr"(?<=[\s():]){re.escape(old)}(?=[\s():])"
#             new_text = re.sub(pattern, new, new_text)
            
#             # Simple fallback for single words
#             if old == new_text: new_text = new
            
#         return new_text

#     # 5. APPLY RENAMING
#     final_blend = {k: set() for k in blend}
    
#     # Update A items
#     for category in blend:
#         for item in blend[category]:
#             final_blend[category].add(apply_renaming(item))

#     # Add B items
#     for category in categories:
#         for item in elements_b[category]:
#             final_blend[category].add(apply_renaming(item))

#     # 6. FORMAT OUTPUT
#     return f"""(Concept BlendedConcept 
#  (spec
#   (sorts ({' '.join(sorted(final_blend['sorts']))}))
#   (ops ({' '.join(sorted(final_blend['ops']))}))
#   (preds ({' '.join(sorted(final_blend['preds']))}))
#   (axioms ({' '.join(sorted(final_blend['axioms']))}))
#  )
# )"""