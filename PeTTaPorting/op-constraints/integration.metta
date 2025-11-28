(= (are-conflicting $item $item2 $terms-antonymity $pre-def-confl)
    (if (or (== ($item $item2) $pre-def-confl) (or (== ($item2 $item) $pre-def-confl) $terms-antonymity))
        1
        0
    )
)
(= (check-i-j-conflict $prop-name-i $prop-name-j $props-antonymity $pre-def-confl)
    (min-atom ((sum-op (map-atom $pre-def-confl $x (are-conflicting $prop-name-i $prop-name-j $props-antonymity $x))) 1))
)

(=(are-terms-antonyms $term1 $term2)
    (let* (
        ($m (collapse (match &self (relation (antonym $term1 $term2) antonym) $relation)))
        ($n (if (> (size-atom $m) 0) True False))
    )
    $n
    )
)
(= (check-props-conflict $props $predefined-conflicts)
    (if (== (size-atom $props) 0) 0
        (let $ht (decons-atom $props)
            (if (> (size-atom $ht) 1) 
                (let* (
                    (($head $tail) $ht)
                    ($map-res (eval (map-atom $tail $x (check-i-j-conflict $head $x (are-terms-antonyms $head $x) $predefined-conflicts))))
                    ($res (sum-op $map-res))
                    ($tail-res (eval (check-props-conflict $tail $predefined-conflicts)))
                    ($result (+ $res $tail-res))
                    )
                    $result
                ) 
                0
            )
        )
    )
)

(= (integration-op $blend)
    (let $prop-list (properties-list $blend)
        (let $prop-names (map-atom $prop-list $x (car-atom $x))
            (let $conflicts (check-props-conflict $prop-names (predefined-conflicts))
                (let $conflict-ratio (/ $conflicts (pow-math (size-atom $prop-names) 0.5)) (max-atom (0.0 (- 1.0 $conflict-ratio))))
            )
        )
    )
)

;!(integration-op (blend))
; Expected output:- 1.0