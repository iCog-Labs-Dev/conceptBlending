# Quantale-Theoretic Conceptual Blending Implementation

## Overview

The **Quantale-Theoretic Conceptual Blending** project implements a mathematically grounded framework for conceptual representation and blending. Unlike traditional flat data models, this approach utilizes **Quantale theory** to integrate fuzzy linguistic truth values with symbolic structural axioms, creating a context-aware representation known as a **V-Predicate**.

Phase 1 focus: **Automated Concept Extraction**. This phase automates the ingestion of conceptual properties and the refinement of their truth values using Graph Neural Networks (GNNs) grounded in real-world Knowledge Graphs.

## Setup and Run

### 1. Install Dependencies
Ensure you have Python 3.8+ installed. Install the required libraries for graph processing and embeddings:

```bash
pip install torch sentence-transformers requests pytest torch-geometric --break-system-packages
```

### 2. Run the Extraction Demo
Execute the full pipeline (Concept Embedding → GNN Refinement → V-Predicate Assembly) to verify the extraction of real-world concepts:

```bash
python3 -m a_quantale_theoretic_approach.demo_pipeline
```

The output will display the generated **Product Quantales** for concepts like Art, Dice, and Fire:

```lisp
(= (VPredicate Art beautiful)      (ProductQuantale (Axiom_Default_Structural) 0.186))
(= (VPredicate Fire red)           (ProductQuantale (Axiom_Default_Structural) 0.284))
(= (VPredicate Dice cube)          (ProductQuantale (Axiom_Default_Structural) 0.291))
```

### 3. Verify Logical Consistency
Run the algebraic test suite to ensure that all extracted truth values adhere to Quantale axioms (residuation, commutativity, and ordering):

```bash
python3 -m pytest a_quantale_theoretic_approach/tests/test_truth_value_pipeline.py -v
```

---

## Technical Pipeline (Phase 1)

### 1. Semantic Grounding (`extractor/concept_extractor.py`)
- **Purpose**: Maps concepts and properties to a high-dimensional vector space.
- **Implementation**: Uses `all-mpnet-base-v2` (768-dim) sentence transformers to ensure context-aware property embeddings.

### 2. Truth-Value Refinement (`extractor/gnn_truth_value.py`)
- **Purpose**: Refines the statistical "strength" of properties using structural relations.
- **Implementation**: A 2-layer **Graph Attention Network (GAT)** trained on **ConceptNet** (AtomSpace) `hasProperty` triples with combined MSE + ranking loss.
- **Training details**: Spearman-rank checkpointing, ranking loss with exponential decay, 70/30 train/test split, cosine annealing LR.

### 3. Mathematical Alignment (`core_representation/`)
- **LogicQuantale**: Encodes the symbolic relation skeleton (e.g., *IsA*, *Partof*) into algebraic axioms.
- **TruthValueQuantale**: Ensures all numeric outputs satisfy the mathematical properties of a commutative residuated quantale.

---

## (Optional) Re-Training the GNN

The training script uses the shared `concept-atomspace` dataset. Point `--data_dir` to your local copy of the unzipped `concept-atomspace-pettav` folder:

```bash
python3 -m a_quantale_theoretic_approach.extractor.gnn_trainer \
    --data_dir /path/to/your/concept-atomspace-pettav
```

The trainer will automatically parse `hasProperty` triples, apply min-max normalization, build concept graphs, and train with Spearman-rank checkpointing.

### Available Hyperparameters

| Flag | Default | Description |
|---|---|---|
| `--epochs` | 100 | Maximum training epochs |
| `--lr` | 0.0005 | Learning rate |
| `--patience` | 30 | Early stopping patience (on Spearman) |
| `--min_props` | 3 | Minimum properties per concept |
| `--train_split` | 0.70 | Train/test split ratio |
| `--rank_weight` | 0.5 | Initial ranking loss weight |
| `--rank_decay` | 0.99 | Ranking loss exponential decay |
| `--margin` | 0.05 | Ranking loss margin |
| `--output` | `extractor/gnn_weights.pth` | Output weights path |

### Pre-Trained Weights
The current production weights (`extractor/gnn_weights.pth`) are loaded automatically by `demo_pipeline.py`. They were trained with Spearman correlation of **0.40** on 115 held-out concepts.
# Quantale-theoretic conceptual blending

The PeTTa entrypoint for the complete habit-biased hybrid search is
`a_quantale_theoretic_approach/main.metta`. Its real-input example parameters
are initialized near the end of the file. The example blends the real
`playing_hockey` and `surfing` functional-use concepts, whose shared properties
create a genuinely multi-objective population. Uncomment exactly one of the
two example calls and run it from the repository root:

```bash
GENERALIZATION_LLM_MODE=off \
GENERALIZATION_CACHE_MODE=on \
petta a_quantale_theoretic_approach/main.metta
```

SentenceTransformer embeddings are used for habit similarity when the optional
model is available. In a fully offline PeTTa environment, the same entrypoint
uses a deterministic lexical-similarity fallback instead of aborting.

The result is a compact `QuantaleBlendPipelineResult` containing completion and
initialization statuses plus only the nondominated candidates in the global
Pareto front. Each public `ParetoCandidate` carries its ID, blend/property
degrees, and four-value fitness vector; detailed objective evidence remains in
the internal candidate representation. Updated habit memory also stays inside
the hybrid-search lifecycle, where it is threaded into each consequent
generation, but is intentionally omitted from the public result. The internal
`HybridSearchLoopResult` still carries the final shared population, generation
trace, detailed candidates, and updated memory.
`InitializedQuantaleBlendPipelineRequest` resumes from a previously
materialized initialization result without repeating extraction,
generalization, or sampling.
