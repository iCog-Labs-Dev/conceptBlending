;; Global NSGA-II-style evolution for the aggregated hybrid-search population.
;; CandidateEvaluation and HybridSearchMcBrideRefinement must be imported first.
;; All four objectives are maximized. Sampling origin is retained only in each
;; CandidateId and in SamplingProvenance; it never partitions mating/selection.

;; --------------------------------------------------------------------------
;; List and fitness helpers
;; --------------------------------------------------------------------------

(= (hs-evolution-append () $right) $right)
(= (hs-evolution-append (cons $head $tail) $right)
   (cons-atom $head (hs-evolution-append $tail $right)))

(= (hs-evolution-length ()) 0)
(= (hs-evolution-length (cons $head $tail))
   (+ 1 (hs-evolution-length $tail)))

(= (hs-evolution-take $count ()) ())
(= (hs-evolution-take $count (cons $head $tail))
   (if (<= $count 0)
       ()
       (cons-atom $head (hs-evolution-take (- $count 1) $tail))))

(= (hs-evolution-at 0 (cons $head $tail)) $head)
(= (hs-evolution-at $index (cons $head $tail))
   (hs-evolution-at (- $index 1) $tail))

(= (hs-evaluated-only ()) ())
(= (hs-evaluated-only (cons $candidate $remaining))
   (let $tail (hs-evaluated-only $remaining)
      (if (== (hs-candidate-status $candidate) Evaluated)
          (cons-atom $candidate $tail)
          $tail)))

(= (hs-fitness-values
      (FitnessVector Evaluated $values)) $values)
(= (hs-candidate-fitness-values $candidate)
   (hs-fitness-values (hs-candidate-fitness-vector $candidate)))

(= (hs-all-ge-and-one-gt () () $strict) $strict)
(= (hs-all-ge-and-one-gt
      (cons $left $left-tail) (cons $right $right-tail) $strict)
   (if (< $left $right)
       False
       (hs-all-ge-and-one-gt
          $left-tail $right-tail
          (or $strict (> $left $right)))))

(= (hs-dominates $left $right)
   (hs-all-ge-and-one-gt
      (hs-candidate-fitness-values $left)
      (hs-candidate-fitness-values $right)
      False))

(= (hs-dominated-by-any $candidate ()) False)
(= (hs-dominated-by-any $candidate (cons $other $remaining))
   (if (and (not (== (hs-candidate-identity $candidate)
                      (hs-candidate-identity $other)))
            (hs-dominates $other $candidate))
       True
       (hs-dominated-by-any $candidate $remaining)))

(= (hs-nondominated-from () $population) ())
(= (hs-nondominated-from (cons $candidate $remaining) $population)
   (let $tail (hs-nondominated-from $remaining $population)
      (if (hs-dominated-by-any $candidate $population)
          $tail
          (cons-atom $candidate $tail))))

(= (hs-remove-candidates () $remove) ())
(= (hs-remove-candidates (cons $candidate $remaining) $remove)
   (let $tail (hs-remove-candidates $remaining $remove)
      (if (hs-list-member $candidate $remove)
          $tail
          (cons-atom $candidate $tail))))

(= (hs-pareto-fronts-from ()) ())
(= (hs-pareto-fronts-from (cons $head $tail))
   (let* (
      ($population (cons-atom $head $tail))
      ($front (hs-nondominated-from $population $population))
      ($remaining (hs-remove-candidates $population $front)))
      (cons-atom (ParetoFront $front)
         (hs-pareto-fronts-from $remaining))))

(= (hs-pareto-fronts $population)
   (hs-pareto-fronts-from (hs-evaluated-only $population)))

(= (hs-global-pareto-front $population)
   (let $evaluated (hs-evaluated-only $population)
      (ParetoFront (hs-nondominated-from $evaluated $evaluated))))

;; --------------------------------------------------------------------------
;; Rank and crowding distance
;; --------------------------------------------------------------------------

(= (hs-front-candidates (ParetoFront $candidates)) $candidates)

(= (hs-rank-in-fronts $candidate () $rank) 1000000)
(= (hs-rank-in-fronts $candidate (cons $front $remaining) $rank)
   (if (hs-list-member $candidate (hs-front-candidates $front))
       $rank
       (hs-rank-in-fronts $candidate $remaining (+ $rank 1))))

(= (hs-rank $candidate $fronts)
   (hs-rank-in-fronts $candidate $fronts 0))

(= (hs-score-at 0 (cons $score $remaining)) $score)
(= (hs-score-at $index (cons $score $remaining))
   (hs-score-at (- $index 1) $remaining))
(= (hs-candidate-score-at $candidate $index)
   (hs-score-at $index (hs-candidate-fitness-values $candidate)))

;; A scan records the objective extrema and the nearest lower/upper neighbor.
(= (hs-crowding-scan $candidate $objective ()
      $minimum $maximum $lower-found $lower $upper-found $upper)
   (CrowdingScan
      $minimum $maximum $lower-found $lower $upper-found $upper))
(= (hs-crowding-scan $candidate $objective
      (cons $other $remaining)
      $minimum $maximum $lower-found $lower $upper-found $upper)
   (let* (
      ($value (hs-candidate-score-at $candidate $objective))
      ($other-value (hs-candidate-score-at $other $objective))
      ($next-minimum (min-atom ($minimum $other-value)))
      ($next-maximum (max-atom ($maximum $other-value)))
      ($next-lower-found
         (or $lower-found (< $other-value $value)))
      ($next-lower
         (if (< $other-value $value)
             (if $lower-found (max-atom ($lower $other-value)) $other-value)
             $lower))
      ($next-upper-found
         (or $upper-found (> $other-value $value)))
      ($next-upper
         (if (> $other-value $value)
             (if $upper-found (min-atom ($upper $other-value)) $other-value)
             $upper)))
      (hs-crowding-scan $candidate $objective $remaining
         $next-minimum $next-maximum
         $next-lower-found $next-lower
         $next-upper-found $next-upper)))

(= (hs-objective-crowding $candidate $front $objective)
   (let* (
      ($value (hs-candidate-score-at $candidate $objective))
      ((CrowdingScan $minimum $maximum
          $lower-found $lower $upper-found $upper)
         (hs-crowding-scan $candidate $objective $front
            $value $value False $value False $value)))
      (if (or (not $lower-found) (not $upper-found))
          1000000000.0
          (if (== $maximum $minimum)
              0.0
              (/ (- $upper $lower) (- $maximum $minimum))))))

(= (hs-crowding-distance-from $candidate $front $objective)
   (if (>= $objective 4)
       0.0
       (let $distance (hs-objective-crowding $candidate $front $objective)
          (if (>= $distance 1000000000.0)
              1000000000.0
              (+ $distance
                 (hs-crowding-distance-from
                    $candidate $front (+ $objective 1)))))))

(= (hs-crowding-distance $candidate $front)
   (hs-crowding-distance-from $candidate $front 0))

(= (hs-find-containing-front $candidate (cons $front $remaining))
   (if (hs-list-member $candidate (hs-front-candidates $front))
       (hs-front-candidates $front)
       (hs-find-containing-front $candidate $remaining)))

(= (hs-preferred-candidate $left $right $fronts)
   (let* (
      ($left-rank (hs-rank $left $fronts))
      ($right-rank (hs-rank $right $fronts)))
      (if (< $left-rank $right-rank)
          $left
          (if (> $left-rank $right-rank)
              $right
              (let* (
                 ($front (hs-find-containing-front $left $fronts))
                 ($left-distance
                    (hs-crowding-distance $left $front))
                 ($right-distance
                    (hs-crowding-distance $right $front)))
                 (if (>= $left-distance $right-distance)
                     $left $right))))))

;; --------------------------------------------------------------------------
;; Deterministic binary tournament
;; --------------------------------------------------------------------------

(= (hs-random-index $state $count)
   (trunc-math (* (hs-lcg-draw $state) $count)))

(= (hs-binary-tournament $population $fronts $state)
   (let* (
      ($count (hs-evolution-length $population))
      ($state-a (hs-lcg-next $state))
      ($state-b (hs-lcg-next $state-a))
      ($left (hs-evolution-at (hs-random-index $state-a $count) $population))
      ($right (hs-evolution-at (hs-random-index $state-b $count) $population))
      ($winner (hs-preferred-candidate $left $right $fronts)))
      (TournamentDraw $winner $state-b
         (Competitors (hs-candidate-identity $left)
                      (hs-candidate-identity $right)))))

;; --------------------------------------------------------------------------
;; Uniform crossover and bounded mutation
;; --------------------------------------------------------------------------

(= (hs-remake-property ($name (WorldSpecSet $worlds) $old-degree) $degree)
   ($name (WorldSpecSet $worlds) $degree))

(= (hs-crossover-properties () () $state) (VariationBatch () $state))
(= (hs-crossover-properties
      (cons $left $left-tail) (cons $right $right-tail) $state)
   (let* (
      ($next-state (hs-lcg-next $state))
      ($selected (if (< (hs-lcg-draw $next-state) 0.5) $left $right))
      ((VariationBatch $tail $final-state)
         (hs-crossover-properties $left-tail $right-tail $next-state)))
      (VariationBatch (cons-atom $selected $tail) $final-state)))

(= (hs-mutate-properties () $rate $scale $state)
   (VariationBatch () $state))
(= (hs-mutate-properties
      (cons $property $remaining) $rate $scale $state)
   (let* (
      ($decision-state (hs-lcg-next $state))
      ($noise-state (hs-lcg-next $decision-state))
      ($degree (hs-v-property-degree $property))
      ($noise (* $scale (- (* 2.0 (hs-lcg-draw $noise-state)) 1.0)))
      ($mutated-degree
         (if (< (hs-lcg-draw $decision-state) $rate)
             (max-atom (0.01 (min-atom (0.99 (+ $degree $noise)))))
             $degree))
      ($mutated (hs-remake-property $property $mutated-degree))
      ((VariationBatch $tail $final-state)
         (hs-mutate-properties $remaining $rate $scale $noise-state)))
      (VariationBatch (cons-atom $mutated $tail) $final-state)))

(= (hs-remake-concept
      (Concept $name $perspective (V-predicate (Property $old))) $properties)
   (Concept $name $perspective (V-predicate (Property $properties))))
(= (hs-remake-concept
      (Concept $name (V-predicate (Property $old))) $properties)
   (Concept $name (V-predicate (Property $properties))))

(= (hs-vary-parent-pair
      $left $right $child-index $generation
      $crossover-rate $mutation-rate $mutation-scale $state)
   (let* (
      ($crossover-state (hs-lcg-next $state))
      ($left-blend (hs-candidate-blend $left))
      ($right-blend (hs-candidate-blend $right))
      ($left-properties (hs-v-property-list $left-blend))
      ($right-properties (hs-v-property-list $right-blend))
      ((VariationBatch $crossed $after-crossover)
         (if (< (hs-lcg-draw $crossover-state) $crossover-rate)
             (hs-crossover-properties
                $left-properties $right-properties $crossover-state)
             (VariationBatch $left-properties $crossover-state)))
      ((VariationBatch $mutated $final-state)
         (hs-mutate-properties
            $crossed $mutation-rate $mutation-scale $after-crossover))
      ($blend (hs-remake-concept $left-blend $mutated)))
      (OffspringVariation
         (OffspringCandidate
            (CandidateId Aggregate $child-index $generation)
            (Parents (hs-candidate-identity $left)
                     (hs-candidate-identity $right))
            (Vector (hs-property-degrees $mutated))
            (Blend $blend)
            (VariationTrace
               (CrossoverRate $crossover-rate)
               (MutationRate $mutation-rate)
               (MutationScale $mutation-scale)))
         $final-state)))

(= (hs-produce-offspring-from $count $population $fronts $generation
      $crossover-rate $mutation-rate $mutation-scale $state $child-index)
   (if (<= $count 0)
       (OffspringBatch () $state)
       (let* (
          ((TournamentDraw $left $state-a $trace-a)
             (hs-binary-tournament $population $fronts $state))
          ((TournamentDraw $right $state-b $trace-b)
             (hs-binary-tournament $population $fronts $state-a))
          ((OffspringVariation $child $state-c)
             (hs-vary-parent-pair
                $left $right $child-index $generation
                $crossover-rate $mutation-rate $mutation-scale $state-b))
          ((OffspringBatch $tail $final-state)
             (hs-produce-offspring-from
                (- $count 1) $population $fronts $generation
                $crossover-rate $mutation-rate $mutation-scale
                $state-c (+ $child-index 1))))
          (OffspringBatch (cons-atom $child $tail) $final-state))))

(= (hs-produce-offspring $population $generation $count
      $crossover-rate $mutation-rate $mutation-scale $seed)
   (hs-produce-offspring-from
      $count $population (hs-pareto-fronts $population) $generation
      $crossover-rate $mutation-rate $mutation-scale
      (hs-lcg-normalize $seed) 0))

;; --------------------------------------------------------------------------
;; Environmental selection
;; --------------------------------------------------------------------------

(= (hs-insert-by-crowding $candidate () $front)
   ($candidate))
(= (hs-insert-by-crowding $candidate (cons $head $tail) $front)
   (if (>= (hs-crowding-distance $candidate $front)
           (hs-crowding-distance $head $front))
       (cons-atom $candidate (cons-atom $head $tail))
       (cons-atom $head (hs-insert-by-crowding $candidate $tail $front))))

(= (hs-sort-by-crowding () $front) ())
(= (hs-sort-by-crowding (cons $head $tail) $front)
   (hs-insert-by-crowding
      $head (hs-sort-by-crowding $tail $front) $front))

(= (hs-fill-fronts () $capacity $selected) $selected)
(= (hs-fill-fronts (cons (ParetoFront $front) $remaining)
      $capacity $selected)
   (let* (
      ($used (hs-evolution-length $selected))
      ($available (- $capacity $used))
      ($front-count (hs-evolution-length $front)))
      (if (<= $available 0)
          $selected
          (if (<= $front-count $available)
              (hs-fill-fronts $remaining $capacity
                 (hs-evolution-append $selected $front))
              (hs-evolution-append $selected
                 (hs-evolution-take $available
                    (hs-sort-by-crowding $front $front)))))))

(= (hs-environmental-select $parents $offspring $capacity)
   (let* (
      ($combined (hs-evolution-append $parents $offspring))
      ($eligible (hs-evaluated-only $combined))
      ($fronts (hs-pareto-fronts-from $eligible))
      ($survivors (hs-fill-fronts $fronts $capacity ())))
      (EnvironmentalSelection
         (Capacity $capacity)
         (EligibleCount (hs-evolution-length $eligible))
         (Population $survivors)
         (ParetoFronts $fronts))))

;; One complete generation. Current parent fitness remains frozen through
;; tournament and environmental selection. Only offspring are freshly scored.
(= (hs-evolve-aggregated-generation
      (AggregatedPopulationRefinement
         $status $candidate-schema $initial-mean $habit-vector $sampler
         $provenance $refinement-summary (Population $parents))
      $generation $offspring-context $next-generation-context
      (HybridEvolutionConfiguration
         $capacity $offspring-count $crossover-rate
         $mutation-rate $mutation-scale $seed))
   (let* (
      ((OffspringBatch $drafts $final-state)
         (hs-produce-offspring
            $parents $generation $offspring-count
            $crossover-rate $mutation-rate $mutation-scale $seed))
      ($offspring
         (hs-evaluate-offspring-candidates $drafts $offspring-context))
      ($selection (hs-environmental-select $parents $offspring $capacity))
      ($survivors (index-atom (index-atom $selection 3) 1))
      ($promoted (hs-promote-survivors $survivors))
      ($next-population
         (hs-evaluate-promoted-survivors
            $promoted $next-generation-context)))
      (HybridGenerationResult
         (Generation $generation)
         (RandomFinalState $final-state)
         (OffspringDrafts $drafts)
         (EvaluatedOffspring $offspring)
         $selection
         (NextGenerationPopulation $next-population))))

(= (hs-final-pareto-from-generation
      (HybridGenerationResult
         $generation $random $drafts $offspring
         (EnvironmentalSelection
            $capacity $eligible (Population $survivors) $fronts)
         $next-generation))
   (HybridSearchParetoResult
      Global (PopulationSize (hs-evolution-length $survivors))
      (hs-global-pareto-front $survivors)))

;; --------------------------------------------------------------------------
;; Recursive generation loop and one global final Pareto front
;; --------------------------------------------------------------------------

(= (hs-reseed-refinement-configuration
      (McBrideRefinementConfiguration
         $eta $steps $threshold $patience $probability $seed)
      $generation)
   (McBrideRefinementConfiguration
      $eta $steps $threshold $patience $probability
      (+ $seed $generation)))

(= (hs-reseed-evolution-configuration
      (HybridEvolutionConfiguration
         $capacity $offspring-count $crossover-rate
         $mutation-rate $mutation-scale $seed)
      $generation)
   (HybridEvolutionConfiguration
      $capacity $offspring-count $crossover-rate
      $mutation-rate $mutation-scale (+ $seed $generation)))

(= (hs-next-aggregated-evaluation
      (AggregatedPopulationEvaluation
         $old-status $candidate-schema $initial-mean $habit-vector $sampler
         $provenance $old-population)
      $next-population)
   (AggregatedPopulationEvaluation
      (if (hs-evaluated-candidates-ready $next-population)
          Evaluated Blocked)
      $candidate-schema $initial-mean $habit-vector $sampler
      $provenance (Population $next-population)))

(= (hs-run-hybrid-generations
      $remaining $generation $evaluation $source-a $source-b
      $refinement-configuration $evolution-configuration
      $generation-contexts $history)
   (if (<= $remaining 0)
       (let* (
          ($population
             (index-atom (index-atom $evaluation 7) 1))
          ($pareto (hs-global-pareto-front $population)))
          (HybridSearchLoopResult Complete
             (Generations $history)
             (FinalPopulation $population)
             (GlobalParetoFront $pareto)))
       (let* (
          ($contexts (car-atom $generation-contexts))
          ($rest-contexts (cdr-atom $generation-contexts))
          ($offspring-context (index-atom $contexts 2))
          ($next-context (index-atom $contexts 3))
          ($refinement-config
             (hs-reseed-refinement-configuration
                $refinement-configuration $generation))
          ($evolution-config
             (hs-reseed-evolution-configuration
                $evolution-configuration $generation))
          ($refined
             (hs-refine-aggregated-population
                $evaluation $source-a $source-b $refinement-config))
          ($generation-result
             (hs-evolve-aggregated-generation
                $refined (+ $generation 1)
                $offspring-context $next-context $evolution-config))
          ($next-population
             (index-atom (index-atom $generation-result 6) 1))
          ($next-evaluation
             (hs-next-aggregated-evaluation
                $evaluation $next-population)))
          (hs-run-hybrid-generations
             (- $remaining 1) (+ $generation 1)
             $next-evaluation $source-a $source-b
             $refinement-configuration $evolution-configuration
             $rest-contexts
             (hs-evolution-append $history ($generation-result))))))

;; Each GenerationContexts atom supplies evidence for newly-created offspring
;; and for survivors after their promotion. This keeps missing external
;; evidence explicit instead of inventing objective scores inside the loop.
(= (run-hybrid-search-loop
      $initialization $initial-evaluation-context
      $refinement-configuration $evolution-configuration
      $generation-contexts)
   (let* (
      ($evaluation-result
         (hs-evaluate-initialization-result
            $initialization $initial-evaluation-context))
      ($sources (index-atom $evaluation-result 2))
      ($source-a (index-atom $sources 1))
      ($source-b (index-atom $sources 2))
      ($evaluation
         (index-atom (index-atom $evaluation-result 5) 1)))
      (hs-run-hybrid-generations
         (hs-evolution-length $generation-contexts) 0
         $evaluation $source-a $source-b
         $refinement-configuration $evolution-configuration
         $generation-contexts ())))
