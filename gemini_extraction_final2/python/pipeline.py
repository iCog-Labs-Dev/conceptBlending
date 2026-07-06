"""
V-Quantale Master Pipeline.

Wires InfoTheoretic + Categoric + Quantale Engine into ONE output.

Flow:
  1. InfoTheoretic extracts 8 shared property dimensions
     (centrality + confidence + WorldSpecSet per concept per property)
  2. Categoric extracts algebraic grounding for each property
     (Sorts/Ops/Preds/Axioms ranked by relevance × confidence, top-5)
  3. Quantale engine merges both:
     - join(c1, c2) → unified degree
     - product(conf_c1, conf_c2) → propagated confidence
     - product(unified, alg_confidence) → quantale strength
     - residuation check → filters weak properties
     - WorldSpec merge ordered by alg relevance signal
  4. ONE unified CASL V-predicate output block

Usage:
    export GEMINI_API_KEY="your_key"
    python pipeline.py --concept1 "Bat" --concept2 "Man"
    python pipeline.py --concept1 "house" --concept2 "boat"
"""

from __future__ import annotations
import argparse
import json
import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor

sys.path.insert(0, os.path.dirname(__file__))

from config import OUT_DIR
from info_theoretic.extractor import extract, InfoExtraction
from categoric.extractor import extract_spec, AlgSpec
from quantale.engine import compute_blend
from quantale.encoder import encode_casl, encode_metta, encode_json


def run(concept1: str, concept2: str) -> dict:
    os.makedirs(OUT_DIR, exist_ok=True)
    t0 = time.time()

    print("=" * 60)
    print(f" V-Quantale Blending Pipeline")
    print(f" Concept 1 : {concept1}")
    print(f" Concept 2 : {concept2}")
    print("=" * 60)

    # ── Step 1: InfoTheoretic extraction ──────────────────────────────────────
    print(f"\n[Step 1] InfoTheoretic — extracting shared property dimensions...")
    info: InfoExtraction = extract(concept1, concept2)

    # ── Step 2: Categoric extraction (parallel across 8 properties) ───────────
    print(f"\n[Step 2] Categoric — extracting algebraic grounding per property...")
    print(f"         (running {len(info.properties)} properties in parallel)")

    def _get_spec(prop_vec):
        return extract_spec(concept1, concept2, prop_vec.name)

    with ThreadPoolExecutor(max_workers=4) as ex:
        alg_specs: list[AlgSpec] = list(ex.map(_get_spec, info.properties))

    # ── Step 3: Quantale engine ───────────────────────────────────────────────
    print(f"\n[Step 3] Quantale engine — join / product / residuation...")
    blend = compute_blend(concept1, concept2, info, alg_specs)

    # ── Step 4: Encode ONE unified output ─────────────────────────────────────
    print(f"\n[Step 4] Encoding unified V-predicate output...")
    casl_str  = encode_casl(blend)
    metta_str = encode_metta(blend)
    json_data = encode_json(blend)

    # ── Print ─────────────────────────────────────────────────────────────────
    print(f"\n{'=' * 60}")
    print(f" FINAL OUTPUT — {blend.blend_name}")
    print(f"{'=' * 60}")
    print(casl_str)

    # ── Save ──────────────────────────────────────────────────────────────────
    pair_id = blend.blend_name
    casl_path  = os.path.join(OUT_DIR, f"{pair_id}.casl")
    metta_path = os.path.join(OUT_DIR, f"{pair_id}.metta")
    json_path  = os.path.join(OUT_DIR, f"{pair_id}.json")

    with open(casl_path,  "w") as f: f.write(casl_str)
    with open(metta_path, "w") as f: f.write(metta_str)
    with open(json_path,  "w") as f: json.dump(json_data, f, indent=2)

    elapsed = time.time() - t0
    print(f"\n[Done] {elapsed:.1f}s — outputs saved to {OUT_DIR}/")
    print(f"  {pair_id}.casl")
    print(f"  {pair_id}.metta")
    print(f"  {pair_id}.json")

    return {"casl": casl_str, "metta": metta_str, "json": json_data, "blend": blend}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="V-Quantale pipeline: InfoTheoretic + Categoric → one output"
    )
    parser.add_argument("--concept1", required=True)
    parser.add_argument("--concept2", required=True)
    args = parser.parse_args()
    run(args.concept1, args.concept2)
