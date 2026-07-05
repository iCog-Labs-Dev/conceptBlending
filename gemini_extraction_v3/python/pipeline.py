"""
Gemini Master Pipeline.

Python equivalent of master_pipeline.metta, using Gemini-backed agents
in place of the llm: and math: atoms. Mirrors the exact four-stage
structure of the original:

    PHASE 1: generate_specs   (algspec_builder.metta / llm:generate-spec)
    PHASE 2: find_generalization (generalization_builder.metta / llm:generate-gen)
    PHASE 3: find_morphism x2 (morphism_finder.metta / llm:find-morph)
    PHASE 4: compute_blend    (math:colimit)

Terminal output: CASL V-predicate / WorldSpecSet / degree-N S-expression.

Usage:
    export GEMINI_API_KEY="your_key"
    python pipeline.py --concept1 house --concept2 boat
    python pipeline.py --concept1 "Solar Energy" --concept2 "Water Purification"
"""

from __future__ import annotations
import argparse
import os
import sys
import time

sys.path.insert(0, os.path.dirname(__file__))

from config import OUT_DIR
from spec_builder import generate_specs
from generalization_builder import find_generalization
from morphism_finder import find_morphism
from blend_colimit import compute_blend


def run(concept1: str, concept2: str, context: str = "") -> dict:
    os.makedirs(OUT_DIR, exist_ok=True)
    t0 = time.time()

    print("=" * 60)
    print(f" Gemini Conceptual Blending Pipeline")
    print(f" Concept 1 : {concept1}")
    print(f" Concept 2 : {concept2}")
    print("=" * 60)

    # ── PHASE 1: Algebraic Spec Generation ───────────────────────────────────
    print("\n>>> [PHASE 1] Generating Specifications...")
    spec_a, spec_b = generate_specs(concept1, concept2, context)

    print("\n; ================= SPEC A ===================")
    print(spec_a)
    print("\n; ================= SPEC B ===================")
    print(spec_b)
    print("; ---> Specs Generated.")

    # ── PHASE 2: Least Generalization ────────────────────────────────────────
    print("\n>>> [PHASE 2] Finding Shared Generalization (G)...")
    spec_g = find_generalization(spec_a, spec_b)

    print("\n; ================= GENERIC SPACE ===================")
    print(spec_g)
    print("; ---> Generalization Found.")

    # ── PHASE 3: Morphisms ────────────────────────────────────────────────────
    print("\n>>> [PHASE 3] Finding Morphisms (Mapping)...")
    morph_a = find_morphism(spec_g, spec_a)
    morph_b = find_morphism(spec_g, spec_b)

    print("\n; ================= MORPHISM G -> A ===================")
    print(morph_a)
    print("\n; ================= MORPHISM G -> B ===================")
    print(morph_b)
    print("; ---> Maps Acquired.")

    # ── PHASE 4: Compute Blend (Colimit) ──────────────────────────────────────
    print("\n>>> [PHASE 4] Computing Final Blend (Colimit)...")
    c1 = concept1.replace(" ", "")
    c2 = concept2.replace(" ", "")
    blend_name = f"{c1}{c2}Blend"
    blend = compute_blend(
        concept1=concept1, concept2=concept2,
        spec_a=spec_a, spec_b=spec_b, spec_g=spec_g,
        morph_a=morph_a, morph_b=morph_b,
        blend_name=blend_name,
    )

    print("\n; ===========================================")
    print(";         FINAL BLEND                       ")
    print("; ===========================================")
    print(blend)

    # ── Save outputs ──────────────────────────────────────────────────────────
    pair_id = f"{c1}_{c2}"
    _write(os.path.join(OUT_DIR, f"{pair_id}_spec_a.metta"),   spec_a)
    _write(os.path.join(OUT_DIR, f"{pair_id}_spec_b.metta"),   spec_b)
    _write(os.path.join(OUT_DIR, f"{pair_id}_generic.metta"),  spec_g)
    _write(os.path.join(OUT_DIR, f"{pair_id}_morph_a.metta"),  morph_a)
    _write(os.path.join(OUT_DIR, f"{pair_id}_morph_b.metta"),  morph_b)
    _write(os.path.join(OUT_DIR, f"{pair_id}_blend.casl"),     blend)

    elapsed = time.time() - t0
    print(f"\n>>> PIPELINE FINISHED in {elapsed:.1f}s")
    print(f"    Outputs saved to {OUT_DIR}/")

    return {
        "spec_a":   spec_a,
        "spec_b":   spec_b,
        "spec_g":   spec_g,
        "morph_a":  morph_a,
        "morph_b":  morph_b,
        "blend":    blend,
    }


def _write(path: str, content: str) -> None:
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"    wrote {os.path.basename(path)}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Gemini conceptual blending pipeline (mirrors master_pipeline.metta)"
    )
    parser.add_argument("--concept1", required=True, help="First concept, e.g. house")
    parser.add_argument("--concept2", required=True, help="Second concept, e.g. boat")
    parser.add_argument(
        "--context", default="",
        help="Optional seed context phrase to guide disambiguation"
    )
    args = parser.parse_args()
    run(args.concept1, args.concept2, args.context)
