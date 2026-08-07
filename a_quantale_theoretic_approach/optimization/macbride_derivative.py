"""
McBride Derivatives for Blend Optimization.

Implements Section 7 of Goertzel (2026):
  "Quantale Weakness Based Conceptual Blending"
"""

from __future__ import annotations
from dataclasses import dataclass
from typing import Callable, Optional
import copy

from a_quantale_theoretic_approach.core_representation.product_quantale import ProductQuantale
from a_quantale_theoretic_approach.core_representation.v_predicate import VPredicateConcept
from a_quantale_theoretic_approach.structural_reasoning.quantale_colimit_engine import QuantaleColimitResult

ValuationFn = Callable[[str, tuple[str, ...]], ProductQuantale]

def uniform_valuation(prop_name: str, universe: tuple[str, ...]) -> ProductQuantale:
    """φ(p) = unit for all p. Treats all properties as equally salient."""
    return ProductQuantale.unit(universe)

def tv_proportional_valuation(
    prop_name: str,
    universe: tuple[str, ...],
    concept: VPredicateConcept,
) -> ProductQuantale:
    """φ(p) = mC(p) itself — the concept's own TV is its salience."""
    entry = concept.entries.get(prop_name)
    if entry is None:
        return ProductQuantale.bottom(universe)
    return entry.quantale

def habit_weighted_valuation(
    prop_name: str,
    universe: tuple[str, ...],
    habit_scores: dict[str, float],
) -> ProductQuantale:
    """φ(p) = habit strength of property p. TV is the habit score; logic is universal."""
    score = max(0.0, min(1.0, habit_scores.get(prop_name, 0.5)))
    unit = ProductQuantale.unit(universe)
    return ProductQuantale(unit.logic, type(unit.tv)(score))

def weakness(concept: VPredicateConcept, valuation: ValuationFn) -> ProductQuantale:
    """w(C) = ⊕_{p ∈ Props} φ(p) ⊗ mC(p)"""
    if not concept.entries:
        return ProductQuantale.bottom(concept.universal_set)
    return concept.weakness(lambda p: valuation(p, concept.universal_set))

def pattern_intensity(
    source: VPredicateConcept,
    blend: VPredicateConcept,
    valuation: ValuationFn,
) -> ProductQuantale:
    """I_A(C) = w(A) ⇒ w(C)"""
    w_source = weakness(source, valuation)
    w_blend  = weakness(blend,  valuation)
    return w_source >> w_blend

def joint_pattern_intensity(
    source_a: VPredicateConcept,
    source_b: VPredicateConcept,
    blend: VPredicateConcept,
    valuation: ValuationFn,
) -> ProductQuantale:
    """I_{A,B}(C) = (w(A) ⊗ w(B)) ⇒ w(C)"""
    w_a    = weakness(source_a, valuation)
    w_b    = weakness(source_b, valuation)
    w_both = w_a * w_b
    w_c    = weakness(blend, valuation)
    return w_both >> w_c

def emergence(
    source_a: VPredicateConcept,
    source_b: VPredicateConcept,
    blend: VPredicateConcept,
    valuation: ValuationFn,
) -> ProductQuantale:
    """σ_{A,B}(C) = (I_A(C) ⊗ I_B(C)) ⇒ I_{A,B}(C)"""
    ia  = pattern_intensity(source_a, blend, valuation)
    ib  = pattern_intensity(source_b, blend, valuation)
    iab = joint_pattern_intensity(source_a, source_b, blend, valuation)
    return (ia * ib) >> iab

def emergence_tv(
    source_a: VPredicateConcept,
    source_b: VPredicateConcept,
    blend: VPredicateConcept,
    valuation: ValuationFn,
) -> float:
    return emergence(source_a, source_b, blend, valuation).tv.value

def mcbride_derivative(
    prop_name: str,
    source_a: VPredicateConcept,
    source_b: VPredicateConcept,
    blend: VPredicateConcept,
    valuation: ValuationFn,
) -> ProductQuantale:
    """∂_p σ_{A,B}(C) = (I_A ⊗ I_B) ⇒ ((w(A) ⊗ w(B)) ⇒ φ(p))"""
    universe = blend.universal_set
    ia  = pattern_intensity(source_a, blend, valuation)
    ib  = pattern_intensity(source_b, blend, valuation)
    ia_ib = ia * ib

    w_a   = weakness(source_a, valuation)
    w_b   = weakness(source_b, valuation)
    w_a_b = w_a * w_b

    phi_p = valuation(prop_name, universe)
    inner = w_a_b >> phi_p

    return ia_ib >> inner

def _natural_gradient_tv_step(
    current_tv: float,
    derivative_tv: float,
    eta: float,
) -> float:
    """
    deg^(t+1)(p,C) = deg^(t) + η · deg · (1-deg) · ∂^tv_p σ   [Eq. 53]

    The Bernoulli variance factor deg·(1-deg) naturally shrinks steps
    near the boundaries [0,1]. A small rescue floor prevents permanent
    stall when TV rounds to 0.0 in float32.
    """
    variance = current_tv * (1.0 - current_tv)

    # Rescue floor only: prevents permanent stall when TV ≈ 0.
    # Does NOT apply near the upper boundary — high-TV properties slow naturally.
    if variance < 1e-6:
        variance = 1e-6

    step = eta * variance * derivative_tv
    return max(0.10, min(0.99, current_tv + step))

def apply_gradient_step(
    blend: VPredicateConcept,
    source_a: VPredicateConcept,
    source_b: VPredicateConcept,
    valuation: ValuationFn,
    eta: float = 0.05,
) -> VPredicateConcept:
    universe = blend.universal_set
    updated = VPredicateConcept(blend.name, universal_set=universe)

    for prop_name, entry in blend.entries.items():
        deriv = mcbride_derivative(prop_name, source_a, source_b, blend, valuation)

        new_tv = _natural_gradient_tv_step(
            current_tv=entry.quantale.tv.value,
            derivative_tv=deriv.tv.value,
            eta=eta,
        )

        new_logic = entry.quantale.logic + deriv.logic
        new_quantale = ProductQuantale(new_logic, type(entry.quantale.tv)(new_tv))

        updated.add_property(
            prop_name,
            new_quantale,
            source=entry.source,
            extraction_method="mcbride_refinement",
            confidence=entry.confidence,
        )

    return updated

@dataclass
class McBrideRefinementResult:
    initial_blend: VPredicateConcept
    refined_blend: VPredicateConcept
    source_a: VPredicateConcept
    source_b: VPredicateConcept
    emergence_history: list[float]
    property_tv_history: dict[str, list[float]]
    converged: bool
    steps_taken: int

    @property
    def emergence_gain(self) -> float:
        if len(self.emergence_history) < 2:
            return 0.0
        return self.emergence_history[-1] - self.emergence_history[0]

    def summary(self) -> str:
        return (
            f"McBride Refinement: {self.steps_taken} steps, "
            f"converged={self.converged}\n"
            f"  Emergence: {self.emergence_history[0]:.4f} → "
            f"{self.emergence_history[-1]:.4f} "
            f"(+{self.emergence_gain:.4f})\n"
            f"  Properties refined: {len(self.property_tv_history)}"
        )

    def to_metta(self) -> str:
        return self.refined_blend.to_metta()

class McBrideOptimizer:
    def __init__(
        self,
        source_a: VPredicateConcept,
        source_b: VPredicateConcept,
        valuation: Optional[ValuationFn] = None,
        eta: float = 0.05,
        max_steps: int = 20,
        convergence_threshold: float = 1e-4,
        patience: int = 5,
        adaptive_eta: bool = True,
    ):
        self.source_a = source_a
        self.source_b = source_b
        self.valuation = valuation or uniform_valuation
        self.eta = eta
        self.max_steps = max_steps
        self.convergence_threshold = convergence_threshold
        self.patience = patience
        self.adaptive_eta = adaptive_eta

    @classmethod
    def from_colimit_result(
        cls,
        colimit_result: QuantaleColimitResult,
        source_a: VPredicateConcept,
        source_b: VPredicateConcept,
        **kwargs,
    ) -> McBrideOptimizer:
        # colimit_result is accepted for API symmetry but not currently used.
        # Future: extract blend universe or initial synergy metrics from it.
        return cls(source_a=source_a, source_b=source_b, **kwargs)

    def refine(
        self,
        initial_blend: VPredicateConcept,
    ) -> McBrideRefinementResult:
        current_blend = copy.deepcopy(initial_blend)
        current_eta   = self.eta

        emergence_history = []
        property_tv_history = {p: [] for p in initial_blend.entries}
        no_improvement_count = 0
        converged = False

        sigma_prev = emergence_tv(self.source_a, self.source_b, current_blend, self.valuation)
        emergence_history.append(sigma_prev)
        for p, entry in current_blend.entries.items():
            property_tv_history[p].append(entry.quantale.tv.value)

        for step in range(self.max_steps):
            next_blend = apply_gradient_step(
                blend=current_blend,
                source_a=self.source_a,
                source_b=self.source_b,
                valuation=self.valuation,
                eta=current_eta,
            )

            sigma_new = emergence_tv(
                self.source_a, self.source_b, next_blend, self.valuation
            )
            emergence_history.append(sigma_new)

            for p, entry in next_blend.entries.items():
                if p in property_tv_history:
                    property_tv_history[p].append(entry.quantale.tv.value)

            delta = abs(sigma_new - sigma_prev)
            if delta < self.convergence_threshold:
                no_improvement_count += 1
                if no_improvement_count >= self.patience:
                    converged = True
                    current_blend = next_blend
                    break
            else:
                no_improvement_count = 0

            if self.adaptive_eta and (sigma_new < sigma_prev - 1e-4):
                current_eta *= 0.8

            sigma_prev = sigma_new
            current_blend = next_blend

        return McBrideRefinementResult(
            initial_blend=initial_blend,
            refined_blend=current_blend,
            source_a=self.source_a,
            source_b=self.source_b,
            emergence_history=emergence_history,
            property_tv_history=property_tv_history,
            converged=converged,
            steps_taken=len(emergence_history) - 1,
        )

    def all_derivatives(
        self, blend: VPredicateConcept
    ) -> dict[str, ProductQuantale]:
        return {
            prop: mcbride_derivative(
                prop, self.source_a, self.source_b, blend, self.valuation
            )
            for prop in blend.entries
        }

    def top_properties_by_gradient(
        self, blend: VPredicateConcept, top_n: int = 5
    ) -> list[tuple[str, float]]:
        derivs = self.all_derivatives(blend)
        ranked = sorted(
            ((prop, d.tv.value) for prop, d in derivs.items()),
            key=lambda x: -x[1],
        )
        return ranked[:top_n]
