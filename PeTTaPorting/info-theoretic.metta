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

 !(py-round 3.112 2)

(=(property-degree $concept)
    (let*(
        ($probability (property-probability $concept))
        ($degree (* -1 (log 10 $probability)))
    )
        (py-round $degree)
    )
)

(=(sum-list $list)
    (fold-flat $list 0 $acc $x (+ $acc $x))
)

(=(log2 $num) (log 2 $num))

(=(-vee $num) (- 0.0 $num))

(=(shannon-entropy $p) (if (or (<= $p 0) (>= $p 1))
    0
    (* $p (log2 $p))

))

(=(binary-shannon-entropy $p)
    (if (or (<= $p 0) (>= $p 1))
    0
    (- (* (-vee $p) (log2 $p)) (* (- 1 $p) (log2 (- 1 $p)))
    )
)
)

(=(custom-cons-atom $elem $list)
    (cons-atom $elem $list)
)

(=(compute-entropy $list)
    (fold-flat $list 0 $acc $x (- $acc (shannon-entropy $x))
)
)






; !(property-degree (Concept Spider@Man (Property (web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
