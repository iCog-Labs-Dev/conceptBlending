from __future__ import annotations

import os
import re
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[1] / "python"))

import generalization_support as support
import cartesian_generalization as cartesian

COMPONENT_ROOT = HERE.parents[1]
_PREVIOUS_LOG_MODE = None


def setUpModule() -> None:
    global _PREVIOUS_LOG_MODE
    _PREVIOUS_LOG_MODE = os.environ.get("PIPELINE_LOG_MODE")
    os.environ["PIPELINE_LOG_MODE"] = "off"


def tearDownModule() -> None:
    if _PREVIOUS_LOG_MODE is None:
        os.environ.pop("PIPELINE_LOG_MODE", None)
    else:
        os.environ["PIPELINE_LOG_MODE"] = _PREVIOUS_LOG_MODE


class LCGRepairValidationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.paths1 = "((sparrow bird animal) (sparrow flyer animal))"
        self.paths2 = "((airplane aircraft vehicle))"
        self.response = {
            "lcg": "flying_entity",
            "path1": {
                "left": "bird",
                "right": "animal",
                "left_stv": [0.8, 0.7],
                "right_stv": [0.7, 0.6],
            },
            "path2": {
                "left": "vehicle",
                "right": None,
                "left_stv": [0.9, 0.8],
                "right_stv": None,
            },
        }

    def test_accepts_only_evidence_anchored_repair(self) -> None:
        repair = support.validate_lcg_repair(
            self.response,
            "sparrow",
            "airplane",
            support._paths(self.paths1, "sparrow"),
            support._paths(self.paths2, "airplane"),
        )
        rendered = support.render_lcg_repair(repair)
        self.assertIn("(LCGRepair flying_entity", rendered)
        self.assertIn("(Path vehicle () (stv 0.9 0.8) ())", rendered)

    def test_rejects_non_adjacent_splice(self) -> None:
        self.response["path1"]["left"] = "sparrow"
        self.response["path1"]["right"] = "animal"
        with self.assertRaises(support.GeneralizationError):
            support.validate_lcg_repair(
                self.response,
                "sparrow",
                "airplane",
                support._paths(self.paths1, "sparrow"),
                support._paths(self.paths2, "airplane"),
            )

    def test_accepts_lcg_already_present_on_exactly_one_side(self) -> None:
        self.response["lcg"] = "animal"
        repair = support.validate_lcg_repair(
            self.response,
            "sparrow",
            "airplane",
            support._paths(self.paths1, "sparrow"),
            support._paths(self.paths2, "airplane"),
        )
        self.assertEqual(repair["lcg"], "animal")

    def test_rejects_lcg_already_common_to_both_sides(self) -> None:
        self.response["lcg"] = "animal"
        with self.assertRaisesRegex(
            support.GeneralizationError, "already common"
        ):
            support.validate_lcg_repair(
                self.response,
                "sparrow",
                "airplane",
                support._paths(self.paths1, "sparrow"),
                support._paths("((airplane vehicle animal))", "airplane"),
            )

    def test_native_petta_arrow_path_is_normalized(self) -> None:
        self.assertEqual(
            support._paths(
                [["sparrow", "->", "bird", "->", "animal"]], "sparrow"
            ),
            [["sparrow", "bird", "animal"]],
        )

    def test_rejects_compound_taxonomy_node_with_diagnostic(self) -> None:
        with self.assertRaisesRegex(
            support.GeneralizationError,
            r"unsafe path symbol .*surface.*water.*raw path=",
        ):
            support._paths("((sea -> (surface water)))", "sea")

    def test_mocked_provider_runs_complete_repair_pipeline(self) -> None:
        with patch.dict(
            os.environ,
            {
                "OPENAI_API_KEY": "test-key",
                "GENERALIZATION_LLM_MODE": "verify",
                "GENERALIZATION_CACHE_MODE": "off",
            },
            clear=False,
        ):
            with patch.object(support, "_call_openai", return_value=self.response):
                rendered = support.repair_lcg(
                    "sparrow", "airplane", self.paths1, self.paths2
                )
        self.assertIn("(LCGRepair flying_entity", rendered)

    def test_invalid_anchor_is_retried_with_validator_feedback(self) -> None:
        invalid = {
            **self.response,
            "path1": {**self.response["path1"], "left": "invented_anchor"},
        }
        with patch.dict(
            os.environ,
            {
                "OPENAI_API_KEY": "test-key",
                "GENERALIZATION_LLM_MODE": "verify",
                "GENERALIZATION_CACHE_MODE": "off",
                "GENERALIZATION_LLM_MAX_ATTEMPTS": "3",
                "GENERALIZATION_LLM_FAILURE_POLICY": "error",
            },
            clear=False,
        ):
            with patch.object(
                support, "_call_openai", side_effect=[invalid, self.response]
            ) as provider:
                rendered = support.repair_lcg(
                    "sparrow", "airplane", self.paths1, self.paths2
                )
        self.assertIn("flying_entity", rendered)
        self.assertEqual(provider.call_count, 2)
        self.assertIn("invented_anchor", provider.call_args_list[1].args[0])
        self.assertIn("not on a path", provider.call_args_list[1].args[0])

    def test_retry_exhaustion_reports_attempt_count(self) -> None:
        invalid = {
            **self.response,
            "path1": {**self.response["path1"], "left": "invented_anchor"},
        }
        with patch.dict(
            os.environ,
            {
                "OPENAI_API_KEY": "test-key",
                "GENERALIZATION_LLM_MODE": "verify",
                "GENERALIZATION_CACHE_MODE": "off",
                "GENERALIZATION_LLM_MAX_ATTEMPTS": "2",
                "GENERALIZATION_LLM_FAILURE_POLICY": "error",
            },
            clear=False,
        ):
            with patch.object(support, "_call_openai", return_value=invalid):
                with self.assertRaisesRegex(
                    support.GeneralizationError, "after 2 attempts"
                ):
                    support.repair_lcg(
                        "sparrow", "airplane", self.paths1, self.paths2
                    )

    def test_off_mode_is_deterministic_and_network_free(self) -> None:
        previous = os.environ.get("GENERALIZATION_LLM_MODE")
        os.environ["GENERALIZATION_LLM_MODE"] = "off"
        try:
            self.assertEqual(
                support.repair_lcg("sparrow", "airplane", self.paths1, self.paths2),
                "()",
            )
        finally:
            if previous is None:
                os.environ.pop("GENERALIZATION_LLM_MODE", None)
            else:
                os.environ["GENERALIZATION_LLM_MODE"] = previous

    def test_default_verify_falls_back_without_api_key(self) -> None:
        with patch.dict(
            os.environ,
            {"GENERALIZATION_CACHE_MODE": "off"},
            clear=True,
        ):
            with patch.object(support, "_call_openai") as provider:
                self.assertEqual(
                    support.repair_lcg(
                        "sparrow", "airplane", self.paths1, self.paths2
                    ),
                    "()",
                )
        provider.assert_not_called()

    def test_default_llm_policy_errors_after_three_attempts(self) -> None:
        invalid = {
            **self.response,
            "path1": {**self.response["path1"], "left": "invented_anchor"},
        }
        with patch.dict(
            os.environ,
            {
                "OPENAI_API_KEY": "test-key",
                "GENERALIZATION_CACHE_MODE": "off",
            },
            clear=True,
        ):
            with patch.object(
                support, "_call_openai", return_value=invalid
            ) as provider:
                with self.assertRaisesRegex(
                    support.GeneralizationError, "after 3 attempts"
                ):
                    support.repair_lcg(
                        "sparrow", "airplane", self.paths1, self.paths2
                    )
        self.assertEqual(provider.call_count, 3)

    def test_cache_is_enabled_by_default(self) -> None:
        with patch.dict(os.environ, {}, clear=True):
            self.assertTrue(support.generalization_cache.enabled())


class AlgebraicGeneralizationTests(unittest.TestCase):
    BOAT = """(Concept boat functional_use
      (spec
        (sorts ((boat (stv 0.95 0.90)) (cargo (stv 0.80 0.70))))
        (ops (((operation move_boat (arrow boat cargo boat)) (stv 0.90 0.80))
              ((operation anchor_boat (arrow boat boat)) (stv 0.70 0.60))))
        (preds (((usable boat) (stv 0.88 0.77))))
        (axioms (((=> true (usable boat)) (stv 0.80 0.70))))))"""

    CAR = """(Concept car functional_use
      (spec
        (sorts ((car (stv 0.92 0.85)) (cargo (stv 0.90 0.65))))
        (ops (((operation move_car (arrow car cargo car)) (stv 0.85 0.75))
              ((operation refuel_car (arrow car car)) (stv 0.75 0.65))))
        (preds (((usable car) (stv 0.82 0.72))))
        (axioms (((=> true (usable car)) (stv 0.75 0.65))))))"""

    def resolutions(self, shared: bool = False):
        plan = support.parse_metta(
            support.build_cartesian_plan("functional_use", self.BOAT, self.CAR)
        )
        requests = plan[1][1]
        values = []
        for _, request_id, left, right in requests:
            generic = left if left == right else ("shared" if shared else f"g_{request_id}")
            values.append(
                ["PairResolution", request_id, generic, ["stv", "0.9", "0.85"]]
            )
        return ["PairResolutions", values]

    def test_plans_the_full_section_cartesian_products(self) -> None:
        self.assertEqual(
            support.cartesian_pair_counts("functional_use", self.BOAT, self.CAR),
            {"sorts": 4, "ops": 4, "preds": 1, "axioms": 1},
        )

    def test_three_by_three_sorts_produce_nine_pairs(self) -> None:
        left = """(Concept house functional_use
          (spec
            (sorts ((house (stv 0.9 0.8)) (person (stv 0.9 0.8))
                    (dwelling_state (stv 0.9 0.8))))
            (ops ()) (preds ()) (axioms ())))"""
        right = """(Concept cabin functional_use
          (spec
            (sorts ((cabin (stv 0.9 0.8)) (person (stv 0.9 0.8))
                    (dwelling_state (stv 0.9 0.8))))
            (ops ()) (preds ()) (axioms ())))"""
        counts = support.cartesian_pair_counts("functional_use", left, right)
        self.assertEqual(counts["sorts"], 9)

    def test_reconstructs_every_resolved_entry_pair(self) -> None:
        result = support.assemble_cartesian_spec(
            "vehicle",
            "functional_use",
            self.BOAT,
            self.CAR,
            self.resolutions(),
        )
        parsed = support.parse_metta(result)
        sections = {section[0]: section[1] for section in parsed[3][1:]}
        self.assertEqual(len(sections["sorts"]), 4)
        self.assertEqual(len(sections["ops"]), 4)
        self.assertEqual(len(sections["preds"]), 1)
        self.assertEqual(len(sections["axioms"]), 1)

    def test_deduplicates_with_max_lattice_join(self) -> None:
        result = support.assemble_cartesian_spec(
            "vehicle",
            "functional_use",
            self.BOAT,
            self.CAR,
            self.resolutions(shared=True),
        )
        self.assertEqual(result.count("(shared (stv 0.9 0.85))"), 1)

    def test_rejects_an_incomplete_resolution_set(self) -> None:
        with self.assertRaisesRegex(
            support.GeneralizationError, "Cartesian concept pairs have no LCG"
        ):
            support.assemble_cartesian_spec(
                "vehicle",
                "functional_use",
                self.BOAT,
                self.CAR,
                ["PairResolutions", []],
            )

    def test_internal_validator_rejects_uppercase_relation_head(self) -> None:
        output = {
            "sorts": [["entity", ["stv", "0.8", "0.7"]]],
            "ops": [],
            "preds": [[["Object", "entity"], ["stv", "0.8", "0.7"]]],
            "axioms": [],
        }
        result = support.render_metta(
            [
                "Concept",
                "generic",
                "functional_use",
                ["spec", *[[section, output[section]] for section in (
                    "sorts", "ops", "preds", "axioms"
                )]],
            ]
        )
        with self.assertRaisesRegex(
            support.GeneralizationError, "relation head.*lowercase"
        ):
            cartesian._validate_result(
                result, "generic", "functional_use", output
            )

    def test_rejects_cross_perspective_inputs(self) -> None:
        with self.assertRaises(support.GeneralizationError):
            support.build_cartesian_plan(
                "structural_composition", self.BOAT, self.CAR
            )


class LCGSelectionTests(unittest.TestCase):
    PROOFS = """(
      (: (LCG-D1-C11-C20 sparrowm airplanem flying_entitym)
         (≞ (→ sparrow airplane (flying_entity)) (stv 0.94 0.38)))
      (: (LCG-D2-C12-C21 sparrowm airplanem vertebratem)
         (≞ (→ sparrow airplane (vertebrate)) (stv 0.99 0.90)))
      (: (LCG-D1-C10-C21 sparrowm airplanem aerial_entitym)
         (≞ (→ sparrow airplane (aerial_entity)) (stv 0.90 0.80))))"""

    def test_normalizes_all_and_only_minimum_depth_lcgs(self) -> None:
        result = support.normalize_lcg_proofs("sparrow", "airplane", self.PROOFS)
        self.assertIn("(: sparrowairplanem", result)
        self.assertIn("(flying_entity)", result)
        self.assertIn("(aerial_entity)", result)
        self.assertNotIn("vertebrate", result)

    def test_downstream_resolutions_preserve_multiple_selected_lcgs(self) -> None:
        normalized = support.normalize_lcg_proofs(
            "sparrow", "airplane", self.PROOFS
        )
        result = support.resolutions_from_proofs(
            "pair_1", "sparrow", "airplane", normalized
        )
        parsed = support.parse_metta(result)
        self.assertEqual(len(parsed), 2)
        self.assertEqual({item[2] for item in parsed}, {"flying_entity", "aerial_entity"})

    def test_graph_paths_find_deep_sea_land_lcg(self) -> None:
        sea = """(((GeneralizationStep sea (stv 1 1))
                    (GeneralizationStep surface_water (stv 0.9 0.86))
                    (GeneralizationStep watershed (stv 0.9 0.86))
                    (GeneralizationStep hydrologic_system (stv 0.9 0.86))))"""
        land = """(((GeneralizationStep land (stv 1 1))
                     (GeneralizationStep land_surface (stv 0.88 0.84))
                     (GeneralizationStep landform (stv 0.9 0.86))
                     (GeneralizationStep terrain (stv 0.9 0.85))
                     (GeneralizationStep geosphere (stv 0.9 0.87))
                     (GeneralizationStep hydrologic_system (stv 0.9 0.85))))"""
        result = support.graph_lcg_proofs("sea", "land", sea, land)
        self.assertIn("(hydrologic_system)", result)
        self.assertIn("(stv 0.88 0.84)", result)

    def test_graph_paths_keep_equal_depth_colour_lcgs(self) -> None:
        red = """(((GeneralizationStep red (stv 1 1))
                    (GeneralizationStep color (stv 0.6 0.4)))
                   ((GeneralizationStep red (stv 1 1))
                    (GeneralizationStep colour (stv 0.6 0.4))))"""
        blue = """(((GeneralizationStep blue (stv 1 1))
                     (GeneralizationStep color (stv 0.6 0.4)))
                    ((GeneralizationStep blue (stv 1 1))
                     (GeneralizationStep colour (stv 0.6 0.4))))"""
        result = support.graph_lcg_proofs("red", "blue", red, blue)
        parsed = support.parse_metta(result)
        self.assertEqual({proof[2][1][3][0] for proof in parsed}, {"color", "colour"})


class GeneralizationCacheTests(unittest.TestCase):
    LEFT = """(Concept house functional_use
      (spec (sorts ((house (stv 0.9 0.8))))
            (ops ()) (preds ()) (axioms ())))"""
    RIGHT = """(Concept cabin functional_use
      (spec (sorts ((cabin (stv 0.8 0.7))))
            (ops ()) (preds ()) (axioms ())))"""
    RESULT = """(Concept building functional_use
      (spec (sorts ((building (stv 0.8 0.7))))
            (ops ()) (preds ()) (axioms ())))"""

    def cache_environment(self, root: str):
        kb = Path(root) / "kb.metta"
        kb.write_text("(: test evidence)\n", encoding="utf-8")
        return patch.dict(
            os.environ,
            {
                "GENERALIZATION_CACHE_MODE": "on",
                "GENERALIZATION_CACHE_PATH": str(Path(root) / "cache.jsonl"),
                "GENERALIZATION_CACHE_KB": str(kb),
                "GENERALIZATION_UNRESOLVED_POLICY": "error",
            },
            clear=False,
        )

    def test_generic_spec_round_trip_and_input_invalidation(self) -> None:
        with tempfile.TemporaryDirectory() as root, self.cache_environment(root):
            self.assertEqual(
                support.lookup_generic_algebraic_spec(
                    "building", "functional_use", self.LEFT, self.RIGHT, 10
                ),
                "()",
            )
            self.assertTrue(
                support.persist_generic_algebraic_spec(
                    "building", "functional_use", self.LEFT, self.RIGHT, 10,
                    self.RESULT,
                )
            )
            cached = support.lookup_generic_algebraic_spec(
                "building", "functional_use", self.LEFT, self.RIGHT, 10
            )
            self.assertEqual(support.canonical_metta(self.RESULT), cached)
            changed = self.RIGHT.replace("0.8 0.7", "0.7 0.6")
            self.assertEqual(
                support.lookup_generic_algebraic_spec(
                    "building", "functional_use", self.LEFT, changed, 10
                ),
                "()",
            )

    def test_partial_omit_result_is_not_persisted(self) -> None:
        with tempfile.TemporaryDirectory() as root, self.cache_environment(root):
            os.environ["GENERALIZATION_UNRESOLVED_POLICY"] = "omit"
            self.assertFalse(
                support.persist_generic_algebraic_spec(
                    "building", "functional_use", self.LEFT, self.RIGHT, 10,
                    self.RESULT,
                )
            )
            self.assertEqual(
                support.lookup_generic_algebraic_spec(
                    "building", "functional_use", self.LEFT, self.RIGHT, 10
                ),
                "()",
            )

    def test_pair_repair_cache_is_reused_with_llm_off(self) -> None:
        response = {
            "lcg": "flying_entity",
            "path1": {
                "left": "bird", "right": "animal",
                "left_stv": [0.8, 0.7], "right_stv": [0.7, 0.6],
            },
            "path2": {
                "left": "vehicle", "right": None,
                "left_stv": [0.9, 0.8], "right_stv": None,
            },
        }
        with tempfile.TemporaryDirectory() as root, self.cache_environment(root):
            os.environ["OPENAI_API_KEY"] = "test-key"
            os.environ["GENERALIZATION_LLM_MODE"] = "verify"
            with patch.object(support, "_call_openai", return_value=response) as call:
                first = support.repair_lcg(
                    "sparrow", "airplane",
                    "((sparrow bird animal))", "((airplane vehicle))",
                )
                os.environ["GENERALIZATION_LLM_MODE"] = "off"
                second = support.repair_lcg(
                    "sparrow", "airplane",
                    "((sparrow bird animal))", "((airplane vehicle))",
                )
            self.assertEqual(first, second)
            call.assert_called_once()

    def test_legacy_pair_cache_is_promoted_to_early_key(self) -> None:
        paths1, paths2 = [["sparrow", "bird", "animal"]], [["airplane", "vehicle"]]
        repair = {
            "lcg": "flying_entity",
            "path1": {
                "left": "bird", "right": "animal",
                "left_stv": [0.8, 0.7], "right_stv": [0.7, 0.6],
            },
            "path2": {
                "left": "vehicle", "right": None,
                "left_stv": [0.9, 0.8], "right_stv": None,
            },
        }
        with tempfile.TemporaryDirectory() as root, self.cache_environment(root):
            _, _, payload, _ = support._pair_cache_identity("sparrow", "airplane")
            legacy_key = support.generalization_cache.content_key(
                "pair_lcg_repair",
                {**payload, "paths1": paths1, "paths2": paths2},
            )
            support.generalization_cache.persist(
                "pair_lcg_repair", legacy_key, repair
            )
            os.environ["GENERALIZATION_LLM_MODE"] = "off"
            result = support.repair_lcg(
                "sparrow", "airplane",
                "((sparrow bird animal))", "((airplane vehicle))",
            )
            self.assertIn("flying_entity", result)
            self.assertIn(
                "flying_entity",
                support.lookup_cached_lcg_repair("sparrow", "airplane", "kb"),
            )

    def test_cache_off_disables_reads_and_writes(self) -> None:
        with tempfile.TemporaryDirectory() as root, self.cache_environment(root):
            os.environ["GENERALIZATION_CACHE_MODE"] = "off"
            self.assertFalse(
                support.persist_generic_algebraic_spec(
                    "building", "functional_use", self.LEFT, self.RIGHT, 10,
                    self.RESULT,
                )
            )
            self.assertFalse((Path(root) / "cache.jsonl").exists())


class ComponentBoundaryTests(unittest.TestCase):
    IMPORT_RE = re.compile(
        r"\((?:static-)?import!\s+\S+\s+(\"[^\"]+\"|[^\s)]+)"
    )

    def test_only_lib_import_resolves_outside_component(self) -> None:
        for source in COMPONENT_ROOT.rglob("*.metta"):
            if "kb" in source.relative_to(COMPONENT_ROOT).parts:
                continue
            for raw_target in self.IMPORT_RE.findall(source.read_text()):
                target = raw_target.strip('"')
                if ".." in Path(target).parts:
                    self.assertTrue(
                        target.endswith("PeTTa/lib/lib_import"),
                        f"{source} imports external target {target}",
                    )
                    continue
                candidates = [
                    COMPONENT_ROOT / target,
                    COMPONENT_ROOT / f"{target}.metta",
                    COMPONENT_ROOT / f"{target}.py",
                ]
                self.assertTrue(
                    any(candidate.exists() for candidate in candidates),
                    f"{source} imports missing local target {target}",
                )

    def test_python_does_not_reference_an_external_component(self) -> None:
        for source in (COMPONENT_ROOT / "python").glob("*.py"):
            self.assertNotIn(
                "v-predicate-extraction-pipeline", source.read_text()
            )


if __name__ == "__main__":
    unittest.main()
