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
        ($m (collapse (match &space (antonym $term1 $var) $var)))
        ($n (is-list-member $term2 $m))
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
    (let*
        (
            ($prop-list (properties-list $blend))
            ($filtered-props (greater-than-threshold-props $prop-list (int-prop-degree-threshold)))
            ($prop-names (map-atom $filtered-props $prop (car-atom $prop)))
            ($conflicts (check-props-conflict $prop-names (predefined-conflicts)))
            ($conflict-ratio (/ $conflicts (pow-math (size-atom $prop-names) 0.5)))
            ($conflict-res (max-atom (0.0 (- 1.0 $conflict-ratio))))
            ($coherence (py-call (op-helper-codes.compute_average_pairwise_similarity $prop-names)))
            ($final-res (/ (+ $conflict-res $coherence) 2.0))
        )
        $final-res
    )
)

(= (int-prop-degree-threshold) 0.3)
