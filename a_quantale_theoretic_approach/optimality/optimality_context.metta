!(import! &self a_quantale_theoretic_approach/optimality/vital_relations)
!(import! &self a_quantale_theoretic_approach/core_representation/v_predicate)

; Raw inputs for one enriched optimality evaluation.
(= (q-optimality-inputs-candidate
      (VOptimalityInputs
         $candidate $vcolimit
         $family-a $family-b $blend-family $correspondences
         $generic-to-a $generic-to-b $map-a $map-b
         $blend-to-a $blend-to-b $property-evidence $relevance-evidence))
   $candidate)

; The shared context stores validated common data and both relation families
; transported into the blend. Topology and Web therefore reuse the same
; companion/conjoint double-coends instead of recomputing them.
;
; (VSharedOptimalityContext
;    Perspective Universe Candidate VColimit
;    SourceFamilyA SourceFamilyB BlendFamily
;    TransportedFamilyA TransportedFamilyB
;    Correspondences GenericToA GenericToB AToBlend BToBlend
;    BlendToA BlendToB PropertyEvidence RelevanceEvidence)

(= (q-context-perspective
      (VSharedOptimalityContext
         $perspective $universe $candidate $vcolimit
         $family-a $family-b $blend-family
         $transported-a $transported-b
         $correspondences $generic-to-a $generic-to-b $map-a $map-b
         $blend-to-a $blend-to-b $property-evidence $relevance-evidence))
   $perspective)

(= (q-context-universe
      (VSharedOptimalityContext
         $perspective $universe $candidate $vcolimit
         $family-a $family-b $blend-family
         $transported-a $transported-b
         $correspondences $generic-to-a $generic-to-b $map-a $map-b
         $blend-to-a $blend-to-b $property-evidence $relevance-evidence))
   $universe)

(= (q-context-candidate
      (VSharedOptimalityContext
         $perspective $universe $candidate $vcolimit
         $family-a $family-b $blend-family
         $transported-a $transported-b
         $correspondences $generic-to-a $generic-to-b $map-a $map-b
         $blend-to-a $blend-to-b $property-evidence $relevance-evidence))
   $candidate)

(= (q-context-vcolimit
      (VSharedOptimalityContext
         $perspective $universe $candidate $vcolimit
         $family-a $family-b $blend-family
         $transported-a $transported-b
         $correspondences $generic-to-a $generic-to-b $map-a $map-b
         $blend-to-a $blend-to-b $property-evidence $relevance-evidence))
   $vcolimit)

(= (q-context-source-family-a
      (VSharedOptimalityContext
         $perspective $universe $candidate $vcolimit
         $family-a $family-b $blend-family
         $transported-a $transported-b
         $correspondences $generic-to-a $generic-to-b $map-a $map-b
         $blend-to-a $blend-to-b $property-evidence $relevance-evidence))
   $family-a)

(= (q-context-source-family-b
      (VSharedOptimalityContext
         $perspective $universe $candidate $vcolimit
         $family-a $family-b $blend-family
         $transported-a $transported-b
         $correspondences $generic-to-a $generic-to-b $map-a $map-b
         $blend-to-a $blend-to-b $property-evidence $relevance-evidence))
   $family-b)

(= (q-context-blend-family
      (VSharedOptimalityContext
         $perspective $universe $candidate $vcolimit
         $family-a $family-b $blend-family
         $transported-a $transported-b
         $correspondences $generic-to-a $generic-to-b $map-a $map-b
         $blend-to-a $blend-to-b $property-evidence $relevance-evidence))
   $blend-family)

(= (q-context-transported-family-a
      (VSharedOptimalityContext
         $perspective $universe $candidate $vcolimit
         $family-a $family-b $blend-family
         $transported-a $transported-b
         $correspondences $generic-to-a $generic-to-b $map-a $map-b
         $blend-to-a $blend-to-b $property-evidence $relevance-evidence))
   $transported-a)

(= (q-context-transported-family-b
      (VSharedOptimalityContext
         $perspective $universe $candidate $vcolimit
         $family-a $family-b $blend-family
         $transported-a $transported-b
         $correspondences $generic-to-a $generic-to-b $map-a $map-b
         $blend-to-a $blend-to-b $property-evidence $relevance-evidence))
   $transported-b)

(= (q-context-valid $context)
   (if (== (q-context-perspective $context) ())
       False
       (if (== (q-context-perspective $context)
               (v-concept-perspective (q-context-candidate $context)))
           (if (vr-family-valid (q-context-source-family-a $context))
               (if (vr-family-valid (q-context-source-family-b $context))
                   (if (vr-family-valid (q-context-blend-family $context))
                       (if (vr-family-valid
                              (q-context-transported-family-a $context))
                           (vr-family-valid
                              (q-context-transported-family-b $context))
                           False)
                       False)
                   False)
               False)
           False)))

(= (q-build-optimality-context
      (VOptimalityInputs
         $candidate $vcolimit
         $family-a $family-b $blend-family $correspondences
         $generic-to-a $generic-to-b $map-a $map-b
         $blend-to-a $blend-to-b $property-evidence $relevance-evidence))
   (let* (
      ($perspective (v-concept-perspective $candidate))
      ($universe (ve-category-universe (vr-family-category $blend-family))))
      (if (== $perspective ())
          (VOptimalityContextError MissingCandidatePerspective)
          (if (vr-family-valid $family-a)
              (if (vr-family-valid $family-b)
                  (if (vr-family-valid $blend-family)
                      (if (== $perspective (vr-family-perspective $family-a))
                          (if (== $perspective (vr-family-perspective $family-b))
                              (if (== $perspective (vr-family-perspective $blend-family))
                                  (if (== (v-world-universe $candidate) $universe)
                                      (if (ve-vmorphism-valid $generic-to-a)
                                          (if (ve-vmorphism-valid $generic-to-b)
                                              (if (== (ve-morphism-source $generic-to-a)
                                                      (ve-morphism-source $generic-to-b))
                                                  (if (== (ve-morphism-target $generic-to-a)
                                                          (vr-family-category $family-a))
                                                      (if (== (ve-morphism-target $generic-to-b)
                                                              (vr-family-category $family-b))
                                                          (if (ve-vmorphism-valid $map-a)
                                                              (if (ve-vmorphism-valid $map-b)
                                                                  (if (== (vr-family-category $family-a)
                                                                          (ve-morphism-source $map-a))
                                                                      (if (== (vr-family-category $family-b)
                                                                              (ve-morphism-source $map-b))
                                                                          (if (== (vr-family-category $blend-family)
                                                                                  (ve-morphism-target $map-a))
                                                                              (if (== (vr-family-category $blend-family)
                                                                                      (ve-morphism-target $map-b))
                                                                                  (let* (
                                                                                     ($transported-a
                                                                                        (vr-pushforward-family
                                                                                           $family-a $map-a))
                                                                                     ($transported-b
                                                                                        (vr-pushforward-family
                                                                                           $family-b $map-b)))
                                                                                     (VSharedOptimalityContext
                                                                                        $perspective $universe
                                                                                        $candidate $vcolimit
                                                                                        $family-a $family-b $blend-family
                                                                                        $transported-a $transported-b
                                                                                        $correspondences
                                                                                        $generic-to-a $generic-to-b
                                                                                        $map-a $map-b
                                                                                        $blend-to-a $blend-to-b
                                                                                        $property-evidence $relevance-evidence))
                                                                                  (VOptimalityContextError SourceBBlendCategoryMismatch))
                                                                              (VOptimalityContextError SourceABlendCategoryMismatch))
                                                                          (VOptimalityContextError SourceBCategoryMismatch))
                                                                      (VOptimalityContextError SourceACategoryMismatch))
                                                                  (VOptimalityContextError InvalidSourceBToBlendMap))
                                                              (VOptimalityContextError InvalidSourceAToBlendMap))
                                                          (VOptimalityContextError GenericToBTargetMismatch))
                                                      (VOptimalityContextError GenericToATargetMismatch))
                                                  (VOptimalityContextError GenericSourceCategoryMismatch))
                                              (VOptimalityContextError InvalidGenericToBMap))
                                          (VOptimalityContextError InvalidGenericToAMap))
                                      (VOptimalityContextError CandidateUniverseMismatch))
                                  (VOptimalityContextError BlendPerspectiveMismatch))
                              (VOptimalityContextError SourceBPerspectiveMismatch))
                          (VOptimalityContextError SourceAPerspectiveMismatch))
                      (VOptimalityContextError InvalidBlendRelationFamily))
                  (VOptimalityContextError InvalidSourceBRelationFamily))
              (VOptimalityContextError InvalidSourceARelationFamily)))))
