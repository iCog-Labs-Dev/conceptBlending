from __future__ import annotations

import os
import sys
from pathlib import Path
from typing import Any

_THIS_FILE = Path(__file__).resolve()
_DEFAULT_EXTRACTOR_V1_ROOT = _THIS_FILE.parents[3] / "extractor_v1"

_engine = None
_engine_load_error: Exception | None = None
_engine_attempted = False


def _extractor_v1_root() -> Path:
    override = os.environ.get("EXTRACTOR_V1_ROOT")
    return Path(override).expanduser().resolve() if override else _DEFAULT_EXTRACTOR_V1_ROOT


def _scorer_mode() -> str:
    mode = os.environ.get("EXTRACTOR_V1_SCORER_MODE", "auto").lower()
    if mode not in {"off", "auto", "on"}:
        raise ValueError("EXTRACTOR_V1_SCORER_MODE must be off, auto, or on")
    return mode


def _decimals() -> int:
    try:
        return max(0, int(os.environ.get("EXTRACTOR_V1_TV_DECIMALS", "4")))
    except ValueError:
        return 4


def _round(score: float) -> float:
    return round(float(score), _decimals())


def _load_engine():
    global _engine, _engine_load_error, _engine_attempted
    if _engine_attempted:
        return _engine
    _engine_attempted = True

    root = _extractor_v1_root()
    if not root.is_dir():
        _engine_load_error = FileNotFoundError(f"extractor_v1 directory not found: {root}")
        return None

    parent = str(root.parent)
    if parent not in sys.path:
        sys.path.insert(0, parent)

    try:
        from extractor_v1.engine import ScoreEngine
    except Exception as exc:
        _engine_load_error = exc
        return None

    kwargs: dict[str, str] = {
        "weights_path": str(root / "model_weights.pt"),
        "rel_map_path": str(root / "rel2idx.json"),
    }
    mpnet_override = os.environ.get("EXTRACTOR_V1_MPNET_PATH")
    if mpnet_override:
        kwargs["mpnet_path"] = mpnet_override

    try:
        _engine = ScoreEngine(**kwargs)
    except Exception as exc:
        _engine_load_error = exc
        _engine = None
    return _engine


def score_concept_triple(source: Any, relation: Any, target: Any) -> float:
    mode = _scorer_mode()
    if mode == "off":
        return 0.0
    engine = _load_engine()
    if engine is None:
        if mode == "on":
            raise RuntimeError(f"extractor_v1 required but failed to load: {_engine_load_error}")
        return 0.0
    try:
        return _round(engine.query(str(source), str(relation), str(target)))
    except Exception:
        return 0.0


def register_builtins() -> int:
    import builtins
    builtins.score_concept_triple = score_concept_triple
    return 0
