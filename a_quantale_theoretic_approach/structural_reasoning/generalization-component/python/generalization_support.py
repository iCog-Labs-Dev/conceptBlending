"""Validated LCG repair and Cartesian algebraic-spec orchestration."""
from __future__ import annotations
import json, os, re
from pathlib import Path
from typing import Any

import generalization_cache
from generalization_event_logger import (
    fail_generalization,
    log_generalization_event,
)

TOKEN_RE = re.compile(r'"(?:\\.|[^"\\])*"|\(|\)|[^\s()]+')
SYMBOL_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_\-]*$")
GENERALIZATION_ALGORITHM_VERSION = "cartesian-weighted-lcg-v1"
LCG_REPAIR_PROMPT_VERSION = "lcg-repair-v4"
RESERVED_LCG_SYMBOLS = {
    "safe_symbol", "descriptive_generic_concept", "unknown_lcg"
}

class GeneralizationError(ValueError): pass

def parse_metta(value: Any) -> Any:
    if isinstance(value, (list, tuple)):
        return [parse_metta(item) if isinstance(item, (list, tuple)) else item for item in value]
    tokens = TOKEN_RE.findall(str(value).strip())
    if not tokens: return []
    def at(i):
        if tokens[i] != "(":
            if tokens[i] == ")": raise GeneralizationError("unexpected closing parenthesis")
            return tokens[i], i + 1
        out, i = [], i + 1
        while i < len(tokens) and tokens[i] != ")":
            item, i = at(i); out.append(item)
        if i >= len(tokens): raise GeneralizationError("unclosed expression")
        return out, i + 1
    out, end = at(0)
    if end != len(tokens): raise GeneralizationError("trailing expressions")
    return out

def render_metta(value: Any) -> str:
    return "(" + " ".join(render_metta(x) for x in value) + ")" if isinstance(value, list) else str(value)

def canonical_metta(value: Any) -> str:
    return render_metta(parse_metta(value))

def _paths(value: Any, concept: str) -> list[list[str]]:
    parsed = parse_metta(value)
    if not isinstance(parsed, list): raise GeneralizationError("paths must be a list")
    paths = []
    for path in parsed:
        if not isinstance(path, list) or not path or str(path[0]) != concept:
            raise GeneralizationError(f"every path must start with {concept}")
        # PeTTa renders the accumulated path as `(a -> b -> c)`.  The arrows
        # are delimiters, not taxonomy nodes.
        clean = [str(x) for x in path if str(x) != "->"]
        unsafe = [x for x in clean if not SYMBOL_RE.fullmatch(x)]
        if unsafe:
            raise GeneralizationError(
                f"unsafe path symbol {unsafe[0]!r}; raw path={render_metta(path)}"
            )
        paths.append(clean)
    return paths or [[concept]]

def validate_lcg_repair(response, concept1, concept2, paths1, paths2):
    lcg = str(response.get("lcg", ""))
    if (
        not SYMBOL_RE.fullmatch(lcg)
        or lcg in {concept1, concept2}
        or lcg in RESERVED_LCG_SYMBOLS
    ):
        raise GeneralizationError("invalid LCG")
    on_path1 = any(lcg in path for path in paths1)
    on_path2 = any(lcg in path for path in paths2)
    if on_path1 and on_path2:
        raise GeneralizationError("LCG is already common to both path sets")
    def side(key, paths):
        raw = response.get(key)
        if not isinstance(raw, dict): raise GeneralizationError(f"missing {key}")
        left = str(raw.get("left", "")); rr = raw.get("right")
        right = None if rr in (None, "", "()") else str(rr)
        containing = [p for p in paths if left in p]
        if not containing: raise GeneralizationError(f"{key}.left is not on a path")
        if right is None:
            if not any(p[-1] == left for p in containing): raise GeneralizationError(f"{key} is not at a boundary")
        elif not any(p.index(left) + 1 < len(p) and p[p.index(left)+1] == right for p in containing):
            raise GeneralizationError(f"{key} is not an adjacent segment")
        def stv(field, required):
            value = raw.get(field)
            if value is None and not required: return None
            if not isinstance(value, list) or len(value) != 2: raise GeneralizationError(f"invalid {key}.{field}")
            pair = [float(value[0]), float(value[1])]
            if any(x < 0 or x > 1 for x in pair): raise GeneralizationError(f"out-of-range {key}.{field}")
            return pair
        return {"left": left, "right": right, "left_stv": stv("left_stv", True), "right_stv": stv("right_stv", right is not None)}
    return {"lcg": lcg, "path1": side("path1", paths1), "path2": side("path2", paths2)}

def _prompt(c1, c2, p1, p2):
    anchors1 = sorted({node for path in p1 for node in path})
    anchors2 = sorted({node for path in p2 for node in path})
    return f"""Find a missing least common generalization for {c1} and {c2}.
Authoritative taxonomy paths: {c1}: {json.dumps(p1)}; {c2}: {json.dumps(p2)}.
Allowed path1 anchor symbols: {json.dumps(anchors1)}.
Allowed path2 anchor symbols: {json.dumps(anchors2)}.
Return JSON only: {{"lcg":"<safe_lowercase_symbol>","path1":{{"left":"...","right":null,
"left_stv":[s,c],"right_stv":null}},"path2":{{...}}}}. left/right must be
an adjacent evidence-path segment; use null right only at a path end. The LCG
may reuse a node already present on exactly one side, but must not already occur
on both sides. Copy every left/right anchor exactly from its allowed list. Never
return schema placeholders such as safe_symbol or text inside angle brackets."""

def _retry_prompt(base_prompt, response, error, attempt):
    return f"""{base_prompt}

Your previous JSON proposal number {attempt} failed deterministic validation:
{type(error).__name__}: {error}
Previous proposal: {json.dumps(response, sort_keys=True, ensure_ascii=False)}
Return a corrected JSON object only. Do not explain the correction."""

def _llm_max_attempts():
    try:
        attempts = int(os.getenv("GENERALIZATION_LLM_MAX_ATTEMPTS", "3"))
    except ValueError as exc:
        raise GeneralizationError(
            "GENERALIZATION_LLM_MAX_ATTEMPTS must be an integer"
        ) from exc
    if not 1 <= attempts <= 10:
        raise GeneralizationError(
            "GENERALIZATION_LLM_MAX_ATTEMPTS must be between 1 and 10"
        )
    return attempts

def _call_openai(prompt):
    from openai import OpenAI
    response = OpenAI().responses.create(model=os.getenv("GENERALIZATION_LLM_MODEL", "gpt-5.4"), input=prompt,
        max_output_tokens=int(os.getenv("GENERALIZATION_LLM_MAX_TOKENS", "1200")))
    text = re.sub(r"^```(?:json)?\s*|\s*```$", "", response.output_text.strip())
    return json.loads(text)

def render_lcg_repair(repair):
    def path(side):
        right = side["right"] or "()"; a = side["left_stv"]; b = side["right_stv"]
        bt = "()" if b is None else f"(stv {b[0]:g} {b[1]:g})"
        return f"(Path {side['left']} {right} (stv {a[0]:g} {a[1]:g}) {bt})"
    return f"(LCGRepair {repair['lcg']} {path(repair['path1'])} {path(repair['path2'])})"

def _pair_cache_identity(concept1, concept2):
    c1, c2 = str(concept1), str(concept2)
    if not SYMBOL_RE.fullmatch(c1) or not SYMBOL_RE.fullmatch(c2):
        raise GeneralizationError("unsafe pair cache identity")
    payload = {
        "algorithm": GENERALIZATION_ALGORITHM_VERSION,
        "prompt": LCG_REPAIR_PROMPT_VERSION,
        "kb": generalization_cache.kb_fingerprint(),
        "left": c1,
        "right": c2,
    }
    return c1, c2, payload, generalization_cache.content_key(
        "pair_lcg_repair", payload
    )

def _cached_repair_shape(repair, concept1, concept2):
    if not isinstance(repair, dict):
        raise GeneralizationError("invalid cached LCG repair")
    lcg = str(repair.get("lcg", ""))
    if (
        not SYMBOL_RE.fullmatch(lcg)
        or lcg in {concept1, concept2}
        or lcg in RESERVED_LCG_SYMBOLS
    ):
        raise GeneralizationError("invalid cached LCG")
    for key in ("path1", "path2"):
        side = repair.get(key)
        if not isinstance(side, dict):
            raise GeneralizationError("invalid cached repair side")
        left, right = str(side.get("left", "")), side.get("right")
        if not SYMBOL_RE.fullmatch(left):
            raise GeneralizationError("invalid cached repair anchor")
        if right not in (None, "", "()") and not SYMBOL_RE.fullmatch(str(right)):
            raise GeneralizationError("invalid cached repair anchor")
        for field, required in (("left_stv", True), ("right_stv", right not in (None, "", "()"))):
            value = side.get(field)
            if value is None and not required:
                continue
            if not isinstance(value, list) or len(value) != 2:
                raise GeneralizationError("invalid cached repair truth value")
            pair = [float(value[0]), float(value[1])]
            if any(item < 0 or item > 1 for item in pair):
                raise GeneralizationError("invalid cached repair truth value")
    return repair

def lookup_cached_lcg_repair(concept1, concept2, cache_scope="kb"):
    # Mutable/custom Atomspaces cannot safely use a static-KB fingerprint.
    if str(cache_scope) != "kb":
        return "()"
    c1, c2, _, cache_key = _pair_cache_identity(concept1, concept2)
    cached = generalization_cache.lookup("pair_lcg_repair", cache_key)
    try:
        return render_lcg_repair(_cached_repair_shape(cached, c1, c2))
    except (GeneralizationError, KeyError, TypeError, ValueError):
        return "()"

def repair_lcg(
    concept1, concept2, raw_paths1, raw_paths2,
    cache_scope="kb", early_cache_checked=False,
):
    c1, c2 = str(concept1), str(concept2); p1, p2 = _paths(raw_paths1, c1), _paths(raw_paths2, c2)
    _, _, cache_payload, cache_key = _pair_cache_identity(c1, c2)
    already_checked = str(early_cache_checked).lower() in {
        "true", "1", "yes", "on"
    }
    cached = (
        generalization_cache.lookup("pair_lcg_repair", cache_key)
        if str(cache_scope) == "kb" and not already_checked
        else None
    )
    if cached is None and str(cache_scope) == "kb":
        # Version-1 records included full paths in their key. They cannot be
        # checked before traversal, but can be revalidated once and promoted
        # to the early, KB-fingerprinted key without another provider call.
        legacy_payloads = [
            {**cache_payload, "paths1": p1, "paths2": p2},
            {
                **cache_payload,
                "prompt": "lcg-repair-v3",
                "paths1": p1,
                "paths2": p2,
            },
            {
                **cache_payload,
                "prompt": "lcg-repair-v2",
                "paths1": p1,
                "paths2": p2,
            },
        ]
        for legacy_payload in legacy_payloads:
            legacy_key = generalization_cache.content_key(
                "pair_lcg_repair", legacy_payload
            )
            cached = generalization_cache.lookup(
                "pair_lcg_repair", legacy_key
            )
            if cached is not None:
                break
    if cached is not None:
        try:
            repair = validate_lcg_repair(
                _cached_repair_shape(cached, c1, c2), c1, c2, p1, p2
            )
            generalization_cache.persist(
                "pair_lcg_repair", cache_key, repair,
                {
                    "left": c1, "right": c2,
                    "algorithm": GENERALIZATION_ALGORITHM_VERSION,
                    "kb": cache_payload["kb"],
                    "key_version": 2,
                    "migrated": True,
                },
            )
            return render_lcg_repair(repair)
        except GeneralizationError:
            pass
    mode = os.getenv("GENERALIZATION_LLM_MODE", "verify").lower()
    # A missing API key is an intentional KB-only configuration, not an LLM
    # failure. At this point the MeTTa pipeline has already tried its caches,
    # synthesizer, and KB path search, so returning no repair preserves that
    # result without attempting a provider call.
    if mode == "off":
        log_generalization_event(
            "success",
            "pair_lcg_llm_skipped",
            f"{c1}×{c2}",
            details="GENERALIZATION_LLM_MODE=off",
        )
        return "()"
    if not os.getenv("OPENAI_API_KEY"):
        log_generalization_event(
            "success",
            "pair_lcg_llm_fallback_used",
            f"{c1}×{c2}",
            details="OPENAI_API_KEY is absent; retaining KB-only result",
        )
        return "()"
    prompt = _prompt(c1, c2, p1, p2)
    last_error = None
    for attempt in range(1, _llm_max_attempts() + 1):
        response = None
        try:
            response = _call_openai(prompt)
            repair = validate_lcg_repair(response, c1, c2, p1, p2)
            if str(cache_scope) == "kb":
                generalization_cache.persist(
                    "pair_lcg_repair", cache_key, repair,
                    {
                        "left": c1, "right": c2,
                        "algorithm": GENERALIZATION_ALGORITHM_VERSION,
                        "kb": cache_payload["kb"],
                        "key_version": 2,
                        "attempts": attempt,
                    },
                )
            log_generalization_event(
                "success",
                "pair_lcg_llm_verified",
                f"{c1}×{c2}",
                details={"lcg": repair["lcg"], "attempt": attempt},
            )
            return render_lcg_repair(repair)
        except Exception as exc:
            last_error = exc
            log_generalization_event(
                "error",
                "pair_lcg_llm_attempt",
                f"{c1}×{c2}",
                details={
                    "attempt": attempt,
                    "error": f"{type(exc).__name__}: {exc}",
                },
            )
            prompt = _retry_prompt(prompt, response, exc, attempt)
    if os.getenv("GENERALIZATION_LLM_FAILURE_POLICY", "error") == "error":
        error = GeneralizationError(
            f"LLM repair failed validation after {_llm_max_attempts()} attempts: "
            f"{last_error}"
        )
        fail_generalization(
            "pair_lcg_llm_repair",
            f"{c1}×{c2}",
            "",
            error,
        )
        raise error from last_error
    log_generalization_event(
        "success",
        "pair_lcg_llm_fallback_used",
        f"{c1}×{c2}",
        details=f"repair failed: {last_error}",
    )
    return "()"

def _spec(value):
    try:
        root = parse_metta(value)
    except GeneralizationError as exc:
        raise GeneralizationError(
            f"cannot parse PeTTa algebraic-spec atom: {value!r}; text={value!s}"
        ) from exc
    if not isinstance(root,list) or len(root)!=4 or root[0]!="Concept": raise GeneralizationError("expected perspective-aware Concept spec")
    body=root[3]
    if not isinstance(body,list) or not body or body[0]!="spec": raise GeneralizationError("missing spec")
    sections={str(x[0]):x[1] for x in body[1:] if isinstance(x,list) and len(x)==2}
    if set(sections)!={"sorts","ops","preds","axioms"}: raise GeneralizationError("spec must have four sections")
    return str(root[1]),str(root[2]),sections

def build_cartesian_plan(perspective, spec1, spec2):
    from cartesian_generalization import build_cartesian_plan as build
    result = build(perspective, spec1, spec2)
    log_generalization_event(
        "success",
        "cartesian_plan_built",
        perspective=perspective,
        details=cartesian_pair_counts(perspective, spec1, spec2),
    )
    return result

def cartesian_pair_counts(perspective, spec1, spec2):
    from cartesian_generalization import cartesian_pair_counts as counts
    return counts(perspective, spec1, spec2)

def resolution_from_proofs(request_id, left, right, proofs):
    from cartesian_generalization import resolution_from_proofs as resolve
    return resolve(request_id, left, right, proofs)

def normalize_lcg_proofs(left, right, proofs):
    from cartesian_generalization import normalize_lcg_proofs as normalize
    return normalize(left, right, proofs)

def graph_lcg_proofs(left, right, paths1, paths2):
    from cartesian_generalization import graph_lcg_proofs as find
    return find(left, right, paths1, paths2)

def resolutions_from_proofs(request_id, left, right, proofs):
    from cartesian_generalization import resolutions_from_proofs as resolve
    result = resolve(request_id, left, right, proofs)
    count = len(parse_metta(result))
    log_generalization_event(
        "success",
        "pair_lcg_resolved" if count else "pair_lcg_unresolved",
        f"{left}×{right}",
        details={"request_id": str(request_id), "resolution_count": count},
    )
    return result

def assemble_cartesian_spec(generic_name, perspective, spec1, spec2, resolutions):
    from cartesian_generalization import assemble_cartesian_spec as assemble
    try:
        result = assemble(
            generic_name, perspective, spec1, spec2, resolutions
        )
    except Exception as exc:
        fail_generalization(
            "generic_space_assembly",
            generic_name,
            perspective,
            f"{type(exc).__name__}: {exc}",
        )
        raise
    log_generalization_event(
        "success",
        "generic_space_assembled",
        generic_name,
        perspective,
        "algebraic specification assembled and validated",
    )
    return result

def _generic_cache_identity(generic_name, perspective, spec1, spec2, max_depth):
    generic, view = str(generic_name), str(perspective)
    if not SYMBOL_RE.fullmatch(generic) or not SYMBOL_RE.fullmatch(view):
        raise GeneralizationError("unsafe generic cache identity")
    left = canonical_metta(spec1)
    right = canonical_metta(spec2)
    _, left_view, _ = _spec(left)
    _, right_view, _ = _spec(right)
    if left_view != view or right_view != view:
        raise GeneralizationError("generic cache perspective mismatch")
    payload = {
        "algorithm": GENERALIZATION_ALGORITHM_VERSION,
        "kb": generalization_cache.kb_fingerprint(),
        "generic": generic,
        "perspective": view,
        "left_spec": left,
        "right_spec": right,
        "max_depth": int(str(max_depth)),
    }
    return generic, view, payload, generalization_cache.content_key(
        "generic_algebraic_spec", payload
    )

def lookup_generic_algebraic_spec(
    generic_name, perspective, spec1, spec2, max_depth
):
    generic, view, _, cache_key = _generic_cache_identity(
        generic_name, perspective, spec1, spec2, max_depth
    )
    cached = generalization_cache.lookup("generic_algebraic_spec", cache_key)
    if not isinstance(cached, str):
        return "()"
    try:
        cached_name, cached_view, _ = _spec(cached)
    except GeneralizationError:
        return "()"
    return cached if (cached_name, cached_view) == (generic, view) else "()"

def persist_generic_algebraic_spec(
    generic_name, perspective, spec1, spec2, max_depth, specification
):
    generic, view, payload, cache_key = _generic_cache_identity(
        generic_name, perspective, spec1, spec2, max_depth
    )
    rendered = canonical_metta(specification)
    result_name, result_view, _ = _spec(rendered)
    if (result_name, result_view) != (generic, view):
        raise GeneralizationError("generic cache result identity mismatch")
    # Diagnostic partial results must never become authoritative cache hits.
    if os.getenv("GENERALIZATION_UNRESOLVED_POLICY", "error") == "omit":
        return False
    return generalization_cache.persist(
        "generic_algebraic_spec", cache_key, rendered,
        {
            "generic": generic,
            "perspective": view,
            "algorithm": payload["algorithm"],
            "max_depth": payload["max_depth"],
        },
    )

def generalize_algebraic_specs(*_args):
    raise GeneralizationError(
        "the old intersection generalizer was removed; resolve the Cartesian "
        "plan through PeTTa pair-lcg before assembling the specification"
    )
