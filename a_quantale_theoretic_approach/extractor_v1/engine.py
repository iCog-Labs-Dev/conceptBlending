from __future__ import annotations

import os
import warnings
from pathlib import Path

os.environ["HF_HUB_DISABLE_PROGRESS_BARS"] = "1"
os.environ["TRANSFORMERS_VERBOSITY"] = "error"
warnings.filterwarnings("ignore")

from .model_config import load_config, relation_map
from .model_extraction import build_model, load_weights, TripleScorer
from .sentence_embedder import TextEmbedder, TripleMapper

BASE_DIR     = Path(__file__).resolve().parent
WEIGHTS_PATH = str(BASE_DIR / "model_weights.pt")
REL_MAP_PATH = str(BASE_DIR / "rel2idx.json")
MPNET_PATH   = str("sentence-transformers/all-mpnet-base-v2")


class ScoreEngine:
    """Holds the loaded model and mapper so both are constructed once per process.

    Usage:
        engine = ScoreEngine()
        score  = engine.query("fire", "hasProperty", "hot")   # -> float in [0, 1]
    """

    def __init__(
        self,
        weights_path: str = WEIGHTS_PATH,
        rel_map_path: str = REL_MAP_PATH,
        mpnet_path: str = MPNET_PATH,
    ):
        config         = load_config(weights_path)
        self.model     = load_weights(build_model(config), weights_path)
        rel_to_idx     = relation_map(rel_map_path)
        unk_id         = max(rel_to_idx.values()) + 1
        self.mapper    = TripleMapper(TextEmbedder(mpnet_path), rel_to_idx, unk_id=unk_id)

    def query(self, source: str, relation: str, target: str) -> float:
        """Return a plausibility score in [0, 1] for (source, relation, target)."""
        triple = self.mapper.map_triple(source, relation, target)
        return self.model.score_pair(triple.source_vec, triple.target_vec, triple.relation_id)
