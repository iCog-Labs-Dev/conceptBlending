#!/usr/bin/env python3
"""Run the stratified semantic algebraic-specification quality benchmark."""

from __future__ import annotations

import argparse
import json
from dataclasses import asdict

from algebraic_spec_semantics import bundle_metrics, validate_bundles
from test_algebraic_spec_semantics import STRATIFIED_CASES, compile_case


QUALITY_THRESHOLDS = {
    "validation_issue_count": 0.0,
    "operation_predicate_overlap_count": 0.0,
    "undeclared_sort_count": 0.0,
    "dangling_axiom_count": 0.0,
}
MINIMUM_THRESHOLDS = {
    "operation_axiom_coverage": 0.75,
}


def evaluate():
    cases = {}
    all_bundles = []
    all_issues = []

    for (concept, perspective), relations in sorted(STRATIFIED_CASES.items()):
        bundles = compile_case(concept, perspective, relations)
        issues = validate_bundles(bundles)
        metrics = bundle_metrics(bundles)
        all_bundles.extend(bundles)
        all_issues.extend(issues)
        cases[f"{concept}:{perspective}"] = {
            "families": [bundle.family for bundle in bundles],
            "metrics": metrics,
            "issues": [asdict(issue) for issue in issues],
        }

    aggregate = bundle_metrics(all_bundles)
    failures = {
        metric: {"expected": expected, "actual": aggregate[metric]}
        for metric, expected in QUALITY_THRESHOLDS.items()
        if aggregate[metric] != expected
    }
    failures.update(
        {
            metric: {"minimum": minimum, "actual": aggregate[metric]}
            for metric, minimum in MINIMUM_THRESHOLDS.items()
            if aggregate[metric] < minimum
        }
    )
    return {
        "passed": not failures,
        "case_count": len(cases),
        "aggregate": aggregate,
        "threshold_failures": failures,
        "cases": cases,
    }


def print_text(report):
    status = "PASS" if report["passed"] else "FAIL"
    aggregate = report["aggregate"]
    print(f"{status}: {report['case_count']} stratified concept/perspective cases")
    print(
        "Aggregate: "
        f"{int(aggregate['sort_count'])} sorts, "
        f"{int(aggregate['operation_count'])} operations, "
        f"{int(aggregate['predicate_count'])} predicates, "
        f"{int(aggregate['axiom_count'])} axioms"
    )
    print(
        "Quality: "
        f"{int(aggregate['operation_predicate_overlap_count'])} operation/predicate overlaps, "
        f"{int(aggregate['undeclared_sort_count'])} undeclared sorts, "
        f"{int(aggregate['dangling_axiom_count'])} dangling axioms, "
        f"{aggregate['operation_axiom_coverage']:.1%} operation/axiom coverage"
    )
    for name, case in report["cases"].items():
        metrics = case["metrics"]
        print(
            f"  {name}: {', '.join(case['families'])}; "
            f"{int(metrics['operation_count'])} ops, "
            f"{int(metrics['predicate_count'])} preds, "
            f"{int(metrics['axiom_count'])} axioms"
        )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit the complete machine-readable evaluation report.",
    )
    args = parser.parse_args()
    report = evaluate()
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print_text(report)
    raise SystemExit(0 if report["passed"] else 1)


if __name__ == "__main__":
    main()
