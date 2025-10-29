!(import! &self list-op-utils)


(= (get-prop-value-pairs $concept)
    (let (Concept $x $y) $concept (cdr-atom $y))
)
;  !(get-prop-value-pairs (Concept Spider@Man (Property (web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
(= (get-property $prop-value-pair)
    (let ($x $y) $prop-value-pair $x)
)
; !(get-property (web-creation 0.1))
(= (get-properties $prop-value-pairs)
    (map-flat $prop-value-pairs get-property)
)
; !(get-properties ((web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1)))
(= (get-value $property)
    (let ($x $y) $property $y)
)

(= (get-values $properties)
    (map-flat $properties get-value)
)
; !(get-values ((web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1)))


(=(property-product $candidate-degrees $properties-min)
    (let
        ($propertiesvalues $properties)
        (collapse(superpose((get-values $properties-min) (get-properties $properties-min))))
        (list-product $candidate-degrees $propertiesvalues $properties)
    )
)


(= (get-number-of-properties $concept)
    (let* (
        ($a $concept)
        ($b (superpose $a))
    )
        (if (is-expr $b)
            (let $c (cdr-atom $b)
                (length $c))
                (empty)
        )
    
     )
)

;  !(get-number-of-properties (Concept Spider@Man (Property (web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))

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

;  !(property-degree (Concept Spider@Man (Property (web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))


(=(property-min $concept $concept2)
    (let*(
        (($properties1 $properites2) (collapse(superpose ((get-prop-value-pairs $concept) (get-prop-value-pairs $concept2)))))
        (($properties1values $properties2values $properties) (collapse (superpose ((get-values $properites1) (get-values $properites2) (get-properties $properties1)))))

    )
        (min-elements $properties1values $properites2values $properties)
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

; (= (spiderman)
;    (Concept Spider@Man
;      (Property
;        (web-creation 0.1)
;        (intelligence 0.3)
;        (strength 0.6)
;        (mobility 0.8))))

; (= (batman)
;    (Concept Bat@Man
;      (Property
;        (web-creation 0.2)
;        (intelligence 0.4)
;        (strength 0.5)
;        (mobility 0.9))))

; !(property-max (spiderman) (batman))

(= (mu-emergence $candidate-degrees $properties-max)
    (let
        ($propertiesvalues $properties)
        (collapse(superpose((get-values $properties-max) (get-properties $properties-max))))
        (list-substract $candidate-degrees $propertiesvalues $properties)
    )
)

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
        (() (println! $1-over-prop-summation))
    )
        (min-atom ($1-over-prop-summation 1))
    )
)

(=(sum-list $list)
    (fold-flat $list 0 $acc $x (+ $acc $x))
)


; (=(log2 $num) (log 2 $num))

; (=(-vee $num) (- 0.0 $num))

; (=(shannon-entropy $p) (if (or (<= $p 0) (>= $p 1))
;     0
;     (* $p (log2 $p))

; ))

; (=(binary-shannon-entropy $p)
;     (if (or (<= $p 0) (>= $p 1))
;     0
;     (- (* (-vee $p) (log2 $p)) (* (- 1 $p) (log2 (- 1 $p)))
;     )
; )
; )

; (=(custom-cons-atom $elem $list)
;     (cons-atom $elem $list)
; )

; (=(compute-entropy $list)
;     (fold-flat $list 0 $acc $x (- $acc (shannon-entropy $x))
; )
; )

; (=(unify $a $b $expr $fail)
;     (if (== $a $b) $expr $fail))

; (= (joint-entropy-pairwise $pi $pj $mode)
;     (function
;         (chain (unify $mode min (chain (min-atom($pi $pj)) $pp11 $pp11) (chain (* $pi $pj) $pp11 $pp11)) $p11
;             (chain (collapse(superpose(
;                 (chain (- $pi $p11) $p10 $p10)
;                 (chain (- $pj $p11) $p01 $p01)
;                 (chain (+ $p11 (- (- 1 $pi) $pj)) $p00 $p00)
;                 ))) $list
;                 (chain (custom-cons-atom $p11 $list) $flist
;                     (chain (compute-entropy $flist) $H
;                         (return $H)
;                     )
;                 )
;             )
;         )
;     )
; )

; (=(joint-entropy-compute-helper $i $list $mode)
;     (collapse (joint-entropy-pairwise $i (superpose $list) $mode)))

; (= (custom-union-atom1 $exp1 $exp2)
;     (union-atom $exp1 $exp2)
; )
; !(union (0.5 0.3 0.2) (0.4 0.6))

; (= (joint-entropy-compute $candidate $mode)
;     (function
;         (chain (decons-atom $candidate) $ht
;             (test ($head $tail) $ht
;                 (chain (test $tail () () (joint-entropy-compute-helper $head $tail $mode)) $jentropy
;                     (chain (eval (joint-entropy-compute $tail $mode)) $tentropy
;                         (chain (union $jentropy $tentropy) $result (return $result))
;                     )
;                 )
;                 (return ())
;             )
;         )
;     )
; )

; ; !(joint-entropy-compute 0.9 (0.9 0.0 0.8 0.2 0.9 0.7 0.7))