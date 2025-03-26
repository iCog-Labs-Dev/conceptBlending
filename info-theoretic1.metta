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


; ###################### Calculate product of two properites ##########################
(= (property-product $properties1 $properties2)
    (let*(
        ($property1 (car-atom $properties1))
        ($property2 (car-atom $properties2))
        ($num1 (get-num $property1))
        ($num2 (get-num $property2))
        ($num-properties (size-atom $properties1))
        ($product ((car-atom $property1) (* $num1 $num2)))
    )
        (if (not (== $num-properties 1))
            (let*(
                ($tail-properties1 (cdr-atom $properties1))
                ($tail-properties2 (cdr-atom $properties2))
                ($call-back (property-product $tail-properties1 $tail-properties2))
            )
                (cons-atom $product $call-back)
            )
            ($product)
        )
    )
)
; ! (property-product ((web-creation 0.1) (intelligence 0.2) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1)) ((web-creation 1.0) (intelligence 0.4) (physical-strength 0.1) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1)))
; Output [((web-creation 0.1) (intelligence 0.08000000000000002) (physical-strength 0.06) (mobility 0.6400000000000001) (predatory-behavior 1.0) (social-structure 0.04000000000000001) (symbolism 0.48999999999999994) (tool-use 0.010000000000000002))]
