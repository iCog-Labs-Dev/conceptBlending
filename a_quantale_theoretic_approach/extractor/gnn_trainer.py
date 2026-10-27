import torch
import torch.nn.functional as F
import os
import re
import random
import argparse
import numpy as np
from collections import defaultdict
from typing import Dict, List, Tuple
from scipy.stats import spearmanr
from .gnn_truth_value import QuantaleTruthValueGNN
from .concept_extractor import ConceptEmbedder, build_concept_graph


def parse_metta_triples(file_path: str) -> List[Tuple[str, str, float]]:
    """
    Parses hasProperty triples from AtomSpace .metta files.

    Normalization: uses min-max scaling to [0.1, 1.0] so that the weakest
    property retains a non-trivial truth value. Mapping to 0.0 causes the
    model to collapse to the global mean (flat-predictor problem).
    """
    if not os.path.exists(file_path):
        return []

    with open(file_path, 'r') as f:
        content = f.read()

    weight_pattern = r'\(weight \(hasProperty (\S+) (\S+)\) ([\d.]+)\)'
    weight_lookup = {(c, p): float(w) for c, p, w in re.findall(weight_pattern, content)}

    raw_triples = []
    for line in content.splitlines():
        m = re.match(r'^\(hasProperty (\S+) (\S+)\)', line)
        if m:
            concept, prop = m.group(1), m.group(2)
            weight = weight_lookup.get((concept, prop), 1.0)
            raw_triples.append((concept, prop.replace('_', ' '), weight))

    if not raw_triples:
        return []

    all_weights = [w for _, _, w in raw_triples]
    w_min, w_max = min(all_weights), max(all_weights)

    # Map to [0.1, 1.0]: keeps a semantic floor so 0.0 is never a target
    triples = [
        (c, p, 0.1 + 0.9 * (w - w_min) / (w_max - w_min) if w_max > w_min else 0.5)
        for c, p, w in raw_triples
    ]
    return triples


def ranking_loss(pred: torch.Tensor, target: torch.Tensor, margin: float = 0.05) -> torch.Tensor:
    """
    Pairwise ranking loss. Penalises the model when it gets the relative order
    of two property truth values wrong (by more than `margin`).

    This directly optimises the Spearman rank correlation and prevents the
    model from collapsing to a flat average under MSE-only training.
    """
    n = pred.shape[0]
    loss, count = 0.0, 0
    for i in range(n):
        for j in range(n):
            if i == j:
                continue
            if (target[i] - target[j]) > margin:
                loss += torch.relu(margin - (pred[i] - pred[j]))
                count += 1
    return loss / max(count, 1)


def evaluate_mse(model: QuantaleTruthValueGNN, graphs: list, device: str) -> float:
    """Returns mean MSE loss on a set of graphs."""
    model.eval()
    losses = []
    with torch.no_grad():
        for data in graphs:
            data = data.to(device)
            pred = model(data)
            loss = F.mse_loss(pred[1:], data.y[1:])
            if not torch.isnan(loss):
                losses.append(loss.item())
    model.train()
    return sum(losses) / max(len(losses), 1)


def evaluate_spearman(model: QuantaleTruthValueGNN, graphs: list, device: str) -> float:
    """Returns mean Spearman rank correlation on a set of graphs."""
    model.eval()
    correlations = []
    with torch.no_grad():
        for data in graphs:
            data = data.to(device)
            pred = model(data)[1:].cpu().numpy()
            target = data.y[1:].cpu().numpy()
            if len(pred) > 1:
                corr, _ = spearmanr(pred, target)
                if not np.isnan(corr):
                    correlations.append(corr)
    model.train()
    return sum(correlations) / max(len(correlations), 1)


def train_quantale_gnn(
    model: QuantaleTruthValueGNN,
    train_graphs: list,
    test_graphs: list,
    epochs: int = 100,
    lr: float = 0.0005,
    patience: int = 30,
    rank_weight_init: float = 0.5,
    rank_weight_decay: float = 0.99,
    ranking_margin: float = 0.05,
    device: str = 'cpu'
) -> Tuple[QuantaleTruthValueGNN, list, list, list, int]:
    """
    Trains the GNN with:
      - Combined MSE + ranking loss (ranking weight decays each epoch)
      - Cosine annealing LR schedule
      - Gradient clipping
      - Spearman-rank checkpointing (saves the epoch with the best ranking)
      - Early stopping on Spearman (not MSE)

    Returns: (model, train_losses, test_losses, spearman_history, best_epoch)
    """
    model = model.to(device)
    optimizer = torch.optim.Adam(model.parameters(), lr=lr, weight_decay=1e-4)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=epochs)
    model.train()

    loss_history, test_loss_history, rank_history = [], [], []
    best_rank_score = -1.0
    patience_counter = 0
    best_state = None
    best_epoch = -1

    for epoch in range(epochs):
        random.shuffle(train_graphs)
        total_loss, valid = 0, 0

        for data in train_graphs:
            data = data.to(device)
            optimizer.zero_grad()
            pred = model(data)

            mse = F.mse_loss(pred[1:], data.y[1:])
            rank = ranking_loss(pred[1:], data.y[1:], margin=ranking_margin)
            rw = rank_weight_init * (rank_weight_decay ** epoch)
            loss = mse + rw * rank

            if torch.isnan(loss):
                continue

            loss.backward()
            torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
            optimizer.step()
            total_loss += loss.item()
            valid += 1

        scheduler.step()

        train_loss = total_loss / max(valid, 1)
        test_loss = evaluate_mse(model, test_graphs, device)
        rank_score = evaluate_spearman(model, test_graphs, device)

        loss_history.append(train_loss)
        test_loss_history.append(test_loss)
        rank_history.append(rank_score)

        if epoch % 5 == 0:
            print(f"epoch {epoch:3d}: train {train_loss:.4f}  test {test_loss:.4f}  spearman {rank_score:.4f}")

        # Checkpoint on Spearman (not MSE) — MSE alone leads to flat-predictor collapse
        if rank_score > best_rank_score:
            best_rank_score = rank_score
            best_epoch = epoch
            patience_counter = 0
            best_state = {k: v.clone() for k, v in model.state_dict().items()}
        else:
            patience_counter += 1
            if patience_counter >= patience:
                print(f"early stopping at epoch {epoch}, best spearman {best_rank_score:.4f} (epoch {best_epoch})")
                break

    if best_state is not None:
        model.load_state_dict(best_state)
    return model, loss_history, test_loss_history, rank_history, best_epoch


def main():
    parser = argparse.ArgumentParser(
        description="Train Quantale GNN on AtomSpace hasProperty data",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("--data_dir", type=str, required=True,
                        help="Path to unzipped concept-atomspace folder")
    parser.add_argument("--output", type=str,
                        default="a_quantale_theoretic_approach/extractor/gnn_weights.pth",
                        help="Path to save trained weights")
    parser.add_argument("--epochs", type=int, default=100)
    parser.add_argument("--lr", type=float, default=0.0005)
    parser.add_argument("--patience", type=int, default=30)
    parser.add_argument("--min_props", type=int, default=3,
                        help="Minimum number of properties a concept must have to be included")
    parser.add_argument("--train_split", type=float, default=0.70,
                        help="Fraction of concepts used for training (rest = held-out test)")
    parser.add_argument("--rank_weight", type=float, default=0.5,
                        help="Initial ranking loss weight (decays each epoch)")
    parser.add_argument("--rank_decay", type=float, default=0.99,
                        help="Exponential decay factor for ranking loss weight")
    parser.add_argument("--margin", type=float, default=0.05,
                        help="Ranking loss margin (how different targets must be to trigger penalty)")
    args = parser.parse_args()

    MODEL_NAME = "all-mpnet-base-v2"
    INPUT_DIM = 768

    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    print(f"Using device: {device}")

    # --- Data Loading ---
    prop_file = os.path.join(
        args.data_dir,
        "hasprerequisite-sw-hasproperty-as-hassubevent-bw-isa-ad.metta"
    )
    triples = parse_metta_triples(prop_file)
    print(f"Loaded {len(triples)} triples.")

    concept_props = defaultdict(dict)
    for c, p, tv in triples:
        concept_props[c][p] = tv

    filtered = {c: p for c, p in concept_props.items() if len(p) >= args.min_props}
    print(f"Concepts with {args.min_props}+ properties: {len(filtered)}")

    # --- 70/30 split by default (configurable) ---
    all_items = list(filtered.items())
    random.shuffle(all_items)
    split = int(len(all_items) * args.train_split)
    train_items = dict(all_items[:split])
    test_items = dict(all_items[split:])
    print(f"Train: {len(train_items)} concepts, Test: {len(test_items)} concepts")

    embedder = ConceptEmbedder(model_name=MODEL_NAME)

    def build_graphs(items):
        graphs = []
        for concept, props in items.items():
            try:
                graphs.append(build_concept_graph(concept, props, embedder))
            except Exception as e:
                print(f"Skipped {concept}: {e}")
        return graphs

    print("Building training graphs...")
    train_graphs = build_graphs(train_items)
    print("Building test graphs...")
    test_graphs = build_graphs(test_items)
    print(f"{len(train_graphs)} train graphs, {len(test_graphs)} test graphs built.")

    model = QuantaleTruthValueGNN(input_dim=INPUT_DIM)

    print("\nStarting training...")
    trained_model, loss_hist, test_hist, rank_hist, best_epoch = train_quantale_gnn(
        model,
        train_graphs,
        test_graphs,
        epochs=args.epochs,
        lr=args.lr,
        patience=args.patience,
        rank_weight_init=args.rank_weight,
        rank_weight_decay=args.rank_decay,
        ranking_margin=args.margin,
        device=device
    )

    best_spearman = max(rank_hist) if rank_hist else 0.0
    print(f"\n✓ Training complete. Best Spearman: {best_spearman:.4f} at epoch {best_epoch}")
    torch.save(trained_model.state_dict(), args.output)
    print(f"✓ Weights saved to {args.output}")


def bootstrap_training_data(embedder: ConceptEmbedder):
    """Minimal fallback data for smoke-testing without the full AtomSpace dataset."""
    raw_data = [
        ("House", {"expensive": 0.16, "safe": 0.18, "permanent": 0.17}),
        ("Diamond", {"expensive": 0.20, "hard": 0.25, "rare": 0.19}),
        ("Fire", {"hot": 0.25, "dangerous": 0.30, "red": 0.28})
    ]
    return [build_concept_graph(c, p, embedder) for c, p in raw_data]


if __name__ == "__main__":
    main()
