#!/usr/bin/env python3
"""Tests for WordNet source adapter, extraction, normalization, and sinks."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from ingestion.models import FactType, KnowledgeSource, NormalizedRecord, RawRecord
from ingestion.sinks import MettaFileSink, PathMapSink
from ingestion.wordnet_adapter import WordNetAdapter, safe_metta_symbol
from v_predicate_contract import (
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


class TestWordNetAdapter(unittest.TestCase):
    def setUp(self):
        self.adapter = WordNetAdapter(max_props_per_concept=10, max_worlds_per_prop=5)

    def test_source_type(self):
        self.assertEqual(self.adapter.source_type, KnowledgeSource.WORDNET)

    def test_safe_metta_symbol(self):
        self.assertEqual(safe_metta_symbol("electronic equipment"), "electronic_equipment")
        self.assertEqual(safe_metta_symbol("phone (device)"), "phone_device")
        self.assertEqual(safe_metta_symbol("123-abc"), "c_123_abc")
        self.assertEqual(safe_metta_symbol(""), "c_empty")
        self.assertEqual(safe_metta_symbol("cellular-telephone"), "cellular_telephone")

    def test_extract_raw_records_offline_fallback(self):
        # Even without the live NLTK wordnet download, the adapter falls back
        # to its bundled lexical knowledge base for standard concepts.
        records = list(self.adapter.extract_concept_records("phone"))
        self.assertGreater(len(records), 0)
        relations = {r.relation for r in records}
        self.assertTrue(relations.intersection({"hypernym", "part_meronym", "gloss_attribute"}))
        for r in records:
            self.assertEqual(r.concept_name, "phone")
            self.assertIsInstance(r.weight, float)
            self.assertGreaterEqual(r.weight, 0.0)
            self.assertLessEqual(r.weight, 1.0)

    def test_normalize_record_perspectives(self):
        records = list(self.adapter.extract_concept_records("phone"))
        normalized = [self.adapter.normalize_record(r) for r in records]
        valid_norm = [n for n in normalized if n is not None]
        self.assertGreater(len(valid_norm), 0)

        perspectives = {n.perspective for n in valid_norm}
        # Should map to established perspectives
        self.assertTrue(
            perspectives.intersection(
                {"taxonomic-kind", "structural-composition", "functional-use", "descriptive-property"}
            )
        )
        for n in valid_norm:
            self.assertGreaterEqual(n.strength, 0.0)
            self.assertLessEqual(n.strength, 1.0)
            self.assertGreaterEqual(n.confidence, 0.0)
            self.assertLessEqual(n.confidence, 1.0)

    def test_transform_to_casl_facts(self):
        records = list(self.adapter.extract_concept_records("phone"))
        normalized = [self.adapter.normalize_record(r) for r in records if r]
        all_casl = []
        for n in normalized:
            if n:
                all_casl.extend(self.adapter.transform_to_casl(n))

        self.assertGreater(len(all_casl), 0)
        types = {f.fact_type for f in all_casl}
        self.assertIn(FactType.HAS_SORT, types)

        for fact in all_casl:
            line = fact.to_metta_line()
            self.assertEqual(line.count("("), line.count(")"))
            self.assertTrue(line.startswith("(") and line.endswith(")"))

    def test_transform_to_property_world_facts(self):
        records = list(self.adapter.extract_concept_records("phone"))
        normalized = [self.adapter.normalize_record(r) for r in records if r]
        all_pw = []
        for n in normalized:
            if n:
                all_pw.extend(self.adapter.transform_to_property_world(n))

        self.assertGreater(len(all_pw), 0)
        types = {f.fact_type for f in all_pw}
        self.assertIn(FactType.HAS_SCOPED_PROPERTY, types)
        self.assertIn(FactType.SCOPED_PROPERTY_HOLDS_IN, types)
        self.assertIn(FactType.PERSPECTIVE_MATCH, types)

        for fact in all_pw:
            line = fact.to_metta_line()
            self.assertEqual(line.count("("), line.count(")"))

    def test_caps_and_limits(self):
        adapter = WordNetAdapter(max_props_per_concept=2, max_worlds_per_prop=2)
        records = list(adapter.extract_concept_records("phone"))
        self.assertLessEqual(len(records), 10)  # Total raw records reasonable
        # Test that worlds generated per property never exceed max_worlds_per_prop
        for r in records:
            norm = adapter.normalize_record(r)
            if norm:
                pw_facts = adapter.transform_to_property_world(norm)
                world_facts = [f for f in pw_facts if f.fact_type == FactType.SCOPED_PROPERTY_HOLDS_IN]
                self.assertLessEqual(len(world_facts), 2)

    def test_metta_file_sink_and_deduplication(self):
        with tempfile.NamedTemporaryFile("w+", suffix=".metta", delete=False) as tmp:
            tmp_path = Path(tmp.name)

        try:
            sink = MettaFileSink(tmp_path)
            records = list(self.adapter.extract_concept_records("battery"))
            for r in records:
                norm = self.adapter.normalize_record(r)
                if norm:
                    for fact in self.adapter.transform_to_property_world(norm):
                        sink.write_fact(fact)
            # Re-write the same facts to test deduplication
            for r in records:
                norm = self.adapter.normalize_record(r)
                if norm:
                    for fact in self.adapter.transform_to_property_world(norm):
                        sink.write_fact(fact)

            sink.flush()
            content = tmp_path.read_text(encoding="utf-8")
            lines = [l for l in content.splitlines() if l.strip()]
            self.assertEqual(len(lines), len(set(lines)), "Sink should not write duplicate lines")
            self.assertGreater(len(lines), 0)
        finally:
            if tmp_path.exists():
                tmp_path.unlink()

    def test_pathmap_sink_interface(self):
        sink = PathMapSink()
        records = list(self.adapter.extract_concept_records("phone"))
        for r in records:
            norm = self.adapter.normalize_record(r)
            if norm:
                success = sink.register_atomspace_record(norm)
                self.assertTrue(success)
        self.assertEqual(len(sink.get_registered_records()), len([r for r in records if self.adapter.normalize_record(r)]))

    def test_v_predicate_stream_facts_offline(self):
        adapter = WordNetAdapter(use_nltk=False)
        facts = list(adapter.stream_facts(limit=20))
        self.assertGreater(len(facts), 0)
        self.assertLessEqual(len(facts), 20)

        # Validate types
        kinds = {f.kind for f in facts}
        self.assertTrue(kinds.intersection({FactKind.SORT, FactKind.PREDICATE, FactKind.PROPERTY}))

        # Assert canonical snake_case perspectives
        for f in facts:
            self.assertIsInstance(f.perspective, Perspective)
            self.assertIn("_", f.perspective.value if "_" in f.perspective.value else f.perspective.value)
            self.assertNotIn("-", f.perspective.value)

        # Validate contract compliance
        validate_record_set(facts)

    def test_v_predicate_stream_facts_origin_distinction(self):
        adapter = WordNetAdapter(use_nltk=False)
        facts = list(adapter.stream_facts())

        # Direct facts should be ASSERTED
        asserted_facts = [f for f in facts if f.provenance.origin == FactOrigin.ASSERTED]
        self.assertGreater(len(asserted_facts), 0)

        # Heuristically generated worlds should be GENERATED with confidence <= 0.8
        generated_facts = [f for f in facts if f.provenance.origin == FactOrigin.GENERATED]
        self.assertGreater(len(generated_facts), 0)
        for gf in generated_facts:
            self.assertEqual(gf.provenance.transformation, "wordnet_heuristic_world_projection")
            self.assertLessEqual(gf.truth.confidence, 0.80)

    def test_v_predicate_full_traversal_support(self):
        # Full traversal parameter exists and can be enabled
        adapter = WordNetAdapter(full_traversal=True)
        self.assertTrue(adapter.full_traversal)
        # Verify generator streaming works
        stream = adapter.stream_facts(limit=5)
        facts = list(stream)
        self.assertEqual(len(facts), 5)
        validate_record_set(facts)


if __name__ == "__main__":
    unittest.main()

