"""
Shared utility helpers.
Importable without Hyperon — used by both gemini_atoms.py and tests.
"""

import re


def atom_to_str(atom) -> str:
    """
    Convert a MeTTa atom to a plain Python string.
    Strips outer quotes that MeTTa wraps around string values.
    """
    raw = str(atom).strip()
    if raw.startswith('"') and raw.endswith('"'):
        raw = raw[1:-1]
    return raw.replace('\\"', '"').replace('\\n', '\n')


def extract_concept_name(spec: str) -> str:
    """Pull the concept name from a (Concept Name ...) S-expression."""
    m = re.search(r"\(Concept\s+(\S+)", spec)
    return m.group(1) if m else "Unknown"
