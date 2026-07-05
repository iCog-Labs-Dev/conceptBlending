"""
Unit tests for gemini_extraction_v3.

Tests only deterministic logic. No Gemini API calls.
"""

import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "python"))

from spec_builder import _split_two_concepts
from blend_colimit import compute_blend
from utils import extract_concept_name as _extract_concept_name


# ─── spec_builder ─────────────────────────────────────────────────────────────

def test_split_two_concepts_by_tag():
    raw = "(Concept House\n (spec (sorts (S)) )\n)\n(Concept Boat\n (spec (sorts (S)) )\n)"
    a, b = _split_two_concepts(raw, "House", "Boat")
    assert "(Concept House" in a
    assert "(Concept Boat" in b
    assert "(Concept Boat" not in a


def test_split_two_concepts_fallback():
    raw = "(Concept A (spec))\n(Concept B (spec))"
    a, b = _split_two_concepts(raw, "A", "B")
    assert "(Concept A" in a
    assert "(Concept B" in b


def test_split_returns_empty_if_only_one_block():
    raw = "(Concept House (spec))"
    a, b = _split_two_concepts(raw, "House", "Boat")
    assert "(Concept House" in a
    assert b == ""


# ─── gemini_atoms ─────────────────────────────────────────────────────────────

def test_extract_concept_name():
    spec = "(Concept House\n (spec (sorts (S))))"
    assert _extract_concept_name(spec) == "House"


def test_extract_concept_name_missing():
    assert _extract_concept_name("no concept here") == "Unknown"


# ─── pipeline structure ───────────────────────────────────────────────────────

def test_pipeline_module_imports():
    """All pipeline stages importable without API key."""
    from spec_builder import generate_specs
    from generalization_builder import find_generalization
    from morphism_finder import find_morphism
    from blend_colimit import compute_blend
    assert callable(generate_specs)
    assert callable(find_generalization)
    assert callable(find_morphism)
    assert callable(compute_blend)


if __name__ == "__main__":
    test_split_two_concepts_by_tag()
    test_split_two_concepts_fallback()
    test_split_returns_empty_if_only_one_block()
    test_extract_concept_name()
    test_extract_concept_name_missing()
    test_pipeline_module_imports()
    print("All tests passed.")
