"""Cartesian planning and reconstruction for PeTTa algebraic generalization."""
from __future__ import annotations

import os
import re
from typing import Any

import generalization_support as core

SECTIONS = ("sorts", "ops", "preds", "axioms")
LOGICAL_HEADS = {"=>", "and", "or", "not", "=", "defined", "true", "false"}
LCG_DEPTH_RE = re.compile(r"^LCG-D([0-9]+)-C1[0-9]+-C2[0-9]+$")


def _split(item: Any) -> tuple[Any, Any]:
    if not isinstance(item, list) or len(item) != 2:
        raise core.GeneralizationError(
            "every section entry must pair a declaration with an stv"
        )
    return item[0], item[1]


class CartesianPlanner:
    def __init__(self) -> None:
        self.requests: list[tuple[str, str, str]] = []
        self.request_ids: dict[tuple[str, str], str] = {}
        self.entries: dict[str, list[tuple[Any | None, Any, Any]]] = {
            section: [] for section in SECTIONS
        }
        self.pair_counts = {section: 0 for section in SECTIONS}

    def request(self, left: Any, right: Any) -> list[str]:
        left_name, right_name = str(left), str(right)
        if not core.SYMBOL_RE.fullmatch(left_name) or not core.SYMBOL_RE.fullmatch(
            right_name
        ):
            raise core.GeneralizationError(
                f"cannot generalize unsafe symbols {left_name!r} and {right_name!r}"
            )
        key = (left_name, right_name)
        request_id = self.request_ids.get(key)
        if request_id is None:
            request_id = f"pair_{len(self.requests)}"
            self.request_ids[key] = request_id
            self.requests.append((request_id, left_name, right_name))
        return ["PairRef", request_id]


def _operation_template(
    left: Any, right: Any, planner: CartesianPlanner
) -> Any | None:
    if not (
        isinstance(left, list)
        and isinstance(right, list)
        and len(left) == len(right) == 3
        and left[0] == right[0] == "operation"
        and isinstance(left[2], list)
        and isinstance(right[2], list)
        and len(left[2]) >= 2
        and len(right[2]) >= 2
    ):
        return None
    left_arrow, right_arrow = str(left[2][0]), str(right[2][0])
    if left_arrow not in {"arrow", "partial_arrow"} or right_arrow not in {
        "arrow",
        "partial_arrow",
    }:
        return None
    arrow = (
        "partial_arrow"
        if "partial_arrow" in {left_arrow, right_arrow}
        else "arrow"
    )
    left_inputs, left_output = left[2][1:-1], left[2][-1]
    right_inputs, right_output = right[2][1:-1], right[2][-1]
    signature = [
        *[planner.request(a, b) for a, b in zip(left_inputs, right_inputs)],
        planner.request(left_output, right_output),
    ]
    return ["operation", planner.request(left[1], right[1]), [arrow, *signature]]


def _predicate_template(
    left: Any, right: Any, planner: CartesianPlanner
) -> Any | None:
    if not (
        isinstance(left, list)
        and isinstance(right, list)
        and len(left) >= 1
        and len(right) >= 1
    ):
        return None
    return [
        planner.request(left[0], right[0]),
        *[planner.request(a, b) for a, b in zip(left[1:], right[1:])],
    ]


def _axiom_template(
    left: Any,
    right: Any,
    planner: CartesianPlanner,
    left_variables: dict[str, str] | None = None,
    right_variables: dict[str, str] | None = None,
) -> Any | None:
    left_variables = left_variables or {}
    right_variables = right_variables or {}
    if isinstance(left, list) != isinstance(right, list):
        return None
    if not isinstance(left, list):
        a, b = str(left), str(right)
        if a in left_variables and b in right_variables:
            return left_variables[a] if left_variables[a] == right_variables[b] else None
        if a == b and (a in LOGICAL_HEADS or a.replace(".", "", 1).isdigit()):
            return a
        return planner.request(a, b)
    if not left or not right:
        return None
    if left[0] == right[0] == "forall":
        return _forall_template(
            left, right, planner, left_variables, right_variables
        )
    head = (
        str(left[0])
        if left[0] == right[0] and str(left[0]) in LOGICAL_HEADS
        else planner.request(left[0], right[0])
    )
    children = [
        _axiom_template(a, b, planner, left_variables, right_variables)
        for a, b in zip(left[1:], right[1:])
    ]
    return None if any(child is None for child in children) else [head, *children]


def _forall_template(
    left: list[Any],
    right: list[Any],
    planner: CartesianPlanner,
    left_variables: dict[str, str],
    right_variables: dict[str, str],
) -> Any | None:
    if (
        len(left) != 3
        or len(right) != 3
        or not isinstance(left[1], list)
        or not isinstance(right[1], list)
    ):
        return None
    binders, lvars, rvars = [], dict(left_variables), dict(right_variables)
    for index, (lbind, rbind) in enumerate(zip(left[1], right[1])):
        if not (
            isinstance(lbind, list)
            and isinstance(rbind, list)
            and len(lbind) == len(rbind) == 2
        ):
            return None
        variable = (
            str(lbind[0])
            if core.SYMBOL_RE.fullmatch(str(lbind[0]))
            else f"v{index}"
        )
        lvars[str(lbind[0])] = variable
        rvars[str(rbind[0])] = variable
        binders.append([variable, planner.request(lbind[1], rbind[1])])
    body = _axiom_template(left[2], right[2], planner, lvars, rvars)
    return None if body is None else ["forall", binders, body]


def plan_cartesian(spec1: Any, spec2: Any, perspective: str) -> CartesianPlanner:
    _, p1, sections1 = core._spec(spec1)
    _, p2, sections2 = core._spec(spec2)
    if p1 != perspective or p2 != perspective:
        raise core.GeneralizationError("perspective mismatch")
    planner = CartesianPlanner()
    for section in SECTIONS:
        for left_item in sections1[section]:
            left, left_tv = _split(left_item)
            for right_item in sections2[section]:
                right, right_tv = _split(right_item)
                planner.pair_counts[section] += 1
                if section == "sorts":
                    template = planner.request(left, right)
                elif section == "ops":
                    template = _operation_template(left, right, planner)
                elif section == "preds":
                    template = _predicate_template(left, right, planner)
                else:
                    template = _axiom_template(left, right, planner)
                planner.entries[section].append((template, left_tv, right_tv))
    return planner


def build_cartesian_plan(perspective: Any, spec1: Any, spec2: Any) -> str:
    planner = plan_cartesian(spec1, spec2, str(perspective))
    requests = [
        ["PairRequest", request_id, left, right]
        for request_id, left, right in planner.requests
    ]
    counts = [[section, str(planner.pair_counts[section])] for section in SECTIONS]
    return core.render_metta(
        ["GeneralizationPlan", ["PairRequests", requests], ["PairCounts", counts]]
    )


def cartesian_pair_counts(
    perspective: Any, spec1: Any, spec2: Any
) -> dict[str, int]:
    return plan_cartesian(spec1, spec2, str(perspective)).pair_counts


def _stv(value: Any) -> tuple[float, float]:
    if isinstance(value, tuple) and len(value) == 2:
        strength, confidence = float(value[0]), float(value[1])
    elif isinstance(value, list) and len(value) == 3 and str(value[0]) == "stv":
        strength, confidence = float(value[1]), float(value[2])
    else:
        strength = confidence = float(value)
    if not (0.0 <= strength <= 1.0 and 0.0 <= confidence <= 1.0):
        raise core.GeneralizationError("truth values must be in [0, 1]")
    return strength, confidence


def _render_stv(value: tuple[float, float]) -> list[str]:
    return ["stv", f"{value[0]:g}", f"{value[1]:g}"]


def _tensor_stvs(*values: Any) -> tuple[float, float]:
    pairs = [_stv(value) for value in values]
    return min(value[0] for value in pairs), min(value[1] for value in pairs)


def _join_stvs(left: Any, right: Any) -> tuple[float, float]:
    """The configured lattice join for redundant generalized declarations."""
    a, b = _stv(left), _stv(right)
    return max(a[0], b[0]), max(a[1], b[1])


def _lcg_candidate(
    proof: Any, left: str, right: str
) -> tuple[int, str, tuple[float, float]] | None:
    """Extract derivation depth, LCG, and truth from a synthesized proof."""
    try:
        proof_head, entailment = proof[1], proof[2]
        relation, tv = entailment[1], entailment[2]
        if not (
            proof[0] == ":"
            and entailment[0] == "≞"
            and relation[0] == "→"
            and str(relation[1]) == left
            and str(relation[2]) == right
            and isinstance(relation[3], list)
            and len(relation[3]) == 1
        ):
            return None
        lcg = str(relation[3][0])
        if not core.SYMBOL_RE.fullmatch(lcg):
            return None
        if isinstance(proof_head, list) and proof_head:
            rule = str(proof_head[0])
            if rule == "LCG-DEPTH-0":
                depth = 0
            else:
                match = LCG_DEPTH_RE.fullmatch(rule)
                if match is None:
                    return None
                depth = int(match.group(1))
        elif core.SYMBOL_RE.fullmatch(str(proof_head)):
            # Directly asserted and normalized LCGs have no inference chain.
            depth = 0
        else:
            return None
        return depth, lcg, _stv(tv)
    except (IndexError, TypeError, ValueError):
        return None


def normalize_lcg_proofs(left: Any, right: Any, proofs: Any) -> str:
    """Keep every minimum-depth LCG and render a stable compact proof form."""
    c1, c2 = str(left), str(right)
    if not core.SYMBOL_RE.fullmatch(c1) or not core.SYMBOL_RE.fullmatch(c2):
        raise core.GeneralizationError("unsafe concept symbol")
    parsed = core.parse_metta(proofs)
    candidates = [
        candidate
        for proof in parsed if isinstance(parsed, list)
        if (candidate := _lcg_candidate(proof, c1, c2)) is not None
    ]
    if not candidates:
        return "()"
    minimum_depth = min(depth for depth, _, _ in candidates)
    selected: dict[str, tuple[float, float]] = {}
    for depth, lcg, tv in candidates:
        if depth == minimum_depth:
            selected[lcg] = tv if lcg not in selected else _join_stvs(selected[lcg], tv)
    proof_name = f"{c1}{c2}m"
    if not core.SYMBOL_RE.fullmatch(proof_name):
        raise core.GeneralizationError("unsafe normalized proof symbol")
    normalized = [
        [":", proof_name, ["≞", ["→", c1, c2, [lcg]], _render_stv(tv)]]
        for lcg, tv in selected.items()
    ]
    return core.render_metta(normalized)


def _weighted_paths(value: Any, concept: str) -> list[list[tuple[str, tuple[float, float]]]]:
    parsed = core.parse_metta(value)
    if not isinstance(parsed, list):
        raise core.GeneralizationError("weighted paths must be a list")
    paths: list[list[tuple[str, tuple[float, float]]]] = []
    for raw_path in parsed:
        if not isinstance(raw_path, list) or not raw_path:
            raise core.GeneralizationError("weighted paths cannot be empty")
        path: list[tuple[str, tuple[float, float]]] = []
        for raw_step in raw_path:
            if not (
                isinstance(raw_step, list)
                and len(raw_step) == 3
                and raw_step[0] == "GeneralizationStep"
            ):
                raise core.GeneralizationError("invalid weighted path step")
            node = str(raw_step[1])
            if not core.SYMBOL_RE.fullmatch(node):
                raise core.GeneralizationError("unsafe weighted path symbol")
            path.append((node, _stv(raw_step[2])))
        if path[0][0] != concept:
            raise core.GeneralizationError(f"every weighted path must start with {concept}")
        paths.append(path)
    return paths


def graph_lcg_proofs(
    left: Any, right: Any, raw_paths1: Any, raw_paths2: Any
) -> str:
    """Find minimum-depth common ancestors using only weighted graph paths."""
    c1, c2 = str(left), str(right)
    if not core.SYMBOL_RE.fullmatch(c1) or not core.SYMBOL_RE.fullmatch(c2):
        raise core.GeneralizationError("unsafe concept symbol")
    paths1 = _weighted_paths(raw_paths1, c1)
    paths2 = _weighted_paths(raw_paths2, c2)
    candidates: list[tuple[int, str, tuple[float, float]]] = []

    def prefixes(path: list[tuple[str, tuple[float, float]]]):
        evidence = (1.0, 1.0)
        result: dict[str, tuple[int, tuple[float, float]]] = {}
        for depth, (node, edge_tv) in enumerate(path):
            evidence = _tensor_stvs(evidence, edge_tv)
            result[node] = (depth, evidence)
        return result

    for path1 in paths1:
        ancestry1 = prefixes(path1)
        for path2 in paths2:
            ancestry2 = prefixes(path2)
            for lcg in ancestry1.keys() & ancestry2.keys():
                depth1, tv1 = ancestry1[lcg]
                depth2, tv2 = ancestry2[lcg]
                candidates.append((max(depth1, depth2), lcg, _tensor_stvs(tv1, tv2)))
    if not candidates:
        return "()"
    minimum_depth = min(depth for depth, _, _ in candidates)
    selected: dict[str, tuple[float, float]] = {}
    for depth, lcg, tv in candidates:
        if depth == minimum_depth:
            selected[lcg] = tv if lcg not in selected else _join_stvs(selected[lcg], tv)
    proof_name = f"{c1}{c2}m"
    if not core.SYMBOL_RE.fullmatch(proof_name):
        raise core.GeneralizationError("unsafe normalized proof symbol")
    return core.render_metta([
        [":", proof_name, ["≞", ["→", c1, c2, [lcg]], _render_stv(tv)]]
        for lcg, tv in selected.items()
    ])


def resolutions_from_proofs(
    request_id: Any, left: Any, right: Any, proofs: Any
) -> str:
    """Preserve every selected LCG as a resolution for Cartesian expansion."""
    request, c1, c2 = str(request_id), str(left), str(right)
    if c1 == c2:
        return f"((PairResolution {request} {c1} (stv 1 1)))"
    parsed = core.parse_metta(proofs)
    resolutions: dict[str, tuple[float, float]] = {}
    for proof in parsed if isinstance(parsed, list) else []:
        candidate = _lcg_candidate(proof, c1, c2)
        if candidate is None:
            continue
        _, lcg, tv = candidate
        resolutions[lcg] = tv if lcg not in resolutions else _join_stvs(resolutions[lcg], tv)
    rendered = [
        ["PairResolution", request, lcg, _render_stv(tv)]
        for lcg, tv in resolutions.items()
    ]
    return core.render_metta(rendered)


def resolution_from_proofs(
    request_id: Any, left: Any, right: Any, proofs: Any
) -> str:
    request, c1, c2 = str(request_id), str(left), str(right)
    if c1 == c2:
        return f"(PairResolution {request} {c1} (stv 1 1))"
    parsed = core.parse_metta(proofs)
    candidates: list[tuple[float, float, str]] = []
    for proof in parsed if isinstance(parsed, list) else []:
        try:
            entailment = proof[2]
            relation, tv = entailment[1], entailment[2]
            if (
                proof[0] == ":"
                and entailment[0] == "≞"
                and relation[0] == "→"
                and str(relation[1]) == c1
                and str(relation[2]) == c2
                and len(relation[3]) == 1
            ):
                strength, confidence = _stv(tv)
                lcg = str(relation[3][0])
                if core.SYMBOL_RE.fullmatch(lcg):
                    candidates.append((strength, confidence, lcg))
        except (IndexError, TypeError, ValueError):
            continue
    if not candidates:
        return f"(PairResolution {request} () ())"
    strength, confidence, lcg = max(candidates)
    return f"(PairResolution {request} {lcg} (stv {strength:g} {confidence:g}))"


def _resolution_map(value: Any) -> dict[str, list[tuple[str, Any]]]:
    parsed = core.parse_metta(value)
    if isinstance(parsed, list) and parsed and parsed[0] == "PairResolutions":
        parsed = (
            parsed[1]
            if len(parsed) == 2 and isinstance(parsed[1], list)
            else parsed[1:]
        )
    result: dict[str, list[tuple[str, Any]]] = {}
    for item in parsed if isinstance(parsed, list) else []:
        if not (
            isinstance(item, list)
            and len(item) == 4
            and item[0] == "PairResolution"
        ):
            continue
        if item[2] == [] or item[3] == []:
            continue
        result.setdefault(str(item[1]), []).append((str(item[2]), item[3]))
    return result


def _expand_template(
    template: Any, resolutions: dict[str, list[tuple[str, Any]]]
) -> list[tuple[Any, list[Any]]]:
    if isinstance(template, list) and len(template) == 2 and template[0] == "PairRef":
        return [(name, [tv]) for name, tv in resolutions.get(str(template[1]), [])]
    if not isinstance(template, list):
        return [(template, [])]
    partial: list[tuple[list[Any], list[Any]]] = [([], [])]
    for child in template:
        expanded = _expand_template(child, resolutions)
        partial = [
            ([*prefix, value], [*truths, *child_truths])
            for prefix, truths in partial
            for value, child_truths in expanded
        ]
        if not partial:
            break
    return partial


def _pair_refs(template: Any) -> set[str]:
    if isinstance(template, list) and len(template) == 2 and template[0] == "PairRef":
        return {str(template[1])}
    if not isinstance(template, list):
        return set()
    return set().union(*(_pair_refs(child) for child in template)) if template else set()


def _deduplicate(entries: list[list[Any]]) -> list[list[Any]]:
    order: list[str] = []
    merged: dict[str, list[Any]] = {}
    for declaration, tv in entries:
        key = core.render_metta(declaration)
        if key not in merged:
            order.append(key)
            merged[key] = [declaration, _render_stv(_stv(tv))]
        else:
            merged[key][1] = _render_stv(_join_stvs(merged[key][1], tv))
    return [merged[key] for key in order]


def _validate_result(
    result: str,
    concept: str,
    perspective: str,
    output: dict[str, list[Any]],
) -> None:
    parsed = core.parse_metta(result)
    expected = [
        "Concept",
        concept,
        perspective,
        ["spec", *[[section, output[section]] for section in SECTIONS]],
    ]
    if parsed != expected:
        raise core.GeneralizationError(
            "rendered algebraic specification failed round-trip validation"
        )

    def symbol(value: Any, role: str) -> str:
        name = str(value)
        if not core.SYMBOL_RE.fullmatch(name) or name[0].isupper():
            raise core.GeneralizationError(
                f"{role} must be a safe lowercase symbol: {name}"
            )
        return name

    def expression(value: Any, variables: set[str] | None = None) -> None:
        variables = variables or set()
        if not isinstance(value, list) or not value:
            raise core.GeneralizationError("invalid axiom expression")
        head = str(value[0])
        if head == "forall":
            if len(value) != 3 or not isinstance(value[1], list):
                raise core.GeneralizationError("invalid forall expression")
            scoped = set(variables)
            for binder in value[1]:
                if not isinstance(binder, list) or len(binder) != 2:
                    raise core.GeneralizationError("invalid forall binder")
                scoped.add(symbol(binder[0], "variable"))
                symbol(binder[1], "binder sort")
            expression(value[2], scoped)
            return
        if head in LOGICAL_HEADS:
            for child in value[1:]:
                if isinstance(child, list):
                    expression(child, variables)
                elif str(child) not in variables and str(child) not in LOGICAL_HEADS:
                    symbol(child, "axiom symbol")
            return
        symbol(head, "relation head")
        for argument in value[1:]:
            if isinstance(argument, list):
                expression(argument, variables)
            elif str(argument) not in variables:
                symbol(argument, "relation argument")

    for declaration, tv in output["sorts"]:
        symbol(declaration, "sort")
        _stv(tv)
    for declaration, tv in output["ops"]:
        if (
            not isinstance(declaration, list)
            or len(declaration) != 3
            or declaration[0] != "operation"
            or not isinstance(declaration[2], list)
            or len(declaration[2]) < 2
            or declaration[2][0] not in {"arrow", "partial_arrow"}
        ):
            raise core.GeneralizationError("invalid operation declaration")
        symbol(declaration[1], "operation")
        for sort_name in declaration[2][1:]:
            symbol(sort_name, "operation sort")
        _stv(tv)
    for declaration, tv in output["preds"]:
        if not isinstance(declaration, list) or not declaration:
            raise core.GeneralizationError("invalid predicate declaration")
        symbol(declaration[0], "relation head")
        for sort_name in declaration[1:]:
            symbol(sort_name, "predicate sort")
        _stv(tv)
    for declaration, tv in output["axioms"]:
        expression(declaration)
        _stv(tv)


def assemble_cartesian_spec(
    generic_name: Any,
    perspective: Any,
    spec1: Any,
    spec2: Any,
    raw_resolutions: Any,
) -> str:
    generic, requested = str(generic_name), str(perspective)
    if not core.SYMBOL_RE.fullmatch(generic) or not core.SYMBOL_RE.fullmatch(requested):
        raise core.GeneralizationError("unsafe output identity")
    if generic[0].isupper():
        raise core.GeneralizationError("generic concept names must start lowercase")
    planner = plan_cartesian(spec1, spec2, requested)
    resolutions = _resolution_map(raw_resolutions)
    used_requests = set().union(
        *(
            _pair_refs(template)
            for section in SECTIONS
            for template, _, _ in planner.entries[section]
            if template is not None
        )
    )
    unresolved = used_requests.difference(resolutions)
    if unresolved and os.getenv("GENERALIZATION_UNRESOLVED_POLICY", "error") != "omit":
        request_lookup = {
            request_id: (left, right)
            for request_id, left, right in planner.requests
        }
        pairs = ", ".join(
            f"{request_lookup[item][0]}×{request_lookup[item][1]}"
            for item in sorted(unresolved, key=lambda value: int(value.split("_")[-1]))
        )
        raise core.GeneralizationError(
            f"{len(unresolved)} Cartesian concept pairs have no LCG: {pairs}"
        )
    output: dict[str, list[list[Any]]] = {}
    for section in SECTIONS:
        generated: list[list[Any]] = []
        for template, left_tv, right_tv in planner.entries[section]:
            if template is None:
                continue
            for declaration, component_tvs in _expand_template(template, resolutions):
                combined = _tensor_stvs(left_tv, right_tv, *component_tvs)
                generated.append([declaration, _render_stv(combined)])
        output[section] = _deduplicate(generated)
    body = ["spec", *[[section, output[section]] for section in SECTIONS]]
    result = core.render_metta(["Concept", generic, requested, body])
    _validate_result(result, generic, requested, output)
    return result
