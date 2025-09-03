import numpy as np
import matplotlib.pyplot as plt
from sklearn.metrics.pairwise import cosine_similarity

GENES = 8
INPUT_A = [0.6, 0.5, 0.0, 0.4, 0.6, 0.5, 0.5, 0.4]
INPUT_B = [0.8, 0.2, 1.0, 0.3, 0.9, 0.4, 0.6, 0.3]

# -----------------------------
# HQ-blend fitness
# -----------------------------
def fitness(candidate):
    emergence = [max(0, c - max(a, b)) for c, a, b in zip(candidate, INPUT_A, INPUT_B)]
    contributions = [min(a, b) * e for a, b, e in zip(INPUT_A, INPUT_B, emergence)]
    return min(sum(contributions) / GENES, 1.0)

# -----------------------------
# Candidate-specific coherence
# -----------------------------
def candidate_coherence(candidate, population):
    if len(population) < 2:
        return 0.0
    sims = cosine_similarity([candidate], population)[0]
    return (np.sum(sims) - 1) / (len(population) - 1)

# -----------------------------
# Pareto dominance
# -----------------------------
def dominates(a, b):
    return all(x >= y for x, y in zip(a, b)) and any(x > y for x, y in zip(a, b))

def pareto_front(candidates, scores):
    front = []
    for i, s in enumerate(scores):
        if not any(dominates(other, s) for j, other in enumerate(scores) if j != i):
            front.append(i)
    return front

# -----------------------------
# CMA-ES with Pareto tracking
# -----------------------------
def cma_es_pareto(dim=GENES, sigma=0.6, max_iter=50, pop_size=20):
    mean = np.array([max(a, b) + 0.5 for a, b in zip(INPUT_A, INPUT_B)])
    cov = np.eye(dim)

    pareto_archive = []

    for gen in range(max_iter):
        samples = np.random.multivariate_normal(mean, cov * sigma**2, pop_size)
        samples = np.clip(samples, 0, 2.0)

        scores = []
        for cand in samples:
            hq = fitness(cand)
            coh = candidate_coherence(cand, samples)
            scores.append((hq, coh))
        scores = np.array(scores)

        front_idx = pareto_front(samples, scores)
        front_samples = samples[front_idx]
        front_scores = scores[front_idx]

        pareto_archive.append((gen, front_samples, front_scores))

        # CMA-ES update by HQ (keeps optimization stable)
        top_half = samples[np.argsort(scores[:, 0])[-pop_size//2:]]
        mean = top_half.mean(axis=0)
        cov = np.cov(top_half.T) + 0.05 * np.eye(dim)

        if gen % 10 == 0 or gen == max_iter - 1:
            print(f"Gen {gen}: Pareto front size={len(front_idx)}")
            best_hq = np.max(front_scores[:, 0])
            best_coh = np.max(front_scores[:, 1])
            print(f"   Best HQ={best_hq:.4f}, Best Coherence={best_coh:.4f}")

    return pareto_archive

# -----------------------------
# Plot Pareto fronts evolution
# -----------------------------
def plot_pareto_evolution(archive, gens_to_plot=[0, 10, 20, 30, 40, -1]):
    plt.figure(figsize=(8, 6))
    colors = plt.cm.viridis(np.linspace(0, 1, len(gens_to_plot)))

    for i, g in enumerate(gens_to_plot):
        if g == -1:  # last generation
            g = archive[-1][0]
            scores = archive[-1][2]
        else:
            _, _, scores = archive[g]
        plt.scatter(scores[:, 0], scores[:, 1], color=colors[i], label=f"Gen {g}")

    plt.xlabel("HQ Fitness")
    plt.ylabel("Coherence")
    plt.title("Pareto Front Evolution")
    plt.legend()
    plt.grid(True)
    plt.show()

# -----------------------------
# Run optimizer & plot
# -----------------------------
if __name__ == "__main__":
    archive = cma_es_pareto(max_iter=50)
    plot_pareto_evolution(archive)
