import sys
import os
import json
import re
import ast
from hyperon import *
from hyperon.ext import register_atoms
from hyperon.stdlib import ValueAtom, OperationAtom

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    from libs.agents.gpt_agent import prompt_agent, context_preprocessing_agent
    from libs.colimit import compute_colimit
except ImportError as e:
    print(f" CRITICAL ERROR: Could not import Libs: {e}")
    sys.exit(1)

metta_parser = MeTTa() 

# =========================================================
# HELPER: AGGRESSIVE JSON CLEANER
# =========================================================
def clean_and_parse_json(text_atom):
    """
    Tries multiple ways to extract a dictionary from a messy string.
    """
    raw_text = str(text_atom)
    
    # Remove outer quotes if MeTTa added them
    if raw_text.startswith('"') and raw_text.endswith('"'):
        raw_text = raw_text[1:-1]
    
    # Unescape characters that MeTTa might have escaped
    raw_text = raw_text.replace('\\"', '"') 
    raw_text = raw_text.replace('\\n', '\n')

    # 2. Extract content between the first { and last }
    match = re.search(r"(\{.*\})", raw_text, re.DOTALL)
    if match:
        clean_text = match.group(1)
    else:
        clean_text = raw_text

    # 3. ATTEMPT 1: Standard JSON (Strict)
    try:
        return json.loads(clean_text)
    except:
        pass 

    # 4. ATTEMPT 2: Python Eval (Forgiving)
    try:
        return ast.literal_eval(clean_text)
    except:
        pass

    # 5. DEBUGGING: If all fail
    print(f"\n [JSON PARSE FAILED]")
    print(f"   Input snippet: {raw_text[:100]}...") 
    return {}

# =========================================================
# 1. LLM WRAPPERS
# =========================================================

def py_generate_spec(c1_atom, c2_atom):
    """Generates Specs for 2 concepts"""
    try:
        context_preprocessing_agent(metta_parser, c1_atom, c2_atom)
    except:
        pass 
    return prompt_agent(metta_parser, "algspec_builder", c1_atom, c2_atom)

def py_generate_gen(spec1_atom, spec2_atom):
    """Generates Generalization"""
    return prompt_agent(metta_parser, "generalization_helper", spec1_atom, spec2_atom)

def py_find_morphisms(spec_g, spec_target):
    """Generates Morphism JSON"""
    print("   -> Python: Finding Morphisms...")
    result = prompt_agent(metta_parser, "morphism_finder", spec_g, spec_target)
    if isinstance(result, str): return [ValueAtom(result)]
    return result

# =========================================================
# 2. MATH WRAPPERS
# =========================================================

def py_compute_colimit(spec_a, spec_b, spec_g, map_a_atom, map_b_atom):
    """Computes the Blend"""
    print("   -> Python: Computing Colimit...")
    try:
        # Use the aggressive cleaner
        map_a = clean_and_parse_json(map_a_atom)
        map_b = clean_and_parse_json(map_b_atom)
        
        if not map_a or not map_b:
            return [ValueAtom("(Error \"Morphism JSON was empty or invalid\")")]

        # Compute Colimit
        result = compute_colimit(str(spec_a), str(spec_b), str(spec_g), map_a, map_b)
        return [ValueAtom(result)]
        
    except Exception as e:
        print(f"   [Colimit Math Failed]: {e}")
        return [ValueAtom(f"(Error \"Math Failed: {e}\")")]

def py_log(msg):
    print(str(msg).strip('"'))
    return [ValueAtom(True)]

def py_save(filename, content):
    path = str(filename).strip('"')
    print(f"   -> Saved file to {path}")
    with open(path, "w") as f: f.write(str(content).strip('"'))
    return [ValueAtom(True)]

# =========================================================
# 3. REGISTRATION
# =========================================================

@register_atoms
def my_atoms():
    return {
        "llm:generate-spec": OperationAtom("llm:generate-spec", py_generate_spec, unwrap=False),
        "llm:generate-gen":  OperationAtom("llm:generate-gen",  py_generate_gen,  unwrap=False),
        "llm:find-morph":    OperationAtom("llm:find-morph",    py_find_morphisms, unwrap=False),
        "math:colimit":      OperationAtom("math:colimit",      py_compute_colimit, unwrap=False),
        "util:log":          OperationAtom("util:log",          py_log, unwrap=False),
        "util:save":         OperationAtom("util:save",         py_save, unwrap=False)
    }