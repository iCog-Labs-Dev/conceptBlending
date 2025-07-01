(: clamp (Number -> Number))
(= (clamp $x)
   (if (< $x 0) 0 (if (> $x 1) 1 $x))
)

;; Helper Function to get the second element of the Pair
(= (get-second $pair)
   (let $tail (cdr-atom $pair) (car-atom $tail))
)

(= (match-single-individual $space $max)
    (
        let $individuals (collapse(match $space (Individual $x $max) $x)) (if (== (size-atom $individuals) 0) () (car-atom $individuals))
    )
)
