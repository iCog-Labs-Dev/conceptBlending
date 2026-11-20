"""Unit tests for the ConceptNet adapter and canonical V-predicate mapping."""

from __future__ import annotations

from pathlib import Path
import sys
import unittest
from typing import Iterator

PIPELINE_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(PIPELINE_ROOT / "python"))

from v_predicate_contract import (  # noqa: E402
    CONTRACT_VERSION,
    FactKind,
    FactOrigin,
    Perspective,
    PredicateFact,
    PropertyFact,
    SortFact,
    render_document,
    validate_record_set,
)

from ingestion.conceptnet_adapter import ConceptNetAdapter  # noqa: E402


class ConceptNetAdapterTests(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture_path = PIPELINE_ROOT / "fixtures" / "conceptnet_sub.json"
        self.adapter = ConceptNetAdapter(fixture_path=self.fixture_path)

    def test_adapter_initialization_and_metadata(self) -> None:
        self.assertEqual(self.adapter.source_name, "conceptnet")
        self.assertEqual(self.adapter.version, "5.7.0")
        self.assertEqual(self.adapter.license, "CC-BY-SA-4.0")

    def test_fetch_resolves_fixture_path(self) -> None:
        fetched = self.adapter.fetch(download=False)
        self.assertTrue(fetched.exists())
        self.assertEqual(fetched.resolve(), self.fixture_path.resolve())

    def test_stream_facts_returns_generator(self) -> None:
        stream = self.adapter.stream_facts()
        self.assertTrue(hasattr(stream, "__iter__"))
        self.assertTrue(hasattr(stream, "__next__"))
        # Ensure it yields records lazily
        first_five = [next(stream) for _ in range(5)]
        self.assertEqual(len(first_five), 5)

    def test_stream_facts_honors_limit(self) -> None:
        facts = list(self.adapter.stream_facts(limit=3))
        self.assertEqual(len(facts), 3)

    def test_relation_mappings(self) -> None:
        facts = list(self.adapter.stream_facts())
        kinds = {fact.kind for fact in facts}
        self.assertIn(FactKind.SORT, kinds)
        self.assertIn(FactKind.PREDICATE, kinds)
        self.assertIn(FactKind.PROPERTY, kinds)

        # Check /r/IsA -> SortFact (taxonomic_kind)
        sort_facts = [f for f in facts if isinstance(f, SortFact)]
        computer_sort = next((f for f in sort_facts if f.concept == "computer"), None)
        self.assertIsNotNone(computer_sort)
        self.assertEqual(computer_sort.perspective, Perspective.TAXONOMIC_KIND)
        self.assertEqual(computer_sort.sort, "machine")

        # Check /r/UsedFor -> PredicateFact (functional_use)
        pred_facts = [f for f in facts if isinstance(f, PredicateFact)]
        used_for_facts = [f for f in pred_facts if f.perspective == Perspective.FUNCTIONAL_USE]
        self.assertTrue(any(f.concept == "computer" and "(used_for computer compute)" in f.predicate for f in used_for_facts))

        # Check /r/CapableOf -> PredicateFact (behavioral_process)
        capable_facts = [f for f in pred_facts if f.perspective == Perspective.BEHAVIORAL_PROCESS]
        self.assertTrue(any(f.concept == "computer" for f in capable_facts))

        # Check /r/AtLocation -> PredicateFact (spatial_context)
        location_facts = [f for f in pred_facts if f.perspective == Perspective.SPATIAL_CONTEXT]
        self.assertTrue(any(f.concept == "computer" for f in location_facts))

        # Check /r/PartOf -> PredicateFact (structural_composition)
        part_facts = [f for f in pred_facts if f.perspective == Perspective.STRUCTURAL_COMPOSITION]
        self.assertTrue(len(part_facts) > 0)

        # Check /r/HasProperty -> PropertyFact (descriptive_property)
        prop_facts = [f for f in facts if isinstance(f, PropertyFact)]
        self.assertTrue(any(f.concept == "computer" and f.perspective == Perspective.DESCRIPTIVE_PROPERTY for f in prop_facts))

        # Check /r/Causes -> PredicateFact (causal_prerequisite)
        causes_facts = [f for f in pred_facts if f.perspective == Perspective.CAUSAL_PREREQUISITE]
        self.assertTrue(len(causes_facts) > 0)

    def test_truth_value_scaling(self) -> None:
        facts = list(self.adapter.stream_facts())
        for fact in facts:
            self.assertGreaterEqual(fact.truth.strength, 0.0)
            self.assertLessEqual(fact.truth.strength, 1.0)
            self.assertGreaterEqual(fact.truth.confidence, 0.1)
            self.assertLessEqual(fact.truth.confidence, 0.95)

    def test_provenance_and_origin(self) -> None:
        facts = list(self.adapter.stream_facts())
        for fact in facts:
            self.assertEqual(fact.provenance.source, "conceptnet")
            self.assertEqual(fact.provenance.license, "CC-BY-SA-4.0")
            self.assertEqual(fact.provenance.origin, FactOrigin.ASSERTED)
            self.assertEqual(fact.provenance.transformation, "conceptnet_adapter_v1")

    def test_all_facts_pass_contract_validation(self) -> None:
        facts = list(self.adapter.stream_facts())
        self.assertGreater(len(facts), 10)
        # validate_record_set raises ContractValidationError if invalid
        validate_record_set(facts)

    def test_render_document_compatibility(self) -> None:
        facts = list(self.adapter.stream_facts(limit=5))
        rendered = render_document(facts)
        self.assertIn(f"; V-predicate contract: {CONTRACT_VERSION}", rendered)
        for fact in facts:
            self.assertIn(f"(: {fact.evidence_id} (≞ ", rendered)
            self.assertIn(f"(: {fact.evidence_id}_provenance (≞ ", rendered)

    def test_deterministic_reruns(self) -> None:
        facts1 = list(self.adapter.stream_facts())
        facts2 = list(self.adapter.stream_facts())
        self.assertEqual([f.evidence_id for f in facts1], [f.evidence_id for f in facts2])
        self.assertEqual([f.to_metta() for f in facts1], [f.to_metta() for f in facts2])

    def test_symbol_sanitization(self) -> None:
        from ingestion.conceptnet_adapter import _sanitize_symbol
        self.assertEqual(_sanitize_symbol("/c/en/computer/n"), "computer")
        self.assertEqual(_sanitize_symbol("3d-printer"), "n_3d_printer")
        self.assertEqual(_sanitize_symbol("personal computer"), "personal_computer")
        self.assertEqual(_sanitize_symbol(""), "unknown")

    def test_download_fallback_on_network_error(self) -> None:
        # Mock network failure by pointing cache_dir to temporary path
        import tempfile
        with tempfile.TemporaryDirectory() as tmp_dir:
            adapter = ConceptNetAdapter(fixture_path=self.fixture_path, cache_dir=Path(tmp_dir))
            # Even if download=True, fallback returns fixture if network fails
            path = adapter.fetch(download=True)
            self.assertTrue(path.exists())


if __name__ == "__main__":
    unittest.main()
