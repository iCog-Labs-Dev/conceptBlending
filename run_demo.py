from conceptual_integration.core.representation.concept import Concept, Property, Relation
from conceptual_integration.core.blending.constraint_manager import ConstraintManager
from conceptual_integration.data_sources.conceptnet_adapter import ConceptNetAdapter
from conceptual_integration.data_sources.llm_integration import LLMIntegration
import yaml
import time
import os

def load_config():
    with open("config/constraints.yaml") as f:
        config = yaml.safe_load(f)
    # Replace environment variables
    if "llm" in config and "api_key" in config["llm"]:
        config["llm"]["api_key"] = os.path.expandvars(config["llm"]["api_key"])
    return config

def create_car():
    car = Concept("car")
    car.add_property("metal", ["car"])
    car.add_property("has wheels", ["car"])
    car.add_relation("UsedFor", "transportation", 0.9)
    car.add_relation("HasPart", "engine", 0.8)
    return car

def create_boat():
    boat = Concept("boat")
    boat.add_property("floats", ["boat"])
    boat.add_property("waterproof", ["boat"])
    boat.add_relation("UsedFor", "transportation", 0.9)
    boat.add_relation("UsedFor", "recreation", 0.7)
    return boat

def create_smart_bottle():
    bottle = Concept("water_bottle")
    bottle.add_property("holds liquid", ["water_bottle"])
    bottle.add_relation("UsedFor", "hydration")

    tracker = Concept("fitness_tracker")
    tracker.add_property("tracks consumption", ["fitness_tracker"])
    tracker.add_relation("HasFeature", "bluetooth")

    blend = Concept("smart_water_bottle")
    blend.add_property("holds liquid", ["water_bottle"])
    blend.add_property("tracks consumption", ["fitness_tracker"])
    blend.add_property("self-cleaning")  # Emergent
    blend.add_relation("UsedFor", "hydration", 1.0)
    blend.add_relation("HasFeature", "bluetooth", 0.8)

    return bottle, tracker, blend


def create_cross_mappings():
    return [{
        "relation_type": "UsedFor",
        "concept_a_relation": Relation("UsedFor", "transportation", 0.9),
        "concept_b_relation": Relation("UsedFor", "transportation", 0.9),
        "confidence": 1.0
    }]

def print_results(blend, result):
    print(f"\n=== Blend: {blend.name} ===")
    print(f"Properties: {[p.name for p in blend.properties]}")
    print(f"Relations: {[f'{r.type}→{r.target}' for r in blend.relations]}")
    
    print("\nConstraint Scores:")
    for name, score in result["raw_scores"].items():
        print(f"- {name.capitalize()}: {score:.2f}")
    
    print(f"\nWeighted Score: {result['weighted_score']:.2f}")
    print(f"Rejected: {result['is_rejected']}")
    if result["is_rejected"]:
        print(f"Reason: {result['rejection_reason']}")

def main():
    config = load_config()
    manager = ConstraintManager(config)
    
    print("===== CAR + BOAT BLEND =====")
    car = create_car()
    boat = create_boat()
    cross_mappings = create_cross_mappings()
    
    # Good blend
    good_blend = Concept("amphibious_vehicle")
    good_blend.add_property("metal", ["car"])
    good_blend.add_property("floats", ["boat"])
    good_blend.add_property("waterproof")  # Emergent
    good_blend.add_relation("UsedFor", "transportation", 1.0)
    good_blend.add_relation("Short_HasPart", "engine", 0.8)  # Compressed
    
    result = manager.evaluate(good_blend, (car, boat), cross_mappings)
    print_results(good_blend, result)
    
    print("\n===== SMART WATER BOTTLE BLEND =====")
    bottle, tracker, smart_bottle = create_smart_bottle()
    result = manager.evaluate(smart_bottle, (bottle, tracker), [])
    print_results(smart_bottle, result)
    
    # Test LLM fallback
    print("\n===== TESTING LLM FALLBACK =====")
    test_blend = Concept("test_concept")
    test_blend.add_property("magic_power")  # Emergent
    result = manager.evaluate(test_blend, (car, boat), [])
    print(f"GoodReason score: {result['raw_scores']['good_reason']:.2f}")

if __name__ == "__main__":
    start_time = time.time()
    main()
    print(f"\nExecution time: {time.time() - start_time:.2f} seconds")