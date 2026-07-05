"""
Stage 3 — Morphism Finder.

Mirrors: llm:find-morph / morphism_finder.metta

Maps the generic space into a target spec.
Called twice per blend: once for spec_a, once for spec_b.

Returns a (Morphism (maps-to ...) ...) S-expression string.
"""

from __future__ import annotations
from gemini_client import call_gemini
from prompts import build_morph_prompt


def find_morphism(spec_g: str, spec_target: str) -> str:
    """
    Find the structure-preserving morphism from generic space G
    into the target spec.

    Returns the morphism as a raw S-expression string.
    """
    prompt = build_morph_prompt(spec_g, spec_target)
    result: str = call_gemini(prompt, expect_json=False)
    result = result.strip()
    print(f"[morphism-finder] morphism: {len(result)} chars")
    return result
