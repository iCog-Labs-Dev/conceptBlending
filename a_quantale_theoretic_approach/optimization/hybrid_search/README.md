# Hybrid-search initialization and candidate evaluation

This component implements steps 1–4 of the memetic quantale-blending search:

1. extract compact source V-predicates with the existing extraction pipeline;
2. attach reproducible scalar placeholder degrees while the GNN is unavailable;
3. generalize every Cartesian property pair and every Cartesian pair of their
   possible worlds, storing a genuine algebraic specification for each generic
   world;
4. augment the sibling `habit_memory` component with indexed atomspace counts,
   construct the habit target, and sample five fixed populations of ten.

The public PeTTa operation is:

```metta
(initialize-habit-biased-populations
  generic-name perspective concept-a concept-b seed kappa)
```

The result contains the two scalar source predicates, the generic V-predicate
with property/world provenance, the habit target, and all 50 candidates.

Candidate evaluation is a second, PeTTa-native stage because its semantic,
optimality, and habit-break evidence is candidate-specific and may be produced
after initialization:

```metta
(hs-evaluate-initialization-result initialization evaluation-context)
```

The evaluation context has this shape:

```metta
(HybridEvaluationContext
  source-a source-b
  (CoherenceConfiguration alpha
    (SemanticCoherenceEvidence semantic-pairs))
  (CandidateOptimalityArtifacts candidate-entries)
  (PeirceanEvaluationEvidence alpha
    (HabitPairStrengths strengths)
    (HabitBreakEvidence candidate-break-entries)))
```

Every `SampledCandidate` becomes a `HybridCandidate` containing four named
`CandidateObjective` records, in the stable order emergence, coherence,
unified optimality, and Peircean quality. It also carries a four-element
`FitnessVector` for later Pareto/CMA operations. Coherence is implemented here
as the weighted information-theoretic/semantic formula; it is no longer
substituted by optimality. Emergence uses an isolated, definitionally equivalent
spelling of the existing Product-quantale evaluator (covered by an equivalence
test), unified optimality uses the existing enriched evaluator during artifact
materialization, and Peircean quality delegates to the existing habit-memory
scoring formula.

Semantic pairs, optimality artifacts, and habit-break evidence must be supplied
explicitly. Missing or candidate-mismatched evidence produces a `Blocked`
objective and therefore a blocked fitness vector; the evaluator never invents
a passing score. The traversal consumes candidate-bound
`CandidateOptimalityResult` entries; an unmaterialized input is blocked.

For a batch of raw `CandidateOptimalityInput` records, import
`CandidateOptimalityEvaluation.metta` and call
`hs-materialize-optimality-entries` before constructing the shared evaluation
context. Keeping this materialization boundary separate prevents PeTTa's
transitive imports from duplicating V-predicate rewrite rules during the 50-way
population traversal.

Sampling is deliberately one-shot.  For bias values
`(0 0.25 0.5 0.75 1)`, subproblem `j` uses

```text
m_j = (1 - beta_j) m_0 + beta_j h
x_jk = random-multivariate(m_j, sigma_0^2 C_0, 10)
```

The draw is performed by `peTTa_version/utils/cma-es-utils.metta`, using its
Cholesky-based `random-multivariate` implementation. Its scalar standard-normal
draw uses Python's standard-library Gaussian generator, so this path does not
require NumPy. No mean, covariance, step-size, or evolution-path update is
performed here.

The first evidence-backed run builds
`habit_memory/.cache/atomspace_habits.sqlite3` from all simple binary edges in
the extraction pipeline's concept atomspace.  Later runs validate the source
fingerprint and reuse the index.  The index contributes property/pair counts to
the existing Jaccard and PMI calculations; existing historical memory and the
existing embedding score remain unchanged.

Run deterministic validation with:

```bash
python3 -B -m unittest \
  a_quantale_theoretic_approach.optimization.hybrid_search.tests.test_hybrid_sampling -v

petta \
  a_quantale_theoretic_approach/optimization/hybrid_search/tests/HybridSearchInitializationValidation.metta

petta \
  a_quantale_theoretic_approach/optimization/hybrid_search/tests/CandidateEvaluationValidation.metta
```
