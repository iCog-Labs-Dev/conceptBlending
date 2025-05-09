import requests

CONCEPTNET_API = "https://api.conceptnet.io/query"

# List of 13 desired ConceptNet relationships
DESIRED_RELATIONS = {
    "IsA", "PartOf", "HasA", "UsedFor", "CapableOf",
    "AtLocation", "Causes", "HasSubevent", "HasFirstSubevent",
    "HasLastSubevent", "HasProperty", "Desires", "MadeOf"
}

def normalize_term(term):
    """
    Normalize concept term for ConceptNet API.
    E.g., "New York City" -> "new_york_city"
    """
    return term.lower().strip().replace(" ", "_")

def get_conceptnet_edges(concept, limit=100):
    """
    Fetches ConceptNet edges for a given concept term, including the weight (if available).
    
    Args:
        concept (str): The input concept term (e.g., "dog").
        limit (int): Max number of results to fetch.

    Returns:
        list: List of dictionaries with keys: 'relation', 'start', 'end', 'weight'
    """
    normalized = normalize_term(concept)
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

        # Skip non-English edges
        if edge["start"]["language"] != "en" or edge["end"]["language"] != "en":
            continue

        # Only include the desired relationships
        if rel in DESIRED_RELATIONS:
            edges.append({
                "relation": rel,
                "start": start,
                "end": end,
                "weight": weight  # Include weight if available
            })

    return edges
