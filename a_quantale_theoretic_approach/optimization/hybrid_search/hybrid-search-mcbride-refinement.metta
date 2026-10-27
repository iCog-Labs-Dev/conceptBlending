;; McBride local refinement between current-generation evaluation and Pareto
;; selection. candidate-evaluation must be imported before this module.
;;
;; Refinement changes only the candidate blend/vector. The current generation's
;; CandidateFitness and FitnessVector atoms are copied verbatim. Reevaluation is
;; available only through the explicit next-generation promotion boundary.

!(import! &self a_quantale_theoretic_approach/mcbride_petta/refinement_loop)

;; --------------------------------------------------------------------------
;; Deterministic PeTTa-native refinement decisions
;; --------------------------------------------------------------------------

(= (hs-default-mcbride-refinement-configuration $probability $seed)
   (McBrideRefinementConfiguration
      0.05 20 0.0001 5 $probability $seed))

(= (hs-positive-remainder $number $modulus)
   (- $number
      (* $modulus (trunc-math (/ $number $modulus)))))

(= (hs-lcg-normalize $seed)
   (let $normalized
      (hs-positive-remainder $seed 2147483647)
      (if (<= $normalized 0) 1 $normalized)))

(= (hs-lcg-next $state)
   (hs-positive-remainder (* 16807 $state) 2147483647))

(= (hs-lcg-draw $state)
   (/ (hs-lcg-next $state) 2147483647.0))

;; --------------------------------------------------------------------------
;; Candidate refinement
;; --------------------------------------------------------------------------

(= (hs-refined-candidate
      (HybridCandidate
         (CandidateId $subproblem $individual $generation)
         $old-vector (Blend $old-blend) $old-state
         $fitness $fitness-vector)
      $source-a $source-b
      (McBrideRefinementConfiguration
         $eta $steps $threshold $patience $probability $seed)
      $draw)
   (if (and (== (hs-candidate-status
                    (HybridCandidate
                       (CandidateId $subproblem $individual $generation)
                       $old-vector (Blend $old-blend) $old-state
                       $fitness $fitness-vector))
                  Evaluated)
            (< $draw $probability))
       (let* (
          ((McBrideRefinementResult $result-status $refined-blend $trace)
             (q-mcbride-refine-result-with
                $old-blend $source-a $source-b
                $eta $steps $threshold $patience))
          ($refined-vector
             (hs-candidate-property-degrees $refined-blend)))
          (HybridCandidate
             (CandidateId $subproblem $individual $generation)
             (Vector $refined-vector)
             (Blend $refined-blend)
             (RefinementState Refined
                (ParentCandidateId
                   $subproblem $individual $generation)
                (Decision $draw $probability)
                (ResultStatus $result-status)
                $trace)
             $fitness
             $fitness-vector))
       (HybridCandidate
          (CandidateId $subproblem $individual $generation)
          $old-vector (Blend $old-blend) $old-state
          $fitness $fitness-vector)))

(= (hs-candidate-was-refined $candidate)
   (== (index-atom (hs-candidate-refinement-state $candidate) 1)
       Refined))

(= (hs-refinement-count ()) 0)
(= (hs-refinement-count (cons $candidate $remaining))
   (+ (if (hs-candidate-was-refined $candidate) 1 0)
      (hs-refinement-count $remaining)))

(= (hs-refine-candidates
      () $source-a $source-b $configuration $state)
   (CandidateRefinementBatch () $state))
(= (hs-refine-candidates
      (cons $candidate $remaining)
      $source-a $source-b $configuration $state)
   (let* (
      ($next-state (hs-lcg-next $state))
      ($draw (/ $next-state 2147483647.0))
      ($refined
         (hs-refined-candidate
            $candidate $source-a $source-b $configuration $draw))
      ((CandidateRefinementBatch $tail $final-state)
         (hs-refine-candidates
            $remaining $source-a $source-b
            $configuration $next-state)))
      (CandidateRefinementBatch
         (cons-atom $refined $tail) $final-state)))

;; --------------------------------------------------------------------------
;; Five-population traversal
;; --------------------------------------------------------------------------

(= (hs-refine-subproblem
      (EvaluatedSubproblemPopulation
         $index $habit-bias $mean $covariance $step-size
         (Population $candidates))
      $source-a $source-b $configuration $state)
   (let* (
      ((CandidateRefinementBatch $refined $next-state)
         (hs-refine-candidates
            $candidates $source-a $source-b $configuration $state)))
      (SubproblemRefinementBatch
         (RefinedSubproblemPopulation
            $index $habit-bias $mean $covariance $step-size
            (Population $refined))
         $next-state
         (hs-refinement-count $refined))))

(= (hs-refine-subproblems
      () $source-a $source-b $configuration $state)
   (SubproblemRefinementBatch () $state 0))
(= (hs-refine-subproblems
      (cons $subproblem $remaining)
      $source-a $source-b $configuration $state)
   (let* (
      ((SubproblemRefinementBatch
          $refined-head $next-state $head-count)
         (hs-refine-subproblem
            $subproblem $source-a $source-b $configuration $state))
      ((SubproblemRefinementBatch
          $refined-tail $final-state $tail-count)
         (hs-refine-subproblems
            $remaining $source-a $source-b
            $configuration $next-state)))
      (SubproblemRefinementBatch
         (cons-atom $refined-head $refined-tail)
         $final-state
         (+ $head-count $tail-count))))

(= (hs-refine-five-populations
      (HabitBiasedPopulationEvaluation
         $status $candidate-schema $initial-mean
         $habit-vector $sampler (Subproblems $subproblems))
      $source-a $source-b
      (McBrideRefinementConfiguration
         $eta $steps $threshold $patience $probability $seed))
   (let* (
      ($configuration
         (McBrideRefinementConfiguration
            $eta $steps $threshold $patience $probability $seed))
      ($initial-state (hs-lcg-normalize $seed))
      ((SubproblemRefinementBatch
          $refined $final-state $refined-count)
         (hs-refine-subproblems
            $subproblems $source-a $source-b
            $configuration $initial-state)))
      (HabitBiasedPopulationRefinement
         $status $candidate-schema $initial-mean
         $habit-vector $sampler
         (RefinementSummary
            (RefinedCount $refined-count)
            (DecisionStreamFinalState $final-state))
         (Subproblems $refined))))

(= (hs-refine-evaluation-result
      (HybridSearchCandidateEvaluationResult
         $status
         (Sources $source-a $source-b)
         (GenericSpace $generic)
         (HabitTargetResult $target)
         (EvaluatedPopulation $population)
         (HabitMemory $memory))
      $configuration)
   (let $refined
      (hs-refine-aggregated-population
         $population $source-a $source-b $configuration)
      (HybridSearchMcBrideRefinementResult
         $status
         (Sources $source-a $source-b)
         (GenericSpace $generic)
         (HabitTargetResult $target)
         (RefinedPopulation $refined)
         (HabitMemory $memory))))

(= (hs-refine-evaluation-result
      (HybridSearchCandidateEvaluationResult
         $status
         (Sources $source-a $source-b)
         (GenericSpace $generic)
         (HabitTargetResult $target)
         (EvaluatedPopulation $population))
      $configuration)
   (let $refined
      (hs-refine-aggregated-population
         $population $source-a $source-b $configuration)
      (HybridSearchMcBrideRefinementResult
         $status
         (Sources $source-a $source-b)
         (GenericSpace $generic)
         (HabitTargetResult $target)
         (RefinedPopulation $refined))))

;; Compatibility with the earlier five-independent-populations result.
(= (hs-refine-evaluation-result
      (HybridSearchCandidateEvaluationResult
         $status
         (Sources $source-a $source-b)
         (GenericSpace $generic)
         (HabitTargetResult $target)
         (EvaluatedPopulations $populations))
      $configuration)
   (let $refined
      (hs-refine-five-populations
         $populations $source-a $source-b $configuration)
      (HybridSearchMcBrideRefinementResult
         $status
         (Sources $source-a $source-b)
         (GenericSpace $generic)
         (HabitTargetResult $target)
         (RefinedPopulations $refined))))

;; Shared-population refinement. Sampling provenance is descriptive only; the
;; flattened population is refined as one stream and later mates globally.
(= (hs-refine-aggregated-population
      (AggregatedPopulationEvaluation
         $status $candidate-schema $initial-mean $habit-vector $sampler
         $provenance (Population $candidates))
      $source-a $source-b
      (McBrideRefinementConfiguration
         $eta $steps $threshold $patience $probability $seed))
   (let* (
      ($configuration
         (McBrideRefinementConfiguration
            $eta $steps $threshold $patience $probability $seed))
      ($initial-state (hs-lcg-normalize $seed))
      ((CandidateRefinementBatch $refined $final-state)
         (hs-refine-candidates
            $candidates $source-a $source-b
            $configuration $initial-state)))
      (AggregatedPopulationRefinement
         $status $candidate-schema $initial-mean $habit-vector $sampler
         $provenance
         (RefinementSummary
            (RefinedCount (hs-refinement-count $refined))
            (DecisionStreamFinalState $final-state))
         (Population $refined))))

;; --------------------------------------------------------------------------
;; Survivor promotion and delayed next-generation evaluation
;; --------------------------------------------------------------------------

(= (hs-promote-survivor
      (HybridCandidate
         (CandidateId $subproblem $individual $generation)
         (Vector $vector) (Blend $blend) $refinement-state
         $fitness $fitness-vector))
   (PromotedCandidate
      $subproblem $individual (+ $generation 1)
      (Vector $vector) (Blend $blend)))

(= (hs-promote-survivors ()) ())
(= (hs-promote-survivors (cons $candidate $remaining))
   (cons-atom
      (hs-promote-survivor $candidate)
      (hs-promote-survivors $remaining)))

(= (hs-evaluate-promoted-survivors () $context) ())
(= (hs-evaluate-promoted-survivors
      (cons $candidate $remaining) $context)
   (cons-atom
      (hs-evaluate-promoted-candidate $candidate $context)
      (hs-evaluate-promoted-survivors $remaining $context)))
