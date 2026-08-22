;; Candidate-evaluation contracts and full five-by-ten traversal.

!(import! &self ../candidate-evaluation)
!(import! &self a_quantale_theoretic_approach/mcbride_petta/emergence)

(= (EvalSourceA)
   (Concept source_a functional_use
      (V-predicate
         (Property
            ((prop_a (WorldSpecSet (W)) 0.7)
             (shared (WorldSpecSet (W)) 0.6))))))

(= (EvalSourceB)
   (Concept source_b functional_use
      (V-predicate
         (Property
            ((prop_b (WorldSpecSet (W)) 0.8)
             (shared (WorldSpecSet (W)) 0.5))))))

(= (EvalCandidate)
   (Concept candidate functional_use
      (V-predicate
         (Property
            ((novel (WorldSpecSet (W)) 0.8)
             (shared (WorldSpecSet (W)) 0.7))))))

(= (EvaluatedOptimality)
   (VOptimalityResult Evaluated
      ((VConstraintResult Integration Evaluated (Q (W) 0.75) Fixture))
      (Q (W) 0.75)))

(= (FixtureContext)
   (HybridEvaluationContext
      (EvalSourceA) (EvalSourceB)
      (CoherenceConfiguration 0.3
         (SemanticCoherenceEvidence
            ((SemanticPair novel shared 0.8))))
      (CandidateOptimalityArtifacts
         ((CandidateOptimalityResult
            0 0 (EvalCandidate) (EvaluatedOptimality))))
      (PeirceanEvaluationEvidence
         0.6
         (HabitPairStrengths
            ((HabitPairStrength novel shared 0.4)))
         (HabitBreakEvidence
            ((CandidateHabitBreakPairs
               0 0 ((novel shared 0.5))))))))

(= (FixtureSample)
   (SampledCandidate 0 0 (Vector (0.8 0.7)) (EvalCandidate)))

;; The isolated implementation is definitionally equal to the existing
;; q-emergence evaluator for the same Product-quantale inputs.
!(test (hs-q-emergence (EvalSourceA) (EvalSourceB) (EvalCandidate))
       (q-emergence (EvalSourceA) (EvalSourceB) (EvalCandidate)))

!(let $candidate (hs-evaluate-candidate (FixtureSample) (FixtureContext))
   (let* (
      ((CandidateFitness $objectives) (hs-candidate-fitness $candidate))
      ((FitnessVector $status $values)
         (hs-candidate-fitness-vector $candidate)))
      (let $_candidate-status (test (hs-candidate-status $candidate) Evaluated)
         (let $_objective-count (test (size-atom $objectives) 4)
            (let $_vector-status (test $status Evaluated)
               (let $_vector-size (test (size-atom $values) 4)
                  (test (index-atom $values 2) 0.75)))))))

!(let $coherence
   (hs-evaluate-coherence
      (EvalCandidate)
      (CoherenceConfiguration 0.3
         (SemanticCoherenceEvidence ())))
   (test (hs-objective-status $coherence) Blocked))

!(let $optimality
   (hs-evaluate-unified-optimality
      0 0 (EvalCandidate)
      (CandidateOptimalityArtifacts ()))
   (test (hs-objective-status $optimality) Blocked))

;; Build a complete 5x10 fixture without duplicating fifty records by hand.
(= (fixture-sampled-candidates $subproblem $individual)
   (if (>= $individual 10)
       ()
       (cons-atom
          (SampledCandidate
             $subproblem $individual
             (Vector (0.8 0.7)) (EvalCandidate))
          (fixture-sampled-candidates
             $subproblem (+ $individual 1)))))

(= (fixture-subproblems $subproblem)
   (if (>= $subproblem 5)
       ()
       (cons-atom
          (SubproblemPopulation
             $subproblem
             (HabitBias (/ $subproblem 4.0))
             (Mean (0.8 0.7))
             (Covariance ((1 0) (0 1)))
             (StepSize 0.15)
             (Population
                (fixture-sampled-candidates $subproblem 0)))
          (fixture-subproblems (+ $subproblem 1)))))

(= (fixture-optimality-entries-for $subproblem $individual)
   (if (>= $individual 10)
       ()
       (cons-atom
          (CandidateOptimalityResult
             $subproblem $individual
             (EvalCandidate) (EvaluatedOptimality))
          (fixture-optimality-entries-for
             $subproblem (+ $individual 1)))))

(= (fixture-optimality-entries $subproblem)
   (if (>= $subproblem 5)
       ()
       (append
          (fixture-optimality-entries-for $subproblem 0)
          (fixture-optimality-entries (+ $subproblem 1)))))

(= (fixture-break-entries-for $subproblem $individual)
   (if (>= $individual 10)
       ()
       (cons-atom
          (CandidateHabitBreakPairs
             $subproblem $individual ((novel shared 0.5)))
          (fixture-break-entries-for
             $subproblem (+ $individual 1)))))

(= (fixture-break-entries $subproblem)
   (if (>= $subproblem 5)
       ()
       (append
          (fixture-break-entries-for $subproblem 0)
          (fixture-break-entries (+ $subproblem 1)))))

(= (FullFixtureContext)
   (HybridEvaluationContext
      (EvalSourceA) (EvalSourceB)
      (CoherenceConfiguration 0.3
         (SemanticCoherenceEvidence
            ((SemanticPair novel shared 0.8))))
      (CandidateOptimalityArtifacts
         (fixture-optimality-entries 0))
      (PeirceanEvaluationEvidence
         0.6
         (HabitPairStrengths
            ((HabitPairStrength novel shared 0.4)))
         (HabitBreakEvidence
            (fixture-break-entries 0)))))

(= (FixturePopulations)
   (HabitBiasedPopulationInitialization Ready
      (CandidateSchema novel shared)
      (InitialMean (0.8 0.7))
      (HabitVector (0.9 0.8))
      (Sampler random-multivariate)
      (Subproblems (fixture-subproblems 0))))

(= (fixture-evaluated-counts ()) ())
(= (fixture-evaluated-counts (cons $subproblem $remaining))
   (cons-atom
      (size-atom (index-atom (index-atom $subproblem 6) 1))
      (fixture-evaluated-counts $remaining)))

!(let $evaluated
   (hs-evaluate-five-populations
      (FixturePopulations) (FullFixtureContext))
   (let* (
      ($subproblems (index-atom (index-atom $evaluated 6) 1))
      ($_status (test (index-atom $evaluated 1) Evaluated))
      ($_subproblem-count (test (size-atom $subproblems) 5)))
      (test (fixture-evaluated-counts $subproblems)
            (10 10 10 10 10))))
