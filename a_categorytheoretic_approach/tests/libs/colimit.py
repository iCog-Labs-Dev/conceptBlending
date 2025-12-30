import sys
import os

# 1. IMPORT PARSING UTILITIES
current_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(current_dir, '../../'))
if project_root not in sys.path:
    sys.path.insert(0, project_root)
    
try:
    from libs.validation import parse_s_expr
except ImportError:
    # If running from inside tests/ folder
    try:
        from tests.libs.validation import parse_s_expr
    except ImportError:
        sys.path.append(os.path.join(current_dir, "../"))
        from validation import parse_s_expr

def parse_s_expr(s):
    # Simple recursive parser for testing
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
            tokens.pop(0)
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
    
    # Checking if it needs renaming
    token = str(node).strip()
    
    # Check strict match first
    if token in mapping:
        return mapping[token]
    
    # Check match without colon
    clean_token = token.replace(":", "")
    if clean_token in mapping:
        # If we map "house" -> "house_boat"
        mapped_val = mapping[clean_token]
        if token.startswith(":"):
            return f":{mapped_val}"
        return mapped_val
    return token

def extract_weighted_items(concept_tree, block_name):
    """
    Extracts items and weights from a block.
    Input:  (sorts (Wall 0.9)) -> Returns dict: { "(Wall)": 0.9 }
    """
    if not concept_tree or concept_tree[0] != 'Concept': return {}
    
    spec = next((x for x in concept_tree[2:] if isinstance(x, list) and x[0] == 'spec'), None)
    if not spec: return {}
    
    block = next((x for x in spec[1:] if isinstance(x, list) and x[0] == block_name), None)
    if not block: return {}

    items = {}
    raw_content = block[1:]
    
    # Handling nested wrapper
    if len(raw_content) == 1 and isinstance(raw_content[0], list):
        raw_content = raw_content[0]

    for item in raw_content:
        try:
            # Check if item is a list and the last element is a number
            if isinstance(item, list) and len(item) > 1:
                try:
                    weight = float(item[-1])     
                    feature_parts = item[:-1]    
                except ValueError:
                    weight = 0.5              
                    feature_parts = item
                
                # Flatten the feature part back to string
                if len(feature_parts) == 1 and not isinstance(feature_parts[0], list):
                    feature_str = str(feature_parts[0])
                else:
                    feature_str = flatten_sexpr(feature_parts)
                
                items[feature_str] = weight
        except:
            continue
            
    return items

def compute_colimit(spec_a, spec_b, spec_g, map_g_to_a, map_g_to_b):    
    """
    Computes the Pushout (Colimit): Blend = (A + B) / (G_a ~ G_b)
    """
    # 1. PARSE INPUTS
    try:
        tree_a = parse_s_expr(spec_a)[0] 
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

    # 4. EXTRACT & MERGE WITH PRIORITIES
    categories = ["sorts", "ops", "preds", "axioms"]
    final_blend = {}
    
    metrics = {"count_a": 0, "count_b": 0, "total_weight": 0.0}
    
    # METRICS TRACKERS 
    stats = {
        "weight_from_a": 0.0,
        "weight_from_b": 0.0,
        "count_input_items": 0,  
        "count_blend_items": 0, 
        "total_blend_weight": 0.0
    }
    
    for cat in categories:
        # Priority extraction functions
        items_a = extract_weighted_items(renamed_tree_a, cat)
        items_b = extract_weighted_items(renamed_tree_b, cat)
        
        merged_items = {}
        
        stats["count_input_items"] += len(items_a) + len(items_b)
        
        # Add A items
        for feat, w in items_a.items():
            merged_items[feat] = w
            metrics["count_a"] += 1
            
        # Add B items (Conflict Resolution: MAX weight)
        for feat, w in items_b.items():
            if feat in merged_items:
                old_w = merged_items[feat]
                merged_items[feat] = max(old_w, w)
                
                if w > old_w:
                    stats["weight_from_b"] += w
                    stats["weight_from_a"] -= old_w
            else:
                merged_items[feat] = w
                stats["weight_from_b"] += w
        
        # Format the list back to strings
        final_list = []
        for feat, w in merged_items.items():
            clean_feat = feat.strip("()")
            # Reconstruct string with weight/priority
            final_list.append(f"({clean_feat} {w})")
            metrics["total_weight"] += w
            
            stats["total_blend_weight"] += w
            stats["count_blend_items"] += 1
            
        final_blend[cat] = final_list
        
    # FINAL METRIC CALCULATIONS
    
    # InfoValue (Total Salience) calculation
    info_value = stats["total_blend_weight"]
    
    # 2. Imbalance (Symmetry)
    total_input_weight = stats["weight_from_a"] + stats["weight_from_b"]
    if total_input_weight > 0:
        imbalance = abs(stats["weight_from_a"] - stats["weight_from_b"]) / total_input_weight
    else:
        imbalance = 0.0
            
    # 3. Compression (Efficiency)
    if stats["count_input_items"] > 0:
        compression = 1.0 - (stats["count_blend_items"] / stats["count_input_items"])
    else:
        compression = 0.0
    # 6. RETURN OUTPUT WITH METRICS
    return f"""(Concept BlendedConcept 
 (metrics
  (compression {compression:.2f})
  (infoValue {info_value:.2f})
  (imbalance {imbalance:.2f})
 )
 (spec
  (sorts ({' '.join(sorted(final_blend['sorts']))}))
  (ops ({' '.join(sorted(final_blend['ops']))}))
  (preds ({' '.join(sorted(final_blend['preds']))}))
  (axioms ({' '.join(sorted(final_blend['axioms']))}))
 )
))"""