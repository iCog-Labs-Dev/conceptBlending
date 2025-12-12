import os, sys, json
from hyperon import MeTTa
# Path setup for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from libs.agents.gpt_agent import prompt_agent
from libs.colimit import compute_colimit

def run_pipeline():
    metta = MeTTa()
    
    # 1. Simulate Inputs (or call builder)
    # Using your previous successful outputs for speed
    print("1. Loading Specs...")
    spec_house = "(Concept House (spec (sorts (Medium)) (ops ((: h House))) (axioms (on h Land))))"
    spec_boat = "(Concept Boat (spec (sorts (Medium)) (ops ((: b Boat))) (axioms (on b Water))))"
    spec_generic = "(Concept Generic (spec (sorts (Medium)) (ops ((: x Entity))) (axioms (on x Medium))))"
    
    # 2. Get Mappings (The LLM Step)
    print("2. Finding Morphisms...")
    map_a_json = prompt_agent(metta, "morphism_finder", spec_generic, spec_house)
    map_b_json = prompt_agent(metta, "morphism_finder", spec_generic, spec_boat)
    
    map_a = json.loads(map_a_json)
    map_b = json.loads(map_b_json)
    
    print(f"   Map A: {map_a}")
    print(f"   Map B: {map_b}")

    # 3. Build Amalgam (The Python Step)
    print("3. Computing Colimit...")
    blend = compute_colimit(spec_house, spec_boat, spec_generic, map_a, map_b)
    
    print("\n>>> FINAL BLEND:\n")
    print(blend)

if __name__ == "__main__":
    run_pipeline()