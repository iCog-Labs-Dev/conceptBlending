"""
Configuration for the Gemini-based concept extraction module.
"""

import os

GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-1.5-flash")
GEMINI_TEMPERATURE: float = 0.2
GEMINI_MAX_TOKENS: int = 8192

NUM_PROPERTIES: int = 8

# Fixed WorldSpec vocabulary, as established in the original CASL spec
# this module implements. Constrains agent output to a controlled ontology
# rather than letting WorldSpec names drift per run.
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

# Degree labels: symbolic degree-N tags, matching the original CASL spec's
# use of `degree-1`, `degree-2`, etc. as the value field, rather than a raw
# float. (gpt_vector's existing pipeline uses raw floats 0-1 instead;
# this module maps the same 0-1 relevance score onto degree-N labels
# to match the format specified for this PR.)
DEGREE_LABELS: dict = {
    (0.85, 1.01): "degree-1",
    (0.65, 0.85): "degree-2",
    (0.45, 0.65): "degree-3",
    (0.25, 0.45): "degree-4",
    (0.00, 0.25): "degree-5",
}

_ROOT = os.path.dirname(os.path.dirname(__file__))
OUTPUT_DIR: str = os.path.join(_ROOT, "metta", "generated")
