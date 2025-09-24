import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
from collections import Counter
import math
from hyperon import *

def parse_to_list(s: str):
        # remove surrounding parentheses
        s = s.strip("()")
        # print("Parsing string to list:", s)
        # split by whitespace
        elements = s.split()
        
        # try to convert each element to int/float if possible, else keep as string
        def convert(x):
            try:
                return int(x)
            except ValueError:
                try:
                    return float(x)
                except ValueError:
                    return x  # leave as string if not numeric
        
        return [convert(el) for el in elements]

# ----------------------------
# 2. Semantic similarity
# ----------------------------
def semantic_similarity(metta: MeTTa, *args):
    """Compute weighted average semantic similarity for properties with degree >= threshold."""
    # if model is None:
    model = SentenceTransformer('all-MiniLM-L6-v2')
    threshold = 0.5
    # print("Args:", args)
    properties, degrees = parse_to_list(str(args[0])), parse_to_list(str(args[1]))
    # print("Properties:", properties)
    # print("Degrees:", degrees)
    # filter properties and degrees by threshold
    filtered = [(p, d) for p, d in zip(properties, degrees) if d >= threshold]
    if not filtered:  # if nothing passes the threshold
        return 0.0
    
    filtered_props, filtered_degrees = zip(*filtered)
    
    embeddings = model.encode(filtered_props, convert_to_numpy=True)
    sim_matrix = cosine_similarity(embeddings)

    # weight by fuzzy memberships
    n = len(filtered_props)
    weighted_sims = []
    for i in range(n):
        for j in range(i+1, n):
            weight = (filtered_degrees[i] + filtered_degrees[j]) / 2
            weighted_sims.append(weight * sim_matrix[i, j])

    res = np.mean(weighted_sims) if weighted_sims else 0.0
    # print("res:", res)

    return [ValueAtom(float(res)) if res else ValueAtom(0.0)]
