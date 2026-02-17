import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
from collections import Counter
import math
from hyperon import *

_sentence_model = None

def get_sentence_model():
    global _sentence_model
    if _sentence_model is None:
        # print("Loading sentence transformer model...")
        _sentence_model = SentenceTransformer('all-MiniLM-L6-v2')
        # print("Model loaded.")
    return _sentence_model

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

def semantic_similarity(properties, degrees):
    """Compute weighted average semantic similarity for properties with degree >= threshold."""
    model = get_sentence_model()
    threshold = 0.5

    # ensure degrees are floats
    degrees = [float(d) for d in degrees]

    # clean properties by replacing '-' with ' '
    properties_clean = [prop.replace('-', ' ') for prop in properties]

    # filter properties and degrees by threshold
    filtered = [(p, d) for p, d in zip(properties_clean, degrees) if d >= threshold]
    if not filtered:
        return 0.0

    filtered_props, filtered_degrees = zip(*filtered)

    embeddings = model.encode(filtered_props, convert_to_numpy=True)
    sim_matrix = cosine_similarity(embeddings)

    # weighted similarity
    n = len(filtered_props)
    weighted_sims = []
    for i in range(n):
        for j in range(i+1, n):
            weight = (filtered_degrees[i] + filtered_degrees[j]) / 2
            weighted_sims.append(weight * sim_matrix[i, j])

    res = np.mean(weighted_sims) if weighted_sims else 0.0
    return float(res)
