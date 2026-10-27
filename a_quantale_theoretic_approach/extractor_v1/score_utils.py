from __future__ import annotations

from .engine import ScoreEngine


def truth_value(engine: ScoreEngine, source: str, relation: str, target: str) -> float:
    """Return the plausibility score for a single triple."""
    return engine.query(source, relation, target)


def score_all(engine: ScoreEngine, triples: dict[str, tuple[str, str, str]]) -> dict[str, float]:
    """Score every triple in the dict and return results keyed by the same names."""
    return {key: engine.query(*triple) for key, triple in triples.items()}


def score_ranked(
    engine: ScoreEngine,
    triples: dict[str, tuple[str, str, str]],
    ascending: bool = False,
) -> list[tuple[str, float]]:
    """Score all triples and return a list of (name, score) sorted by score."""
    results = score_all(engine, triples)
    return sorted(results.items(), key=lambda x: x[1], reverse=not ascending)


def print_scores(engine: ScoreEngine, triples: dict[str, tuple[str, str, str]]) -> None:
    """Print each triple with its score, aligned for easy reading."""
    results = score_all(engine, triples)
    width   = max(len(k) for k in results)
    for key, score in results.items():
        src, rel, tgt = triples[key]
        print(f"{key:<{width}}  {score:.4f}   ({src}, {rel}, {tgt})")
