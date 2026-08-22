;; Executable orchestration of the structural, quantale-colimit, and enriched
;; optimality components. This bootstrap imports each producer once and keeps
;; GNN scalar assignment and enriched-Hom extraction as explicit boundaries.

; PeTTa does not re-export definitions hidden behind a second facade import.
; Load the structural component's direct dependencies here, once, so the
; public producer heads are callable from a query importing this facade.
!(import! &self ../../../PeTTa/lib/lib_import)
!(import! &self "python/integration_support.py")
!(integration_support.configure_component_roots)
(= (py-eval $str)
   (let $dict (py-call (dict))
      (py-call (quote (eval $str $dict $dict)))))
!(import! &self ../v-predicate-extraction-pipeline/synthesizers)
!(import! &self ../v-predicate-extraction-pipeline/metta/logging/PipelineLogger)
!(import! &self
   ../structural_reasoning/generalization-component/metta/Common)
!(import! &self
   ../structural_reasoning/generalization-component/metta/GeneralizationDTLhelper)
!(import! &self
   ../structural_reasoning/generalization-component/metta/GeneralizationDTL)
!(static-import! &kb
   ../structural_reasoning/generalization-component/kb/lcg_kb)
!(import! &self
   "../structural_reasoning/generalization-component/python/generalization_event_logger.py")
!(import! &self
   ../structural_reasoning/generalization-component/metta/logging/GeneralizationLogger)
!(import! &self
   "../structural_reasoning/generalization-component/python/lcggenerator.py")
!(import! &self
   "../structural_reasoning/generalization-component/python/generalization_support.py")
!(import! &self
   ../structural_reasoning/generalization-component/metta/GeneralizationPipeline)
!(import! &self a_quantale_theoretic_approach/optimality/optimality-integration)
; Optimality supplies the shared quantale and V-predicate definitions. Import
; only the colimit's world helpers and definition-only core to avoid duplicate
; reductions of the same quantale operations.
!(import! &self a_quantale_theoretic_approach/structural_reasoning/world_spec_colimit)
!(import! &self a_quantale_theoretic_approach/structural_reasoning/quantale-colimit-core)

(= (q-complete-pipeline-status
      (VOptimalityResult $status $constraints $value))
   $status)

; Native assembly avoids leaking the integration_support Python module across
; PeTTa's import boundary. main-lcg is still the real cached Cartesian
; generalizer loaded above.
(= (q-complete-prepare-structural-blend
      $generic-name $perspective
      $compact-source-a $compact-source-b
      $source-spec-a $source-spec-b)
   (let $generic-spec
      (main-lcg
         $generic-name $perspective $source-spec-a $source-spec-b)
      (if (== $generic-spec ())
          (IntegrationError
             GenericSpaceAlgebraicSpecificationUnavailable
             $generic-name $perspective)
          (structural-blend-preparation
             $generic-name $perspective
             (SourceVPredicates $compact-source-a $compact-source-b)
             (SourceAlgebraicSpecifications $source-spec-a $source-spec-b)
             (GenericSpaceAlgebraicSpecification $generic-spec)
             (EnrichmentStatus
                (PropertyTruthScalars Pending GNN)
                (EnrichedHomValues Pending HomExtractionPipeline)
                (VColimitCheck Blocked EnrichedHomValues))))))

(= (q-complete-pipeline-package $structural $colimit $optimality)
   (CompleteBlendPipelineResult
      (q-complete-pipeline-status $optimality)
      (StructuralPreparation $structural)
      (VPredicateColimit $colimit)
      (Optimality $optimality)))

(= (q-complete-pipeline-pending-scalars $structural)
   (CompleteBlendPipelineResult
      Pending
      (StructuralPreparation $structural)
      (VPredicateColimit ())
      (Optimality
         (VOptimalityResult Pending
            ((VConstraintResult
                IntegrationContext Pending (q-bottom)
                (MissingPropertyTruthScalars GNN)))
            (q-bottom)))))

(= (q-enriched-source-compatible
      $compact-source $enriched-source $perspective)
   (if (== (v-concept-name $compact-source)
           (v-concept-name $enriched-source))
       (if (== (v-concept-perspective $compact-source) $perspective)
           (== (v-concept-perspective $enriched-source) $perspective)
           False)
       False))

(= (q-preparation-source-a
      (structural-blend-preparation
         $generic-name $perspective
         (SourceVPredicates $source-a $source-b)
         $source-specs $generic-spec $status))
   $source-a)
(= (q-preparation-source-b
      (structural-blend-preparation
         $generic-name $perspective
         (SourceVPredicates $source-a $source-b)
         $source-specs $generic-spec $status))
   $source-b)

(= (q-complete-pipeline-invalid-scalars $structural $side $reason)
   (CompleteBlendPipelineResult
      Blocked
      (StructuralPreparation $structural)
      (VPredicateColimit ())
      (Optimality
         (VOptimalityResult Blocked
            ((VConstraintResult
                IntegrationContext Blocked (q-bottom)
                (InvalidPropertyTruthScalars $side $reason)))
            (q-bottom)))))

(= (q-run-complete-after-structural
      $generic-name $perspective $structural
      $enriched-source-a $enriched-source-b
      $property-mappings $world-clusters $world-spec-registry $artifacts)
   (if (== $enriched-source-a ())
       (q-complete-pipeline-pending-scalars $structural)
       (if (== $enriched-source-b ())
           (q-complete-pipeline-pending-scalars $structural)
           (if (q-enriched-source-compatible
                  (q-preparation-source-a $structural)
                  $enriched-source-a $perspective)
               (if (q-enriched-source-compatible
                      (q-preparation-source-b $structural)
                      $enriched-source-b $perspective)
                   (let* (
                      ($colimit
                         (q-vpredicate-integrated-colimit
                            $generic-name
                            $enriched-source-a $enriched-source-b
                            $property-mappings $world-clusters
                            $world-spec-registry))
                      ($optimality
                         (q-evaluate-integrated-optimality
                            $structural $colimit $artifacts)))
                      (q-complete-pipeline-package
                         $structural $colimit $optimality))
                   (q-complete-pipeline-invalid-scalars
                      $structural SourceB ConceptOrPerspectiveMismatch))
               (q-complete-pipeline-invalid-scalars
                  $structural SourceA ConceptOrPerspectiveMismatch)))))

; Public end-to-end entry point. Compact predicates and algebraic specs flow
; through the real generalization component; enriched source predicates flow
; through the real world-aware quantale colimit; its output flows directly to
; enriched optimality.
(= (q-run-complete-blend-pipeline
      $generic-name $perspective
      $compact-source-a $compact-source-b
      $source-spec-a $source-spec-b
      $enriched-source-a $enriched-source-b
      $property-mappings $world-clusters $world-spec-registry
      $artifacts)
   (let $structural
      (q-complete-prepare-structural-blend
         $generic-name $perspective
         $compact-source-a $compact-source-b
         $source-spec-a $source-spec-b)
      (q-run-complete-after-structural
         $generic-name $perspective $structural
         $enriched-source-a $enriched-source-b
         $property-mappings $world-clusters $world-spec-registry
         $artifacts)))
