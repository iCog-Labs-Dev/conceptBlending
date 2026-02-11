import json
import re
import ast
import time
import sys
import os
from hyperon import *
from hyperon.ext import register_atoms
from hyperon.stdlib import ValueAtom, OperationAtom

from libs.performance_monitor import monitor

current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.append(current_dir)

try:
    from libs.agents.gpt_agent import prompt_agent, context_preprocessing_agent    
    from libs.colimit import compute_colimit
except ImportError as e:
    sys.exit(1)

# Initialize MeTTa (needed for prompt_agent to parse results)
metta_parser = MeTTa() 

# =========================================================
# HELPER: AGGRESSIVE JSON CLEANER
# =========================================================
def clean_and_parse_json(text_atom):
    """
    Robustly extracts a dictionary from a potentially messy string (Atom).
    """
    raw_text = str(text_atom)
    
    # 1. Clean MeTTa string artifacts (quotes)
    if raw_text.startswith('"') and raw_text.endswith('"'):
        raw_text = raw_text[1:-1]
    
    # Unescape characters
    raw_text = raw_text.replace('\\"', '"').replace('\\n', '\n')

    # 2. Extract content between the first { and last }
    match = re.search(r"(\{.*\})", raw_text, re.DOTALL)
    if match:
        clean_text = match.group(1)
    else:
        clean_text = raw_text

    # 3. Parsing (JSON first, then Python literal)
    try:
        return json.loads(clean_text)
    except:
        try:
            return ast.literal_eval(clean_text)
        except:
            print(f"   [Warning] JSON Parse Failed for: {clean_text[:50]}...")
            return {}

# =========================================================
# 3. WRAPPERS: LLM AGENTS
# =========================================================

def py_generate_spec(c1_atom, c2_atom):
    """
    Calls GPT to generate Algebraic Specs for two concepts.
    MeTTa Call: (llm:generate-spec house boat)
    """
    # Optional: Run preprocessing context agent first if needed
    start_time = time.time()
    try:
        try:
           context_preprocessing_agent(metta_parser, c1_atom, c2_atom)
        except:
            pass
        result = prompt_agent(metta_parser, "algspec_builder", c1_atom, c2_atom)
        
        # Log Success
        monitor.log_llm_attempt(success=True)
        return result
    except Exception as e:
        monitor.log_llm_attempt(success=False)
        return [ValueAtom(f'(Error "{str(e)}")')]
    
    finally:
        # Log Latency
        duration = time.time() - start_time
        monitor.log_phase("1_Spec_Generation", duration)
    # return prompt_agent(metta_parser, "algspec_builder", c1_atom, c2_atom)

def py_generate_gen(spec1_atom, spec2_atom):
    """
    Calls GPT to find the Generalization (Shared Interface).
    MeTTa Call: (llm:generate-gen $specA $specB)
    """
    return prompt_agent(metta_parser, "generalization_helper", spec1_atom, spec2_atom)

def py_find_morphisms(spec_g, spec_target):
    """
    Calls GPT to find the JSON mapping (Morphism).
    Returns a ValueAtom containing the JSON string.
    MeTTa Call: (llm:find-morph $specG $specA)
    """
    print("   -> [Agent] Finding Morphisms (Mapping G -> Target)...")
    result_string = prompt_agent(metta_parser, "morphism_finder", spec_g, spec_target)
    
    # Wrap in ValueAtom so MeTTa treats it as a single string object, not code
    return [ValueAtom(result_string)]

# =========================================================
# 4. WRAPPERS: MATH ENGINE (COLIMIT)
# =========================================================

def py_compute_colimit(spec_a, spec_b, spec_g, map_a_atom, map_b_atom):
    """
    Executes the Mathematical Pushout using colimit.py
    MeTTa Call: (math:colimit $specA $specB $specG $mapA $mapB)
    """
    print("   -> [Math] Parsing Morphisms & Computing Colimit...")
    
    try:
        # 1. Clean and Parse the JSON Maps
        map_a = clean_and_parse_json(map_a_atom)
        map_b = clean_and_parse_json(map_b_atom)
        
        if not map_a or not map_b:
            return [ValueAtom('(Error "Morphism JSON extraction failed or empty")')]

        result = compute_colimit(str(spec_a), str(spec_b), str(spec_g), map_a, map_b)
        
        return [ValueAtom(result)]
        
    except Exception as e:
        print(f"   [Colimit Error] {e}")
        return [ValueAtom(f'(Error "Math Execution Failed: {e}")')]

# =========================================================
# 5. UTILITIES
# =========================================================

def py_log(msg):
    """Simple logging helper"""
    print(str(msg).strip('"'))
    return [ValueAtom(True)]

# =========================================================
# 6. REGISTRATION (EXPOSING TO METTA)
# =========================================================

@register_atoms
def operation_atoms():
    return {
        "llm:generate-spec": OperationAtom("llm:generate-spec", py_generate_spec, unwrap=False),
        "llm:generate-gen":  OperationAtom("llm:generate-gen",  py_generate_gen,  unwrap=False),
        "llm:find-morph":    OperationAtom("llm:find-morph",    py_find_morphisms, unwrap=False),
        "math:colimit":      OperationAtom("math:colimit",      py_compute_colimit, unwrap=False),
        "util:log":          OperationAtom("util:log",          py_log, unwrap=False)
    }
    
if "extensions_loaded" not in globals():
    print("DEBUG: extensions.py is loading/registering atoms...")
    globals()["extensions_loaded"] = True
    
    @register_atoms
    def register_operation_atoms_wrapper():
        return operation_atoms()
