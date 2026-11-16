from pathlib import Path
import sys
import unittest


PIPELINE_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(PIPELINE_ROOT / "python"))

from pathmap_kb_integration import split_records  # noqa: E402
from v_predicate_contract import (  # noqa: E402
    FactOrigin,
    OperationFact,
    OperationSignatureFact,
    PerspectiveDefinitionFact,
    PropertyFact,
    PropertyWorldFact,
    Provenance,
    TruthValue,
)


def provenance(origin: FactOrigin = FactOrigin.ASSERTED) -> Provenance:
    return Provenance(
        source="fixture",
        source_record_id="record-1",
        source_uri="fixture://integration",
        source_version="1",
        license="internal",
        transformation="integration_fixture",
        origin=origin,
    )


class PathMapIntegrationTests(unittest.TestCase):
    def test_split_keeps_linked_records_together_and_metadata_available(self) -> None:
        operation = OperationFact(
            evidence_id="operation_edge",
            edge_id="operation_edge",
            concept="computer",
            perspective="functional_use",
            operation="process",
            truth=TruthValue(0.9, 0.8),
            provenance=provenance(),
        )
        signature = OperationSignatureFact(
            evidence_id="signature_edge",
            edge_id="operation_edge",
            signature="(arrow information output)",
            truth=TruthValue(0.8, 0.7),
            provenance=provenance(FactOrigin.INFERRED),
        )
        property_fact = PropertyFact(
            evidence_id="property_edge",
            edge_id="property_edge",
            concept="computer",
            perspective="behavioral_process",
            property_id="process_property",
            property_name="process_information",
            truth=TruthValue(0.9, 0.8),
            provenance=provenance(),
        )
        world = PropertyWorldFact(
            evidence_id="world_edge",
            edge_id="world_edge",
            property_id="process_property",
            perspective="spatial_context",
            world="data_center",
            truth=TruthValue(0.8, 0.7),
            provenance=provenance(),
        )
        definition = PerspectiveDefinitionFact(
            evidence_id="perspective_edge",
            perspective="functional_use",
            role="function_role",
            truth=TruthValue(1.0, 1.0),
            provenance=provenance(),
        )

        property_records, algebraic_records = split_records(
            [world, signature, definition, property_fact, operation]
        )

        self.assertEqual(algebraic_records, [signature, operation])
        self.assertEqual(property_records, [world, definition, property_fact])


if __name__ == "__main__":
    unittest.main()
