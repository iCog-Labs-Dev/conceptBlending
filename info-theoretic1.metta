! (import! &self conceptual_blending)


(: Concept Concept)

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
;! (get-properties (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))))
; Output [((mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))]


(= (get-value $property)
    (let*(
        ($value (cdr-atom $property))
        ($num (car-atom $value))
    )
        $num
    )
)
;! (get-value (mobility 0.9))
; Output [0.9]


(=(get-values $properties)
    (map-atom $properties $property (get-value $property))
)
;! (get-values (get-properties (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7)))))
; Output [(0.9 0.9 0.0 0.8 0.2 0.9 0.7 0.7)]


; ###################### Calculate product of two properites ##########################
(= (property-product $properties1 $properties2)
    (let*(
        ($property1 (car-atom $properties1))
        ($property2 (car-atom $properties2))
        ($num1 (get-value $property1))
        ($num2 (get-value $property2))
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
;! (property-product ((mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7)) ((mobility 0.8) (intelligence 0.2) (web-creation 1.0) (social-structure 0.3) (predatory-behavior 0.9) (communication 0.4) (symbolism 0.6) (physical-strength 0.3)))
; Output [((mobility 0.7200000000000001) (intelligence 0.18000000000000002) (web-creation 0.0) (social-structure 0.24) (predatory-behavior 0.18000000000000002) (communication 0.36000000000000004) (symbolism 0.42) (physical-strength 0.21))]

; ###################### Calculate Number of properties #####################
(: get-number-of-properties (-> Concept Number))
(=(get-number-of-properties $concept)
    (
        let*(
                ($a $concept)
                ($b (superpose $a))
        )
    (if (== (get-metatype $b) Expression)
        (let $c (cdr-atom $b)
            (size-atom $c))
        (empty)
    )
)
)
;!(get-number-of-properties (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))))
; Output [8]

; ################### Convert Number to Decimal ##########################
(: decimal (-> Number Number))
(=(decimal $number)
    (+ $number 0.0)
)
;!(decimal 1)
; Output [1.0]


; ###################### Calculate Probability ##############################
(: property-probability (-> Concept Number))
(=(property-probability $concept)
    (let*(
        ($numberofprops (get-number-of-properties $concept))
        ($probability (/ 1.0 (decimal $numberofprops)))
    )
    $probability
    )
    )
;!(property-probability (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))))
; Output [0.125]

; ###################### Calculate Degree function ##########################
(: property-degree (-> Concept Number))
(=(property-degree $concept)
    (let*(
        ($probability (property-probability $concept))
        ($degree (* -1 (log-math 10 $probability)))
    )
        $degree
    )
)
;! (property-degree (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))))
; Output [0.9030899869919434]

; ###################### Calculate min and max for Properties ##########################
(= (min-property $properties1 $properties2)
    (let*(
        ($property1 (car-atom $properties1))
        ($property2 (car-atom $properties2))
        ($num1 (get-value $property1))
        ($num2 (get-value $property2))
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
;! (min-property ((mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7)) ((mobility 0.8) (intelligence 0.2) (web-creation 1.0) (social-structure 0.3) (predatory-behavior 0.9) (communication 0.4) (symbolism 0.6) (physical-strength 0.3)))
; Output [((mobility 0.8) (intelligence 0.2) (web-creation 0.0) (social-structure 0.3) (predatory-behavior 0.2) (communication 0.4) (symbolism 0.6) (physical-strength 0.3))]


(= (max-property $properties1 $properties2)
    (let*(
        ($property1 (car-atom $properties1))
        ($property2 (car-atom $properties2))
        ($num1 (get-value $property1))
        ($num2 (get-value $property2))
        ($num-properties (size-atom $properties1))
        ($max-prop ((car-atom $property1) (max-atom ($num1 $num2))))
        ;(() (println! $max-prop))
    )
        (if (not (== $num-properties 1))
            (let*(
                ($tail-properties1 (cdr-atom $properties1))
                ($tail-properties2 (cdr-atom $properties2))
                ($call-back (max-property $tail-properties1 $tail-properties2))
                ;(() (println! (quote ($call-back (max-property $tail-properties1 $tail-properties2)))))
            ) 
                (cons-atom $max-prop $call-back) 
            )
            ($max-prop)

        )
    )
)
;! (max-property ((mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7)) ((mobility 0.8) (intelligence 0.2) (web-creation 1.0) (social-structure 0.3) (predatory-behavior 0.9) (communication 0.4) (symbolism 0.6) (physical-strength 0.3)))
; Output [((mobility 0.9) (intelligence 0.9) (web-creation 1.0) (social-structure 0.8) (predatory-behavior 0.9) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))]


; ###################### Calculate min and max for Concepts ##########################
(=(property-min $concept1 $concept2)
    (let*(
        ($properties1 (get-properties $concept1))
        ($properties2 (get-properties $concept2))
    )
        (min-property $properties1 $properties2)
    )
)
;!(property-min (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))) (Concept Spider@Man (Property (mobility 0.8) (intelligence 0.2) (web-creation 1.0) (social-structure 0.3) (predatory-behavior 0.9) (communication 0.4) (symbolism 0.6) (physical-strength 0.3))))
; Output [((mobility 0.8) (intelligence 0.2) (web-creation 0.0) (social-structure 0.3) (predatory-behavior 0.2) (communication 0.4) (symbolism 0.6) (physical-strength 0.3))]


(=(property-max $concept1 $concept2)
    (let*(
        ($properties1 (get-properties $concept1))
        ($properties2 (get-properties $concept2))
    )
        (max-property $properties1 $properties2)
    )
)
;!(property-max (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))) (Concept Spider@Man (Property (mobility 0.8) (intelligence 0.2) (web-creation 1.0) (social-structure 0.3) (predatory-behavior 0.9) (communication 0.4) (symbolism 0.6) (physical-strength 0.3))))
; Output [((mobility 0.9) (intelligence 0.9) (web-creation 1.0) (social-structure 0.8) (predatory-behavior 0.9) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))]


; ###################### Calculate mu emergence ##########################
(= (mu-emergence $property-degree $properties-max)
    (let*(
        ($property (car-atom $properties-max))
        ($num (get-value $property))
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
;! (mu-emergence 0.9030899869919434 (property-max (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))) (Concept Spider@Man (Property (mobility 0.8) (intelligence 0.2) (web-creation 1.0) (social-structure 0.3) (predatory-behavior 0.9) (communication 0.4) (symbolism 0.6) (physical-strength 0.3)))))
; Output [((mobility 0.0030899869919434053) (intelligence 0.0030899869919434053) (web-creation 0.0) (social-structure 0.10308998699194338) (predatory-behavior 0.0030899869919434053) (communication 0.0030899869919434053) (symbolism 0.20308998699194347) (physical-strength 0.20308998699194347))]

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
        ($1-over-prop (/ 1.0 (decimal $num-properties)))
        ($1-over-prop-summation (* $1-over-prop $product-emer-min-summation))
    )
        (min-atom ($1-over-prop-summation 1))
    )
)
! (let*(
        ($concept1 (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))))
        ($concept2 (Concept Spider@Man (Property (mobility 0.8) (intelligence 0.2) (web-creation 1.0) (social-structure 0.3) (predatory-behavior 0.9) (communication 0.4) (symbolism 0.6) (physical-strength 0.3))))
        ($degree (property-degree $concept1))
        ($max (property-max $concept1 $concept2))
        ($min (property-min $concept1 $concept2))
        ($calculated-mu-emergence (mu-emergence $degree $max))
        ($calculated-mu-hqblend (mu-hqblend $calculated-mu-emergence $min))
    )
    $calculated-mu-hqblend
)
;Output [0.027331495447180196]


(= (blend $input1 $input2)
    (let*(
        ($concepts (gpt_vector $input1 $input2))
        ($concept1 (car-atom $concepts))
        ($wrapped-concept2 (cdr-atom $concepts))
        ($concept2 (car-atom $wrapped-concept2))
        ($degree (property-degree $concept1))
        ($max (property-max $concept1 $concept2))
        ($calculated-mu-emergence (mu-emergence $degree $max))
        ($min (property-min $concept1 $concept2))
        ($calculated-mu-hqblend (mu-hqblend $calculated-mu-emergence $min))
        ($concept-pair (let (Concept $x $y) $concept1 $x))
    )
        (if (> $calculated-mu-hqblend 0)
            (let*(
                ($network (gpt_network_selector $concept-pair))
            )
                (if (not (noreduce-eq $network None))
                    ($network $concept-pair $calculated-mu-emergence)
                    (empty)
                )
            )
            (empty)
        )
    )
)
 ! (blend "Bat" "Man")
; [(doubleScope (expand Bat Man) BatMan (extended NocturnalSymbolicHero))]
