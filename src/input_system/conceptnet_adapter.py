
import requests

def get_conceptnet_edges(concept, lang='en', limit=10):
    concept = concept.replace(' ', '_')
    url = f'https://api.conceptnet.io/c/{lang}/{concept}?limit={limit}'
    response = requests.get(url).json()

    edges = []
    for edge in response.get('edges', []):
        rel = edge['rel']['label']
        start = edge['start']['label']
        end = edge['end']['label']
        weight = edge.get('weight', 1.0)

        if rel in ['Causes', 'PartOf', 'UsedFor', 'HasA', 'CapableOf']:
            edges.append({
                "relation": rel,
                "start": start,
                "end": end,
                "weight": weight
            })
    return edges

