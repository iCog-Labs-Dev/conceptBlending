"""
Configuration for the gemini_extraction module.
Provides Gemini-backed alternatives to the existing llm: atoms.
"""

import os

GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
GEMINI_MODEL: str   = os.getenv("GEMINI_MODEL", "gemini-1.5-flash")
GEMINI_TEMPERATURE  = 0.2
GEMINI_MAX_TOKENS   = 8192

NUM_PROPERTIES: int = 8

# Fixed WorldSpec vocabulary — controlled ontology for WorldSpecSet fields.
WORLDSPEC_VOCAB: list[str] = [
    "WorldSpec-Physics",
    "WorldSpec-Chemistry",
    "WorldSpec-Biology",
    "WorldSpec-Ecology",
    "WorldSpec-Thermodynamics",
    "WorldSpec-Engineering",
    "WorldSpec-Mathematics",
    "WorldSpec-ComputerScience",
    "WorldSpec-Economics",
    "WorldSpec-SocialScience",
    "WorldSpec-Philosophy",
    "WorldSpec-Medicine",
    "WorldSpec-Agriculture",
    "WorldSpec-Energy",
    "WorldSpec-Materials",
    "WorldSpec-Information",
    "WorldSpec-Cognition",
    "WorldSpec-Linguistics",
]

# Degree bucketing: maps centrality float -> symbolic degree-N label
# matching the CASL V-predicate output format.
DEGREE_LABELS: dict = {
    (0.85, 1.01): "degree-1",
    (0.65, 0.85): "degree-2",
    (0.45, 0.65): "degree-3",
    (0.25, 0.45): "degree-4",
    (0.00, 0.25): "degree-5",
}

_ROOT    = os.path.dirname(os.path.dirname(__file__))
OUT_DIR  = os.path.join(_ROOT, "metta", "generated")
