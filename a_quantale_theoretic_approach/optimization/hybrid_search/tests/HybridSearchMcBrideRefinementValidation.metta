;; McBride refinement lifecycle: mutate degrees now, retain fitness until a
;; selected survivor is explicitly promoted and evaluated in the next generation.

;; PeTTa does not re-export nested imports to an importing caller. Load the
;; public component rules explicitly, then load the initialization entry point
;; to validate that it wires the same refinement stage.
!(import! &self ../CandidateEvaluation)
!(import! &self ../HybridSearchMcBrideRefinement)
!(import! &self ../HybridSearchInitialization)

(= (RefinementSourceA)
   (Concept source_a functional_use
      (V-predicate
         (Property
            ((prop_a (WorldSpecSet (W)) 0.55)
             (shared (WorldSpecSet (W)) 0.50))))))

(= (RefinementSourceB)
   (Concept source_b functional_use
      (V-predicate
         (Property
            ((prop_b (WorldSpecSet (W)) 0.60)
             (shared (WorldSpecSet (W)) 0.45))))))

(= (RefinementCandidate)
   (Concept candidate functional_use
      (V-predicate
         (Property
            ((novel (WorldSpecSet (W)) 0.55)
             (shared (WorldSpecSet (W)) 0.60))))))

(= (RefinementOptimality $candidate)
   (VOptimalityResult Evaluated
      ((VConstraintResult Integration Evaluated (Q (W) 0.75) Fixture))
      (Q (W) 0.75)))

(= (RefinementContextFor $subproblem $individual $candidate)
   (HybridEvaluationContext
      (RefinementSourceA) (RefinementSourceB)
      (CoherenceConfiguration 0.3
         (SemanticCoherenceEvidence
            ((SemanticPair novel shared 0.8))))
      (CandidateOptimalityArtifacts
         ((CandidateOptimalityResult
            $subproblem $individual
            $candidate (RefinementOptimality $candidate))))
      (PeirceanEvaluationEvidence
         0.6
         (HabitPairStrengths
            ((HabitPairStrength novel shared 0.4)))
         (HabitBreakEvidence
            ((CandidateHabitBreakPairs
               $subproblem $individual
               ((novel shared 0.5))))))))

(= (RefinementConfiguration)
   (McBrideRefinementConfiguration
      0.05 2 0.0001 5 1.0 1729))

(= (RefinementEvaluatedCandidate $subproblem $individual)
   (hs-evaluate-candidate
      (SampledCandidate
         $subproblem $individual
         (Vector (0.55 0.60))
         (RefinementCandidate))
      (RefinementContextFor
         $subproblem $individual (RefinementCandidate))))

;; A permissive threshold with patience one terminates after one step and the
;; trace reports that convergence without dropping the concept perspective.
!(let* (
   ((McBrideRefinementResult $status $blend $trace)
      (q-mcbride-refine-result-with
         (RefinementCandidate)
         (RefinementSourceA) (RefinementSourceB)
         0.05 10 2.0 1)))
   (let $_status (test $status Converged)
      (let $_steps (test (index-atom $trace 1) 1)
         (test (index-atom $blend 2) functional_use))))

;; Candidate-level contract: blend/vector change, fitness snapshot and identity
;; remain byte-for-byte equal for current-generation Pareto selection.
!(let* (
   ($original (RefinementEvaluatedCandidate 0 0))
   ($refined
      (hs-refined-candidate
         $original (RefinementSourceA) (RefinementSourceB)
         (RefinementConfiguration) 0.0))
   ($original-blend (hs-candidate-blend $original))
   ($refined-blend (hs-candidate-blend $refined)))
   (let $_identity
      (test (hs-candidate-identity $refined)
            (hs-candidate-identity $original))
      (let $_fitness
         (test (hs-candidate-fitness $refined)
               (hs-candidate-fitness $original))
         (let $_fitness-vector
            (test (hs-candidate-fitness-vector $refined)
                  (hs-candidate-fitness-vector $original))
            (let $_changed
               (test (== $refined-blend $original-blend) False)
               (let $_degree-zero
                  (test
                     (> (index-atom
                           (index-atom (hs-candidate-vector $refined) 1) 0)
                        (index-atom
                           (index-atom (hs-candidate-vector $original) 1) 0))
                     True)
                  (let $_degree-one
                     (test
                        (> (index-atom
                              (index-atom (hs-candidate-vector $refined) 1) 1)
                           (index-atom
                              (index-atom (hs-candidate-vector $original) 1) 1))
                        True)
                     (let $_perspective
                        (test (index-atom $refined-blend 2) functional_use)
                        (test
                           (index-atom
                              (hs-candidate-refinement-state $refined) 1)
                           Refined)))))))))

;; A skipped decision returns the original candidate unchanged.
!(let $original (RefinementEvaluatedCandidate 0 0)
   (test
      (hs-refined-candidate
         $original (RefinementSourceA) (RefinementSourceB)
         (McBrideRefinementConfiguration
            0.05 2 0.0001 5 0.0 1729)
         0.5)
      $original))

;; Reevaluation is delayed until explicit survivor promotion. The promoted
;; candidate enters generation 1 and coherence observes its refined degrees.
!(let* (
   ($original (RefinementEvaluatedCandidate 0 0))
   ($refined
      (hs-refined-candidate
         $original (RefinementSourceA) (RefinementSourceB)
         (RefinementConfiguration) 0.0))
   ($promoted (hs-promote-survivor $refined))
   ($refined-blend (hs-candidate-blend $refined))
   ($next
      (hs-evaluate-promoted-candidate
         $promoted (RefinementContextFor 0 0 $refined-blend)))
   ((CandidateFitness $old-objectives)
      (hs-candidate-fitness $original))
   ((CandidateFitness $next-objectives)
      (hs-candidate-fitness $next)))
   (let $_generation
      (test (index-atom (hs-candidate-identity $next) 3) 1)
      (let $_count (test (size-atom $next-objectives) 4)
         (test
            (== (hs-objective-score (index-atom $old-objectives 1))
                (hs-objective-score (index-atom $next-objectives 1)))
            False))))

;; Complete 5x10 evaluated fixture.
(= (refinement-candidates $subproblem $individual)
   (if (>= $individual 10)
       ()
       (cons-atom
          (RefinementEvaluatedCandidate $subproblem $individual)
          (refinement-candidates
             $subproblem (+ $individual 1)))))

(= (refinement-subproblems $subproblem)
   (if (>= $subproblem 5)
       ()
       (cons-atom
          (EvaluatedSubproblemPopulation
             $subproblem
             (HabitBias (/ $subproblem 4.0))
             (Mean (0.55 0.60))
             (Covariance ((1 0) (0 1)))
             (StepSize 0.15)
             (Population (refinement-candidates $subproblem 0)))
          (refinement-subproblems (+ $subproblem 1)))))

(= (RefinementFivePopulations)
   (HabitBiasedPopulationEvaluation Evaluated
      (CandidateSchema novel shared)
      (InitialMean (0.55 0.60))
      (HabitVector (0.9 0.8))
      (Sampler random-multivariate)
      (Subproblems (refinement-subproblems 0))))

(= (refinement-population-counts ()) ())
(= (refinement-population-counts (cons $subproblem $remaining))
   (cons-atom
      (size-atom (index-atom (index-atom $subproblem 6) 1))
      (refinement-population-counts $remaining)))

(= (refinement-all-fitness-preserved ()) True)
(= (refinement-all-fitness-preserved (cons $candidate $remaining))
   (if (== (hs-candidate-fitness-vector $candidate)
           (hs-candidate-fitness-vector
              (RefinementEvaluatedCandidate
                 (index-atom (hs-candidate-identity $candidate) 1)
                 (index-atom (hs-candidate-identity $candidate) 2))))
       (refinement-all-fitness-preserved $remaining)
       False))

(= (refinement-subproblem-fitness-preserved ()) True)
(= (refinement-subproblem-fitness-preserved
      (cons $subproblem $remaining))
   (if (refinement-all-fitness-preserved
          (index-atom (index-atom $subproblem 6) 1))
       (refinement-subproblem-fitness-preserved $remaining)
       False))

!(let $refined
   (hs-refine-five-populations
      (RefinementFivePopulations)
      (RefinementSourceA) (RefinementSourceB)
      (McBrideRefinementConfiguration
         0.05 1 0.0001 5 1.0 1729))
   (let* (
      ($summary (index-atom $refined 6))
      ($subproblems (index-atom (index-atom $refined 7) 1)))
      (let $_refined-count
         (test (index-atom (index-atom $summary 1) 1) 50)
         (let $_subproblem-count
            (test (size-atom $subproblems) 5)
            (let $_population-counts
               (test (refinement-population-counts $subproblems)
                     (10 10 10 10 10))
               (test
                  (refinement-subproblem-fitness-preserved $subproblems)
                  True))))))

;; Same seed yields the same first two decision draws.
!(let* (
   ($state (hs-lcg-normalize 1729))
   ($first (hs-lcg-next $state))
   ($second (hs-lcg-next $first)))
   (let $_first
      (test $first (hs-lcg-next (hs-lcg-normalize 1729)))
      (test $second
            (hs-lcg-next
               (hs-lcg-next (hs-lcg-normalize 1729))))))
