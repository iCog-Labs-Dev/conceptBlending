"""Unit tests for Gene Ontology (GO) source adapter under canonical v-predicate/1 contract."""

from __future__ import annotations

from pathlib import Path
import unittest

from ingestion.go_adapter import GeneOntologyAdapter
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


class TestGeneOntologyAdapter(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture_path = PIPELINE_ROOT / "fixtures" / "bioenergetics_sub_go.obo"
        self.adapter = GeneOntologyAdapter(obo_path=self.fixture_path)

    def test_adapter_metadata_and_dynamic_version(self) -> None:
        self.assertEqual(self.adapter.source_name, "gene_ontology")
        self.assertEqual(self.adapter.license, "CC-BY-4.0")
        # Dynamic version extracted from OBO header 'data-version: releases/2026-11-01'
        self.assertEqual(self.adapter.version, "releases/2026-11-01")
        self.assertIn("geneontology.org", self.adapter.source_uri)

    def test_obo_parsing_and_obsolete_purging(self) -> None:
        # Fixture has 8 terms total: 7 active and 1 obsolete (GO:0000002)
        terms = list(self.adapter.parse_obo(self.fixture_path))
        self.assertEqual(len(terms), 7, "Obsolete terms must be strictly purged")

        term_ids = {t["id"] for t in terms}
        self.assertNotIn("GO:0000002", term_ids, "GO:0000002 has is_obsolete: true and must be filtered")
        self.assertIn("GO:0015986", term_ids)
        self.assertIn("GO:0046933", term_ids)
        self.assertIn("GO:0005743", term_ids)

        atp_term = next(t for t in terms if t["id"] == "GO:0015986")
        self.assertEqual(atp_term["name"], "ATP synthesis coupled proton transport")
        self.assertEqual(atp_term["namespace"], "biological_process")

    def test_stream_facts_generator_and_bounded_memory(self) -> None:
        stream = self.adapter.stream_facts()
        self.assertTrue(hasattr(stream, "__iter__"))
        self.assertTrue(hasattr(stream, "__next__"))
        first_fact = next(stream)
        self.assertIsNotNone(first_fact)
        self.assertTrue(hasattr(first_fact, "evidence_id"))

    def test_stream_facts_honors_limit(self) -> None:
        stream = self.adapter.stream_facts(limit=4)
        facts = list(stream)
        self.assertEqual(len(facts), 4)

    def test_canonical_snake_case_perspectives(self) -> None:
        facts = list(self.adapter.stream_facts(limit=50))
        for f in facts:
            self.assertIsInstance(f.perspective, Perspective)
            self.assertNotIn("-", f.perspective.value)
            self.assertIn(
                f.perspective,
                {
                    Perspective.TAXONOMIC_KIND,
                    Perspective.STRUCTURAL_COMPOSITION,
                    Perspective.FUNCTIONAL_USE,
                    Perspective.BEHAVIORAL_PROCESS,
                    Perspective.CAUSAL_PREREQUISITE,
                    Perspective.SPATIAL_CONTEXT,
                    Perspective.DESCRIPTIVE_PROPERTY,
                },
            )

    def test_relational_mappings_and_fact_kinds(self) -> None:
        facts = list(self.adapter.stream_facts())
        kinds = {f.kind for f in facts}
        self.assertIn(FactKind.SORT, kinds)
        self.assertIn(FactKind.PREDICATE, kinds)
        self.assertIn(FactKind.PROPERTY, kinds)
        self.assertIn(FactKind.PROPERTY_WORLD, kinds)

        # 1. is_a -> SortFact (taxonomic_kind)
        sort_facts = [f for f in facts if isinstance(f, SortFact)]
        self.assertTrue(
            any(
                f.concept == "atp_synthesis_coupled_proton_transport"
                and f.sort == "oxidative_phosphorylation"
                for f in sort_facts
            )
        )

        # 2. part_of -> PredicateFact (structural_composition)
        pred_facts = [f for f in facts if isinstance(f, PredicateFact)]
        part_of_facts = [f for f in pred_facts if f.perspective == Perspective.STRUCTURAL_COMPOSITION]
        self.assertTrue(any("part_of" in f.predicate for f in part_of_facts))

    def test_cellular_components_as_possible_worlds(self) -> None:
        facts = list(self.adapter.stream_facts())
        world_facts = [f for f in facts if isinstance(f, PropertyWorldFact)]
        self.assertGreater(len(world_facts), 0)

        # Spatial context perspective
        for wf in world_facts:
            self.assertEqual(wf.perspective, Perspective.SPATIAL_CONTEXT)
            self.assertEqual(wf.provenance.origin, FactOrigin.ASSERTED)

        # Mitochondrial inner membrane should be present as a possible world
        worlds = {wf.world for wf in world_facts}
        self.assertIn("mitochondrial_inner_membrane", worlds)

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

    def test_dynamic_header_version_fallback(self) -> None:
        sample_obo = (
            "format-version: 1.2\n"
            "date: 14:11:2026 12:00\n"
            "ontology: test_ont\n"
            "\n"
            "[Term]\n"
            "id: TEST:001\n"
            "name: test item\n"
        )
        lines = sample_obo.splitlines(keepends=True)
        meta = self.adapter._extract_obo_header(lines)
        self.assertEqual(meta.get("date"), "14:11:2026 12:00")


if __name__ == "__main__":
    unittest.main()
