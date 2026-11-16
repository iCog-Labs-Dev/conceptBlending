"""Correctness and performance gates for a compiled V-predicate PathMap index."""

from __future__ import annotations

import argparse
import json
import subprocess
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Sequence


class EvaluationError(RuntimeError):
    """Raised when an index fails a correctness or regression gate."""


@dataclass(frozen=True)
class QueryCase:
    source: str
    perspective: str
    concept: str
    command: str
    family: str | None = None
    property: str | None = None
    contains: str | None = None
    min_rows: int = 1


def read_build_stats(index_dir: str | Path) -> dict[str, float]:
    stats: dict[str, float] = {}
    path = Path(index_dir) / "build-stats.txt"
    for line in path.read_text(encoding="utf-8").splitlines():
        name, separator, value = line.partition("=")
        if not separator:
            raise EvaluationError(f"malformed build statistic: {line!r}")
        stats[name] = float(value)
    return stats


def validate_build_stats(stats: dict[str, float]) -> None:
    required = {
        "property_facts",
        "world_facts",
        "sorts",
        "operations",
        "predicates",
        "axioms",
        "skipped_worlds",
        "provenance_records",
        "build_elapsed_ms",
        "peak_rss_kib",
    }
    missing = sorted(required - stats.keys())
    if missing:
        raise EvaluationError(f"missing build statistics: {', '.join(missing)}")
    if stats["skipped_worlds"] != 0:
        raise EvaluationError(f"PathMap skipped {int(stats['skipped_worlds'])} world facts")
    indexed_facts = sum(
        stats[name]
        for name in (
            "property_facts",
            "world_facts",
            "sorts",
            "operations",
            "predicates",
            "axioms",
        )
    )
    if stats["provenance_records"] < indexed_facts:
        raise EvaluationError(
            "provenance coverage is incomplete: "
            f"{int(stats['provenance_records'])} records for {int(indexed_facts)} facts"
        )
    if stats["build_elapsed_ms"] <= 0 or stats["peak_rss_kib"] < 0:
        raise EvaluationError("build timing must be positive and peak RSS must be non-negative")


def parse_key_values(line: str) -> dict[str, float | str]:
    parsed: dict[str, float | str] = {}
    for field in line.split():
        name, separator, value = field.partition("=")
        if not separator:
            continue
        try:
            parsed[name] = float(value)
        except ValueError:
            parsed[name] = value
    return parsed


def _run(command: Sequence[str]) -> subprocess.CompletedProcess[str]:
    completed = subprocess.run(command, capture_output=True, text=True, check=False)
    if completed.returncode != 0:
        raise EvaluationError(
            f"command failed ({' '.join(command)}): "
            + (completed.stderr.strip() or completed.stdout.strip())
        )
    return completed


def evaluate_index(
    compiler: str | Path,
    index_dir: str | Path,
    cases: Sequence[QueryCase],
    *,
    iterations: int = 20,
) -> dict[str, Any]:
    if iterations < 1:
        raise EvaluationError("iterations must be positive")
    compiler = str(Path(compiler).resolve())
    index_dir = str(Path(index_dir).resolve())
    stats = read_build_stats(index_dir)
    validate_build_stats(stats)

    correctness: list[dict[str, Any]] = []
    performance: list[dict[str, Any]] = []
    for case in cases:
        query = [
            compiler,
            case.command,
            "--index",
            index_dir,
            "--perspective",
            case.perspective,
            "--concept",
            case.concept,
        ]
        if case.family:
            query.extend(("--family", case.family))
        if case.property:
            query.extend(("--property", case.property))
        output = _run(query).stdout
        rows = sum(line.startswith("concept=") for line in output.splitlines())
        if rows < case.min_rows:
            raise EvaluationError(
                f"{case.source} case returned {rows} rows; expected at least {case.min_rows}"
            )
        if case.contains and case.contains not in output:
            raise EvaluationError(
                f"{case.source} case did not contain expected text: {case.contains!r}"
            )
        correctness.append({**asdict(case), "rows": rows})

        benchmark = _run(
            [
                compiler,
                "benchmark",
                "--index",
                index_dir,
                "--perspective",
                case.perspective,
                "--concept",
                case.concept,
                "--iterations",
                str(iterations),
                "--extensions",
                "0",
            ]
        )
        metrics = parse_key_values(benchmark.stdout.strip())
        performance.append(
            {
                "source": case.source,
                "perspective": case.perspective,
                "concept": case.concept,
                **metrics,
            }
        )

    query_means = [float(item["query_mean_us"]) for item in performance]
    peak_values = [float(item["peak_rss_kib"]) for item in performance]
    aggregate = {
        "case_count": len(cases),
        "total_rows": sum(item["rows"] for item in correctness),
        "mean_query_us": sum(query_means) / len(query_means) if query_means else 0.0,
        "worst_query_us": max(query_means, default=0.0),
        "max_peak_rss_kib": max(peak_values, default=0.0),
        "build_elapsed_ms": stats["build_elapsed_ms"],
        "build_peak_rss_kib": stats["peak_rss_kib"],
    }
    return {
        "build_stats": stats,
        "correctness": correctness,
        "performance": performance,
        "aggregate": aggregate,
    }


def enforce_baseline(
    report: dict[str, Any],
    baseline: dict[str, Any],
    *,
    latency_factor: float,
    memory_factor: float,
) -> None:
    current = report["aggregate"]
    expected = baseline["aggregate"]
    limits = {
        "worst_query_us": latency_factor,
        "max_peak_rss_kib": memory_factor,
        "build_peak_rss_kib": memory_factor,
    }
    regressions = []
    for metric, factor in limits.items():
        if float(expected[metric]) <= 0 or float(current[metric]) <= 0:
            continue
        limit = float(expected[metric]) * factor
        if float(current[metric]) > limit:
            regressions.append(f"{metric}={current[metric]:.3f} exceeds {limit:.3f}")
    if regressions:
        raise EvaluationError("; ".join(regressions))


def load_cases(path: str | Path) -> list[QueryCase]:
    payload = json.loads(Path(path).read_text(encoding="utf-8"))
    return [QueryCase(**case) for case in payload["cases"]]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--compiler", required=True)
    parser.add_argument("--index", required=True)
    parser.add_argument("--cases", required=True)
    parser.add_argument("--iterations", type=int, default=20)
    parser.add_argument("--output")
    parser.add_argument("--baseline")
    parser.add_argument("--latency-factor", type=float, default=1.25)
    parser.add_argument("--memory-factor", type=float, default=1.15)
    arguments = parser.parse_args()

    report = evaluate_index(
        arguments.compiler,
        arguments.index,
        load_cases(arguments.cases),
        iterations=arguments.iterations,
    )
    if arguments.baseline:
        baseline = json.loads(Path(arguments.baseline).read_text(encoding="utf-8"))
        enforce_baseline(
            report,
            baseline,
            latency_factor=arguments.latency_factor,
            memory_factor=arguments.memory_factor,
        )
    rendered = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if arguments.output:
        Path(arguments.output).write_text(rendered, encoding="utf-8")
    else:
        print(rendered, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
