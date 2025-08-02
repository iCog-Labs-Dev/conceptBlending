! (import! &self utils:list-op-utils)
!(import! &self libs)

(: Concept Concept)

; ###################### Helper functions ##########################

(=(get-prop-value-pairs $concept)
    (let (Concept $x $y) $concept (cdr-atom $y))
)
;! (get-prop-value-pairs (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))))
; Output [((mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))]


(= (get-property $prop-value-pair)
    (let ($x $y) $prop-value-pair $x)
)
;! (get-property (mobility 0.9))
; Output [mobility]


(= (get-properties $prop-value-pairs)
    (map-atom $prop-value-pairs $x (get-property $x))
)
;!(get-properties ((mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7)))
; Output [(mobility intelligence web-creation social-structure predatory-behavior communication symbolism physical-strength)]


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
        (list-multiply $property1values $property2values $properties)
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

(: decimal (-> Number Number))
(=(decimal $number)
    (+ $number 0.0)
)
; !(decimal 1)
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
;! (property-degree (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))))
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
(= (mu-emergence $candidate-degrees $properties-max)
    (
        let
        ($propertiesvalues $properties)
        (collapse(superpose((get-values $properties-max) (get-properties $properties-max))))
        (list-substract $candidate-degrees $propertiesvalues $properties)
    )
)
;! (mu-emergence (0.9030899869919434 0.9030899869919434 0.9030899869919434 0.9030899869919434 0.9030899869919434 0.9030899869919434 0.9030899869919434 0.9030899869919434)(property-max (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))) (Concept Spider@Man (Property (mobility 0.8) (intelligence 0.2) (web-creation 1.0) (social-structure 0.3) (predatory-behavior 0.9) (communication 0.4) (symbolism 0.6) (physical-strength 0.3)))))
; Output [((mobility 0.0030899869919434053) (intelligence 0.0030899869919434053) (web-creation 0.0) (social-structure 0.10308998699194338) (predatory-behavior 0.0030899869919434053) (communication 0.0030899869919434053) (symbolism 0.20308998699194347) (physical-strength 0.20308998699194347))]


; ###################### Calculate mu hq blend ##########################
(= (mu-hqblend $candidate-degrees $concept1 $concept2)
    (let*(
        ($properties-max (property-max $concept1 $concept2))
        ($properties-min (property-min $concept1 $concept2))
        ($mu-emer (mu-emergence $candidate-degrees $properties-max))
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

;;;; Vital Relation Extraction ;;;;
(= (vit-rel-extraction $input1 $input2)
    (let ($vital-relation-1 $vital-relation-2) (gpt_vital_relation $input1 $input2)
        (let $vital-relations (union-atom $vital-relation-1 $vital-relation-2) (unique-atom $vital-relations))
    )
)

;;;; Vector Extraction ;;;;
(= (vec-extraction $input1 $input2)
    (let $vital-relations (vit-rel-extraction $input1 $input2)
        (let $vec-concepts (gpt_vector $input1 $input2 $vital-relations) $vec-concepts)
    )
)

;;;; Add vectorized concepts to self space ;;;;
(= (add-concepts)
    (let ($concept1 $concept2) (vec-extraction (Input1) (Input2))
        (superpose((add-atom &self (= (concept1) $concept1)) (add-atom &self (= (concept2) $concept2))))
    )
)

(= (blend $GAorCMA)
    (let $final-pop ($GAorCMA)
        (let $best-sample-with-fitness (index-atom $final-pop (- (GENERATIONS) 1))
            (let $best-fitness (index-atom $best-sample-with-fitness 1)
                (if (>= $best-fitness 0)
                    (let $concept-pair (let (Concept $x $y) (concept1) $x)
                        (let $network (gpt_network_selector $concept-pair)
                            (if (not (== $network None))
                                (let $best-candidate (let $best-sample (index-atom $best-sample-with-fitness 0) (index-atom $best-sample 0))
                                    (let $best-cand-mu-emergence (mu-emergence $best-candidate (property-max (concept1) (concept2)))
                                        ($network $concept-pair $best-cand-mu-emergence)
                                    )
                                )
                                (Error $newtwork NoNetworkSelected)
                            )
                        )
                    )
                    (Error $best-fitness NegativeMu-hqblendValue)
                )
            )
        )
    )
)
