from __future__ import annotations

import torch
import torch.nn as nn
import torch.nn.functional as F
from torch_geometric.nn import RGATConv

from .model_config import ModelConfig


class GatEncoder(nn.Module):
    """Two stacked RGATConv layers with LayerNorm and a residual skip on layer 2."""

    def __init__(self, config: ModelConfig):
        super().__init__()
        self.conv1 = RGATConv(
            config.node_dim, config.hidden_dim // config.gat_heads_l1,
            config.encoder_relations, heads=config.gat_heads_l1,
            concat=True, dropout=config.dropout,
        )
        self.conv2 = RGATConv(
            config.hidden_dim, config.hidden_dim // config.gat_heads_l2,
            config.encoder_relations, heads=config.gat_heads_l2,
            concat=True, dropout=config.dropout,
        )
        self.activation = nn.GELU()
        self.dropout    = nn.Dropout(config.dropout)
        self.norm1      = nn.LayerNorm(config.hidden_dim)
        self.norm2      = nn.LayerNorm(config.hidden_dim)

    def forward(self, x: torch.Tensor, edge_index: torch.Tensor, edge_type: torch.Tensor) -> torch.Tensor:
        h1 = self.conv1(x, edge_index, edge_type)
        h1 = self.dropout(self.activation(self.norm1(h1)))
        h2 = self.norm2(self.conv2(h1, edge_index, edge_type)) + h1
        return h2


class CalibratedTranslationalDecoder(nn.Module):
    """TransE decoder with a per-relation additive cosine calibration term.

    logit = (gamma[r] - ||h_src + e_r - h_tgt||_2)
          + (cosine_weight[r] * cosine_similarity(h_src, h_tgt) + cosine_bias[r])
    score = sigmoid(logit)

    gamma, cosine_weight, cosine_bias are all trainable, one value per relation.
    """

    def __init__(self, config: ModelConfig):
        super().__init__()
        n = config.num_relations
        d = config.hidden_dim
        self.relation_translations = nn.Embedding(n, d)
        self.gamma         = nn.Parameter(torch.full((n,), 3.0))
        self.cosine_weight = nn.Parameter(torch.zeros(n))
        self.cosine_bias   = nn.Parameter(torch.zeros(n))

    def forward(self, h_source: torch.Tensor, relation_ids: torch.Tensor, h_target: torch.Tensor) -> torch.Tensor:
        e_r        = self.relation_translations(relation_ids)
        offset     = torch.norm((h_source + e_r) - h_target, p=2, dim=1)
        base_logit = self.gamma[relation_ids] - offset
        cos_sim    = F.cosine_similarity(h_source, h_target, dim=1)
        cal_logit  = self.cosine_weight[relation_ids] * cos_sim + self.cosine_bias[relation_ids]
        return torch.sigmoid(base_logit + cal_logit)


class TripleScorer(nn.Module):
    """Scores one (source, relation, target) triple from raw 768-d embedding vectors."""

    def __init__(self, config: ModelConfig):
        super().__init__()
        self.config  = config
        self.encoder = GatEncoder(config)
        self.decoder = CalibratedTranslationalDecoder(config)

    def score_pair(self, source_vec: torch.Tensor, target_vec: torch.Tensor, relation_id: int) -> float:
        with torch.no_grad():
            x_local    = torch.stack([source_vec, target_vec], dim=0)
            self_loop  = self.config.self_loop_id
            edge_index = torch.tensor([[1, 0, 0, 1], [0, 1, 0, 1]], dtype=torch.long)
            edge_type  = torch.tensor(
                [relation_id, relation_id, self_loop, self_loop], dtype=torch.long,
            )
            h_all      = self.encoder(x_local, edge_index, edge_type)
            rel_tensor = torch.tensor([relation_id], dtype=torch.long)
            score      = self.decoder(h_all[0:1], rel_tensor, h_all[1:2])
        return float(score.squeeze(0).item())


def build_model(config: ModelConfig) -> TripleScorer:
    return TripleScorer(config)


def load_weights(model: TripleScorer, weights_path: str) -> TripleScorer:
    """Loads checkpoint weights into model with strict key matching."""
    checkpoint = torch.load(weights_path, map_location="cpu", weights_only=False)
    model.load_state_dict(checkpoint["model_state_dict"], strict=True)
    model.eval()
    return model
