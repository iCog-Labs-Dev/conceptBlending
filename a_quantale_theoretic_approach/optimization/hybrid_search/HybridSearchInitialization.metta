;; Steps 1-4 of Algorithm 1: extract, generalize, build habits, sample once.

!(import! &self ../../../PeTTa/lib/lib_import)
(= (py-eval $str)
   (let $dict (py-call (dict))
      (py-call (quote (eval $str $dict $dict)))))

;; Initialize repository-qualified Python paths before imported components run
;; their own eager storage and logger setup.
(= (hs-register-python-bridge)
   (py-eval "(lambda os,sys,importlib:(lambda repo:(sys.path.insert(0,os.path.join(repo,'a_quantale_theoretic_approach','optimization','hybrid_search','python')),importlib.import_module('hybrid_sampling').register_petta_builtins(),True)[-1])(os.path.abspath(os.path.join(os.getcwd(),'../../..')) if os.path.basename(os.getcwd())=='hybrid_search' else os.getcwd()))(__import__('os'),__import__('sys'),__import__('importlib'))"))
!(hs-register-python-bridge)

;; Source V-predicate extraction and world algebraic-specification storage.
!(import! &self ../../integration/python/integration_support.py)
!(integration_support.configure_component_roots)
!(import! &self ../../v-predicate-extraction-pipeline/synthesizers)
!(import! &self ../../v-predicate-extraction-pipeline/metta/logging/PipelineLogger)
!(static-import! &algkb ../../v-predicate-extraction-pipeline/kb/generated/AlgebraicSpecificationKB)
!(static-import! &propertyworldkb ../../v-predicate-extraction-pipeline/kb/generated/PropertyWorldKB)
!(import! &self ../../v-predicate-extraction-pipeline/metta/algebraic_spec/AlgebraicSpecificationDataLayer)
!(import! &self ../../v-predicate-extraction-pipeline/metta/algebraic_spec/AlgebraicSpecificationSpace)
!(import! &self ../../v-predicate-extraction-pipeline/metta/property_world/PropertyWorldDataLayer)

;; Cached property/world LCG and real Cartesian algebraic-spec generalization.
!(import! &self ../../structural_reasoning/generalization-component/metta/Common)
!(import! &self ../../structural_reasoning/generalization-component/metta/GeneralizationDTLhelper)
!(import! &self ../../structural_reasoning/generalization-component/metta/GeneralizationDTL)
!(static-import! &kb ../../structural_reasoning/generalization-component/kb/lcg_kb)
!(import! &self "../../structural_reasoning/generalization-component/python/generalization_event_logger.py")
!(import! &self ../../structural_reasoning/generalization-component/metta/logging/GeneralizationLogger)
!(import! &self "../../structural_reasoning/generalization-component/python/lcggenerator.py")
!(import! &self "../../structural_reasoning/generalization-component/python/generalization_support.py")
!(import! &self ../../structural_reasoning/generalization-component/metta/GeneralizationPipeline)

;; Existing sibling Peircean memory plus the atomspace evidence adapter.
!(import! &self ../../../habit_memory/memory)
!(import! &self "../../../habit_memory/real_embeddings.py")
!(import! &self ../../../habit_memory/embeddings)
!(import! &self ../../../habit_memory/habit_memory)
!(import! &self ../../../habit_memory/atomspace_memory)

;; Reuse the CMA-ES Cholesky-based multivariate-normal implementation.
!(import! &self ../../../peTTa_version/utils/cma-es-utils)

;; Candidate records and the four-objective population-evaluation stage.
!(import! &self CandidateEvaluation)
!(import! &self HybridSearchMcBrideRefinement)

(= (hs-enrich-compact $compact $seed)
   (let $_bridge (hs-register-python-bridge)
      (sread (py-call
         (builtins.hs_enrich_compact_vpredicate
            (repr (reduce $compact)) $seed 0.05 0.95)))))

(= (hs-request-list $request-expression)
   (cdr-atom $request-expression))

(= (hs-resolve-properties $source-a $source-b)
   (let $_bridge (hs-register-python-bridge)
      (let $request-expression
         (sread (py-call
            (builtins.hs_property_pair_requests
               (repr (reduce $source-a)) (repr (reduce $source-b)))))
         (let $requests (hs-request-list $request-expression)
            (PairResolutions
               (resolve-pair-requests $requests kb &kb 10))))))

(= (hs-world-pair-requests $source-a $source-b $property-resolutions)
   (let $_bridge (hs-register-python-bridge)
      (sread (py-call
         (builtins.hs_world_pair_requests
            (repr (reduce $source-a)) (repr (reduce $source-b))
            (repr (reduce $property-resolutions)))))))

(= (hs-resolve-worlds $source-a $source-b $property-resolutions)
   (let $request-expression
      (hs-world-pair-requests $source-a $source-b $property-resolutions)
      (let $requests (hs-request-list $request-expression)
         (WorldResolutions
            (resolve-pair-requests $requests kb &kb 10)))))

(= (hs-single-world-spec $world $perspective)
   (let $specifications (collapse (get-world-algebraic-spec $world $perspective))
      (if (== (size-atom $specifications) 1)
          (car-atom $specifications)
          (HybridInitializationError
             WorldAlgebraicSpecificationUnavailable
             $world $perspective (Found (size-atom $specifications))))))

(= (hs-is-error $value)
   (== (car-atom $value) HybridInitializationError))

(= (hs-pair-generic-world-spec
      $generic-world $perspective $world-a $world-b $spec-a $spec-b)
   (if (== $world-a $world-b)
       $spec-a
       (main-lcg $generic-world $perspective $spec-a $spec-b)))

;; When multiple source-world pairs share an LCG, fold their genuine pairwise
;; generic specs into the one perspective-qualified generic world spec.
(= (hs-store-generic-world-spec $generic-world $perspective $pair-spec)
   (if (has-world-algebraic-spec $generic-world $perspective)
       (let $existing (hs-single-world-spec $generic-world $perspective)
          (if (== $existing $pair-spec)
              True
              (let $combined (main-lcg
                                $generic-world $perspective $existing $pair-spec)
                 (store-world-algebraic-spec
                    $generic-world $perspective $combined))))
       (store-world-algebraic-spec
          $generic-world $perspective $pair-spec)))

(= (hs-materialize-world-resolutions $perspective ()) ())
(= (hs-materialize-world-resolutions $perspective
      (cons
         (PairResolution
            (WorldPairId $generic-property $property-a $property-b $world-a $world-b)
            $generic-world $tv)
         $remaining))
   (let* (
      ($spec-a (hs-single-world-spec $world-a $perspective))
      ($spec-b (hs-single-world-spec $world-b $perspective)))
      (if (hs-is-error $spec-a)
          $spec-a
          (if (hs-is-error $spec-b)
              $spec-b
              (let* (
                 ($pair-spec
                    (hs-pair-generic-world-spec
                       $generic-world $perspective
                       $world-a $world-b $spec-a $spec-b))
                 ($_stored
                    (hs-store-generic-world-spec
                       $generic-world $perspective $pair-spec))
                 ($rest
                    (hs-materialize-world-resolutions
                       $perspective $remaining)))
                 (cons-atom
                    (GenericWorldMapping
                       $generic-world $generic-property
                       $property-a $property-b $world-a $world-b)
                    $rest))))))

(= (hs-generic-result-from-mappings
      $generic-name $perspective $property-resolutions $world-mappings $seed)
   (let $_bridge (hs-register-python-bridge)
      (sread (py-call
         (builtins.hs_generic_vpredicate_result
            $generic-name $perspective
            (repr (reduce $property-resolutions))
            (repr (reduce $world-mappings)) $seed 0.05 0.95)))))

(= (hs-generic-vpredicate
      $generic-name $perspective $source-a $source-b $seed)
   (let* (
      ($property-resolutions (hs-resolve-properties $source-a $source-b))
      ($world-resolutions
         (hs-resolve-worlds $source-a $source-b $property-resolutions))
      ((WorldResolutions $resolved-worlds) $world-resolutions)
      ($world-mappings
         (WorldMappings
            (hs-materialize-world-resolutions $perspective $resolved-worlds))))
      (hs-generic-result-from-mappings
         $generic-name $perspective
         $property-resolutions $world-mappings $seed)))

(= (hs-generic-property-mappings $generic-result)
   (let $mapping-block (index-atom $generic-result 2)
      (cdr-atom $mapping-block)))

(= (hs-habit-strengths $memory ()) ())
(= (hs-habit-strengths $memory
      (cons (GenericPropertyMapping $generic $property-a $property-b) $remaining))
   (cons-atom
      (HabitStrength $generic $property-a $property-b
         (get-habit-strength $memory $property-a $property-b))
      (hs-habit-strengths $memory $remaining)))

(= (hs-habit-target-from-strengths
      $source-a $source-b $generic-result $strengths $kappa)
   (let $_bridge (hs-register-python-bridge)
      (sread (py-call
         (builtins.hs_habit_target
            (repr (reduce $source-a)) (repr (reduce $source-b))
            (repr (reduce $generic-result))
            (repr (reduce $strengths)) $kappa)))))

(= (hs-build-habit-target $source-a $source-b $generic-result $memory $kappa)
   (let* (
      ($mappings (hs-generic-property-mappings $generic-result))
      ($strengths (HabitStrengths (hs-habit-strengths $memory $mappings))))
      (hs-habit-target-from-strengths
         $source-a $source-b $generic-result $strengths $kappa)))

(= (hs-memory-for-sources $source-a $source-b)
   (let $_bridge (hs-register-python-bridge)
      (let $properties
         (sread (py-call
            (builtins.hs_source_property_names
               (repr (reduce $source-a)) (repr (reduce $source-b)))))
         (augment-habit-memory-from-atomspace
            (memory-from-imported-history) $properties))))

(= (hs-sample-five-populations $generic-result $target $seed)
   (let* (
      ($_bridge (hs-register-python-bridge))
      ($plan
         (sread (py-call
            (builtins.hs_sampling_plan
               (repr (reduce $generic-result)) (repr (reduce $target))
               10 0.15 "(0 0.25 0.5 0.75 1)"))))
      ($_seeded (py-call (builtins.hs_seed_multivariate_stream $seed)))
      ($subproblem-plans (cdr-atom (index-atom $plan 5)))
      ($sampled
         (SampledSubproblems
            (hs-random-multivariate-subproblems $subproblem-plans))))
      (sread (py-call
         (builtins.hs_materialize_populations
            (repr (reduce $generic-result)) (repr (reduce $plan))
            (repr (reduce $sampled)))))))

(= (hs-random-multivariate-subproblems ()) ())
(= (hs-random-multivariate-subproblems
      (cons
         (SamplingSubproblem $index $bias
            (Mean $mean) (Covariance $covariance) (StepSize $step-size))
         $remaining))
   (let* (
      ($scaled-covariance
         (mat-scalar-op $covariance (pow-math $step-size 2) *))
      ($samples
         (mat-clip
            (random-multivariate $mean $scaled-covariance 10)
            0.01 0.99))
      ($rest (hs-random-multivariate-subproblems $remaining)))
      (cons-atom (SampledSubproblem $index $samples) $rest)))

(= (hs-population-count $populations)
   (let $_bridge (hs-register-python-bridge)
      (py-call
         (builtins.hs_population_count (repr (reduce $populations))))))

(= (hs-individual-counts $populations)
   (let $_bridge (hs-register-python-bridge)
      (sread (py-call
         (builtins.hs_individual_counts (repr (reduce $populations)))))))

;; Public end-to-end entry point for the agreed initialization boundary.
(= (initialize-habit-biased-populations
      $generic-name $perspective $concept-a $concept-b $seed $kappa)
   (let* (
      ($compact-a
         (build-concept-property-world-specifications $concept-a $perspective))
      ($compact-b
         (build-concept-property-world-specifications $concept-b $perspective))
      ($source-a (hs-enrich-compact $compact-a $seed))
      ($source-b (hs-enrich-compact $compact-b (+ $seed 1)))
      ($generic
         (hs-generic-vpredicate
            $generic-name $perspective $source-a $source-b (+ $seed 2)))
      ($memory (hs-memory-for-sources $source-a $source-b))
      ($target
         (hs-build-habit-target
            $source-a $source-b $generic $memory $kappa))
      ($populations
         (hs-sample-five-populations $generic $target (+ $seed 3))))
      (HybridSearchInitializationResult Ready
         (Sources $source-a $source-b)
         (GenericSpace $generic)
         (HabitTargetResult $target)
         (Populations $populations))))
