import json
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

def llm_result(response):
    text = "".join(response)
    text = text.replace("```json", "").replace("```", "")

    data = json.loads(text)
    return list(map(int, data["result"].strip("()").split()))



def compute_average_pairwise_similarity(properties):
    model = SentenceTransformer('all-MiniLM-L6-v2')
    threshold = 0.5

    properties_clean = [str(prop).replace('-', ' ').replace('_', ' ') for prop in properties]
    
    n = len(properties_clean)
    if n < 2: # need at least 2 items to compare
        return 0.0
    
    embeddings = model.encode(properties_clean, convert_to_numpy=True)
    sim_matrix = cosine_similarity(embeddings)

    pairwise = []

    for i in range(n):
        for j in range(i + 1, n):
            pairwise.append(sim_matrix[i][j])

    score = float(np.mean(pairwise)) if pairwise else 0.0
    return score