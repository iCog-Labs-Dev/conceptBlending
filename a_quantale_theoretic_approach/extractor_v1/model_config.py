"""Architecture settings for the triple scorer, read from a saved checkpoint."""

from __future__ import annotations

from dataclasses import dataclass
import json

import torch


@dataclass
class ModelConfig:
    node_dim: int = 768
    hidden_dim: int = 128
    gat_heads_l1: int = 4
    gat_heads_l2: int = 4
    num_relations: int = 29      # 28 real + 1 UNK slot (id 28)
    dropout: float = 0.15

    @property
    def self_loop_id(self) -> int:
        """Relation id reserved for self-loops — one past the decoder vocab."""
        return self.num_relations

    @property
    def encoder_relations(self) -> int:
        """Total relation types seen by RGATConv: real + UNK + self-loop."""
        return self.num_relations + 1


def load_config(weights_path: str) -> ModelConfig:
    """Reads encoder/decoder shape settings embedded in model_weights.pt."""
    checkpoint = torch.load(weights_path, map_location="cpu", weights_only=False)
    raw = checkpoint.get("config", {})
    return ModelConfig(
        node_dim=raw.get("node_dim", 768),
        hidden_dim=raw.get("hidden_dim", 128),
        gat_heads_l1=raw.get("gat_heads_l1", 4),
        gat_heads_l2=raw.get("gat_heads_l2", 4),
        num_relations=raw.get("num_relations", 29),
    )


def relation_map(rel_map_path: str) -> dict[str, int]:
    """Loads the relation-string → relation-id vocabulary saved by the training notebook."""
    with open(rel_map_path, "r", encoding="utf-8") as f:
        return json.load(f)
