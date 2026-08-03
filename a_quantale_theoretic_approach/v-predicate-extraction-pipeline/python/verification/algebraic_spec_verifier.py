#!/usr/bin/env python3
"""LLM verification and persistence for built algebraic specifications."""

from __future__ import annotations

import ast
import hashlib
import json
import os
import re
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Protocol

from pipeline_event_logger import fail_pipeline, log_pipeline_event


PROMPT_VERSION = "algebraic-spec-final-verifier-v4"
DEFAULT_MODEL = os.environ.get(
    "ALGEBRAIC_SPEC_VERIFIER_MODEL",
    os.environ.get("OPENAI_MODEL", "gpt-5.4"),
)
SCRIPT_DIR = Path(__file__).resolve().parent
PIPELINE_ROOT = SCRIPT_DIR.parents[1]
REFERENCE_EXAMPLE_PATH = (
    PIPELINE_ROOT / "fixtures" / "human_cognitive_agency_reference.metta"
)
DEFAULT_AUDIT_PATH = (
    PIPELINE_ROOT / "kb" / "runtime" / "verified"
    / "AlgebraicSpecificationVerified.jsonl"
)
DEFAULT_METTA_STORE_PATH = (
    PIPELINE_ROOT / "kb" / "runtime" / "verified"
    / "AlgebraicSpecificationVerifiedKB.metta"
)

PERSPECTIVE_CONTEXTS = {
    "descriptive_property": (
        "Models observable, measurable, dispositional, or attributed qualities "
        "of the concept. Prefer domain-specific property/value sorts, observers "
        "or measurements, property relations, and laws connecting observation "
        "to those properties; generic related_entity scaffolding is weak evidence."
    ),
    "physical_attribute": (
        "Models physical qualities such as form, material, dimensions, condition, "
        "and measurable state, together with observations and measurement laws."
    ),
    "functional_use": (
        "Models what the concept can be used to accomplish: goals, inputs, outputs, "
        "use contexts, transformations, affordances, and laws governing successful use."
    ),
    "behavioral_process": (
        "Models actions, responses, state transitions, process stages, and observable "
        "outcomes characteristic of the concept as an acting or changing entity."
    ),
    "causal_prerequisite": (
        "Models causes, enabling conditions, prerequisites, effects, dependencies, "
        "and transition laws that connect conditions to outcomes."
    ),
    "spatial_context": (
        "Models location, containment, adjacency, movement, source/destination, spatial "
        "configuration, and invariants governing those spatial relations."
    ),
    "temporal_context": (
        "Models ordering, duration, recurrence, temporal state, lifecycle position, "
        "and laws governing change over time."
    ),
    "quantitative_comparative": (
        "Models quantities, scales, measurements, comparisons, bounds, aggregation, "
        "and algebraic laws for the relevant measures."
    ),
    "social_normative": (
        "Models social roles, permissions, obligations, conventions, evaluations, "
        "interactions, and rules constraining socially meaningful behavior."
    ),
    "economic_ownership": (
        "Models ownership, transfer, value, cost, exchange, resources, agents, and "
        "laws governing economic or possession changes."
    ),
    "information_computational": (
        "Models information, inputs, programs or procedures, state, transformations, "
        "outputs, observation, composition, and computation laws."
    ),
    "safety_risk": (
        "Models hazards, exposure, vulnerability, protection, failure states, "
        "mitigations, outcomes, and laws relating actions or conditions to risk."
    ),
    "state_lifecycle": (
        "Models states, creation, activation, transitions, persistence, termination, "
        "and lifecycle invariants."
    ),
    "structural_composition": (
        "Models parts, wholes, materials, interfaces, assembly/disassembly, structural "
        "relations, and composition or integrity laws."
    ),
    "taxonomic_kind": (
        "Models the concept as a kind: supertypes, subtypes, distinguishing features, "
        "classification operations, membership predicates, and classification laws."
    ),
    "taxonomic_classification": (
        "Models classification evidence, categories, subtype structure, membership, "
        "and rules for assigning or refining a category."
    ),
    "artifact_kind": (
        "Models the concept as a designed artifact, emphasizing artifact classes, "
        "design roles, intended structure, identifying features, and classification laws."
    ),
    "role_kind": (
        "Models the concept as a role borne in a context, including bearers, contexts, "
        "eligibility, assignment, discharge, and role constraints."
    ),
    "prerequisite_action": (
        "Models actions and the conditions required before they can occur, including "
        "enablement, ordering, and precondition-preservation laws."
    ),
    "event_composition": (
        "Models events, subevents, sequencing, composition, participants, outcomes, "
        "and laws connecting composite events to their parts."
    ),
    "cognitive_agency": (
        "Models an agent's embodied perception, experience, interpretation, memory, "
        "reasoning, goals, decisions, communication, and action, with laws connecting "
        "those capabilities rather than merely listing human properties."
    ),
}


class VerificationError(RuntimeError):
    pass


class VerificationProvider(Protocol):
    @property
    def model_id(self) -> str: ...

    def verify(self, instructions: str, candidate: str) -> dict[str, Any]: ...


@dataclass(frozen=True)
class VerificationConfig:
    mode: str = "auto"
    model: str = DEFAULT_MODEL
    api_key_env: str = "OPENAI_API_KEY"
    base_url: str | None = None
    timeout: float = 90.0
    max_output_tokens: int = 10000
    max_attempts: int = 2
    failure_policy: str = "fallback"
    failure_cache_seconds: int = 3600
    audit_path: Path = DEFAULT_AUDIT_PATH
    metta_store_path: Path = DEFAULT_METTA_STORE_PATH

    def __post_init__(self) -> None:
        if self.mode not in {"off", "auto", "verify"}:
            raise ValueError("verification mode must be off, auto, or verify")
        if self.max_attempts < 1:
            raise ValueError("verification max_attempts must be at least one")
        if self.failure_policy not in {"fallback", "error"}:
            raise ValueError("verification failure_policy must be fallback or error")
        if self.failure_cache_seconds < 0:
            raise ValueError("verification failure_cache_seconds must be nonnegative")


@dataclass(frozen=True)
class VerificationResult:
    verdict: str
    confidence: float
    summary: str
    issues: tuple[dict[str, str], ...]
    section_assessments: dict[str, dict[str, str]]
    specification: dict[str, Any]


class OpenAIVerificationProvider:
    def __init__(
        self,
        api_key: str,
        model: str = DEFAULT_MODEL,
        base_url: str | None = None,
        timeout: float = 90.0,
        max_output_tokens: int = 10000,
    ) -> None:
        if not api_key:
            raise VerificationError("OPENAI_API_KEY is required for LLM verification")
        try:
            from openai import OpenAI
        except ImportError as exc:
            raise VerificationError("The openai package is required for LLM verification") from exc
        kwargs: dict[str, Any] = {"api_key": api_key, "timeout": timeout}
        if base_url:
            kwargs["base_url"] = base_url
        self._client = OpenAI(**kwargs)
        self._model = model
        self._max_output_tokens = max_output_tokens

    @property
    def model_id(self) -> str:
        return self._model

    def verify(self, instructions: str, candidate: str) -> dict[str, Any]:
        response = self._client.responses.create(
            model=self._model,
            instructions=instructions,
            input=candidate,
            max_output_tokens=self._max_output_tokens,
            text={
                "format": {
                    "type": "json_schema",
                    "name": "algebraic_spec_verification",
                    "strict": True,
                    "schema": verification_response_schema(),
                }
            },
        )
        try:
            value = json.loads(response.output_text)
        except (TypeError, json.JSONDecodeError) as exc:
            raise VerificationError("LLM verification returned invalid JSON") from exc
        if not isinstance(value, dict):
            raise VerificationError("LLM verification response must be a JSON object")
        usage = getattr(response, "usage", None)
        if hasattr(usage, "model_dump"):
            usage = usage.model_dump()
        value["_response_metadata"] = {
            "response_id": str(getattr(response, "id", "")),
            "status": str(getattr(response, "status", "")),
            "usage": usage if isinstance(usage, dict) else {},
        }
        return value


def verification_response_schema() -> dict[str, Any]:
    stv = {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "strength": {"type": "number", "minimum": 0.0, "maximum": 1.0},
            "confidence": {"type": "number", "minimum": 0.0, "maximum": 1.0},
        },
        "required": ["strength", "confidence"],
    }
    term = {"$ref": "#/$defs/term"}
    atom = {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "predicate": {"type": "string"},
            "arguments": {"type": "array", "items": term},
        },
        "required": ["predicate", "arguments"],
    }
    assessment = {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "status": {"type": "string", "enum": ["correct", "corrected", "incorrect"]},
            "rationale": {"type": "string"},
        },
        "required": ["status", "rationale"],
    }
    response = {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "verdict": {"type": "string", "enum": ["correct", "corrected", "rejected"]},
            "confidence": {"type": "number", "minimum": 0.0, "maximum": 1.0},
            "summary": {"type": "string"},
            "issues": {
                "type": "array",
                "items": {
                    "type": "object",
                    "additionalProperties": False,
                    "properties": {
                        "severity": {"type": "string", "enum": ["info", "warning", "error"]},
                        "section": {
                            "type": "string",
                            "enum": ["perspective", "sorts", "operations", "predicates", "axioms", "cross_section"],
                        },
                        "code": {"type": "string"},
                        "explanation": {"type": "string"},
                    },
                    "required": ["severity", "section", "code", "explanation"],
                },
            },
            "section_assessments": {
                "type": "object",
                "additionalProperties": False,
                "properties": {
                    "perspective": assessment,
                    "sorts": assessment,
                    "operations": assessment,
                    "predicates": assessment,
                    "axioms": assessment,
                    "cross_section": assessment,
                },
                "required": ["perspective", "sorts", "operations", "predicates", "axioms", "cross_section"],
            },
            "specification": {
                "type": "object",
                "additionalProperties": False,
                "properties": {
                    "concept": {"type": "string"},
                    "perspective": {"type": "string"},
                    "sorts": {
                        "type": "array", "maxItems": 15,
                        "items": {
                            "type": "object", "additionalProperties": False,
                            "properties": {"name": {"type": "string"}, "stv": stv},
                            "required": ["name", "stv"],
                        },
                    },
                    "operations": {
                        "type": "array", "maxItems": 15,
                        "items": {
                            "type": "object", "additionalProperties": False,
                            "properties": {
                                "name": {"type": "string"},
                                "inputs": {"type": "array", "items": {"type": "string"}},
                                "output": {"type": "string"},
                                "partial": {"type": "boolean"},
                                "role": {"type": "string", "enum": ["constructor", "transformation", "observer", "selector", "constant", "combinator"]},
                                "stv": stv,
                            },
                            "required": ["name", "inputs", "output", "partial", "role", "stv"],
                        },
                    },
                    "predicates": {
                        "type": "array", "maxItems": 15,
                        "items": {
                            "type": "object", "additionalProperties": False,
                            "properties": {
                                "name": {"type": "string"},
                                "argument_sorts": {"type": "array", "items": {"type": "string"}},
                                "stv": stv,
                            },
                            "required": ["name", "argument_sorts", "stv"],
                        },
                    },
                    "axioms": {
                        "type": "array", "maxItems": 15,
                        "items": {
                            "type": "object", "additionalProperties": False,
                            "properties": {
                                "name": {"type": "string"},
                                "variables": {
                                    "type": "array",
                                    "items": {
                                        "type": "object", "additionalProperties": False,
                                        "properties": {"name": {"type": "string"}, "sort": {"type": "string"}},
                                        "required": ["name", "sort"],
                                    },
                                },
                                "law_kind": {
                                    "type": "string",
                                    "enum": [
                                        "equational_law",
                                        "conditional_equation",
                                        "predicate_implication",
                                        "closure_law",
                                        "definedness_law",
                                    ],
                                },
                                "antecedent": {
                                    "type": "array",
                                    "maxItems": 3,
                                    "items": atom,
                                },
                                "consequent": {
                                    "type": "object", "additionalProperties": False,
                                    "properties": {
                                        "kind": {"type": "string", "enum": ["atom", "equality"]},
                                        "predicate": {"type": "string"},
                                        "arguments": {"type": "array", "items": term},
                                        "left": term,
                                        "right": term,
                                    },
                                    "required": ["kind", "predicate", "arguments", "left", "right"],
                                },
                                "stv": stv,
                            },
                            "required": ["name", "variables", "law_kind", "antecedent", "consequent", "stv"],
                        },
                    },
                },
                "required": ["concept", "perspective", "sorts", "operations", "predicates", "axioms"],
            },
        },
        "required": ["verdict", "confidence", "summary", "issues", "section_assessments", "specification"],
    }
    response["$defs"] = {
        "term": {
            "type": "object",
            "additionalProperties": False,
            "properties": {
                "kind": {"type": "string", "enum": ["variable", "constant", "application"]},
                "symbol": {"type": "string"},
                "arguments": {"type": "array", "items": {"$ref": "#/$defs/term"}},
            },
            "required": ["kind", "symbol", "arguments"],
        }
    }
    return response


def system_prompt(reference_example: str | None = None) -> str:
    example = reference_example or """(Concept human cognitive_agency
  (spec
    (sorts ((human (stv 0.95 0.9)) (meaning (stv 0.9 0.85))))
    (ops (((operation reason (arrow human meaning meaning)) (stv 0.9 0.85))))
    (preds (((understands human meaning) (stv 0.9 0.85))))
    (axioms (((forall ((h human) (m meaning))
      (=> (understands h m) (= (reason h (reason h m)) (reason h m))))
      (stv 0.88 0.82))))))"""
    return f"""You verify and correct one perspective-aware algebraic specification.

The draft is NOT authoritative: it comes from an incomplete, noisy KB. Correct,
replace, add, or remove content as needed, while preserving the requested concept,
perspective, four sections, typed signatures, STVs, and structured response schema.
The perspective is semantically binding: retain only information relevant under that
viewpoint, even when other facts about the concept are generally true.

Section rules:
- sorts: domain-relevant carrier types used by signatures and laws. No capabilities,
  individual facts, duplicate types, or generic filler.
- operations: typed capabilities, transformations, observers, constructors, useful
  constants, or combinators. They are functions, not truth-valued relations.
- predicates: typed relations, properties, roles, and states. They are not capabilities
  or paraphrases of operations. Predicate names must start lowercase.
- axioms: nontrivial, type-correct first-order Horn laws. Quantification covers the
  entire implication: forall variables, antecedent implies consequent. Antecedents
  contain at most three meaningful DOMAIN predicates. Do not emit inPerspective,
  declaredOperation, or other verifier metadata. Do not emit x=x, repeat a premise as
  its conclusion, invent generic laws to increase coverage, or use a partial operation
  without a matching defined(...) premise. Use law_kind consistently: equational_law
  for unconditional equality, conditional_equation for conditional equality,
  predicate_implication for relational rules, closure_law for closedUnder conclusions,
  and definedness_law for defined conclusions.

The outer Concept already supplies perspective. Never create perspective-plumbing
operations named exactly like the perspective or named view_as_*, base_*, or
perspective_of_*. Prefer direct domain signatures such as birth_time: human ->
time_point. Include only meaningful items; there is no minimum section size and each
section may contain at most 15 items. Major transformations and combinators should be
constrained where a defensible law exists, but never fabricate a law merely to cover an
operation.

All referenced sorts, operations, predicates, and variables must resolve locally and be
type-correct. For variable/constant terms use arguments=[]. For application terms use
the operation name and recursive arguments. For atom consequents fill the schema's
unused left/right fields with harmless constants; for equality use meaningful left and
right and empty predicate/arguments. Return structured JSON only.

Compact quality example (illustrative, not a vocabulary template):
{example.strip()}
"""


def candidate_prompt(concept: str, perspective: str, spec_text: str) -> str:
    context = PERSPECTIVE_CONTEXTS.get(
        perspective,
        (
            "Interpret this perspective literally as the semantic viewpoint that "
            "selects which aspects of the concept belong in the specification. "
            "Exclude true but perspective-irrelevant content."
        ),
    )
    return (
        f"Verify and correct this generated algebraic specification.\n"
        f"Expected concept: {concept}\n"
        f"Expected perspective: {perspective}\n"
        f"Perspective context: {context}\n"
        "The draft is incomplete and non-authoritative. Keep only meaningful, "
        "perspective-relevant content; quality matters more than item count.\n"
        "Return only the structured response required by the response schema.\n\n"
        f"{spec_text.strip()}"
    )


def repair_prompt(
    concept: str,
    perspective: str,
    spec_text: str,
    previous_response: dict[str, Any],
    validation_errors: list[str],
) -> str:
    return (
        candidate_prompt(concept, perspective, spec_text)
        + "\n\nThe previous structured response failed deterministic validation. "
        "Return a complete replacement response, correcting every listed error.\n"
        + "Validation errors:\n- "
        + "\n- ".join(validation_errors)
        + "\nRegenerate a corrected response from the original draft. Do not repeat "
        "the invalid response."
    )


TOKEN_RE = re.compile(r'"(?:\\.|[^"\\])*"|\(|\)|[^\s()]+')


def metta_text(value: Any) -> str:
    """Render the nested Python value supplied by PeTTa as MeTTa text."""

    if isinstance(value, (list, tuple)):
        return f"({' '.join(metta_text(item) for item in value)})"
    if isinstance(value, str):
        return value
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value)


def coerce_spec_text(value: Any) -> str:
    if not isinstance(value, str):
        return metta_text(value).strip()
    candidate = value.strip()
    if candidate.startswith("["):
        try:
            return metta_text(ast.literal_eval(candidate)).strip()
        except (SyntaxError, ValueError):
            pass
    return candidate


SYMBOL_RE = re.compile(r"^[a-z_][A-Za-z0-9_]*$")
BUILTIN_PREDICATES = {"closedUnder", "defined"}
METADATA_OPERATION_PREFIXES = ("view_as_", "base_", "perspective_of_")
LAW_KINDS = {
    "equational_law",
    "conditional_equation",
    "predicate_implication",
    "closure_law",
    "definedness_law",
}


def _valid_stv(value: Any, path: str, errors: list[str]) -> None:
    if not isinstance(value, dict):
        errors.append(f"{path}: stv must be an object")
        return
    for field in ("strength", "confidence"):
        number = value.get(field)
        if not isinstance(number, (int, float)) or isinstance(number, bool) or not 0.0 <= float(number) <= 1.0:
            errors.append(f"{path}: stv {field} must be numeric and in [0,1]")


def _valid_symbol(value: Any, path: str, errors: list[str]) -> bool:
    if not isinstance(value, str) or not SYMBOL_RE.fullmatch(value):
        errors.append(f"{path}: symbol must start lowercase and contain only letters, digits, or underscores")
        return False
    return True


def structured_spec_errors(specification: Any, concept: str, perspective: str) -> list[str]:
    errors: list[str] = []
    if not isinstance(specification, dict):
        return ["specification must be an object"]
    if specification.get("concept") != concept:
        errors.append("specification changed the requested concept")
    if specification.get("perspective") != perspective:
        errors.append("specification changed the requested perspective")

    sections: dict[str, list[Any]] = {}
    for section in ("sorts", "operations", "predicates", "axioms"):
        items = specification.get(section)
        if not isinstance(items, list):
            errors.append(f"{section}: must be an array")
            items = []
        elif len(items) > 15:
            errors.append(f"{section}: exceeds the 15-item limit")
        sections[section] = items

    sort_names: set[str] = set()
    for index, item in enumerate(sections["sorts"]):
        path = f"sorts[{index}]"
        if not isinstance(item, dict):
            errors.append(f"{path}: must be an object")
            continue
        name = item.get("name")
        if _valid_symbol(name, f"{path}.name", errors):
            if name in sort_names:
                errors.append(f"{path}: duplicate sort {name}")
            sort_names.add(name)
        _valid_stv(item.get("stv"), path, errors)

    operation_names: set[str] = set()
    operation_inputs: dict[str, list[str]] = {}
    operation_outputs: dict[str, str] = {}
    partial_operations: set[str] = set()
    for index, item in enumerate(sections["operations"]):
        path = f"operations[{index}]"
        if not isinstance(item, dict):
            errors.append(f"{path}: must be an object")
            continue
        name = item.get("name")
        if _valid_symbol(name, f"{path}.name", errors):
            if name in operation_names:
                errors.append(f"{path}: duplicate operation {name}")
            operation_names.add(name)
            if name == perspective or name.startswith(METADATA_OPERATION_PREFIXES):
                errors.append(
                    f"{path}: perspective-plumbing operation {name} is not domain content"
                )
        inputs = item.get("inputs")
        if not isinstance(inputs, list) or not all(isinstance(value, str) for value in inputs):
            errors.append(f"{path}.inputs: must be an array of sort names")
            inputs = []
        operation_inputs[str(name)] = list(inputs)
        operation_outputs[str(name)] = str(item.get("output"))
        for sort in [*inputs, item.get("output")]:
            if sort not in sort_names:
                errors.append(f"{path}: undeclared signature sort {sort}")
        if not isinstance(item.get("partial"), bool):
            errors.append(f"{path}.partial: must be boolean")
        elif item.get("partial"):
            partial_operations.add(str(name))
        _valid_stv(item.get("stv"), path, errors)

    predicate_names: set[str] = set()
    predicate_arguments: dict[str, list[str]] = {}
    for index, item in enumerate(sections["predicates"]):
        path = f"predicates[{index}]"
        if not isinstance(item, dict):
            errors.append(f"{path}: must be an object")
            continue
        name = item.get("name")
        if _valid_symbol(name, f"{path}.name", errors):
            if name in predicate_names:
                errors.append(f"{path}: duplicate predicate {name}")
            predicate_names.add(name)
        arguments = item.get("argument_sorts")
        if not isinstance(arguments, list) or not all(isinstance(value, str) for value in arguments):
            errors.append(f"{path}.argument_sorts: must be an array of sort names")
            arguments = []
        predicate_arguments[str(name)] = list(arguments)
        for sort in arguments:
            if sort not in sort_names:
                errors.append(f"{path}: undeclared predicate sort {sort}")
        _valid_stv(item.get("stv"), path, errors)

    overlap = operation_names.intersection(predicate_names)
    if overlap:
        errors.append(f"operations/predicates overlap: {', '.join(sorted(overlap))}")

    axiom_names: set[str] = set()
    for index, item in enumerate(sections["axioms"]):
        path = f"axioms[{index}]"
        if not isinstance(item, dict):
            errors.append(f"{path}: must be an object")
            continue
        axiom_name = item.get("name")
        if _valid_symbol(axiom_name, f"{path}.name", errors):
            if axiom_name in axiom_names:
                errors.append(f"{path}: duplicate axiom {axiom_name}")
            axiom_names.add(str(axiom_name))
        law_kind = item.get("law_kind")
        if law_kind not in LAW_KINDS:
            errors.append(f"{path}.law_kind: unsupported law kind {law_kind}")
        variables = item.get("variables")
        variable_names: set[str] = set()
        variable_sorts: dict[str, str] = {}
        if not isinstance(variables, list):
            errors.append(f"{path}.variables: must be an array")
            variables = []
        for variable_index, variable in enumerate(variables):
            variable_path = f"{path}.variables[{variable_index}]"
            if not isinstance(variable, dict):
                errors.append(f"{variable_path}: must be an object")
                continue
            name = variable.get("name")
            if _valid_symbol(name, f"{variable_path}.name", errors):
                if name in variable_names:
                    errors.append(f"{variable_path}: duplicate variable {name}")
                variable_names.add(name)
            if variable.get("sort") not in sort_names:
                errors.append(f"{variable_path}: undeclared variable sort {variable.get('sort')}")
            else:
                variable_sorts[str(name)] = str(variable.get("sort"))

        used_operations: set[str] = set()
        used_variables: set[str] = set()
        guarded_partial_terms: set[str] = set()
        unguarded_partial_terms: dict[str, str] = {}

        def check_term(
            term: Any, term_path: str, *, defined_guard: bool = False
        ) -> str | None:
            if not isinstance(term, dict):
                errors.append(f"{term_path}: term must be an object")
                return None
            kind = term.get("kind")
            symbol = term.get("symbol")
            arguments = term.get("arguments")
            if kind not in {"variable", "constant", "application"}:
                errors.append(f"{term_path}: invalid term kind {kind}")
                return None
            _valid_symbol(symbol, f"{term_path}.symbol", errors)
            if not isinstance(arguments, list):
                errors.append(f"{term_path}.arguments: must be an array")
                arguments = []
            if kind == "variable" and symbol not in variable_names:
                errors.append(f"{term_path}: undeclared variable {symbol}")
                result_sort = None
            elif kind == "variable":
                result_sort = variable_sorts.get(str(symbol))
                used_variables.add(str(symbol))
            if (
                kind == "constant"
                and symbol not in operation_names
                and symbol not in sort_names
            ):
                errors.append(f"{term_path}: undeclared constant {symbol}")
                result_sort = None
            elif kind == "constant" and symbol in operation_names:
                if operation_inputs.get(str(symbol)):
                    errors.append(f"{term_path}: operation {symbol} is not a zero-argument constant")
                    result_sort = None
                else:
                    used_operations.add(str(symbol))
                    result_sort = operation_outputs.get(str(symbol))
                    identity = json.dumps(term, sort_keys=True)
                    if symbol in partial_operations:
                        if defined_guard:
                            guarded_partial_terms.add(identity)
                        else:
                            unguarded_partial_terms[identity] = term_path
            elif kind == "constant":
                result_sort = str(symbol) if symbol in sort_names else None
            if kind == "application":
                if symbol not in operation_names:
                    errors.append(f"{term_path}: undeclared operation {symbol}")
                    result_sort = None
                else:
                    used_operations.add(str(symbol))
                    result_sort = operation_outputs.get(str(symbol))
                    identity = json.dumps(term, sort_keys=True)
                    if symbol in partial_operations:
                        if defined_guard:
                            guarded_partial_terms.add(identity)
                        else:
                            unguarded_partial_terms[identity] = term_path
                expected_arity = len(operation_inputs.get(str(symbol), []))
                if len(arguments) != expected_arity:
                    errors.append(f"{term_path}: operation {symbol} expects {expected_arity} arguments")
            elif arguments:
                errors.append(f"{term_path}: {kind} term arguments must be empty")
            argument_sorts = []
            for argument_index, argument in enumerate(arguments):
                argument_sorts.append(
                    check_term(
                        argument,
                        f"{term_path}.arguments[{argument_index}]",
                        defined_guard=defined_guard,
                    )
                )
            if kind == "application" and symbol in operation_names:
                expected_sorts = operation_inputs.get(str(symbol), [])
                for argument_index, (actual, expected) in enumerate(
                    zip(argument_sorts, expected_sorts)
                ):
                    if actual is not None and actual != expected:
                        errors.append(
                            f"{term_path}.arguments[{argument_index}]: "
                            f"expected sort {expected}, got {actual}"
                        )
            return result_sort

        def check_atom(atom: Any, atom_path: str) -> None:
            if not isinstance(atom, dict):
                errors.append(f"{atom_path}: atom must be an object")
                return
            predicate = atom.get("predicate")
            arguments = atom.get("arguments")
            if not isinstance(arguments, list):
                errors.append(f"{atom_path}.arguments: must be an array")
                arguments = []
            if predicate not in predicate_names and predicate not in BUILTIN_PREDICATES:
                errors.append(f"{atom_path}: undeclared predicate {predicate}")
            actual_sorts = [
                check_term(
                    argument,
                    f"{atom_path}.arguments[{argument_index}]",
                    defined_guard=predicate == "defined",
                )
                for argument_index, argument in enumerate(arguments)
            ]
            if predicate in predicate_names:
                expected_sorts = predicate_arguments.get(str(predicate), [])
                if len(arguments) != len(expected_sorts):
                    errors.append(
                        f"{atom_path}: predicate {predicate} expects "
                        f"{len(expected_sorts)} arguments"
                    )
                for argument_index, (actual, expected) in enumerate(
                    zip(actual_sorts, expected_sorts)
                ):
                    if actual is not None and actual != expected:
                        errors.append(
                            f"{atom_path}.arguments[{argument_index}]: "
                            f"expected sort {expected}, got {actual}"
                        )
            elif predicate == "closedUnder":
                if len(arguments) != 2:
                    errors.append(f"{atom_path}: closedUnder expects 2 arguments")
                elif (
                    isinstance(arguments[1], dict)
                    and arguments[1].get("kind") == "constant"
                    and arguments[1].get("symbol") in sort_names
                    and actual_sorts[0] is not None
                    and actual_sorts[0] != arguments[1].get("symbol")
                ):
                    errors.append(
                        f"{atom_path}: closedUnder result sort {actual_sorts[0]} "
                        f"does not match {arguments[1].get('symbol')}"
                    )

        antecedent = item.get("antecedent")
        if not isinstance(antecedent, list):
            errors.append(f"{path}.antecedent: must be an array")
            antecedent = []
        elif len(antecedent) > 3:
            errors.append(f"{path}.antecedent: exceeds the 3-premise limit")
        for atom_index, atom in enumerate(antecedent):
            atom_path = f"{path}.antecedent[{atom_index}]"
            check_atom(atom, atom_path)

        consequent = item.get("consequent")
        if not isinstance(consequent, dict):
            errors.append(f"{path}.consequent: must be an object")
        elif consequent.get("kind") == "atom":
            check_atom(consequent, f"{path}.consequent")
            if any(
                consequent.get("predicate") == atom.get("predicate")
                and consequent.get("arguments") == atom.get("arguments")
                for atom in antecedent
                if isinstance(atom, dict)
            ):
                errors.append(f"{path}: consequent merely repeats an antecedent")
        elif consequent.get("kind") == "equality":
            left_sort = check_term(consequent.get("left"), f"{path}.consequent.left")
            right_sort = check_term(consequent.get("right"), f"{path}.consequent.right")
            if left_sort is not None and right_sort is not None and left_sort != right_sort:
                errors.append(
                    f"{path}.consequent: equality compares {left_sort} with {right_sort}"
                )
            if consequent.get("left") == consequent.get("right"):
                errors.append(f"{path}: tautological self-equality is not a constraint")
        else:
            errors.append(f"{path}.consequent: kind must be atom or equality")

        consequent_kind = consequent.get("kind") if isinstance(consequent, dict) else None
        consequent_predicate = (
            consequent.get("predicate") if consequent_kind == "atom" else None
        )
        expected_law_kind = (
            "equational_law"
            if consequent_kind == "equality" and not antecedent
            else "conditional_equation"
            if consequent_kind == "equality"
            else "closure_law"
            if consequent_predicate == "closedUnder"
            else "definedness_law"
            if consequent_predicate == "defined"
            else "predicate_implication"
        )
        if law_kind in LAW_KINDS and law_kind != expected_law_kind:
            errors.append(
                f"{path}.law_kind: expected {expected_law_kind} for this formula"
            )
        for identity, term_path in unguarded_partial_terms.items():
            if identity not in guarded_partial_terms:
                errors.append(
                    f"{term_path}: partial operation requires a matching defined premise"
                )
        unused_variables = variable_names.difference(used_variables)
        if unused_variables:
            errors.append(
                f"{path}: quantified variables are unused: "
                f"{', '.join(sorted(unused_variables))}"
            )
        if not used_operations and consequent_kind == "equality":
            errors.append(f"{path}: equational law does not constrain an operation")
        _valid_stv(item.get("stv"), path, errors)
    return errors


def validate_structured_specification(specification: Any, concept: str, perspective: str) -> None:
    errors = structured_spec_errors(specification, concept, perspective)
    if errors:
        raise VerificationError("; ".join(errors))


def _number(value: Any) -> str:
    return f"{float(value):.12g}"


def _render_stv(value: dict[str, Any]) -> str:
    return f"(stv {_number(value['strength'])} {_number(value['confidence'])})"


def _render_term(term: dict[str, Any]) -> str:
    if term["kind"] != "application":
        return term["symbol"]
    arguments = " ".join(_render_term(argument) for argument in term["arguments"])
    return f"({term['symbol']}{(' ' + arguments) if arguments else ''})"


def _render_atom(atom: dict[str, Any]) -> str:
    arguments = " ".join(_render_term(argument) for argument in atom["arguments"])
    return f"({atom['predicate']}{(' ' + arguments) if arguments else ''})"


def axiom_operation_dependencies(specification: dict[str, Any]) -> dict[str, list[str]]:
    declared = {
        str(operation.get("name")) for operation in specification.get("operations", [])
        if isinstance(operation, dict)
    }

    def term_operations(term: Any) -> set[str]:
        if not isinstance(term, dict):
            return set()
        found = {
            str(term.get("symbol"))
        } if term.get("kind") in {"application", "constant"} and term.get("symbol") in declared else set()
        for argument in term.get("arguments", []):
            found.update(term_operations(argument))
        return found

    dependencies: dict[str, list[str]] = {}
    for axiom in specification.get("axioms", []):
        if not isinstance(axiom, dict):
            continue
        found: set[str] = set()
        for atom in axiom.get("antecedent", []):
            if isinstance(atom, dict):
                for argument in atom.get("arguments", []):
                    found.update(term_operations(argument))
        consequent = axiom.get("consequent", {})
        if isinstance(consequent, dict):
            for argument in consequent.get("arguments", []):
                found.update(term_operations(argument))
            found.update(term_operations(consequent.get("left")))
            found.update(term_operations(consequent.get("right")))
        dependencies[str(axiom.get("name", ""))] = sorted(found)
    return dependencies


def render_structured_specification(specification: dict[str, Any]) -> str:
    concept = specification["concept"]
    perspective = specification["perspective"]
    sorts = " ".join(
        f"({item['name']} {_render_stv(item['stv'])})" for item in specification["sorts"]
    )
    operations = []
    for item in specification["operations"]:
        arrow = "partial_arrow" if item["partial"] else "arrow"
        signature = " ".join([*item["inputs"], item["output"]])
        operations.append(
            f"((operation {item['name']} ({arrow} {signature})) {_render_stv(item['stv'])})"
        )
    predicates = " ".join(
        f"(({item['name']}{(' ' + ' '.join(item['argument_sorts'])) if item['argument_sorts'] else ''}) {_render_stv(item['stv'])})"
        for item in specification["predicates"]
    )
    axioms = []
    for item in specification["axioms"]:
        antecedents = [_render_atom(atom) for atom in item["antecedent"]]
        antecedent = (
            "true"
            if not antecedents
            else antecedents[0]
            if len(antecedents) == 1
            else f"(and {' '.join(antecedents)})"
        )
        consequent_ir = item["consequent"]
        if consequent_ir["kind"] == "atom":
            consequent = _render_atom(consequent_ir)
        else:
            consequent = f"(= {_render_term(consequent_ir['left'])} {_render_term(consequent_ir['right'])})"
        implication = f"(=> {antecedent} {consequent})"
        if item["variables"]:
            variables = " ".join(f"({variable['name']} {variable['sort']})" for variable in item["variables"])
            implication = f"(forall ({variables}) {implication})"
        axioms.append(f"({implication} {_render_stv(item['stv'])})")
    return (
        f"(Concept {concept} {perspective} (spec "
        f"(sorts ({sorts})) "
        f"(ops ({' '.join(operations)})) "
        f"(preds ({predicates})) "
        f"(axioms ({' '.join(axioms)}))))"
    )


def parse_metta(text: str) -> Any:
    tokens = TOKEN_RE.findall(text)
    if not tokens:
        raise VerificationError("verified specification is empty")

    def parse_at(index: int) -> tuple[Any, int]:
        if index >= len(tokens):
            raise VerificationError("unexpected end of MeTTa expression")
        token = tokens[index]
        if token != "(":
            if token == ")":
                raise VerificationError("unexpected closing parenthesis")
            return token, index + 1
        result: list[Any] = []
        index += 1
        while index < len(tokens) and tokens[index] != ")":
            value, index = parse_at(index)
            result.append(value)
        if index >= len(tokens):
            raise VerificationError("unclosed MeTTa expression")
        return result, index + 1

    parsed, end = parse_at(0)
    if end != len(tokens):
        raise VerificationError("verified specification contains trailing expressions")
    return parsed


def _section_map(root: list[Any]) -> dict[str, Any]:
    if len(root) != 4 or root[0] != "Concept" or not isinstance(root[3], list):
        raise VerificationError("specification must use the Concept/concept/perspective/spec container")
    spec = root[3]
    if not spec or spec[0] != "spec":
        raise VerificationError("specification is missing the spec container")
    sections: dict[str, Any] = {}
    for section in spec[1:]:
        if isinstance(section, list) and len(section) == 2 and isinstance(section[0], str):
            sections[section[0]] = section[1]
    if set(sections) != {"sorts", "ops", "preds", "axioms"}:
        raise VerificationError("specification must contain exactly sorts, ops, preds, and axioms")
    return sections


def validate_spec_text(
    spec_text: str,
    concept: str,
    perspective: str,
    *,
    normalized_axioms: bool = False,
) -> None:
    parsed = parse_metta(spec_text)
    if not isinstance(parsed, list):
        raise VerificationError("specification root must be a MeTTa expression")
    sections = _section_map(parsed)
    if str(parsed[1]) != concept or str(parsed[2]) != perspective:
        raise VerificationError("verified specification changed the requested concept or perspective")
    for section_name, items in sections.items():
        if not isinstance(items, list):
            raise VerificationError(f"{section_name} section must contain a list")
        if len(items) > 15:
            raise VerificationError(f"{section_name} section exceeds the 15-item limit")
    for match in re.finditer(r"\(\s*([A-Z][A-Za-z0-9_]*)", spec_text):
        if match.group(1) != "Concept":
            raise VerificationError(f"relation head must start lowercase: {match.group(1)}")
    axioms = sections["axioms"]
    if not isinstance(axioms, list):
        raise VerificationError("axioms section must contain a list")
    for item in axioms:
        if not isinstance(item, list) or not item or not isinstance(item[0], list):
            raise VerificationError("each axiom must pair an expression with an stv")
        expression = item[0]
        if not expression:
            raise VerificationError("axiom expression must not be empty")
        if expression[0] == "forall":
            if (
                len(expression) != 3
                or not isinstance(expression[1], list)
                or not isinstance(expression[2], list)
                or not expression[2]
                or expression[2][0] != "=>"
            ):
                raise VerificationError(
                    "quantified axiom must wrap one Horn implication"
                )
            implication = expression[2]
        elif expression[0] == "=>":
            implication = expression
            if normalized_axioms and any(
                isinstance(node, list) and node and node[0] == "forall"
                for node in implication[1:]
            ):
                raise VerificationError(
                    "forall must scope over the complete Horn implication"
                )
        else:
            raise VerificationError(
                "each axiom must be a Horn implication, optionally wrapped by forall"
            )
        if len(implication) != 3:
            raise VerificationError("Horn implication must have one antecedent and consequent")
        if normalized_axioms:
            serialized = metta_text(expression)
            if "inPerspective" in serialized or "declaredOperation" in serialized:
                raise VerificationError(
                    "verified axioms must not contain verifier metadata guards"
                )


def normalize_result(value: dict[str, Any]) -> VerificationResult:
    verdict = str(value.get("verdict", "rejected"))
    if verdict not in {"correct", "corrected", "rejected"}:
        raise VerificationError(f"unsupported verification verdict: {verdict}")
    issues = value.get("issues", [])
    assessments = value.get("section_assessments", {})
    if not isinstance(issues, list) or not isinstance(assessments, dict):
        raise VerificationError("invalid issue or section assessment payload")
    specification = value.get("specification")
    if not isinstance(specification, dict):
        raise VerificationError("verification response is missing structured specification")
    return VerificationResult(
        verdict=verdict,
        confidence=max(0.0, min(1.0, float(value.get("confidence", 0.0)))),
        summary=str(value.get("summary", "")),
        issues=tuple(dict(item) for item in issues if isinstance(item, dict)),
        section_assessments={str(key): dict(item) for key, item in assessments.items() if isinstance(item, dict)},
        specification=dict(specification),
    )


def verification_key(concept: str, perspective: str, spec_text: str, model_id: str) -> str:
    try:
        normalized_spec = metta_text(parse_metta(spec_text))
    except VerificationError:
        normalized_spec = spec_text.strip()
    payload = json.dumps(
        {
            "prompt_version": PROMPT_VERSION,
            "model": model_id,
            "concept": concept,
            "perspective": perspective,
            "spec": normalized_spec,
        },
        sort_keys=True,
        separators=(",", ":"),
    ).encode()
    return hashlib.sha256(payload).hexdigest()


def _cached_record(path: Path, key: str) -> dict[str, Any] | None:
    if not path.exists():
        return None
    with path.open(encoding="utf-8", errors="replace") as handle:
        for line in handle:
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            if (
                row.get("key") == key
                and row.get("record_type", "final") == "final"
                and row.get("verdict") in {"correct", "corrected"}
            ):
                return row
    return None


def _latest_accepted_record(path: Path, concept: str, perspective: str) -> dict[str, Any] | None:
    latest: dict[str, Any] | None = None
    if not path.exists():
        return None
    with path.open(encoding="utf-8", errors="replace") as handle:
        for line in handle:
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            if (
                row.get("concept") == concept
                and row.get("perspective") == perspective
                and row.get("prompt_version") == PROMPT_VERSION
                and row.get("record_type", "final") == "final"
                and row.get("verdict") in {"correct", "corrected"}
                and isinstance(row.get("verified_spec"), str)
            ):
                latest = row
    return latest


def _recent_failure_record(
    path: Path, key: str, max_age_seconds: int
) -> dict[str, Any] | None:
    if max_age_seconds <= 0 or not path.exists():
        return None
    latest: dict[str, Any] | None = None
    with path.open(encoding="utf-8", errors="replace") as handle:
        for line in handle:
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            if row.get("key") == key and row.get("record_type") == "fallback":
                latest = row
    if latest is None:
        return None
    try:
        timestamp = datetime.fromisoformat(str(latest.get("timestamp", "")))
    except ValueError:
        return None
    age = datetime.now(timezone.utc) - timestamp.astimezone(timezone.utc)
    return latest if age.total_seconds() <= max_age_seconds else None


def load_verified_algebraic_spec(
    concept: Any,
    perspective: Any,
    audit_path: str | Path | None = None,
) -> str:
    """Return the newest accepted representation for a concept/perspective."""

    concept_text = str(concept)
    perspective_text = str(perspective)
    path = Path(
        audit_path
        or os.environ.get("ALGEBRAIC_SPEC_VERIFIER_AUDIT", DEFAULT_AUDIT_PATH)
    )
    latest = _latest_accepted_record(path, concept_text, perspective_text)
    if latest is None:
        raise VerificationError(
            f"no verified specification stored for {concept_text}/{perspective_text}"
        )
    verified = str(latest.get("verified_spec", ""))
    validate_spec_text(
        verified, concept_text, perspective_text, normalized_axioms=True
    )
    return verified


def _append_jsonl(path: Path, row: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(row, sort_keys=True) + "\n")


def _safe_atom(value: str) -> str:
    atom = re.sub(r"[^A-Za-z0-9_]+", "_", value).strip("_")
    if not atom or not atom[0].islower():
        atom = f"v_{atom}"
    return atom


def _append_metta_store(path: Path, row: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    record_id = f"llm_verification_{row['key'][:20]}"
    fact = (
        f"(: {record_id} (llm_verified_algebraic_spec {record_id} "
        f"{_safe_atom(row['concept'])} {_safe_atom(row['perspective'])} "
        f"{row['verdict']} {row['confidence']:.6f} {row['verified_spec']}))\n"
    )
    with path.open("a", encoding="utf-8") as handle:
        handle.write(fact)


def verify_with_provider(
    concept: str,
    perspective: str,
    spec_text: str,
    provider: VerificationProvider,
    config: VerificationConfig,
) -> str:
    concept = str(concept)
    perspective = str(perspective)
    spec_text = str(spec_text).strip()
    validate_spec_text(spec_text, concept, perspective)
    key = verification_key(concept, perspective, spec_text, provider.model_id)
    cached = _cached_record(config.audit_path, key)
    if cached is not None:
        verified = str(cached.get("verified_spec", ""))
        validate_spec_text(verified, concept, perspective, normalized_axioms=True)
        log_pipeline_event(
            "success",
            "algebraic_spec_verifier_cache_hit",
            concept,
            perspective,
            {"model": provider.model_id},
        )
        return verified
    recent_failure = _recent_failure_record(
        config.audit_path, key, config.failure_cache_seconds
    )
    if recent_failure is not None:
        log_pipeline_event(
            "error",
            "algebraic_spec_verifier_failure_cooldown",
            concept,
            perspective,
            {"model": provider.model_id},
        )
        if config.failure_policy == "error":
            raise VerificationError("verification is in failed-query cooldown")
        fallback_spec = str(recent_failure.get("fallback_spec", spec_text))
        validate_spec_text(fallback_spec, concept, perspective)
        log_pipeline_event(
            "success",
            "algebraic_spec_verifier_fallback_used",
            concept,
            perspective,
            "recent failure cooldown",
        )
        return fallback_spec

    instructions = system_prompt()
    prompt = candidate_prompt(concept, perspective, spec_text)
    previous_response: dict[str, Any] = {}
    last_errors: list[str] = []
    for attempt in range(1, config.max_attempts + 1):
        raw: dict[str, Any] = {}
        errors: list[str] = []
        result: VerificationResult | None = None
        rendered = ""
        effective_verdict = ""
        try:
            raw = provider.verify(instructions, prompt)
            result = normalize_result(raw)
            if result.verdict == "rejected":
                errors.append(f"LLM rejected the specification: {result.summary}")
            else:
                errors.extend(structured_spec_errors(result.specification, concept, perspective))
                if not errors:
                    rendered = render_structured_specification(result.specification)
                    validate_spec_text(
                        rendered, concept, perspective, normalized_axioms=True
                    )
                    effective_verdict = (
                        "corrected"
                        if result.verdict == "correct"
                        and parse_metta(rendered) != parse_metta(spec_text)
                        else result.verdict
                    )
        except Exception as exc:
            errors.append(f"{type(exc).__name__}: {exc}")

        attempt_row = {
            "record_type": "attempt",
            "key": key,
            "prompt_version": PROMPT_VERSION,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "attempt": attempt,
            "model": provider.model_id,
            "concept": concept,
            "perspective": perspective,
            "status": "invalid" if errors else "valid",
            "validation_errors": errors,
            "raw_response": raw,
        }
        _append_jsonl(config.audit_path, attempt_row)
        if errors:
            log_pipeline_event(
                "error",
                "algebraic_spec_verification_attempt",
                concept,
                perspective,
                {"attempt": attempt, "errors": errors},
            )

        if not errors and result is not None:
            row = {
                "record_type": "final",
                "key": key,
                "prompt_version": PROMPT_VERSION,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "model": provider.model_id,
                "concept": concept,
                "perspective": perspective,
                "verdict": effective_verdict,
                "confidence": result.confidence,
                "summary": result.summary,
                "issues": list(result.issues),
                "section_assessments": result.section_assessments,
                "original_spec": spec_text,
                "structured_specification": result.specification,
                "axiom_operation_dependencies": axiom_operation_dependencies(
                    result.specification
                ),
                "verified_spec": rendered,
            }
            _append_jsonl(config.audit_path, row)
            _append_metta_store(config.metta_store_path, row)
            log_pipeline_event(
                "success",
                "algebraic_spec_llm_verified",
                concept,
                perspective,
                {
                    "attempt": attempt,
                    "verdict": effective_verdict,
                    "model": provider.model_id,
                },
            )
            return rendered

        last_errors = errors
        previous_response = raw
        prompt = repair_prompt(concept, perspective, spec_text, previous_response, errors)

    latest = _latest_accepted_record(config.audit_path, concept, perspective)
    fallback_spec = str(latest["verified_spec"]) if latest is not None else spec_text
    validate_spec_text(fallback_spec, concept, perspective)
    failure_row = {
        "record_type": "fallback",
        "key": key,
        "prompt_version": PROMPT_VERSION,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "model": provider.model_id,
        "concept": concept,
        "perspective": perspective,
        "status": "verification_failed",
        "validation_errors": last_errors,
        "original_spec": spec_text,
        "fallback_spec": fallback_spec,
    }
    _append_jsonl(config.audit_path, failure_row)
    log_pipeline_event(
        "error",
        "algebraic_spec_verification_failed",
        concept,
        perspective,
        {"attempts": config.max_attempts, "errors": last_errors},
    )
    if config.failure_policy == "error":
        raise VerificationError("verification failed after retries: " + "; ".join(last_errors))
    log_pipeline_event(
        "success",
        "algebraic_spec_verifier_fallback_used",
        concept,
        perspective,
        "latest accepted specification or local candidate",
    )
    return fallback_spec


def config_from_environment() -> VerificationConfig:
    return VerificationConfig(
        mode=os.environ.get("ALGEBRAIC_SPEC_VERIFIER_MODE", "auto").lower(),
        model=os.environ.get("ALGEBRAIC_SPEC_VERIFIER_MODEL", DEFAULT_MODEL),
        api_key_env=os.environ.get("ALGEBRAIC_SPEC_VERIFIER_API_KEY_ENV", "OPENAI_API_KEY"),
        base_url=os.environ.get("OPENAI_BASE_URL") or None,
        timeout=float(os.environ.get("ALGEBRAIC_SPEC_VERIFIER_TIMEOUT", "90")),
        max_output_tokens=int(os.environ.get("ALGEBRAIC_SPEC_VERIFIER_MAX_OUTPUT_TOKENS", "10000")),
        max_attempts=int(os.environ.get("ALGEBRAIC_SPEC_VERIFIER_MAX_ATTEMPTS", "2")),
        failure_policy=os.environ.get("ALGEBRAIC_SPEC_VERIFIER_FAILURE_POLICY", "fallback").lower(),
        failure_cache_seconds=int(
            os.environ.get("ALGEBRAIC_SPEC_VERIFIER_FAILURE_CACHE_SECONDS", "3600")
        ),
        audit_path=Path(os.environ.get("ALGEBRAIC_SPEC_VERIFIER_AUDIT", DEFAULT_AUDIT_PATH)),
        metta_store_path=Path(os.environ.get("ALGEBRAIC_SPEC_VERIFIER_METTA_STORE", DEFAULT_METTA_STORE_PATH)),
    )


def verify_algebraic_spec(concept: Any, perspective: Any, spec_text: Any) -> str:
    """PeTTa entry point: verify, persist, and return a complete specification."""

    concept_text = str(concept)
    perspective_text = str(perspective)
    candidate = coerce_spec_text(spec_text)
    log_pipeline_event(
        "success",
        "algebraic_spec_verification_started",
        concept_text,
        perspective_text,
        "candidate received",
    )
    try:
        if os.environ.get("ALGEBRAIC_SPEC_VERIFIER_TRACE") == "1":
            print(f"ALGEBRAIC_SPEC_VERIFIER candidate={candidate!r}", file=sys.stderr)
        config = config_from_environment()
        validate_spec_text(candidate, concept_text, perspective_text)
        api_key = os.environ.get(config.api_key_env, "")
        if config.mode == "off" or (config.mode == "auto" and not api_key):
            log_pipeline_event(
                "success",
                "algebraic_spec_verification_skipped",
                concept_text,
                perspective_text,
                {"mode": config.mode},
            )
            return candidate
        if not api_key:
            raise VerificationError(f"{config.api_key_env} is required in verify mode")
        provider = OpenAIVerificationProvider(
            api_key=api_key,
            model=config.model,
            base_url=config.base_url,
            timeout=config.timeout,
            max_output_tokens=config.max_output_tokens,
        )
        verified = verify_with_provider(
            concept_text, perspective_text, candidate, provider, config
        )
        log_pipeline_event(
            "success",
            "algebraic_spec_verification_completed",
            concept_text,
            perspective_text,
            {"model": config.model},
        )
        return verified
    except Exception as exc:
        fail_pipeline(
            "algebraic_spec_verification",
            concept_text,
            perspective_text,
            f"{type(exc).__name__}: {exc}",
        )
        raise
