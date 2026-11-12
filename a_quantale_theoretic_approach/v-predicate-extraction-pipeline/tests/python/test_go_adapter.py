#!/usr/bin/env python3
"""Tests for Gene Ontology OBO adapter, tri-namespace routing, and CASL/Property-World transformations."""

from __future__ import annotations

import unittest
from pathlib import Path

from ingestion.go_adapter import GeneOntologyAdapter
from ingestion.models import FactType, KnowledgeSource, NormalizedRecord, RawRecord


class TestGeneOntologyAdapter(unittest.TestCase):
    def setUp(self):
        self.fixture_path = (
            Path(__file__).resolve().parents[2] / "fixtures" / "bioenergetics_sub_go.obo"
        )
        self.adapter = GeneOntologyAdapter(obo_path=self.fixture_path)

    def test_source_type(self):
        self.assertEqual(self.adapter.source_type, KnowledgeSource.GENE_ONTOLOGY)

    def test_obo_parsing_and_obsolete_purging(self):
        # The fixture contains 8 terms total: 7 active and 1 obsolete (GO:0000002)
        terms = list(self.adapter.parse_obo(self.fixture_path))
        self.assertEqual(len(terms), 7, "Obsolete terms must be strictly purged")

        term_ids = {t["id"] for t in terms}
        self.assertNotIn("GO:0000002", term_ids, "GO:0000002 has is_obsolete: true and must not be present")
        self.assertIn("GO:0015986", term_ids)
        self.assertIn("GO:0046933", term_ids)
        self.assertIn("GO:0005743", term_ids)

        # Inspect fields of ATP synthesis term
        atp_term = next(t for t in terms if t["id"] == "GO:0015986")
        self.assertEqual(atp_term["name"], "ATP synthesis coupled proton transport")
        self.assertEqual(atp_term["namespace"], "biological_process")
        self.assertIn("GO:0006119", atp_term["is_a"])
        self.assertTrue(any(rel[0] == "part_of" for rel in atp_term["relationships"]))

    def test_tri_namespace_perspective_mapping(self):
        raw_records = list(self.adapter.extract_raw_records())
        self.assertGreater(len(raw_records), 0)

        normalized = [self.adapter.normalize_record(r) for r in raw_records]
        valid_norm = [n for n in normalized if n is not None]
        self.assertGreater(len(valid_norm), 0)

        perspectives = {n.perspective for n in valid_norm}
        # Must map to the three distinct canonical namespaces/perspectives
        self.assertIn("structural-composition", perspectives)
        self.assertIn("functional-use", perspectives)
        self.assertIn("behavioral-process", perspectives)

        for n in valid_norm:
            self.assertGreaterEqual(n.strength, 0.0)
            self.assertLessEqual(n.strength, 1.0)
            self.assertGreaterEqual(n.confidence, 0.0)
            self.assertLessEqual(n.confidence, 1.0)

    def test_transform_to_casl_facts(self):
        raw_records = list(self.adapter.extract_raw_records())
        all_casl = []
        for r in raw_records:
            norm = self.adapter.normalize_record(r)
            if norm:
                all_casl.extend(self.adapter.transform_to_casl(norm))

        self.assertGreater(len(all_casl), 0)
        types = {f.fact_type for f in all_casl}
        self.assertIn(FactType.HAS_SORT, types)
        self.assertIn(FactType.HAS_OPERATION, types)
        self.assertIn(FactType.OPERATION_SIGNATURE, types)
        self.assertIn(FactType.HAS_PREDICATE, types)

        for fact in all_casl:
            line = fact.to_metta_line()
            self.assertEqual(line.count("("), line.count(")"))
            self.assertTrue(line.startswith("(") and line.endswith(")"))

    def test_transform_to_property_world_facts(self):
        raw_records = list(self.adapter.extract_raw_records())
        all_pw = []
        for r in raw_records:
            norm = self.adapter.normalize_record(r)
            if norm:
                all_pw.extend(self.adapter.transform_to_property_world(norm))

        self.assertGreater(len(all_pw), 0)
        types = {f.fact_type for f in all_pw}
        self.assertIn(FactType.HAS_SCOPED_PROPERTY, types)
        self.assertIn(FactType.SCOPED_PROPERTY_HOLDS_IN, types)
        self.assertIn(FactType.PERSPECTIVE_MATCH, types)

        for fact in all_pw:
            line = fact.to_metta_line()
            self.assertEqual(line.count("("), line.count(")"))

    def test_offline_determinism(self):
        # Fetching without download flag must return the local fixture
        fetched_path = self.adapter.fetch(download=False)
        self.assertTrue(fetched_path.exists())
        self.assertEqual(fetched_path.resolve(), self.fixture_path.resolve())

        # Repeated extractions must produce identical counts
        run1 = [n.to_metta_line() for r in self.adapter.extract_raw_records()
                for n in [self.adapter.normalize_record(r)] if n
                for n in self.adapter.transform_to_casl(n)]
        run2 = [n.to_metta_line() for r in self.adapter.extract_raw_records()
                for n in [self.adapter.normalize_record(r)] if n
                for n in self.adapter.transform_to_casl(n)]
        self.assertEqual(run1, run2, "Extraction must be deterministic across runs")


if __name__ == "__main__":
    unittest.main()

