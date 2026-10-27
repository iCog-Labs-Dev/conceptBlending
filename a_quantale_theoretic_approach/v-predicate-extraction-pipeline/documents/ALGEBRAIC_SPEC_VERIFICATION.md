# Final algebraic-specification verification

`build-algebraic-spec` builds the KB-backed draft and sends it through the final
verifier when enabled. The model returns a typed JSON representation rather
than handwritten MeTTa. The verifier validates that representation, renders
balanced MeTTa deterministically, stores the accepted result, and returns it.

The deterministic builder remains available as:

```metta
!(build-algebraic-spec-unverified human cognitive_agency)
```

The integrated verified builder is:

```metta
!(build-algebraic-spec human cognitive_agency)
```

The newest stored representation can be retrieved without another LLM call:

```metta
!(load-verified-algebraic-spec human cognitive_agency)
```

## Runtime configuration

- `ALGEBRAIC_SPEC_VERIFIER_MODE=auto` is the default. It verifies when
  `OPENAI_API_KEY` exists and otherwise returns the locally validated draft.
- `ALGEBRAIC_SPEC_VERIFIER_MODE=verify` requires the API key. Its behavior after
  unsuccessful verification is controlled by `ALGEBRAIC_SPEC_VERIFIER_FAILURE_POLICY`.
- `ALGEBRAIC_SPEC_VERIFIER_MODE=off` performs no LLM call and returns the
  locally validated draft.
- `ALGEBRAIC_SPEC_VERIFIER_MODEL` selects the model.
- `ALGEBRAIC_SPEC_VERIFIER_MAX_ATTEMPTS` sets the total initial-plus-repair
  attempts. The default is `2`.
- `ALGEBRAIC_SPEC_VERIFIER_MAX_OUTPUT_TOKENS` sets the model output budget. The
  default is `10000`.
- `ALGEBRAIC_SPEC_VERIFIER_FAILURE_CACHE_SECONDS` prevents an identical failed
  draft from immediately purchasing the same retries again. The default
  cooldown is `3600` seconds; set it to `0` to disable the cooldown.
- `ALGEBRAIC_SPEC_VERIFIER_FAILURE_POLICY=fallback` is the default. After all
  attempts fail, the verifier returns the newest accepted result for the same
  concept and perspective, or the original locally validated draft if none is
  stored.
- `ALGEBRAIC_SPEC_VERIFIER_FAILURE_POLICY=error` raises a `VerificationError`
  after all attempts fail. This is useful for strict batch validation.
- `ALGEBRAIC_SPEC_VERIFIER_TRACE=1` prints the complete candidate algebraic
  specification passed to the verifier to standard error. It is useful for
  confirming what the data layer generated before LLM repair.
- `ALGEBRAIC_SPEC_VERIFIER_AUDIT` overrides the JSONL audit/cache path.
- `ALGEBRAIC_SPEC_VERIFIER_METTA_STORE` overrides the MeTTa store path.

For a strict diagnostic run:

```sh
export ALGEBRAIC_SPEC_VERIFIER_MODE=verify
export ALGEBRAIC_SPEC_VERIFIER_FAILURE_POLICY=error
export ALGEBRAIC_SPEC_VERIFIER_TRACE=1
```

Redirect trace output separately when needed:

```sh
petta your-query.metta \
  2> /tmp/algebraic-spec-verifier.log
```

The trace is emitted only when `build-algebraic-spec` reaches the verifier.
An accepted verifier-cache hit may reuse a result without a provider request,
and an `ensure-world-algebraic-spec` hit in `&algspecspace` or the persistent
algebraic-specification cache skips the builder and verifier entirely.

Every LLM attempt, including malformed or rejected attempts, is stored in
`AlgebraicSpecificationVerified.jsonl` with its raw structured response and
validation errors. Only validated final results are cacheable and are appended
to `AlgebraicSpecificationVerifiedKB.metta`. The cache key includes the complete
draft, model, and prompt version, so an unchanged accepted specification is not
billed for verification again.

Prompt version `algebraic-spec-final-verifier-v4` treats the KB result as a
non-authoritative draft. It permits comprehensive content reconstruction while
preserving the MeTTa container and section formats. It supplies a short semantic
context for the requested perspective but sets no minimum section size. The
compact worked example and reduced retry payload lower input-token use. The
version bump prevents older verifier results with incorrectly scoped axioms
from being reused.

## Failure handling

The response schema enforces the 15-item section limit before generation and
represents terms and Horn axioms as structured data. Local validation then
checks the requested concept and perspective, symbol syntax, declarations,
operation and predicate signatures, term and predicate argument types, equality
types, closure sorts, law kinds, nontriviality, partial-operation definedness,
and quantified-variable use. Python alone emits the final parentheses, so
truncated model text cannot produce an unclosed MeTTa expression.

Verified axioms use the normal form:

```metta
(forall ((x sort_x) (y sort_y))
  (=> (domain_premise x y) (domain_consequence x y)))
```

The quantifier scopes over the complete implication. `inPerspective` and
`declaredOperation` are not logical premises: perspective remains in the outer
`Concept` container, while operation dependencies are derived locally and kept
in JSON audit metadata. Perspective-plumbing operations such as `view_as_*`,
`base_*`, and an operation named after the perspective are rejected.

When an attempt fails schema, semantic, or local MeTTa validation, the next
attempt receives the original draft and exact validation errors, without
resending the previous full response. No invalid response is written to the
verified MeTTa store. With the default fallback policy, exhausted retries no
longer terminate the PeTTa process, and the failed-query cooldown avoids an
immediate repeat of the same paid attempts.

The verifier prompt and local acceptance checks are implemented in
`python/verification/algebraic_spec_verifier.py`. Its complete worked example
is stored in `fixtures/human_cognitive_agency_reference.metta`.
