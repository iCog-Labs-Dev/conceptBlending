import torch
import torch.nn as nn
import torch.nn.functional as F
from torch_geometric.nn import GATConv

class QuantaleTruthValueGNN(nn.Module):
    """
    Graph Neural Network that refines truth values using Graph Attention (GAT).
    Architecture:
      - 2 Multi-head GAT layers for relational message passing.
      - MLP + Sigmoid head to project embeddings to [0, 1].
    """
    def __init__(self, input_dim: int = 768, hidden_dim: int = 256, heads: int = 4):
        super().__init__()
        
        # GAT Layer 1: Contextual information propagation
        self.gat1 = GATConv(
            in_channels=input_dim,
            out_channels=hidden_dim // heads,
            heads=heads,
            dropout=0.1,
            concat=True
        )
        
        # GAT Layer 2: Final embedding refinement
        self.gat2 = GATConv(
            in_channels=hidden_dim,
            out_channels=hidden_dim,
            heads=1,
            dropout=0.1,
            concat=False
        )
        
        # Output Head: Project to [0, 1] scalar
        self.truth_head = nn.Sequential(
            nn.Linear(hidden_dim, 64),
            nn.ReLU(),
            nn.Linear(64, 1),
            nn.Sigmoid() # Essential for TruthValueQuantale bounds
        )
        
        self.norm1 = nn.LayerNorm(hidden_dim)
        self.norm2 = nn.LayerNorm(hidden_dim)

    def forward(self, data):
        x, edge_index = data.x, data.edge_index
        
        # GAT Block 1
        x = self.gat1(x, edge_index)
        x = self.norm1(F.elu(x))
        
        # GAT Block 2
        x = self.gat2(x, edge_index)
        x = self.norm2(F.elu(x))
        
        # Prediction for all nodes
        scores = self.truth_head(x).squeeze(-1)
        return scores
