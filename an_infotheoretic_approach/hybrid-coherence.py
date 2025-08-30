import numpy as np
# from sentence_transformers import SentenceTransformer
# from sklearn.metrics.pairwise import cosine_similarity
from collections import Counter
import math
# ----------------------------
# 1. Compute entropy helpers
# ----------------------------
def shannon_entropy(p: float, base: int = 2) -> float:
    """Binary Shannon entropy H(p) = –p log p – (1–p) log(1–p)."""
    if p <= 0 or p >= 1:
        return 0.0
    log = math.log2 if base == 2 else math.log
    return -p * log(p) - (1 - p) * log(1 - p)


def joint_entropy_pairwise(p_i: float, p_j: float, mode: str = "independent", base: int = 2) -> float:
    """
    Pairwise joint entropy approximation.

    Args:
        p_i, p_j : float
            Bernoulli parameters for variables X_i and X_j
        mode : str
            "independent" → assume P(1,1) = p_i * p_j
            "min"         → assume P(1,1) = min(p_i, p_j) (max correlation)
        base : int
            Log base: 2 for bits, e for nats
    """
    if mode == "independent":
        p11 = p_i * p_j
    elif mode == "min":
        p11 = min(p_i, p_j)
    else:
        raise ValueError("mode must be 'independent' or 'min'")
    p10 = p_i - p11
    p01 = p_j - p11
    p00 = 1 - p_i - p_j + p11
    # print(p11, p10, p01, p00)

    log = math.log2 if base == 2 else math.log
    H = 0.0
    for p in (p00, p01, p10, p11):
        if p > 0:
            H -= p * log(p)
    return H


def coherence_entropy(candidate: list[float], mode: str = "independent", base: int = 2) -> float:
    """
    Entropy-based coherence:
        coherence ≈ (sum H(p_i) – avg_pairwise_H) / sum H(p_i)
    """
    n = len(candidate)
    print(n)
    Hs = [shannon_entropy(p, base=base) for p in candidate]
    sum_H = sum(Hs)
    if sum_H == 0:
        return 0.0

    print(sum_H)
    # average pairwise joint entropy
    pair_H = []
    for i in range(n):
        for j in range(i+1, n):
            pair_H.append(joint_entropy_pairwise(candidate[i], candidate[j], mode=mode, base=base))
        # print("pair_h at", i, pair_H)

    # print("sum of pair_H", sum(pair_H))
    H_joint_approx = sum(pair_H) * 2 / (n * (n - 1))
    print("H_joint_approx", H_joint_approx)
    TC = sum_H - H_joint_approx
    return TC / sum_H

# ----------------------------
# 2. Semantic similarity
# ----------------------------
def semantic_similarity(properties, degrees, model=None, threshold=0.5):
    """Compute weighted average semantic similarity for properties with degree >= threshold."""
    if model is None:
        model = SentenceTransformer('all-MiniLM-L6-v2')
    
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
    
    return np.mean(weighted_sims) if weighted_sims else 0.0

# ----------------------------
# 3. Combined Coherence
# ----------------------------
def coherence(properties, degrees, alpha=0.5):
    tc = total_correlation(degrees)
    sim = semantic_similarity(properties, degrees)
    return alpha * tc + (1 - alpha) * sim, tc, sim

# ----------------------------
# Example usage
# ----------------------------
properties = ["color", "shape", "texture", "function", 
              "size", "weight", "material", "purpose"]
degrees = [0.9, 0.9, 0.0, 0.8, 0.2, 0.9, 0.7, 0.7]

# score, tc, sim = coherence(properties, degrees, alpha=0.6)

# print("Total Correlation:", tc)
# print("Semantic Similarity:", sim)
# print("Final Coherence Score:", score)

print(coherence_entropy([0.9, 0.9, 0.0, 0.8, 0.2, 0.9, 0.7, 0.7], mode="min"))
# print(shannon_entropy(0.9))