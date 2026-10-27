"""
Tests that mcbride_runner.metta has correct import paths.
Includes static validation plus a PeTTa runtime integration test when the
``petta`` executable is installed.
"""
import unittest
import os
import shutil
import subprocess


class TestMettaRunnerImports(unittest.TestCase):
    """
    Validates the mcbride_runner.metta import paths without executing MeTTa.
    The original file had bare import names that would fail at runtime.
    """

    def _get_runner_path(self):
        base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        return os.path.join(base, "mcbride_petta", "mcbride_runner.metta")

    def test_runner_file_exists(self):
        path = self._get_runner_path()
        self.assertTrue(os.path.exists(path),
            f"mcbride_runner.metta not found at {path}")

    def test_no_bare_import_names(self):
        """
        Import statements must use full repo-relative paths, not bare names.
        Bare names like 'quantale_types' fail at MeTTa runtime.
        """
        path = self._get_runner_path()
        with open(path) as f:
            content = f.read()

        forbidden_patterns = [
            "!(import! &self quantale_types)",
            "!(import! &self v_predicate)",
            "!(import! &self quantale_colimit_engine)",
        ]
        for pattern in forbidden_patterns:
            self.assertNotIn(
                pattern, content,
                f"Found bare import name in mcbride_runner.metta: '{pattern}'. "
                f"Use full repo-relative path instead."
            )

    def test_correct_full_path_present_without_duplicate_transitive_imports(self):
        """Import the colimit engine once; it supplies the other modules."""
        path = self._get_runner_path()
        with open(path) as f:
            content = f.read()

        refinement_import = (
            "!(import! &self "
            "a_quantale_theoretic_approach/mcbride_petta/"
            "refinement_loop)"
        )
        self.assertIn(refinement_import, content)

        # quantale_colimit_engine imports these transitively. Importing them a
        # second time duplicates PeTTa rewrite rules and can exhaust its stack.
        self.assertNotIn(
            "!(import! &self "
            "a_quantale_theoretic_approach/core_representation/quantale_types)",
            content,
        )
        self.assertNotIn(
            "!(import! &self "
            "a_quantale_theoretic_approach/core_representation/v_predicate)",
            content,
        )

    def test_mcbride_refine_function_defined(self):
        """mcbride-refine must be defined in the runner."""
        path = self._get_runner_path()
        with open(path) as f:
            content = f.read()
        self.assertIn("mcbride-refine", content)

    def test_quantale_blend_and_refine_defined(self):
        """The full pipeline combinator must be defined."""
        path = self._get_runner_path()
        with open(path) as f:
            content = f.read()
        self.assertIn("quantale-blend-and-refine", content)


class TestMettaRunnerRuntime(unittest.TestCase):
    """Execute every public runner operation in the real PeTTa runtime."""

    @unittest.skipUnless(shutil.which("petta"), "PeTTa executable is not installed")
    def test_public_operations_return_expected_results(self):
        tests_dir = os.path.dirname(os.path.abspath(__file__))
        fixture = "mcbride_runner_runtime_test.metta"

        completed = subprocess.run(
            ["petta", fixture],
            cwd=tests_dir,
            capture_output=True,
            text=True,
            timeout=30,
        )

        self.assertEqual(
            completed.returncode,
            0,
            f"PeTTa runner failed:\nSTDOUT:\n{completed.stdout}\n"
            f"STDERR:\n{completed.stderr}",
        )

        output_lines = completed.stdout.splitlines()
        expected_assertions = [
            "(assertEqual true true)",
            "(assertEqual Amphibian Amphibian)",
            "(assertEqual false false)",
        ]
        for assertion in expected_assertions:
            self.assertIn(
                assertion,
                output_lines,
                f"PeTTa did not return the expected runtime assertion: {assertion}",
            )


class TestMettaVEnrichedRuntime(unittest.TestCase):
    """Execute the quantale-law and V-enriched contracts in PeTTa."""

    @unittest.skipUnless(shutil.which("petta"), "PeTTa executable is not installed")
    def test_v_enriched_contracts(self):
        tests_dir = os.path.dirname(os.path.abspath(__file__))
        repo_root = os.path.dirname(os.path.dirname(tests_dir))
        fixture = os.path.join(tests_dir, "quantale_petta_enriched_smoke.metta")

        completed = subprocess.run(
            ["petta", fixture],
            cwd=repo_root,
            capture_output=True,
            text=True,
            timeout=30,
        )

        self.assertEqual(
            completed.returncode,
            0,
            f"PeTTa V-enriched contracts failed:\nSTDOUT:\n{completed.stdout}\n"
            f"STDERR:\n{completed.stderr}",
        )
        results = [
            line.strip().lower()
            for line in completed.stdout.splitlines()
            if line.strip().lower() in {"true", "false"}
        ]
        # One True is emitted by import!, followed by thirty-one contract results.
        self.assertEqual(results, ["true"] * 32, completed.stdout)


class TestMettaVitalRelationRuntime(unittest.TestCase):
    """Execute the perspective-aware vital-relation contracts in PeTTa."""

    @unittest.skipUnless(shutil.which("petta"), "PeTTa executable is not installed")
    def test_vital_relation_contracts(self):
        tests_dir = os.path.dirname(os.path.abspath(__file__))
        repo_root = os.path.dirname(os.path.dirname(tests_dir))
        fixture = os.path.join(
            tests_dir, "quantale-petta-vital-relations-smoke.metta"
        )

        completed = subprocess.run(
            ["petta", fixture],
            cwd=repo_root,
            capture_output=True,
            text=True,
            timeout=30,
        )

        self.assertEqual(
            completed.returncode,
            0,
            f"PeTTa vital-relation contracts failed:\nSTDOUT:\n{completed.stdout}\n"
            f"STDERR:\n{completed.stderr}",
        )
        results = [
            line.strip().lower()
            for line in completed.stdout.splitlines()
            if line.strip().lower() in {"true", "false"}
        ]
        # One True is emitted by import!, followed by twenty contract results.
        self.assertEqual(results, ["true"] * 21, completed.stdout)


class TestMettaEnrichedOptimalityRuntime(unittest.TestCase):
    """Execute all evidence-aware PeTTa optimality constraints."""

    @unittest.skipUnless(shutil.which("petta"), "PeTTa executable is not installed")
    def test_enriched_optimality_contracts(self):
        tests_dir = os.path.dirname(os.path.abspath(__file__))
        repo_root = os.path.dirname(os.path.dirname(tests_dir))
        fixture = os.path.join(
            tests_dir, "quantale-petta-enriched-optimality-smoke.metta"
        )

        completed = subprocess.run(
            ["petta", fixture],
            cwd=repo_root,
            capture_output=True,
            text=True,
            timeout=60,
        )

        self.assertEqual(
            completed.returncode,
            0,
            f"PeTTa enriched optimality contracts failed:\n"
            f"STDOUT:\n{completed.stdout}\nSTDERR:\n{completed.stderr}",
        )
        results = [
            line.strip().lower()
            for line in completed.stdout.splitlines()
            if line.strip().lower() in {"true", "false"}
        ]
        # One import result, followed by twenty-eight contract results.
        self.assertEqual(results, ["true"] * 29, completed.stdout)


class TestMettaOptimalityIntegrationRuntime(unittest.TestCase):
    """Exercise the staged structural/colimit/optimality data contract."""

    @unittest.skipUnless(shutil.which("petta"), "PeTTa executable is not installed")
    def test_optimality_integration_contracts(self):
        tests_dir = os.path.dirname(os.path.abspath(__file__))
        repo_root = os.path.dirname(os.path.dirname(tests_dir))
        fixture = os.path.join(
            tests_dir, "quantale-petta-optimality-integration-smoke.metta"
        )

        completed = subprocess.run(
            ["petta", fixture],
            cwd=repo_root,
            capture_output=True,
            text=True,
            timeout=60,
        )

        self.assertEqual(
            completed.returncode,
            0,
            f"PeTTa optimality integration contracts failed:\n"
            f"STDOUT:\n{completed.stdout}\nSTDERR:\n{completed.stderr}",
        )
        results = [
            line.strip().lower()
            for line in completed.stdout.splitlines()
            if line.strip().lower() in {"true", "false"}
        ]
        # One import result, followed by nine integration contract results.
        self.assertEqual(results, ["true"] * 10, completed.stdout)


class TestMettaCompleteBlendPipelineRuntime(unittest.TestCase):
    """Run structural generalization, quantale colimit, and optimality together."""

    @unittest.skipUnless(shutil.which("petta"), "PeTTa executable is not installed")
    def test_complete_blend_pipeline_contracts(self):
        tests_dir = os.path.dirname(os.path.abspath(__file__))
        repo_root = os.path.dirname(os.path.dirname(tests_dir))
        fixture = os.path.join(
            tests_dir, "quantale-petta-complete-pipeline-smoke.metta"
        )
        environment = os.environ.copy()
        environment.update(
            {
                "GENERALIZATION_LLM_MODE": "off",
                "GENERALIZATION_CACHE_MODE": "on",
            }
        )

        completed = subprocess.run(
            ["petta", fixture],
            cwd=repo_root,
            env=environment,
            capture_output=True,
            text=True,
            timeout=90,
        )

        self.assertEqual(
            completed.returncode,
            0,
            f"PeTTa complete pipeline failed:\n"
            f"STDOUT:\n{completed.stdout}\nSTDERR:\n{completed.stderr}",
        )
        results = [
            line.strip().lower()
            for line in completed.stdout.splitlines()
            if line.strip().lower() in {"true", "false"}
        ]
        # One import result, followed by pending/blocked/evaluated checks.
        self.assertEqual(results, ["true"] * 4, completed.stdout)


class TestMettaPerspectiveAwareVPredicateRuntime(unittest.TestCase):
    """Check that PeTTa V-predicate transformations preserve perspective."""

    @unittest.skipUnless(shutil.which("petta"), "PeTTa executable is not installed")
    def test_perspective_aware_vpredicate_contracts(self):
        tests_dir = os.path.dirname(os.path.abspath(__file__))
        repo_root = os.path.dirname(os.path.dirname(tests_dir))
        fixture = os.path.join(tests_dir, "quantale_petta_perspective_smoke.metta")

        completed = subprocess.run(
            ["petta", fixture],
            cwd=repo_root,
            capture_output=True,
            text=True,
            timeout=30,
        )

        self.assertEqual(
            completed.returncode,
            0,
            f"PeTTa perspective-aware V-predicate contracts failed:\n"
            f"STDOUT:\n{completed.stdout}\nSTDERR:\n{completed.stderr}",
        )
        results = [
            line.strip().lower()
            for line in completed.stdout.splitlines()
            if line.strip().lower() in {"true", "false"}
        ]
        self.assertEqual(results, ["true"] * 8, completed.stdout)

if __name__ == "__main__":
    unittest.main()
