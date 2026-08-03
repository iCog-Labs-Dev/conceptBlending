import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import pipeline_event_logger as logger


class PipelineEventLoggerTests(unittest.TestCase):
    def test_run_events_are_correlated_and_persisted(self):
        with tempfile.TemporaryDirectory() as root:
            path = Path(root) / "events.jsonl"
            environment = {
                "PIPELINE_LOG_PATH": str(path),
                "PIPELINE_LOG_STDERR": "0",
                "PIPELINE_LOG_VERBOSITY": "default",
            }
            with patch.dict(os.environ, environment, clear=False):
                run_id = logger.start_pipeline("computer", "functional_use")
                logger.log_pipeline_event(
                    "success",
                    "properties_extracted",
                    "computer",
                    "functional_use",
                    [["process_information", "functional_use"]],
                )
                logger.finish_pipeline(
                    "success", "computer", "functional_use", "result returned"
                )

            rows = [
                json.loads(line)
                for line in path.read_text(encoding="utf-8").splitlines()
            ]
            self.assertEqual(3, len(rows))
            self.assertEqual({run_id}, {row["run_id"] for row in rows})
            self.assertEqual(
                ["pipeline_started", "properties_extracted", "pipeline_completed"],
                [row["stage"] for row in rows],
            )

    def test_error_event_and_detail_truncation(self):
        with tempfile.TemporaryDirectory() as root:
            path = Path(root) / "events.jsonl"
            environment = {
                "PIPELINE_LOG_PATH": str(path),
                "PIPELINE_LOG_STDERR": "0",
                "PIPELINE_LOG_MAX_DETAIL_CHARS": "12",
                "PIPELINE_LOG_VERBOSITY": "default",
            }
            with patch.dict(os.environ, environment, clear=False):
                logger.log_pipeline_event(
                    "error", "world_verification", "property", "functional_use", "x" * 30
                )
            row = json.loads(path.read_text(encoding="utf-8"))
            self.assertEqual("error", row["status"])
            self.assertIn("truncated", row["details"])

    def test_logging_can_be_disabled(self):
        with tempfile.TemporaryDirectory() as root:
            path = Path(root) / "events.jsonl"
            with patch.dict(
                os.environ,
                {"PIPELINE_LOG_MODE": "off", "PIPELINE_LOG_PATH": str(path)},
                clear=False,
            ):
                self.assertFalse(
                    logger.log_pipeline_event(
                        "success", "stage", "subject", "perspective", ""
                    )
                )
            self.assertFalse(path.exists())

    def test_fatal_error_closes_active_run(self):
        with tempfile.TemporaryDirectory() as root:
            path = Path(root) / "events.jsonl"
            environment = {
                "PIPELINE_LOG_PATH": str(path),
                "PIPELINE_LOG_STDERR": "0",
                "PIPELINE_LOG_VERBOSITY": "default",
            }
            with patch.dict(os.environ, environment, clear=False):
                run_id = logger.start_pipeline("computer", "functional_use")
                logger.fail_pipeline(
                    "property_worlds_verification",
                    "process_information",
                    "functional_use",
                    "provider failed",
                )
            rows = [
                json.loads(line)
                for line in path.read_text(encoding="utf-8").splitlines()
            ]
            self.assertEqual({run_id}, {row["run_id"] for row in rows})
            self.assertEqual("error", rows[-1]["status"])
            self.assertEqual("pipeline_completed", rows[-1]["stage"])

    def test_default_mode_suppresses_detailed_success_event(self):
        with tempfile.TemporaryDirectory() as root:
            path = Path(root) / "events.jsonl"
            environment = {
                "PIPELINE_LOG_PATH": str(path),
                "PIPELINE_LOG_STDERR": "0",
                "PIPELINE_LOG_VERBOSITY": "default",
            }
            with patch.dict(os.environ, environment, clear=False):
                logged = logger.log_pipeline_event(
                    "success",
                    "property_worlds_verification_started",
                    "process_information",
                    "functional_use",
                    "detail",
                )
            self.assertFalse(logged)
            self.assertFalse(path.exists())

    def test_verbose_mode_keeps_detailed_success_event(self):
        with tempfile.TemporaryDirectory() as root:
            path = Path(root) / "events.jsonl"
            environment = {
                "PIPELINE_LOG_PATH": str(path),
                "PIPELINE_LOG_STDERR": "0",
                "PIPELINE_LOG_VERBOSITY": "verbose",
            }
            with patch.dict(os.environ, environment, clear=False):
                logged = logger.log_pipeline_event(
                    "success",
                    "property_worlds_verification_started",
                    "process_information",
                    "functional_use",
                    "detail",
                )
            self.assertTrue(logged)
            row = json.loads(path.read_text(encoding="utf-8"))
            self.assertEqual(
                "property_worlds_verification_started", row["stage"]
            )


if __name__ == "__main__":
    unittest.main()
