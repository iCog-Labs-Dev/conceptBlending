import os
from src.input_system.conceptnet_adapter import get_conceptnet_edges

# Save MeTTa-formatted data to a file with optional reversed edges
def save_to_metta(concept, output_path="conceptnet_knowledge.metta", include_reversed=False, default_weight=1.0):
    """
    Saves ConceptNet knowledge of a given concept to a .metta file in a human-readable format.
    
    Adds weight to each edge if available.

    Args:
        concept (str): The concept to fetch knowledge for.
        output_path (str): Path where the .metta file will be saved.
        include_reversed (bool): Whether to include reversed edges (e.g., if 'A causes B', also include 'B causes A').
        default_weight (float): Default weight to assign if no weight is found in the ConceptNet data.
    """
    # Fetch ConceptNet edges for the provided concept
    edges = get_conceptnet_edges(concept)

    # Open the output file for writing
    with open(output_path, 'w') as file:
        # Write metadata
        file.write(f";;; ConceptNet knowledge for: {concept}\n")
        file.write(f";;; Generated with ConceptNet data\n")
        file.write(f";;; Concept: {concept}\n\n")
        
        # Write each edge in MeTTa format with weight
        for edge in edges:
            relation = edge["relation"]
            start = edge["start"]
            end = edge["end"]
            
            # Get the weight (use default_weight if no weight is available)
            weight = edge.get("weight", default_weight)  # You can adjust this logic based on your ConceptNet response
            
            # Write the forward edge with weight
            file.write(f"({relation.lower()} {start.lower()} {end.lower()} {weight})\n")

            # Optionally write the reversed edge (if enabled) with weight
            if include_reversed:
                file.write(f"({relation.lower()} {end.lower()} {start.lower()} {weight})\n")

        # Add a message at the end of the file for clarity
        file.write("\n;;; End of ConceptNet data\n")
    
    print(f"ConceptNet knowledge for '{concept}' saved to {output_path}")
