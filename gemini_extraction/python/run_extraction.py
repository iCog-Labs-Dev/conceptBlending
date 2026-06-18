"""
Entry point: extract a shared-property pair via Gemini, emit CASL + .metta.

Usage:
    export GEMINI_API_KEY="your_key"
    python run_extraction.py --concept1 "Bat" --concept2 "Man"

Output:
    metta/generated/Concept1_Concept2.casl   (both CASL blocks)
    metta/generated/Concept1_Concept2.metta  (MeTTa atoms, shared-property linked)
"""

from __future__ import annotations
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

from config import OUTPUT_DIR
from extractor import extract_pair
from casl_encoder import encode_pair, encode_pair_metta


def run(concept1: str, concept2: str) -> None:
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print(f"Extracting shared properties for '{concept1}' <-> '{concept2}' via Gemini...\n")
    extraction = extract_pair(concept1, concept2)

    casl1, casl2 = encode_pair(extraction)
    metta_str = encode_pair_metta(extraction)

    pair_id = f"{concept1.replace(' ', '_')}_{concept2.replace(' ', '_')}"
    casl_path = os.path.join(OUTPUT_DIR, f"{pair_id}.casl")
    metta_path = os.path.join(OUTPUT_DIR, f"{pair_id}.metta")

    with open(casl_path, "w") as f:
        f.write(f"; {concept1}\n{casl1}\n\n; {concept2}\n{casl2}\n")
    with open(metta_path, "w") as f:
        f.write(metta_str)

    print(f"\n{'-'*60}\nCASL -- {concept1}\n{'-'*60}")
    print(casl1)
    print(f"\n{'-'*60}\nCASL -- {concept2}\n{'-'*60}")
    print(casl2)

    print(f"\nDone. Output written to:\n  {casl_path}\n  {metta_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Gemini-based shared-property extraction -> CASL + .metta"
    )
    parser.add_argument("--concept1", required=True)
    parser.add_argument("--concept2", required=True)
    args = parser.parse_args()
    run(args.concept1, args.concept2)
