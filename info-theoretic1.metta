; ###################### Helper functions ##########################
(=(get-properties $concept)
    (let*(
        ($full-concept (superpose $concept))
    )
        (if (== (get-metatype $full-concept) Expression)
            (let $property (cdr-atom $full-concept)
                $property)
            (empty)
        )
    )
)
; ! (get-properties (Concept Spider@Man (Property (web-creation 1.0) (intelligence 0.4) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
; Output [((web-creation 1.0) (intelligence 0.4) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))]


(= (get-num $property)
    (let*(
        ($value (cdr-atom $property))
        ($num (car-atom $value))
    )
        $num
    )
)
; ! (get-num (web-creation 1.0))
; Output [1.0]


(=(get-values $properties)
    (let*(
        ($property (car-atom $properties))
        ($num (get-num $property))
        ($num-properties (size-atom $properties))
    )
        (if (not (== $num-properties 1))
            (let*(
                ($tail-properties (cdr-atom $properties))
                ($call-back (get-values $tail-properties))
            )
                (cons-atom $num $call-back)
            )
            ($num)
        )
    )
)
; ! (get-values (get-properties (Concept Spider@Man (Property (web-creation 1.0) (intelligence 0.4) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1)))))
; Output [(1.0 0.4 0.6 0.8 1.0 0.2 0.7 0.1)]

