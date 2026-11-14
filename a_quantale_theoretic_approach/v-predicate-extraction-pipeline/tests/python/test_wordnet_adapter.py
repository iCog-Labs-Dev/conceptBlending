"""Unit tests for WordNet source adapter under canonical v-predicate/1 contract."""

from __future__ import annotations

from pathlib import Path
import unittest

from ingestion.wordnet_adapter import WordNetAdapter, safe_metta_symbol
from v_predicate_contract import (
    CONTRACT_VERSION,
    FactKind,
    FactOrigin,
    Perspective,
    PredicateFact,
    PropertyFact,
    PropertyWorldFact,
    SortFact,
    render_document,
    validate_record_set,
)

PIPELINE_ROOT = Path(__file__).resolve().parents[2]


class TestWordNetAdapter(unittest.TestCase):
    def setUp(self) -> None:
        self.adapter = WordNetAdapter(max_props_per_concept=10, max_worlds_per_prop=5, use_nltk=False)

    def test_adapter_metadata(self) -> None:
        self.assertEqual(self.adapter.source_name, "wordnet")
        self.assertEqual(self.adapter.version, "3.1")
        self.assertEqual(self.adapter.license, "WordNet-3.0")

    def test_safe_metta_symbol(self) -> None:
        self.assertEqual(safe_metta_symbol("electronic equipment"), "electronic_equipment")
        self.assertEqual(safe_metta_symbol("phone (device)"), "phone_device")
        self.assertEqual(safe_metta_symbol("123-abc"), "c_123_abc")
        self.assertEqual(safe_metta_symbol(""), "c_empty")
        self.assertEqual(safe_metta_symbol("cellular-telephone"), "cellular_telephone")

    def test_fetch_initializes_marker(self) -> None:
        path = self.adapter.fetch(download=False)
        self.assertTrue(path.exists())
        self.assertIn("wordnet", str(path))

    def test_stream_facts_generator_and_limit(self) -> None:
        stream = self.adapter.stream_facts(limit=5)
        self.assertTrue(hasattr(stream, "__iter__"))
        self.assertTrue(hasattr(stream, "__next__"))
        facts = list(stream)
        self.assertEqual(len(facts), 5)

    def test_canonical_snake_case_perspectives(self) -> None:
        facts = list(self.adapter.stream_facts(limit=30))
        for f in facts:
            self.assertIsInstance(f.perspective, Perspective)
            self.assertNotIn("-", f.perspective.value)
            # Persisted perspectives must match registered canonical values
            self.assertIn(
                f.perspective,
                {
                    Perspective.TAXONOMIC_KIND,
                    Perspective.STRUCTURAL_COMPOSITION,
                    Perspective.FUNCTIONAL_USE,
                    Perspective.DESCRIPTIVE_PROPERTY,
                },
            )

    def test_relational_mappings_and_fact_kinds(self) -> None:
        facts = list(self.adapter.stream_facts(limit=50))
        kinds = {f.kind for f in facts}
        self.assertIn(FactKind.SORT, kinds)
        self.assertIn(FactKind.PREDICATE, kinds)
        self.assertIn(FactKind.PROPERTY, kinds)
        self.assertIn(FactKind.PROPERTY_WORLD, kinds)

        # Hypernyms -> SortFact
        sort_facts = [f for f in facts if isinstance(f, SortFact)]
        phone_sorts = [f for f in sort_facts if f.concept == "phone"]
        self.assertTrue(len(phone_sorts) > 0)
        self.assertEqual(phone_sorts[0].perspective, Perspective.TAXONOMIC_KIND)

        # Meronyms -> PredicateFact (part_of target concept)
        pred_facts = [f for f in facts if isinstance(f, PredicateFact)]
        meronym_preds = [f for f in pred_facts if f.perspective == Perspective.STRUCTURAL_COMPOSITION]
        self.assertTrue(any(f.concept == "phone" and "(part_of " in f.predicate for f in meronym_preds))

        # Functional gloss properties -> PropertyFact
        prop_facts = [f for f in facts if isinstance(f, PropertyFact)]
        func_props = [f for f in prop_facts if f.perspective == Perspective.FUNCTIONAL_USE]
        self.assertTrue(len(func_props) > 0)

    def test_origin_distinction_asserted_vs_heuristic(self) -> None:
        facts = list(self.adapter.stream_facts(limit=60))

        # Direct assertions are ASSERTED
        asserted_facts = [f for f in facts if f.provenance.origin == FactOrigin.ASSERTED]
        self.assertGreater(len(asserted_facts), 0)

        # Heuristically projected worlds are GENERATED with discounted confidence <= 0.8
        generated_facts = [f for f in facts if f.provenance.origin == FactOrigin.GENERATED]
        self.assertGreater(len(generated_facts), 0)
        for gf in generated_facts:
            self.assertEqual(gf.provenance.transformation, "wordnet_heuristic_world_projection")
            self.assertLessEqual(gf.truth.confidence, 0.80)

    def test_full_traversal_flag_support(self) -> None:
        adapter = WordNetAdapter(full_traversal=True)
        self.assertTrue(adapter.full_traversal)
        # Even without live NLTK wordnet corpus, fallback gracefully yields facts
        facts = list(adapter.stream_facts(limit=10))
        self.assertGreater(len(facts), 0)
        validate_record_set(facts)

    def test_deterministic_reruns(self) -> None:
        facts1 = list(self.adapter.stream_facts(limit=15))
        facts2 = list(self.adapter.stream_facts(limit=15))
        self.assertEqual([f.evidence_id for f in facts1], [f.evidence_id for f in facts2])
        self.assertEqual([f.to_metta() for f in facts1], [f.to_metta() for f in facts2])

    def test_contract_validation_passes(self) -> None:
        facts = list(self.adapter.stream_facts())
        self.assertGreater(len(facts), 10)
        validate_record_set(facts)

    def test_render_document_compatibility(self) -> None:
        facts = list(self.adapter.stream_facts(limit=10))
        rendered = render_document(facts)
        self.assertIn(f"; V-predicate contract: {CONTRACT_VERSION}", rendered)
        for fact in facts:
            self.assertIn(f"(: {fact.evidence_id} (≞ ", rendered)
            self.assertIn(f"(: {fact.evidence_id}_provenance (≞ ", rendered)


if __name__ == "__main__":
    unittest.main()
