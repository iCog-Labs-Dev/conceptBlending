(: clamp (Number -> Number))
(= (clamp $x)
   (if (< $x 0) 0 (if (> $x 1) 1 $x))
)

;; Helper Function to get the second element of the Pair
(= (get-second $pair)
   (let $tail (cdr-atom $pair) (car-atom $tail))
)
