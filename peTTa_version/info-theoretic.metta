!(import! &self utils/list-op-utils)
!(import! &self utils/info-theoretic-utils)
!(import! &self op-constraints/op-evaluation)
!(import! &self "../utils/semantic_correlation.py")
!(import! &self "../libs/agents/gpt_agents.py")

(= (get-prop-value-pairs $concept)
    (let (Concept $x $y) $concept (cdr-atom $y))
)

(= (get-property $prop-value-pair)
    (let ($x $y) $prop-value-pair $x)
)

(= (get-properties $prop-value-pairs)
    (map-atom $prop-value-pairs get-property)
)

(= (get-value $property)
    (let ($x $y) $property $y)
)

(= (get-values $properties)
    (map-atom $properties get-value)
)

; ###################### Calculate product of two properites ##########################

(= (property-product $properties1 $properties2)
    (let ($property1values $property2values $properties)
            (collapse(superpose((get-values $properties1) (get-values $properties2) (get-properties $properties1))))
                (list-multiply $property1values $property2values $properties)
    )
)

; ###################### Calculate Number of properties #####################

(= (get-number-of-properties $concept)
    (let*
        (
            ($a $concept)
            ($b (superpose $a))
        )
        (if (is-expr $b)
            (let $c (cdr-atom $b) (size-atom $c))
            (empty)
        )
    )
)


(= (decimal $number)
    (+ $number 0.0)
)

(= (property-probability $concept)
    (let*
        (
            ($numberofprops (get-number-of-properties $concept))
            ($probability (/ 1.0 (decimal $numberofprops)))
        )
        $probability
    )
)

; ###################### Calculate Degree function ##########################

(= (py-round $number $digits)
   (py-call (round $number $digits))
)

(= (property-degree $concept)
    (let*
        (
            ($probability (property-probability $concept))
            ($degree (* -1 (log-math 10 $probability)))
        )
        (py-round $degree 2)
    )
)

; ###################### Calculate min and max for Concepts ##########################

(=(property-min $concept $concept2)
    (let*
        (
            (($properties1 $properites2) (collapse(superpose ((get-prop-value-pairs $concept) (get-prop-value-pairs $concept2)))))
            (($properties1values $properties2values $properties) (collapse (superpose ((get-values $properties1) (get-values $properites2) (get-properties $properties1)))))
        )
        (min-elements $properties1values $properties2values $properties)
    )
)

(= (property-max $concept1 $concept2)
    (let*
        (
            (($properties1 $properties2) (collapse(superpose((get-prop-value-pairs $concept1) (get-prop-value-pairs $concept2)))))
            (($properties1values $properties2values $properties) (collapse(superpose((get-values $properties1) (get-values $properties2) (get-properties $properties1)))))
        )
        (max-elements $properties1values $properties2values $properties)
    )
)

(= (mu-emergence $candidate-degrees $properties-max)
    (let* 
        (
            (($propertiesvalues $properties) ((get-values $properties-max) (get-properties $properties-max)))
            ($result (list-subtract $candidate-degrees $propertiesvalues $properties))
        )
        $result
    )
)

; ###################### Calculate mu hq blend ##########################

(= (mu-hqblend $candidate-degrees $concept1 $concept2)
    (let*
        (
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

(=(joint-entropy-compute $candidate $mode)
    (if (== $candidate ()) 
        ()
        (let* 
            (
                ($head (car-atom $candidate))
                ($tail (cdr-atom $candidate))
                ($jentropy (if (== $tail ()) () (joint-entropy-compute-helper $head $tail $mode)))
                ($tentropy (eval (joint-entropy-compute $tail $mode)))
                ($result (union-atom $jentropy $tentropy))
            )
            $result
        )
    )
)

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

(= (Alpha) 0.3)

(= (coherence $props $degrees) 
    (let* (
            ($tc (total-correlation-entropy $degrees min))
            ($tv (isnan-math $tc))
            ($ftc (if $tv 0 $tc))
            ($sim (py-call (semantic_correlation.semantic_similarity $props $degrees)))
        )
        (+ (* (Alpha) $ftc) (* (- 1 (Alpha)) $sim))        
    )
)

(= (objectives $concept1 $concept2 $candidate-degree)
    (let* (
        ($prop-val-pairs (get-prop-value-pairs $concept1))
        ($props (get-properties $prop-val-pairs))

    )
        (collapse(superpose((mu-hqblend $candidate-degree $concept1 $concept2) (coherence $props $candidate-degree)))
    ))
)

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
        (let $props (cdr-atom $properties)
            (cons-blend-properties-helper $props $blend-prop-values)
        )
    )
)

(= (format-concepts ($input1 $concept1) ($input2 $concept2) ($blend $blendproperties))
    (let ($con1rels $con2rels $blenrels) (collapse(superpose((get-concept-relations $input1 &space 5) (get-concept-relations $input2 &space 5) (get-concept-relations $blend &space 5))))
        (let ((Concept $conpair1 $propsc1) (Concept $conpair2 $propsc2)) ($concept1 $concept2)
            (let ($formattedcon1 $formattedcon2 $formattedblend) (collapse(superpose((let $conce1rels (cons-atom Relations $con1rels) (Concept $input1 $propsc1 $conce1rels)) 
                                                                                    (let $conce2rels (cons-atom Relations $con2rels) (Concept $input2 $propsc2 $conce2rels))   
                                                                                    (let ($blenprops $blendrels) ((cons-atom Property $blendproperties) (cons-atom Relations $blenrels)) (Blend $blend $blenprops $blendrels))))) ($formattedcon1 $formattedcon2 $formattedblend)
            )
        )
    )
)

(= (context-preprocesser $input1 $input2 $space $n)
    (let ($context1 $context2) (collapse(superpose((fetch-context $input1 $space $n) (fetch-context $input2 $space $n))))
        (sread (py-call (gpt_agents.gpt_context_preprocessing $input1 $context1 $input2 $context2)))
    )
)
; ;;;; Vital Relation Extraction ;;;;
(= (vit-rel-extraction $input1 $input2 $space $n)
    (let $context (context-preprocesser $input1 $input2 $space $n)
        (let ($vital-relation-1 $vital-relation-2) (sread (py-call (gpt_agents.gpt_vital_relation $input1 $input2 $context)))
            (let $vital-relations (union-atom $vital-relation-1 $vital-relation-2) (unique-atom $vital-relations))
        )
    )
)

; ;;;; Vector Extraction ;;;;
(= (vec-extraction $input1 $input2 $space $n)
    (let $vital-relations (vit-rel-extraction $input1 $input2 $space $n)
        (sread (py-call (gpt_agents.gpt_vector_extraction $input1 $input2 $vital-relations)))
    )
)

; ;;;; Amount of contexts to load form the concept-atomspace for both concepts
(= (Context-param) 10)

;;;; The atomspace containg the concept-atomspace knowledge base
(= (kbspace) &space)


; ;;;; Add vectorized concepts to self space ;;;;
(= (add-concepts)
    (let ($concept1 $concept2) (vec-extraction (Input1) (Input2) (kbspace) (Context-param))
        (superpose((add-atom &self (= (concept1) $concept1)) (add-atom &self (= (concept2) $concept2))))
    )
)

; !(add-concepts)

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
                    (let $_ (println! (Best-candidatee $best-candidate))
                        (let $best-cand-mu-emergence (mu-emergence $best-candidate (property-max (eval (concept1)) (eval (concept2))))
                            (let $blend (sread (py-call ($network $concept-pair $best-cand-mu-emergence)))
                                (if (== $eval True) 
                                (let ($blend-name $blendprops) ((index-atom $blend 2) (cons-blend-properties (eval (concept1)) $best-candidate))
                                    (let ($input1 $input2 $concept1 $concept2) ((Input1) (Input2) (eval (concept1)) (eval (concept2)))
                                        (let ($formattedcon1 $formattedcon2 $formattedblend) (format-concepts ($input1 $concept1) ($input2 $concept2) ($blend-name $blendprops))
                                            (let ($integration-res $metonymy-res $unpacking-res $web-res $topology-res $good-reason-res $average-eval-result) (op-evaluater $formattedblend $formattedcon1 $formattedcon2)
                                                (
                                                Formed Blend: $blend-name
                                                Blend-properties: $blendprops
                                                Evaluation-Metrics:
                                                Integration: $integration-res
                                                Unpacking: $unpacking-res
                                                Web: $web-res
                                                Topology: $topology-res
                                                Metonymy: $metonymy-res
                                                Good-reason: $good-reason-res
                                                Average-Evaluation-Result: $average-eval-result
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
                )
            (Error $best-fitness NegativeMu-hqblendValue)
        )
    )
)


(= (multi-objective-blend-single $single-best-blend $concept-pair $network $eval)
    (let $scalarized-fitness (index-atom $single-best-blend 1)
        (if (> $scalarized-fitness 0)
            ;; -- PATH A: Fitness is positive, attempt blend --
            (let $best-candidate (let $unscalarized-zip (index-atom $single-best-blend 0) (let ($props $unscalarized-fitness-score) $unscalarized-zip $props))
                (let $_ (println! (best single-candidate: $best-candidate))
                    (let $best-cand-mu-emergence (mu-emergence $best-candidate (property-max (eval (concept1)) (eval (concept2))))
                        (let $_ (println! (best candidate mu emergence: $best-cand-mu-emergence))
                            (let $blend (sread (py-call ($network $concept-pair $best-cand-mu-emergence)))
                                (let $_ (println! (blend: $blend))
                                    (if $eval
                                        ;; -- Sub-Path A1: Eval is True --
                                        (let ($blend-name $blendprops) ((index-atom $blend 2) (cons-blend-properties (eval (concept1)) $best-candidate))
                                            (let ($input1 $input2 $concept1 $concept2) ((Input1) (Input2) (eval (concept1)) (eval (concept2)))
                                                (let ($formattedcon1 $formattedcon2 $formattedblend) (format-concepts ($input1 $concept1) ($input2 $concept2) ($blend-name $blendprops))
                                                    (let $res-op (op-evaluater $formattedblend $formattedcon1 $formattedcon2)
                                                        (let ($integration-res $metonymy-res $unpacking-res $web-res $topology-res $good-reason-res $average-eval-result) $res-op
                                                            (
                                                            Formed Blend: $blend
                                                            Blend-properties: $blendprops
                                                            Evaluation-Metrics:
                                                            Integration: $integration-res
                                                            Unpacking: $unpacking-res
                                                            Web: $web-res
                                                            Topology: $topology-res
                                                            Metonymy: $metonymy-res
                                                            Good-reason: $good-reason-res
                                                            Average-Evaluation-Result: $average-eval-result)
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
            (Candidate property vector: $single-best-blend || fitness value: $scalarized-fitness || NegativeMu-hqblendValue)
        )
    )
)


(= (multi-objective-blend-loop $best-sample-with-fitness $concept-pair $network $eval)
    (map-atom $best-sample-with-fitness $single-best-blend (multi-objective-blend-single $single-best-blend $concept-pair $network $eval)))


(= (blend $SCMAorMCMA $eval)
    (let $concept-pair (let (Concept $x $y) (concept1) $x)
        (let $network (sread (py-call (gpt_agents.gpt_network_selector $concept-pair)))
            (if (not (== $network none))
                (let $generations (if (== $SCMAorMCMA moedd-cma-es-main-loop) Moedd-cma-gen GENERATIONS)
                    (let $final-pop ($SCMAorMCMA)
                        (let $best-sample-with-fitness (index-atom $final-pop (- ($generations) 1))
                            (let $_ (println! (Best-sample $best-sample-with-fitness))
                                (let $prepared-network (prepare-network-call $network)
                                    (if (== $SCMAorMCMA moedd-cma-es-main-loop)
                                        (let $_ (println! (Type of CMA-ES: Multi-Objective CMA-ES | Selected Network: $prepared-network | Concept-pair: $concept-pair)) ((concept1) (concept2) (multi-objective-blend-loop $best-sample-with-fitness $concept-pair $prepared-network $eval)))
                                        (let $_ (println! (Type of CMA-ES: Single-Objective CMA-ES | Selected Network: $prepared-network | Concept-pair: $concept-pair)) ((concept1) (concept2) (single-objective-blend $best-sample-with-fitness $concept-pair $prepared-network $eval)))
                                    )
                                )
                            )
                        )
                    )
                )
                (Error $network (The concept pair $concept-pair couldn't produce a blend))
            )
        )
    )
)
