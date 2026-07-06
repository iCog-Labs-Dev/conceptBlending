"""
InfoTheoretic Track — Property Extraction.

Extracts 8 shared property dimensions across both concepts.
Each property gets:
  - a shared name (same across both concepts)
  - per-concept centrality score (0.0-1.0)
  - per-concept WorldSpecSet
  - per-concept confidence score (0.0-1.0) — mentor spec: propagate confidence

This is the ONLY job of this track. No blending happens here.
The quantale engine consumes these scores downstream.
"""

from __future__ import annotations
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from dataclasses import dataclass, field
from gemini_client import call_gemini
from config import WORLDSPEC_VOCAB, NUM_PROPERTIES

_WS = "\n".join(f"  - {w}" for w in WORLDSPEC_VOCAB)

_PROMPT = """You are an expert in conceptual analysis and knowledge representation.

### Given Concepts
- Concept 1: "{concept1}"
- Concept 2: "{concept2}"

### Task
Extract exactly {num} properties that are MEANINGFULLY SHARED or COMPARABLE
between both concepts. The SAME property names apply to both concepts —
they are shared dimensions, not shared strengths.

For each property:
1. Give a shared hyphenated name
2. Score EACH concept's centrality on this property (0.0-1.0)
3. Score EACH concept's confidence in this property assignment (0.0-1.0)
   Confidence reflects how reliably this property characterizes the concept
   (high = definitional, low = speculative or context-dependent)
4. Select a WorldSpecSet for EACH concept from the allowed vocabulary

### Allowed WorldSpec vocabulary:
{ws}

### Output — ONLY valid JSON:
{{
  "properties": [
    {{
      "name": "<hyphenated-property-name>",
      "c1_centrality": <float 0.0-1.0>,
      "c1_confidence": <float 0.0-1.0>,
      "c1_world_specs": ["WorldSpec-X"],
      "c2_centrality": <float 0.0-1.0>,
      "c2_confidence": <float 0.0-1.0>,
      "c2_world_specs": ["WorldSpec-Y"]
    }}
  ]
}}
Exactly {num} property objects. No markdown, no extra text.
""".replace("{ws}", _WS)


@dataclass
class PropertyVector:
    """One shared property dimension with per-concept scores."""
    name: str
    c1_centrality: float
    c1_confidence: float
    c1_world_specs: list[str]
    c2_centrality: float
    c2_confidence: float
    c2_world_specs: list[str]


@dataclass
class InfoExtraction:
    concept1: str
    concept2: str
    properties: list[PropertyVector] = field(default_factory=list)


def _clean_ws(ws_list) -> list[str]:
    return [w for w in (ws_list or []) if w in WORLDSPEC_VOCAB]


def _clamp(v) -> float:
    try:
        return max(0.0, min(1.0, float(v)))
    except (TypeError, ValueError):
        return 0.5


def _sanitize(name: str) -> str:
    cleaned = name.strip().replace(" ", "-").replace("_", "-")
    cleaned = "".join(c for c in cleaned if c.isalnum() or c == "-")
    return cleaned or "unnamed-property"


def extract(concept1: str, concept2: str) -> InfoExtraction:
    """
    Single Gemini call: extract 8 shared property vectors for the pair.
    """
    prompt = _PROMPT.format(concept1=concept1, concept2=concept2, num=NUM_PROPERTIES)
    raw: dict = call_gemini(prompt, expect_json=True)

    props = []
    for p in raw.get("properties", [])[:NUM_PROPERTIES]:
        props.append(PropertyVector(
            name=_sanitize(p.get("name", "")),
            c1_centrality=_clamp(p.get("c1_centrality", 0.5)),
            c1_confidence=_clamp(p.get("c1_confidence", 0.5)),
            c1_world_specs=_clean_ws(p.get("c1_world_specs", [])),
            c2_centrality=_clamp(p.get("c2_centrality", 0.5)),
            c2_confidence=_clamp(p.get("c2_confidence", 0.5)),
            c2_world_specs=_clean_ws(p.get("c2_world_specs", [])),
        ))

    # Pad to NUM_PROPERTIES to keep downstream indexing safe
    while len(props) < NUM_PROPERTIES:
        i = len(props) + 1
        props.append(PropertyVector(
            name=f"unnamed-property-{i}",
            c1_centrality=0.1, c1_confidence=0.1, c1_world_specs=[],
            c2_centrality=0.1, c2_confidence=0.1, c2_world_specs=[],
        ))

    result = InfoExtraction(concept1=concept1, concept2=concept2, properties=props)
    print(f"[InfoTheoretic] '{concept1}' <-> '{concept2}' → {len(props)} shared properties")
    for p in props:
        print(f"   {p.name}: c1={p.c1_centrality:.2f}({p.c1_confidence:.2f}) "
              f"c2={p.c2_centrality:.2f}({p.c2_confidence:.2f})")
    return result
