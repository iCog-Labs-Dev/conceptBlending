"""
Stage 2 — Generalization Builder.

Mirrors: llm:generate-gen / generalization_builder.metta

Finds the least common generalization of two algebraic specs --
the generic space (colimit base) in category-theoretic terms.

Returns one (Concept GenericSpace (spec ...)) S-expression.
"""

from __future__ import annotations
from gemini_client import call_gemini
from prompts import build_gen_prompt


def find_generalization(spec_a: str, spec_b: str) -> str:
    """
    Given two algebraic spec strings, return the least generalization
    as a single (Concept GenericSpace ...) S-expression string.
    """
    prompt = build_gen_prompt(spec_a, spec_b)
    result: str = call_gemini(prompt, expect_json=False)
    result = result.strip()
    print(f"[generalization] generic space: {len(result)} chars")
    return result
