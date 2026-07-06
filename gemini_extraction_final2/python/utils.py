"""Shared utility helpers — importable without Hyperon."""

import re

def atom_to_str(atom) -> str:
    raw = str(atom).strip()
    if raw.startswith('"') and raw.endswith('"'):
        raw = raw[1:-1]
    return raw.replace('\\"', '"').replace('\\n', '\n')

def extract_concept_name(spec: str) -> str:
    m = re.search(r"\(Concept\s+(\S+)", spec)
    return m.group(1) if m else "Unknown"

def degree_label(value: float) -> str:
    from config import DEGREE_LABELS
    for (lo, hi), label in DEGREE_LABELS.items():
        if lo <= value < hi:
            return label
    return "degree-5"
