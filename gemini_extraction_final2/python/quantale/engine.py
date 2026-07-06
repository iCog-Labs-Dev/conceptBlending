"""
V-Quantale Engine — pure Python, no AI calls.

Implements the quantale operators over the combined InfoTheoretic +
Categoric data, producing one unified property per shared dimension.

A quantale (V, ⊗, ⊤) is a complete lattice with a monoid operation ⊗.
Here we use the unit interval [0,1] with:

  join(a, b)         = max(a, b)         — lattice join (least upper bound)
  product(a, b)      = a * b             — quantale tensor product
  residuation(a, b)  = b / a if a > 0    — right residual a ⊸ b

These are applied as follows per property:

  1. join(c1_centrality, c2_centrality)
         → unified_degree: the strongest presence of this property
           across either concept. This becomes the degree-N label.

  2. product(c1_confidence, c2_confidence)
         → propagated_confidence: how reliable the unified degree is.
           Filters weak properties via residuation threshold check.

  3. product(unified_degree, alg_spec.overall_confidence)
         → quantale_strength: the final scalar attached to the property
           in the output. Combines semantic centrality with algebraic
           grounding quality.

  4. residuation check: if quantale_strength < RESIDUATION_THRESHOLD,
         the property's WorldSpecSet is collapsed to empty () and its
         degree is capped at degree-5.
         (Mentor spec: optimality constraint over colimit structure.)

  5. WorldSpecSet merge: union of c1 and c2 WorldSpecs, deduplicated,
         ordered by how many of the top-N algebraic items reference
         those domains (approximated by frequency in sorts/ops/preds).

Mentor spec compliance:
  ✓ Confidence/strength values propagated
  ✓ Residuation filters weak/malformed properties
  ✓ Top-N ranking already applied upstream in categoric/extractor.py
  ✓ Quantale join/product/residuation over V-predicate structure
"""

from __future__ import annotations
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from dataclasses import dataclass, field
from info_theoretic.extractor import PropertyVector
from categoric.extractor import AlgSpec
from config import DEGREE_LABELS, RESIDUATION_THRESHOLD, WORLDSPEC_VOCAB


# ─── Output data model ────────────────────────────────────────────────────────

@dataclass
class QuantaleProperty:
    """
    One property in the final unified output.
    Produced by the quantale engine from one PropertyVector + one AlgSpec.
    """
    name: str
    world_specs: list[str]          # merged WorldSpecSet
    unified_degree: float           # join(c1, c2) centrality
    propagated_confidence: float    # product(c1_conf, c2_conf)
    quantale_strength: float        # product(unified_degree, alg_confidence)
    degree_label: str               # degree-1 … degree-5
    alg_spec: AlgSpec               # full algebraic grounding (for MeTTa output)
    filtered: bool = False          # True if residuation collapsed this property


@dataclass
class QuantaleBlend:
    """Final unified output for the concept pair."""
    concept1: str
    concept2: str
    blend_name: str
    properties: list[QuantaleProperty] = field(default_factory=list)


# ─── Quantale operators ───────────────────────────────────────────────────────

def join(a: float, b: float) -> float:
    """Lattice join — least upper bound on [0,1]."""
    return max(a, b)


def product(a: float, b: float) -> float:
    """Quantale tensor product on [0,1]."""
    return a * b


def residuation(a: float, b: float) -> float:
    """
    Right residual: largest x such that product(a, x) <= b.
    On the unit interval: b / a (clamped to [0,1]).
    """
    if a <= 0.0:
        return 1.0
    return min(1.0, b / a)


# ─── WorldSpecSet merger ──────────────────────────────────────────────────────

def _merge_world_specs(
    c1_ws: list[str],
    c2_ws: list[str],
    alg_spec: AlgSpec,
) -> list[str]:
    """
    Union of c1 and c2 WorldSpecs, ordered by relevance signal from
    the algebraic spec items (sorts/ops/preds mention domain keywords).
    """
    union = list(dict.fromkeys(c1_ws + c2_ws))  # dedup, preserve order

    # Score each WorldSpec by how many alg items contain a matching keyword
    all_items = alg_spec.sorts + alg_spec.ops + alg_spec.preds + alg_spec.axioms
    item_names = " ".join(i.item.lower() for i in all_items)

    def _alg_score(ws: str) -> float:
        keyword = ws.replace("WorldSpec-", "").lower()
        return sum(1 for word in item_names.split() if keyword in word)

    union.sort(key=_alg_score, reverse=True)
    return [w for w in union if w in WORLDSPEC_VOCAB]


# ─── Degree label ─────────────────────────────────────────────────────────────

def _degree_label(value: float) -> str:
    for (lo, hi), label in DEGREE_LABELS.items():
        if lo <= value < hi:
            return label
    return "degree-5"


# ─── Main quantale computation ────────────────────────────────────────────────

def compute(
    prop_vec: PropertyVector,
    alg_spec: AlgSpec,
) -> QuantaleProperty:
    """
    Apply quantale operators to one (PropertyVector, AlgSpec) pair,
    producing one unified QuantaleProperty.
    """
    # Step 1: join → unified degree
    unified = join(prop_vec.c1_centrality, prop_vec.c2_centrality)

    # Step 2: product → propagated confidence
    prop_conf = product(prop_vec.c1_confidence, prop_vec.c2_confidence)

    # Step 3: product → quantale strength
    alg_conf = alg_spec.overall_confidence
    strength = product(unified, alg_conf if alg_conf > 0 else unified)

    # Step 4: residuation check — optimality constraint
    filtered = strength < RESIDUATION_THRESHOLD

    # If filtered: collapse WorldSpecSet to empty, cap at degree-5
    if filtered:
        world_specs  = []
        degree_value = min(unified, 0.20)
        degree_lbl   = "degree-5"
    else:
        world_specs  = _merge_world_specs(
            prop_vec.c1_world_specs, prop_vec.c2_world_specs, alg_spec
        )
        degree_value = unified
        degree_lbl   = _degree_label(unified)

    return QuantaleProperty(
        name=prop_vec.name,
        world_specs=world_specs,
        unified_degree=round(degree_value, 4),
        propagated_confidence=round(prop_conf, 4),
        quantale_strength=round(strength, 4),
        degree_label=degree_lbl,
        alg_spec=alg_spec,
        filtered=filtered,
    )


def compute_blend(
    concept1: str,
    concept2: str,
    info: "InfoExtraction",        # noqa: F821
    alg_specs: list[AlgSpec],
) -> QuantaleBlend:
    """
    Apply the quantale engine across all 8 properties.
    Returns one QuantaleBlend — the single unified output.
    """
    blend_name = f"{concept1.replace(' ','')}{concept2.replace(' ','')}"

    properties = []
    for prop_vec, alg_spec in zip(info.properties, alg_specs):
        qprop = compute(prop_vec, alg_spec)
        properties.append(qprop)
        status = "FILTERED (residuation)" if qprop.filtered else "OK"
        print(f"   [Quantale] {qprop.name}: "
              f"join={qprop.unified_degree:.3f} "
              f"strength={qprop.quantale_strength:.3f} "
              f"→ {qprop.degree_label} [{status}]")

    return QuantaleBlend(
        concept1=concept1,
        concept2=concept2,
        blend_name=blend_name,
        properties=properties,
    )
