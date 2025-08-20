import requests
import networkx as nx
import matplotlib.pyplot as plt
import os
CONCEPTNET_API = "https://api.conceptnet.io/query"

# List of 13 desired ConceptNet relationships
DESIRED_RELATIONS = {
    "IsA", "PartOf", "HasA", "UsedFor", "CapableOf",
    "AtLocation", "Causes", "HasSubevent", "HasFirstSubevent",
    "HasLastSubevent", "HasProperty", "Desires", "MadeOf", "RelatedTo"
}

def get_conceptnet_edges(concept, limit=100):
    """
    Fetches ConceptNet edges for a given concept term, including the weight (if available).
    
    Args:
        concept (str): The input concept term (e.g., "dog").
        limit (int): Max number of results to fetch.

    Returns:
        list: List of dictionaries with keys: 'relation', 'start', 'end', 'weight'
    """
    # Normalize the concept term for the API request
    normalized = concept.lower().strip('"').replace(" ", "_")
    url = f"{CONCEPTNET_API}?node=/c/en/{normalized}&limit={limit}"
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f"ConceptNet API error: {response.status_code}")

    edges = []
    for edge in response.json().get("edges", []):
        rel = edge["rel"]["label"]
        start = edge["start"]["label"]
        end = edge["end"]["label"]
        weight = edge.get("weight", None)  # Check if the weight is available
        surftext = edge.get("surfaceText", None)
        # Skip non-English edges
        if edge["start"]["language"] != "en" or edge["end"]["language"] != "en":
            continue

        # Only include the desired relationships
        if rel in DESIRED_RELATIONS:
            edges.append({
                "relation": rel,
                "start": start,
                "end": end,
                "weight": weight,  # Include weight if available
                "surftext": surftext
            })
    return edges

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

def visualize_conceptnet_graph(edges, concept, export_path=None):
    G = nx.DiGraph()

    for edge in edges:
        G.add_edge(edge["start"], edge["end"], label=edge["relation"])

    pos = nx.spring_layout(G, seed=42)

    plt.figure(figsize=(10, 8))
    nx.draw(G, pos, with_labels=True, node_size=2000, node_color="lightblue", font_size=10, arrows=True)
    nx.draw_networkx_edge_labels(G, pos, edge_labels=nx.get_edge_attributes(G, "label"), font_color="red")
    plt.title(f"ConceptNet Graph for '{concept}'")

    if export_path:
        plt.savefig(export_path, format="png")
        print(f"✅ PNG graph saved to: {export_path}")
    else:
        plt.show()