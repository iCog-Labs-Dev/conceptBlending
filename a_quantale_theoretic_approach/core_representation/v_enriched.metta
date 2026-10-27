!(import! &self a_quantale_theoretic_approach/core_representation/quantale_types)

; Explicit Q-enriched structures.
;
; (VCategory Name Universe Objects Homs)
;   Homs: ((Source Target (Q Worlds Degree)) ...)
;
; (VMorphism Name SourceCategory TargetCategory ObjectMap)
;   ObjectMap: ((SourceObject TargetObject) ...)
;
; (VCocone Name GenericToLeft GenericToRight LeftToApex RightToApex)
;
; (VProfunctor Name SourceCategory TargetCategory Values)
;   Values: ((SourceObject TargetObject (Q Worlds Degree)) ...)

(= (ve-category-name (VCategory $name $universe $objects $homs)) $name)
(= (ve-category-universe (VCategory $name $universe $objects $homs)) $universe)
(= (ve-category-objects (VCategory $name $universe $objects $homs)) $objects)
(= (ve-category-homs (VCategory $name $universe $objects $homs)) $homs)

(= (ve-morphism-name (VMorphism $name $source $target $object-map)) $name)
(= (ve-morphism-source (VMorphism $name $source $target $object-map)) $source)
(= (ve-morphism-target (VMorphism $name $source $target $object-map)) $target)
(= (ve-morphism-object-map (VMorphism $name $source $target $object-map)) $object-map)

(= (ve-cocone-name
      (VCocone $name $generic-to-left $generic-to-right $left-to-apex $right-to-apex))
   $name)
(= (ve-cocone-generic-to-left
      (VCocone $name $generic-to-left $generic-to-right $left-to-apex $right-to-apex))
   $generic-to-left)
(= (ve-cocone-generic-to-right
      (VCocone $name $generic-to-left $generic-to-right $left-to-apex $right-to-apex))
   $generic-to-right)
(= (ve-cocone-left-to-apex
      (VCocone $name $generic-to-left $generic-to-right $left-to-apex $right-to-apex))
   $left-to-apex)
(= (ve-cocone-right-to-apex
      (VCocone $name $generic-to-left $generic-to-right $left-to-apex $right-to-apex))
   $right-to-apex)
(= (ve-cocone-apex $cocone)
   (ve-morphism-target (ve-cocone-left-to-apex $cocone)))

(= (ve-profunctor-name (VProfunctor $name $source $target $values)) $name)
(= (ve-profunctor-source (VProfunctor $name $source $target $values)) $source)
(= (ve-profunctor-target (VProfunctor $name $source $target $values)) $target)
(= (ve-profunctor-values (VProfunctor $name $source $target $values)) $values)

(= (ve-object-member $object $objects)
   (q-list-member $object $objects))

(= (ve-list-unique $items)
   (if (== $items ())
       True
       (let* (($head (car-atom $items))
              ($tail (cdr-atom $items)))
          (if (q-list-member $head $tail)
              False
              (ve-list-unique $tail)))))

(= (ve-q-entry-pair-exists $source-object $target-object $entries)
   (if (== $entries ())
       False
       (let* (($head (car-atom $entries))
              ($tail (cdr-atom $entries)))
          (if (== $source-object (index-atom $head 0))
              (if (== $target-object (index-atom $head 1))
                  True
                  (ve-q-entry-pair-exists $source-object $target-object $tail))
              (ve-q-entry-pair-exists $source-object $target-object $tail)))))

(= (ve-find-q-entry $source-object $target-object $entries)
   (if (== $entries ())
       (q-bottom)
       (let* (($head (car-atom $entries))
              ($tail (cdr-atom $entries))
              ($head-source (index-atom $head 0))
              ($head-target (index-atom $head 1)))
          (if (== $source-object $head-source)
              (if (== $target-object $head-target)
                  (index-atom $head 2)
                  (ve-find-q-entry $source-object $target-object $tail))
              (ve-find-q-entry $source-object $target-object $tail)))))

(= (ve-category-hom $category $source-object $target-object)
   (ve-find-q-entry $source-object $target-object (ve-category-homs $category)))

(= (ve-category-homs-well-formed $homs $objects $universe)
   (if (== $homs ())
       True
       (let* (($head (car-atom $homs))
              ($tail (cdr-atom $homs))
              ($source-object (index-atom $head 0))
              ($target-object (index-atom $head 1))
              ($value (index-atom $head 2)))
          (if (ve-object-member $source-object $objects)
              (if (ve-object-member $target-object $objects)
                  (if (q-value-in-universe $value $universe)
                      (if (ve-q-entry-pair-exists $source-object $target-object $tail)
                          False
                          (ve-category-homs-well-formed $tail $objects $universe))
                      False)
                  False)
              False))))

(= (ve-category-identities-valid $objects $category)
   (if (== $objects ())
       True
       (let* (($object (car-atom $objects))
              ($tail (cdr-atom $objects))
              ($unit (q-unit (ve-category-universe $category)))
              ($self-hom (ve-category-hom $category $object $object)))
          (if (q-less-eq $unit $self-hom)
              (ve-category-identities-valid $tail $category)
              False))))

(= (ve-category-composition-targets-valid $source $middle $targets $category)
   (if (== $targets ())
       True
       (let* (($target (car-atom $targets))
              ($tail (cdr-atom $targets))
              ($composite (q-tensor
                 (ve-category-hom $category $middle $target)
                 (ve-category-hom $category $source $middle)))
              ($bound (ve-category-hom $category $source $target)))
          (if (q-less-eq $composite $bound)
              (ve-category-composition-targets-valid $source $middle $tail $category)
              False))))

(= (ve-category-composition-middles-valid $source $middles $objects $category)
   (if (== $middles ())
       True
       (let* (($middle (car-atom $middles))
              ($tail (cdr-atom $middles)))
          (if (ve-category-composition-targets-valid $source $middle $objects $category)
              (ve-category-composition-middles-valid $source $tail $objects $category)
              False))))

(= (ve-category-composition-sources-valid $sources $objects $category)
   (if (== $sources ())
       True
       (let* (($source (car-atom $sources))
              ($tail (cdr-atom $sources)))
          (if (ve-category-composition-middles-valid $source $objects $objects $category)
              (ve-category-composition-sources-valid $tail $objects $category)
              False))))

(= (ve-vcategory-valid $category)
   (let* (($objects (ve-category-objects $category))
          ($universe (ve-category-universe $category))
          ($homs (ve-category-homs $category)))
      (if (ve-category-homs-well-formed $homs $objects $universe)
          (if (ve-list-unique $objects)
              (if (ve-category-identities-valid $objects $category)
                  (ve-category-composition-sources-valid $objects $objects $category)
                  False)
              False)
          False)))

(= (ve-map-object-from-entries $object $object-map)
   (if (== $object-map ())
       ()
       (let* (($head (car-atom $object-map))
              ($tail (cdr-atom $object-map)))
          (if (== $object (index-atom $head 0))
              (index-atom $head 1)
              (ve-map-object-from-entries $object $tail)))))

(= (ve-map-object $morphism $object)
   (ve-map-object-from-entries $object (ve-morphism-object-map $morphism)))

(= (ve-map-source-exists $source-object $object-map)
   (if (== $object-map ())
       False
       (let* (($head (car-atom $object-map))
              ($tail (cdr-atom $object-map)))
          (if (== $source-object (index-atom $head 0))
              True
              (ve-map-source-exists $source-object $tail)))))

(= (ve-morphism-entries-well-formed $object-map $source-objects $target-objects)
   (if (== $object-map ())
       True
       (let* (($head (car-atom $object-map))
              ($tail (cdr-atom $object-map))
              ($source-object (index-atom $head 0))
              ($target-object (index-atom $head 1)))
          (if (ve-object-member $source-object $source-objects)
              (if (ve-object-member $target-object $target-objects)
                  (if (ve-map-source-exists $source-object $tail)
                      False
                      (ve-morphism-entries-well-formed $tail $source-objects $target-objects))
                  False)
              False))))

(= (ve-morphism-map-valid $objects $morphism)
   (if (== $objects ())
       True
       (let* (($object (car-atom $objects))
              ($tail (cdr-atom $objects))
              ($image (ve-map-object $morphism $object))
              ($target-objects (ve-category-objects (ve-morphism-target $morphism))))
          (if (== $image ())
              False
              (if (ve-object-member $image $target-objects)
                  (ve-morphism-map-valid $tail $morphism)
                  False)))))

(= (ve-morphism-targets-valid $source-object $target-objects $morphism)
   (if (== $target-objects ())
       True
       (let* (($target-object (car-atom $target-objects))
              ($tail (cdr-atom $target-objects))
              ($source-category (ve-morphism-source $morphism))
              ($target-category (ve-morphism-target $morphism))
              ($source-hom (ve-category-hom $source-category $source-object $target-object))
              ($target-hom (ve-category-hom $target-category
                 (ve-map-object $morphism $source-object)
                 (ve-map-object $morphism $target-object))))
          (if (q-less-eq $source-hom $target-hom)
              (ve-morphism-targets-valid $source-object $tail $morphism)
              False))))

(= (ve-morphism-sources-valid $source-objects $objects $morphism)
   (if (== $source-objects ())
       True
       (let* (($source-object (car-atom $source-objects))
              ($tail (cdr-atom $source-objects)))
          (if (ve-morphism-targets-valid $source-object $objects $morphism)
              (ve-morphism-sources-valid $tail $objects $morphism)
              False))))

(= (ve-vmorphism-valid $morphism)
   (let* (($source (ve-morphism-source $morphism))
          ($target (ve-morphism-target $morphism))
          ($objects (ve-category-objects $source))
          ($target-objects (ve-category-objects $target)))
      (if (ve-vcategory-valid $source)
          (if (ve-vcategory-valid $target)
              (if (== (ve-category-universe $source) (ve-category-universe $target))
                  (if (ve-morphism-entries-well-formed
                         (ve-morphism-object-map $morphism) $objects $target-objects)
                      (if (ve-morphism-map-valid $objects $morphism)
                          (ve-morphism-sources-valid $objects $objects $morphism)
                          False)
                      False)
                  False)
              False)
          False)))

(= (ve-compose-object-map $objects $first $after)
   (if (== $objects ())
       ()
       (let* (($object (car-atom $objects))
              ($tail (cdr-atom $objects))
              ($middle (ve-map-object $first $object))
              ($target (ve-map-object $after $middle))
              ($tail-map (ve-compose-object-map $tail $first $after)))
          (cons-atom ($object $target) $tail-map))))

(= (ve-vmorphism-compose $name $first $after)
   (if (== (ve-morphism-target $first) (ve-morphism-source $after))
       (VMorphism $name
          (ve-morphism-source $first)
          (ve-morphism-target $after)
          (ve-compose-object-map
             (ve-category-objects (ve-morphism-source $first))
             $first
             $after))
       (VError IncompatibleMorphismComposition)))

(= (ve-vmorphism-same-map $first $second)
   (if (== (ve-morphism-source $first) (ve-morphism-source $second))
       (if (== (ve-morphism-target $first) (ve-morphism-target $second))
           (== (ve-morphism-object-map $first)
               (ve-morphism-object-map $second))
           False)
       False))

(= (ve-cocone-object-commutes $object $generic-to-left $generic-to-right $left-to-apex $right-to-apex)
   (== (ve-map-object $left-to-apex (ve-map-object $generic-to-left $object))
       (ve-map-object $right-to-apex (ve-map-object $generic-to-right $object))))

(= (ve-cocone-objects-commute $objects $generic-to-left $generic-to-right $left-to-apex $right-to-apex)
   (if (== $objects ())
       True
       (let* (($object (car-atom $objects))
              ($tail (cdr-atom $objects)))
          (if (ve-cocone-object-commutes
                 $object $generic-to-left $generic-to-right $left-to-apex $right-to-apex)
              (ve-cocone-objects-commute
                 $tail $generic-to-left $generic-to-right $left-to-apex $right-to-apex)
              False))))

(= (ve-vcocone-valid
      (VCocone $name $generic-to-left $generic-to-right $left-to-apex $right-to-apex))
   (if (== (ve-morphism-source $generic-to-left) (ve-morphism-source $generic-to-right))
       (if (== (ve-morphism-target $generic-to-left) (ve-morphism-source $left-to-apex))
           (if (== (ve-morphism-target $generic-to-right) (ve-morphism-source $right-to-apex))
               (if (== (ve-morphism-target $left-to-apex) (ve-morphism-target $right-to-apex))
                   (if (ve-vmorphism-valid $generic-to-left)
                       (if (ve-vmorphism-valid $generic-to-right)
                           (if (ve-vmorphism-valid $left-to-apex)
                               (if (ve-vmorphism-valid $right-to-apex)
                                   (ve-cocone-objects-commute
                                      (ve-category-objects (ve-morphism-source $generic-to-left))
                                      $generic-to-left $generic-to-right $left-to-apex $right-to-apex)
                                   False)
                               False)
                           False)
                       False)
                   False)
               False)
           False)
       False))

(= (ve-profunctor-value $profunctor $source-object $target-object)
   (ve-find-q-entry $source-object $target-object (ve-profunctor-values $profunctor)))

(= (ve-profunctor-values-well-formed $values $source-objects $target-objects $universe)
   (if (== $values ())
       True
       (let* (($head (car-atom $values))
              ($tail (cdr-atom $values))
              ($source-object (index-atom $head 0))
              ($target-object (index-atom $head 1))
              ($value (index-atom $head 2)))
          (if (ve-object-member $source-object $source-objects)
              (if (ve-object-member $target-object $target-objects)
                  (if (q-value-in-universe $value $universe)
                      (if (ve-q-entry-pair-exists $source-object $target-object $tail)
                          False
                          (ve-profunctor-values-well-formed
                             $tail $source-objects $target-objects $universe))
                      False)
                  False)
              False))))

(= (ve-profunctor-left-targets-valid $source-prime $source-object $targets $profunctor)
   (if (== $targets ())
       True
       (let* (($target-object (car-atom $targets))
              ($tail (cdr-atom $targets))
              ($action (q-tensor
                 (ve-category-hom (ve-profunctor-source $profunctor) $source-prime $source-object)
                 (ve-profunctor-value $profunctor $source-object $target-object)))
              ($bound (ve-profunctor-value $profunctor $source-prime $target-object)))
          (if (q-less-eq $action $bound)
              (ve-profunctor-left-targets-valid $source-prime $source-object $tail $profunctor)
              False))))

(= (ve-profunctor-left-sources-valid $source-prime $sources $targets $profunctor)
   (if (== $sources ())
       True
       (let* (($source-object (car-atom $sources))
              ($tail (cdr-atom $sources)))
          (if (ve-profunctor-left-targets-valid $source-prime $source-object $targets $profunctor)
              (ve-profunctor-left-sources-valid $source-prime $tail $targets $profunctor)
              False))))

(= (ve-profunctor-left-primes-valid $source-primes $sources $targets $profunctor)
   (if (== $source-primes ())
       True
       (let* (($source-prime (car-atom $source-primes))
              ($tail (cdr-atom $source-primes)))
          (if (ve-profunctor-left-sources-valid $source-prime $sources $targets $profunctor)
              (ve-profunctor-left-primes-valid $tail $sources $targets $profunctor)
              False))))

(= (ve-profunctor-right-primes-valid $source-object $target-object $target-primes $profunctor)
   (if (== $target-primes ())
       True
       (let* (($target-prime (car-atom $target-primes))
              ($tail (cdr-atom $target-primes))
              ($action (q-tensor
                 (ve-profunctor-value $profunctor $source-object $target-object)
                 (ve-category-hom (ve-profunctor-target $profunctor) $target-object $target-prime)))
              ($bound (ve-profunctor-value $profunctor $source-object $target-prime)))
          (if (q-less-eq $action $bound)
              (ve-profunctor-right-primes-valid $source-object $target-object $tail $profunctor)
              False))))

(= (ve-profunctor-right-targets-valid $source-object $targets $all-targets $profunctor)
   (if (== $targets ())
       True
       (let* (($target-object (car-atom $targets))
              ($tail (cdr-atom $targets)))
          (if (ve-profunctor-right-primes-valid $source-object $target-object $all-targets $profunctor)
              (ve-profunctor-right-targets-valid $source-object $tail $all-targets $profunctor)
              False))))

(= (ve-profunctor-right-sources-valid $sources $targets $profunctor)
   (if (== $sources ())
       True
       (let* (($source-object (car-atom $sources))
              ($tail (cdr-atom $sources)))
          (if (ve-profunctor-right-targets-valid $source-object $targets $targets $profunctor)
              (ve-profunctor-right-sources-valid $tail $targets $profunctor)
              False))))

(= (ve-vprofunctor-valid $profunctor)
   (let* (($source (ve-profunctor-source $profunctor))
          ($target (ve-profunctor-target $profunctor))
          ($sources (ve-category-objects $source))
          ($targets (ve-category-objects $target)))
      (if (ve-vcategory-valid $source)
          (if (ve-vcategory-valid $target)
              (if (== (ve-category-universe $source) (ve-category-universe $target))
                  (if (ve-profunctor-values-well-formed
                         (ve-profunctor-values $profunctor)
                         $sources $targets (ve-category-universe $source))
                      (if (ve-profunctor-left-primes-valid $sources $sources $targets $profunctor)
                          (ve-profunctor-right-sources-valid $sources $targets $profunctor)
                          False)
                      False)
                  False)
              False)
          False)))

(= (ve-coend-fold $source-object $target-object $middles $first $after)
   (if (== $middles ())
       (q-bottom)
       (let* (($middle (car-atom $middles))
              ($tail (cdr-atom $middles))
              ($head-value (q-tensor
                 (ve-profunctor-value $first $source-object $middle)
                 (ve-profunctor-value $after $middle $target-object)))
              ($tail-value (ve-coend-fold
                 $source-object $target-object $tail $first $after)))
          (q-join $head-value $tail-value))))

; Public finite enriched coend:
;   (after o first)(a,c) = join_b first(a,b) tensor after(b,c)
; Both profunctors and both requested endpoints are validated before folding.
(= (ve-coend $source-object $target-object $first $after)
   (if (ve-vprofunctor-valid $first)
       (if (ve-vprofunctor-valid $after)
           (if (== (ve-profunctor-target $first)
                   (ve-profunctor-source $after))
               (if (ve-object-member
                      $source-object
                      (ve-category-objects (ve-profunctor-source $first)))
                   (if (ve-object-member
                          $target-object
                          (ve-category-objects (ve-profunctor-target $after)))
                       (ve-coend-fold
                          $source-object $target-object
                          (ve-category-objects (ve-profunctor-target $first))
                          $first $after)
                       (VError UnknownCoendTarget $target-object))
                   (VError UnknownCoendSource $source-object))
               (VError IncompatibleProfunctorComposition))
           (VError InvalidAfterProfunctor))
       (VError InvalidFirstProfunctor)))

; Compatibility alias retained for existing callers that supply the middle
; object list explicitly. New code should use ve-coend.
(= (ve-profunctor-coend-value $source-object $target-object $middles $first $after)
   (ve-coend-fold $source-object $target-object $middles $first $after))

(= (ve-profunctor-compose-target-values $source-object $targets $middles $first $after)
   (if (== $targets ())
       ()
       (let* (($target-object (car-atom $targets))
              ($tail (cdr-atom $targets))
              ($value (ve-coend-fold
                 $source-object $target-object $middles $first $after))
              ($tail-values (ve-profunctor-compose-target-values
                 $source-object $tail $middles $first $after)))
          (cons-atom ($source-object $target-object $value) $tail-values))))

(= (ve-profunctor-compose-values $sources $targets $middles $first $after)
   (if (== $sources ())
       ()
       (let* (($source-object (car-atom $sources))
              ($tail (cdr-atom $sources))
              ($head-values (ve-profunctor-compose-target-values
                 $source-object $targets $middles $first $after))
              ($tail-values (ve-profunctor-compose-values
                 $tail $targets $middles $first $after)))
          (union-atom $head-values $tail-values))))

(= (ve-vprofunctor-compose $name $first $after)
   (if (ve-vprofunctor-valid $first)
       (if (ve-vprofunctor-valid $after)
           (if (== (ve-profunctor-target $first) (ve-profunctor-source $after))
               (VProfunctor $name
                  (ve-profunctor-source $first)
                  (ve-profunctor-target $after)
                  (ve-profunctor-compose-values
                     (ve-category-objects (ve-profunctor-source $first))
                     (ve-category-objects (ve-profunctor-target $after))
                     (ve-category-objects (ve-profunctor-target $first))
                     $first
                     $after))
               (VError IncompatibleProfunctorComposition))
           (VError InvalidAfterProfunctor))
       (VError InvalidFirstProfunctor)))

(= (ve-profunctor-identity-target-values $source-object $targets $category)
   (if (== $targets ())
       ()
       (let* (($target-object (car-atom $targets))
              ($tail (cdr-atom $targets))
              ($tail-values (ve-profunctor-identity-target-values $source-object $tail $category)))
          (cons-atom
             ($source-object $target-object (ve-category-hom $category $source-object $target-object))
             $tail-values))))

(= (ve-profunctor-identity-values $sources $objects $category)
   (if (== $sources ())
       ()
       (let* (($source-object (car-atom $sources))
              ($tail (cdr-atom $sources))
              ($head-values (ve-profunctor-identity-target-values $source-object $objects $category))
              ($tail-values (ve-profunctor-identity-values $tail $objects $category)))
          (union-atom $head-values $tail-values))))

(= (ve-vprofunctor-identity $name $category)
   (VProfunctor $name $category $category
      (ve-profunctor-identity-values
         (ve-category-objects $category)
         (ve-category-objects $category)
         $category)))

; Companion of F : A -> C, with F_*(a,c) = C(Fa,c).
(= (ve-companion-target-values $source-object $targets $morphism)
   (if (== $targets ())
       ()
       (let* (($target-object (car-atom $targets))
              ($tail (cdr-atom $targets))
              ($value (ve-category-hom
                 (ve-morphism-target $morphism)
                 (ve-map-object $morphism $source-object)
                 $target-object))
              ($tail-values
                 (ve-companion-target-values
                    $source-object $tail $morphism)))
          (cons-atom ($source-object $target-object $value) $tail-values))))

(= (ve-companion-values $sources $targets $morphism)
   (if (== $sources ())
       ()
       (let* (($source-object (car-atom $sources))
              ($tail (cdr-atom $sources))
              ($head-values
                 (ve-companion-target-values
                    $source-object $targets $morphism))
              ($tail-values
                 (ve-companion-values $tail $targets $morphism)))
          (union-atom $head-values $tail-values))))

(= (ve-vmorphism-companion $name $morphism)
   (if (ve-vmorphism-valid $morphism)
       (VProfunctor $name
          (ve-morphism-source $morphism)
          (ve-morphism-target $morphism)
          (ve-companion-values
             (ve-category-objects (ve-morphism-source $morphism))
             (ve-category-objects (ve-morphism-target $morphism))
             $morphism))
       (VError InvalidCompanionMorphism)))

; Conjoint of F : A -> C, with F^*(c,a) = C(c,Fa).
(= (ve-conjoint-target-values $source-object $targets $morphism)
   (if (== $targets ())
       ()
       (let* (($target-object (car-atom $targets))
              ($tail (cdr-atom $targets))
              ($value (ve-category-hom
                 (ve-morphism-target $morphism)
                 $source-object
                 (ve-map-object $morphism $target-object)))
              ($tail-values
                 (ve-conjoint-target-values
                    $source-object $tail $morphism)))
          (cons-atom ($source-object $target-object $value) $tail-values))))

(= (ve-conjoint-values $sources $targets $morphism)
   (if (== $sources ())
       ()
       (let* (($source-object (car-atom $sources))
              ($tail (cdr-atom $sources))
              ($head-values
                 (ve-conjoint-target-values
                    $source-object $targets $morphism))
              ($tail-values
                 (ve-conjoint-values $tail $targets $morphism)))
          (union-atom $head-values $tail-values))))

(= (ve-vmorphism-conjoint $name $morphism)
   (if (ve-vmorphism-valid $morphism)
       (VProfunctor $name
          (ve-morphism-target $morphism)
          (ve-morphism-source $morphism)
          (ve-conjoint-values
             (ve-category-objects (ve-morphism-target $morphism))
             (ve-category-objects (ve-morphism-source $morphism))
             $morphism))
       (VError InvalidConjointMorphism)))

; Explicit relative V-colimit certificate.
;
; (VColimit Name Cocone (MediatingWitnesses ...) (ComparisonScope (...) Exhaustive))
; Each supplied comparison cocone must have exactly one witness mediator. The
; Exhaustive marker is an explicit contract from the comparison-cocone producer.

(= (ve-vcolimit-name
      (VColimit $name $cocone $witnesses $scope))
   $name)
(= (ve-vcolimit-cocone
      (VColimit $name $cocone $witnesses $scope))
   $cocone)
(= (ve-vcolimit-witnesses
      (VColimit $name $cocone (MediatingWitnesses $witnesses) $scope))
   $witnesses)
(= (ve-vcolimit-comparisons
      (VColimit $name $cocone $witnesses
         (ComparisonScope $comparisons Exhaustive)))
   $comparisons)

(= (ve-cocones-share-diagram $first $second)
   (if (ve-vmorphism-same-map
          (ve-cocone-generic-to-left $first)
          (ve-cocone-generic-to-left $second))
       (ve-vmorphism-same-map
          (ve-cocone-generic-to-right $first)
          (ve-cocone-generic-to-right $second))
       False))

(= (ve-mediator-leg-commutes $objects $candidate-leg $comparison-leg $mediator)
   (if (== $objects ())
       True
       (let* (($object (car-atom $objects))
              ($tail (cdr-atom $objects))
              ($candidate-image (ve-map-object $candidate-leg $object))
              ($mediated-image (ve-map-object $mediator $candidate-image))
              ($comparison-image (ve-map-object $comparison-leg $object)))
          (if (== $mediated-image $comparison-image)
              (ve-mediator-leg-commutes
                 $tail $candidate-leg $comparison-leg $mediator)
              False))))

(= (ve-mediator-valid $candidate $comparison $mediator)
   (if (ve-vmorphism-valid $mediator)
       (if (== (ve-morphism-source $mediator) (ve-cocone-apex $candidate))
           (if (== (ve-morphism-target $mediator) (ve-cocone-apex $comparison))
               (if (ve-mediator-leg-commutes
                      (ve-category-objects
                         (ve-morphism-source
                            (ve-cocone-left-to-apex $candidate)))
                      (ve-cocone-left-to-apex $candidate)
                      (ve-cocone-left-to-apex $comparison)
                      $mediator)
                   (ve-mediator-leg-commutes
                      (ve-category-objects
                         (ve-morphism-source
                            (ve-cocone-right-to-apex $candidate)))
                      (ve-cocone-right-to-apex $candidate)
                      (ve-cocone-right-to-apex $comparison)
                      $mediator)
                   False)
               False)
           False)
       False))

(= (ve-witness-count $comparison $candidate $witnesses)
   (if (== $witnesses ())
       0
       (let* (($head (car-atom $witnesses))
              ($tail (cdr-atom $witnesses))
              ((MediatingWitness $head-comparison $mediator) $head)
              ($tail-count
                 (ve-witness-count $comparison $candidate $tail)))
          (if (== $head-comparison $comparison)
              (if (ve-mediator-valid $candidate $comparison $mediator)
                  (+ 1 $tail-count)
                  $tail-count)
              $tail-count))))

(= (ve-witness-entry-valid $entry $candidate $comparisons)
   (let (MediatingWitness $comparison $mediator) $entry
      (if (q-list-member $comparison $comparisons)
          (ve-mediator-valid $candidate $comparison $mediator)
          False)))

(= (ve-witnesses-valid $witnesses $candidate $comparisons)
   (if (== $witnesses ())
       True
       (if (ve-witness-entry-valid
              (car-atom $witnesses) $candidate $comparisons)
           (ve-witnesses-valid
              (cdr-atom $witnesses) $candidate $comparisons)
           False)))

(= (ve-comparisons-have-unique-mediators
      $comparisons $candidate $witnesses)
   (if (== $comparisons ())
       True
       (let* (($comparison (car-atom $comparisons))
              ($tail (cdr-atom $comparisons)))
          (if (ve-vcocone-valid $comparison)
              (if (ve-cocones-share-diagram $candidate $comparison)
                  (if (== (ve-witness-count
                             $comparison $candidate $witnesses) 1)
                      (ve-comparisons-have-unique-mediators
                         $tail $candidate $witnesses)
                      False)
                  False)
              False))))

(= (ve-vcolimit-valid
      (VColimit $name $candidate
         (MediatingWitnesses $witnesses)
         (ComparisonScope $comparisons Exhaustive)))
   (if (ve-vcocone-valid $candidate)
       (if (== $comparisons ())
           False
           (if (ve-list-unique $comparisons)
               (if (ve-witnesses-valid $witnesses $candidate $comparisons)
                   (ve-comparisons-have-unique-mediators
                      $comparisons $candidate $witnesses)
                   False)
               False))
       False))
