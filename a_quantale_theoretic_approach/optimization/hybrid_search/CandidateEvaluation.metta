;; PeTTa-first evaluation of the five-by-ten hybrid-search populations.
;;
;; Candidate records retain the raw evidence for each objective alongside the
;; scalar value consumed by later Pareto/CMA operations. Missing external
;; evidence is Blocked; it is never replaced by a passing score.

!(import! &self habit_memory/peircean_scoring)

;; --------------------------------------------------------------------------
;; Candidate and objective records
;; --------------------------------------------------------------------------

(= (hs-objective-status
      (CandidateObjective $name $status $score $evidence))
   $status)
(= (hs-objective-score
      (CandidateObjective $name $status $score $evidence))
   $score)

(= (hs-objectives-ready ()) True)
(= (hs-objectives-ready (cons $objective $remaining))
   (if (== (hs-objective-status $objective) Evaluated)
       (hs-objectives-ready $remaining)
       False))

(= (hs-objective-scores ()) ())
(= (hs-objective-scores (cons $objective $remaining))
   (cons-atom
      (hs-objective-score $objective)
      (hs-objective-scores $remaining)))

(= (hs-make-fitness-vector $objectives)
   (if (hs-objectives-ready $objectives)
       (FitnessVector Evaluated (hs-objective-scores $objectives))
       (FitnessVector Blocked ())))

(= (hs-candidate-status
      (HybridCandidate $identity $vector $blend
         (CandidateFitness $objectives) $fitness-vector))
   (if (hs-objectives-ready $objectives) Evaluated Blocked))

(= (hs-candidate-fitness
      (HybridCandidate $identity $vector $blend
         $fitness $fitness-vector))
   $fitness)

(= (hs-candidate-fitness-vector
      (HybridCandidate $identity $vector $blend
         $fitness $fitness-vector))
   $fitness-vector)

;; --------------------------------------------------------------------------
;; Shared context accessors
;; --------------------------------------------------------------------------

;; (HybridEvaluationContext
;;    SourceA SourceB
;;    (CoherenceConfiguration Alpha SemanticPairs)
;;    (CandidateOptimalityArtifacts Entries)
;;    (PeirceanEvaluationEvidence Alpha HabitPairStrengths BreakEntries))

(= (hs-context-source-a
      (HybridEvaluationContext $source-a $source-b $coherence $optimality $peircean))
   $source-a)
(= (hs-context-source-b
      (HybridEvaluationContext $source-a $source-b $coherence $optimality $peircean))
   $source-b)
(= (hs-context-coherence
      (HybridEvaluationContext $source-a $source-b $coherence $optimality $peircean))
   $coherence)
(= (hs-context-optimality
      (HybridEvaluationContext $source-a $source-b $coherence $optimality $peircean))
   $optimality)
(= (hs-context-peircean
      (HybridEvaluationContext $source-a $source-b $coherence $optimality $peircean))
   $peircean)

;; --------------------------------------------------------------------------
;; Candidate V-predicate projections
;; --------------------------------------------------------------------------

(= (hs-v-property-list
      (Concept $name $perspective (V-predicate (Property $properties))))
   $properties)
(= (hs-v-property-list
      (Concept $name (V-predicate (Property $properties))))
   $properties)

(= (hs-v-property-name ($name (WorldSpecSet $worlds) $degree)) $name)
(= (hs-v-property-degree ($name (WorldSpecSet $worlds) $degree)) $degree)
(= (hs-v-property-worlds ($name (WorldSpecSet $worlds) $degree)) $worlds)
(= (hs-q-degree (Q $worlds $degree)) $degree)

(= (hs-property-names ()) ())
(= (hs-property-names (cons $property $remaining))
   (cons-atom
      (hs-v-property-name $property)
      (hs-property-names $remaining)))

(= (hs-property-degrees ()) ())
(= (hs-property-degrees (cons $property $remaining))
   (cons-atom
      (hs-v-property-degree $property)
      (hs-property-degrees $remaining)))

(= (hs-candidate-property-names $candidate)
   (hs-property-names (hs-v-property-list $candidate)))

(= (hs-candidate-property-degrees $candidate)
   (hs-property-degrees (hs-v-property-list $candidate)))

;; --------------------------------------------------------------------------
;; Objective 1: quantale emergence
;; --------------------------------------------------------------------------

;; Deterministic local spelling of q-emergence's uniform-valuation path. This
;; is definitionally the same Product-quantale calculation as
;; mcbride_petta/emergence.metta, but avoids merging that module's transitive
;; helper rules with the enriched-optimality dependency graph.
(= (hs-list-member $item ()) False)
(= (hs-list-member $item (cons $head $tail))
   (if (== $item $head) True (hs-list-member $item $tail)))

(= (hs-list-difference () $remove) ())
(= (hs-list-difference (cons $head $tail) $remove)
   (let $rest (hs-list-difference $tail $remove)
      (if (hs-list-member $head $remove)
          $rest
          (cons-atom $head $rest))))

(= (hs-world-universe-from-properties ()) ())
(= (hs-world-universe-from-properties (cons $property $remaining))
   (unique-atom
      (union-atom
         (hs-v-property-worlds $property)
         (hs-world-universe-from-properties $remaining))))

(= (hs-maximum-degree ()) 0.0)
(= (hs-maximum-degree (cons $property $remaining))
   (max-atom
      ((hs-v-property-degree $property)
       (hs-maximum-degree $remaining))))

(= (hs-q-weakness $concept)
   (let $properties (hs-v-property-list $concept)
      (Q (hs-world-universe-from-properties $properties)
         (hs-maximum-degree $properties))))

(= (hs-q-tensor
      (Q $worlds-a $degree-a) (Q $worlds-b $degree-b))
   (Q (intersection-atom $worlds-a $worlds-b)
      (* $degree-a $degree-b)))

(= (hs-q-tv-residuation $left $right)
   (if (== $left 0.0)
       1.0
       (min-atom ((/ $right $left) 1.0))))

(= (hs-q-residuation
      (Q $worlds-a $degree-a) (Q $worlds-b $degree-b) $universe)
   (Q (unique-atom
         (union-atom
            $worlds-b (hs-list-difference $universe $worlds-a)))
      (hs-q-tv-residuation $degree-a $degree-b)))

(= (hs-q-emergence $source-a $source-b $blend)
   (let* (
      ($universe
         (hs-world-universe-from-properties
            (hs-v-property-list $blend)))
      ($weakness-a (hs-q-weakness $source-a))
      ($weakness-b (hs-q-weakness $source-b))
      ($weakness-blend (hs-q-weakness $blend))
      ($intensity-a
         (hs-q-residuation $weakness-a $weakness-blend $universe))
      ($intensity-b
         (hs-q-residuation $weakness-b $weakness-blend $universe))
      ($joint-weakness
         (hs-q-tensor $weakness-a $weakness-b))
      ($joint-intensity
         (hs-q-residuation $joint-weakness $weakness-blend $universe)))
      (hs-q-residuation
         (hs-q-tensor $intensity-a $intensity-b)
         $joint-intensity $universe)))

(= (hs-evaluate-emergence $source-a $source-b $candidate)
   (let $value (hs-q-emergence $source-a $source-b $candidate)
      (CandidateObjective
         Emergence Evaluated (hs-q-degree $value) $value)))

;; --------------------------------------------------------------------------
;; Objective 2: information-theoretic and semantic coherence
;; --------------------------------------------------------------------------

(= (hs-log2 $number) (log-math 2 $number))

(= (hs-entropy-term $probability)
   (if (<= $probability 0.0)
       0.0
       (* -1.0 (* $probability (hs-log2 $probability)))))

(= (hs-binary-entropy $probability)
   (if (or (<= $probability 0.0) (>= $probability 1.0))
       0.0
       (+ (hs-entropy-term $probability)
          (hs-entropy-term (- 1.0 $probability)))))

(= (hs-entropy-sum ()) 0.0)
(= (hs-entropy-sum (cons $probability $remaining))
   (+ (hs-binary-entropy $probability)
      (hs-entropy-sum $remaining)))

(= (hs-joint-entropy $left $right)
   (let* (
      ($p11 (min-atom ($left $right)))
      ($p10 (- $left $p11))
      ($p01 (- $right $p11))
      ($p00 (+ $p11 (- (- 1.0 $left) $right))))
      (+ (hs-entropy-term $p11)
         (+ (hs-entropy-term $p10)
            (+ (hs-entropy-term $p01)
               (hs-entropy-term $p00))))))

(= (hs-joint-summary-with $left ())
   (NumericSummary 0.0 0))
(= (hs-joint-summary-with $left (cons $right $remaining))
   (let* (
      ((NumericSummary $tail-sum $tail-count)
         (hs-joint-summary-with $left $remaining)))
      (NumericSummary
         (+ (hs-joint-entropy $left $right) $tail-sum)
         (+ 1 $tail-count))))

(= (hs-joint-summary ())
   (NumericSummary 0.0 0))
(= (hs-joint-summary (cons $head $tail))
   (let* (
      ((NumericSummary $head-sum $head-count)
         (hs-joint-summary-with $head $tail))
      ((NumericSummary $tail-sum $tail-count)
         (hs-joint-summary $tail)))
      (NumericSummary
         (+ $head-sum $tail-sum)
         (+ $head-count $tail-count))))

(= (hs-total-correlation $degrees)
   (let* (
      ($individual-sum (hs-entropy-sum $degrees))
      ((NumericSummary $joint-sum $pair-count)
         (hs-joint-summary $degrees)))
      (if (or (== $pair-count 0) (== $individual-sum 0.0))
          0.0
          (/ (- $individual-sum (/ $joint-sum $pair-count))
             $individual-sum))))

(= (hs-find-semantic-pair $left $right ())
   (SemanticLookup Missing $left $right))
(= (hs-find-semantic-pair $left $right
      (cons (SemanticPair $first $second $score) $remaining))
   (if (or (and (== $left $first) (== $right $second))
           (and (== $left $second) (== $right $first)))
       (SemanticLookup Found $score)
       (hs-find-semantic-pair $left $right $remaining)))

(= (hs-semantic-summary-with $name $degree () $semantic-pairs)
   (SemanticSummary Evaluated 0.0 0 ()))
(= (hs-semantic-summary-with
      $name $degree
      (cons ($next-name $next-degree) $remaining)
      $semantic-pairs)
   (let $tail-summary
      (hs-semantic-summary-with
         $name $degree $remaining $semantic-pairs)
      (if (== (index-atom $tail-summary 1) Blocked)
          $tail-summary
          (if (and (>= $degree 0.5) (>= $next-degree 0.5))
              (let $lookup
                 (hs-find-semantic-pair
                    $name $next-name $semantic-pairs)
                 (if (== (index-atom $lookup 1) Missing)
                     (SemanticSummary Blocked 0.0 0
                        (MissingSemanticPair $name $next-name))
                     (SemanticSummary Evaluated
                        (+ (* (/ (+ $degree $next-degree) 2.0)
                              (index-atom $lookup 2))
                           (index-atom $tail-summary 2))
                        (+ 1 (index-atom $tail-summary 3))
                        ())))
              $tail-summary))))

(= (hs-semantic-summary () $semantic-pairs)
   (SemanticSummary Evaluated 0.0 0 ()))
(= (hs-semantic-summary
      (cons ($name $degree) $remaining) $semantic-pairs)
   (let* (
      ($head-summary
         (hs-semantic-summary-with
            $name $degree $remaining $semantic-pairs))
      ($tail-summary
         (hs-semantic-summary $remaining $semantic-pairs)))
      (if (== (index-atom $head-summary 1) Blocked)
          $head-summary
          (if (== (index-atom $tail-summary 1) Blocked)
              $tail-summary
              (SemanticSummary Evaluated
                 (+ (index-atom $head-summary 2)
                    (index-atom $tail-summary 2))
                 (+ (index-atom $head-summary 3)
                    (index-atom $tail-summary 3))
                 ())))))

(= (hs-zip-properties () ()) ())
(= (hs-zip-properties
      (cons $name $remaining-names)
      (cons $degree $remaining-degrees))
   (cons-atom
      ($name $degree)
      (hs-zip-properties $remaining-names $remaining-degrees)))

(= (hs-clamp-unit $score)
   (if (< $score 0.0)
       0.0
       (if (> $score 1.0) 1.0 $score)))

(= (hs-evaluate-coherence
      $candidate
      (CoherenceConfiguration $alpha (SemanticCoherenceEvidence $semantic-pairs)))
   (let* (
      ($names (hs-candidate-property-names $candidate))
      ($degrees (hs-candidate-property-degrees $candidate))
      ($pairs (hs-zip-properties $names $degrees))
      ($total-correlation (hs-total-correlation $degrees))
      ($semantic-summary
         (hs-semantic-summary $pairs $semantic-pairs)))
      (if (== (index-atom $semantic-summary 1) Blocked)
          (CandidateObjective Coherence Blocked 0.0
             (index-atom $semantic-summary 4))
          (let* (
             ($semantic-count (index-atom $semantic-summary 3))
             ($semantic-score
                (if (== $semantic-count 0)
                    0.0
                    (/ (index-atom $semantic-summary 2)
                       $semantic-count)))
             ($raw-score
                (+ (* $alpha $total-correlation)
                   (* (- 1.0 $alpha) $semantic-score))))
             (CandidateObjective Coherence Evaluated
                (hs-clamp-unit $raw-score)
                (CoherenceEvidence
                   (TotalCorrelation $total-correlation)
                   (SemanticCoherence $semantic-score)
                   (Alpha $alpha)
                   (RawScore $raw-score)))))))

;; --------------------------------------------------------------------------
;; Objective 3: unified enriched optimality
;; --------------------------------------------------------------------------

(= (hs-find-optimality-entry $subproblem $individual ()) ())
(= (hs-find-optimality-entry $subproblem $individual
      (cons $entry $remaining))
   (if (and (== $subproblem (index-atom $entry 1))
            (== $individual (index-atom $entry 2)))
       $entry
       (hs-find-optimality-entry
          $subproblem $individual $remaining)))

(= (hs-optimality-objective-from-result
      (VOptimalityResult Evaluated $constraints $value))
   (CandidateObjective UnifiedOptimality Evaluated
      (hs-q-degree $value)
      (VOptimalityResult Evaluated $constraints $value)))
(= (hs-optimality-objective-from-result
      (VOptimalityResult Blocked $constraints $value))
   (CandidateObjective UnifiedOptimality Blocked 0.0
      (VOptimalityResult Blocked $constraints $value)))
(= (hs-optimality-objective-from-result
      (VOptimalityResult Pending $constraints $value))
   (CandidateObjective UnifiedOptimality Blocked 0.0
      (VOptimalityResult Pending $constraints $value)))

(= (hs-evaluate-optimality-entry
      $candidate
      (CandidateOptimalityInput
         $subproblem $individual $input-candidate $inputs))
   (CandidateObjective UnifiedOptimality Blocked 0.0
      (UnmaterializedCandidateOptimalityInput
         $subproblem $individual)))
(= (hs-evaluate-optimality-entry
      $candidate
      (CandidateOptimalityResult
         $subproblem $individual $result-candidate $result))
   (if (== $candidate $result-candidate)
       (hs-optimality-objective-from-result $result)
       (CandidateObjective UnifiedOptimality Blocked 0.0
          (CandidateOptimalityMismatch $subproblem $individual))))
(= (hs-evaluate-optimality-entry $candidate ())
   (CandidateObjective UnifiedOptimality Blocked 0.0
      MissingCandidateOptimalityArtifacts))

(= (hs-evaluate-unified-optimality
      $subproblem $individual $candidate
      (CandidateOptimalityArtifacts $entries))
   (hs-evaluate-optimality-entry
      $candidate
      (hs-find-optimality-entry
         $subproblem $individual $entries)))

;; --------------------------------------------------------------------------
;; Objective 4: Peircean blend quality
;; --------------------------------------------------------------------------

(= (hs-find-habit-pair $left $right ())
   (HabitPairLookup Missing $left $right))
(= (hs-find-habit-pair $left $right
      (cons (HabitPairStrength $first $second $strength) $remaining))
   (if (or (and (== $left $first) (== $right $second))
           (and (== $left $second) (== $right $first)))
       (HabitPairLookup Found $strength)
       (hs-find-habit-pair $left $right $remaining)))

(= (hs-habit-bonus-with $name () $strengths)
   (PeirceanSummary Evaluated 0.0 ()))
(= (hs-habit-bonus-with
      $name (cons $next $remaining) $strengths)
   (let* (
      ($lookup (hs-find-habit-pair $name $next $strengths))
      ($tail (hs-habit-bonus-with $name $remaining $strengths)))
      (if (== (index-atom $lookup 1) Missing)
          (PeirceanSummary Blocked 0.0
             (MissingHabitPairStrength $name $next))
          (if (== (index-atom $tail 1) Blocked)
              $tail
              (PeirceanSummary Evaluated
                 (+ (index-atom $lookup 2)
                    (index-atom $tail 2))
                 ())))))

(= (hs-habit-bonus-from-strengths () $strengths)
   (PeirceanSummary Evaluated 0.0 ()))
(= (hs-habit-bonus-from-strengths
      (cons $name $remaining) $strengths)
   (let* (
      ($head (hs-habit-bonus-with $name $remaining $strengths))
      ($tail (hs-habit-bonus-from-strengths $remaining $strengths)))
      (if (== (index-atom $head 1) Blocked)
          $head
          (if (== (index-atom $tail 1) Blocked)
              $tail
              (PeirceanSummary Evaluated
                 (+ (index-atom $head 2)
                    (index-atom $tail 2))
                 ())))))

(= (hs-habit-break-from-strengths () $strengths)
   (PeirceanSummary Evaluated 0.0 ()))
(= (hs-habit-break-from-strengths
      (cons ($left $right $pair-emergence) $remaining) $strengths)
   (let* (
      ($lookup (hs-find-habit-pair $left $right $strengths))
      ($tail (hs-habit-break-from-strengths $remaining $strengths)))
      (if (== (index-atom $lookup 1) Missing)
          (PeirceanSummary Blocked 0.0
             (MissingHabitPairStrength $left $right))
          (if (== (index-atom $tail 1) Blocked)
              $tail
              (PeirceanSummary Evaluated
                 (+ (* (- 1.0 (index-atom $lookup 2))
                       $pair-emergence)
                    (index-atom $tail 2))
                 ())))))

(= (hs-find-break-entry $subproblem $individual ()) ())
(= (hs-find-break-entry $subproblem $individual
      (cons (CandidateHabitBreakPairs $entry-subproblem $entry-individual $pairs)
            $remaining))
   (if (and (== $subproblem $entry-subproblem)
            (== $individual $entry-individual))
       (CandidateHabitBreakPairs
          $entry-subproblem $entry-individual $pairs)
       (hs-find-break-entry
          $subproblem $individual $remaining)))

(= (hs-evaluate-peircean-entry
      $candidate $emergence-score $alpha $strengths
      (CandidateHabitBreakPairs $subproblem $individual $break-pairs))
   (let* (
      ($names (hs-candidate-property-names $candidate))
      ($habit-bonus
         (hs-habit-bonus-from-strengths $names $strengths))
      ($habit-break
         (hs-habit-break-from-strengths $break-pairs $strengths)))
      (if (== (index-atom $habit-bonus 1) Blocked)
          (CandidateObjective PeirceanQuality Blocked 0.0
             (index-atom $habit-bonus 3))
          (if (== (index-atom $habit-break 1) Blocked)
              (CandidateObjective PeirceanQuality Blocked 0.0
                 (index-atom $habit-break 3))
              (let* (
                 ($bonus-score (index-atom $habit-bonus 2))
                 ($break-score (index-atom $habit-break 2))
                 ($quality
                    (peircean-blend-quality
                       $alpha $bonus-score $break-score
                       $emergence-score)))
                 (CandidateObjective PeirceanQuality Evaluated $quality
                    (PeirceanEvidence
                       (Alpha $alpha)
                       (HabitBonus $bonus-score)
                       (HabitBreak $break-score)
                       (Synergy $emergence-score))))))))

(= (hs-evaluate-peircean-entry
      $candidate $emergence-score $alpha $strengths ())
   (CandidateObjective PeirceanQuality Blocked 0.0
      MissingCandidateHabitBreakEvidence))

(= (hs-evaluate-peircean
      $subproblem $individual $candidate $emergence-score
      (PeirceanEvaluationEvidence
         $alpha (HabitPairStrengths $strengths)
         (HabitBreakEvidence $break-entries)))
   (hs-evaluate-peircean-entry
      $candidate $emergence-score $alpha $strengths
      (hs-find-break-entry
         $subproblem $individual $break-entries)))

;; --------------------------------------------------------------------------
;; Candidate and population traversal
;; --------------------------------------------------------------------------

(= (hs-evaluate-candidate
      (SampledCandidate
         $subproblem $individual (Vector $vector) $candidate)
      $context)
   (let* (
      ($emergence
         (hs-evaluate-emergence
            (hs-context-source-a $context)
            (hs-context-source-b $context)
            $candidate))
      ($coherence
         (hs-evaluate-coherence
            $candidate (hs-context-coherence $context)))
      ($optimality
         (hs-evaluate-unified-optimality
            $subproblem $individual $candidate
            (hs-context-optimality $context)))
      ($peircean
         (hs-evaluate-peircean
            $subproblem $individual $candidate
            (hs-objective-score $emergence)
            (hs-context-peircean $context)))
      ($objectives ($emergence $coherence $optimality $peircean)))
      (HybridCandidate
         (CandidateId $subproblem $individual 0)
         (Vector $vector)
         (Blend $candidate)
         (CandidateFitness $objectives)
         (hs-make-fitness-vector $objectives))))

(= (hs-evaluate-candidates () $context) ())
(= (hs-evaluate-candidates (cons $candidate $remaining) $context)
   (cons-atom
      (hs-evaluate-candidate $candidate $context)
      (hs-evaluate-candidates $remaining $context)))

(= (hs-evaluate-subproblem $subproblem $context)
   (let* (
      ($index (index-atom $subproblem 1))
      ($habit-bias (index-atom $subproblem 2))
      ($mean (index-atom $subproblem 3))
      ($covariance (index-atom $subproblem 4))
      ($step-size (index-atom $subproblem 5))
      ($population (index-atom $subproblem 6))
      ($candidates (cdr-atom $population))
      ($evaluated (hs-evaluate-candidates $candidates $context)))
      (EvaluatedSubproblemPopulation
         $index $habit-bias $mean $covariance $step-size
         (Population $evaluated))))

(= (hs-evaluate-subproblems () $context) ())
(= (hs-evaluate-subproblems (cons $subproblem $remaining) $context)
   (cons-atom
      (hs-evaluate-subproblem $subproblem $context)
      (hs-evaluate-subproblems $remaining $context)))

(= (hs-evaluated-candidates-ready ()) True)
(= (hs-evaluated-candidates-ready (cons $candidate $remaining))
   (if (== (hs-candidate-status $candidate) Evaluated)
       (hs-evaluated-candidates-ready $remaining)
       False))

(= (hs-evaluated-subproblems-ready ()) True)
(= (hs-evaluated-subproblems-ready (cons $subproblem $remaining))
   (let $population (index-atom $subproblem 6)
      (if (hs-evaluated-candidates-ready (index-atom $population 1))
          (hs-evaluated-subproblems-ready $remaining)
          False)))

(= (hs-evaluate-five-populations $initialization $context)
   (let* (
      ($candidate-schema (index-atom $initialization 2))
      ($initial-mean (index-atom $initialization 3))
      ($habit-vector (index-atom $initialization 4))
      ($sampler (index-atom $initialization 5))
      ($subproblem-block (index-atom $initialization 6))
      ($subproblems (cdr-atom $subproblem-block))
      ($evaluated
         (hs-evaluate-subproblems $subproblems $context))
      ($status
         (if (hs-evaluated-subproblems-ready $evaluated)
             Evaluated Blocked)))
      (HabitBiasedPopulationEvaluation
         $status $candidate-schema $initial-mean $habit-vector $sampler
         (Subproblems $evaluated))))

(= (hs-evaluate-initialization-result
      (HybridSearchInitializationResult
         Ready (Sources $source-a $source-b)
         (GenericSpace $generic)
         (HabitTargetResult $target)
         (Populations $populations))
      $context)
   (if (and (== $source-a (hs-context-source-a $context))
            (== $source-b (hs-context-source-b $context)))
       (let $evaluated
          (hs-evaluate-five-populations $populations $context)
          (HybridSearchCandidateEvaluationResult
             (index-atom $evaluated 1)
             (Sources $source-a $source-b)
             (GenericSpace $generic)
             (HabitTargetResult $target)
             (EvaluatedPopulations $evaluated)))
       (HybridSearchCandidateEvaluationResult Blocked
          (EvaluationContextSourceMismatch)
          (Sources $source-a $source-b))))
