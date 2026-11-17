from pathlib import Path
import sys
import unittest


PIPELINE_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(PIPELINE_ROOT / "python"))

from pathmap_kb_evaluation import (  # noqa: E402
    EvaluationError,
    enforce_baseline,
    parse_key_values,
    validate_build_stats,
)


class PathMapEvaluationTests(unittest.TestCase):
    def valid_stats(self) -> dict[str, float]:
        return {
            "property_facts": 2,
            "world_facts": 3,
            "sorts": 4,
            "operations": 1,
            "predicates": 2,
            "axioms": 1,
            "skipped_worlds": 0,
            "provenance_records": 15,
            "build_elapsed_ms": 12.5,
            "peak_rss_kib": 4096,
        }

    def test_build_stats_require_complete_provenance_and_no_skips(self) -> None:
        validate_build_stats(self.valid_stats())
        unavailable_memory = self.valid_stats()
        unavailable_memory["peak_rss_kib"] = 0
        validate_build_stats(unavailable_memory)
        skipped = self.valid_stats()
        skipped["skipped_worlds"] = 1
        with self.assertRaisesRegex(EvaluationError, "skipped 1"):
            validate_build_stats(skipped)
        incomplete = self.valid_stats()
        incomplete["provenance_records"] = 1
        with self.assertRaisesRegex(EvaluationError, "provenance coverage"):
            validate_build_stats(incomplete)

    def test_benchmark_output_is_parsed(self) -> None:
        parsed = parse_key_values(
            "backend=pathmap rows=4 query_mean_us=8.250 peak_rss_kib=2048"
        )
        self.assertEqual(parsed["backend"], "pathmap")
        self.assertEqual(parsed["rows"], 4.0)
        self.assertEqual(parsed["query_mean_us"], 8.25)

    def test_baseline_gate_reports_latency_and_memory_regressions(self) -> None:
        baseline = {
            "aggregate": {
                "worst_query_us": 10.0,
                "max_peak_rss_kib": 1000.0,
                "build_peak_rss_kib": 2000.0,
            }
        }
        report = {
            "aggregate": {
                "worst_query_us": 14.0,
                "max_peak_rss_kib": 1000.0,
                "build_peak_rss_kib": 2000.0,
            }
        }
        with self.assertRaisesRegex(EvaluationError, "worst_query_us"):
            enforce_baseline(report, baseline, latency_factor=1.25, memory_factor=1.15)


if __name__ == "__main__":
    unittest.main()
