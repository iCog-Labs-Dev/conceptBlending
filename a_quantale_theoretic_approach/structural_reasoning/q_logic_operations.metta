!(import! &self a_quantale_theoretic_approach/core_representation/quantale_types)
!(import! &self a_quantale_theoretic_approach/core_representation/v_predicate)

; Property-level quantale support.  This first PeTTa pass uses exact property
; support; semantic support will later be delegated to grounded Python atoms,
; matching the older OP-constraint implementation pattern.

(= (q-property-support $prop-name $target-properties)
   (let $target-prop (v-find-property $prop-name $target-properties)
      (if (== $target-prop ())
          (q-bottom)
          (v-property-quantale $target-prop))))

(= (q-hom-properties $source-properties $target-properties $universe)
   (if (== $source-properties ())
       (q-unit $universe)
       (let* (($head (car-atom $source-properties))
              ($tail (cdr-atom $source-properties))
              ($source-name (v-property-name $head))
              ($source-q (v-property-quantale $head))
              ($support (q-property-support $source-name $target-properties))
              ($head-score (q-residuation $source-q $support $universe))
              ($tail-score (q-hom-properties $tail $target-properties $universe)))
          (q-tensor $head-score $tail-score))))

(= (q-hom $source-concept $target-concept)
   (let* (($source-properties (v-property-list $source-concept))
          ($target-properties (v-property-list $target-concept))
          ($universe (unique-atom (union-atom (v-world-universe $source-concept)
                                             (v-world-universe $target-concept)))))
      (q-hom-properties $source-properties $target-properties $universe)))

(= (q-equivalence-score $concept-a $concept-b)
   (let* (($universe (unique-atom (union-atom (v-world-universe $concept-a)
                                             (v-world-universe $concept-b))))
          ($a-to-b (q-hom-properties (v-property-list $concept-a) (v-property-list $concept-b) $universe))
          ($b-to-a (q-hom-properties (v-property-list $concept-b) (v-property-list $concept-a) $universe)))
      (q-tensor $a-to-b $b-to-a)))
