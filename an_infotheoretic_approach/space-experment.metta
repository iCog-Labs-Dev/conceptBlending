!(bind! &space (new-space))

!(collapse(superpose((add-atom &space (Individual X)) (add-atom &space (Individual Y)) (match &space (Individual $x) $x))))

; !(let $x (add-atom &space (Individual X)) (+ 3 3))
;!(match &space $x $x)


; !(index-atom (1 2 3 4) 0)