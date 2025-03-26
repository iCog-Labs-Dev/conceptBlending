! (import! &self conceptual_blending)
! (import! &self info-theoretic1)


! (let*(
        ($concepts (gpt_vector "Spider" "Man"))
        ($concept1 (car-atom $concepts))
        ($wrapped-concept2 (cdr-atom $concepts))
        ($concept2 (car-atom $wrapped-concept2))
        ($degree (property-degree $concept1))
        ($max (property-max $concept1 $concept2))
        ($calculated-mu-emergence (mu-emergence $degree $max))
        ($min (property-min $concept1 $concept2))
        ($calculated-mu-hqblend (mu-hqblend $calculated-mu-emergence $min))
    )
    ($calculated-mu-hqblend $concept1 $concept2)
)
; Output [(0.03182937256098939 (Concept Spider@Man (Property (legs 1.0) (intelligence 0.2) (web-creation 1.0) (strength 0.3) (symbolism 0.7) (agility 0.6) (predatory-behavior 1.0) (social-structure 0.1))) (Concept Man@Spider (Property (legs 0.1) (intelligence 1.0) (web-creation 0.0) (strength 0.8) (symbolism 0.5) (agility 0.7) (predatory-behavior 0.2) (social-structure 0.9))))]
