!(import! &self utils/list-op-utils-rec)
!(import! &self utils/info-theoretic-utils)
; a temporary representation of the function Error
(=(Error $atom $message) 
    $message)

(= (get-prop-value-pairs $concept)
    (let (Concept $x $y) $concept (cdr-atom $y))
)
;  !(get-prop-value-pairs (Concept Spider@Man (Property (web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
(= (get-property $prop-value-pair)
    (let ($x $y) $prop-value-pair $x)
)
; !(get-property (web-creation 0.1))
(= (get-properties $prop-value-pairs)
    (map-atom $prop-value-pairs get-property)
)
; !(get-properties ((web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1)))
(= (get-value $property)
    (let ($x $y) $property $y)
)

(= (get-values $properties)
    (map-atom $properties get-value)
)
; !(get-values ((web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1)))

; ###################### Calculate product of two properites ##########################

(= (property-product $properties1 $properties2)
    (let
        ($property1values $property2values $properties)
        (collapse(superpose((get-values $properties1) (get-values $properties2) (get-properties $properties1))))
        (list-multiply $property1values $property2values $properties)
    )
)

; ! (property-product ((web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8)) ((web-creation 0.2) (intelligence 0.4) (physical-strength 0.5) (mobility 0.9)))
; ###################### Calculate Number of properties #####################


(= (get-number-of-properties $concept)
    (let* (
        ($a $concept)
        ($b (superpose $a))
    )
        (if (is-expr $b)
            (let $c (cdr-atom $b)
                (size-atom $c))
                (empty)
        )
    
     )
)

; !(get-number-of-properties (Concept Spider@Man (Property (web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))

(=(decimal $number)
    (+ $number 0.0)
)

(=(property-probability $concept)
    (let*(
        ($numberofprops (get-number-of-properties $concept))
        ($probability (/ 1.0 (decimal $numberofprops)))
    )
    $probability
    )
)

; !(property-probability (Concept Spider@Man (Property (web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))


; ###################### Calculate Degree function ##########################

(= (py-round $number $digits)
   (py-call (round $number $digits))
)

(=(property-degree $concept)
    (let*(
        ($probability (property-probability $concept))
        ($degree (* -1 (log 10 $probability)))
    )
        (py-round $degree 2)
    )
)

; ###################### Calculate min and max for Concepts ##########################

;  !(property-degree (Concept Spider@Man (Property (web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))

(=(property-min $concept $concept2)
    (let*(
        (($properties1 $properites2) (collapse(superpose ((get-prop-value-pairs $concept) (get-prop-value-pairs $concept2)))))
        (($properties1values $properties2values $properties) (collapse (superpose ((get-values $properties1) (get-values $properites2) (get-properties $properties1)))))

    )
        (min-elements $properties1values $properties2values $properties)
    )
)

(=(property-max $concept1 $concept2)
    (let*(
        (($properties1 $properties2) (collapse(superpose((get-prop-value-pairs $concept1) (get-prop-value-pairs $concept2)))))
        ; ($_ (println! (pmax $properties1 $properties2)))
        (($properties1values $properties2values $properties) (collapse(superpose((get-values $properties1) (get-values $properties2) (get-properties $properties1)))))
    )
        (max-elements $properties1values $properties2values $properties)
    )
)

(= (spiderman)
   (Concept Spider@Man
     (Property
       (web-creation 0.1)
       (intelligence 0.3)
       (strength 0.6)
       (mobility 0.8))))

(= (batman)
   (Concept Bat@Man
     (Property
       (web-creation 0.2)
       (intelligence 0.4)
       (strength 0.5)
       (mobility 0.9))))

; !(property-max (spiderman) (batman))

; !(property-min (spiderman) (batman))

(= (mu-emergence $candidate-degrees $properties-max)
    (let* (
        ; ($_ (println! Starting-mu-emergence))
        (($propertiesvalues $properties) ((get-values $properties-max) (get-properties $properties-max)))
        ; ($_ (println! (Properties-values $propertiesvalues)))
        ($result (list-subtract $candidate-degrees $propertiesvalues $properties))
        ; ($_ (println! (Mu-emergence-end $result)))
    )
        $result
    )
)

;  !(mu-emergence (0.5 0.3 0.2 0.9) ((web-creation 0.1) (intelligence 0.3) (strength 0.5) (mobility 0.8)) )

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
        (min-atom ($1-over-prop-summation))
    )
)

;  !(mu-hqblend (0.5 0.3 0.2 0.9) (batman) (spiderman) )

(= (cons-blend-properties $concept1 $blend-prop-values)
    (let (Concept $concpair $properties) $concept1
        (let ($length $props) ((size-atom $blend-prop-values) (cdr-atom $properties))
            (collapse(superpose
                (
                    (if (>= (- $length 1) 0) (let $prop0 (index-atom $props 0) (let ($prop0name $blendprop0val) ((car-atom $prop0) (index-atom $blend-prop-values 0)) ($prop0name $blendprop0val))) (empty))
                    (if (>= (- $length 2) 0) (let $prop1 (index-atom $props 1) (let ($prop1name $blendprop1val) ((car-atom $prop1) (index-atom $blend-prop-values 1)) ($prop1name $blendprop1val))) (empty))
                    (if (>= (- $length 3) 0) (let $prop2 (index-atom $props 2) (let ($prop2name $blendprop2val) ((car-atom $prop2) (index-atom $blend-prop-values 2)) ($prop2name $blendprop2val))) (empty))
                    (if (>= (- $length 4) 0) (let $prop3 (index-atom $props 3) (let ($prop3name $blendprop3val) ((car-atom $prop3) (index-atom $blend-prop-values 3)) ($prop3name $blendprop3val))) (empty))
                    (if (>= (- $length 5) 0) (let $prop4 (index-atom $props 4) (let ($prop4name $blendprop4val) ((car-atom $prop4) (index-atom $blend-prop-values 4)) ($prop4name $blendprop4val))) (empty))
                    (if (>= (- $length 6) 0) (let $prop5 (index-atom $props 5) (let ($prop5name $blendprop5val) ((car-atom $prop5) (index-atom $blend-prop-values 5)) ($prop5name $blendprop5val))) (empty))
                    (if (>= (- $length 7) 0) (let $prop6 (index-atom $props 6) (let ($prop6name $blendprop6val) ((car-atom $prop6) (index-atom $blend-prop-values 6)) ($prop6name $blendprop6val))) (empty))
                    (if (>= (- $length 8) 0) (let $prop7 (index-atom $props 7) (let ($prop7name $blendprop7val) ((car-atom $prop7) (index-atom $blend-prop-values 7)) ($prop7name $blendprop7val))) (empty))
                    (if (>= (- $length 9) 0) (let $prop8 (index-atom $props 8) (let ($prop8name $blendprop8val) ((car-atom $prop8) (index-atom $blend-prop-values 8)) ($prop8name $blendprop8val))) (empty))
                    (if (>= (- $length 10) 0) (let $prop9 (index-atom $props 9) (let ($prop9name $blendprop9val) ((car-atom $prop9) (index-atom $blend-prop-values 9))($prop9name $blendprop9val))) (empty))
                )
            ))
        )
    )    
)

;!(cons-blend-properties (spiderman) (0.15 0.35 0.55 0.85))

(=(sum-list $list)
    (foldl-atom $list 0 $acc $x (+ $acc $x))
)

; !(sum-list (1 2 3 4 5))


(=(log2 $num) (log-math 2 $num))

; !(log2 8)

(=(-vee $num) (- 0.0 $num))

; !(-vee 5)

(=(shannon-entropy $p) (if (or (<= $p 0) (>= $p 1))
    0
    (* $p (log2 $p))

))

; !(shannon-entropy 0.5)

(=(binary-shannon-entropy $p)
    (if (or (<= $p 0) (>= $p 1))
    0
    (- (* (-vee $p) (log2 $p)) (* (- 1 $p) (log2 (- 1 $p)))
    )
)
)

; !(binary-shannon-entropy 0.5)

(=(custom-cons-atom $elem $list)
    (cons-atom $elem $list)
)

; !(test (custom-cons-atom 42 (1 2 3)) (42 1 2 3))

(=(compute-entropy $list)
    (foldl-atom $list 0 $acc $x (- $acc (shannon-entropy $x))
)
)

; !(test (compute-entropy (0.5 0.5)) 1.0)


(= (joint-entropy-pairwise $pi $pj $mode)
        (let $p11 (if (== $mode min) (let $pp11 (min-atom($pi $pj))  $pp11) (let $pp11 (* $pi $pj) $pp11)) 
            (let $list (collapse(superpose(
                (let $p10 (- $pi $p11)  $p10)
                (let $p01 (- $pj $p11)  $p01)
                (let $p00 (+ $p11 (- (- 1 $pi) $pj))  $p00)
                ))) 
                (let $flist (cons-atom $p11 $list) 
                    (let $H (compute-entropy $flist) 
                        $H
                    )
                )
            )
        )
)

(= (joint-entropy-compute-helper $i $list $mode)
    (collapse (joint-entropy-pairwise $i (superpose $list) $mode))
)

;  !(joint-entropy-compute-helper 0.9 (0.9 0.0 0.8 0.2 0.9 0.7 0.7) min)
; !(joint-entropy-compute-helper 0.9 (0.9 0.0 0.8 0.2 0.9 0.7 0.7) min)



(=(joint-entropy-compute $candidate $mode)
    (if (== $candidate ()) () (let* (
          ($head (car-atom $candidate))
          ($tail (cdr-atom $candidate))
          ($jentropy (if (== $tail ()) () (joint-entropy-compute-helper $head $tail $mode)))
          ($tentropy (eval (joint-entropy-compute $tail $mode)))
          ($result (union-atom $jentropy $tentropy))
    )
    $result
    ))
)

; !(joint-entropy-compute (0.9 0.9 0.0 0.8 0.2 0.9 0.7 0.7) min)
; !(joint-entropy-pairwise 0.9 0.9 min) ; (0.46899559358928117)
; !(joint-entropy-compute-helper 0.9 (0.9 0.0 0.8 0.2 0.9 0.7 0.7) min) ; ((0.46899559358928117 0.46899559358928117 0.9219280948873622 1.1567796494470395 0.46899559358928117 1.1567796494470395 1.1567796494470395))

(= (total-correlation-entropy $candidate $mode)
        (let (map-atom $candidate $elem (binary-shannon-entropy $elem)) $indiv-entropy
            (let $indiv-entropy-sum (sum-list $indiv-entropy)
                (if (== $indiv-entropy-sum 0) 0.0
                    (let $pairwise-joint-entropy (joint-entropy-compute $candidate $mode) 
                        (let $pairwise-joint-entropy-sum (sum-list $pairwise-joint-entropy) 
                            (let $len (size-atom $candidate) 
                                (let $average-joint-entropy (/ (* $pairwise-joint-entropy-sum 2) (* $len (- $len 1))) 
                                    (let $total-correlation (- $indiv-entropy-sum $average-joint-entropy) 
                                            (let $normalized-correlation (/ $total-correlation $indiv-entropy-sum)   $normalized-correlation                                    
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

;  !(total-correlation-entropy (0.9 0.0 0.8 0.2 0.9 0.7 ) min)

(= (Alpha) 0.3)

; (= (coherence $props $degrees)
;     (let $tc (total-correlation-entropy $degrees min)
;         (let $tv (isnan-math $tc)
;             (let $ftc (if $tv 0 $tc)
;                 (let $sim (semantic-correlation $props $degrees) (+ (* (Alpha) $ftc) (* (- 1 (Alpha)) $sim)))        
;             )        
;         )
;     )
; )

(=(coherence $props $degrees) 
    (let* (
        ($tc (total-correlation-entropy $degrees min))
        ($tv (isnan-math $tc))
        ($ftc (if $tv 0 $tc))
        ($sim (semantic-correlation $props $degrees))
        ; ($_ (println! ("Total Correlation: " $ftc " Semantic Similarity: " $sim)))
    )
        (+ (* (Alpha) $ftc) (* (- 1 (Alpha)) $sim))        
    )
)


; !(coherence (intelligence physical-strength agility) (0.3 0.7 0.6))


(=(objectives $concept1 $concept2 $candidate-degree)
    (let* (
        ($prop-val-pairs (get-prop-value-pairs $concept1))
        ($props (get-properties $prop-val-pairs))

    )
        (collapse(superpose((mu-hqblend $candidate-degree $concept1 $concept2) (coherence $props $candidate-degree)))
    ))
)

; !(objectives (spiderman) (batman) (0.5 0.3 0.2 0.9))

(= (dominates $u $v)
    (and (all-true (compare-lists $u $v >=)) (any-true (compare-lists $u $v >)))
)



(= (check-cross-dominance $obj1 $obj2)
    (if (dominates $obj1 $obj2) True (if (dominates $obj2 $obj1) False True))
)

(= (non-deter-non-dominated-helper $obj $obj-tail)
    (all-true (collapse
        (check-cross-dominance $obj (superpose $obj-tail))
    ))
)

;; Non Dominated-helper
(=(non-dominated-helper $obj $obj-tail) (
    (if (== $obj-tail ()) () 
    (let* (
        ($head (car-atom $obj-tail))
        ($tail (cdr-atom $obj-tail))
        ($head-res (eval (dominates $obj $head)))
        ($tail-res (eval (non-dominated-helper $obj $tail)))
        ($head-res2 (eval (doaminates $head $obj)))
        ($result (if (== $head-res True) $tail-res (if (== $head-res2 True) False (eval (non-dominated-helper $obj $tail)))))
    )
    $result
    ))
))



(=(non-dominated-sort-helper $objs-list $objs-tail $index)  
        (if (== $objs-tail ()) ()
        (let* 
        (
            ($fhead (car-atom $objs-tail))
            ($ftail (cdr-atom $objs-tail))
            ($head (index-atom $objs-list $index))
            ($filtered-objs-list (filter-list $objs-list $head))
            ($head-res (non-dominated-helper $head $filtered-objs-list))
            ($new-index (+ $index 1))
            ($tail-res (eval (non-dominated-sort-helper $objs-list $ftail $new-index)))
            ($result (custom-cons-atom $head-res $tail-res ))
        )
        $result
)   )
)

(= (non-dominated-sort $objs-list $objs-tv-list $index $accum)
        (if (== $objs-tv-list ()) () 
        (let* (
            ($head (car-atom $objs-tv-list))
            ($tail (cdr-atom $objs-tv-list))
            ($index-obj (index-atom $objs-list $index))
            ($new-accum (custom-cons-atom $index-obj $accum))
            ($new-index (+ $index 1))
            ($tail-res (eval (non-domainted-sort $objs-list $tail $new-index $new-accum)))
        )
        (if (== $head True) $tail-res $accum)
        )
        )
)



(= (non-deter-non-dominated-sort-helper $var $objs-list)
    (let $filtered-objs (filter-list $objs-list $var) (if (non-deter-non-dominated-helper $var $filtered-objs) $var (empty)))
)

(= (non-deter-non-dominated-sort $objs-list)
    (collapse
        (non-deter-non-dominated-sort-helper (superpose $objs-list) $objs-list)
    )
)

; ; (= (objs-list) ((7 9.1) (2 3) (6 8) (2 3) (4 6) (8 9) (3 5) (4 6)))
; ; !(non-dominated-sort-helper (objs-list) (objs-list) 0)
; ; !(non-dominated-sort (objs-list) (non-dominated-sort-helper (objs-list) (objs-list) 0) 0 ())

; ; !(non-deter-non-dominated-sort (objs-list))



(=(check-non-dominated $indiv $candidates)
    (let* (
        ($inner-indiv (car-atom $indiv))
        ($indiv-obj (index-atom $inner-indiv 1))
        ($inner-candis (let $inner-unzipped-candis (unzip-list $candidates) (car-atom $inner-unzipped-candis)))
        ($unzipped-inner-candis (unzip-list $inner-candis))
        ($candis-objs  (index-atom $unzipped-inner-candis 1))
        ($filtered-candis-objs (filter-list $candis-objs $indiv-obj))
        ($truthvalue (non-deter-non-dominated-helper $indiv-obj $filtered-candis-objs))
        ($result (if $truthvalue $indiv (empty)))
    )
    $result
    )
)

(= (filter-non-dominated $candidates)
    (collapse
        (check-non-dominated (superpose $candidates) $candidates)
    )
)

(= (cons-blend-properties $concept1 $blend-prop-values)
    (let (Concept $concpair $properties) $concept1
        (let ($length $props) ((size-atom $blend-prop-values) (cdr-atom $properties))
            (collapse(superpose
                (
                    (if (>= (- $length 1) 0) (let $prop0 (index-atom $props 0) (let ($prop0name $blendprop0val) ((car-atom $prop0) (index-atom $blend-prop-values 0)) ($prop0name $blendprop0val))) (empty))
                    (if (>= (- $length 2) 0) (let $prop1 (index-atom $props 1) (let ($prop1name $blendprop1val) ((car-atom $prop1) (index-atom $blend-prop-values 1)) ($prop1name $blendprop1val))) (empty))
                    (if (>= (- $length 3) 0) (let $prop2 (index-atom $props 2) (let ($prop2name $blendprop2val) ((car-atom $prop2) (index-atom $blend-prop-values 2)) ($prop2name $blendprop2val))) (empty))
                    (if (>= (- $length 4) 0) (let $prop3 (index-atom $props 3) (let ($prop3name $blendprop3val) ((car-atom $prop3) (index-atom $blend-prop-values 3)) ($prop3name $blendprop3val))) (empty))
                    (if (>= (- $length 5) 0) (let $prop4 (index-atom $props 4) (let ($prop4name $blendprop4val) ((car-atom $prop4) (index-atom $blend-prop-values 4)) ($prop4name $blendprop4val))) (empty))
                    (if (>= (- $length 6) 0) (let $prop5 (index-atom $props 5) (let ($prop5name $blendprop5val) ((car-atom $prop5) (index-atom $blend-prop-values 5)) ($prop5name $blendprop5val))) (empty))
                    (if (>= (- $length 7) 0) (let $prop6 (index-atom $props 6) (let ($prop6name $blendprop6val) ((car-atom $prop6) (index-atom $blend-prop-values 6)) ($prop6name $blendprop6val))) (empty))
                    (if (>= (- $length 8) 0) (let $prop7 (index-atom $props 7) (let ($prop7name $blendprop7val) ((car-atom $prop7) (index-atom $blend-prop-values 7)) ($prop7name $blendprop7val))) (empty))
                    (if (>= (- $length 9) 0) (let $prop8 (index-atom $props 8) (let ($prop8name $blendprop8val) ((car-atom $prop8) (index-atom $blend-prop-values 8)) ($prop8name $blendprop8val))) (empty))
                    (if (>= (- $length 10) 0) (let $prop9 (index-atom $props 9) (let ($prop9name $blendprop9val) ((car-atom $prop9) (index-atom $blend-prop-values 9))($prop9name $blendprop9val))) (empty))
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

; ;;;; Vital Relation Extraction ;;;;
(= (vit-rel-extraction $input1 $input2)
    (let ($vital-relation-1 $vital-relation-2) (gpt_vital_relation $input1 $input2)
        (let $vital-relations (union-atom $vital-relation-1 $vital-relation-2) (unique-atom $vital-relations))
    )
)

; ;;;; Vector Extraction ;;;;
(= (vec-extraction $input1 $input2)
    (let $vital-relations (vit-rel-extraction $input1 $input2)
        (let $vec-concepts (gpt_vector $input1 $input2 $vital-relations) $vec-concepts)
    )
)

; ;;;; Add vectorized concepts to self space ;;;;
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
                            (if (== $eval True) 
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
                            (let $_ (println! (best single-candidate: $best-candidate))
                                (let $best-cand-mu-emergence (mu-emergence $best-candidate (property-max (testconcept1) (testconcept2)))
                                    (let $_ (println! (best candidate mu emergence: $best-cand-mu-emergence))
                                        (let $blend ($network $concept-pair $best-cand-mu-emergence)
                                            (let $_ (println! (blend: $blend))
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
        (let $best-sample-with-fitness (index-atom $final-pop (- (Moedd-cma-gen) 1))
            (let $multi-objective-check-result (multi-objective-check $best-sample-with-fitness)
                (let $concept-pair (let (Concept $x $y) (testconcept1) $x)
                    (let $network (gpt-network-selector $concept-pair)
                        (if (not (== $network None))
                            (if $multi-objective-check-result
                                (let $_ (println! (Multi-objective check result: $multi-objective-check-result | Selected Network: $network)) (multi-objective-blend-loop $best-sample-with-fitness $concept-pair $network $eval))
                                ; (single-objective-blend $best-sample-with-fitness $concept-pair $network $eval)
                                (let $_ (println! (Multi-objective check result: $multi-objective-check-result | Selected Network: $network)) (single-objective-blend $best-sample-with-fitness $concept-pair $network $eval))

                            )
                            (Error $network NoNetworkSelected)
                        )
                    )
                )
            )
        )
    )
)
