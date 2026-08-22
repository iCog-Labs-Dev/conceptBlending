;; Validation of post-selection habit formation, decay, and context refresh.

!(import! &self ../../../../PeTTa/lib/lib_import)
!(import! &self "../../../../habit_memory/real_embeddings.py")
!(import! &self ../../../../habit_memory/embeddings)
!(import! &self ../../../../habit_memory/habit_memory)
!(import! &self ../../../../habit_memory/atomspace_memory)
!(import! &self ../candidate-evaluation)
!(import! &self ../hybrid-search-mcbride-refinement)
!(import! &self ../hybrid-search-habit-dynamics)
!(import! &self ../hybrid-search-evolution)

(= (habit-test-candidate $name $individual $left $right $e $c $o $p)
   (HybridCandidate
      (CandidateId $name $individual 0)
      (Vector (0.8 0.7))
      (Blend
         (Concept $name functional_use
            (V-predicate
               (Property
                  (($left (WorldSpecSet (world)) 0.8)
                   ($right (WorldSpecSet (world)) 0.7))))))
      (RefinementState Unrefined)
      (CandidateFitness
         ((CandidateObjective Emergence Evaluated $e ())
          (CandidateObjective Coherence Evaluated $c ())
          (CandidateObjective UnifiedOptimality Evaluated $o ())
          (CandidateObjective PeirceanQuality Evaluated $p ())))
      (FitnessVector Evaluated ($e $c $o $p))))

(= (HabitTestContext)
   (HybridEvaluationContext
      SourceA SourceB
      (CoherenceConfiguration 0.5
         (SemanticCoherenceEvidence ()))
      (CandidateOptimalityArtifacts ())
      (PeirceanEvaluationEvidence
         0.6
         (HabitPairStrengths
            ((HabitPairStrength a b 0.0)
             (HabitPairStrength c d 0.0)))
         (HabitBreakEvidence ()))))

(= (HabitTestSourceA)
   (Concept source-a functional_use
      (V-predicate
         (Property
            ((a (WorldSpecSet (world)) 0.7)
             (b (WorldSpecSet (world)) 0.6))))))
(= (HabitTestSourceB)
   (Concept source-b functional_use
      (V-predicate
         (Property
            ((a (WorldSpecSet (world)) 0.6)
             (b (WorldSpecSet (world)) 0.7))))))

(= (HabitGenerationContext)
   (HybridEvaluationContext
      (HabitTestSourceA) (HabitTestSourceB)
      (CoherenceConfiguration 0.5
         (SemanticCoherenceEvidence ()))
      (CandidateOptimalityArtifacts ())
      (PeirceanEvaluationEvidence
         0.6
         (HabitPairStrengths ())
         (HabitBreakEvidence ()))))

(= (get-habit-strength (habit-test-strength-memory $strength) $left $right)
   $strength)

!(let* (
   ($strong (habit-test-candidate strong 0 a b 0.9 0.9 0.9 0.9))
   ($dominated (habit-test-candidate dominated 1 c d 0.5 0.5 0.5 0.5))
   ($tradeoff (habit-test-candidate tradeoff 2 e f 1.0 0.4 0.8 0.7))
   ($survivors ($strong $dominated $tradeoff))
   ($memory (habit-memory ((a b) (c d) (c d))))
   ((HabitEvolutionResult $updated $trace)
      (hs-update-habit-memory
         $memory $survivors (HabitEvolutionConfiguration 0.9))))
   (let* (
      ;; Strong and tradeoff are nondominated and form habits; the dominated
      ;; candidate's c-d association receives no new observation.
      ($_successful-count
         (test (size-atom (index-atom (index-atom $trace 2) 1)) 2))
      ($_property-set-count
         (test (size-atom (index-atom (index-atom $trace 3) 1)) 2))
      ($_reinforced-a (test (property-count $updated a) 2))
      ($_not-reinforced-c (test (property-count $updated c) 2))
      ($_new-habit (test (pair-count $updated e f) 1))
      ($_unused-decay
         (test (habit-strength-jaccard $updated c d) 0.9))
      ($refreshed
         (hs-refresh-evaluation-context-habits
            (habit-test-strength-memory 0.42) (HabitTestContext)))
      ($strengths
         (index-atom
            (index-atom (index-atom $refreshed 5) 2) 1))
      ($_refreshed-strength
         (test (index-atom (car-atom $strengths) 3) 0.42))
      ;; A second generation multiplies the prior and current decay factors.
      ((HabitEvolutionResult $updated-twice $second-trace)
         (hs-update-habit-memory
            $updated $survivors (HabitEvolutionConfiguration 0.9)))
      ($_cumulative-decay
         (test (index-atom $updated-twice 1) 0.81)))
      (test (pair-count $updated-twice a b) 3)))

;; Integration boundary: current fitness selects survivors first; only then
;; are habits evolved and promoted candidates reevaluated with refreshed data.
!(let* (
   ($strong (habit-test-candidate strong 0 a b 0.9 0.9 0.9 0.9))
   ($dominated (habit-test-candidate dominated 1 c d 0.5 0.5 0.5 0.5))
   ($tradeoff (habit-test-candidate tradeoff 2 e f 1.0 0.4 0.8 0.7))
   ($parents ($strong $dominated $tradeoff))
   ($refined
      (AggregatedPopulationRefinement
         Evaluated schema mean habit sampler provenance summary
         (Population $parents)))
   ($configuration
      (HybridEvolutionConfiguration 3 0 0.9 0.2 0.1 31))
   ($result
      (hs-evolve-aggregated-generation-with-habits
         $refined 1
         (HabitGenerationContext) (HabitGenerationContext)
         $configuration
         (habit-memory ((a b) (c d) (c d)))
         (HabitEvolutionConfiguration 0.9)))
   ($selection (index-atom $result 5))
   ($selected (index-atom (index-atom $selection 3) 1))
   ($trace (index-atom $result 6))
   ($updated (index-atom (index-atom $result 7) 1))
   ($next-population (index-atom (index-atom $result 8) 1)))
   (let* (
      ($_selected-before-update (test (hs-list-member $strong $selected) True))
      ($_front-formed-habits
         (test (size-atom (index-atom (index-atom $trace 2) 1)) 2))
      ($_memory-threaded (test (pair-count $updated e f) 1)))
      (test (size-atom $next-population) 3)))

;; Atomspace-backed evidence remains wrapped and usable after reinforcement.
!(let* (
   ($candidate (habit-test-candidate strong 0 a b 0.9 0.9 0.9 0.9))
   ($memory
      (atomspace-habit-memory
         (habit-memory ()) () () 0 fixture-index))
   ((HabitEvolutionResult $updated $trace)
      (hs-update-habit-memory
         $memory ($candidate) (HabitEvolutionConfiguration 0.95))))
   (let $_wrapper
      (test (car-atom (index-atom $updated 2)) atomspace-habit-memory)
      (test (pair-count $updated a b) 1)))

;; The public loop retains initialized memory even when no generations run.
!(let* (
   ($memory (habit-memory ((a b))))
   ($initialization
      (HybridSearchInitializationResult Ready
         (Sources SourceA SourceB)
         (GenericSpace Generic)
         (HabitTargetResult Target)
         (SamplingPopulations Sampling)
         (AggregatedPopulation
            (AggregatedPopulationInitialization
               Ready schema mean habit sampler
               (SamplingProvenance ()) (Population ())))
         (HabitMemory $memory)))
   ($result
      (run-hybrid-search-loop
         $initialization (HabitTestContext)
         (McBrideRefinementConfiguration 0.05 1 0.0001 1 0.0 11)
         (HybridEvolutionConfiguration 50 25 0.9 0.1 0.05 17)
         ())))
   (let* (
      ($_complete (test (index-atom $result 1) Complete))
      ($_empty-front
         (test (index-atom (index-atom $result 4) 1)
               (ParetoFront ()))))
      (test (index-atom (index-atom $result 5) 1) $memory)))
