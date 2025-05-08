from src.input_system.conceptnet_adapter import get_conceptnet_edges  # Import the correct function

def save_to_metta(concept, output_path):
    # Fetch relationships for the concept from ConceptNet using the correct function
    relations = get_conceptnet_edges(concept)  # Call the correct function
    
    # Debugging: Print fetched relations
    print(f"Fetched relations for {concept}: {relations}")
    
    # Save the relations in MeTTa format
    with open(output_path, "w") as f:
        f.write(f"; ConceptNet knowledge for: {concept}\n")
        for relation in relations:
            # Format each relation correctly as a meTTa-like expression
            relation_str = f"({relation['relation'].lower()} {relation['start']} {relation['end']})"
            f.write(relation_str + "\n")
