#!/usr/bin/env python3
"""Tests for knowledge ingestion data models and provenance contracts."""

from __future__ import annotations

import unittest
from dataclasses import FrozenInstanceError

from ingestion.models import (
    FactType,
    IngestionProvenance,
    KnowledgeSource,
    MettaFact,
    NormalizedRecord,
    RawRecord,
)


class TestIngestionModels(unittest.TestCase):
    def setUp(self):
        self.prov = IngestionProvenance(
            source=KnowledgeSource.WORDNET,
            source_uri_or_path="nltk://wordnet-3.1",
            source_version="3.1",
            license="WordNet-3.0",
        )

    def test_knowledge_source_enum(self):
        expected = {"WORDNET", "GENE_ONTOLOGY", "CHEBI", "OPENMATH", "CONCEPTNET"}
        actual = {source.name for source in KnowledgeSource}
        self.assertEqual(actual, expected)

    def test_ingestion_provenance_immutability(self):
        with self.assertRaises(FrozenInstanceError):
            self.prov.source_version = "3.2"  # type: ignore[misc]

    def test_raw_record_immutability(self):
        raw = RawRecord(
            source_id="phone.n.01",
            concept_name="phone",
            relation="hypernym",
            target_name="electronic_equipment",
            weight=1.0,
            metadata={"gloss": "electronic equipment that converts sound into electrical signals"},
            provenance=self.prov,
        )
        self.assertEqual(raw.concept_name, "phone")
        self.assertEqual(raw.target_name, "electronic_equipment")
        with self.assertRaises(FrozenInstanceError):
            raw.weight = 0.5  # type: ignore[misc]

    def test_normalized_record_bounds_valid(self):
        norm = NormalizedRecord(
            concept="phone",
            property_or_target="electronic_equipment",
            relation="isA",
            perspective="taxonomic-kind",
            strength=0.9,
            confidence=0.8,
            provenance=self.prov,
        )
        self.assertAlmostEqual(norm.strength, 0.9)
        self.assertAlmostEqual(norm.confidence, 0.8)
        self.assertEqual(norm.perspective, "taxonomic-kind")

    def test_normalized_record_bounds_enforced(self):
        with self.assertRaises(ValueError):
            NormalizedRecord(
                concept="phone",
                property_or_target="electronic_equipment",
                relation="isA",
                perspective="taxonomic-kind",
                strength=1.5,  # Invalid: > 1.0
                confidence=0.8,
                provenance=self.prov,
            )

        with self.assertRaises(ValueError):
            NormalizedRecord(
                concept="phone",
                property_or_target="electronic_equipment",
                relation="isA",
                perspective="taxonomic-kind",
                strength=0.5,
                confidence=-0.1,  # Invalid: < 0.0
                provenance=self.prov,
            )

    def test_metta_fact_rendering(self):
        fact = MettaFact(
            fact_type=FactType.HAS_SORT,
            expression="(has_sort edge_001 phone taxonomic-kind electronic_equipment)",
            stv=(0.95, 0.90),
        )
        rendered = fact.to_metta_line()
        self.assertEqual(
            rendered,
            "(has_sort edge_001 phone taxonomic-kind electronic_equipment) (stv 0.95 0.9)",
        )

    def test_metta_fact_balanced_parentheses(self):
        fact = MettaFact(
            fact_type=FactType.HAS_SCOPED_PROPERTY,
            expression="(has_scoped_property edge_002 phone functional-use prop_transmit transmit_voice)",
            stv=(0.85, 0.80),
        )
        expr = fact.to_metta_line()
        self.assertEqual(expr.count("("), expr.count(")"))


if __name__ == "__main__":
    unittest.main()

