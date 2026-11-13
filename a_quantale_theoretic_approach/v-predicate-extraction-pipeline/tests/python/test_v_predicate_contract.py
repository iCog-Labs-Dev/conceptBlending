from pathlib import Path
import sys
import unittest


PIPELINE_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(PIPELINE_ROOT / "python"))

from v_predicate_contract import (  # noqa: E402
    CONTRACT_VERSION,
    ContractValidationError,
    FactOrigin,
    OperationFact,
    OperationSignatureFact,
    Perspective,
    PredicateFact,
    PropertyFact,
    PropertyWorldFact,
    Provenance,
    SortFact,
    TruthValue,
    canonicalize_perspective,
    render_document,
    stable_evidence_id,
    validate_record_set,
)


def provenance(origin: FactOrigin = FactOrigin.ASSERTED) -> Provenance:
    return Provenance(
        source="wordnet",
        source_record_id="computer.n.01",
        source_uri="nltk://wordnet",
        source_version="3.1",
        license="WordNet-3.0",
        transformation="wordnet_adapter_v1",
        origin=origin,
    )


class VPredicateContractTests(unittest.TestCase):
    def test_contract_version_is_explicit(self) -> None:
        self.assertEqual(CONTRACT_VERSION, "v-predicate/1")

    def test_hyphenated_input_normalizes_to_registered_perspective(self) -> None:
        self.assertEqual(
            canonicalize_perspective("functional-use"), Perspective.FUNCTIONAL_USE
        )
        with self.assertRaises(ContractValidationError):
            canonicalize_perspective("adapter-invented-perspective")

    def test_truth_values_are_bounded(self) -> None:
        self.assertEqual(TruthValue(0.9, 0.85).to_metta(), "(stv 0.900 0.850)")
        with self.assertRaises(ContractValidationError):
            TruthValue(1.01, 0.5)

    def test_evidence_ids_are_stable_and_source_specific(self) -> None:
        wordnet_id = stable_evidence_id(
            "sort", "wordnet", "computer.n.01", "computer", "machine"
        )
        self.assertEqual(
            wordnet_id,
            stable_evidence_id(
                "sort", "wordnet", "computer.n.01", "computer", "machine"
            ),
        )
        self.assertNotEqual(
            wordnet_id,
            stable_evidence_id(
                "sort", "conceptnet", "computer", "computer", "machine"
            ),
        )

    def test_sort_renders_canonical_annotation_and_provenance(self) -> None:
        fact = SortFact(
            evidence_id="computer_machine_edge",
            edge_id="computer_machine_edge",
            concept="computer",
            perspective="taxonomic-kind",
            sort="machine",
            truth=TruthValue(0.95, 0.9),
            provenance=provenance(),
        )
        self.assertEqual(
            fact.to_metta(),
            "(: computer_machine_edge (≞ (has_sort computer_machine_edge computer "
            "taxonomic_kind machine) (stv 0.950 0.900)))",
        )
        self.assertIn("evidence_provenance computer_machine_edge wordnet", fact.provenance_to_metta())
        self.assertIn('"computer.n.01"', fact.provenance_to_metta())

    def test_predicates_must_retain_a_structured_relation(self) -> None:
        fact = PredicateFact(
            evidence_id="phenol_role_edge",
            edge_id="phenol_role_edge",
            concept="phenol",
            perspective="functional_use",
            predicate="(hasRole phenol antiseptic)",
            truth=TruthValue(0.9, 0.95),
            provenance=provenance(),
        )
        self.assertIn("(hasRole phenol antiseptic)", fact.to_metta())
        with self.assertRaises(ContractValidationError):
            PredicateFact(
                evidence_id="bad_edge",
                edge_id="bad_edge",
                concept="phenol",
                perspective="functional_use",
                predicate="antiseptic",
                truth=TruthValue(0.9, 0.95),
                provenance=provenance(),
            )

    def test_primary_evidence_is_the_queryable_edge(self) -> None:
        with self.assertRaisesRegex(ContractValidationError, "same evidence_id"):
            SortFact(
                evidence_id="outer_label",
                edge_id="different_edge",
                concept="computer",
                perspective="taxonomic_kind",
                sort="machine",
                truth=TruthValue(1.0, 1.0),
                provenance=provenance(),
            )

    def test_linked_records_validate_independently_of_order(self) -> None:
        signature = OperationSignatureFact(
            evidence_id="computer_process_signature",
            edge_id="computer_process_edge",
            signature="(arrow computer information information)",
            truth=TruthValue(0.9, 0.85),
            provenance=provenance(FactOrigin.INFERRED),
        )
        operation = OperationFact(
            evidence_id="computer_process_edge",
            edge_id="computer_process_edge",
            concept="computer",
            perspective="functional_use",
            operation="process_information",
            truth=TruthValue(0.9, 0.85),
            provenance=provenance(),
        )
        validate_record_set([signature, operation])
        rendered = render_document([signature, operation])
        self.assertTrue(rendered.startswith(f"; V-predicate contract: {CONTRACT_VERSION}"))

    def test_missing_linked_records_are_rejected(self) -> None:
        orphan_signature = OperationSignatureFact(
            evidence_id="orphan_signature",
            edge_id="missing_operation",
            signature="(arrow computer information)",
            truth=TruthValue(1.0, 1.0),
            provenance=provenance(),
        )
        with self.assertRaisesRegex(ContractValidationError, "missing edge"):
            validate_record_set([orphan_signature])

    def test_property_world_requires_declared_property(self) -> None:
        property_fact = PropertyFact(
            evidence_id="computer_compute_edge",
            edge_id="computer_compute_edge",
            concept="computer",
            perspective="functional_use",
            property_id="computer_compute_property_id",
            property_name="compute",
            truth=TruthValue(0.85, 0.8),
            provenance=provenance(),
        )
        world_fact = PropertyWorldFact(
            evidence_id="computer_compute_world_edge",
            edge_id="computer_compute_world_edge",
            property_id="computer_compute_property_id",
            perspective="functional_use",
            world="workstation",
            truth=TruthValue(0.65, 0.5),
            provenance=provenance(FactOrigin.GENERATED),
        )
        validate_record_set([world_fact, property_fact])

    def test_authoritative_fixture_is_canonical(self) -> None:
        fixture = PIPELINE_ROOT / "fixtures" / "v_predicate_contract_v1.metta"
        text = fixture.read_text(encoding="utf-8")
        self.assertIn("; V-predicate contract: v-predicate/1", text)
        self.assertNotIn("functional-use", text)
        for line in text.splitlines():
            if line and not line.startswith(";"):
                self.assertTrue(line.startswith("(: "))
                self.assertEqual(line.count("("), line.count(")"))


if __name__ == "__main__":
    unittest.main()
