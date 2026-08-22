;; Public PeTTa entrypoint for the complete habit-biased hybrid search.
;;
;; The initialization module owns extraction, Cartesian generalization, habit
;; targeting, five sampling passes, and aggregation. The recursive search then
;; evaluates four objectives, performs McBride degree-only refinement, evolves
;; the shared population, updates/decays habits, and returns one Pareto front.

;; Import the lifecycle dependency root while repository-qualified imports are
;; resolved from the process working directory.
!(import! &self a_quantale_theoretic_approach/optimization/hybrid_search/hybrid-search-initialization)
!(import! &self a_quantale_theoretic_approach/optimization/hybrid_search/candidate-optimality-evaluation)

;; Bootstrap the caller-owned Python environment and static-import macro.
!(import! &self ../PeTTa/lib/lib_import)
!(import! &self "integration/python/integration_support.py")
!(integration_support.configure_component_roots)
!(import! &self "structural_reasoning/generalization-component/python/generalization_event_logger.py")
!(import! &self "structural_reasoning/generalization-component/python/lcggenerator.py")
!(import! &self "structural_reasoning/generalization-component/python/generalization_support.py")
!(import! &self "../habit_memory/real_embeddings.py")
!(import! &self "../habit_memory/persist_memory.py")

;; Static AtomSpaces are caller-owned and therefore bound at this top level.
!(static-import! &algkb v-predicate-extraction-pipeline/kb/generated/AlgebraicSpecificationKB)
!(static-import! &propertyworldkb v-predicate-extraction-pipeline/kb/generated/PropertyWorldKB)
!(static-import! &kb structural_reasoning/generalization-component/kb/lcg_kb)

;; Continue from a materialized initialization result. This is also the stable
;; checkpoint/resume boundary for callers that persist initialization output.
(= (public-pareto-candidates ()) ())
(= (public-pareto-candidates
      (cons
         (HybridCandidate
            $candidate-id $vector $blend $refinement
            $candidate-fitness $fitness-vector)
         $remaining))
   (cons-atom
      (ParetoCandidate $candidate-id $blend $fitness-vector)
      (public-pareto-candidates $remaining)))

(= (public-pareto-front (ParetoFront $candidates))
   (ParetoFront (public-pareto-candidates $candidates)))

(= (run-initialized-quantale-blending-pipeline
      $initialization $initial-evaluation-context
      $refinement-configuration $evolution-configuration
      $habit-configuration $generation-contexts)
   (let* (
      ($search-result
         (run-hybrid-search-loop
            $initialization $initial-evaluation-context
            $refinement-configuration $evolution-configuration
            $habit-configuration $generation-contexts))
      ($_search-complete (hs-log-stage "hybrid_search_completed")))
      (QuantaleBlendPipelineResult
         (index-atom $search-result 1)
         (InitializationStatus (index-atom $initialization 1))
         (GlobalParetoFront
            (public-pareto-front
               (index-atom (index-atom $search-result 4) 1))))))

;; Fresh requests can carry evidence without duplicating source extraction.
;; The exact enriched sources produced by initialization are inserted here.
(= (materialize-initial-evaluation-context
      (HybridSearchInitializationResult
         $status (Sources $source-a $source-b)
         $generic $target $sampling $aggregated $memory)
      (HybridEvaluationEvidence $coherence $optimality $peircean))
   (HybridEvaluationContext
      $source-a $source-b $coherence $optimality $peircean))

;; Backward-compatible form for callers that already provide a complete context.
(= (materialize-initial-evaluation-context
      $initialization
      (HybridEvaluationContext
         $source-a $source-b $coherence $optimality $peircean))
   (HybridEvaluationContext
      $source-a $source-b $coherence $optimality $peircean))

;; Materialize real candidate-level evidence after deterministic sampling.
;; Categories and evidence are derived from each candidate's actual property
;; worlds and degrees, so all four objective values can discriminate candidates.
(= (example-initialization-candidates
      (HybridSearchInitializationResult
         $status $sources $generic $target $sampling
         (AggregatedPopulation
            (AggregatedPopulationInitialization
               $aggregate-status $schema $mean $habit $sampler $provenance
               (Population $candidates)))
         $memory))
   $candidates)

(= (example-opt-g $universe)
   (VCategory ExampleG $universe (g) ((g g (Q $universe 1.0)))))
(= (example-opt-a $universe)
   (VCategory ExampleA $universe (a) ((a a (Q $universe 1.0)))))
(= (example-opt-b $universe)
   (VCategory ExampleB $universe (b) ((b b (Q $universe 1.0)))))
(= (example-opt-c $universe)
   (VCategory ExampleC $universe (c) ((c c (Q $universe 1.0)))))
(= (example-opt-x $universe)
   (VCategory ExampleX $universe (x) ((x x (Q $universe 1.0)))))

(= (example-opt-sigma-a $universe)
   (VMorphism ExampleSigmaA
      (example-opt-g $universe) (example-opt-a $universe) ((g a))))
(= (example-opt-sigma-b $universe)
   (VMorphism ExampleSigmaB
      (example-opt-g $universe) (example-opt-b $universe) ((g b))))
(= (example-opt-in-a $universe)
   (VMorphism ExampleInA
      (example-opt-a $universe) (example-opt-c $universe) ((a c))))
(= (example-opt-in-b $universe)
   (VMorphism ExampleInB
      (example-opt-b $universe) (example-opt-c $universe) ((b c))))
(= (example-opt-back-a $universe)
   (VMorphism ExampleBackA
      (example-opt-c $universe) (example-opt-a $universe) ((c a))))
(= (example-opt-back-b $universe)
   (VMorphism ExampleBackB
      (example-opt-c $universe) (example-opt-b $universe) ((c b))))
(= (example-opt-cocone $universe)
   (VCocone ExampleCocone
      (example-opt-sigma-a $universe) (example-opt-sigma-b $universe)
      (example-opt-in-a $universe) (example-opt-in-b $universe)))
(= (example-opt-comparison $universe)
   (VCocone ExampleComparison
      (example-opt-sigma-a $universe) (example-opt-sigma-b $universe)
      (VMorphism ExampleCompareInA
         (example-opt-a $universe) (example-opt-x $universe) ((a x)))
      (VMorphism ExampleCompareInB
         (example-opt-b $universe) (example-opt-x $universe) ((b x)))))
(= (example-opt-vcolimit $universe)
   (VColimit ExampleVColimit (example-opt-cocone $universe)
      (MediatingWitnesses
         ((MediatingWitness
            (example-opt-comparison $universe)
            (VMorphism ExampleMediator
               (example-opt-c $universe) (example-opt-x $universe)
               ((c x))))))
      (ComparisonScope ((example-opt-comparison $universe)) Exhaustive)))

(= (example-opt-family-a $universe)
   (VitalRelationFamily functional_use (example-opt-a $universe)
      ((vr-make ExampleRelation functional_use (example-opt-a $universe)
         ((a a (Q $universe 0.8))) (SourceConcept playing_hockey)))))
(= (example-opt-family-b $universe)
   (VitalRelationFamily functional_use (example-opt-b $universe)
      ((vr-make ExampleRelation functional_use (example-opt-b $universe)
         ((b b (Q $universe 0.7))) (SourceConcept surfing)))))
(= (example-opt-family-c $universe $degree)
   (VitalRelationFamily functional_use (example-opt-c $universe)
      ((vr-make ExampleRelation functional_use (example-opt-c $universe)
         ((c c (Q $universe $degree)))
         (BlendConcept recreational-sport-blend)))))

(= (example-property-evidence () $universe) ())
(= (example-property-evidence (cons $property $remaining) $universe)
   (cons-atom
      (PropertyEvidence
         (hs-v-property-name $property)
         (Q $universe (hs-v-property-degree $property))
         (SourceContributions playing_hockey surfing))
      (example-property-evidence $remaining $universe)))

(= (example-candidate-optimality-inputs $candidate)
   (let* (
      ($properties (hs-v-property-list $candidate))
      ($universe (v-world-universe $candidate))
      ($degree (hs-maximum-degree $properties)))
      (VOptimalityInputs
         $candidate (example-opt-vcolimit $universe)
         (example-opt-family-a $universe)
         (example-opt-family-b $universe)
         (example-opt-family-c $universe $degree)
         ((VitalRelationCorrespondence
            ExampleSharedRelation ExampleRelation ExampleRelation
            ExampleRelation (Q $universe 1.0)))
         (example-opt-sigma-a $universe) (example-opt-sigma-b $universe)
         (example-opt-in-a $universe) (example-opt-in-b $universe)
         (example-opt-back-a $universe) (example-opt-back-b $universe)
         (example-property-evidence $properties $universe)
         ((RelevantEvidence functional_use
            (Q $universe $degree) (Q $universe 1.0))))))

(= (example-break-pairs-with $property ()) ())
(= (example-break-pairs-with $property (cons $next $remaining))
   (cons-atom
      ((hs-v-property-name $property)
       (hs-v-property-name $next)
       (* (hs-v-property-degree $property)
          (hs-v-property-degree $next)))
      (example-break-pairs-with $property $remaining)))
(= (example-break-pairs ()) ())
(= (example-break-pairs (cons $property $remaining))
   (hs-candidate-list-append
      (example-break-pairs-with $property $remaining)
      (example-break-pairs $remaining)))

(= (example-pair-evidence-with $memory $name ())
   (ExamplePairEvidence () ()))
(= (example-pair-evidence-with
      $memory $name (cons $next $remaining))
   (let* (
      ($strength (get-habit-strength $memory $name $next))
      ((ExamplePairEvidence $semantic-tail $strength-tail)
         (example-pair-evidence-with $memory $name $remaining)))
      (ExamplePairEvidence
         (cons-atom (SemanticPair $name $next $strength) $semantic-tail)
         (cons-atom (HabitPairStrength $name $next $strength)
            $strength-tail))))
(= (example-pair-evidence $memory ())
   (ExamplePairEvidence () ()))
(= (example-pair-evidence $memory (cons $name $remaining))
   (let* (
      ((ExamplePairEvidence $head-semantic $head-strengths)
         (example-pair-evidence-with $memory $name $remaining))
      ((ExamplePairEvidence $tail-semantic $tail-strengths)
         (example-pair-evidence $memory $remaining)))
      (ExamplePairEvidence
         (hs-candidate-list-append $head-semantic $tail-semantic)
         (hs-candidate-list-append $head-strengths $tail-strengths))))

(= (example-candidate-evidence ())
   (ExampleCandidateEvidence () ()))
(= (example-candidate-evidence
      (cons
         (SampledCandidate
            $subproblem $individual $vector $candidate)
         $remaining))
   (let* (
      ((ExampleCandidateEvidence $optimality-tail $break-tail)
         (example-candidate-evidence $remaining))
      ($optimality
         (CandidateOptimalityResult
            $subproblem $individual $candidate
            (q-enriched-optimality-evaluator
               (example-candidate-optimality-inputs $candidate))))
      ($breaks
         (CandidateHabitBreakPairs $subproblem $individual
            (example-break-pairs (hs-v-property-list $candidate)))))
      (ExampleCandidateEvidence
         (cons-atom $optimality $optimality-tail)
         (cons-atom $breaks $break-tail))))

(= (materialize-initial-evaluation-context
      $initialization
      (AutomaticHybridEvaluationEvidence $coherence-alpha $peircean-alpha))
   (let* (
      ($candidates (example-initialization-candidates $initialization))
      ((ExampleCandidateEvidence $optimality $breaks)
         (example-candidate-evidence $candidates))
      ($source-block (index-atom $initialization 2))
      ($memory (index-atom (index-atom $initialization 7) 1))
      ($first-candidate
         (index-atom (car-atom $candidates) 4))
      ($property-names (hs-candidate-property-names $first-candidate))
      ((ExamplePairEvidence $semantic $strengths)
         (example-pair-evidence $memory $property-names)))
      (HybridEvaluationContext
         (index-atom $source-block 1)
         (index-atom $source-block 2)
         (CoherenceConfiguration
            $coherence-alpha (SemanticCoherenceEvidence $semantic))
         (CandidateOptimalityArtifacts $optimality)
         (PeirceanEvaluationEvidence
            $peircean-alpha (HabitPairStrengths $strengths)
            (HabitBreakEvidence $breaks)))))

;; Fresh-run request: execute every implemented stage from the two source
;; concept names through the final global Pareto front.
(= (execute-quantale-blending-request
      (QuantaleBlendPipelineRequest
         $generic-name $perspective $concept-a $concept-b $seed $kappa
         $initial-evaluation-context
         $refinement-configuration $evolution-configuration
         $habit-configuration $generation-contexts))
   (let* (
      ($initialization
         (initialize-habit-biased-populations
            $generic-name $perspective $concept-a $concept-b $seed $kappa))
      ($materialized-context
         (materialize-initial-evaluation-context
            $initialization $initial-evaluation-context)))
      (run-initialized-quantale-blending-pipeline
         $initialization $materialized-context
         $refinement-configuration $evolution-configuration
         $habit-configuration $generation-contexts)))

;; Resume request: use an already materialized initialization result without
;; repeating extraction, generalization, or the five sampling passes.
(= (execute-quantale-blending-request
      (InitializedQuantaleBlendPipelineRequest
         $initialization $initial-evaluation-context
         $refinement-configuration $evolution-configuration
         $habit-configuration $generation-contexts))
   (run-initialized-quantale-blending-pipeline
      $initialization $initial-evaluation-context
      $refinement-configuration $evolution-configuration
      $habit-configuration $generation-contexts))

;; Conventional standalone entrypoint. Keep request execution behind a
;; non-reserved symbol so imported callers can use the same implementation.
(= (main $request)
   (execute-quantale-blending-request $request))

;; Descriptive alias for hosts that do not use the conventional main symbol.
(= (run-quantale-blending-pipeline $request)
   (execute-quantale-blending-request $request))

;; --------------------------------------------------------------------------
;; Ready-to-run examples
;; --------------------------------------------------------------------------
;; Uncomment exactly one block below and run from the repository root with:
;;   petta a_quantale_theoretic_approach/main.metta
;;
;; `playing_hockey` and `surfing` are real functional-use concepts in the
;; generated property/world KB. Their shared challenge, entertainment,
;; exercise, and fun properties produce a genuinely multi-property search
;; space when GENERALIZATION_LLM_MODE=off. Candidate-specific coherence,
;; optimality, and habit-break evidence is materialized from each sampled
;; candidate, allowing Pareto selection to reject dominated candidates. The
;; example performs initialization and Pareto selection with zero evolutionary
;; generations; supply GenerationContexts to evolve it further.

;; Concrete example parameter initialization.
(= (example-generic-name) recreational-sport-blend)
(= (example-perspective) functional_use)
(= (example-source-concept-a) playing_hockey)
(= (example-source-concept-b) surfing)
(= (example-seed) 41)
(= (example-habit-bias) 0.5)

(= (example-initial-evaluation-context)
   (AutomaticHybridEvaluationEvidence 0.5 0.6))

(= (example-mcbride-configuration)
   (McBrideRefinementConfiguration 0.05 20 0.0001 5 0.25 101))

(= (example-evolution-configuration)
   (HybridEvolutionConfiguration 50 25 0.9 0.1 0.05 211))

(= (example-habit-configuration)
   (HabitEvolutionConfiguration 0.99))

(= (example-generation-contexts) ())

(= (example-quantale-blend-request)
   (QuantaleBlendPipelineRequest
      (example-generic-name) (example-perspective)
      (example-source-concept-a) (example-source-concept-b)
      (example-seed) (example-habit-bias)
      (example-initial-evaluation-context)
      (example-mcbride-configuration)
      (example-evolution-configuration)
      (example-habit-configuration)
      (example-generation-contexts)))

;; Conventional `main` entrypoint. Uncomment to run.
!(once (main (example-quantale-blend-request)))

;; Descriptive entrypoint alias. Uncomment to run.
; !(once (run-quantale-blending-pipeline (example-quantale-blend-request)))
