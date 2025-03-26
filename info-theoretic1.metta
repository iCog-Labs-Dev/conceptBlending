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


; ###################### Calculate Degree function ##########################
(=(property-degree $concept)
    (let*(
        ($properties (get-properties $concept))
        ($num-properties (size-atom $properties))
        ($probability (/ 1.0 $num-properties))
        ($degree (* -1 (log-math 10 $probability)))
    )
        $degree
    )
)
; ! (property-degree (Concept Spider@Man (Property (web-creation 1.0) (intelligence 0.4) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
; Output [0.9030899869919434]


; ###################### Calculate min and max for Properties ##########################
(= (min-property $properties1 $properties2)
    (let*(
        ($property1 (car-atom $properties1))
        ($property2 (car-atom $properties2))
        ($num1 (get-num $property1))
        ($num2 (get-num $property2))
        ($num-properties (size-atom $properties1))
        ($min-prop ((car-atom $property1) (min-atom ($num1 $num2))))
    )
        (if (not (== $num-properties 1))
            (let*(
                ($tail-properties1 (cdr-atom $properties1))
                ($tail-properties2 (cdr-atom $properties2))
                ($call-back (min-property $tail-properties1 $tail-properties2))
            )
                (cons-atom $min-prop $call-back)
            )
            ($min-prop)
        )
    )
)
; ! (min-property ((web-creation 0.1) (intelligence 0.2) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1)) ((web-creation 1.0) (intelligence 0.4) (physical-strength 0.1) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1)))
; Output [((web-creation 0.1) (intelligence 0.2) (physical-strength 0.1) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))]


(= (max-property $properties1 $properties2)
    (let*(
        ($property1 (car-atom $properties1))
        ($property2 (car-atom $properties2))
        ($num1 (get-num $property1))
        ($num2 (get-num $property2))
        ($num-properties (size-atom $properties1))
        ($max-prop ((car-atom $property1) (max-atom ($num1 $num2))))
    )
        (if (not (== $num-properties 1))
            (let*(
                ($tail-properties1 (cdr-atom $properties1))
                ($tail-properties2 (cdr-atom $properties2))
                ($call-back (max-property $tail-properties1 $tail-properties2))
            )
                (cons-atom $max-prop $call-back)
            )
            ($max-prop)

        )
    )
)
; ! (max-property ((web-creation 0.1) (intelligence 0.2) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1)) ((web-creation 1.0) (intelligence 0.4) (physical-strength 0.1) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1)))
; Output [((web-creation 1.0) (intelligence 0.4) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))]


; ###################### Calculate min and max for Concepts ##########################
(=(property-min $concept1 $concept2)
    (let*(
        ($properties1 (get-properties $concept1))
        ($properties2 (get-properties $concept2))
    )
        (min-property $properties1 $properties2)
    )
)
; ! (property-min (Concept Spider@Man (Property (web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))) (Concept Spider@Man (Property (web-creation 1.0) (intelligence 0.4) (physical-strength 0.2) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
; Output [((web-creation 0.1) (intelligence 0.3) (physical-strength 0.2) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))]


(=(property-max $concept1 $concept2)
    (let*(
        ($properties1 (get-properties $concept1))
        ($properties2 (get-properties $concept2))
    )
        (max-property $properties1 $properties2)
    )
)
; ! (property-max (Concept Spider@Man (Property (web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))) (Concept Spider@Man (Property (web-creation 1.0) (intelligence 0.4) (physical-strength 0.2) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
; Output [((web-creation 1.0) (intelligence 0.4) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))]


; ###################### Calculate mu emergence ##########################
(= (mu-emergence $property-degree $properties-max)
    (let*(
        ($property (car-atom $properties-max))
        ($num (get-num $property))
        ($num-properties (size-atom $properties-max))
        ($property-minus-num (- $property-degree $num))
        ($non-zero (max-atom ($property-minus-num 0)))
        ($result ((car-atom $property) $non-zero))
    )
        (if (not (== $num-properties 1))
            (let*(
                ($tail-properties (cdr-atom $properties-max))
                ($call-back (mu-emergence $property-degree $tail-properties))
            )
                (cons-atom $result $call-back)
            )
            ($result)
        )
    )
)
; ! (mu-emergence 0.9030899869919434 (property-max (Concept Spider@Man (Property (web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))) (Concept Spider@Man (Property (web-creation 1.0) (intelligence 0.4) (physical-strength 0.2) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1)))))
; Output [((web-creation 0.0) (intelligence 0.5030899869919434) (physical-strength 0.30308998699194345) (mobility 0.10308998699194338) (predatory-behavior 0.0) (social-structure 0.7030899869919434) (symbolism 0.20308998699194347) (tool-use 0.8030899869919434))]

; ! (let*(
;         ($concept1 (Concept Spider@Man (Property (web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
;         ($concept2 (Concept Spider@Man (Property (web-creation 1.0) (intelligence 0.4) (physical-strength 0.2) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
;         ($degree (property-degree $concept1))
;         ($max (property-max $concept1 $concept2))
;         ($calculated-mu-emergence (mu-emergence $degree $max))
;     )
;     $calculated-mu-emergence
; )
; Output [((web-creation 0.0) (intelligence 0.5030899869919434) (physical-strength 0.30308998699194345) (mobility 0.10308998699194338) (predatory-behavior 0.0) (social-structure 0.7030899869919434) (symbolism 0.20308998699194347) (tool-use 0.8030899869919434))]


; ###################### Calculate mu hq blend ##########################
(= (mu-hqblend $mu-emer $properties-min)
    (let*(
        ($product-emer-min (property-product $mu-emer $properties-min))
        ($product-emer-min-nums (get-values $product-emer-min))
        ($product-emer-min-summation (foldl-atom $product-emer-min-nums 0 $acc $val (+ $acc $val)))
        ($num-properties (size-atom $product-emer-min))
        ($1-over-prop (/ 1.0 $num-properties))
        ($1-over-prop-summation (* $1-over-prop $product-emer-min-summation))
    )
        (min-atom ($1-over-prop-summation 1))
    )
)
; ! (let*(
;         ($concept1 (Concept Spider@Man (Property (web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
;         ($concept2 (Concept Spider@Man (Property (web-creation 1.0) (intelligence 0.4) (physical-strength 0.2) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
;         ($degree (property-degree $concept1))
;         ($max (property-max $concept1 $concept2))
;         ($min (property-min $concept1 $concept2))
;         ($calculated-mu-emergence (mu-emergence $degree $max))
;         ($calculated-mu-hqblend (mu-hqblend $calculated-mu-emergence $min))
;     )
;     $calculated-mu-hqblend
; )
; Output [0.08213837126018374]
