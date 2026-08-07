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

        colimit_import = (
            "!(import! &self "
            "a_quantale_theoretic_approach/structural_reasoning/"
            "quantale_colimit_engine)"
        )
        self.assertIn(colimit_import, content)

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
        repo_root = os.path.dirname(os.path.dirname(tests_dir))
        fixture = os.path.join(tests_dir, "mcbride_runner_runtime_test.metta")

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
            f"PeTTa runner failed:\nSTDOUT:\n{completed.stdout}\n"
            f"STDERR:\n{completed.stderr}",
        )

        output = completed.stdout
        self.assertIn(
            "(Refined (BlendName Boat)",
            output,
            "mcbride-refine did not return the expected refined result",
        )
        self.assertIn(
            "(Eta 0.05) (Steps 20)",
            output,
            "mcbride-refine did not forward its default eta and step count",
        )
        self.assertIn(
            "(Eta 0.1) (Steps 3)",
            output,
            "mcbride-refine-with did not forward explicit parameters",
        )
        self.assertIn(
            "(EmergenceScore Boat Boat Car 0.625)",
            output,
            "mcbride-emergence did not return the expected score",
        )
        self.assertIn(
            "(Refined (BlendName TestBlend)",
            output,
            "quantale-blend-and-refine did not refine the generated colimit",
        )
        self.assertIn(
            "(providesTransport (WorldSpecSet (W_FERRY W_COMMUTE)) 0.85)",
            output,
            "the combined operation did not return the expected joined property",
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
        # One True is emitted by import!, followed by thirteen contract results.
        self.assertEqual(results, ["true"] * 14, completed.stdout)


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
