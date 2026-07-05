"""
Stage 4 — Blend (Colimit).

Mirrors: math:colimit

Takes both algebraic specs, the generic space, and both morphisms,
and computes the categorical pushout (blend).

The output is the CASL V-predicate / WorldSpecSet / degree-N format
established at the start of this project:

    (Concept BlendName
      (V-predicate
        (Property

          (property-name
            (WorldSpecSet
              (WorldSpec-X
               WorldSpec-Y))
            degree-1)

          ...)))

This is the terminal output of the full categorical pipeline.
"""

from __future__ import annotations
from gemini_client import call_gemini
from prompts import build_blend_prompt


def compute_blend(
    concept1: str,
    concept2: str,
    spec_a: str,
    spec_b: str,
    spec_g: str,
    morph_a: str,
    morph_b: str,
    blend_name: str = "",
) -> str:
    """
    Compute the categorical colimit of the blending diagram and encode
    the result as a CASL V-predicate S-expression.

    Returns the full (Concept BlendName (V-predicate (Property ...)))
    string, which is the terminal output of the pipeline.
    """
    if not blend_name:
        c1 = concept1.replace(" ", "")
        c2 = concept2.replace(" ", "")
        blend_name = f"{c1}{c2}Blend"

    prompt = build_blend_prompt(
        concept1=concept1, concept2=concept2, blend_name=blend_name,
        spec_a=spec_a, spec_b=spec_b, spec_g=spec_g,
        morph_a=morph_a, morph_b=morph_b,
    )
    result: str = call_gemini(prompt, expect_json=False)
    result = result.strip()
    print(f"[colimit] blend '{blend_name}': {len(result)} chars")
    return result
