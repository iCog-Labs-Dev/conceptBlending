
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
(=(get_spec $algspec) 
  (index-atom $algspec 2)

)

(= (get_priority_value ($entity $p_val)) 
     $p_val
)

(=(get_sorts_priority $sorts)

    (let $sorts_element (cdr-atom $sorts)
    (let $sorts_priority (get_priority_value (car-atom $sorts_element))
    $sorts_priority
    )
    
    )
)

(=(get_ops_priority $ops)

    (let $ops_element (cdr-atom $ops)
    (let $ops_priority (get_priority_value (car-atom $ops_element))
    $ops_priority
    )
    
    )
)

(=(get_preds_priority $preds)

    (let $preds_element (cdr-atom $preds)
    (let $preds_priority (get_priority_value (car-atom $preds_element))
    $preds_priority
    )
    
    )
)
(=(get_axioms_priority $axioms)

    (let $axioms_element (cdr-atom $axioms)
    (let $axioms_priority (get_priority_value (car-atom $axioms_element))
    $axioms_priority
    )
    
    )
)




(= (priority-extractor $concept_algspec)
  (let $spec (get_spec $concept_algspec)
    (let ($sort $op $pred $axioms) (cdr-atom $spec)
    (let $priorities
      ((get_sorts_priority $sort)
       (get_ops_priority $op)
       (get_preds_priority $pred)
       (get_axioms_priority $axioms)
      )

      $priorities
    )
  )
)
)


;------------Blend Evalation Matrix------------

; Information value
(= (infoValue $algspec)
  (let $priorities (priority-extractor $algspec)
    (sum $priorities)
  )
)

;Compression


; Imbalance between two specs
(= (imbalance $spec1 $spec2)
  (let $spec1_info_value (infoValue $spec1)
    (let $spec2_info_value (infoValue $spec2)
      (/ (abs-math (- $spec1_info_value $spec2_info_value)) 2)
    )
  )
)

;Value


!(infoValue (Concept Cube@Dice_Blend (spec (sorts (Object 2) ((< GenericObject Object) 2) (Number 2) (Face 2) (GeometricForm 2) (Property 2) (UsageContext 1) (Symbolism 2) (Action 2)) (ops ((: genericObject GenericObject) 20) ((: six Number) 10) ((: squareFace Face) 10) ((: geometricForm GeometricForm) 10) ((: buildingBlock Property) 5) ((: unit Property) 5) ((: randomNumericalResult Property) 5) ((: game UsageContext) 5) ((: order Symbolism) 5) ((: stability Symbolism) 5) ((: unpredictability Symbolism) 5) ((: handle Action) 10) ((: rotate Action) 10) ((: throw Action) 10)) (preds ((is3DPolyhedralObject GenericObject) 6) ((hasFaces GenericObject Number Face) 6) ((representsForm GenericObject GeometricForm) 6) ((canPerformAction GenericObject Action) 6) ((hasProperty GenericObject Property) 6) ((usedIn GenericObject UsageContext) 3) ((symbolizes GenericObject Symbolism) 6)) (axioms ((is3DPolyhedralObject genericObject) 20) ((hasFaces genericObject six squareFace) 20) ((representsForm genericObject geometricForm) 20) ((canPerformAction genericObject handle) 20) ((canPerformAction genericObject rotate) 20) ((canPerformAction genericObject throw) 20) ((hasProperty genericObject buildingBlock) 10) ((hasProperty genericObject unit) 10) ((hasProperty genericObject randomNumericalResult) 10) ((usedIn genericObject game) 10) ((symbolizes genericObject order) 10) ((symbolizes genericObject stability) 10) ((symbolizes genericObject unpredictability) 10)))))
!(imbalance (Concept Cube@Dice_Blend (spec (sorts (Object 20) ((< GenericObject Object) 882) (Number 2) (Face 2) (GeometricForm 2) (Property 2) (UsageContext 1) (Symbolism 2) (Action 2)) (ops ((: genericObject GenericObject) 20) ((: six Number) 10) ((: squareFace Face) 10) ((: geometricForm GeometricForm) 10) ((: buildingBlock Property) 5) ((: unit Property) 5) ((: randomNumericalResult Property) 5) ((: game UsageContext) 5) ((: order Symbolism) 5) ((: stability Symbolism) 5) ((: unpredictability Symbolism) 5) ((: handle Action) 10) ((: rotate Action) 10) ((: throw Action) 10)) (preds ((is3DPolyhedralObject GenericObject) 6) ((hasFaces GenericObject Number Face) 6) ((representsForm GenericObject GeometricForm) 6) ((canPerformAction GenericObject Action) 6) ((hasProperty GenericObject Property) 6) ((usedIn GenericObject UsageContext) 3) ((symbolizes GenericObject Symbolism) 6)) (axioms ((is3DPolyhedralObject genericObject) 20) ((hasFaces genericObject six squareFace) 20) ((representsForm genericObject geometricForm) 20) ((canPerformAction genericObject handle) 20) ((canPerformAction genericObject rotate) 20) ((canPerformAction genericObject throw) 20) ((hasProperty genericObject buildingBlock) 10) ((hasProperty genericObject unit) 10) ((hasProperty genericObject randomNumericalResult) 10) ((usedIn genericObject game) 10) ((symbolizes genericObject order) 10) ((symbolizes genericObject stability) 10) ((symbolizes genericObject unpredictability) 10)))) (Concept Cube@Dice_Blend (spec (sorts (Object 2) ((< GenericObject Object) 2) (Number 2) (Face 2) (GeometricForm 2) (Property 2) (UsageContext 1) (Symbolism 2) (Action 2)) (ops ((: genericObject GenericObject) 20) ((: six Number) 10) ((: squareFace Face) 10) ((: geometricForm GeometricForm) 10) ((: buildingBlock Property) 5) ((: unit Property) 5) ((: randomNumericalResult Property) 5) ((: game UsageContext) 5) ((: order Symbolism) 5) ((: stability Symbolism) 5) ((: unpredictability Symbolism) 5) ((: handle Action) 10) ((: rotate Action) 10) ((: throw Action) 10)) (preds ((is3DPolyhedralObject GenericObject) 6) ((hasFaces GenericObject Number Face) 6) ((representsForm GenericObject GeometricForm) 6) ((canPerformAction GenericObject Action) 6) ((hasProperty GenericObject Property) 6) ((usedIn GenericObject UsageContext) 3) ((symbolizes GenericObject Symbolism) 6)) (axioms ((is3DPolyhedralObject genericObject) 20) ((hasFaces genericObject six squareFace) 20) ((representsForm genericObject geometricForm) 20) ((canPerformAction genericObject handle) 20) ((canPerformAction genericObject rotate) 20) ((canPerformAction genericObject throw) 20) ((hasProperty genericObject buildingBlock) 10) ((hasProperty genericObject unit) 10) ((hasProperty genericObject randomNumericalResult) 10) ((usedIn genericObject game) 10) ((symbolizes genericObject order) 10) ((symbolizes genericObject stability) 10) ((symbolizes genericObject unpredictability) 10)))))

;test
