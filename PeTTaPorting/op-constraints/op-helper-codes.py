import json
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np
import requests

def get_word_associations(word):
    url = f"https://api.datamuse.com/words?rel_trg={word}&max=10"
    response = requests.get(url)

    if response.status_code == 200:
        data = response.json()
        word_list = [item['word'] for item in data]

        if word not in word_list:
            word_list.insert(0, word)

        return word_list
    return [word]
# Output: ['web', 'snake', 'venom', 'bite', 'creepy', 'legs', 'arachnid', 'tarantula'...]


def llm_result(response):
    text = "".join(response)
    text = text.replace("```json", "").replace("```", "")

    data = json.loads(text)
    return list(map(int, data["result"].strip("()").split()))



_sentence_model = None

def get_sentence_model():
    global _sentence_model
    if _sentence_model is None:
        print("Loading sentence transformer model...")
        _sentence_model = SentenceTransformer('all-MiniLM-L6-v2')
        print("Model loaded.")
    return _sentence_model

def compute_average_pairwise_similarity(properties):
    print(f"Computing average pairwise similarity for properties: {properties}")
    model = get_sentence_model()
    threshold = 0.5

    properties_clean = [str(prop).replace('-', ' ').replace('_', ' ') for prop in properties]
    
    n = len(properties_clean)
    if n < 2: # need at least 2 items to compare
        return 0.0
    
    embeddings = model.encode(properties_clean, convert_to_numpy=True)
    sim_matrix = cosine_similarity(embeddings)
    print(f"Similarity matrix:\n{sim_matrix}")
    pairwise = []

    for i in range(n):
        for j in range(i + 1, n):
            pairwise.append(sim_matrix[i][j])

    score = float(np.mean(pairwise)) if pairwise else 0.0
    print(f"Average pairwise similarity score: {score}")
    return score