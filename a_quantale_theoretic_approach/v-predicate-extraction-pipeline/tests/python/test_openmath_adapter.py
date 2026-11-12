"""Unit tests for OpenMath source adapter (TDD Red -> Green)."""

from pathlib import Path
import pytest

from ingestion.models import FactType, KnowledgeSource
from ingestion.openmath_adapter import OpenMathAdapter


@pytest.fixture
def openmath_adapter() -> OpenMathAdapter:
    fixture_path = (
        Path(__file__).resolve().parents[2] / "fixtures" / "group_theory_sub_openmath.ocd"
    )
    return OpenMathAdapter(ocd_path=fixture_path)


class TestOpenMathAdapter:
    def test_source_type(self, openmath_adapter: OpenMathAdapter):
        assert openmath_adapter.source_type == KnowledgeSource.OPENMATH
        assert openmath_adapter.provenance.source == KnowledgeSource.OPENMATH
        assert "openmath" in openmath_adapter.provenance.source_uri_or_path.lower()

    def test_openmath_xml_parsing(self, openmath_adapter: OpenMathAdapter):
        definitions = list(openmath_adapter.parse_ocd(openmath_adapter.ocd_path))
        assert len(definitions) >= 6

        def_names = {d["name"] for d in definitions}
        assert "group" in def_names
        assert "abelian_group" in def_names
        assert "identity" in def_names
        assert "inverse" in def_names
        assert "operation" in def_names
        assert "is_associative" in def_names
        assert "is_abelian" in def_names

        # Check CMP and FMP extraction on is_abelian
        abelian_def = next(d for d in definitions if d["name"] == "is_abelian")
        assert "commutative" in abelian_def.get("description", "").lower() or "for all" in abelian_def.get("cmp", "").lower()
        assert abelian_def.get("fmp") is not None

    def test_equational_axiom_extraction(self, openmath_adapter: OpenMathAdapter):
        records = list(openmath_adapter.extract_raw_records())
        axiom_records = [r for r in records if r.relation == "has_axiom"]
        assert len(axiom_records) >= 3

        axiom_formulas = [r.metadata.get("formula", "") for r in axiom_records]

        # Check for core algebraic axioms
        # Associativity: (= (* (* $a $b) $c) (* $a (* $b $c)))
        assert any("=" in f and ("*" in f or "operation" in f) and "$a" in f and "$b" in f and "$c" in f for f in axiom_formulas)
        # Identity: (= (* $x $e) $x) or similar
        assert any("=" in f and ("identity" in f or "$e" in f) for f in axiom_formulas)
        # Commutativity: (= (* $a $b) (* $b $a))
        assert any("=" in f and ("*" in f or "operation" in f) and ("$a $b" in f or "$b $a" in f) for f in axiom_formulas)

    def test_perspective_routing(self, openmath_adapter: OpenMathAdapter):
        records = list(openmath_adapter.extract_raw_records())
        assert len(records) > 0

        perspectives = {}
        for raw in records:
            norm = openmath_adapter.normalize_record(raw)
            if norm:
                perspectives[(raw.relation, norm.perspective)] = norm

        # Types/constructors -> taxonomic-classification
        assert any(k[1] == "taxonomic-classification" for k in perspectives)
        # Operations and axioms -> structural-composition
        assert any(k[1] == "structural-composition" for k in perspectives)
        # Predicates -> quantitative-comparative
        assert any(k[1] == "quantitative-comparative" for k in perspectives)

    def test_transform_to_casl_facts(self, openmath_adapter: OpenMathAdapter):
        records = list(openmath_adapter.extract_raw_records())
        all_casl = []
        for raw in records:
            norm = openmath_adapter.normalize_record(raw)
            if norm:
                facts = openmath_adapter.transform_to_casl(norm)
                all_casl.extend(facts)

        fact_types = {f.fact_type for f in all_casl}
        assert FactType.HAS_SORT in fact_types
        assert FactType.HAS_OPERATION in fact_types
        assert FactType.OPERATION_SIGNATURE in fact_types
        assert FactType.HAS_PREDICATE in fact_types
        assert FactType.HAS_AXIOM in fact_types

        # Verify operation and operation_signature edge alignment
        op_facts = [f for f in all_casl if f.fact_type == FactType.HAS_OPERATION]
        sig_facts = [f for f in all_casl if f.fact_type == FactType.OPERATION_SIGNATURE]
        assert len(op_facts) > 0
        assert len(sig_facts) == len(op_facts)
        for op, sig in zip(op_facts, sig_facts):
            assert op.expression.split()[1] == sig.expression.split()[1]

        # Verify 4-ary has_axiom with composite axiom atom
        axiom_facts = [f for f in all_casl if f.fact_type == FactType.HAS_AXIOM]
        assert len(axiom_facts) > 0
        for ax in axiom_facts:
            assert ax.expression.startswith("(has_axiom ")
            assert "(axiom " in ax.expression

    def test_transform_to_property_world_facts(self, openmath_adapter: OpenMathAdapter):
        records = list(openmath_adapter.extract_raw_records())
        all_pw = []
        for raw in records:
            norm = openmath_adapter.normalize_record(raw)
            if norm:
                facts = openmath_adapter.transform_to_property_world(norm)
                all_pw.extend(facts)

        pw_types = {f.fact_type for f in all_pw}
        assert FactType.HAS_SCOPED_PROPERTY in pw_types
        assert FactType.SCOPED_PROPERTY_HOLDS_IN in pw_types
        assert FactType.PERSPECTIVE_MATCH in pw_types

        # Verify 3-ary perspective_match
        pm_facts = [f for f in all_pw if f.fact_type == FactType.PERSPECTIVE_MATCH]
        assert len(pm_facts) > 0
        for pm in pm_facts:
            tokens = pm.expression.strip("()").split()
            assert tokens[0] == "perspective_match"
            assert len(tokens) == 4  # head + 3 arguments

        # Check mathematical structures as possible worlds
        holds_in = [f for f in all_pw if f.fact_type == FactType.SCOPED_PROPERTY_HOLDS_IN]
        assert len(holds_in) > 0
        assert any("integers" in f.expression or "abelian_group" in f.expression or "cyclic" in f.expression for f in holds_in)

    def test_offline_determinism(self, openmath_adapter: OpenMathAdapter):
        path = openmath_adapter.fetch(download=False)
        assert path.exists()
        assert path == openmath_adapter.ocd_path

    def test_experiment4_abelian_group_blending_assertions(self, openmath_adapter: OpenMathAdapter):
        """Verify algebraic assertions required for Experiment 4 (Abelian Group conceptual blending)."""
        records = list(openmath_adapter.extract_raw_records())
        norm_records = [openmath_adapter.normalize_record(r) for r in records if openmath_adapter.normalize_record(r)]

        # 1. Monoid input space components: associative operation + identity
        op_records = [r for r in norm_records if r.relation == "hasOperation" and r.property_or_target == "operation"]
        assert len(op_records) > 0
        ident_records = [r for r in norm_records if r.property_or_target == "identity"]
        assert len(ident_records) > 0

        # 2. Invertible input space components: inverse operation
        inv_records = [r for r in norm_records if r.relation == "hasOperation" and r.property_or_target == "inverse"]
        assert len(inv_records) > 0

        # 3. Emergent Abelian Blend: commutativity axiom and predicate
        comm_records = [r for r in norm_records if "abelian" in r.property_or_target]
        assert len(comm_records) > 0

        # CASL validation: verify equational commutativity axiom
        casl_facts = []
        for r in norm_records:
            casl_facts.extend(openmath_adapter.transform_to_casl(r))

        axiom_facts = [f for f in casl_facts if f.fact_type == FactType.HAS_AXIOM]
        assert any("ax_is_abelian" in f.expression and "(* $a $b)" in f.expression and "(* $b $a)" in f.expression for f in axiom_facts)

