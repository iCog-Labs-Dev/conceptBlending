import sys
import os

# ==============================================================================
# 1. PARSING UTILITIES
# ==============================================================================

def parse_s_expr(s):
    """
    Parses a Lisp-like string into a Python list (Abstract Syntax Tree).
    Example: "(a (b c))" -> ['a', ['b', 'c']]
    """
    # Pad parens to ensure clean splitting
    s = s.replace('(', ' ( ').replace(')', ' ) ')
    tokens = s.split()
    if not tokens: return []
    
    def read_from_tokens(tokens):
        if len(tokens) == 0: raise SyntaxError("Unexpected EOF")
        token = tokens.pop(0)
        
        if token == '(':
            L = []
            while len(tokens) > 0 and tokens[0] != ')':
                L.append(read_from_tokens(tokens))
            if len(tokens) > 0: tokens.pop(0) # Consume ')'
            return L
        elif token == ')':
            raise SyntaxError("Unexpected )")
        else:
            return token
            
    return [read_from_tokens(tokens)]

def flatten_sexpr(item_list):
    """
    Recursive helper to turn a Python list back into an S-Expr string.
    Example: ['a', ['b', 'c']] -> "(a (b c))"
    """
    if not isinstance(item_list, list):
        return str(item_list)
    
    elements = [flatten_sexpr(x) for x in item_list]
    return f"({' '.join(elements)})"

def recursive_rename(node, mapping):
    """
    Recursively traverses the AST and renames atoms based on the Unification Map.
    Handles strict matches ("Wall") and operator matches (":wall").
    """
    if isinstance(node, list):
        return [recursive_rename(x, mapping) for x in node]
    
    token = str(node).strip()
    
    # 1. Check Strict Match (e.g., "Wall" -> "Wall_Hull")
    if token in mapping:
        return mapping[token]
    
    # 2. Check Match ignoring colon (e.g., ":wall" -> ":wall_hull")
    # This preserves the type/operator indicator ":"
    clean_token = token.replace(":", "")
    if clean_token in mapping:
        mapped_val = mapping[clean_token]
        if token.startswith(":"):
            return f":{mapped_val}"
        return mapped_val
        
    return token

def extract_weighted_items(concept_tree, block_name):
    """
    Extracts items and weights from a specific block (sorts, ops, preds, axioms).
    Returns a dict: { "(Wall)": 0.9, "(Door)": 0.5 }
    """
    if not concept_tree or len(concept_tree) < 3: return {}
    
    # Find the (spec ...) block
    spec = next((x for x in concept_tree if isinstance(x, list) and len(x) > 0 and x[0] == 'spec'), None)
    if not spec: return {}
    
    # Find the specific block name inside spec
    block = next((x for x in spec if isinstance(x, list) and len(x) > 0 and x[0] == block_name), None)
    if not block: return {}

    items = {}
    raw_content = block[1:] # Skip the tag name
    
    # Handle double nesting case: (sorts ((A 1) (B 2)))
    if len(raw_content) == 1 and isinstance(raw_content[0], list) and raw_content[0] and isinstance(raw_content[0][0], list):
        raw_content = raw_content[0]

    for item in raw_content:
        if not isinstance(item, list): continue
        
        try:
            # Try to grab the weight from the last element
            last_elem = item[-1]
            try:
                weight = float(last_elem)
                feature_parts = item[:-1]
            except ValueError:
                # If last element isn't a float, assume default weight
                weight = 1.0
                feature_parts = item
            
            # Reconstruct the feature string (without the weight)
            if len(feature_parts) == 1 and not isinstance(feature_parts[0], list):
                feature_str = str(feature_parts[0])
            else:
                feature_str = flatten_sexpr(feature_parts)
                
            # Clean outer parens for key consistency
            feature_str = feature_str.strip("()")
            items[feature_str] = weight
            
        except Exception:
            continue
            
    return items

# ==============================================================================
# 2. CORE LOGIC: THE PUSHOUT (COLIMIT)
# ==============================================================================

# ==============================================================================
# 2. ADVANCED METRICS (CCR & SFS) - [PAPER COMPLIANT]
# ==============================================================================

def calculate_hybrid_metrics(renamed_tree_a, renamed_tree_b, final_blend_stats):
    """
    Calculates metrics comparing Structural Fidelity vs Efficiency.
    """
    categories = ["sorts", "ops", "preds", "axioms"]
    
    # DATA PREPARATION: Extract weighted items from both inputs for all categories
    input_items_a = {}
    input_items_b = {}
    
    for cat in categories:
        input_items_a.update(extract_weighted_items(renamed_tree_a, cat))
        input_items_b.update(extract_weighted_items(renamed_tree_b, cat))
        
    #1. WEIGHTED CONCEPTUAL COMPRESSION RATIO (CCR)
    # EQ: 1 - (TotalWeight(Blend) / TotalWeight(Inputs))
    total_input_weight = sum(input_items_a.values()) + sum(input_items_b.values())
    total_blend_weight = final_blend_stats["total_blend_weight"]
    
    if total_input_weight > 0:
        ccr = max(0.0, 1.0 - (total_blend_weight / total_input_weight))
    else:
        ccr = 0.0

    # 3. SFS: STRUCTURAL FIDELITY SCORE (How many AXIOMS from the inputs survived in the blend?)  
    axioms_a = extract_weighted_items(renamed_tree_a, "axioms")
    axioms_b = extract_weighted_items(renamed_tree_b, "axioms")
    
    total_axiom_weight = sum(axioms_a.values()) + sum(axioms_b.values())
    preserved_weight = 0.0
    
    # Get the set of axioms that actually made it into the blend
    blend_axioms_content = set()
    for entry in final_blend_stats.get('axioms_list', []):
        # clean entry: "( (isA x y) 0.9 )" -> "(isA x y)"
        clean = entry.strip("() ")
        last_space = clean.rfind(' ')
        if last_space != -1:
            content = clean[:last_space].strip("() ")
            blend_axioms_content.add(content)

    # Check preservation (A)
    for ax_str, w in axioms_a.items():
        if ax_str in blend_axioms_content:
            preserved_weight += w
            
    # Check preservation (B)
    for ax_str, w in axioms_b.items():
        if ax_str in blend_axioms_content:
            preserved_weight += w
            
    if total_axiom_weight > 0:
        sfs = preserved_weight / total_axiom_weight
    else:
        # Perfect fidelity if there were no rules to break
        sfs = 1.0 
        
    return ccr, sfs

def compute_colimit(spec_a, spec_b, spec_g, map_g_to_a, map_g_to_b):    
    """
    Computes the Colimit (Blend) deterministically.
    Inputs:
      spec_a, spec_b, spec_g: Strings containing the S-Expressions.
      map_g_to_a, map_g_to_b: Dictionaries mapping generic terms to specific terms.
    """
    
    # 1. PARSE S-EXPRESSIONS
    try:
        # We take [0] because parse returns a list of expressions
        tree_a = parse_s_expr(spec_a)[0] 
        tree_b = parse_s_expr(spec_b)[0]
    except Exception as e:
        return f"(Error \"Parsing Failed: {str(e)}\")"
    
    # 2. BUILD UNIFICATION MAP (The Quotient)
    # If G maps x->A and x->B, then A and B must be renamed to the same thing.
    renaming_map = {}
    
    for category in ["sorts", "ops", "preds"]:
        map_a = map_g_to_a.get(category, {})
        map_b = map_g_to_b.get(category, {})
        
        for generic_key, target_a in map_a.items():
            if generic_key in map_b:
                target_b = map_b[generic_key]
                
                # If A and B targets are different, we UNIFY them
                if target_a != target_b:
                    clean_a = target_a.replace(":", "").strip()
                    clean_b = target_b.replace(":", "").strip()
                    
                    # Create the blended name (e.g., "Land_Water")
                    if clean_a == clean_b: 
                        unified = clean_a
                    else: 
                        unified = f"{clean_a}_{clean_b}"
                    
                    # Store mappings
                    renaming_map[clean_a] = unified
                    renaming_map[clean_b] = unified
                    renaming_map[target_a] = unified
                    renaming_map[target_b] = unified
                    
    # 3. APPLY RENAMING (The Pushout)
    renamed_tree_a = recursive_rename(tree_a, renaming_map)
    renamed_tree_b = recursive_rename(tree_b, renaming_map)

    # 4. MERGE & CALCULATE WEIGHTS
    categories = ["sorts", "ops", "preds", "axioms"]
    final_blend = {}
    
    # Metrics State
    stats = {
        "weight_from_a": 0.0,
        "weight_from_b": 0.0,
        "count_input_items": 0,  
        "count_blend_items": 0, 
        "total_blend_weight": 0,
        "axioms_list": []
    }
    
    for cat in categories:
        items_a = extract_weighted_items(renamed_tree_a, cat)
        items_b = extract_weighted_items(renamed_tree_b, cat)
        
        merged_items = {}
        stats["count_input_items"] += len(items_a) + len(items_b)
        
        # Add A items
        for feat, w in items_a.items():
            merged_items[feat] = w
            stats["weight_from_a"] += w 
            
        # Add B items (Conflict Resolution: Max Weight)
        for feat, w in items_b.items():
            if feat in merged_items:
                # Collision: Shared element found
                old_w = merged_items[feat]
                merged_items[feat] = max(old_w, w)
                
                # Adjust metrics if B dominates
                if w > old_w:
                    stats["weight_from_b"] += w
                    stats["weight_from_a"] -= old_w 
            else:
                # Unique to B
                merged_items[feat] = w
                stats["weight_from_b"] += w
        
        # Re-Structure for Output
        final_list = []
        for feat, w in merged_items.items():
            final_list.append(f"({feat} {w})")
            stats["total_blend_weight"] += w
            stats["count_blend_items"] += 1
            
        final_blend[cat] = final_list
        
    # 5. CALCULATE METRICS
    
    # InfoValue
    info_value = stats["total_blend_weight"]
    
    # Imbalance
    total_input = stats["weight_from_a"] + stats["weight_from_b"]
    if total_input > 0:
        imbalance = abs(stats["weight_from_a"] - stats["weight_from_b"]) / total_input
    else:
        imbalance = 0.0
            
    # Compression
    if stats["count_input_items"] > 0:
        compression = 1.0 - (stats["count_blend_items"] / stats["count_input_items"])
    else:
        compression = 0.0

    # 6. RETURN FORMATTED S-EXPRESSION
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
