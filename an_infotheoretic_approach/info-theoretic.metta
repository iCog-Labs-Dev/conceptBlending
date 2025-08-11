!(import! &self utils:list-op-utils)
!(import! &self libs)

(: Concept Concept)

; ###################### Helper functions ##########################

(=(get-prop-value-pairs $concept)
    (let (Concept $x $y) $concept (cdr-atom $y))
)

(= (get-property $prop-value-pair)
    (let ($x $y) $prop-value-pair $x)
)

(= (get-properties $prop-value-pairs)
    (map-atom $prop-value-pairs $x (get-property $x))
)

(= (get-value $property)
    (let ($x $y) $property $y)
)

(= (get-values $properties)
    (map-atom $properties $x (get-value $x))
)

; ###################### Calculate product of two properites ##########################
(= (property-product $properties1 $properties2)
    (let
        ($property1values $property2values $properties)
        (collapse(superpose((get-values $properties1) (get-values $properties2) (get-properties $properties1))))
        (list-multiply $property1values $property2values $properties)
    )
)

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

(: decimal (-> Number Number))
(=(decimal $number)
    (+ $number 0.0)
)

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

; ###################### Calculate min and max for Concepts ##########################
(=(property-min $concept1 $concept2)
    (let*(
        (($properties1 $properties2) (collapse(superpose((get-prop-value-pairs $concept1) (get-prop-value-pairs $concept2)))))
        (($properties1values $properties2values $properties) (collapse(superpose((get-values $properties1) (get-values $properties2) (get-properties $properties1)))))
    )
        (min-elements $properties1values $properties2values $properties)
    )
)

(=(property-max $concept1 $concept2)
    (let*(
        (($properties1 $properties2) (collapse(superpose((get-prop-value-pairs $concept1) (get-prop-value-pairs $concept2)))))
        (($properties1values $properties2values $properties) (collapse(superpose((get-values $properties1) (get-values $properties2) (get-properties $properties1)))))
    )
        (max-elements $properties1values $properties2values $properties)
    )
)

; ###################### Calculate mu emergence ##########################
(= (mu-emergence $candidate-degrees $properties-max)
    (
        let
        ($propertiesvalues $properties)
        (collapse(superpose((get-values $properties-max) (get-properties $properties-max))))
        (list-substract $candidate-degrees $propertiesvalues $properties)
    )
)

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

(= (cons-blend-properties $concept1 $blend-prop-values)
    (let (Concept $concpair $properties) $concept1
        (let ($length $props) ((size-atom $blend-prop-values) (cdr-atom $properties))
            (collapse(superpose
                (
                    (if (>= (- $length 1) 0) (let $prop0 (index-atom $props 0) (let ($prop0name $blendprop0val) ((car-atom $prop0) (index-atom $blend-prop-values 0)) ($prop0name $blendprop0val))) Empty)
                    (if (>= (- $length 2) 0) (let $prop1 (index-atom $props 1) (let ($prop1name $blendprop1val) ((car-atom $prop1) (index-atom $blend-prop-values 1)) ($prop1name $blendprop1val))) Empty)
                    (if (>= (- $length 3) 0) (let $prop2 (index-atom $props 2) (let ($prop2name $blendprop2val) ((car-atom $prop2) (index-atom $blend-prop-values 2)) ($prop2name $blendprop2val))) Empty)
                    (if (>= (- $length 4) 0) (let $prop3 (index-atom $props 3) (let ($prop3name $blendprop3val) ((car-atom $prop3) (index-atom $blend-prop-values 3)) ($prop3name $blendprop3val))) Empty)
                    (if (>= (- $length 5) 0) (let $prop4 (index-atom $props 4) (let ($prop4name $blendprop4val) ((car-atom $prop4) (index-atom $blend-prop-values 4)) ($prop4name $blendprop4val))) Empty)
                    (if (>= (- $length 6) 0) (let $prop5 (index-atom $props 5) (let ($prop5name $blendprop5val) ((car-atom $prop5) (index-atom $blend-prop-values 5)) ($prop5name $blendprop5val))) Empty)
                    (if (>= (- $length 7) 0) (let $prop6 (index-atom $props 6) (let ($prop6name $blendprop6val) ((car-atom $prop6) (index-atom $blend-prop-values 6)) ($prop6name $blendprop6val))) Empty)
                    (if (>= (- $length 8) 0) (let $prop7 (index-atom $props 7) (let ($prop7name $blendprop7val) ((car-atom $prop7) (index-atom $blend-prop-values 7)) ($prop7name $blendprop7val))) Empty)
                    (if (>= (- $length 9) 0) (let $prop8 (index-atom $props 8) (let ($prop8name $blendprop8val) ((car-atom $prop8) (index-atom $blend-prop-values 8)) ($prop8name $blendprop8val))) Empty)
                    (if (>= (- $length 10) 0) (let $prop9 (index-atom $props 9) (let ($prop9name $blendprop9val) ((car-atom $prop9) (index-atom $blend-prop-values 9))($prop9name $blendprop9val))) Empty)
                )
            ))
        )
    )    
)

(= (format-concepts ($input1 $concept1) ($input2 $concept2) ($blend $blendproperties))
    (let ($con1rels $con2rels $blenrels) (collapse(superpose((get-concept-relations $input1) (get-concept-relations $input2) (get-concept-relations $blend))))
        (let ((Concept $conpair1 $propsc1) (Concept $conpair2 $propsc2)) ($concept1 $concept2)
            (let ($formattedcon1 $formattedcon2 $formattedblend) (collapse(superpose((let $conce1rels (cons-atom Relations $con1rels) (Concept $input1 $propsc1 $conce1rels)) 
                                                                                    (let $conce2rels (cons-atom Relations $con2rels) (Concept $input2 $propsc2 $conce2rels))   
                                                                                    (let ($blenprops $blendrels) ((cons-atom Property $blendproperties) (cons-atom Relations $blenrels)) (Blend $blend $blenprops $blendrels))))) ($formattedcon1 $formattedcon2 $formattedblend)
            )
        )
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
                                        (let $blend ($network $concept-pair $best-cand-mu-emergence)
                                            ; (if $eval
                                            ; (let ($blend-name $blendpropwithoutprov) ((index-atom $blend 2) (cons-blend-properties (concept1) $best-candidate))
                                            ;     (let ($input1 $input2 $concept1 $concept2) ((Input1) (Input2) (concept1) (concept2))
                                            ;         (let $blenpropwithprov (provenance-helper ($input1 (get-prop-value-pairs $concept1)) ($input2 (get-prop-value-pairs $concept2)) ($blend-name $blendpropwithoutprov))
                                            ;             (let ($formattedcon1 $formattedcon2 $formattedblend) (format-concepts ($input1 $concept1) ($input2 $concept2) ($blend-name $blenpropwithprov))
                                            ;                 (let ($integration-res $good-reason-res $unpacking-res $web-res $topology-res $metonymy-res) (op-evaluater $formattedblend $formattedcon1 $formattedcon2)
                                            ;                     (Formed Blend: $blend-name
                                            ;                     Evaluation-Metrics:
                                            ;                     Integration: $integration-res
                                            ;                     Good-reason: $good-reason-res
                                            ;                     Unpacking: $unpacking-res
                                            ;                     Web: $web-res
                                            ;                     Topology: $topology-res
                                            ;                     Metonymy: $metonymy-res
                                            ;                     )
                                            ;                 )
                                            ;             )
                                            ;         )
                                            ;     )
                                            ; )
                                            ; $blend
                                            ; )
                                            $blend
                                        )
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
