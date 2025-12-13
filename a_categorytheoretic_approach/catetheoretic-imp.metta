
!(import! &self libs)
!(import! &self utils:helper)

; GPT-based Algspec Builder

(=(algspec-builder $concept1 $concept2)
     (let ($context1 $context2) ((main-fetch $concept1) (main-fetch $concept2))
        (let ($generated_context) (collapse (gpt-context-preprocessing $concept1 $context1 $concept2 $context2))
           (gpt-algspec-builder $concept1 $concept2 $generated_context) 
           )
           )
)



; GPT-based Generalization Builder

(=(least-generalization-builder $concept1 $concept2)
    (let ($algspec1 $algspec2) (collapse (algspec-builder $concept1 $concept2))
        (gpt-generalization-helper $algspec1 $algspec2)
    )
)


; GPT-based Amalgam Builder
(=(amalgam-builder $concept1 $concept2)
        (let ($algspec1 $algspec2) (collapse (algspec-builder $concept1 $concept2))
            (let $generalized_algspec (collapse (gpt-generalization-helper $algspec1 $algspec2))
                (gpt-amalgam-builder $algspec1 $algspec2 $generalized_algspec) 
            )
        )
)


(=(sum $priorities)
    (foldl-atom $priorities 0 $acc $p (+ $acc $p))
)
(= (get-spec $algspec)
  (index-atom $algspec 2))


(=(get-morphism $lcg)
  (let $spec (get-spec $lcg)
  (let ($sort $op $pred $axioms) (cdr-atom $spec)
      ((- (size-atom $sort) 1)
       (- (size-atom $op) 1)
       (- (size-atom $pred) 1)
       (- (size-atom $axioms) 1)
       )
  
  )
)
)
(= (get-priority-value ($entity $p-val))
  $p-val)

(= (get-sorts-priority $sorts)
  (let $items (cdr-atom $sorts)
    (if (> (size-atom $items) 0)
      (+ (get-priority-value (car-atom $items)) (get-sorts-priority $items))
      0)))

(= (get-ops-priority $ops)
  (let $items (cdr-atom $ops)
    (if (> (size-atom $items) 0)
      (+ (get-priority-value (car-atom $items)) (get-ops-priority $items))
      0)))

(= (get-preds-priority $preds)
  (let $items (cdr-atom $preds)
    (if (> (size-atom $items) 0)
      (+ (get-priority-value (car-atom $items)) (get-preds-priority $items))
      0)))

(= (get-axioms-priority $axioms)
  (let $items (cdr-atom $axioms)
    (if (> (size-atom $items) 0)
      (+ (get-priority-value (car-atom $items)) (get-axioms-priority $items))
      0)))

(= (priority-extractor $concept_algspec)
  (let $spec (get-spec $concept_algspec)
    (let ($sort $op $pred $axioms) (cdr-atom $spec)
      ((get-sorts-priority $sort)
       (get-ops-priority $op)
       (get-preds-priority $pred)
       (get-axioms-priority $axioms)))))








;------------Blend Evaluation Matrix------------

; Information value
(= (infoValue $blend)
  (let $priorities (priority-extractor $blend)
    (sum $priorities)
    
    ))
    
;Compression
(=(compression $lcg $blend)
 (let $info_value (infoValue $blend)
 (let $number_of_morphism (sum (get-morphism $lcg))
    (/ $info_value $number_of_morphism)
 
  )
 
 )

)

; Imbalance between two specs
(= (imbalance $spec1 $spec2)
  (let $v1 (infoValue $spec1)
    (let $v2 (infoValue $spec2)
      (/ (abs-math (- $v1 $v2)) 2))))

; The final evaluation Matrix
(=(value $spec1 $spec2 $lcg $blend)
(let ($info_value $compression $imbalance) ((infoValue $blend) (compression $lcg $blend) (imbalance $spec1 $spec2))
  (- (+ $info_value $compression) $imbalance)
)


)
