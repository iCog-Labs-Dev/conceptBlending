"""
Unit tests for deterministic logic only (no Gemini API calls).
"""

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "python"))

from extractor import _sanitize_name, _degree_label, PairExtraction, PropertyInstance
from casl_encoder import encode_pair, encode_pair_metta


def test_sanitize_name():
    assert _sanitize_name("call and response") == "call-and-response"
    assert _sanitize_name("") == "unnamed-property"
    assert _sanitize_name("rhythm!!") == "rhythm"


def test_degree_label_boundaries():
    assert _degree_label(0.95) == "degree-1"
    assert _degree_label(0.70) == "degree-2"
    assert _degree_label(0.50) == "degree-3"
    assert _degree_label(0.30) == "degree-4"
    assert _degree_label(0.05) == "degree-5"


def test_shared_property_names_across_concepts():
    """Both concepts in a pair must have identical property name lists."""
    extraction = PairExtraction(
        concept1="A", concept2="B",
        concept1_properties=[PropertyInstance("x", 0.9, [], "degree-1")],
        concept2_properties=[PropertyInstance("x", 0.1, [], "degree-5")],
    )
    names1 = [p.name for p in extraction.concept1_properties]
    names2 = [p.name for p in extraction.concept2_properties]
    assert names1 == names2


def test_encode_pair_produces_two_blocks():
    extraction = PairExtraction(
        concept1="Bat", concept2="Man",
        concept1_properties=[PropertyInstance("flight", 0.9, ["WorldSpec-Biology"], "degree-1")],
        concept2_properties=[PropertyInstance("flight", 0.0, [], "degree-5")],
    )
    casl1, casl2 = encode_pair(extraction)
    assert "(Concept Bat" in casl1
    assert "(Concept Man" in casl2
    assert "flight" in casl1 and "flight" in casl2
    assert "(WorldSpecSet ())" in casl2   # empty set for Man


def test_encode_pair_metta_links_shared_property():
    extraction = PairExtraction(
        concept1="Bat", concept2="Man",
        concept1_properties=[PropertyInstance("flight", 0.9, ["WorldSpec-Biology"], "degree-1")],
        concept2_properties=[PropertyInstance("flight", 0.0, [], "degree-5")],
    )
    metta = encode_pair_metta(extraction)
    assert "(SharedProperty flight Bat Man)" in metta


if __name__ == "__main__":
    test_sanitize_name()
    test_degree_label_boundaries()
    test_shared_property_names_across_concepts()
    test_encode_pair_produces_two_blocks()
    test_encode_pair_metta_links_shared_property()
    print("All tests passed.")
