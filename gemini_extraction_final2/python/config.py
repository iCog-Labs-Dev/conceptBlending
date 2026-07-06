"""
Shared configuration for the unified V-quantale blending pipeline.
"""

import os

GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
GEMINI_MODEL: str   = os.getenv("GEMINI_MODEL", "gemini-1.5-flash")
GEMINI_TEMPERATURE  = 0.2
GEMINI_MAX_TOKENS   = 8192

NUM_PROPERTIES: int = 8
TOP_N_PER_SECTION: int = 5      # mentor spec: limit each section to top 5

WORLDSPEC_VOCAB: list[str] = [
    "WorldSpec-Physics",       "WorldSpec-Chemistry",
    "WorldSpec-Biology",       "WorldSpec-Ecology",
    "WorldSpec-Thermodynamics","WorldSpec-Engineering",
    "WorldSpec-Mathematics",   "WorldSpec-ComputerScience",
    "WorldSpec-Economics",     "WorldSpec-SocialScience",
    "WorldSpec-Philosophy",    "WorldSpec-Medicine",
    "WorldSpec-Agriculture",   "WorldSpec-Energy",
    "WorldSpec-Materials",     "WorldSpec-Information",
    "WorldSpec-Cognition",     "WorldSpec-Linguistics",
]

# Degree bucketing: quantale join value -> symbolic degree-N label
DEGREE_LABELS: dict = {
    (0.85, 1.01): "degree-1",
    (0.65, 0.85): "degree-2",
    (0.45, 0.65): "degree-3",
    (0.25, 0.45): "degree-4",
    (0.00, 0.25): "degree-5",
}

# Quantale residuation threshold:
# properties whose quantale strength falls below this are filtered out
# and replaced with an abstract/empty-WorldSpecSet fallback.
RESIDUATION_THRESHOLD: float = 0.15

_ROOT   = os.path.dirname(os.path.dirname(__file__))
OUT_DIR = os.path.join(_ROOT, "metta", "generated")
