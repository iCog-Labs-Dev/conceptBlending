! (import! &self libs)
! (import! &self common-utils)


(= (are-conflicting $item $item2 $terms-antonymity $pre-def-confl)
    (if (or (== ($item $item2) $pre-def-confl) (or (== ($item2 $item) $pre-def-confl) $terms-antonymity))
        1
        0
    )
)

(= (check-i-j-conflict $prop-name-i $prop-name-j $props-antonymity $pre-def-confl)
    (min-atom ((sum (map-atom $pre-def-confl $x (are-conflicting $prop-name-i $prop-name-j $props-antonymity $x))) 1))
)

(= (check-props-conflict $props $predefined-conflicts)
    (function 
        (chain (decons-atom $props) $ht
            (unify ($head $tail) $ht
                (chain (eval (map-atom $tail $x (check-i-j-conflict $head $x (are-terms-antonyms $head $x) $predefined-conflicts))) $map-res
                    (chain (sum $map-res) $res
                            (chain (eval (check-props-conflict $tail $predefined-conflicts)) $tail-res
                                (chain (+ $res $tail-res) $result (return $result))
                            )
                        )
                    )
                (return 0)
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

; ! (integration-op (good_blend))
