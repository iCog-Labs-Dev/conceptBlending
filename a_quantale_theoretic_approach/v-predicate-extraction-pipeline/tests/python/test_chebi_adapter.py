"""Unit tests for ChEBI source adapter (TDD Red -> Green)."""

from pathlib import Path
import pytest

from ingestion.models import FactType, KnowledgeSource
from ingestion.chebi_adapter import ChebiAdapter


@pytest.fixture
def chebi_adapter() -> ChebiAdapter:
    fixture_path = (
        Path(__file__).resolve().parents[2] / "fixtures" / "phenol_sub_chebi.obo"
    )
    return ChebiAdapter(obo_path=fixture_path)


class TestChebiAdapter:
    def test_source_type(self, chebi_adapter: ChebiAdapter):
        assert chebi_adapter.source_type == KnowledgeSource.CHEBI
        assert chebi_adapter.provenance.source == KnowledgeSource.CHEBI
        assert "chebi" in chebi_adapter.provenance.source_uri_or_path.lower()

    def test_chebi_parsing_and_obsolete_purging(self, chebi_adapter: ChebiAdapter):
        terms = list(chebi_adapter.parse_obo(chebi_adapter.obo_path))
        assert len(terms) >= 7

        term_ids = {t["id"] for t in terms}
        assert "CHEBI:16127" in term_ids  # phenol
        assert "CHEBI:22712" in term_ids  # benzene
        assert "CHEBI:43176" in term_ids  # hydroxyl group
        assert "CHEBI:33854" in term_ids  # phenolate
        assert "CHEBI:99999" not in term_ids  # obsolete term must be purged

        # Find phenol term and inspect parsed chemical relations
        phenol_term = next(t for t in terms if t["id"] == "CHEBI:16127")
        assert phenol_term["name"].lower() == "phenol"
        rel_types = {rel[0] for rel in phenol_term.get("relationships", [])}
        assert "has_part" in rel_types
        assert "is_conjugate_acid_of" in rel_types
        assert "has_role" in rel_types

    def test_chemical_relationship_perspective_mapping(self, chebi_adapter: ChebiAdapter):
        records = list(chebi_adapter.extract_raw_records())
        assert len(records) > 0

        perspectives = {}
        for raw in records:
            norm = chebi_adapter.normalize_record(raw)
            if norm:
                perspectives[(raw.relation, norm.perspective)] = norm

        # is_a -> taxonomic-kind
        assert any(k[0] == "is_a" and k[1] == "taxonomic-kind" for k in perspectives)
        # has_part -> structural-composition
        assert any(k[0] == "has_part" and k[1] == "structural-composition" for k in perspectives)
        # has_role -> functional-use
        assert any(k[0] == "has_role" and k[1] == "functional-use" for k in perspectives)
        # is_conjugate_acid_of -> state-lifecycle or behavioral-process
        assert any(
            k[0] == "is_conjugate_acid_of" and k[1] in {"state-lifecycle", "behavioral-process"}
            for k in perspectives
        )

    def test_transform_to_casl_facts(self, chebi_adapter: ChebiAdapter):
        records = list(chebi_adapter.extract_raw_records())
        all_casl = []
        for raw in records:
            norm = chebi_adapter.normalize_record(raw)
            if norm:
                facts = chebi_adapter.transform_to_casl(norm)
                all_casl.extend(facts)

        fact_types = {f.fact_type for f in all_casl}
        assert FactType.HAS_SORT in fact_types
        assert FactType.HAS_OPERATION in fact_types
        assert FactType.OPERATION_SIGNATURE in fact_types
        assert FactType.HAS_PREDICATE in fact_types

        # Verify operation and operation_signature edge alignment (MeTTa spec-operation-rule)
        op_facts = [f for f in all_casl if f.fact_type == FactType.HAS_OPERATION]
        sig_facts = [f for f in all_casl if f.fact_type == FactType.OPERATION_SIGNATURE]
        assert len(op_facts) > 0
        assert len(sig_facts) == len(op_facts)

        # Extract edge IDs from has_operation and operation_signature
        for op, sig in zip(op_facts, sig_facts):
            op_edge = op.expression.split()[1]
            sig_edge = sig.expression.split()[1]
            assert op_edge == sig_edge

    def test_transform_to_property_world_facts(self, chebi_adapter: ChebiAdapter):
        records = list(chebi_adapter.extract_raw_records())
        all_pw = []
        for raw in records:
            norm = chebi_adapter.normalize_record(raw)
            if norm:
                facts = chebi_adapter.transform_to_property_world(norm)
                all_pw.extend(facts)

        pw_types = {f.fact_type for f in all_pw}
        assert FactType.HAS_SCOPED_PROPERTY in pw_types
        assert FactType.SCOPED_PROPERTY_HOLDS_IN in pw_types
        assert FactType.PERSPECTIVE_MATCH in pw_types

        # Verify perspective_match has exact arity 3 matching MeTTa rule contracts
        pm_facts = [f for f in all_pw if f.fact_type == FactType.PERSPECTIVE_MATCH]
        assert len(pm_facts) > 0
        for pm in pm_facts:
            tokens = pm.expression.strip("()").split()
            assert tokens[0] == "perspective_match"
            assert len(tokens) == 4  # head + 3 arguments: (perspective_match req eff class)

        # Check that chemical entities serve as possible worlds
        holds_in = [f for f in all_pw if f.fact_type == FactType.SCOPED_PROPERTY_HOLDS_IN]
        assert len(holds_in) > 0
        assert any("phenol" in f.expression or "water" in f.expression or "solution" in f.expression for f in holds_in)

    def test_offline_determinism(self, chebi_adapter: ChebiAdapter):
        # Fetching without download must return local obo path and never touch network
        path = chebi_adapter.fetch(download=False)
        assert path.exists()
        assert path == chebi_adapter.obo_path

    def test_phenol_blending_domain_assertions(self, chebi_adapter: ChebiAdapter):
        """Verify domain facts required for Experiment 3 (Phenol conceptual blending)."""
        records = list(chebi_adapter.extract_raw_records())
        norm_records = [chebi_adapter.normalize_record(r) for r in records if chebi_adapter.normalize_record(r)]

        # Phenol structural composition: has parts benzene and hydroxyl group
        phenol_parts = {
            r.property_or_target
            for r in norm_records
            if r.concept == "phenol" and r.perspective == "structural-composition"
        }
        assert "benzene" in phenol_parts
        assert "hydroxyl_group" in phenol_parts

        # Phenol state-lifecycle: dissociation to phenolate
        phenol_dissoc = [
            r
            for r in norm_records
            if r.concept == "phenol" and r.perspective == "state-lifecycle"
        ]
        assert len(phenol_dissoc) > 0
        assert any(r.property_or_target == "phenolate" for r in phenol_dissoc)

        # CASL equational axioms for phenol dissociation
        casl_facts = []
        for r in phenol_dissoc:
            casl_facts.extend(chebi_adapter.transform_to_casl(r))
        axiom_facts = [f for f in casl_facts if f.fact_type == FactType.HAS_AXIOM]
        assert any("reversible-equilibrium" in f.expression and "phenolate" in f.expression for f in axiom_facts)

