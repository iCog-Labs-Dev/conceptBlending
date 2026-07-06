"""
Categoric Track — Algebraic Grounding.

For each shared property (from the InfoTheoretic track), extracts a
formal algebraic structure: Sorts, Ops, Preds, Axioms — with relevance
scores and confidence values per item.

Mentor spec:
  - Rank candidates by relevance
  - Propagate confidence/strength values
  - Limit each section to top TOP_N_PER_SECTION items
  - Validate: filter malformed or semantically weak items

This track does NOT blend. It provides algebraic grounding for each
property so the quantale engine has formal structure to work with.
"""

from __future__ import annotations
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from dataclasses import dataclass, field
from gemini_client import call_gemini
from config import TOP_N_PER_SECTION

_PROMPT = """You are an expert in algebraic specification (CASL style).

### Task
Given a shared property of two concepts, produce a formal algebraic
specification grounding that property. This is NOT a blend — it is
a structural description of what the property means algebraically
when applied to these two concepts together.

### Concepts: "{concept1}" and "{concept2}"
### Shared property: "{property_name}"
### Property description: "{description}"

For each algebraic element, assign:
- "item": the element name (short, formal)
- "relevance": float 0.0-1.0, how relevant this item is to the property
- "confidence": float 0.0-1.0, how confident the assignment is

Produce at least 6 candidates per section so the top-5 filter has room
to work. Malformed, vague, or semantically weak items should have low
confidence (below 0.3).

### Output — ONLY valid JSON:
{{
  "sorts":  [{{"item": "<name>", "relevance": <f>, "confidence": <f>}}, ...],
  "ops":    [{{"item": "<name>", "relevance": <f>, "confidence": <f>}}, ...],
  "preds":  [{{"item": "<name>", "relevance": <f>, "confidence": <f>}}, ...],
  "axioms": [{{"item": "<name>", "relevance": <f>, "confidence": <f>}}, ...]
}}
No markdown, no extra text.
"""


@dataclass
class AlgItem:
    """One algebraic element with relevance and confidence."""
    item: str
    relevance: float
    confidence: float

    @property
    def strength(self) -> float:
        """Combined strength = relevance * confidence (quantale product)."""
        return self.relevance * self.confidence


@dataclass
class AlgSpec:
    """Algebraic spec for one property, filtered to top-N per section."""
    property_name: str
    sorts:  list[AlgItem] = field(default_factory=list)
    ops:    list[AlgItem] = field(default_factory=list)
    preds:  list[AlgItem] = field(default_factory=list)
    axioms: list[AlgItem] = field(default_factory=list)

    @property
    def overall_confidence(self) -> float:
        """
        Mean strength across all sections.
        Used by quantale engine for product propagation.
        """
        all_items = self.sorts + self.ops + self.preds + self.axioms
        if not all_items:
            return 0.0
        return sum(i.strength for i in all_items) / len(all_items)


def _parse_section(raw_list: list[dict], top_n: int) -> list[AlgItem]:
    """
    Parse, validate, and rank a section.
    Mentor spec: filter malformed/weak, keep top TOP_N by strength.
    """
    items = []
    for entry in raw_list:
        name = str(entry.get("item", "")).strip()
        if not name or len(name) < 2:          # filter malformed
            continue
        relevance  = max(0.0, min(1.0, float(entry.get("relevance",  0.5))))
        confidence = max(0.0, min(1.0, float(entry.get("confidence", 0.5))))
        if confidence < 0.2:                   # filter semantically weak
            continue
        items.append(AlgItem(name, relevance, confidence))

    # Rank by strength (relevance * confidence) descending, keep top N
    items.sort(key=lambda x: x.strength, reverse=True)
    return items[:top_n]


def extract_spec(
    concept1: str,
    concept2: str,
    property_name: str,
    description: str = "",
) -> AlgSpec:
    """
    Extract algebraic grounding for one shared property.
    """
    prompt = _PROMPT.format(
        concept1=concept1, concept2=concept2,
        property_name=property_name, description=description or property_name,
    )
    raw: dict = call_gemini(prompt, expect_json=True)

    spec = AlgSpec(
        property_name=property_name,
        sorts  = _parse_section(raw.get("sorts",  []), TOP_N_PER_SECTION),
        ops    = _parse_section(raw.get("ops",    []), TOP_N_PER_SECTION),
        preds  = _parse_section(raw.get("preds",  []), TOP_N_PER_SECTION),
        axioms = _parse_section(raw.get("axioms", []), TOP_N_PER_SECTION),
    )

    print(f"   [Categoric] '{property_name}' → "
          f"sorts={len(spec.sorts)} ops={len(spec.ops)} "
          f"preds={len(spec.preds)} axioms={len(spec.axioms)} "
          f"confidence={spec.overall_confidence:.3f}")
    return spec
