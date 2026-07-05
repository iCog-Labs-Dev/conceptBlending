"""
Stage 1 — Algebraic Spec Builder.

Mirrors: llm:generate-spec / algspec_builder.metta

Given two concept names and a context string, produces two algebraic
specifications in the iCog Labs format:

    (Concept X
     (spec
      (sorts ...)
      (ops ...)
      (preds ...)
      (axioms ...)
     )
    )
"""

from __future__ import annotations
from gemini_client import call_gemini
from prompts import build_spec_prompt


def generate_specs(
    concept1: str,
    concept2: str,
    context: str = "",
) -> tuple[str, str]:
    """
    Generate algebraic specifications for both concepts.

    Returns (spec_a, spec_b) as raw S-expression strings,
    ready to be added to the AtomSpace or passed to stage 2.
    """
    if not context:
        context = f"a comparison of {concept1} and {concept2}"

    prompt = build_spec_prompt(concept1, concept2, context)
    raw: str = call_gemini(prompt, expect_json=False)

    # Split the two (Concept ...) blocks
    spec_a, spec_b = _split_two_concepts(raw, concept1, concept2)

    print(f"[spec-builder] '{concept1}' spec: {len(spec_a)} chars")
    print(f"[spec-builder] '{concept2}' spec: {len(spec_b)} chars")
    return spec_a, spec_b


def _split_two_concepts(raw: str, concept1: str, concept2: str) -> tuple[str, str]:
    """
    Split the Gemini response into two (Concept ...) blocks.
    Finds the second (Concept token as the split point.
    """
    raw = raw.strip()
    c1_tag = f"(Concept {concept1.replace(' ', '')}"
    c2_tag = f"(Concept {concept2.replace(' ', '')}"

    idx = raw.find(c2_tag)
    if idx == -1:
        # Fallback: split on second occurrence of "(Concept "
        first = raw.find("(Concept ")
        second = raw.find("(Concept ", first + 1)
        if second == -1:
            return raw, ""
        return raw[:second].strip(), raw[second:].strip()

    return raw[:idx].strip(), raw[idx:].strip()
