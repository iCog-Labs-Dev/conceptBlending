"""
Registers Gemini-backed Python functions as MeTTa atoms.

Uses the EXACT same pattern as extensions.py:
  - @register_atoms decorator from hyperon.ext
  - OperationAtom with unwrap=False from hyperon.stdlib
  - Returns a dict mapping atom name strings to OperationAtom instances

This means gemini_atoms.py can be imported by MeTTa the same way
extensions.py is:
  !(import! &self gemini_extraction:python:gemini_atoms)

Registers:
  gemini:generate-spec  mirrors  llm:generate-spec
  gemini:generate-gen   mirrors  llm:generate-gen
  gemini:find-morph     mirrors  llm:find-morph
  gemini:colimit        mirrors  math:colimit
"""

import os
import sys
import time

from hyperon import *
from hyperon.ext import register_atoms
from hyperon.stdlib import ValueAtom, OperationAtom

# Ensure python/ is on path when called from MeTTa runtime
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.append(current_dir)

from spec_builder import generate_specs
from generalization_builder import find_generalization
from morphism_finder import find_morphism
from blend_colimit import compute_blend
from utils import atom_to_str as _atom_to_str, extract_concept_name as _extract_concept_name


# ─── Wrappers (same structure as py_generate_spec etc. in extensions.py) ─────

def py_gemini_generate_spec(c1_atom, c2_atom):
    """
    gemini:generate-spec
    Mirrors: llm:generate-spec ($c1 $context1) ($c2 $context2)

    Calls Gemini to generate algebraic specs for two concepts.
    Accepts the same (concept context) atom pairs as llm:generate-spec.
    """
    start_time = time.time()
    try:
        # Extract concept name from the atom pair, same as py_generate_spec does:
        # str(c1_atom).split()[0].replace('(', '')
        c1 = str(c1_atom).split()[0].replace('(', '').strip()
        c2 = str(c2_atom).split()[0].replace('(', '').strip()

        # Extract context from second element of the pair if present
        parts1 = str(c1_atom).split(None, 1)
        parts2 = str(c2_atom).split(None, 1)
        ctx1 = parts1[1].strip() if len(parts1) > 1 else ""
        ctx2 = parts2[1].strip() if len(parts2) > 1 else ""
        context = f"{ctx1} {ctx2}".strip()

        spec_a, spec_b = generate_specs(c1, c2, context)

        # Return as a list of two ValueAtoms, same return shape as
        # py_generate_spec which returns a list from prompt_agent
        return [ValueAtom(spec_a), ValueAtom(spec_b)]

    except Exception as e:
        print(f"   [gemini:generate-spec Error] {e}")
        return [ValueAtom(f'(Error "{str(e)}")')]
    finally:
        duration = time.time() - start_time
        print(f"   [gemini:generate-spec] completed in {duration:.2f}s")


def py_gemini_generate_gen(spec1_atom, spec2_atom):
    """
    gemini:generate-gen
    Mirrors: llm:generate-gen $specA $specB
    """
    start_time = time.time()
    try:
        result = find_generalization(_atom_to_str(spec1_atom), _atom_to_str(spec2_atom))
        return [ValueAtom(result)]
    except Exception as e:
        print(f"   [gemini:generate-gen Error] {e}")
        return [ValueAtom('(Error "Generalization Failed")')]
    finally:
        duration = time.time() - start_time
        print(f"   [gemini:generate-gen] completed in {duration:.2f}s")


def py_gemini_find_morph(spec_g, spec_target):
    """
    gemini:find-morph
    Mirrors: llm:find-morph $specG $specTarget

    Returns a ValueAtom containing the morphism S-expression string,
    same return shape as py_find_morphisms which returns [ValueAtom(result_string)].
    """
    print("   -> [Gemini] Finding Morphism (Mapping G -> Target)...")
    start_time = time.time()
    try:
        result = find_morphism(_atom_to_str(spec_g), _atom_to_str(spec_target))
        return [ValueAtom(result)]
    except Exception as e:
        print(f"   [gemini:find-morph Error] {e}")
        return [ValueAtom('(Error "Morphism Failed")')]
    finally:
        duration = time.time() - start_time
        print(f"   [gemini:find-morph] completed in {duration:.2f}s")


def py_gemini_colimit(spec_a, spec_b, spec_g, map_a_atom, map_b_atom):
    """
    gemini:colimit
    Mirrors: math:colimit $specA $specB $specG $mapA $mapB

    Unlike math:colimit which calls compute_colimit (a pure math engine
    that takes JSON morphism maps), this calls Gemini to compute the
    pushout linguistically from the S-expression morphisms, then encodes
    the result in CASL V-predicate / WorldSpecSet / degree-N format.

    Returns [ValueAtom(result)] matching math:colimit's return shape.
    """
    print("   -> [Gemini] Computing Colimit (Categorical Blend)...")
    try:
        sa = _atom_to_str(spec_a)
        sb = _atom_to_str(spec_b)
        sg = _atom_to_str(spec_g)
        ma = _atom_to_str(map_a_atom)
        mb = _atom_to_str(map_b_atom)

        c1 = _extract_concept_name(sa)
        c2 = _extract_concept_name(sb)

        result = compute_blend(c1, c2, sa, sb, sg, ma, mb)
        return [ValueAtom(result)]

    except Exception as e:
        print(f"   [gemini:colimit Error] {e}")
        return [ValueAtom(f'(Error "Colimit Failed: {e}")')]


# ─── Registration — exact same pattern as extensions.py ──────────────────────

@register_atoms
def gemini_operation_atoms():
    return {
        "gemini:generate-spec": OperationAtom(
            "gemini:generate-spec", py_gemini_generate_spec, unwrap=False
        ),
        "gemini:generate-gen":  OperationAtom(
            "gemini:generate-gen",  py_gemini_generate_gen,  unwrap=False
        ),
        "gemini:find-morph":    OperationAtom(
            "gemini:find-morph",    py_gemini_find_morph,    unwrap=False
        ),
        "gemini:colimit":       OperationAtom(
            "gemini:colimit",       py_gemini_colimit,       unwrap=False
        ),
    }


if "gemini_atoms_loaded" not in globals():
    print("DEBUG: gemini_atoms.py is loading/registering atoms...")
    globals()["gemini_atoms_loaded"] = True

    @register_atoms
    def register_gemini_atoms_wrapper():
        return gemini_operation_atoms()
