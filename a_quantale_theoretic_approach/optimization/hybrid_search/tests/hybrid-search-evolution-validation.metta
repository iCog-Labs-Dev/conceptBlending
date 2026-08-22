;; Focused validation of the shared-population evolutionary boundary.

!(import! &self ../../../../PeTTa/lib/lib_import)
!(import! &self ../candidate-evaluation)
!(import! &self ../hybrid-search-mcbride-refinement)
!(import! &self ../hybrid-search-evolution)

(= (evolution-test-candidate $subproblem $individual $e $c $o $p)
   (HybridCandidate
      (CandidateId $subproblem $individual 0)
      (Vector (0.5))
      (Blend
         (Concept test functional_use
            (V-predicate
               (Property ((feature (WorldSpecSet (world)) 0.5))))))
      (RefinementState Unrefined)
      (CandidateFitness
         ((CandidateObjective Emergence Evaluated $e ())
          (CandidateObjective Coherence Evaluated $c ())
          (CandidateObjective UnifiedOptimality Evaluated $o ())
          (CandidateObjective PeirceanQuality Evaluated $p ())))
      (FitnessVector Evaluated ($e $c $o $p))))

(= (evolution-test-population $index $count)
   (if (>= $index $count)
       ()
       (cons-atom
          (evolution-test-candidate
             (hs-positive-remainder $index 5) $index
             (/ (+ $index 1) (+ $count 1.0))
             (/ (- $count $index) (+ $count 1.0))
             0.5 0.5)
          (evolution-test-population (+ $index 1) $count))))

(= (evolution-test-sampled-candidates $subproblem $individual)
   (if (>= $individual 10)
       ()
       (cons-atom
          (SampledCandidate $subproblem $individual
             (Vector (0.5))
             (Concept test functional_use
                (V-predicate
                   (Property ((feature (WorldSpecSet (world)) 0.5))))))
          (evolution-test-sampled-candidates
             $subproblem (+ $individual 1)))))

(= (evolution-test-subproblems $subproblem)
   (if (>= $subproblem 5)
       ()
       (cons-atom
          (SubproblemPopulation
             $subproblem (* 0.25 $subproblem)
             (Mean (0.5)) (Covariance ((0.1))) (StepSize 0.15)
             (Population
                (evolution-test-sampled-candidates $subproblem 0)))
          (evolution-test-subproblems (+ $subproblem 1)))))

(= (EvolutionTestInitialization)
   (HabitBiasedPopulationInitialization Ready
      (CandidateSchema feature)
      (InitialMean (0.5))
      (HabitVector (0.5))
      (Sampler random-multivariate)
      (Subproblems (evolution-test-subproblems 0))))

;; Five sampling distributions become one population of fifty, while their
;; five source/bias records remain available as provenance.
!(let $aggregated (hs-aggregate-five-samples (EvolutionTestInitialization))
   (let* (
      ($_status (test (index-atom $aggregated 1) Ready))
      ($_sources
         (test (size-atom (index-atom (index-atom $aggregated 6) 1)) 5)))
      (test (size-atom (index-atom (index-atom $aggregated 7) 1)) 50)))

;; Dominance uses all four maximized objectives, not either of the legacy
;; two-objective comparisons.
!(let* (
   ($strong (evolution-test-candidate 0 0 0.9 0.8 0.7 0.6))
   ($weak (evolution-test-candidate 1 1 0.8 0.8 0.6 0.5))
   ($tradeoff (evolution-test-candidate 2 2 0.95 0.3 0.9 0.4)))
   (let* (
      ($_dominates (test (hs-dominates $strong $weak) True))
      ($_not-reverse (test (hs-dominates $weak $strong) False)))
      (test
         (size-atom
            (hs-front-candidates
               (hs-global-pareto-front ($strong $weak $tradeoff))))
         2)))

;; Environmental selection combines parent and offspring candidates globally
;; and returns exactly the requested survivor capacity.
!(let* (
   ($parents (evolution-test-population 0 50))
   ($offspring (evolution-test-population 50 25))
   ($selection (hs-environmental-select $parents $offspring 50)))
   (test (size-atom (index-atom (index-atom $selection 3) 1)) 50))

;; Tournament selection and variation share one global candidate pool and are
;; reproducible for a fixed seed.
!(let* (
   ($population (evolution-test-population 0 6))
   ($first (hs-produce-offspring $population 1 3 0.9 0.2 0.1 71))
   ($second (hs-produce-offspring $population 1 3 0.9 0.2 0.1 71)))
   (let $_deterministic (test $first $second)
      (test (size-atom (index-atom $first 1)) 3)))

;; Direct variation demonstrates that parents from different sampling origins
;; can mate, and that mutation clamps degrees to the admissible interval.
!(let* (
   ($left (evolution-test-candidate 0 0 0.9 0.8 0.7 0.6))
   ($right (evolution-test-candidate 4 9 0.8 0.9 0.6 0.7))
   ((OffspringVariation $child $state)
      (hs-vary-parent-pair $left $right 0 1 1.0 1.0 4.0 17))
   ($parents (index-atom $child 2))
   ($degree (car-atom (index-atom (index-atom $child 3) 1))))
   (let* (
      ($_left-origin
         (test (index-atom (index-atom $parents 1) 1) 0))
      ($_right-origin
         (test (index-atom (index-atom $parents 2) 1) 4))
      ($_lower-bound (test (>= $degree 0.01) True)))
      (test (<= $degree 0.99) True)))
