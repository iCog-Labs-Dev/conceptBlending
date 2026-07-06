"""
Tests for the V-Quantale pipeline — deterministic logic only, no API calls.
"""

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "python"))

from utils import degree_label
from info_theoretic.extractor import _sanitize, _clamp, PropertyVector
from categoric.extractor import AlgItem, AlgSpec, _parse_section
from quantale.engine import join, product, residuation, compute, compute_blend
from quantale.encoder import encode_casl, encode_metta, encode_json


# ─── Utils ────────────────────────────────────────────────────────────────────
def test_degree_label():
    assert degree_label(0.95) == "degree-1"
    assert degree_label(0.70) == "degree-2"
    assert degree_label(0.50) == "degree-3"
    assert degree_label(0.35) == "degree-4"
    assert degree_label(0.10) == "degree-5"

def test_sanitize():
    assert _sanitize("call and response") == "call-and-response"
    assert _sanitize("") == "unnamed-property"
    assert _sanitize("rhythm!!") == "rhythm"

def test_clamp():
    assert _clamp(1.5) == 1.0
    assert _clamp(-0.5) == 0.0
    assert _clamp(0.7) == 0.7


# ─── Categoric ────────────────────────────────────────────────────────────────
def test_parse_section_filters_malformed():
    raw = [
        {"item": "FlyingObject", "relevance": 0.9, "confidence": 0.9},  # ok
        {"item": "",             "relevance": 0.9, "confidence": 0.9},  # empty name
        {"item": "WeakItem",     "relevance": 0.9, "confidence": 0.1},  # low confidence
    ]
    result = _parse_section(raw, 5)
    assert len(result) == 1
    assert result[0].item == "FlyingObject"

def test_parse_section_top_n():
    raw = [{"item": f"Item{i}", "relevance": i/10, "confidence": 0.9} for i in range(10)]
    result = _parse_section(raw, 3)
    assert len(result) == 3

def test_alg_item_strength():
    item = AlgItem("test", relevance=0.8, confidence=0.9)
    assert abs(item.strength - 0.72) < 0.001

def test_alg_spec_overall_confidence():
    spec = AlgSpec(
        property_name="flight",
        sorts=[AlgItem("Object", 0.8, 0.9)],
        ops=[AlgItem("fly", 0.7, 0.8)],
        preds=[], axioms=[],
    )
    assert spec.overall_confidence > 0


# ─── Quantale operators ───────────────────────────────────────────────────────
def test_join():
    assert join(0.3, 0.8) == 0.8
    assert join(0.9, 0.2) == 0.9

def test_product():
    assert abs(product(0.5, 0.8) - 0.4) < 0.001
    assert product(0.0, 0.9) == 0.0

def test_residuation():
    assert abs(residuation(0.5, 0.4) - 0.8) < 0.001
    assert residuation(0.0, 0.5) == 1.0   # a=0 edge case


# ─── Quantale compute ─────────────────────────────────────────────────────────
def _dummy_prop_vec(c1=0.9, c2=0.3, c1_conf=0.8, c2_conf=0.7):
    return PropertyVector(
        name="flight",
        c1_centrality=c1, c1_confidence=c1_conf, c1_world_specs=["WorldSpec-Biology"],
        c2_centrality=c2, c2_confidence=c2_conf, c2_world_specs=[],
    )

def _dummy_alg_spec():
    return AlgSpec(
        property_name="flight",
        sorts=[AlgItem("FlyingObject", 0.9, 0.9)],
        ops=[AlgItem("fly", 0.8, 0.8)],
        preds=[AlgItem("canFly", 0.7, 0.9)],
        axioms=[AlgItem("canFly(bird)", 0.6, 0.8)],
    )

def test_compute_join_is_max():
    prop = compute(_dummy_prop_vec(c1=0.9, c2=0.3), _dummy_alg_spec())
    assert prop.unified_degree == 0.9

def test_compute_product_propagates():
    prop = compute(_dummy_prop_vec(c1_conf=0.8, c2_conf=0.7), _dummy_alg_spec())
    assert abs(prop.propagated_confidence - 0.56) < 0.01

def test_compute_residuation_filters_weak():
    # Low confidence scores will produce a low strength → should be filtered
    prop = compute(
        _dummy_prop_vec(c1=0.1, c2=0.1, c1_conf=0.1, c2_conf=0.1),
        AlgSpec("weak", [], [], [], []),
    )
    assert prop.filtered is True
    assert prop.world_specs == []
    assert prop.degree_label == "degree-5"

def test_compute_strong_property_not_filtered():
    prop = compute(_dummy_prop_vec(c1=0.9, c2=0.8), _dummy_alg_spec())
    assert prop.filtered is False
    assert prop.degree_label == "degree-1"


# ─── Encoder ──────────────────────────────────────────────────────────────────
def _dummy_blend():
    from quantale.engine import QuantaleBlend, QuantaleProperty
    return QuantaleBlend(
        concept1="Bat", concept2="Man", blend_name="BatMan",
        properties=[
            QuantaleProperty(
                name="flight",
                world_specs=["WorldSpec-Biology", "WorldSpec-Physics"],
                unified_degree=0.9, propagated_confidence=0.56,
                quantale_strength=0.612, degree_label="degree-1",
                alg_spec=_dummy_alg_spec(), filtered=False,
            ),
            QuantaleProperty(
                name="abstract-force",
                world_specs=[],
                unified_degree=0.1, propagated_confidence=0.01,
                quantale_strength=0.01, degree_label="degree-5",
                alg_spec=AlgSpec("abstract-force"), filtered=True,
            ),
        ]
    )

def test_encode_casl_one_block():
    casl = encode_casl(_dummy_blend())
    assert casl.count("(Concept") == 1
    assert "(Concept BatMan" in casl
    assert "flight" in casl
    assert "quantale-strength" in casl
    assert "(WorldSpecSet ())" in casl      # filtered property

def test_encode_metta_has_quantale_atoms():
    metta = encode_metta(_dummy_blend())
    assert "(QuantaleStrength flight" in metta
    assert "(Filtered flight False)" in metta
    assert "(Filtered abstract-force True)" in metta

def test_encode_json_structure():
    data = encode_json(_dummy_blend())
    assert data["blend_name"] == "BatMan"
    assert len(data["V_predicate"]["Property"]) == 2
    assert "algebraic_spec" in data["V_predicate"]["Property"][0]


if __name__ == "__main__":
    test_degree_label()
    test_sanitize()
    test_clamp()
    test_parse_section_filters_malformed()
    test_parse_section_top_n()
    test_alg_item_strength()
    test_alg_spec_overall_confidence()
    test_join()
    test_product()
    test_residuation()
    test_compute_join_is_max()
    test_compute_product_propagates()
    test_compute_residuation_filters_weak()
    test_compute_strong_property_not_filtered()
    test_encode_casl_one_block()
    test_encode_metta_has_quantale_atoms()
    test_encode_json_structure()
    print(f"All {17} tests passed.")
