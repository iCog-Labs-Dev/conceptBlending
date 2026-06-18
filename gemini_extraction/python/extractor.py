"""
Extraction agent: concept pair -> shared property dimensions, with
per-concept centrality and WorldSpecSet.

Mirrors gpt_vector's design: ONE extraction call covers BOTH concepts,
so the resulting property names are guaranteed identical across the pair
(only centrality/WorldSpecSet differ per concept), making the two
concepts directly comparable for later blending.
"""

from __future__ import annotations
from dataclasses import dataclass

from prompts import build_prompt
from gemini_client import call_gemini
from config import WORLDSPEC_VOCAB, NUM_PROPERTIES, DEGREE_LABELS


@dataclass
class PropertyInstance:
    """One property as it applies to a single concept."""
    name: str
    centrality: float
    world_specs: list[str]
    degree_label: str


@dataclass
class PairExtraction:
    """Result of extracting shared properties for a concept pair."""
    concept1: str
    concept2: str
    concept1_properties: list[PropertyInstance]
    concept2_properties: list[PropertyInstance]


def _sanitize_name(raw: str) -> str:
    cleaned = raw.strip().replace(" ", "-").replace("_", "-")
    cleaned = "".join(c for c in cleaned if c.isalnum() or c == "-")
    return cleaned or "unnamed-property"


def _clean_world_specs(ws_list) -> list[str]:
    if not isinstance(ws_list, list):
        return []
    return [w for w in ws_list if w in WORLDSPEC_VOCAB]


def _degree_label(centrality: float) -> str:
    for (lo, hi), label in DEGREE_LABELS.items():
        if lo <= centrality < hi:
            return label
    return "degree-5"


def extract_pair(concept1: str, concept2: str) -> PairExtraction:
    """
    Run a single Gemini call to extract shared properties for both concepts.
    """
    prompt = build_prompt(concept1, concept2)
    raw: dict = call_gemini(prompt, expect_json=True)

    raw_props = raw.get("properties", [])[:NUM_PROPERTIES]

    c1_props: list[PropertyInstance] = []
    c2_props: list[PropertyInstance] = []

    for p in raw_props:
        name = _sanitize_name(p.get("name", ""))

        c1_centrality = max(0.0, min(1.0, float(p.get("concept1_centrality", 0.0))))
        c2_centrality = max(0.0, min(1.0, float(p.get("concept2_centrality", 0.0))))

        c1_ws = _clean_world_specs(p.get("concept1_world_specs", []))
        c2_ws = _clean_world_specs(p.get("concept2_world_specs", []))

        c1_props.append(PropertyInstance(
            name=name, centrality=c1_centrality, world_specs=c1_ws,
            degree_label=_degree_label(c1_centrality),
        ))
        c2_props.append(PropertyInstance(
            name=name, centrality=c2_centrality, world_specs=c2_ws,
            degree_label=_degree_label(c2_centrality),
        ))

    # Pad if fewer than NUM_PROPERTIES were returned, keeping names aligned
    # across both concepts so the shared-property invariant always holds.
    while len(c1_props) < NUM_PROPERTIES:
        idx = len(c1_props) + 1
        fallback_name = f"unnamed-property-{idx}"
        c1_props.append(PropertyInstance(fallback_name, 0.0, [], "degree-5"))
        c2_props.append(PropertyInstance(fallback_name, 0.0, [], "degree-5"))

    result = PairExtraction(
        concept1=concept1, concept2=concept2,
        concept1_properties=c1_props, concept2_properties=c2_props,
    )

    print(f"[extractor] '{concept1}' <-> '{concept2}' -> {len(c1_props)} shared properties")
    for p1, p2 in zip(c1_props, c2_props):
        ws1 = ", ".join(p1.world_specs) if p1.world_specs else "(empty)"
        ws2 = ", ".join(p2.world_specs) if p2.world_specs else "(empty)"
        print(f"   {p1.name}:")
        print(f"      {concept1}: {p1.degree_label} ({p1.centrality:.2f}) | {ws1}")
        print(f"      {concept2}: {p2.degree_label} ({p2.centrality:.2f}) | {ws2}")

    return result
