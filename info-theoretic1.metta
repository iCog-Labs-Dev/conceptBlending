! (import! &self conceptual_blending)
! (import! &self list-op-utils)
; Defines type of Concept
(: Concept Concept)

; ###################### Helper functions ##########################

; extract the list of (prop value) pair from the concept
(=(get-prop-value-pairs $concept)
    (let (Concept $x $y) $concept (cdr-atom $y))
)

;! (get-prop-value-pairs (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))))
; Output [((mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))]

; extracts the property name from a pair
(= (get-property $prop-value-pair)
    (let ($x $y) $prop-value-pair $x)
)
+;! (get-property (mobility 0.9))
+; Output [mobility]

; Maps over all pairs to get just the property names
(= (get-properties $prop-value-pairs)
    (map-atom $prop-value-pairs $x (get-property $x))
)
;!(get-properties ((mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7)))
; Output [(mobility intelligence web-creation social-structure predatory-behavior communication symbolism physical-strength)]

; extracts numeric values from one or all properties
(= (get-value $property)
    (let ($x $y) $property $y)
)
;! (get-value (mobility 0.9))
; Output [0.9]


(= (get-values $properties)
    (map-atom $properties $x (get-value $x))
)
;! (get-values (get-prop-value-pairs (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7)))))
; Output [(0.9 0.9 0.0 0.8 0.2 0.9 0.7 0.7)]


; ###################### Calculate product of two properites ##########################

(= (property-product $properties1 $properties2)
    (let
        ($property1values $property2values $properties)
        (collapse(superpose((get-values $properties1) (get-values $properties2) (get-properties $properties1))))
        (tuple-multiply $property1values $property2values $properties)
    )
)
;! (property-product ((mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7)) ((mobility 0.8) (intelligence 0.2) (web-creation 1.0) (social-structure 0.3) (predatory-behavior 0.9) (communication 0.4) (symbolism 0.6) (physical-strength 0.3)))
; Output [((mobility 0.7200000000000001) (intelligence 0.18000000000000002) (web-creation 0.0) (social-structure 0.24) (predatory-behavior 0.18000000000000002) (communication 0.36000000000000004) (symbolism 0.42) (physical-strength 0.21))]


; ###################### Calculate Number of properties #####################
(: get-number-of-properties (-> Concept Number))
(=(get-number-of-properties $concept)
    (let*(
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
        ((py-atom round) $degree 2)
    )
)
! (property-degree (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))))
; Output [0.9030899869919434]


; ###################### Calculate min and max for Concepts ##########################
(=(property-min $concept1 $concept2)
    (let*(
        (($properties1 $properties2) (collapse(superpose((get-prop-value-pairs $concept1) (get-prop-value-pairs $concept2)))))
        (($properties1values $properties2values $properties) (collapse(superpose((get-values $properties1) (get-values $properties2) (get-properties $properties1)))))
    )
        (min-elements $properties1values $properties2values $properties)
    )
)
;!(property-min (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))) (Concept Spider@Man (Property (mobility 0.8) (intelligence 0.2) (web-creation 1.0) (social-structure 0.3) (predatory-behavior 0.9) (communication 0.4) (symbolism 0.6) (physical-strength 0.3))))
; Output [((mobility 0.8) (intelligence 0.2) (web-creation 0.0) (social-structure 0.3) (predatory-behavior 0.2) (communication 0.4) (symbolism 0.6) (physical-strength 0.3))]


(=(property-max $concept1 $concept2)
    (let*(
        (($properties1 $properties2) (collapse(superpose((get-prop-value-pairs $concept1) (get-prop-value-pairs $concept2)))))
        (($properties1values $properties2values $properties) (collapse(superpose((get-values $properties1) (get-values $properties2) (get-properties $properties1)))))
    )
        (max-elements $properties1values $properties2values $properties)
    )
)
;!(property-max (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))) (Concept Spider@Man (Property (mobility 0.8) (intelligence 0.2) (web-creation 1.0) (social-structure 0.3) (predatory-behavior 0.9) (communication 0.4) (symbolism 0.6) (physical-strength 0.3))))
; Output [((mobility 0.9) (intelligence 0.9) (web-creation 1.0) (social-structure 0.8) (predatory-behavior 0.9) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))]


; ###################### Calculate mu emergence ##########################
(= (mu-emergence $property-degree $properties-max)
    (
        let
        ($propertiesvalues $properties)
        (collapse(superpose((get-values $properties-max) (get-properties $properties-max))))
        (tuple-substract $property-degree $propertiesvalues $properties)
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
; ! (let*(
;     ($concept1 (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))))
;     ($concept2 (Concept Spider@Man (Property (mobility 0.8) (intelligence 0.2) (web-creation 1.0) (social-structure 0.3) (predatory-behavior 0.9) (communication 0.4) (symbolism 0.6) (physical-strength 0.3))))
;     ($degree (property-degree $concept1))
;     ($max (property-max $concept1 $concept2))
;     ($min (property-min $concept1 $concept2))
;     ($calculated-mu-emergence (mu-emergence $degree $max))
;     ($calculated-mu-hqblend (mu-hqblend $calculated-mu-emergence $min))
; )
; $calculated-mu-hqblend
; )
;Output [0.027331495447180196]

;                                                 ###################### Calculate Intersection ##########################
; This Function Extracts the intersection of the given list of vital realtions from gpt_vital_relation function
(=(extract-intersection $list )
(foldl-atom $list (empty) $acc $item (let ($head $tail) $item
  (if (== $head Intersection) $tail $acc))))

; checks if a given item is a member of the list
(= (is-member $item $list)
    (foldl-atom $list False $acc $element
        (or $acc (== $item $element))
    )
)
; Helper function to check if a vital relation is the intersection of the two concepts 
; if it is it multiplies the value of the property by 1.5
(=(weight ($prop $val) $vital-types)( if (is-member $prop $vital-types)
                 ($prop (* 1.5 $val)) ; boost important properties
                ($prop $val)
            ))
; Applies the vital weighting to the mu-emergence values
(= (apply-vital-weighting $mu-emergence $vital-types)(
    collapse (weight (superpose $mu-emergence) $vital-types)
))


(= (blend $input1 $input2)
    (let*(
        ($concepts (gpt_vector $input1 $input2))
        ($concept1 (car-atom $concepts))
        ($wrapped-concept2 (cdr-atom $concepts))
        ($concept2 (car-atom $wrapped-concept2))
        ;; Call Vital relation Agent
        ($vital-output ((gpt_vital_relation $input1 $input2)))
        ($vital-types (extract-intersection $vital-output))
        (() (println! $vital-types))
        ($degree (property-degree $concept1))
        ($max (property-max $concept1 $concept2))
        ($calculated-mu-emergence (mu-emergence $degree $max))
        ($weighted-mu-emergence (apply-vital-weighting $calculated-mu-emergence $vital-types))
        ($min (property-min $concept1 $concept2))
        ($calculated-mu-hqblend (mu-hqblend $weighted-mu-emergence $min))
        ($concept-pair (let (Concept $x $y) $concept1 $x))
    )
        (if (> $calculated-mu-hqblend 0)
            (let*(
                ($network (gpt_network_selector $concept-pair))
            )
                (if (not (noreduce-eq $network None))
                    ($network $concept-pair $weighted-mu-emergence)
                    (empty)
                )
            )
            (empty)
        )
    )
)


;! (gpt_vital_relation house boat)
 ! (blend Bat Man)
; [(doubleScope (expand Bat Man) BatMan (extended NocturnalSymbolicHero))]
