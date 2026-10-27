!(import! &self a_quantale_theoretic_approach/optimality/optimality_context)

; Evidence-aware PeTTa optimality constraints.
;
; (VConstraintResult Name Status Value Evidence)
; Status is Evaluated, Blocked, or Pending. Blocked/Pending results always carry
; bottom rather than the quantale unit, so missing evidence cannot improve Opt.

(= (q-constraint-name
      (VConstraintResult $name $status $value $evidence))
   $name)
(= (q-constraint-status
      (VConstraintResult $name $status $value $evidence))
   $status)
(= (q-constraint-value
      (VConstraintResult $name $status $value $evidence))
   $value)
(= (q-constraint-evidence
      (VConstraintResult $name $status $value $evidence))
   $evidence)

(= (q-constraint-evaluated $name $value $evidence)
   (VConstraintResult $name Evaluated $value $evidence))
(= (q-constraint-blocked $name $universe $reason)
   (VConstraintResult $name Blocked (Q () 0.0) $reason))
(= (q-constraint-pending $name $universe $reason)
   (VConstraintResult $name Pending (Q () 0.0) $reason))

; Integration: the supplied certificate must satisfy cocone validity and the
; relative universal property for its exhaustive comparison scope.
(= (q-vcolimit-integration-op () $universe)
   (q-constraint-blocked Integration $universe MissingVColimitCertificate))
(= (q-vcolimit-integration-op $vcolimit $universe)
   (if (ve-vcolimit-valid $vcolimit)
       (q-constraint-evaluated
          Integration (q-unit $universe)
          (UniversalProperty Verified))
       (q-constraint-evaluated
          Integration (q-bottom)
          (UniversalProperty Violated))))

; Topology: Equation (28), evaluated independently for both source families
; after exact double-coend transport through their blend maps.
(= (q-topology-op
      $source-family-a $source-family-b $blend-family
      $source-a-to-blend $source-b-to-blend)
   (let $universe
      (ve-category-universe (vr-family-category $blend-family))
      (if (vr-family-valid $source-family-a)
          (if (vr-family-valid $source-family-b)
              (if (vr-family-valid $blend-family)
                  (if (ve-vmorphism-valid $source-a-to-blend)
                      (if (ve-vmorphism-valid $source-b-to-blend)
                          (if (== (vr-family-relations $source-family-a) ())
                              (q-constraint-blocked Topology $universe MissingSourceARelations)
                              (if (== (vr-family-relations $source-family-b) ())
                                  (q-constraint-blocked Topology $universe MissingSourceBRelations)
                                  (if (== (vr-family-relations $blend-family) ())
                                      (q-constraint-blocked Topology $universe MissingBlendRelations)
                                      (let* (
                                         ($score-a
                                            (vr-family-preservation-score
                                               $source-family-a $blend-family
                                               $source-a-to-blend))
                                         ($score-b
                                            (vr-family-preservation-score
                                               $source-family-b $blend-family
                                               $source-b-to-blend))
                                         ($score (q-meet $score-a $score-b)))
                                         (q-constraint-evaluated
                                            Topology $score
                                            (DoubleCoendPreservation
                                               (SourceA $score-a) (SourceB $score-b)))))))
                          (q-constraint-blocked Topology $universe InvalidOrMissingSourceBHomMap))
                      (q-constraint-blocked Topology $universe InvalidOrMissingSourceAHomMap))
                  (q-constraint-blocked Topology $universe InvalidOrMissingBlendHoms))
              (q-constraint-blocked Topology $universe InvalidOrMissingSourceBHoms))
          (q-constraint-blocked Topology $universe InvalidOrMissingSourceAHoms))))

(= (q-topology-transported-op
      $transported-family-a $transported-family-b $blend-family)
   (let $universe
      (ve-category-universe (vr-family-category $blend-family))
      (if (vr-family-valid $transported-family-a)
          (if (vr-family-valid $transported-family-b)
              (if (vr-family-valid $blend-family)
                  (if (== (vr-family-relations $transported-family-a) ())
                      (q-constraint-blocked Topology $universe MissingSourceARelations)
                      (if (== (vr-family-relations $transported-family-b) ())
                          (q-constraint-blocked Topology $universe MissingSourceBRelations)
                          (if (== (vr-family-relations $blend-family) ())
                              (q-constraint-blocked Topology $universe MissingBlendRelations)
                              (let* (
                                 ($score-a
                                    (vr-transported-family-preservation-score
                                       $transported-family-a $blend-family))
                                 ($score-b
                                    (vr-transported-family-preservation-score
                                       $transported-family-b $blend-family))
                                 ($score (q-meet $score-a $score-b)))
                                 (q-constraint-evaluated
                                    Topology $score
                                    (CachedDoubleCoendPreservation
                                       (SourceA $score-a)
                                       (SourceB $score-b)))))))
                  (q-constraint-blocked Topology $universe InvalidOrMissingBlendHoms))
              (q-constraint-blocked Topology $universe InvalidTransportedSourceBHoms))
          (q-constraint-blocked Topology $universe InvalidTransportedSourceAHoms))))

; Web correspondence input:
; (VitalRelationCorrespondence Name RelationA RelationB BlendRelation WeightQ)
(= (q-web-correspondence-name
      (VitalRelationCorrespondence $name $a $b $blend $weight))
   $name)
(= (q-web-correspondence-a
      (VitalRelationCorrespondence $name $a $b $blend $weight))
   $a)
(= (q-web-correspondence-b
      (VitalRelationCorrespondence $name $a $b $blend $weight))
   $b)
(= (q-web-correspondence-blend
      (VitalRelationCorrespondence $name $a $b $blend $weight))
   $blend)
(= (q-web-correspondence-weight
      (VitalRelationCorrespondence $name $a $b $blend $weight))
   $weight)

(= (q-transported-relation-score $source-relation $blend-relation $map)
   (let* (
      ($transported (vr-pushforward $source-relation $map))
      ($expected (vr-profunctor $transported))
      ($actual (vr-profunctor $blend-relation))
      ($category (vr-source-category $blend-relation))
      ($objects (ve-category-objects $category))
      ($universe (ve-category-universe $category)))
      (vr-profunctor-preservation-score
         $objects $objects $expected $actual $universe)))

(= (q-web-fold
      $correspondences $relations-a $relations-b $blend-relations
      $map-a $map-b $universe)
   (if (== $correspondences ())
       (q-unit $universe)
       (let* (
          ($head (car-atom $correspondences))
          ($tail (cdr-atom $correspondences))
          ($relation-a
             (vr-family-find
                (q-web-correspondence-a $head) $relations-a))
          ($relation-b
             (vr-family-find
                (q-web-correspondence-b $head) $relations-b))
          ($blend-relation
             (vr-family-find
                (q-web-correspondence-blend $head) $blend-relations))
          ($head-score
             (if (== $relation-a ())
                 (q-bottom)
                 (if (== $relation-b ())
                     (q-bottom)
                     (if (== $blend-relation ())
                         (q-bottom)
                         (q-tensor
                            (q-web-correspondence-weight $head)
                            (q-meet
                               (q-transported-relation-score
                                  $relation-a $blend-relation $map-a)
                               (q-transported-relation-score
                                  $relation-b $blend-relation $map-b)))))))
          ($tail-score
             (q-web-fold
                $tail $relations-a $relations-b $blend-relations
                $map-a $map-b $universe)))
          (q-meet $head-score $tail-score))))

(= (q-web-op
      $correspondences $source-family-a $source-family-b $blend-family
      $source-a-to-blend $source-b-to-blend)
   (let $universe
      (ve-category-universe (vr-family-category $blend-family))
      (if (== $correspondences ())
          (q-constraint-blocked Web $universe MissingCrossSpaceCorrespondences)
          (if (vr-family-valid $source-family-a)
              (if (vr-family-valid $source-family-b)
                  (if (vr-family-valid $blend-family)
                      (if (ve-vmorphism-valid $source-a-to-blend)
                          (if (ve-vmorphism-valid $source-b-to-blend)
                              (q-constraint-evaluated
                                 Web
                                 (q-web-fold
                                    $correspondences
                                    (vr-family-relations $source-family-a)
                                    (vr-family-relations $source-family-b)
                                    (vr-family-relations $blend-family)
                                    $source-a-to-blend $source-b-to-blend $universe)
                                 (CrossSpaceCorrespondences $correspondences))
                              (q-constraint-blocked Web $universe InvalidOrMissingSourceBHomMap))
                          (q-constraint-blocked Web $universe InvalidOrMissingSourceAHomMap))
                      (q-constraint-blocked Web $universe InvalidOrMissingBlendHoms))
                  (q-constraint-blocked Web $universe InvalidOrMissingSourceBHoms))
              (q-constraint-blocked Web $universe InvalidOrMissingSourceAHoms)))))

(= (q-web-transported-fold
      $correspondences $transported-relations-a $transported-relations-b
      $blend-relations $universe)
   (if (== $correspondences ())
       (q-unit $universe)
       (let* (
          ($head (car-atom $correspondences))
          ($tail (cdr-atom $correspondences))
          ($relation-a
             (vr-family-find
                (q-web-correspondence-a $head)
                $transported-relations-a))
          ($relation-b
             (vr-family-find
                (q-web-correspondence-b $head)
                $transported-relations-b))
          ($blend-relation
             (vr-family-find
                (q-web-correspondence-blend $head) $blend-relations))
          ($head-score
             (if (== $relation-a ())
                 (q-bottom)
                 (if (== $relation-b ())
                     (q-bottom)
                     (if (== $blend-relation ())
                         (q-bottom)
                         (q-tensor
                            (q-web-correspondence-weight $head)
                            (q-meet
                               (vr-transported-relation-preservation-score
                                  $relation-a $blend-relation)
                               (vr-transported-relation-preservation-score
                                  $relation-b $blend-relation)))))))
          ($tail-score
             (q-web-transported-fold
                $tail $transported-relations-a $transported-relations-b
                $blend-relations $universe)))
          (q-meet $head-score $tail-score))))

(= (q-web-transported-op
      $correspondences $transported-family-a $transported-family-b
      $blend-family)
   (let $universe
      (ve-category-universe (vr-family-category $blend-family))
      (if (== $correspondences ())
          (q-constraint-blocked Web $universe MissingCrossSpaceCorrespondences)
          (if (vr-family-valid $transported-family-a)
              (if (vr-family-valid $transported-family-b)
                  (if (vr-family-valid $blend-family)
                      (q-constraint-evaluated
                         Web
                         (q-web-transported-fold
                            $correspondences
                            (vr-family-relations $transported-family-a)
                            (vr-family-relations $transported-family-b)
                            (vr-family-relations $blend-family)
                            $universe)
                         (CachedCrossSpaceCorrespondences
                            $correspondences))
                      (q-constraint-blocked Web $universe InvalidOrMissingBlendHoms))
                  (q-constraint-blocked Web $universe InvalidTransportedSourceBHoms))
              (q-constraint-blocked Web $universe InvalidTransportedSourceAHoms)))))

; Unpacking: explicit C -> A/B reconstruction morphisms. The score is the
; enriched equivalence of each source object and its reconstructed image.
(= (q-split-object-score $object $forward $reverse $category $universe)
   (let $reconstructed
      (ve-map-object $reverse (ve-map-object $forward $object))
      (q-meet
         (ve-category-hom $category $object $reconstructed)
         (ve-category-hom $category $reconstructed $object))))

(= (q-split-objects-score $objects $forward $reverse $category $universe)
   (if (== $objects ())
       (q-unit $universe)
       (let* (($object (car-atom $objects))
              ($tail (cdr-atom $objects))
              ($head-score
                 (q-split-object-score
                    $object $forward $reverse $category $universe))
              ($tail-score
                 (q-split-objects-score
                    $tail $forward $reverse $category $universe)))
          (q-meet $head-score $tail-score))))

(= (q-split-morphism-score $forward $reverse)
   (let* (($source (ve-morphism-source $forward))
          ($universe (ve-category-universe $source)))
      (if (ve-vmorphism-valid $forward)
          (if (ve-vmorphism-valid $reverse)
              (if (== (ve-morphism-target $forward)
                      (ve-morphism-source $reverse))
                  (if (== $source (ve-morphism-target $reverse))
                      (q-split-objects-score
                         (ve-category-objects $source)
                         $forward $reverse $source $universe)
                      (q-bottom))
                  (q-bottom))
              (q-bottom))
          (q-bottom))))

(= (q-unpacking-op
      $source-a-to-blend $blend-to-source-a
      $source-b-to-blend $blend-to-source-b $universe)
   (if (== $source-a-to-blend ())
       (q-constraint-blocked Unpacking $universe MissingSourceAHomMap)
       (if (== $source-b-to-blend ())
           (q-constraint-blocked Unpacking $universe MissingSourceBHomMap)
           (if (== $blend-to-source-a ())
               (q-constraint-blocked Unpacking $universe MissingSourceAReconstruction)
               (if (== $blend-to-source-b ())
                   (q-constraint-blocked Unpacking $universe MissingSourceBReconstruction)
                   (if (ve-vmorphism-valid $source-a-to-blend)
                       (if (ve-vmorphism-valid $source-b-to-blend)
                           (if (ve-vmorphism-valid $blend-to-source-a)
                               (if (ve-vmorphism-valid $blend-to-source-b)
                                   (let* (
                                      ($score-a
                                         (q-split-morphism-score
                                            $source-a-to-blend $blend-to-source-a))
                                      ($score-b
                                         (q-split-morphism-score
                                            $source-b-to-blend $blend-to-source-b))
                                      ($score (q-join $score-a $score-b)))
                                      (q-constraint-evaluated
                                         Unpacking $score
                                         (VSplit (SourceA $score-a) (SourceB $score-b))))
                                   (q-constraint-blocked Unpacking $universe InvalidSourceBReconstruction))
                               (q-constraint-blocked Unpacking $universe InvalidSourceAReconstruction))
                           (q-constraint-blocked Unpacking $universe InvalidSourceBHomMap))
                       (q-constraint-blocked Unpacking $universe InvalidSourceAHomMap)))))))

; Good Reason evidence:
; (PropertyEvidence PropertyName SupportQ Provenance)
(= (q-property-evidence-find $name $evidence)
   (if (== $evidence ())
       ()
       (let* (($head (car-atom $evidence))
              ($tail (cdr-atom $evidence))
              ((PropertyEvidence $head-name $support $provenance) $head))
          (if (== $name $head-name)
              $head
              (q-property-evidence-find $name $tail)))))

(= (q-property-evidence-valid $evidence $universe)
   (if (== $evidence ())
       True
       (let* (($head (car-atom $evidence))
              ($tail (cdr-atom $evidence))
              ((PropertyEvidence $name $support $provenance) $head))
          (if (== $provenance ())
              False
              (if (q-value-in-universe $support $universe)
                  (q-property-evidence-valid $tail $universe)
                  False)))))

(= (q-good-reason-fold $properties $evidence $universe)
   (if (== $properties ())
       (q-unit $universe)
       (let* (($property (car-atom $properties))
              ($tail (cdr-atom $properties))
              ($entry
                 (q-property-evidence-find
                    (v-property-name $property) $evidence))
              ($head-score
                 (if (== $entry ())
                     (q-bottom)
                     (let (PropertyEvidence $name $support $provenance) $entry
                        (q-residuation
                           (v-property-quantale $property)
                           $support $universe))))
              ($tail-score
                 (q-good-reason-fold $tail $evidence $universe)))
          (q-meet $head-score $tail-score))))

(= (q-good-reason-provenance-op $candidate $evidence)
   (let $universe (v-world-universe $candidate)
      (if (== $evidence ())
          (q-constraint-blocked GoodReason $universe MissingPropertyProvenance)
          (if (q-property-evidence-valid $evidence $universe)
              (q-constraint-evaluated
                 GoodReason
                 (q-good-reason-fold
                    (v-property-list $candidate) $evidence $universe)
                 (TraceableProvenance $evidence))
              (q-constraint-blocked GoodReason $universe InvalidPropertyProvenance)))))

; Metonymic tightening, paper Equations (34)-(35). For each g, a, and b,
; compare R_C(i_A a,i_B b) with R_A(a,sigma_A g) tensor R_B(sigma_B g,b).
(= (q-tightening-b-score
      $a $generic-image-a $b-objects $generic-image-b
      $relation-a $relation-b $blend-relation
      $map-a $map-b $universe)
   (if (== $b-objects ())
       (q-unit $universe)
       (let* (($b (car-atom $b-objects))
              ($tail (cdr-atom $b-objects))
              ($expected
                 (q-tensor
                    (vr-value $relation-a $a $generic-image-a)
                    (vr-value $relation-b $generic-image-b $b)))
              ($actual
                 (vr-value $blend-relation
                    (ve-map-object $map-a $a)
                    (ve-map-object $map-b $b)))
              ($head-score
                 (q-residuation $expected $actual $universe))
              ($tail-score
                 (q-tightening-b-score
                    $a $generic-image-a $tail $generic-image-b
                    $relation-a $relation-b $blend-relation
                    $map-a $map-b $universe)))
          (q-meet $head-score $tail-score))))

(= (q-tightening-a-score
      $a-objects $generic-image-a $b-objects $generic-image-b
      $relation-a $relation-b $blend-relation
      $map-a $map-b $universe)
   (if (== $a-objects ())
       (q-unit $universe)
       (let* (($a (car-atom $a-objects))
              ($tail (cdr-atom $a-objects))
              ($head-score
                 (q-tightening-b-score
                    $a $generic-image-a $b-objects $generic-image-b
                    $relation-a $relation-b $blend-relation
                    $map-a $map-b $universe))
              ($tail-score
                 (q-tightening-a-score
                    $tail $generic-image-a $b-objects $generic-image-b
                    $relation-a $relation-b $blend-relation
                    $map-a $map-b $universe)))
          (q-meet $head-score $tail-score))))

(= (q-tightening-g-score
      $generic-objects $a-objects $b-objects
      $relation-a $relation-b $blend-relation
      $generic-to-a $generic-to-b $map-a $map-b $universe)
   (if (== $generic-objects ())
       (q-unit $universe)
       (let* (($g (car-atom $generic-objects))
              ($tail (cdr-atom $generic-objects))
              ($head-score
                 (q-tightening-a-score
                    $a-objects (ve-map-object $generic-to-a $g)
                    $b-objects (ve-map-object $generic-to-b $g)
                    $relation-a $relation-b $blend-relation
                    $map-a $map-b $universe))
              ($tail-score
                 (q-tightening-g-score
                    $tail $a-objects $b-objects
                    $relation-a $relation-b $blend-relation
                    $generic-to-a $generic-to-b $map-a $map-b $universe)))
          (q-meet $head-score $tail-score))))

(= (q-tightening-relations-fold
      $relations-a $relations-b $blend-relations
      $generic-to-a $generic-to-b $map-a $map-b $universe)
   (if (== $relations-a ())
       (q-unit $universe)
       (let* (($relation-a (car-atom $relations-a))
              ($tail (cdr-atom $relations-a))
              ($relation-b
                 (vr-family-find (vr-name $relation-a) $relations-b))
              ($blend-relation
                 (vr-family-find (vr-name $relation-a) $blend-relations))
              ($head-score
                 (if (== $relation-b ())
                     (q-bottom)
                     (if (== $blend-relation ())
                         (q-bottom)
                         (q-tightening-g-score
                            (ve-category-objects
                               (ve-morphism-source $generic-to-a))
                            (ve-category-objects
                               (ve-morphism-target $generic-to-a))
                            (ve-category-objects
                               (ve-morphism-target $generic-to-b))
                            $relation-a $relation-b $blend-relation
                            $generic-to-a $generic-to-b
                            $map-a $map-b $universe))))
              ($tail-score
                 (q-tightening-relations-fold
                    $tail $relations-b $blend-relations
                    $generic-to-a $generic-to-b
                    $map-a $map-b $universe)))
          (q-meet $head-score $tail-score))))

(= (q-metonymic-tightening-op
      $source-family-a $source-family-b $blend-family
      $generic-to-a $generic-to-b $map-a $map-b)
   (let $universe
      (ve-category-universe (vr-family-category $blend-family))
      (if (vr-family-valid $source-family-a)
          (if (vr-family-valid $source-family-b)
              (if (vr-family-valid $blend-family)
                  (if (ve-vmorphism-valid $generic-to-a)
                      (if (ve-vmorphism-valid $generic-to-b)
                          (if (ve-vmorphism-valid $map-a)
                              (if (ve-vmorphism-valid $map-b)
                                  (if (== (vr-family-relations $source-family-a) ())
                                      (q-constraint-blocked MetonymicTightening $universe MissingSourceRelations)
                                      (if (== (vr-family-relations $blend-family) ())
                                          (q-constraint-blocked MetonymicTightening $universe MissingBlendRelations)
                                          (q-constraint-evaluated
                                             MetonymicTightening
                                             (q-tightening-relations-fold
                                                (vr-family-relations $source-family-a)
                                                (vr-family-relations $source-family-b)
                                                (vr-family-relations $blend-family)
                                                $generic-to-a $generic-to-b $map-a $map-b $universe)
                                             (GenericMediatedRelationPaths))))
                                  (q-constraint-blocked MetonymicTightening $universe InvalidSourceBHomMap))
                              (q-constraint-blocked MetonymicTightening $universe InvalidSourceAHomMap))
                          (q-constraint-blocked MetonymicTightening $universe InvalidGenericToBMap))
                      (q-constraint-blocked MetonymicTightening $universe InvalidGenericToAMap))
                  (q-constraint-blocked MetonymicTightening $universe InvalidOrMissingBlendHoms))
              (q-constraint-blocked MetonymicTightening $universe InvalidOrMissingSourceBHoms))
          (q-constraint-blocked MetonymicTightening $universe InvalidOrMissingSourceAHoms))))

; Relevance consumes already computed evidence, never missing placeholders.
; (RelevantEvidence Label ValueQ WeightQ)
(= (q-relevance-evidence-fold $evidence $universe)
   (if (== $evidence ())
       (q-bottom)
       (let* (($head (car-atom $evidence))
              ($tail (cdr-atom $evidence))
              ((RelevantEvidence $label $value $weight) $head)
              ($head-score (q-tensor $weight $value))
              ($tail-score
                 (q-relevance-evidence-fold $tail $universe)))
          (q-join $head-score $tail-score))))

(= (q-relevance-evidence-valid $evidence $universe)
   (if (== $evidence ())
       True
       (let* (($head (car-atom $evidence))
              ($tail (cdr-atom $evidence))
              ((RelevantEvidence $label $value $weight) $head))
          (if (q-value-in-universe $value $universe)
              (if (q-value-in-universe $weight $universe)
                  (q-relevance-evidence-valid $tail $universe)
                  False)
              False))))

(= (q-relevance-evidence-op $evidence $universe)
   (if (== $evidence ())
       (q-constraint-blocked Relevance $universe MissingRelevanceEvidence)
       (if (q-relevance-evidence-valid $evidence $universe)
           (q-constraint-evaluated
              Relevance
              (q-relevance-evidence-fold $evidence $universe)
              (WeightedEvidence $evidence))
           (q-constraint-blocked Relevance $universe InvalidRelevanceEvidence))))

(= (q-results-ready $results)
   (if (== $results ())
       True
       (if (== (q-constraint-status (car-atom $results)) Evaluated)
           (q-results-ready (cdr-atom $results))
           False)))

(= (q-results-product $results $universe)
   (if (== $results ())
       (q-unit $universe)
       (q-tensor
          (q-constraint-value (car-atom $results))
          (q-results-product (cdr-atom $results) $universe))))

; Paper Equation (36) has six factors. Topology and Web remain separate
; diagnostics, but jointly form the single vital-relation-coherence factor.
(= (q-six-constraint-product
      ($integration $topology $web $unpacking
       $good-reason $tightening $relevance))
   (q-tensor
      (q-constraint-value $integration)
      (q-tensor
         (q-meet
            (q-constraint-value $topology)
            (q-constraint-value $web))
         (q-tensor
            (q-constraint-value $unpacking)
            (q-tensor
               (q-constraint-value $good-reason)
               (q-tensor
                  (q-constraint-value $tightening)
                  (q-constraint-value $relevance)))))))

; Backward-compatible input spelling. It is normalized through the shared
; context builder before any constraint runs.
(= (q-enriched-optimality-evaluator
      (VOptimalityContext
         $candidate $vcolimit
         $source-family-a $source-family-b $blend-family
         $correspondences
         $generic-to-a $generic-to-b $map-a $map-b
         $blend-to-a $blend-to-b
         $property-evidence $relevance-evidence))
   (q-enriched-optimality-evaluator
      (VOptimalityInputs
         $candidate $vcolimit
         $source-family-a $source-family-b $blend-family
         $correspondences
         $generic-to-a $generic-to-b $map-a $map-b
         $blend-to-a $blend-to-b
         $property-evidence $relevance-evidence)))

(= (q-enriched-optimality-evaluator
      (VOptimalityInputs
         $candidate $vcolimit
         $source-family-a $source-family-b $blend-family
         $correspondences
         $generic-to-a $generic-to-b $map-a $map-b
         $blend-to-a $blend-to-b
         $property-evidence $relevance-evidence))
   (q-evaluate-built-optimality-context
      (q-build-optimality-context
         (VOptimalityInputs
            $candidate $vcolimit
            $source-family-a $source-family-b $blend-family
            $correspondences
            $generic-to-a $generic-to-b $map-a $map-b
            $blend-to-a $blend-to-b
            $property-evidence $relevance-evidence))))

(= (q-evaluate-built-optimality-context
      (VOptimalityContextError $reason))
   (VOptimalityResult Blocked
      ((VConstraintResult
          Context Blocked (q-bottom)
          (InvalidOptimalityContext $reason)))
      (q-bottom)))

(= (q-evaluate-built-optimality-context
      (VSharedOptimalityContext
         $perspective $universe $candidate $vcolimit
         $source-family-a $source-family-b $blend-family
         $transported-family-a $transported-family-b
         $correspondences
         $generic-to-a $generic-to-b $map-a $map-b
         $blend-to-a $blend-to-b
         $property-evidence $relevance-evidence))
   (q-enriched-optimality-evaluator
      (VSharedOptimalityContext
         $perspective $universe $candidate $vcolimit
         $source-family-a $source-family-b $blend-family
         $transported-family-a $transported-family-b
         $correspondences
         $generic-to-a $generic-to-b $map-a $map-b
         $blend-to-a $blend-to-b
         $property-evidence $relevance-evidence)))

(= (q-enriched-optimality-evaluator
      (VSharedOptimalityContext
         $perspective $universe $candidate $vcolimit
         $source-family-a $source-family-b $blend-family
         $transported-family-a $transported-family-b
         $correspondences
         $generic-to-a $generic-to-b $map-a $map-b
         $blend-to-a $blend-to-b
         $property-evidence $relevance-evidence))
   (let* (
      ($integration
         (q-vcolimit-integration-op $vcolimit $universe))
      ($topology
         (q-topology-transported-op
            $transported-family-a $transported-family-b $blend-family))
      ($web
         (q-web-transported-op
            $correspondences
            $transported-family-a $transported-family-b $blend-family))
      ($unpacking
         (q-unpacking-op
            $map-a $blend-to-a $map-b $blend-to-b $universe))
      ($good-reason
         (q-good-reason-provenance-op
            $candidate $property-evidence))
      ($tightening
         (q-metonymic-tightening-op
            $source-family-a $source-family-b $blend-family
            $generic-to-a $generic-to-b $map-a $map-b))
      ($relevance
         (q-relevance-evidence-op $relevance-evidence $universe))
      ($results
         ($integration $topology $web $unpacking
          $good-reason $tightening $relevance)))
      (if (q-results-ready $results)
          (VOptimalityResult Evaluated $results
             (q-six-constraint-product $results))
          (VOptimalityResult Blocked $results (q-bottom)))))
