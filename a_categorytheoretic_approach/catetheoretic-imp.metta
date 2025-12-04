
!(import! &self tests:libs)
!(import! &self utils:helper)

; GPT-based Algspec Builder

(=(algspec_builder $concept1 $concept2)
     (let ($context1 $context2) ((main-fetch $concept1) (main-fetch $concept2))
        (let ($generated_context) (collapse (gpt_context_preprocessing $concept1 $context1 $concept2 $context2))
           (gpt_algspec_builder $concept1 $concept2 $generated_context) 
           )
           )
)


;!(algspec_builder dice cube)

; GPT-based Generalization Builder

(=(least_generalization_builder $concept1 $concept2)
    (let ($algspec1 $algspec2) (collapse (algspec_builder $concept1 $concept2))
        (gpt_generalization_helper $algspec1 $algspec2)
    )
)

;!(least_generalization_builder dice cube)
; GPT-based Amalgam Builder
(=(amalgam_builder $concept1 $concept2)
        (let ($algspec1 $algspec2) (collapse (algspec_builder $concept1 $concept2))
            (let $generalized_algspec (collapse (gpt_generalization_helper $algspec1 $algspec2))
                (gpt_amalgam_builder $algspec1 $algspec2 $generalized_algspec) 
            )
        )
)


(=(sum $priorities)
    (foldl-atom $priorities 0 $acc $p (+ $acc $p))
)
(= (get_spec $algspec)
  (index-atom $algspec 2))

(= (get_priority_value ($entity $p_val))
  $p_val)

(= (get_sorts_priority $sorts)
  (let $items (cdr-atom $sorts)
    (if (> (size-atom $items) 0)
      (+ (get_priority_value (car-atom $items)) (get_sorts_priority $items))
      0)))

(= (get_ops_priority $ops)
  (let $items (cdr-atom $ops)
    (if (> (size-atom $items) 0)
      (+ (get_priority_value (car-atom $items)) (get_ops_priority $items))
      0)))

(= (get_preds_priority $preds)
  (let $items (cdr-atom $preds)
    (if (> (size-atom $items) 0)
      (+ (get_priority_value (car-atom $items)) (get_preds_priority $items))
      0)))

(= (get_axioms_priority $axioms)
  (let $items (cdr-atom $axioms)
    (if (> (size-atom $items) 0)
      (+ (get_priority_value (car-atom $items)) (get_axioms_priority $items))
      0)))

(= (priority-extractor $concept_algspec)
  (let $spec (get_spec $concept_algspec)
    (let ($sort $op $pred $axioms) (cdr-atom $spec)
      ((get_sorts_priority $sort)
       (get_ops_priority $op)
       (get_preds_priority $pred)
       (get_axioms_priority $axioms)))))








;------------Blend Evalation Matrix------------

; Information value
(= (infoValue $algspec)
  (let $priorities (priority-extractor $algspec)
    (sum $priorities)))

    
;Compression



; Imbalance between two specs
(= (imbalance $spec1 $spec2)
  (let $v1 (infoValue $spec1)
    (let $v2 (infoValue $spec2)
      (/ (abs-math (- $v1 $v2)) 2))))


!(priority-extractor (Concept cube (spec (sorts (Object 1) (GeometricFeature 1) (Characteristic 1) (Attribute 1) (Role 1) (Count 1) ((< Cube Object) 1) ((< Face GeometricFeature) 1) ((< Edge GeometricFeature) 1) ((< Vertex GeometricFeature) 1)) (ops ((: cube Cube) 10) ((: six Count) 5) ((: threeDimensional Characteristic) 10) ((: distinct Characteristic) 10) ((: discreteUnit Characteristic) 10) ((: geometricForm Attribute) 5) ((: structuralDefinition Role) 5)) (preds ((hasCharacteristic Object Characteristic) 3) ((hasFeature Object GeometricFeature) 
3) ((hasCount Object Count GeometricFeature) 3) ((definedBy Object GeometricFeature GeometricFeature) 3) ((hasAttribute Object Attribute) 3) ((hasRole Object Role) 3)) (axioms ((hasCharacteristic cube threeDimensional) 10) ((hasFeature cube Face) 10) ((hasCount cube six Face) 10) ((hasCharacteristic cube distinct) 10) ((definedBy cube Edge Vertex) 10) ((hasCharacteristic cube discreteUnit) 10) ((hasAttribute cube geometricForm) 5) ((hasRole cube structuralDefinition) 5))

)))




;!(get_sorts_priority (sorts (Object 5) ))


