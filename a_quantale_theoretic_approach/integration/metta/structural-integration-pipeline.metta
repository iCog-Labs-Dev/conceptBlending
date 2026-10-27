(= (integration-compact-v-predicate-match
      (Concept $actual-name $actual-perspective (Properties $properties))
      $expected-name $expected-perspective)
   (if (== $actual-name $expected-name)
       (== $actual-perspective $expected-perspective)
       False))

(= (integration-compact-v-predicate-valid
      $candidate $expected-name $expected-perspective)
   (== (collapse
          (integration-compact-v-predicate-match
             $candidate $expected-name $expected-perspective))
       (True)))

(= (integration-algebraic-spec-match
      (Concept $name $actual-perspective
         (spec (sorts $sorts) (ops $ops) (preds $preds) (axioms $axioms)))
      $expected-perspective)
   (== $actual-perspective $expected-perspective))

(= (integration-algebraic-spec-valid $candidate $expected-perspective)
   (== (collapse
          (integration-algebraic-spec-match
             $candidate $expected-perspective))
       (True)))

(= (integration-one-spec $concept $perspective)
   (let $specifications
         (collapse (get-world-algebraic-spec $concept $perspective))
      (if (== (size-atom $specifications) 1)
          (car-atom $specifications)
          (IntegrationError
             SourceAlgebraicSpecificationUnavailable
             $concept $perspective
             (Found (size-atom $specifications))))))

(= (integration-preparation-generic-spec
      (structural-blend-preparation
         $generic-name $perspective
         $sources $source-specs
         (GenericSpaceAlgebraicSpecification $generic-spec)
         $status))
   $generic-spec)

(= (integration-preparation-enrichment-status
      (structural-blend-preparation
         $generic-name $perspective
         $sources $source-specs $generic-spec $status))
   $status)

(= (prepare-structural-blend-from-texts
      $generic-name $perspective
      $left-v-predicate-text $right-v-predicate-text
      $left-spec-text $right-spec-text)
   (let* (
      ($left-spec (sread $left-spec-text))
      ($right-spec (sread $right-spec-text))
      ($generic-spec
         (main-lcg
            $generic-name $perspective $left-spec $right-spec))
      ($generic-spec-text (repr (reduce $generic-spec))))
      (sread
         (py-call
            (integration_support.assemble_structural_blend_preparation
               $generic-name $perspective
               $left-v-predicate-text $right-v-predicate-text
               $left-spec-text $right-spec-text
               $generic-spec-text)))))

(: prepare-structural-blend-from-specs
   (-> Atom Atom
       Expression Expression Expression Expression
       Expression))
(= (prepare-structural-blend-from-specs
      $generic-name $perspective
      $left-v-predicate-expression $right-v-predicate-expression
      $left-spec-expression $right-spec-expression)
   (prepare-structural-blend-from-texts
      $generic-name $perspective
      (repr (reduce $left-v-predicate-expression))
      (repr (reduce $right-v-predicate-expression))
      (repr (reduce $left-spec-expression))
      (repr (reduce $right-spec-expression))))

(= (prepare-structural-blend
      $generic-name $perspective $left-concept $right-concept)
   (let* (
      ($left-v-predicate
         (build-concept-property-world-specifications
            $left-concept $perspective))
      ($right-v-predicate
         (build-concept-property-world-specifications
            $right-concept $perspective)))
      (if (integration-compact-v-predicate-valid
             $left-v-predicate $left-concept $perspective)
          (if (integration-compact-v-predicate-valid
                 $right-v-predicate $right-concept $perspective)
              (let* (
                 ($left-spec
                    (integration-one-spec $left-concept $perspective))
                 ($right-spec
                    (integration-one-spec $right-concept $perspective)))
                 (if (== (car-atom $left-spec) IntegrationError)
                     $left-spec
                     (if (== (car-atom $right-spec) IntegrationError)
                         $right-spec
                         (prepare-structural-blend-from-specs
                            $generic-name $perspective
                            $left-v-predicate $right-v-predicate
                            $left-spec $right-spec))))
              (IntegrationError
                 InvalidCompactVPredicate right
                 $right-concept $perspective))
          (IntegrationError
             InvalidCompactVPredicate left
             $left-concept $perspective))))
