import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[1] / "python"))

import generalization_event_logger as logger


class GeneralizationEventLoggerTests(unittest.TestCase):
    def test_run_events_match_integrated_pipeline_schema(self):
        with tempfile.TemporaryDirectory() as root:
            path = Path(root) / "events.jsonl"
            environment = {
                "PIPELINE_LOG_PATH": str(path),
                "PIPELINE_LOG_STDERR": "0",
                "PIPELINE_LOG_VERBOSITY": "default",
            }
            with patch.dict(os.environ, environment, clear=False):
                run_id = logger.start_generalization(
                    "building", "functional_use"
                )
                logger.log_generalization_event(
                    "success",
                    "generic_space_cache_miss",
                    "building",
                    "functional_use",
                    {"cache_key": "abc"},
                )
                logger.finish_generalization(
                    "success",
                    "building",
                    "functional_use",
                    "generic space returned",
                )
            rows = [
                json.loads(line)
                for line in path.read_text(encoding="utf-8").splitlines()
            ]
            self.assertEqual(3, len(rows))
            self.assertEqual({run_id}, {row["run_id"] for row in rows})
            self.assertEqual(
                {
                    "timestamp",
                    "run_id",
                    "status",
                    "stage",
                    "subject",
                    "perspective",
                    "details",
                    "pid",
                },
                set(rows[0]),
            )
            self.assertEqual(
                [
                    "generalization_started",
                    "generic_space_cache_miss",
                    "generalization_completed",
                ],
                [row["stage"] for row in rows],
            )

    def test_error_detail_is_bounded(self):
        with tempfile.TemporaryDirectory() as root:
            path = Path(root) / "events.jsonl"
            with patch.dict(
                os.environ,
                {
                    "PIPELINE_LOG_PATH": str(path),
                    "PIPELINE_LOG_STDERR": "0",
                    "PIPELINE_LOG_MAX_DETAIL_CHARS": "12",
                },
                clear=False,
            ):
                logger.log_generalization_event(
                    "error",
                    "pair_lcg_llm_attempt",
                    "house×cabin",
                    "functional_use",
                    "x" * 30,
                )
            row = json.loads(path.read_text(encoding="utf-8"))
            self.assertIn("truncated", row["details"])

    def test_logging_can_be_disabled(self):
        with tempfile.TemporaryDirectory() as root:
            path = Path(root) / "events.jsonl"
            with patch.dict(
                os.environ,
                {
                    "PIPELINE_LOG_MODE": "off",
                    "PIPELINE_LOG_PATH": str(path),
                },
                clear=False,
            ):
                self.assertFalse(
                    logger.log_generalization_event(
                        "success",
                        "generalization_started",
                        "building",
                        "functional_use",
                        "",
                    )
                )
            self.assertFalse(path.exists())

    def test_default_suppresses_detail_but_verbose_keeps_it(self):
        with tempfile.TemporaryDirectory() as root:
            default_path = Path(root) / "default.jsonl"
            with patch.dict(
                os.environ,
                {
                    "PIPELINE_LOG_PATH": str(default_path),
                    "PIPELINE_LOG_STDERR": "0",
                    "PIPELINE_LOG_VERBOSITY": "default",
                },
                clear=False,
            ):
                self.assertFalse(
                    logger.log_generalization_event(
                        "success",
                        "pair_lcg_llm_skipped",
                        "house×cabin",
                        "functional_use",
                        "off",
                    )
                )
            self.assertFalse(default_path.exists())

            verbose_path = Path(root) / "verbose.jsonl"
            with patch.dict(
                os.environ,
                {
                    "PIPELINE_LOG_PATH": str(verbose_path),
                    "PIPELINE_LOG_STDERR": "0",
                    "PIPELINE_LOG_VERBOSITY": "verbose",
                },
                clear=False,
            ):
                self.assertTrue(
                    logger.log_generalization_event(
                        "success",
                        "pair_lcg_llm_skipped",
                        "house×cabin",
                        "functional_use",
                        "off",
                    )
                )
            row = json.loads(verbose_path.read_text(encoding="utf-8"))
            self.assertEqual("pair_lcg_llm_skipped", row["stage"])

    def test_fatal_error_closes_active_run(self):
        with tempfile.TemporaryDirectory() as root:
            path = Path(root) / "events.jsonl"
            with patch.dict(
                os.environ,
                {
                    "PIPELINE_LOG_PATH": str(path),
                    "PIPELINE_LOG_STDERR": "0",
                },
                clear=False,
            ):
                run_id = logger.start_generalization(
                    "building", "functional_use"
                )
                logger.fail_generalization(
                    "generic_space_assembly",
                    "building",
                    "functional_use",
                    "invalid specification",
                )
            rows = [
                json.loads(line)
                for line in path.read_text(encoding="utf-8").splitlines()
            ]
            self.assertEqual({run_id}, {row["run_id"] for row in rows})
            self.assertEqual("error", rows[-1]["status"])
            self.assertEqual("generalization_completed", rows[-1]["stage"])


if __name__ == "__main__":
    unittest.main()
