"""Unit tests for OpenMath source adapter under canonical v-predicate/1 contract."""

from pathlib import Path
import pytest

from ingestion.openmath_adapter import OpenMathAdapter
from v_predicate_contract import (
    CONTRACT_VERSION,
    AxiomFact,
    FactKind,
    FactOrigin,
    OperationFact,
    OperationSignatureFact,
    Perspective,
    PredicateFact,
    PredicateSignatureFact,
    PropertyFact,
    PropertyWorldFact,
    SortFact,
    render_document,
    validate_record_set,
)


@pytest.fixture
def openmath_adapter() -> OpenMathAdapter:
    fixture_path = (
        Path(__file__).resolve().parents[2] / "fixtures" / "group_theory_sub_openmath.ocd"
    )
    return OpenMathAdapter(ocd_path=fixture_path)


class TestOpenMathAdapter:
    def test_adapter_metadata(self, openmath_adapter: OpenMathAdapter):
        assert openmath_adapter.source_name == "openmath"
        assert openmath_adapter.version == "2.0"
        assert openmath_adapter.license == "OpenMath-2.0"
        assert "openmath" in openmath_adapter.source_uri.lower()

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

        abelian_def = next(d for d in definitions if d["name"] == "is_abelian")
        assert "commutative" in abelian_def.get("description", "").lower() or "for all" in abelian_def.get("cmp", "").lower()
        assert abelian_def.get("fmp") is not None

    def test_fetch_fixture_path(self, openmath_adapter: OpenMathAdapter):
        path = openmath_adapter.fetch(download=False)
        assert path.exists()
        assert path == openmath_adapter.ocd_path

    def test_stream_facts_generator_and_limit(self, openmath_adapter: OpenMathAdapter):
        stream = openmath_adapter.stream_facts(limit=6)
        assert hasattr(stream, "__iter__")
        assert hasattr(stream, "__next__")
        facts = list(stream)
        assert len(facts) == 6

    def test_canonical_perspectives(self, openmath_adapter: OpenMathAdapter):
        facts = list(openmath_adapter.stream_facts())
        assert len(facts) > 0
        perspective_facts = [f for f in facts if hasattr(f, "perspective")]
        assert len(perspective_facts) > 0
        for f in perspective_facts:
            assert isinstance(f.perspective, Perspective)
            assert "-" not in f.perspective.value
            assert f.perspective in {
                Perspective.TAXONOMIC_KIND,
                Perspective.STRUCTURAL_COMPOSITION,
                Perspective.INFORMATION_COMPUTATIONAL,
            }

    def test_paired_operations_and_signatures(self, openmath_adapter: OpenMathAdapter):
        facts = list(openmath_adapter.stream_facts())
        op_facts = {f.edge_id: f for f in facts if isinstance(f, OperationFact)}
        sig_facts = {f.edge_id: f for f in facts if isinstance(f, OperationSignatureFact)}

        assert len(op_facts) > 0
        assert len(sig_facts) > 0

        # Every signature must reference an existing operation edge
        for edge_id in sig_facts:
            assert edge_id in op_facts
            assert "(arrow " in sig_facts[edge_id].signature

        # Binary operation has arity 3 arrow
        binary_op = next(f for f in op_facts.values() if f.operation == "operation")
        binary_sig = sig_facts[binary_op.edge_id]
        assert binary_sig.signature == "(arrow group group group)"

    def test_paired_predicates_and_signatures(self, openmath_adapter: OpenMathAdapter):
        facts = list(openmath_adapter.stream_facts())
        pred_facts = {f.edge_id: f for f in facts if isinstance(f, PredicateFact)}
        psig_facts = {f.edge_id: f for f in facts if isinstance(f, PredicateSignatureFact)}

        assert len(pred_facts) > 0
        assert len(psig_facts) > 0
        for edge_id in psig_facts:
            assert edge_id in pred_facts
            assert psig_facts[edge_id].signature == "(arrow group Boolean)"

    def test_executable_equational_axioms(self, openmath_adapter: OpenMathAdapter):
        facts = list(openmath_adapter.stream_facts())
        axiom_facts = [f for f in facts if isinstance(f, AxiomFact)]
        assert len(axiom_facts) >= 3

        for ax in axiom_facts:
            assert ax.axiom.startswith("(= ")
            assert ax.truth.strength == 1.0
            assert ax.truth.confidence == 1.0
            assert ax.provenance.origin == FactOrigin.ASSERTED

        # Core axioms: associativity and commutativity
        assert any("operation (operation $x $y) $z" in ax.axiom for ax in axiom_facts)
        assert any("operation $x $y) (operation $y $x)" in ax.axiom for ax in axiom_facts)

    def test_mathematical_structures_as_possible_worlds(self, openmath_adapter: OpenMathAdapter):
        facts = list(openmath_adapter.stream_facts())
        world_facts = [f for f in facts if isinstance(f, PropertyWorldFact)]
        assert len(world_facts) > 0

        worlds = {wf.world for wf in world_facts}
        assert "integers_under_addition" in worlds
        assert "abelian_group" in worlds
        assert "cyclic_group_z_n" in worlds

    def test_deterministic_reruns(self, openmath_adapter: OpenMathAdapter):
        facts1 = list(openmath_adapter.stream_facts())
        facts2 = list(openmath_adapter.stream_facts())
        assert [f.evidence_id for f in facts1] == [f.evidence_id for f in facts2]
        assert [f.to_metta() for f in facts1] == [f.to_metta() for f in facts2]

    def test_contract_validation_passes(self, openmath_adapter: OpenMathAdapter):
        facts = list(openmath_adapter.stream_facts())
        assert len(facts) > 10
        validate_record_set(facts)

    def test_render_document_compatibility(self, openmath_adapter: OpenMathAdapter):
        facts = list(openmath_adapter.stream_facts(limit=10))
        rendered = render_document(facts)
        assert f"; V-predicate contract: {CONTRACT_VERSION}" in rendered
        for fact in facts:
            assert f"(: {fact.evidence_id} (≞ " in rendered
            assert f"(: {fact.evidence_id}_provenance (≞ " in rendered
