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
    (let
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
        ;(() (println! $1-over-prop-summation))
    )
        (min-atom ($1-over-prop-summation 1))
    )
)

(= (sum-list $list)
    (foldl-atom $list 0 $acc $x (+ $acc $x))
)

(= (log2 $num) (log-math 2 $num))

(= (-vee $num) (- 0.0 $num))

(= (shannon-entropy $p)
    (if (or (<= $p 0) (>= $p 1))
    0
    (* $p (log2 $p))
    )
)

(= (binary-shannon-entropy $p)
    (if (or (<= $p 0) (>= $p 1))
    0
    (- (* (-vee $p) (log2 $p)) (* (- 1 $p) (log2 (- 1 $p))))
    )
)

(= (custom-cons-atom $elem $list)
    (cons-atom $elem $list)
)

(= (compute-entropy $list)
    (foldl-atom $list 0 $acc $x (- $acc (shannon-entropy $x)))
)

(= (joint-entropy-pairwise $pi $pj $mode)
    (function
        (chain (unify $mode min (chain (min-atom($pi $pj)) $pp11 $pp11) (chain (* $pi $pj) $pp11 $pp11)) $p11
            (chain (collapse(superpose(
                (chain (- $pi $p11) $p10 $p10)
                (chain (- $pj $p11) $p01 $p01)
                (chain (+ $p11 (- (- 1 $pi) $pj)) $p00 $p00)
                ))) $list
                (chain (custom-cons-atom $p11 $list) $flist
                    (chain (compute-entropy $flist) $H
                        (return $H)
                    )
                )
            )
        )
    )
)

(= (joint-entropy-compute-helper $i $list $mode)
    (collapse(joint-entropy-pairwise $i (superpose $list) $mode))
)

(= (custom-union-atom1 $exp1 $exp2)
    (union-atom $exp1 $exp2)
)

; !(semantic-correlation (color shape texture function size weight material purpose) (0.9 0.9 0.0 0.8 0.2 0.9 0.7 0.7))
; !(test-function "test")
(= (joint-entropy-compute $candidate $mode)
    (function
        (chain (decons-atom $candidate) $ht
            (unify ($head $tail) $ht
                (chain (unify $tail () () (joint-entropy-compute-helper $head $tail $mode)) $jentropy
                    (chain (eval (joint-entropy-compute $tail $mode)) $tentropy
                        (chain (custom-union-atom1 $jentropy $tentropy) $result (return $result))
                    )
                )
                (return ())
            )
        )
    )
)
; !(joint-entropy-compute-helper 0.9 (0.9 0.0 0.8 0.2 0.9 0.7 0.7))
; !(joint-entropy-pairwise 0.9 0.9 min)
; !(joint-entropy-compute (0.9 0.9 0.0 0.8 0.2 0.9 0.7 0.7) min)
; !(list-entropy-compute-helper 3 (2 3 4 5 6 7))
; !(joint-entropy-pairwise 0.7 0.5 independent)

(= (total-correlation-entropy $candidate $mode)
    (function
        (chain (map-atom $candidate $elem (binary-shannon-entropy $elem)) $indiv-entropy
            (chain (sum-list $indiv-entropy) $indiv-entropy-sum
                (unify $indiv-entropy-sum 0 (return 0.0)
                    (chain (joint-entropy-compute $candidate $mode) $pairwise-joint-entropy
                        (chain (sum-list $pairwise-joint-entropy) $pairwise-joint-entropy-sum
                            (chain (size-atom $candidate) $len
                                (chain (/ (* $pairwise-joint-entropy-sum 2) (* $len (- $len 1))) $average-joint-entropy
                                    (chain (- $indiv-entropy-sum $average-joint-entropy) $total-correlation
                                            (chain (/ $total-correlation $indiv-entropy-sum) $normalized-correlation (return $normalized-correlation)                                       
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )
    )
)

(= (Alpha) 0.3)

(= (coherence $props $degrees)
    (let $tc (total-correlation-entropy $degrees min)
        (let $tv (isnan-math $tc)
            (let $ftc (if $tv 0 $tc)
                (let $sim (semantic-correlation $props $degrees) (+ (* (Alpha) $ftc) (* (- 1 (Alpha)) $sim)))        
            )        
        )
    )
)

(= (objectives $concept1 $concept2 $candidate-degree)
    (function
        (chain (get-prop-value-pairs $concept1) $prop-val-pairs
            (chain (get-properties $prop-val-pairs) $props
                (return (collapse(superpose((mu-hqblend $candidate-degree $concept1 $concept2) (coherence $props $candidate-degree)))))
            )
        )
    )
)

(= (dominates $u $v)
    (and (all-true (compare-lists $u $v >=)) (any-true (compare-lists $u $v >)))
)

(= (custom-unify $var1 $var2 $op1 $op2)
    (function
        (chain (unify $var1 $var2 $op1 $op2) $result (return $result))
    )
)

(= (check-cross-dominance $obj1 $obj2)
    (if (dominates $obj1 $obj2) True (if (dominates $obj2 $obj1) False True))
)

(= (non-deter-non-dominated-helper $obj $obj-tail)
    (all-true (collapse
        (check-cross-dominance $obj (superpose $obj-tail))
    ))
)

(= (non-dominated-helper $obj $obj-tail)
    (function
        (chain (decons-atom $obj-tail) $ht
            (unify ($head $tail) $ht
                (chain (eval (dominates $obj $head)) $head-res
                    (return (custom-unify $head-res True
                        (chain (eval (non-dominated-helper $obj $tail)) $tail-res
                            $tail-res
                        )
                        (chain (eval (dominates $head $obj)) $head-res2
                            (custom-unify $head-res2 True
                                False
                                (eval (non-dominated-helper $obj $tail))
                            )
                        )
                    ))
                )
                (return True)
            )
        )
    )
)

(= (non-dominated-sort-helper $objs-list $objs-tail $index)
    (function
        (chain (decons-atom $objs-tail) $ht
            (unify ($fhead $ftail) $ht
                (chain (index-atom $objs-list $index) $head      
                    (chain (filter-list $objs-list $head) $filtered-objs-list
                        (chain (non-dominated-helper $head $filtered-objs-list) $head-res
                            (chain (+ 1 $index) $new-index
                                (chain (eval (non-dominated-sort-helper $objs-list $ftail $new-index)) $tail-res
                                    (chain (custom-cons-atom $head-res $tail-res) $result (return $result))
                                )
                            )
                        )
                    )
                )
                (return ())
            )
        )
    )
)

(= (non-dominated-sort $objs-list $objs-tv-list $index $accum)
    (function
        (chain (decons-atom $objs-tv-list) $ht
            (chain (index-atom $objs-list $index) $index-obj
                (unify ($head $tail) $ht
                    (chain (unify $head True (custom-cons-atom $index-obj $accum) $accum) $new-accum
                        (chain (+ 1 $index) $new-index
                            (chain (eval (non-dominated-sort $objs-list $tail $new-index $new-accum)) $tail-res (return $tail-res))
                        )
                    )
                    (return $accum)
                )
            )
        )
    )
)

(= (non-deter-non-dominated-sort-helper $var $objs-list)
    (let $filtered-objs (filter-list $objs-list $var) (if (non-deter-non-dominated-helper $var $filtered-objs) $var Empty))
)

(= (non-deter-non-dominated-sort $objs-list)
    (collapse
        (non-deter-non-dominated-sort-helper (superpose $objs-list) $objs-list)
    )
)

; (= (objs-list) ((7 9.1) (2 3) (6 8) (2 3) (4 6) (8 9) (3 5) (4 6)))
; !(non-dominated-sort-helper (objs-list) (objs-list) 0)
; !(non-dominated-sort (objs-list) (non-dominated-sort-helper (objs-list) (objs-list) 0) 0 ())

; !(non-deter-non-dominated-sort (objs-list))

(= (check-non-dominated $indiv $candidates)
    (let ($indiv-obj $candis-objs) ((index-atom $indiv 1) (let $unzipped-candis (unzip-list $candidates) (index-atom $unzipped-candis 1))) (let $filtered-candis-objs (filter-list $candis-objs $indiv-obj) (if (non-deter-non-dominated-helper $indiv-obj $filtered-candis-objs) $indiv Empty)))
)

(= (filter-non-dominated $candidates)
    (collapse
        (check-non-dominated (superpose $candidates) $candidates)
    )
)

; (= (candidates-list) (((1 1 1 1 1 1) (7 9.1)) ((1 0 1 0 1 0) (2 3)) ((1 1 0 0 1 1) (6 8)) ((1 1 1 0 0 0) (2 3)) ((1 1 0 0 1 1) (4 6)) ((1 1 1 1 1 0) (8 9)) ((0 0 0 0 0 1) (3 5)) ((0 0 0 0 1 1) (4 6))))

; !(filter-non-dominated (candidates-list))

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


(= (multi-objective-check $best-sample-with-fitness)
    (let $one-sample (index-atom $best-sample-with-fitness 0)
        (let $first-atom (car-atom $one-sample)
            (if (== (size-atom $first-atom) 2) True False
            )))
)



(= (single-objective-blend $best-sample-with-fitness $concept-pair $network $eval)
    (let $best-fitness (index-atom $best-sample-with-fitness 1)
        (if (>= $best-fitness 0)
                (let $best-candidate (let $best-sample (index-atom $best-sample-with-fitness 0) (index-atom $best-sample 0))
                    (let $best-cand-mu-emergence (mu-emergence $best-candidate (property-max (testconcept1) (testconcept2)))
                        (let $blend ($network $concept-pair $best-cand-mu-emergence)
                            (if $eval
                            (let ($blend-name $blendpropwithoutprov) ((index-atom $blend 2) (cons-blend-properties (testconcept1) $best-candidate))
                                (let ($input1 $input2 $concept1 $concept2) ((Input1) (Input2) (testconcept1) (testconcept2))
                                    (let $blenpropwithprov (provenance-helper ($input1 (get-prop-value-pairs $concept1)) ($input2 (get-prop-value-pairs $concept2)) ($blend-name $blendpropwithoutprov))
                                        (let ($formattedcon1 $formattedcon2 $formattedblend) (format-concepts ($input1 $concept1) ($input2 $concept2) ($blend-name $blenpropwithprov))
                                            (let ($integration-res $good-reason-res $unpacking-res $web-res $topology-res $metonymy-res) (op-evaluater $formattedblend $formattedcon1 $formattedcon2)
                                                (Formed Blend: $blend-name
                                                Evaluation-Metrics:
                                                Integration: $integration-res
                                                Good-reason: $good-reason-res
                                                Unpacking: $unpacking-res
                                                Web: $web-res
                                                Topology: $topology-res
                                                Metonymy: $metonymy-res
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                            $blend
                            )
                        )
                    )
                )
            (Error $best-fitness NegativeMu-hqblendValue)
        )
    )
)


(= (multi-objective-blend-single $single-best-blend $concept-pair $network $eval)
    (let $scalarized-fitness (index-atom $single-best-blend 1)
    ((if (> $scalarized-fitness 0)
                        ;; -- PATH A: Fitness is positive, attempt blend --
                        (let $best-candidate (let $unscalarized-zip (index-atom $single-best-blend 0) (let ($props $unscalarized-fitness-score) $unscalarized-zip $props))
                            (let () (println! (best single-candidate: $best-candidate))
                                (let $best-cand-mu-emergence (miu-emergence $best-candidate (property-max (testconcept1) (testconcept2)))
                                    (let () (println! (best candidate miu emergence: $best-cand-mu-emergence))
                                        (let $blend ($network $concept-pair $best-cand-mu-emergence)
                                            (let () (println! (blend: $blend))
                                                (if $eval
                                                    ;; -- Sub-Path A1: Eval is True --
                                                    (let ($blend-name $blendpropwithoutprov) ((index-atom $blend 2) (cons-blend-properties (testconcept1) $best-candidate))
                                                        (let ($input1 $input2 $concept1 $concept2) ((Input1) (Input2) (testconcept1) (testconcept2))
                                                            (let $blenpropwithprov (provenance-helper ($input1 (get-prop-value-pairs $concept1)) ($input2 (get-prop-value-pairs $concept2)) ($blend-name $blendpropwithoutprov))
                                                                (let ($formattedcon1 $formattedcon2 $formattedblend) (format-concepts ($input1 $concept1) ($input2 $concept2) ($blend-name $blenpropwithprov))
                                                                    (let ($integration-res $good-reason-res $unpacking-res $web-res $topology-res $metonymy-res) (op-evaluater $formattedblend $formattedcon1 $formattedcon2)
                                                                        (Formed Blend: $blend-name
                                                                        Evaluation-Metrics:
                                                                        Integration: $integration-res
                                                                        Good-reason: $good-reason-res
                                                                        Unpacking: $unpacking-res
                                                                        Web: $web-res
                                                                        Topology: $topology-res
                                                                        Metonymy: $metonymy-res)
                                                                    )
                                                                )
                                                            )
                                                        )
                                                    )
                                                    ;; -- Sub-Path A2: Eval is False (Skip this item) --
                                                    $blend
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                        )
                        ;; -- PATH B: Fitness is <= 0 (Skip this item) --
                        (println! (Blend ignored. Fitness cannot be less than zero! Scalarized-fitness: $scalarized-fitness Blend: $single-best-blend))
                    )))
)


(= (multi-objective-blend-loop $best-sample-with-fitness $concept-pair $network $eval)
    (map-atom $best-sample-with-fitness $single-best-blend (multi-objective-blend-single $single-best-blend $concept-pair $network $eval)))


(= (blend $GAorCMA $eval)
    (let $final-pop ($GAorCMA)                                    ;Moedd-cma-gen
        (let $best-sample-with-fitness (index-atom $final-pop (- (GENERATIONS) 1))
            (let $multi-objective-check-result (multi-objective-check $best-sample-with-fitness)
                (let $concept-pair (let (Concept $x $y) (testconcept1) $x)
                    (let $network (gpt_network_selector $concept-pair)
                        (if (not (== $network None))
                            (if $multi-objective-check-result
                                (let () (println! (Multi-objective check result: $multi-objective-check-result)) (multi-objective-blend-loop $best-sample-with-fitness $concept-pair $network $eval))
                                (let () (println! (Multi-objective check result: $multi-objective-check-result)) (single-objective-blend $best-sample-with-fitness $concept-pair $network $eval))
                            )
                            (Error $network NoNetworkSelected)
                        )
                    )
                )
            )
        )
    )
)
