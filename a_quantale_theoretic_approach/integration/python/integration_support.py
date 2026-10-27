"""Runtime path setup for the MeTTa component-integration bootstrap."""

from __future__ import annotations

import os
from pathlib import Path


INTEGRATION_ROOT = Path(__file__).resolve().parent.parent
QUANTALE_ROOT = INTEGRATION_ROOT.parent
V_PREDICATE_PIPELINE_ROOT = (
    QUANTALE_ROOT / "v-predicate-extraction-pipeline"
)


def configure_component_roots() -> bool:
    """Make nested Python-backed MeTTa modules resolve their own component."""

    os.environ.setdefault(
        "V_PREDICATE_PIPELINE_ROOT", str(V_PREDICATE_PIPELINE_ROOT)
    )
    return True


def assemble_structural_blend_preparation(
    generic_name: object,
    perspective: object,
    left_v_predicate: object,
    right_v_predicate: object,
    left_spec: object,
    right_spec: object,
    generic_spec: object,
) -> str:
    """Serialize the staged result as inert MeTTa data."""

    generic_spec_text = str(generic_spec)
    if generic_spec_text == "()":
        return (
            "(IntegrationError "
            "GenericSpaceAlgebraicSpecificationUnavailable "
            f"{generic_name} {perspective})"
        )
    if generic_spec_text.startswith("((") and generic_spec_text.endswith("))"):
        generic_spec_text = generic_spec_text[1:-1]

    return (
        f"(structural-blend-preparation {generic_name} {perspective} "
        f"(SourceVPredicates {left_v_predicate} {right_v_predicate}) "
        f"(SourceAlgebraicSpecifications {left_spec} {right_spec}) "
        f"(GenericSpaceAlgebraicSpecification {generic_spec_text}) "
        "(EnrichmentStatus "
        "(PropertyTruthScalars Pending GNN) "
        "(EnrichedHomValues Pending HomExtractionPipeline) "
        "(VColimitCheck Blocked EnrichedHomValues)))"
    )
