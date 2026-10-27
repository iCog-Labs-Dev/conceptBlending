import torch
import os
from a_quantale_theoretic_approach.extractor.concept_extractor import (
    ConceptEmbedder, 
    build_concept_graph, 
    concept_to_vpredicate,
    get_axioms_for_property
)
from a_quantale_theoretic_approach.extractor.gnn_truth_value import QuantaleTruthValueGNN

def run_demo():
    print("="*60)
    print("QUANTALE-GNN PIPELINE DEMO")
    print("="*60)
    
    # 1. Setup
    model_name = "all-mpnet-base-v2"
    embedder = ConceptEmbedder(model_name=model_name)
    model = QuantaleTruthValueGNN(input_dim=768)
    
    weights_path = "a_quantale_theoretic_approach/extractor/gnn_weights.pth"
    if os.path.exists(weights_path):
        model.load_state_dict(torch.load(weights_path, map_location=torch.device('cpu')))
        print(f"Loaded trained GNN weights from {weights_path}")
    else:
        print("Warning: GNN weights not found. Running with initial weights.")
    
    model.eval()
    
    # 2. Concepts to test (selected from real AtomSpace data)
    test_concepts = ["Art", "Dice", "Fire"]
    
    concept_properties = {
        "Art": ["beautiful", "subjective", "abstract", "philosophical"],
        "Dice": ["cube", "small", "hard", "numbered"],
        "Fire": ["hot", "dangerous", "bright", "red"]
    }
    
    universal_axioms = {
        "Axiom_Property", "Axiom_IsA", "Axiom_PartOf", 
        "Axiom_Function", "Axiom_Implicit", "Axiom_Related", 
        "Axiom_Default_Structural"
    }

    for concept_name in test_concepts:
        print(f"\nProcessing Concept: {concept_name}")
        print("-" * 30)
        
        # Stage 1: Get property list (pre-defined here)
        properties = {p: 0.5 for p in concept_properties[concept_name]}
        
        # Stage 2 & 3: Build graph and run GNN
        graph = build_concept_graph(concept_name, properties, embedder)
        
        with torch.no_grad():
            refined_scores = model(graph)
        
        # Stage 4: Extract Axioms and Assemble
        prop_truth_values = {}
        prop_axiom_sets = {}
        
        for i, prop_name in enumerate(graph.prop_names):
            # Property nodes start from index 1 (index 0 is concept anchor)
            truth_value = refined_scores[i+1].item()
            prop_truth_values[prop_name] = truth_value
            
            # Extract symbolic axioms (Stage 4)
            axioms = get_axioms_for_property(concept_name, prop_name)
            prop_axiom_sets[prop_name] = axioms
            
        # Assemble the final V-Predicate Concept object
        v_concept = concept_to_vpredicate(
            concept_name, 
            prop_truth_values, 
            prop_axiom_sets, 
            universal_axioms
        )
        
        # 3. Explain the output
        print(f"Concept: {concept_name}")
        for assertion in v_concept.to_metta_assertions():
            # Assertion format: (= (VPredicate Concept Property) (ProductQuantale (Axioms) TruthValue))
            print(f"  {assertion}")
            
    print("\n" + "="*60)
    print("EXPLANATION OF THE OUTPUT:")
    print("1. ProductQuantale(A, T):")
    print("   - 'A' (Axioms): The symbolic logic channel. Shows the structural basis.")
    print("   - 'T' (TruthValue): The numeric channel [0,1]. Shows semantic strength.")
    print("2. The GNN ensures that 'T' is context-aware and relation-preserving.")
    print("3. These assertions are ready to be loaded into the PeTTa reasoning engine.")
    print("="*60)

if __name__ == "__main__":
    run_demo()
