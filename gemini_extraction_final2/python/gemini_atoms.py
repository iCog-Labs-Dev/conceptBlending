"""
Registers the unified V-Quantale pipeline as a single MeTTa atom.

  gemini:vq-blend  — runs full InfoTheoretic + Categoric + Quantale pipeline
                     returns one CASL V-predicate result atom

Matches extensions.py pattern exactly:
  @register_atoms, OperationAtom(unwrap=False), double-registration guard.
"""

import os, sys, time
from hyperon import *
from hyperon.ext import register_atoms
from hyperon.stdlib import ValueAtom, OperationAtom

current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.append(current_dir)

from utils import atom_to_str


def py_gemini_vq_blend(c1_atom, c2_atom):
    """
    gemini:vq-blend
    Full V-Quantale pipeline: InfoTheoretic + Categoric + Quantale → one output.
    MeTTa call: (gemini:vq-blend house boat)
    """
    start = time.time()
    try:
        from pipeline import run
        c1 = str(c1_atom).replace('(','').replace(')','').strip()
        c2 = str(c2_atom).replace('(','').replace(')','').strip()
        result = run(c1, c2)
        return [ValueAtom(result["casl"])]
    except Exception as e:
        print(f"   [gemini:vq-blend Error] {e}")
        return [ValueAtom(f'(Error "{str(e)}")')]
    finally:
        print(f"   [gemini:vq-blend] {time.time()-start:.2f}s")


@register_atoms
def gemini_vq_atoms():
    return {
        "gemini:vq-blend": OperationAtom(
            "gemini:vq-blend", py_gemini_vq_blend, unwrap=False
        ),
    }


if "gemini_vq_loaded" not in globals():
    print("DEBUG: gemini_atoms.py loading/registering atoms...")
    globals()["gemini_vq_loaded"] = True

    @register_atoms
    def register_gemini_vq_wrapper():
        return gemini_vq_atoms()
