
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


(=(get_morphism $lcg)
  (let $spec (get_spec $lcg)
  (let ($sort $op $pred $axioms) (cdr-atom $spec)
      ((- (size-atom $sort) 1)
       (- (size-atom $op) 1)
       (- (size-atom $pred) 1)
       (- (size-atom $axioms) 1)
       )
  
  )
)
)
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
(= (infoValue $blend)
  (let $priorities (priority-extractor $blend)
    (sum $priorities)
    
    ))

(=(compression $lcg $blend)
 (let $infovalue (infoValue $blend)
 (let $number_of_morphism (sum (get_morphism $lcg))
    (/ $infovalue $number_of_morphism)
 
  )
 
 )

)
;Compression
;count number of element in the lcg and calculate info value of the blend and devide it with number of element inside lcg as it is total number of morphism to the blend space
;(use llm python grounding to know number of input morphism to the blend by giving the two spec and final blend)

;main evaluator takes two concept generate spec using gpt algspec then store it and generate lcg and store it and fin..;

; Imbalance between two specs
(= (imbalance $spec1 $spec2)
  (let $v1 (infoValue $spec1)
    (let $v2 (infoValue $spec2)
      (/ (abs-math (- $v1 $v2)) 2))))

; The final evaluation Matrix
(=(value $spec1 $spec2 $lcg $blend)
(let ($info_value $compression $imbalance) ((infoValue $blend) (Compression $lcg $blend) (Imbalance $spec1 $spec2))
  (- (+ $info_value $compression) $imbalance)
)


)
