# Hybrid-search initialization

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

Sampling is deliberately one-shot.  For bias values
`(0 0.25 0.5 0.75 1)`, subproblem `j` uses

```text
m_j = (1 - beta_j) m_0 + beta_j h
x_jk ~ N(m_j, sigma_0^2 I),  k = 1..10
```

No mean, covariance, step-size, or evolution-path update is performed here.

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
```
