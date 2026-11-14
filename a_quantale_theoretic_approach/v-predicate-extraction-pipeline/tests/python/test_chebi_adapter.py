"""Unit tests for ChEBI source adapter under canonical v-predicate/1 contract."""

from __future__ import annotations

from pathlib import Path
import unittest

from ingestion.chebi_adapter import ChebiAdapter
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


class TestChebiAdapter(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture_path = PIPELINE_ROOT / "fixtures" / "phenol_sub_chebi.obo"
        self.adapter = ChebiAdapter(obo_path=self.fixture_path)

    def test_adapter_metadata_and_dynamic_version(self) -> None:
        self.assertEqual(self.adapter.source_name, "chebi")
        self.assertEqual(self.adapter.license, "CC-BY-4.0")
        # Dynamic version extracted from OBO header 'data-version: releases/2026-11-01'
        self.assertEqual(self.adapter.version, "releases/2026-11-01")
        self.assertIn("chebi", self.adapter.source_uri.lower())

    def test_chebi_parsing_and_obsolete_purging(self) -> None:
        terms = list(self.adapter.parse_obo(self.fixture_path))
        term_ids = {t["id"] for t in terms}
        self.assertNotIn("CHEBI:99999", term_ids, "Obsolete term CHEBI:99999 must be strictly purged")
        self.assertIn("CHEBI:16127", term_ids)  # phenol
        self.assertIn("CHEBI:22712", term_ids)  # benzene
        self.assertIn("CHEBI:43176", term_ids)  # hydroxyl group
        self.assertIn("CHEBI:33854", term_ids)  # phenolate

    def test_stream_facts_generator_and_bounded_memory(self) -> None:
        stream = self.adapter.stream_facts()
        self.assertTrue(hasattr(stream, "__iter__"))
        self.assertTrue(hasattr(stream, "__next__"))
        first_fact = next(stream)
        self.assertIsNotNone(first_fact)
        self.assertTrue(hasattr(first_fact, "evidence_id"))

    def test_stream_facts_honors_limit(self) -> None:
        stream = self.adapter.stream_facts(limit=5)
        facts = list(stream)
        self.assertEqual(len(facts), 5)

    def test_chemical_relationship_perspective_mapping(self) -> None:
        facts = list(self.adapter.stream_facts())
        perspectives = {f.perspective for f in facts}

        self.assertIn(Perspective.TAXONOMIC_KIND, perspectives)
        self.assertIn(Perspective.STRUCTURAL_COMPOSITION, perspectives)
        self.assertIn(Perspective.FUNCTIONAL_USE, perspectives)
        self.assertIn(Perspective.STATE_LIFECYCLE, perspectives)

        for p in perspectives:
            self.assertNotIn("-", p.value)

    def test_phenol_blending_domain_assertions(self) -> None:
        """Verify chemical domain facts required for Phenol conceptual blending."""
        facts = list(self.adapter.stream_facts())

        # 1. Structural composition: phenol has_part benzene and hydroxyl_group
        pred_facts = [f for f in facts if isinstance(f, PredicateFact)]
        phenol_parts = [
            f for f in pred_facts
            if f.concept == "phenol" and f.perspective == Perspective.STRUCTURAL_COMPOSITION
        ]
        self.assertTrue(any("benzene" in f.predicate for f in phenol_parts))
        self.assertTrue(any("hydroxyl_group" in f.predicate for f in phenol_parts))

        # 2. Functional use: phenol has_role antiseptic
        phenol_roles = [
            f for f in pred_facts
            if f.concept == "phenol" and f.perspective == Perspective.FUNCTIONAL_USE
        ]
        self.assertTrue(any("antiseptic" in f.predicate for f in phenol_roles))

        # 3. State lifecycle: phenol is_conjugate_acid_of phenolate
        phenol_dissoc = [
            f for f in pred_facts
            if f.concept == "phenol" and f.perspective == Perspective.STATE_LIFECYCLE
        ]
        self.assertTrue(any("phenolate" in f.predicate for f in phenol_dissoc))

    def test_chemical_possible_worlds(self) -> None:
        facts = list(self.adapter.stream_facts())
        world_facts = [f for f in facts if isinstance(f, PropertyWorldFact)]
        self.assertGreater(len(world_facts), 0)

        worlds = {wf.world for wf in world_facts}
        self.assertTrue(any(w in worlds for w in {"aqueous_solution", "water", "organic_phase"}))
        for wf in world_facts:
            self.assertEqual(wf.provenance.origin, FactOrigin.ASSERTED)

    def test_contract_validation_passes(self) -> None:
        facts = list(self.adapter.stream_facts())
        self.assertGreater(len(facts), 0)
        # validate_record_set passes cleanly without raising ContractValidationError
        validate_record_set(facts)

    def test_canonical_metta_document_rendering(self) -> None:
        facts = list(self.adapter.stream_facts())
        doc = render_document(facts)
        self.assertIn(f"; V-predicate contract: {CONTRACT_VERSION}", doc)
        self.assertIn("≞", doc)
        self.assertIn("stv", doc)
        self.assertIn("evidence_provenance", doc)
        self.assertEqual(doc.count("("), doc.count(")"))

    def test_offline_determinism(self) -> None:
        path = self.adapter.fetch(download=False)
        self.assertTrue(path.exists())
        self.assertEqual(path.resolve(), self.fixture_path.resolve())

        run1 = [f.to_metta() for f in self.adapter.stream_facts()]
        run2 = [f.to_metta() for f in self.adapter.stream_facts()]
        self.assertEqual(run1, run2, "stream_facts() must be 100% deterministic across reruns")


if __name__ == "__main__":
    unittest.main()
