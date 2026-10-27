from __future__ import annotations

import re
from dataclasses import dataclass

import torch
from sentence_transformers import SentenceTransformer

_URI_PREFIX = re.compile(r"^/c/[a-z]{2}/")


def clean_text(text: str) -> str:
    text = _URI_PREFIX.sub("", text)
    return text.replace("_", " ").replace("/", " ").strip()


class TextEmbedder:
    """Wraps SentenceTransformer to embed a single concept string.

    SentenceTransformer with normalize_embeddings=True produces the same
    768-d L2-normalised vectors as the training notebook's mean-pool pipeline
    for all-mpnet-base-v2.
    """

    def __init__(self, model_path: str):
        self.model = SentenceTransformer(model_path)

    def embed(self, text: str) -> torch.Tensor:
        vec = self.model.encode(
            clean_text(text),
            normalize_embeddings=True,
            convert_to_tensor=True,
            show_progress_bar=False,
        )
        return vec.float().cpu()


@dataclass
class MappedTriple:
    source_vec:  torch.Tensor
    target_vec:  torch.Tensor
    relation_id: int


class TripleMapper:
    """Maps a (source, relation, target) triple to embeddings and a relation id."""

    def __init__(self, embedder: TextEmbedder, rel_to_idx: dict[str, int], unk_id: int | None = None):
        self.embedder   = embedder
        self.rel_to_idx = rel_to_idx
        self.unk_id     = unk_id if unk_id is not None else max(rel_to_idx.values(), default=0) + 1

    def map_relation(self, relation: str) -> int:
        return self.rel_to_idx.get(relation.strip(), self.unk_id)

    def map_triple(self, source: str, relation: str, target: str) -> MappedTriple:
        return MappedTriple(
            source_vec=self.embedder.embed(source),
            target_vec=self.embedder.embed(target),
            relation_id=self.map_relation(relation),
        )
