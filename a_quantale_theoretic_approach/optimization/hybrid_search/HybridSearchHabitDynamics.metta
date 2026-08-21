;; Habit formation and decay at the post-environmental-selection boundary.
;; CandidateEvaluation supplies candidate/property accessors. Evolution passes
;; the already-selected successful front. Runtime updates are pure.

!(import! &self ../../../habit_memory/habit_memory)
!(import! &self ../../../habit_memory/embeddings)
!(import! &self ../../../habit_memory/atomspace_memory)
!(import! &self "../../../habit_memory/persist_memory.py")

(= (hs-default-habit-evolution-configuration)
   (HabitEvolutionConfiguration 0.99))

;; --------------------------------------------------------------------------
;; Wrapper-preserving reinforcement and cumulative decay
;; --------------------------------------------------------------------------

(= (hs-reinforce-one-property-set (habit-memory $history) $properties)
   (reinforce-selected-blend (habit-memory $history) $properties))
(= (hs-reinforce-one-property-set
      (atomspace-habit-memory
         $memory $property-counts $pair-counts $total $index)
      $properties)
   (atomspace-habit-memory
      (hs-reinforce-one-property-set $memory $properties)
      $property-counts $pair-counts $total $index))
(= (hs-reinforce-one-property-set
      (decayed-habit-memory $factor $memory) $properties)
   (decayed-habit-memory $factor
      (hs-reinforce-one-property-set $memory $properties)))

(= (hs-reinforce-property-sets $memory ()) $memory)
(= (hs-reinforce-property-sets
      $memory (cons $properties $remaining))
   (hs-reinforce-property-sets
      (hs-reinforce-one-property-set $memory $properties)
      $remaining))

(= (hs-apply-cumulative-habit-decay
      (habit-memory $history) $gamma)
   (apply-habit-decay (habit-memory $history) $gamma))
(= (hs-apply-cumulative-habit-decay
      (atomspace-habit-memory
         $memory $property-counts $pair-counts $total $index)
      $gamma)
   (apply-habit-decay
      (atomspace-habit-memory
         $memory $property-counts $pair-counts $total $index)
      $gamma))
(= (hs-apply-cumulative-habit-decay
      (decayed-habit-memory $factor $memory) $gamma)
   (decayed-habit-memory (* $factor $gamma) $memory))

;; --------------------------------------------------------------------------
;; Successful Pareto candidates -> property co-occurrence observations
;; --------------------------------------------------------------------------

(= (hs-candidate-identities ()) ())
(= (hs-candidate-identities (cons $candidate $remaining))
   (cons-atom
      (hs-candidate-identity $candidate)
      (hs-candidate-identities $remaining)))

(= (hs-candidate-property-sets ()) ())
(= (hs-candidate-property-sets (cons $candidate $remaining))
   (cons-atom
      (hs-candidate-property-names (hs-candidate-blend $candidate))
      (hs-candidate-property-sets $remaining)))

(= (hs-update-habit-memory-from-successful
      $memory $successful (HabitEvolutionConfiguration $gamma))
   (let* (
      ($property-sets (hs-candidate-property-sets $successful))
      ($reinforced
         (hs-reinforce-property-sets $memory $property-sets))
      ($updated
         (hs-apply-cumulative-habit-decay $reinforced $gamma)))
      (HabitEvolutionResult
         $updated
         (HabitEvolutionTrace
            (DecayFactor $gamma)
            (SuccessfulCandidateIds
               (hs-candidate-identities $successful))
            (ReinforcedPropertySets $property-sets)))))

;; --------------------------------------------------------------------------
;; Recompute the context's habit strengths from evolved memory
;; --------------------------------------------------------------------------

(= (hs-refresh-habit-pair-strengths $memory ()) ())
(= (hs-refresh-habit-pair-strengths $memory
      (cons (HabitPairStrength $left $right $old-strength) $remaining))
   (cons-atom
      (HabitPairStrength $left $right
         (get-habit-strength $memory $left $right))
      (hs-refresh-habit-pair-strengths $memory $remaining)))

(= (hs-refresh-peircean-evidence $memory
      (PeirceanEvaluationEvidence
         $alpha (HabitPairStrengths $strengths) $break-evidence))
   (PeirceanEvaluationEvidence
      $alpha
      (HabitPairStrengths
         (hs-refresh-habit-pair-strengths $memory $strengths))
      $break-evidence))

(= (hs-refresh-evaluation-context-habits $memory
      (HybridEvaluationContext
         $source-a $source-b $coherence $optimality $peircean))
   (HybridEvaluationContext
      $source-a $source-b $coherence $optimality
      (hs-refresh-peircean-evidence $memory $peircean)))

;; --------------------------------------------------------------------------
;; Explicit durable persistence (never invoked by the pure search loop)
;; --------------------------------------------------------------------------

(= (hs-persist-property-sets! ()) ())
(= (hs-persist-property-sets! (cons $properties $remaining))
   (cons-atom
      (py-call (persist_memory.persist_blend $properties))
      (hs-persist-property-sets! $remaining)))

(= (hs-persist-final-pareto!
      (ParetoFront $successful))
   (let $property-sets (hs-candidate-property-sets $successful)
      (HabitPersistenceResult
         (PersistedCount (size-atom $property-sets))
         (PersistedBlends
            (hs-persist-property-sets! $property-sets)))))
