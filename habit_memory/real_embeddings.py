import math
import multiprocessing
import os
from pathlib import Path
import re
import sys


os.environ.setdefault("HF_HUB_OFFLINE", "1")
os.environ.setdefault("TRANSFORMERS_OFFLINE", "1")
os.environ.setdefault("TOKENIZERS_PARALLELISM", "false")

_DEPS_PATH = Path(__file__).with_name(".python_deps")
if _DEPS_PATH.exists():
    sys.path.insert(0, str(_DEPS_PATH))

_PYTHON_EXECUTABLE = Path(sys.exec_prefix) / "bin" / f"python{sys.version_info.major}.{sys.version_info.minor}"
if _PYTHON_EXECUTABLE.exists():
    multiprocessing.set_executable(str(_PYTHON_EXECUTABLE))

_MODEL_NAME = "all-MiniLM-L6-v2"
_MODEL = None
_MODEL_ERROR = None
_EMBEDDING_CACHE = {}


def _atom_to_text(value):
    text = str(value)
    text = re.sub(r"'([^']*)'", r"\1", text)
    text = text.strip()
    if text.startswith("[") and text.endswith("]"):
        text = text[1:-1].replace(",", " ")
    if text.startswith("(") and text.endswith(")"):
        text = text[1:-1].replace(",", " ")
    return " ".join(text.split())


def _embedding_text(value):
    return _atom_to_text(value).replace("_", " ").replace("-", " ")


def _cosine(vector_a, vector_b):
    dot = sum(a * b for a, b in zip(vector_a, vector_b))
    norm_a = math.sqrt(sum(a * a for a in vector_a))
    norm_b = math.sqrt(sum(b * b for b in vector_b))
    if norm_a == 0 or norm_b == 0:
        return 0.0
    return dot / (norm_a * norm_b)


def _load_sentence_model():
    global _MODEL, _MODEL_ERROR
    if _MODEL is not None:
        return _MODEL
    if _MODEL_ERROR is not None:
        raise RuntimeError(_MODEL_ERROR)

    try:
        from sentence_transformers import SentenceTransformer

        _MODEL = SentenceTransformer(_MODEL_NAME, local_files_only=True)
    except Exception as exc:
        _MODEL_ERROR = (
            f"{type(exc).__name__}: {exc}. "
            "Install sentence-transformers for PeTTa's embedded Python or make the model cache available."
        )
        _MODEL = None
        raise RuntimeError(_MODEL_ERROR) from exc
    return _MODEL


def _real_embedding(value):
    text = _embedding_text(value)
    if text in _EMBEDDING_CACHE:
        return _EMBEDDING_CACHE[text]

    model = _load_sentence_model()
    embedding = model.encode(text, convert_to_numpy=False)
    vector = [float(x) for x in embedding]
    _EMBEDDING_CACHE[text] = vector
    return vector


def provider_mode():
    return "sentence-transformers"


def provider_name():
    _load_sentence_model()
    return f"sentence-transformers:{_MODEL_NAME}"


def provider_error():
    try:
        _load_sentence_model()
    except RuntimeError:
        pass
    return _MODEL_ERROR or ""


def provider_status():
    return "error" if provider_error() else "ready"


def embedding_similarity(property_a, property_b):
    vector_a = _real_embedding(property_a)
    vector_b = _real_embedding(property_b)
    return float(_cosine(vector_a, vector_b))
