"""
Main entry point for Quantale-Theoretic Conceptual Blending.

Wires together:
  1. Quantale Colimit Engine (pushout construction)
  2. McBride Derivative Optimization (emergence refinement)
  3. Optimality Constraint Evaluation (coherence, integration, web checks)
"""

from typing import Optional, Dict, Any
from a_quantale_theoretic_approach.structural_reasoning.quantale_colimit_engine import (
    compute_quantale_colimit,
    QuantaleColimitResult,
    PropertyMap,
)
from a_quantale_theoretic_approach.optimization.macbride_derivative import (
    McBrideOptimizer,
    McBrideRefinementResult,
)
from a_quantale_theoretic_approach.optimality.constraint_manager import (
    evaluate_quantale_optimality,
)
from a_quantale_theoretic_approach.core_representation.v_predicate import (
    VPredicateConcept,
)


def run_full_pipeline(
    concept_a: VPredicateConcept,
    concept_b: VPredicateConcept,
    concept_g: Optional[VPredicateConcept] = None,
    map_g_to_a: PropertyMap = None,
    map_g_to_b: PropertyMap = None,
    blend_name: str = "RefinedBlend",
    mcbride_eta: float = 0.05,
    mcbride_steps: int = 20,
) -> Dict[str, Any]:
    """
    Executes the full 3-step Quantale conceptual blending pipeline:
      Step 1: Compute property-level Quantale Colimit.
      Step 2: Apply McBride Derivative refinement to maximize emergence.
      Step 3: Evaluate optimality constraints on the refined blend.
    """
    # Step 1: Colimit Engine
    colimit_result: QuantaleColimitResult = compute_quantale_colimit(
        concept_a=concept_a,
        concept_b=concept_b,
        concept_g=concept_g,
        map_g_to_a=map_g_to_a,
        map_g_to_b=map_g_to_b,
        blend_name=blend_name,
    )

    # Step 2: McBride Derivative Optimization
    optimizer = McBrideOptimizer(
        source_a=concept_a,
        source_b=concept_b,
        eta=mcbride_eta,
        max_steps=mcbride_steps,
    )
    refinement_result: McBrideRefinementResult = optimizer.refine(
        colimit_result.blend
    )

    # Build a new QuantaleColimitResult wrapping the refined blend,
    # preserving the world specs and property maps from the colimit step.
    refined_colimit = QuantaleColimitResult(
        blend=refinement_result.refined_blend,
        world_specs=colimit_result.world_specs,
        property_maps=colimit_result.property_maps,
        contributions=colimit_result.contributions,
        generated_worlds=colimit_result.generated_worlds,
        metrics=colimit_result.metrics,
    )
    optimality_report = evaluate_quantale_optimality(
        concept_a, concept_b, refined_colimit
    )

    return {
        "colimit": colimit_result,
        "refinement": refinement_result,
        "optimality": optimality_report,
        "final_blend": refinement_result.refined_blend,
    }
