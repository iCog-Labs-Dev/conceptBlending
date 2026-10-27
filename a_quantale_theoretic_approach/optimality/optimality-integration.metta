!(import! &self a_quantale_theoretic_approach/optimality/enriched_optimality_constraints)

; Staged boundary between the structural/V-predicate/colimit producers and
; enriched optimality. Producer results are inert data here: this module does
; not import their large executable pipelines, which avoids duplicate PeTTa
; imports and lets each stage be run, cached, and inspected independently.

(= (q-structural-preparation
      (Prepare-structural-result ($preparation)))
   $preparation)
(= (q-structural-preparation
      (structural-blend-preparation
         $generic-name $perspective $sources $source-specs
         $generic-spec $status))
   (structural-blend-preparation
      $generic-name $perspective $sources $source-specs
      $generic-spec $status))

(= (q-preparation-generic-name
      (structural-blend-preparation
         $generic-name $perspective $sources $source-specs
         $generic-spec $status))
   $generic-name)
(= (q-preparation-perspective
      (structural-blend-preparation
         $generic-name $perspective $sources $source-specs
         $generic-spec $status))
   $perspective)

(= (q-colimit-result-blend
      (QuantaleVPredicateColimitResult
         (WorldSpecs $world-specs)
         (Blend $blend)
         (WorldMap $world-map)
         (PropertyContributionMap $property-map)))
   $blend)

(= (q-colimit-result-property-map
      (QuantaleVPredicateColimitResult
         (WorldSpecs $world-specs)
         (Blend $blend)
         (WorldMap $world-map)
         (PropertyContributionMap $property-map)))
   $property-map)

(= (q-derived-property-evidence-fold
      $candidate-properties $source-a-properties $source-b-properties)
   (if (== $candidate-properties ())
       ()
       (let* (
          ($candidate-property (car-atom $candidate-properties))
          ($tail (cdr-atom $candidate-properties))
          ($name (v-property-name $candidate-property))
          ($source-a-property
             (v-find-property $name $source-a-properties))
          ($source-b-property
             (v-find-property $name $source-b-properties))
          ($tail-evidence
             (q-derived-property-evidence-fold
                $tail $source-a-properties $source-b-properties)))
          (if (== $source-a-property ())
              (if (== $source-b-property ())
                  $tail-evidence
                  (cons-atom
                     (PropertyEvidence
                        $name (v-property-quantale $source-b-property)
                        (ColimitContribution
                           (SourceB $source-b-property)))
                     $tail-evidence))
              (if (== $source-b-property ())
                  (cons-atom
                     (PropertyEvidence
                        $name (v-property-quantale $source-a-property)
                        (ColimitContribution
                           (SourceA $source-a-property)))
                     $tail-evidence)
                  (cons-atom
                     (PropertyEvidence
                        $name
                        (q-join
                           (v-property-quantale $source-a-property)
                           (v-property-quantale $source-b-property))
                        (ColimitContributions
                           (SourceA $source-a-property)
                           (SourceB $source-b-property)))
                     $tail-evidence))))))

(= (q-derived-property-evidence
      $candidate ((A $source-a-properties) (B $source-b-properties)))
   (q-derived-property-evidence-fold
      (v-property-list $candidate)
      $source-a-properties $source-b-properties))
(= (q-derived-property-evidence $candidate ()) ())

(= (q-select-property-evidence
      $explicit-evidence $candidate $property-map)
   (if (== $explicit-evidence ())
       (q-derived-property-evidence $candidate $property-map)
       $explicit-evidence))

; Values not produced by structural preparation or the V-predicate colimit
; are supplied by the enriched-Hom/relation stage through this explicit atom.
;
; (OptimalityEnrichmentArtifacts
;    VColimit SourceFamilyA SourceFamilyB BlendFamily Correspondences
;    GenericToA GenericToB SourceAToBlend SourceBToBlend
;    BlendToA BlendToB PropertyEvidence RelevanceEvidence)

(= (q-optimality-integration-blocked $reason)
   (OptimalityIntegrationResult Blocked (q-bottom) $reason))

(= (q-prepare-integrated-optimality-context
      $structural-result $colimit-result ())
   (q-optimality-integration-blocked
      (MissingEnrichmentArtifacts
         VColimit EnrichedHomValues VitalRelations Provenance)))

(= (q-prepare-integrated-optimality-context
      $structural-result
      $colimit-result
      (OptimalityEnrichmentArtifacts
         $vcolimit $family-a $family-b $blend-family $correspondences
         $generic-to-a $generic-to-b $map-a $map-b
         $blend-to-a $blend-to-b $property-evidence $relevance-evidence))
   (let* (
      ($preparation (q-structural-preparation $structural-result))
      ($generic-name (q-preparation-generic-name $preparation))
      ($perspective (q-preparation-perspective $preparation))
      ($candidate (q-colimit-result-blend $colimit-result))
      ($selected-property-evidence
         (q-select-property-evidence
            $property-evidence $candidate
            (q-colimit-result-property-map $colimit-result))))
      (if (== $generic-name (v-concept-name $candidate))
          (if (== $perspective (v-concept-perspective $candidate))
              (q-finish-integrated-optimality-context
                 (q-build-optimality-context
                    (VOptimalityInputs
                       $candidate $vcolimit
                       $family-a $family-b $blend-family $correspondences
                       $generic-to-a $generic-to-b $map-a $map-b
                       $blend-to-a $blend-to-b
                       $selected-property-evidence $relevance-evidence)))
              (q-optimality-integration-blocked
                 (PerspectiveMismatch
                    (Structural $perspective)
                    (Colimit (v-concept-perspective $candidate)))))
          (q-optimality-integration-blocked
             (GenericConceptMismatch
                (Structural $generic-name)
                (Colimit (v-concept-name $candidate)))))))

(= (q-finish-integrated-optimality-context
      (VOptimalityContextError $reason))
   (q-optimality-integration-blocked
      (InvalidOptimalityContext $reason)))
(= (q-finish-integrated-optimality-context
      (VSharedOptimalityContext
         $perspective $universe $candidate $vcolimit
         $family-a $family-b $blend-family
         $transported-a $transported-b
         $correspondences $generic-to-a $generic-to-b $map-a $map-b
         $blend-to-a $blend-to-b $property-evidence $relevance-evidence))
   (OptimalityIntegrationResult Ready
      (q-unit $universe)
      (VSharedOptimalityContext
         $perspective $universe $candidate $vcolimit
         $family-a $family-b $blend-family
         $transported-a $transported-b
         $correspondences $generic-to-a $generic-to-b $map-a $map-b
         $blend-to-a $blend-to-b $property-evidence $relevance-evidence)))

(= (q-evaluate-integrated-optimality
      $structural-result $colimit-result $artifacts)
   (q-evaluate-optimality-integration-result
      (q-prepare-integrated-optimality-context
         $structural-result $colimit-result $artifacts)))

(= (q-evaluate-optimality-integration-result
      (OptimalityIntegrationResult Blocked $value $reason))
   (VOptimalityResult Blocked
      ((VConstraintResult
          IntegrationContext Blocked $value $reason))
      $value))
(= (q-evaluate-optimality-integration-result
      (OptimalityIntegrationResult Ready $value $context))
   (q-enriched-optimality-evaluator $context))
