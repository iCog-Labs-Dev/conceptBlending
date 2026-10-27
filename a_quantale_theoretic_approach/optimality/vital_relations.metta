!(import! &self a_quantale_theoretic_approach/core_representation/v_enriched)

; Perspective-aware vital relations from paper Definition 4.1.
;
; (VitalRelation Name Perspective Profunctor Provenance)
;
; Profunctor must be an endo-profunctor R : C^op tensor C -> V. Its entries
; contain the possible-world support and scalar degree from paper Equation 23.
; Provenance is deliberately open data, for example:
;   (SourceConcept Boat)
;   (ExtractedFrom knowledge_graph edge_id)

(= (vr-name (VitalRelation $name $perspective $profunctor $provenance))
   $name)

(= (vr-perspective (VitalRelation $name $perspective $profunctor $provenance))
   $perspective)

(= (vr-profunctor (VitalRelation $name $perspective $profunctor $provenance))
   $profunctor)

(= (vr-provenance (VitalRelation $name $perspective $profunctor $provenance))
   $provenance)

(= (vr-source-category $relation)
   (ve-profunctor-source (vr-profunctor $relation)))

(= (vr-target-category $relation)
   (ve-profunctor-target (vr-profunctor $relation)))

(= (vr-value $relation $source-object $target-object)
   (ve-profunctor-value
      (vr-profunctor $relation) $source-object $target-object))

(= (vr-make $name $perspective $category $values $provenance)
   (VitalRelation
      $name $perspective
      (VProfunctor $name $category $category $values)
      $provenance))

(= (vr-valid
      (VitalRelation $name $perspective $profunctor $provenance))
   (if (== $perspective ())
       False
       (if (ve-vprofunctor-valid $profunctor)
           (== (ve-profunctor-source $profunctor)
               (ve-profunctor-target $profunctor))
           False)))

; A family is scoped to exactly one perspective and one enriched category.
; Relation names must be unique within the family.
;
; (VitalRelationFamily Perspective Category Relations)

(= (vr-family-perspective
      (VitalRelationFamily $perspective $category $relations))
   $perspective)

(= (vr-family-category
      (VitalRelationFamily $perspective $category $relations))
   $category)

(= (vr-family-relations
      (VitalRelationFamily $perspective $category $relations))
   $relations)

(= (vr-name-member $name $relations)
   (if (== $relations ())
       False
       (let* (($head (car-atom $relations))
              ($tail (cdr-atom $relations)))
          (if (== $name (vr-name $head))
              True
              (vr-name-member $name $tail)))))

(= (vr-family-relations-valid $relations $perspective $category)
   (if (== $relations ())
       True
       (let* (($head (car-atom $relations))
              ($tail (cdr-atom $relations)))
          (if (vr-valid $head)
              (if (== (vr-perspective $head) $perspective)
                  (if (== (vr-source-category $head) $category)
                      (if (vr-name-member (vr-name $head) $tail)
                          False
                          (vr-family-relations-valid
                             $tail $perspective $category))
                      False)
                  False)
              False))))

(= (vr-family-valid
      (VitalRelationFamily $perspective $category $relations))
   (if (== $perspective ())
       False
       (if (ve-vcategory-valid $category)
           (vr-family-relations-valid
              $relations $perspective $category)
           False)))

(= (vr-family-find $name $relations)
   (if (== $relations ())
       ()
       (let* (($head (car-atom $relations))
              ($tail (cdr-atom $relations)))
          (if (== $name (vr-name $head))
              $head
              (vr-family-find $name $tail)))))

; Double-coend transport from A to C:
;   R_hat_A = M_A^circ tensor_A R_A tensor_A M_A
; where M_A is the companion of the source-to-blend morphism and M_A^circ
; is its conjoint.
(= (vr-pushforward $relation $source-to-blend)
   (if (vr-valid $relation)
       (if (ve-vmorphism-valid $source-to-blend)
           (if (== (vr-source-category $relation)
                   (ve-morphism-source $source-to-blend))
               (let* (
                  ($companion
                     (ve-vmorphism-companion
                        VitalRelationCompanion $source-to-blend))
                  ($conjoint
                     (ve-vmorphism-conjoint
                        VitalRelationConjoint $source-to-blend))
                  ($relation-after-conjoint
                     (ve-vprofunctor-compose
                        VitalRelationFirstCoend
                        $conjoint (vr-profunctor $relation)))
                  ($transported
                     (ve-vprofunctor-compose
                        VitalRelationDoubleCoend
                        $relation-after-conjoint $companion)))
                  (VitalRelation
                     (vr-name $relation)
                     (vr-perspective $relation)
                     $transported
                     (TransportedRelation
                        (vr-provenance $relation)
                        (ve-morphism-name $source-to-blend))))
               (VError RelationMapSourceMismatch))
           (VError InvalidRelationMap))
       (VError InvalidVitalRelation)))

(= (vr-pushforward-relations $relations $source-to-blend)
   (if (== $relations ())
       ()
       (let* (($head (car-atom $relations))
              ($tail (cdr-atom $relations))
              ($transported (vr-pushforward $head $source-to-blend))
              ($transported-tail
                 (vr-pushforward-relations $tail $source-to-blend)))
          (cons-atom $transported $transported-tail))))

(= (vr-pushforward-family
      (VitalRelationFamily $perspective $category $relations)
      $source-to-blend)
   (if (vr-family-valid
          (VitalRelationFamily $perspective $category $relations))
       (if (ve-vmorphism-valid $source-to-blend)
           (if (== $category (ve-morphism-source $source-to-blend))
               (VitalRelationFamily
                  $perspective
                  (ve-morphism-target $source-to-blend)
                  (vr-pushforward-relations
                     $relations $source-to-blend))
               (VError RelationFamilyMapSourceMismatch))
           (VError InvalidRelationFamilyMap))
       (VError InvalidVitalRelationFamily)))

(= (vr-profunctor-row-score
      $source-object $target-objects $expected $actual $universe)
   (if (== $target-objects ())
       (q-unit $universe)
       (let* (($target-object (car-atom $target-objects))
              ($tail (cdr-atom $target-objects))
              ($expected-value
                 (ve-profunctor-value
                    $expected $source-object $target-object))
              ($actual-value
                 (ve-profunctor-value
                    $actual $source-object $target-object))
              ($entry-score
                 (q-residuation
                    $expected-value $actual-value $universe))
              ($tail-score
                 (vr-profunctor-row-score
                    $source-object $tail $expected $actual $universe)))
          (q-meet $entry-score $tail-score))))

(= (vr-profunctor-preservation-score
      $source-objects $target-objects $expected $actual $universe)
   (if (== $source-objects ())
       (q-unit $universe)
       (let* (($source-object (car-atom $source-objects))
              ($tail (cdr-atom $source-objects))
              ($row-score
                 (vr-profunctor-row-score
                    $source-object $target-objects
                    $expected $actual $universe))
              ($tail-score
                 (vr-profunctor-preservation-score
                    $tail $target-objects
                    $expected $actual $universe)))
          (q-meet $row-score $tail-score))))

(= (vr-relation-preservation-score
      $source-relation $blend-relation $source-to-blend)
   (let $transported
      (vr-pushforward $source-relation $source-to-blend)
      (if (vr-valid $transported)
          (if (vr-valid $blend-relation)
              (if (== (vr-name $transported) (vr-name $blend-relation))
                  (if (== (vr-perspective $transported)
                          (vr-perspective $blend-relation))
                      (let* (
                         ($expected (vr-profunctor $transported))
                         ($actual (vr-profunctor $blend-relation))
                         ($category (vr-source-category $transported))
                         ($objects (ve-category-objects $category))
                         ($universe (ve-category-universe $category)))
                         (vr-profunctor-preservation-score
                            $objects $objects
                            $expected $actual $universe))
                      (VError RelationPerspectiveMismatch))
                  (VError RelationNameMismatch))
              (VError InvalidBlendVitalRelation))
          $transported)))

; Compare an already transported relation with its blend counterpart. Shared
; contexts use this form so Topology and Web reuse one double-coend result.
(= (vr-transported-relation-preservation-score
      $transported-relation $blend-relation)
   (if (vr-valid $transported-relation)
       (if (vr-valid $blend-relation)
           (if (== (vr-name $transported-relation)
                   (vr-name $blend-relation))
               (if (== (vr-perspective $transported-relation)
                       (vr-perspective $blend-relation))
                   (if (== (vr-source-category $transported-relation)
                           (vr-source-category $blend-relation))
                       (let* (
                          ($category
                             (vr-source-category $transported-relation))
                          ($objects (ve-category-objects $category))
                          ($universe (ve-category-universe $category)))
                          (vr-profunctor-preservation-score
                             $objects $objects
                             (vr-profunctor $transported-relation)
                             (vr-profunctor $blend-relation)
                             $universe))
                       (VError TransportedRelationCategoryMismatch))
                   (VError RelationPerspectiveMismatch))
               (VError RelationNameMismatch))
           (VError InvalidBlendVitalRelation))
       (VError InvalidTransportedVitalRelation)))

(= (vr-transported-family-preservation-fold
      $transported-relations $blend-relations $universe)
   (if (== $transported-relations ())
       (q-unit $universe)
       (let* (
          ($transported-relation (car-atom $transported-relations))
          ($tail (cdr-atom $transported-relations))
          ($blend-relation
             (vr-family-find
                (vr-name $transported-relation) $blend-relations))
          ($head-score
             (if (== $blend-relation ())
                 (q-bottom)
                 (vr-transported-relation-preservation-score
                    $transported-relation $blend-relation)))
          ($tail-score
             (vr-transported-family-preservation-fold
                $tail $blend-relations $universe)))
          (q-meet $head-score $tail-score))))

(= (vr-transported-family-preservation-score
      (VitalRelationFamily
         $perspective $category $transported-relations)
      (VitalRelationFamily
         $blend-perspective $blend-category $blend-relations))
   (if (== $transported-relations ())
       (VError MissingTransportedVitalRelations)
       (if (== $blend-relations ())
           (VError MissingBlendVitalRelations)
           (if (vr-family-valid
                  (VitalRelationFamily
                     $perspective $category $transported-relations))
               (if (vr-family-valid
                      (VitalRelationFamily
                         $blend-perspective $blend-category
                         $blend-relations))
                   (if (== $perspective $blend-perspective)
                       (if (== $category $blend-category)
                           (vr-transported-family-preservation-fold
                              $transported-relations $blend-relations
                              (ve-category-universe $blend-category))
                           (VError TransportedRelationFamilyCategoryMismatch))
                       (VError RelationFamilyPerspectiveMismatch))
                   (VError InvalidBlendVitalRelationFamily))
               (VError InvalidTransportedVitalRelationFamily)))))

(= (vr-family-preservation-fold
      $source-relations $blend-relations $source-to-blend $universe)
   (if (== $source-relations ())
       (q-unit $universe)
       (let* (($source-relation (car-atom $source-relations))
              ($tail (cdr-atom $source-relations))
              ($blend-relation
                 (vr-family-find
                    (vr-name $source-relation) $blend-relations))
              ($head-score
                 (if (== $blend-relation ())
                     (q-bottom)
                     (vr-relation-preservation-score
                        $source-relation $blend-relation
                        $source-to-blend)))
              ($tail-score
                 (vr-family-preservation-fold
                    $tail $blend-relations $source-to-blend $universe)))
          (q-meet $head-score $tail-score))))

(= (vr-family-preservation-score
      (VitalRelationFamily $source-perspective $source-category $source-relations)
      (VitalRelationFamily $blend-perspective $blend-category $blend-relations)
      $source-to-blend)
   (if (== $source-relations ())
       (VError MissingSourceVitalRelations)
       (if (== $blend-relations ())
           (VError MissingBlendVitalRelations)
           (if (vr-family-valid
                  (VitalRelationFamily
                     $source-perspective $source-category $source-relations))
               (if (vr-family-valid
                      (VitalRelationFamily
                         $blend-perspective $blend-category $blend-relations))
                   (if (== $source-perspective $blend-perspective)
                       (if (== $source-category
                               (ve-morphism-source $source-to-blend))
                           (if (== $blend-category
                                   (ve-morphism-target $source-to-blend))
                               (vr-family-preservation-fold
                                  $source-relations $blend-relations
                                  $source-to-blend
                                  (ve-category-universe $blend-category))
                               (VError BlendRelationCategoryMismatch))
                           (VError SourceRelationCategoryMismatch))
                       (VError RelationFamilyPerspectiveMismatch))
                   (VError InvalidBlendVitalRelationFamily))
               (VError InvalidSourceVitalRelationFamily)))))
