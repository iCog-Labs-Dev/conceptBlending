# PeTTa hybrid search

This component implements steps 1–4 of the memetic quantale-blending search:

1. extract compact source V-predicates with the existing extraction pipeline;
2. attach reproducible scalar placeholder degrees while the GNN is unavailable;
3. generalize every Cartesian property pair and every Cartesian pair of their
   possible worlds, storing a genuine algebraic specification for each generic
   world;
4. augment the sibling `habit_memory` component with indexed atomspace counts,
   construct the habit target, and sample five batches of ten;
5. immediately aggregate those batches into one shared population of 50;
6. evaluate, refine, and evolve the shared population, then return one global
   Pareto front;
7. after each environmental selection, reinforce successful blends and decay
   habit memory before evaluating the next generation.

The public PeTTa operation is:

```metta
(initialize-habit-biased-populations
  generic-name perspective concept-a concept-b seed kappa)
```

The result contains the two scalar source predicates, the generic V-predicate
with property/world provenance, the habit target, the five sampling batches,
an `AggregatedPopulation` holding all 50 candidates, and the atomspace-augmented
`HabitMemory` used to initialize the search. The original batch
index and habit bias remain in `CandidateId`/`SamplingProvenance`, but are never
used to partition mating or environmental selection.

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

## McBride local refinement

McBride refinement runs after current-generation evaluation and before Pareto
selection:

```metta
(hs-refine-evaluation-result
  evaluated-result
  (McBrideRefinementConfiguration
    eta max-steps threshold patience probability seed))
```

The operation is PeTTa-native and uses a deterministic Park–Miller decision
stream. A convenience constructor supplies the standard McBride parameters:

```metta
(hs-default-mcbride-refinement-configuration probability seed)
```

Refinement updates only the blend's property degrees and its corresponding
candidate vector. Candidate identity, `CandidateFitness`, and `FitnessVector`
are copied verbatim, so Pareto selection sees exactly the fitness values that
were computed before local refinement. The refinement state records the
decision draw, convergence status, step count, and initial/final emergence
signal.

After Pareto selection, promote only the surviving candidates:

```metta
(hs-promote-survivors survivors)
(hs-evaluate-promoted-survivors promoted-candidates next-generation-context)
```

Promotion increments the generation and is the explicit reevaluation boundary.
Consequently, refined degrees affect emergence and coherence only in the next
generation, if the candidate survives selection.

## Global evolution

`HybridSearchEvolution.metta` implements four-objective nondominated sorting,
crowding distance, seeded binary tournament selection, uniform crossover,
bounded mutation, and capacity-limited environmental selection. All four
fitness objectives are maximized. A generation is configured with:

```metta
(HybridEvolutionConfiguration
  capacity offspring-count crossover-rate mutation-rate mutation-scale seed)
```

For the agreed 50-member search, use capacity `50`; offspring count `25`
matches the previous Python loop. `hs-produce-offspring` creates lineage-bearing
drafts with no inherited fitness. `hs-evaluate-offspring-candidates` evaluates
those drafts before `hs-environmental-select` combines them with the 50 parents.

The complete recursive entry point is:

```metta
(run-hybrid-search-loop
  initialization initial-evaluation-context
  mcbride-configuration evolution-configuration habit-configuration
  generation-contexts)
```

Habit evolution is configured as `(HabitEvolutionConfiguration gamma)`. The
five-argument loop form remains available and uses the default `gamma = 0.99`.

Each item in `generation-contexts` has the shape
`(GenerationContexts generation offspring-context next-generation-context)`.
The two explicit contexts provide candidate-specific optimality and Peircean
evidence for offspring evaluation and survivor reevaluation. The loop returns
`HybridSearchLoopResult` with the generation trace, final 50-member population,
and one `GlobalParetoFront` over that population.

## Habit formation and decay

`HybridSearchHabitDynamics.metta` implements Algorithm 1's post-selection
habit boundary. For every generation it takes the nondominated front of the
environmentally selected population, converts each successful candidate to its
property-name set, and reuses `reinforce-nondominated-blends` semantics to add
those co-occurrences to memory. It then applies the configured decay factor.
Associations absent from successful blends therefore receive decay without a
new observation.

The update happens after selection, so it never changes the fitness values that
selected the current survivors. Before those survivors are promoted, existing
`HabitPairStrength` entries in the next-generation context are recomputed with
`get-habit-strength` from the updated memory. This makes the new habits affect
the next generation's Peircean objective while leaving emergence/coherence and
the McBride frozen-fitness rule intact. Sampling remains one-shot; evolved
habits also become available to later search runs through the returned
`UpdatedHabitMemory`.

The pure loop does not write `habit_memory/memory.metta`. Durable persistence is
an explicit final action:

```metta
(hs-persist-final-pareto! final-pareto-front)
```

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

petta \
  a_quantale_theoretic_approach/optimization/hybrid_search/tests/HybridSearchMcBrideRefinementValidation.metta

petta \
  a_quantale_theoretic_approach/optimization/hybrid_search/tests/HybridSearchEvolutionValidation.metta

petta \
  a_quantale_theoretic_approach/optimization/hybrid_search/tests/HybridSearchHabitDynamicsValidation.metta
```
