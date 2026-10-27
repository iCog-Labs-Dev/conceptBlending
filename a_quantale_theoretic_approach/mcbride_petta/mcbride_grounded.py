"""
Grounded Python atoms that expose McBrideOptimizer to MeTTa.
Follows the pattern used in op-constraints/op-helper-codes.py.
"""
from typing import Any
from hyperon import OperationAtom, ValueAtom
from a_quantale_theoretic_approach.optimization.macbride_derivative import (
    McBrideOptimizer,
    _natural_gradient_tv_step,
    emergence_tv,
    uniform_valuation,
)
from a_quantale_theoretic_approach.core_representation.v_predicate_parser import (
    parse_v_predicate_concept
)
from a_quantale_theoretic_approach.core_representation.v_predicate import (
    VPredicateConcept
)


def _concept_from_metta_atom(atom: Any) -> VPredicateConcept:
    """Parse a MeTTa atom's string representation into a VPredicateConcept."""
    return parse_v_predicate_concept(str(atom))


def mcbride_py_tv_step(current_tv_atom, deriv_tv_atom, eta_atom):
    """Natural gradient TV update step with Bernoulli variance & clamping."""
    try:
        current_tv = float(str(current_tv_atom))
        deriv_tv   = float(str(deriv_tv_atom))
        eta        = float(str(eta_atom))
    except Exception as exc:
        raise RuntimeError(
            f"mcbride-py-tv-step: failed to parse arguments — {exc}"
        ) from exc
    new_tv = _natural_gradient_tv_step(current_tv, deriv_tv, eta)
    return ValueAtom(new_tv)


def mcbride_py_abs_diff(a_atom, b_atom):
    """Absolute difference for convergence checks."""
    try:
        a = float(str(a_atom))
        b = float(str(b_atom))
    except Exception as exc:
        raise RuntimeError(
            f"mcbride-py-abs-diff: failed to parse arguments — {exc}"
        ) from exc
    return ValueAtom(abs(a - b))


def mcbride_py_refine(blend_atom, source_a_atom, source_b_atom, eta_atom, steps_atom):
    try:
        blend    = _concept_from_metta_atom(blend_atom)
        source_a = _concept_from_metta_atom(source_a_atom)
        source_b = _concept_from_metta_atom(source_b_atom)
        eta      = float(str(eta_atom))
        steps    = int(str(steps_atom))
    except Exception as exc:
        raise RuntimeError(
            f"mcbride-py-refine: failed to parse arguments — {exc}"
        ) from exc

    optimizer = McBrideOptimizer(
        source_a=source_a, source_b=source_b,
        eta=eta, max_steps=steps,
    )
    result = optimizer.refine(blend)
    return ValueAtom(result.refined_blend.to_metta())


def mcbride_py_emergence(blend_atom, source_a_atom, source_b_atom):
    try:
        blend    = _concept_from_metta_atom(blend_atom)
        source_a = _concept_from_metta_atom(source_a_atom)
        source_b = _concept_from_metta_atom(source_b_atom)
    except Exception as exc:
        raise RuntimeError(
            f"mcbride-py-emergence: failed to parse arguments — {exc}"
        ) from exc

    score = emergence_tv(source_a, source_b, blend, uniform_valuation)
    return ValueAtom(score)


def register_mcbride_atoms(metta_instance):
    """Call this once when setting up your MeTTa runtime."""
    metta_instance.register_atom(
        "mcbride-py-tv-step",
        OperationAtom("mcbride-py-tv-step", mcbride_py_tv_step, unwrap=False)
    )
    metta_instance.register_atom(
        "mcbride-py-abs-diff",
        OperationAtom("mcbride-py-abs-diff", mcbride_py_abs_diff, unwrap=False)
    )
    metta_instance.register_atom(
        "mcbride-py-refine",
        OperationAtom("mcbride-py-refine", mcbride_py_refine, unwrap=False)
    )
    metta_instance.register_atom(
        "mcbride-py-emergence",
        OperationAtom("mcbride-py-emergence", mcbride_py_emergence, unwrap=False)
    )
