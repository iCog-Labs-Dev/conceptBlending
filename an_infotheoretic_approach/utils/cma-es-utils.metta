! (bind! np-rnd (py-atom numpy.random))
(= (gauss $std) ((py-dot np-rnd normal) 0 $std))

(= (apply-log $vector $base)
    (map-atom $vector $x (log-math $base $x))
)

(= (apply-power $vector $power)
    (map-atom $vector $x (pow-math $x $power))
)

(= (sum $list)
    (foldl-atom $list 0 $acc $x (+ $acc $x))
)

(= (l2-norm $vector)
    (
        sqrt-math(
            sum (apply-power $vector 2)
        )
    )
)

(= (identity-matrice $dim)
    (collapse
        (superpose
            (
                (
                    if (>= (- $dim 1) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $dim 1) 0) 1 Empty) (if (>= (- $dim 2) 0) 0 Empty) (if (>= (- $dim 3) 0) 0 Empty) (if (>= (- $dim 4) 0) 0 Empty) (if (>= (- $dim 5) 0) 0 Empty) (if (>= (- $dim 6) 0) 0 Empty) (if (>= (- $dim 7) 0) 0 Empty) (if (>= (- $dim 8) 0) 0 Empty) (if (>= (- $dim 9) 0) 0 Empty) (if (>= (- $dim 10) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $dim 2) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $dim 1) 0) 0 Empty) (if (>= (- $dim 2) 0) 1 Empty) (if (>= (- $dim 3) 0) 0 Empty) (if (>= (- $dim 4) 0) 0 Empty) (if (>= (- $dim 5) 0) 0 Empty) (if (>= (- $dim 6) 0) 0 Empty) (if (>= (- $dim 7) 0) 0 Empty) (if (>= (- $dim 8) 0) 0 Empty) (if (>= (- $dim 9) 0) 0 Empty) (if (>= (- $dim 10) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $dim 3) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $dim 1) 0) 0 Empty) (if (>= (- $dim 2) 0) 0 Empty) (if (>= (- $dim 3) 0) 1 Empty) (if (>= (- $dim 4) 0) 0 Empty) (if (>= (- $dim 5) 0) 0 Empty) (if (>= (- $dim 6) 0) 0 Empty) (if (>= (- $dim 7) 0) 0 Empty) (if (>= (- $dim 8) 0) 0 Empty) (if (>= (- $dim 9) 0) 0 Empty) (if (>= (- $dim 10) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $dim 4) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $dim 1) 0) 0 Empty) (if (>= (- $dim 2) 0) 0 Empty) (if (>= (- $dim 3) 0) 0 Empty) (if (>= (- $dim 4) 0) 1 Empty) (if (>= (- $dim 5) 0) 0 Empty) (if (>= (- $dim 6) 0) 0 Empty) (if (>= (- $dim 7) 0) 0 Empty) (if (>= (- $dim 8) 0) 0 Empty) (if (>= (- $dim 9) 0) 0 Empty) (if (>= (- $dim 10) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $dim 5) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $dim 1) 0) 0 Empty) (if (>= (- $dim 2) 0) 0 Empty) (if (>= (- $dim 3) 0) 0 Empty) (if (>= (- $dim 4) 0) 0 Empty) (if (>= (- $dim 5) 0) 1 Empty) (if (>= (- $dim 6) 0) 0 Empty) (if (>= (- $dim 7) 0) 0 Empty) (if (>= (- $dim 8) 0) 0 Empty) (if (>= (- $dim 9) 0) 0 Empty) (if (>= (- $dim 10) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $dim 6) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $dim 1) 0) 0 Empty) (if (>= (- $dim 2) 0) 0 Empty) (if (>= (- $dim 3) 0) 0 Empty) (if (>= (- $dim 4) 0) 0 Empty) (if (>= (- $dim 5) 0) 0 Empty) (if (>= (- $dim 6) 0) 1 Empty) (if (>= (- $dim 7) 0) 0 Empty) (if (>= (- $dim 8) 0) 0 Empty) (if (>= (- $dim 9) 0) 0 Empty) (if (>= (- $dim 10) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $dim 7) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $dim 1) 0) 0 Empty) (if (>= (- $dim 2) 0) 0 Empty) (if (>= (- $dim 3) 0) 0 Empty) (if (>= (- $dim 4) 0) 0 Empty) (if (>= (- $dim 5) 0) 0 Empty) (if (>= (- $dim 6) 0) 0 Empty) (if (>= (- $dim 7) 0) 1 Empty) (if (>= (- $dim 8) 0) 0 Empty) (if (>= (- $dim 9) 0) 0 Empty) (if (>= (- $dim 10) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $dim 8) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $dim 1) 0) 0 Empty) (if (>= (- $dim 2) 0) 0 Empty) (if (>= (- $dim 3) 0) 0 Empty) (if (>= (- $dim 4) 0) 0 Empty) (if (>= (- $dim 5) 0) 0 Empty) (if (>= (- $dim 6) 0) 0 Empty) (if (>= (- $dim 7) 0) 0 Empty) (if (>= (- $dim 8) 0) 1 Empty) (if (>= (- $dim 9) 0) 0 Empty) (if (>= (- $dim 10) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $dim 9) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $dim 1) 0) 0 Empty) (if (>= (- $dim 2) 0) 0 Empty) (if (>= (- $dim 3) 0) 0 Empty) (if (>= (- $dim 4) 0) 0 Empty) (if (>= (- $dim 5) 0) 0 Empty) (if (>= (- $dim 6) 0) 0 Empty) (if (>= (- $dim 7) 0) 0 Empty) (if (>= (- $dim 8) 0) 0 Empty) (if (>= (- $dim 9) 0) 1 Empty) (if (>= (- $dim 10) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $dim 10) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $dim 1) 0) 0 Empty) (if (>= (- $dim 2) 0) 0 Empty) (if (>= (- $dim 3) 0) 0 Empty) (if (>= (- $dim 4) 0) 0 Empty) (if (>= (- $dim 5) 0) 0 Empty) (if (>= (- $dim 6) 0) 0 Empty) (if (>= (- $dim 7) 0) 0 Empty) (if (>= (- $dim 8) 0) 0 Empty) (if (>= (- $dim 9) 0) 0 Empty) (if (>= (- $dim 10) 0) 1 Empty)
                            )
                        )
                    )
                    Empty
                )
            )
        )
    )
)

(= (zeros-vec $length)
    (let $toy-list (generate-toy-list $length) (map-atom $toy-list $x 0))
)


(= (range $lb $ub)
    (let $x (- $ub $lb) (
            collapse(
                superpose(
                    (if (>= (- $x 1) 0) 1 Empty)
                    (if (>= (- $x 2) 0) 2 Empty)
                    (if (>= (- $x 3) 0) 3 Empty)
                    (if (>= (- $x 4) 0) 4 Empty)
                    (if (>= (- $x 5) 0) 5 Empty)
                    (if (>= (- $x 6) 0) 6 Empty)
                    (if (>= (- $x 7) 0) 7 Empty)
                    (if (>= (- $x 8) 0) 8 Empty)
                    (if (>= (- $x 9) 0) 9 Empty)
                )
            )
        )
    )
)

(= (scalar-op $vector $num $op)
    (map-atom $vector $x ($op $x $num))
)

(= (rev-scalar-op $num $vector $op)
    (map-atom $vector $x ($op $num $x))
)

(= (vector-op $vector1 $vector2 $op)
    (let ($length1 $length2) ((size-atom $vector1) (size-atom $vector2))
        (
            if (not (== $length1 $length2))
            (Error ($length1 $length2) LengthMismatch)
            (collapse
                (superpose
                    (
                        (if (>= (- $length1 1) 0) ($op (index-atom $vector1 0) (index-atom $vector2 0)) Empty)
                        (if (>= (- $length1 2) 0) ($op (index-atom $vector1 1) (index-atom $vector2 1)) Empty)
                        (if (>= (- $length1 3) 0) ($op (index-atom $vector1 2) (index-atom $vector2 2)) Empty)
                        (if (>= (- $length1 4) 0) ($op (index-atom $vector1 3) (index-atom $vector2 3)) Empty)
                        (if (>= (- $length1 5) 0) ($op (index-atom $vector1 4) (index-atom $vector2 4)) Empty)
                        (if (>= (- $length1 6) 0) ($op (index-atom $vector1 5) (index-atom $vector2 5)) Empty)
                        (if (>= (- $length1 7) 0) ($op (index-atom $vector1 6) (index-atom $vector2 6)) Empty)
                        (if (>= (- $length1 8) 0) ($op (index-atom $vector1 7) (index-atom $vector2 7)) Empty)
                    )
                )
            )
        )
    )
)

; !(vector-op (1 2 3 4 5 6 5 4) (2 3 4 5 6 4 3 2) +)

(= (mat-scalar-op $matrice $num $op)
    (map-atom $matrice $x (scalar-op $x $num $op))    
)

(= (num-clip $x $lb $ub)
    (superpose(
        (if (< $x $lb) $lb Empty)
        (if (> $x $ub) $ub Empty)
        (if (and (>= $x $lb) (<= $x $ub)) $x Empty)
        )
    )
)

; !(num-clip 5 0 1)

(= (vec-clip $vec $lb $ub)
    (map-atom $vec $x (num-clip $x $lb $ub))
)

; !(vec-clip (2 1 0.5 -0.5 -4 1.1 53 4 1 2 -77 4 53 -43 -3 44 565 32 56 67 43 -54 -67 -8 -8 9 2 34 56 0 1) 0 1)

(= (mat-clip $matrice $lb $ub)
    (map-atom $matrice $x (vec-clip $x $lb $ub))
)

; !(mat-clip ((33 3 4 5 6 6 6 3) (33 3 4 5 6 6 6 3) (33 3 4 5 6 6 6 3) (33 3 4 5 6 6 6 3) (33 3 4 5 6 6 6 3) (33 3 4 5 6 6 6 3) (33 3 4 5 6 6 6 3) (33 3 4 5 6 6 6 3) (33 3 4 5 6 6 6 3) (33 3 4 5 6 6 6 3)) 0 1)

!(bind! &lspace (new-space))
!(bind! &mspace (new-space))
; !(bind! &mlspace (new-space))
; !(add-atom &lspace (l00 56))
; !(let $x (collapse(get-atoms &lspace)) (size-atom $x))

(= (add-lmat-to-lspace $mat)
    (let ($l0 $l1 $l2 $l3 $l4 $l5 $l6 $l7) (collapse(superpose((index-atom $mat 0) (index-atom $mat 1) (index-atom $mat 2) (index-atom $mat 3) (index-atom $mat 4) (index-atom $mat 5) (index-atom $mat 6) (index-atom $mat 7))))
        (collapse
            (superpose
                (
                    (add-atom &lspace (cell l00 (index-atom $l0 0)))
                    (collapse(superpose((add-atom &lspace (cell l10 (index-atom $l1 0))) (add-atom &lspace (cell l11 (index-atom $l1 1))))))
                    (collapse(superpose((add-atom &lspace (cell l20 (index-atom $l2 0))) (add-atom &lspace (cell l21 (index-atom $l2 1))) (add-atom &lspace (cell l22 (index-atom $l2 2))))))
                    (collapse(superpose((add-atom &lspace (cell l30 (index-atom $l3 0))) (add-atom &lspace (cell l31 (index-atom $l3 1))) (add-atom &lspace (cell l32 (index-atom $l3 2))) (add-atom &lspace (cell l33 (index-atom $l3 3))))))
                    (collapse(superpose((add-atom &lspace (cell l40 (index-atom $l4 0))) (add-atom &lspace (cell l41 (index-atom $l4 1))) (add-atom &lspace (cell l42 (index-atom $l4 2))) (add-atom &lspace (cell l43 (index-atom $l4 3))) (add-atom &lspace (cell l44 (index-atom $l4 4))))))
                    (collapse(superpose((add-atom &lspace (cell l50 (index-atom $l5 0))) (add-atom &lspace (cell l51 (index-atom $l5 1))) (add-atom &lspace (cell l52 (index-atom $l5 2))) (add-atom &lspace (cell l53 (index-atom $l5 3))) (add-atom &lspace (cell l54 (index-atom $l5 4))) (add-atom &lspace (cell l55 (index-atom $l5 5))))))
                    (collapse(superpose((add-atom &lspace (cell l60 (index-atom $l6 0))) (add-atom &lspace (cell l61 (index-atom $l6 1))) (add-atom &lspace (cell l62 (index-atom $l6 2))) (add-atom &lspace (cell l63 (index-atom $l6 3))) (add-atom &lspace (cell l64 (index-atom $l6 4))) (add-atom &lspace (cell l65 (index-atom $l6 5))) (add-atom &lspace (cell l66 (index-atom $l6 6))))))
                    (collapse(superpose((add-atom &lspace (cell l70 (index-atom $l7 0))) (add-atom &lspace (cell l71 (index-atom $l7 1))) (add-atom &lspace (cell l72 (index-atom $l7 2))) (add-atom &lspace (cell l73 (index-atom $l7 3))) (add-atom &lspace (cell l74 (index-atom $l7 4))) (add-atom &lspace (cell l75 (index-atom $l7 5))) (add-atom &lspace (cell l76 (index-atom $l7 6))) (add-atom &lspace (cell l77 (index-atom $l7 7))))))
                )
            )
        )               
    )
)

; !(get-atoms &lspace)

(= (call-lik $i $k)
    (
        superpose(
            (if (== $i 1) (match &lspace (cell l10 $x) $x) Empty)
            (if (== $i 2) (superpose((if (== $k 0) (match &lspace (cell l20 $x) $x) Empty) (if (== $k 1) (match &lspace (cell l21 $x) $x) Empty))) Empty)
            (if (== $i 3) (superpose((if (== $k 0) (match &lspace (cell l30 $x) $x) Empty) (if (== $k 1) (match &lspace (cell l31 $x) $x) Empty) (if (== $k 2) (match &lspace (cell l32 $x) $x) Empty))) Empty)
            (if (== $i 4) (superpose((if (== $k 0) (match &lspace (cell l40 $x) $x) Empty) (if (== $k 1) (match &lspace (cell l41 $x) $x) Empty) (if (== $k 2) (match &lspace (cell l42 $x) $x) Empty) (if (== $k 3) (match &lspace (cell l43 $x) $x) Empty))) Empty)
            (if (== $i 5) (superpose((if (== $k 0) (match &lspace (cell l50 $x) $x) Empty) (if (== $k 1) (match &lspace (cell l51 $x) $x) Empty) (if (== $k 2) (match &lspace (cell l52 $x) $x) Empty) (if (== $k 3) (match &lspace (cell l53 $x) $x) Empty) (if (== $k 4) (match &lspace (cell l54 $x) $x) Empty))) Empty)
            (if (== $i 6) (superpose((if (== $k 0) (match &lspace (cell l60 $x) $x) Empty) (if (== $k 1) (match &lspace (cell l61 $x) $x) Empty) (if (== $k 2) (match &lspace (cell l62 $x) $x) Empty) (if (== $k 3) (match &lspace (cell l63 $x) $x) Empty) (if (== $k 4) (match &lspace (cell l64 $x) $x) Empty) (if (== $k 5) (match &lspace (cell l65 $x) $x) Empty))) Empty)
            (if (== $i 7) (superpose((if (== $k 0) (match &lspace (cell l70 $x) $x) Empty) (if (== $k 1) (match &lspace (cell l71 $x) $x) Empty) (if (== $k 2) (match &lspace (cell l72 $x) $x) Empty) (if (== $k 3) (match &lspace (cell l73 $x) $x) Empty) (if (== $k 4) (match &lspace (cell l74 $x) $x) Empty) (if (== $k 5) (match &lspace (cell l75 $x) $x) Empty) (if (== $k 6) (match &lspace (cell l76 $x) $x) Empty))) Empty)
        )
    )
)

(= (call-ljk $j $k)
    (
        superpose(
            (if (== $j 1) (match &lspace (cell l00 $x) $x) Empty)
            (if (== $j 2) (superpose((if (== $k 0) (match &lspace (cell l20 $x) $x) Empty) (if (== $k 1) (match &lspace (cell l21 $x) $x) Empty))) Empty)
            (if (== $j 3) (superpose((if (== $k 0) (match &lspace (cell l30 $x) $x) Empty) (if (== $k 1) (match &lspace (cell l31 $x) $x) Empty) (if (== $k 2) (match &lspace (cell l32 $x) $x) Empty))) Empty)
            (if (== $j 4) (superpose((if (== $k 0) (match &lspace (cell l40 $x) $x) Empty) (if (== $k 1) (match &lspace (cell l41 $x) $x) Empty) (if (== $k 2) (match &lspace (cell l42 $x) $x) Empty) (if (== $k 3) (match &lspace (cell l43 $x) $x) Empty))) Empty)
            (if (== $j 5) (superpose((if (== $k 0) (match &lspace (cell l50 $x) $x) Empty) (if (== $k 1) (match &lspace (cell l51 $x) $x) Empty) (if (== $k 2) (match &lspace (cell l52 $x) $x) Empty) (if (== $k 3) (match &lspace (cell l53 $x) $x) Empty) (if (== $k 4) (match &lspace (cell l54 $x) $x) Empty))) Empty)
            (if (== $j 6) (superpose((if (== $k 0) (match &lspace (cell l60 $x) $x) Empty) (if (== $k 1) (match &lspace (cell l61 $x) $x) Empty) (if (== $k 2) (match &lspace (cell l62 $x) $x) Empty) (if (== $k 3) (match &lspace (cell l63 $x) $x) Empty) (if (== $k 4) (match &lspace (cell l64 $x) $x) Empty) (if (== $k 5) (match &lspace (cell l65 $x) $x) Empty))) Empty)
            (if (== $j 7) (superpose((if (== $k 0) (match &lspace (cell l70 $x) $x) Empty) (if (== $k 1) (match &lspace (cell l71 $x) $x) Empty) (if (== $k 2) (match &lspace (cell l72 $x) $x) Empty) (if (== $k 3) (match &lspace (cell l73 $x) $x) Empty) (if (== $k 4) (match &lspace (cell l74 $x) $x) Empty) (if (== $k 5) (match &lspace (cell l75 $x) $x) Empty) (if (== $k 6) (match &lspace (cell l76 $x) $x) Empty))) Empty)
        )
    )
)

(= (call-mkj $k $j)
    (
        superpose(
            (if (== $j 0) (superpose((if (== $k 0) (match &mspace (cell m00 $x) $x) Empty) (if (== $k 1) (match &mspace (cell m10 $x) $x) Empty) (if (== $k 2) (match &mspace (cell m20 $x) $x) Empty) (if (== $k 3) (match &mspace (cell m30 $x) $x) Empty) (if (== $k 4) (match &mspace (cell m40 $x) $x) Empty) (if (== $k 5) (match &mspace (cell m50 $x) $x) Empty) (if (== $k 6) (match &mspace (cell m60 $x) $x) Empty))) Empty)
            (if (== $j 1) (superpose((if (== $k 1) (match &mspace (cell m11 $x) $x) Empty) (if (== $k 2) (match &mspace (cell m21 $x) $x) Empty) (if (== $k 3) (match &mspace (cell m31 $x) $x) Empty) (if (== $k 4) (match &mspace (cell m41 $x) $x) Empty) (if (== $k 5) (match &mspace (cell m51 $x) $x) Empty) (if (== $k 6) (match &mspace (cell m61 $x) $x) Empty))) Empty)
            (if (== $j 2) (superpose((if (== $k 2) (match &mspace (cell m22 $x) $x) Empty) (if (== $k 3) (match &mspace (cell m32 $x) $x) Empty) (if (== $k 4) (match &mspace (cell m42 $x) $x) Empty) (if (== $k 5) (match &mspace (cell m52 $x) $x) Empty) (if (== $k 6) (match &mspace (cell m62 $x) $x) Empty))) Empty)
            (if (== $j 3) (superpose((if (== $k 3) (match &mspace (cell m33 $x) $x) Empty) (if (== $k 4) (match &mspace (cell m43 $x) $x) Empty) (if (== $k 5) (match &mspace (cell m53 $x) $x) Empty) (if (== $k 6) (match &mspace (cell m63 $x) $x) Empty))) Empty)
            (if (== $j 4) (superpose((if (== $k 4) (match &mspace (cell m44 $x) $x) Empty) (if (== $k 5) (match &mspace (cell m54 $x) $x) Empty) (if (== $k 6) (match &mspace (cell m64 $x) $x) Empty))) Empty)
            (if (== $j 5) (superpose((if (== $k 5) (match &mspace (cell m55 $x) $x) Empty) (if (== $k 6) (match &mspace (cell m65 $x) $x) Empty))) Empty)
        )
    )
)

(= (cells-product $i $j)
    (collapse
        (superpose
            (
                (if (>= (- $j 1) 0) (* (call-lik $i 0) (call-ljk $j 0)) Empty)
                (if (>= (- $j 2) 0) (* (call-lik $i 1) (call-ljk $j 1)) Empty)
                (if (>= (- $j 3) 0) (* (call-lik $i 2) (call-ljk $j 2)) Empty)
                (if (>= (- $j 4) 0) (* (call-lik $i 3) (call-ljk $j 3)) Empty)
                (if (>= (- $j 5) 0) (* (call-lik $i 4) (call-ljk $j 4)) Empty)
                (if (>= (- $j 6) 0) (* (call-lik $i 5) (call-ljk $j 5)) Empty)
                (if (>= (- $j 7) 0) (* (call-lik $i 6) (call-ljk $j 6)) Empty)
                (if (>= (- $j 8) 0) (* (call-lik $i 7) (call-ljk $j 7)) Empty)
            )
        )
    )
)

(= (inverse-cells-product $i $j)
    (collapse
        (superpose
            (
                (if (and (<= $j 0) (>= (- $i  1) 0)) (* (call-lik $i 0) (call-mkj 0 $j)) Empty)
                (if (and (<= $j 1) (>= (- $i  2) 0)) (* (call-lik $i 1) (call-mkj 1 $j)) Empty)
                (if (and (<= $j 2) (>= (- $i  3) 0)) (* (call-lik $i 2) (call-mkj 2 $j)) Empty)
                (if (and (<= $j 3) (>= (- $i  4) 0)) (* (call-lik $i 3) (call-mkj 3 $j)) Empty)
                (if (and (<= $j 4) (>= (- $i  5) 0)) (* (call-lik $i 4) (call-mkj 4 $j)) Empty)
                (if (and (<= $j 5) (>= (- $i  6) 0)) (* (call-lik $i 5) (call-mkj 5 $j)) Empty)
                (if (and (<= $j 6) (>= (- $i  7) 0)) (* (call-lik $i 6) (call-mkj 6 $j)) Empty)
            )
        )
    )
)

(= (l00 $cov-matrice)
    (let $a0 (index-atom $cov-matrice 0)
        (let $a00 (index-atom $a0 0)
            (let $l00 (sqrt-math $a00)
                (let $add (add-atom &lspace (cell l00 $l00)) $l00)
            )
        )
    )
)

(= (l10 $cov-matrice)
    (let ($a1 $l00) ((index-atom $cov-matrice 1) (match &lspace (cell l00 $x) $x))
        (let $a10 (index-atom $a1 0)
            (let $l10 (/ $a10 $l00)
                (let $add (add-atom &lspace (cell l10 $l10)) $l10)
            )
        )
    )
)

(= (l11 $cov-matrice)
    (let ($a1 $l10) ((index-atom $cov-matrice 1) (match &lspace (cell l10 $x) $x))
        (let $l11 (sqrt-math (let $a11 (index-atom $a1 1) (- $a11 (pow-math $l10 2))))
            (let $add (add-atom &lspace (cell l11 $l11)) $l11)
        )
    )
)

(= (l20 $cov-matrice)
    (let ($a2 $l00) ((index-atom $cov-matrice 2) (match &lspace (cell l00 $x) $x))
        (let $a20 (index-atom $a2 0)
            (let $l20 (/ $a20 $l00)
                (let $add (add-atom &lspace (cell l20 $l20)) $l20)
            )
        )
    )
)

(= (l21 $cov-matrice)
    (let ($a2 $l10 $l11 $l20) (collapse(superpose((index-atom $cov-matrice 2) (match &lspace (cell l10 $x) $x) (match &lspace (cell l11 $x) $x) (match &lspace (cell l20 $x) $x))))
        (let $a21 (index-atom $a2 1)
            (let $l21 (/ (- $a21 (* $l20 $l10)) $l11)
                (let $add (add-atom &lspace (cell l21 $l21)) $l21)
            )
        )
    )
)

(= (l22 $cov-matrice)
    (let $a2 (index-atom $cov-matrice 2)
        (let $l22 (sqrt-math (let $a22 (index-atom $a2 2) (- $a22 (sum (cells-product 2 2))))) 
            (let $add (add-atom &lspace (cell l22 $l22)) $l22)
        )
    )
)

(= (l30 $cov-matrice)
    (let ($a3 $l00) ((index-atom $cov-matrice 3) (match &lspace (cell l00 $x) $x))
        (let $a30 (index-atom $a3 0)
            (let $l30 (/ $a30 $l00)
                (let $add (add-atom &lspace (cell l30 $l30)) $l30)
            )
        )
    )
)

(= (l31 $cov-matrice)
    (let ($a3 $l30 $l10 $l11) (collapse(superpose((index-atom $cov-matrice 3) (match &lspace (cell l30 $x) $x) (match &lspace (cell l10 $x) $x) (match &lspace (cell l11 $x) $x))))
        (let $a31 (index-atom $a3 1)
            (let $l31 (/ (- $a31 (* $l30 $l10)) $l11)
                (let $add (add-atom &lspace (cell l31 $l31)) $l31)
            )
        )
    )
)

(= (l32 $cov-matrice)
    (let ($a3 $l22) ((index-atom $cov-matrice 3) (match &lspace (cell l22 $x) $x))
        (let $a33 (index-atom $a3 2)
            (let $l32 (/ (- $a33 (sum (cells-product 3 2))) $l22)
                (let $add (add-atom &lspace (cell l32 $l32)) $l32)
            )
        )
    )
)

(= (l33 $cov-matrice)
    (let $a3 (index-atom $cov-matrice 3)
        (let $l33 (sqrt-math (let $a33 (index-atom $a3 3) (- $a33 (sum (cells-product 3 3)))))
            (let $add (add-atom &lspace (cell l33 $l33)) $l33)
        )
    )
)

(= (l40 $cov-matrice)
    (let ($a4 $l00) ((index-atom $cov-matrice 4) (match &lspace (cell l00 $x) $x))
        (let $a40 (index-atom $a4 0) 
            (let $l40 (/ $a40 $l00)
                (let $add (add-atom &lspace (cell l40 $l40)) $l40)
            )
        )
    )
)

(= (l41 $cov-matrice)
    (let ($a4 $l40 $l10 $l11) (collapse(superpose((index-atom $cov-matrice 4) (match &lspace (cell l40 $x) $x) (match &lspace (cell l10 $x) $x) (match &lspace (cell l11 $x) $x))))
        (let $a41 (index-atom $a4 1)
            (let $l41 (/ (- $a41 (* $l40 $l10)) $l11)
                (let $add (add-atom &lspace (cell l41 $l41)) $l41)
            )
        )
    )
)

(= (l42 $cov-matrice)
    (let ($a4 $l22) ((index-atom $cov-matrice 4) (match &lspace (cell l22 $x) $x))
        (let $a42 (index-atom $a4 2)
            (let $l42 (/ (- $a42 (sum (cells-product 4 2))) $l22)
                (let $add (add-atom &lspace (cell l42 $l42)) $l42)
            )
        )
    )
)

(= (l43 $cov-matrice)
    (let ($a4 $l33) ((index-atom $cov-matrice 4) (match &lspace (cell l33 $x) $x))
        (let $a43 (index-atom $a4 3)
            (let $l43 (/ (- $a43 (sum (cells-product 4 3))) $l33)
                (let $add (add-atom &lspace (cell l43 $l43)) $l43)
            )
        )
    )
)

(= (l44 $cov-matrice)
    (let $a4 (index-atom $cov-matrice 4)
        (let $l44 (sqrt-math (let $a44 (index-atom $a4 4) (- $a44 (sum (cells-product 4 4)))))
            (let $add (add-atom &lspace (cell l44 $l44)) $l44)
        )
    )
)

(= (l50 $cov-matrice)
    (let ($a5 $l00) ((index-atom $cov-matrice 5) (match &lspace (cell l00 $x) $x))
        (let $a50 (index-atom $a5 0)
            (let $l50 (/ $a50 $l00)
                (let $add (add-atom &lspace (cell l50 $l50)) $l50)
            )
        )
    )
)

(= (l51 $cov-matrice)
    (let ($a5 $l50 $l10 $l11) (collapse (superpose ((index-atom $cov-matrice 5) (match &lspace (cell l50 $x) $x) (match &lspace (cell l10 $x) $x) (match &lspace (cell l11 $x) $x))))
        (let $a51 (index-atom $a5 1)
            (let $l51 (/ (- $a51 (* $l50 $l10)) $l11)
                (let $add (add-atom &lspace (cell l51 $l51)) $l51)
            )
        )
    )
)

(= (l52 $cov-matrice)
    (let ($a5 $l22) ((index-atom $cov-matrice 5) (match &lspace (cell l22 $x) $x))
        (let $a52 (index-atom $a5 2)
            (let $l52 (/ (- $a52 (sum (cells-product 5 2))) $l22)
                (let $add (add-atom &lspace (cell l52 $l52)) $l52)
            )
        )
    )
)

(= (l53 $cov-matrice)
    (let ($a5 $l33) ((index-atom $cov-matrice 5) (match &lspace (cell l33 $x) $x))
        (let $a53 (index-atom $a5 3)
            (let $l53 (/ (- $a53 (sum (cells-product 5 3))) $l33)
                (let $add (add-atom &lspace (cell l53 $l53)) $l53)
            )
        )
    )
)

(= (l54 $cov-matrice)
    (let ($a5 $l44) ((index-atom $cov-matrice 5) (match &lspace (cell l44 $x) $x))
        (let $a54 (index-atom $a5 4)
            (let $l54 (/ (- $a54 (sum (cells-product 5 4))) $l44)
                (let $add (add-atom &lspace (cell l54 $l54)) $l54)
            )
        )
    )
)

(= (l55 $cov-matrice)
    (let $a5 (index-atom $cov-matrice 5)
        (let $l55 (sqrt-math (let $a55 (index-atom $a5 5) (- $a55 (sum (cells-product 5 5)))))
            (let $add (add-atom &lspace (cell l55 $l55)) $l55)
        )
    )
)

(= (l60 $cov-matrice)
    (let ($a6 $l00) ((index-atom $cov-matrice 6) (match &lspace (cell l00 $x) $x))
        (let $a60 (index-atom $a6 0)
            (let $l60 (/ $a60 $l00)
                (let $add (add-atom &lspace (cell l60 $l60)) $l60)
            )
        )
    )
)

(= (l61 $cov-matrice)
    (let ($a6 $l60 $l10 $l11) (collapse (superpose ((index-atom $cov-matrice 6) (match &lspace (cell l60 $x) $x) (match &lspace (cell l10 $x) $x) (match &lspace (cell l11 $x) $x))))
        (let $a61 (index-atom $a6 1)
            (let $l61 (/ (- $a61 (* $l60 $l10)) $l11)
                (let $add (add-atom &lspace (cell l61 $l61)) $l61)
            )
        )
    )
)

(= (l62 $cov-matrice)
    (let ($a6 $l22) ((index-atom $cov-matrice 6) (match &lspace (cell l22 $x) $x))
        (let $a62 (index-atom $a6 2)
            (let $l62 (/ (- $a62 (sum (cells-product 6 2))) $l22)
                (let $add (add-atom &lspace (cell l62 $l62)) $l62)
            )
        )
    )
)

(= (l63 $cov-matrice)
    (let ($a6 $l33) ((index-atom $cov-matrice 6) (match &lspace (cell l33 $x) $x))
        (let $a63 (index-atom $a6 3)
            (let $l63 (/ (- $a63 (sum (cells-product 6 3))) $l33)
                (let $add (add-atom &lspace (cell l63 $l63)) $l63)
            )
        )
    )
)

(= (l64 $cov-matrice)
    (let ($a6 $l44) ((index-atom $cov-matrice 6) (match &lspace (cell l44 $x) $x))
        (let $a64 (index-atom $a6 4)
            (let $l64 (/ (- $a64 (sum (cells-product 6 4))) $l44)
                (let $add (add-atom &lspace (cell l64 $l64)) $l64)
            )
        )
    )
)

(= (l65 $cov-matrice)
    (let ($a6 $l55) ((index-atom $cov-matrice 6) (match &lspace (cell l55 $x) $x))
        (let $a65 (index-atom $a6 5)
            (let $l65 (/ (- $a65 (sum (cells-product 6 5))) $l55)
                (let $add (add-atom &lspace (cell l65 $l65)) $l65)
            )
        )
    )
)

(= (l66 $cov-matrice)
    (let $a6 (index-atom $cov-matrice 6)
        (let $l66 (sqrt-math (let $a66 (index-atom $a6 6) (- $a66 (sum (cells-product 6 6)))))
            (let $add (add-atom &lspace (cell l66 $l66)) $l66)
        )
    )
)

(= (l70 $cov-matrice)
    (let ($a7 $l00) ((index-atom $cov-matrice 7) (match &lspace (cell l00 $x) $x))
        (let $a70 (index-atom $a7 0)
            (let $l70 (/ $a70 $l00)
                (let $add (add-atom &lspace (cell l70 $l70)) $l70)
            )
        )
    )
)

(= (l71 $cov-matrice)
    (let ($a7 $l70 $l10 $l11) (collapse (superpose ((index-atom $cov-matrice 7) (match &lspace (cell l70 $x) $x) (match &lspace (cell l10 $x) $x) (match &lspace (cell l11 $x) $x))))
        (let $a71 (index-atom $a7 1)
            (let $l71 (/ (- $a71 (* $l70 $l10)) $l11)
                (let $add (add-atom &lspace (cell l71 $l71)) $l71)
            )
        )
    )
)

(= (l72 $cov-matrice)
    (let ($a7 $l22) ((index-atom $cov-matrice 7) (match &lspace (cell l22 $x) $x))
        (let $a72 (index-atom $a7 2)
            (let $l72 (/ (- $a72 (sum (cells-product 7 2))) $l22)
                (let $add (add-atom &lspace (cell l72 $l72)) $l72)
            )
        )
    )
)

(= (l73 $cov-matrice)
    (let ($a7 $l33) ((index-atom $cov-matrice 7) (match &lspace (cell l33 $x) $x))
        (let $a73 (index-atom $a7 3)
            (let $l73 (/ (- $a73 (sum (cells-product 7 3))) $l33)
                (let $add (add-atom &lspace (cell l73 $l73)) $l73)
            )
        )
    )
)

(= (l74 $cov-matrice)
    (let ($a7 $l44) ((index-atom $cov-matrice 7) (match &lspace (cell l44 $x) $x))
        (let $a74 (index-atom $a7 4)
            (let $l74 (/ (- $a74 (sum (cells-product 7 4))) $l44)
                (let $add (add-atom &lspace (cell l74 $l74)) $l74)
            )
        )
    )
)

(= (l75 $cov-matrice)
    (let ($a7 $l55) ((index-atom $cov-matrice 7) (match &lspace (cell l55 $x) $x))
        (let $a75 (index-atom $a7 5)
            (let $l75 (/ (- $a75 (sum (cells-product 7 5))) $l55)
                (let $add (add-atom &lspace (cell l75 $l75)) $l75)
            )
        )
    )
)

(= (l76 $cov-matrice)
    (let ($a7 $l66) ((index-atom $cov-matrice 7) (match &lspace (cell l66 $x) $x))
        (let $a76 (index-atom $a7 6)
            (let $l76 (/ (- $a76 (sum (cells-product 7 6))) $l66)
                (let $add (add-atom &lspace (cell l76 $l76)) $l76)
            )
        )
    )
)

(= (l77 $cov-matrice)
    (let $a7 (index-atom $cov-matrice 7)
        (let $l77 (sqrt-math (let $a77 (index-atom $a7 7) (- $a77 (sum (cells-product 7 7)))))
            (let $add (add-atom &lspace (cell l77 $l77)) $l77)
        )
    )
)

; !(let $add (add-lmat-to-lspace ((6 2 3 2 1 1 1 1)
;  (2 6 3 2 1 1 1 1)
;  (3 3 6 2 1 1 1 1)
;  (2 2 2 6 1 1 1 1)
;  (1 1 1 1 6 1 1 1)
;  (1 1 1 1 1 6 1 1)
;  (1 1 1 1 1 1 6 1)
;  (1 1 1 1 1 1 1 6))) (match &lspace $x $x))

(= (chol-decomp $cov-matrice)
    (let ($rows $columns $clean) ((size-atom $cov-matrice) (let $row1 (index-atom $cov-matrice 0) (size-atom $row1)) (collapse(match &lspace (cell $x $y) (remove-atom &lspace (cell $x $y)))))
    (collapse
        (superpose
            (
                (
                    if (>= (- $rows 1) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (l00 $cov-matrice) Empty) (if (>= (- $columns 2) 0) 0 Empty) (if (>= (- $columns 3) 0) 0 Empty) (if (>= (- $columns 4) 0) 0 Empty) (if (>= (- $columns 5) 0) 0 Empty) (if (>= (- $columns 6) 0) 0 Empty) (if (>= (- $columns 7) 0) 0 Empty) (if (>= (- $columns 8) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $rows 2) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (l10 $cov-matrice) Empty) (if (>= (- $columns 2) 0) (l11 $cov-matrice) Empty) (if (>= (- $columns 3) 0) 0 Empty) (if (>= (- $columns 4) 0) 0 Empty) (if (>= (- $columns 5) 0) 0 Empty) (if (>= (- $columns 6) 0) 0 Empty) (if (>= (- $columns 7) 0) 0 Empty) (if (>= (- $columns 8) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $rows 3) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (l20 $cov-matrice) Empty) (if (>= (- $columns 2) 0) (l21 $cov-matrice) Empty) (if (>= (- $columns 3) 0) (l22 $cov-matrice) Empty) (if (>= (- $columns 4) 0) 0 Empty) (if (>= (- $columns 5) 0) 0 Empty) (if (>= (- $columns 6) 0) 0 Empty) (if (>= (- $columns 7) 0) 0 Empty) (if (>= (- $columns 8) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $rows 4) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (l30 $cov-matrice) Empty) (if (>= (- $columns 2) 0) (l31 $cov-matrice) Empty) (if (>= (- $columns 3) 0) (l32 $cov-matrice) Empty) (if (>= (- $columns 4) 0) (l33 $cov-matrice) Empty) (if (>= (- $columns 5) 0) 0 Empty) (if (>= (- $columns 6) 0) 0 Empty) (if (>= (- $columns 7) 0) 0 Empty) (if (>= (- $columns 8) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $rows 5) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (l40 $cov-matrice) Empty) (if (>= (- $columns 2) 0) (l41 $cov-matrice) Empty) (if (>= (- $columns 3) 0) (l42 $cov-matrice) Empty) (if (>= (- $columns 4) 0) (l43 $cov-matrice) Empty) (if (>= (- $columns 5) 0) (l44 $cov-matrice) Empty) (if (>= (- $columns 6) 0) 0 Empty) (if (>= (- $columns 7) 0) 0 Empty) (if (>= (- $columns 8) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $rows 6) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (l50 $cov-matrice) Empty) (if (>= (- $columns 2) 0) (l51 $cov-matrice) Empty) (if (>= (- $columns 3) 0) (l52 $cov-matrice) Empty) (if (>= (- $columns 4) 0) (l53 $cov-matrice) Empty) (if (>= (- $columns 5) 0) (l54 $cov-matrice) Empty) (if (>= (- $columns 6) 0) (l55 $cov-matrice) Empty) (if (>= (- $columns 7) 0) 0 Empty) (if (>= (- $columns 8) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $rows 7) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (l60 $cov-matrice) Empty) (if (>= (- $columns 2) 0) (l61 $cov-matrice) Empty) (if (>= (- $columns 3) 0) (l62 $cov-matrice) Empty) (if (>= (- $columns 4) 0) (l63 $cov-matrice) Empty) (if (>= (- $columns 5) 0) (l64 $cov-matrice) Empty) (if (>= (- $columns 6) 0) (l65 $cov-matrice) Empty) (if (>= (- $columns 7) 0) (l66 $cov-matrice) Empty) (if (>= (- $columns 8) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $rows 8) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (l70 $cov-matrice) Empty) (if (>= (- $columns 2) 0) (l71 $cov-matrice) Empty) (if (>= (- $columns 3) 0) (l72 $cov-matrice) Empty) (if (>= (- $columns 4) 0) (l73 $cov-matrice) Empty) (if (>= (- $columns 5) 0) (l74 $cov-matrice) Empty) (if (>= (- $columns 6) 0) (l75 $cov-matrice) Empty) (if (>= (- $columns 7) 0) (l76 $cov-matrice) Empty) (if (>= (- $columns 8) 0) (l77 $cov-matrice) Empty)
                            )
                        )
                    )
                    Empty
                )
            )
        )
    )
)
)

(= (-ve $number)
    (- 0.0 $number)
)

(: to-float (-> Number Number))
(=(to-float $number)
    (- (+ $number 0.1) 0.1)
)
; !(to-float 1)

(: div (-> Number Number Number))
(= (div $num $denom)
    (/ (to-float $num) $denom)
)

(= (m00)
    (let $l00 (match &lspace (cell l00 $x) $x) 
        (let $m00 (div 1 $l00) 
            (let $add (add-atom &mspace (cell m00 $m00)) $m00)
        )
    )
)

(= (m10)
    (let ($l10 $l11 $m00) ((match &lspace (cell l10 $x) $x) (match &lspace (cell l11 $x) $x) (match &mspace (cell m00 $x) $x))
        (let $m10 (-ve (* $m00 (div $l10 $l11)))
            (let $add (add-atom &mspace (cell m10 $m10)) $m10)
        )
    )
)


(= (m11)
    (let $l11 (match &lspace (cell l11 $x) $x) 
        (let $m11 (div 1.0 $l11) 
            (let $add (add-atom &mspace (cell m11 $m11)) $m11)
        )
    )
)

(= (m20)
    (let $l22 (match &lspace (cell l22 $x) $x)
        (let $m20 (-ve (div (sum (inverse-cells-product 2 0)) $l22))
            (let $add (add-atom &mspace (cell m20 $m20)) $m20)
        )
    )
)

(= (m21)
    (let ($l21 $l22 $l11) (collapse(superpose((match &lspace (cell l21 $x) $x) (match &lspace (cell l22 $x) $x) (match &lspace (cell l11 $x) $x))))
        (let $m21 (-ve (div $l21 (* $l22 $l11)))
            (let $add (add-atom &mspace (cell m21 $m21)) $m21)
        )
    )
)

(= (m22)
    (let $l22 (match &lspace (cell l22 $x) $x)
        (let $m22 (div 1.0 $l22)
            (let $add (add-atom &mspace (cell m22 $m22)) $m22)
        )
    )
)

(= (m30)
    (let $l33 (match &lspace (cell l33 $x) $x)
        (let $m30 (-ve (div (sum (inverse-cells-product 3 0)) $l33))
            (let $add (add-atom &mspace (cell m30 $m30)) $m30)
        )
    )
)

(= (m31)
    (let $l33 (match &lspace (cell l33 $x) $x)
        (let $m31 (-ve (div (sum (inverse-cells-product 3 1)) $l33))
            (let $add (add-atom &mspace (cell m31 $m31)) $m31)
        )
    )
)

(= (m32)
    (let ($l32 $l33 $l22) (collapse(superpose((match &lspace (cell l32 $x) $x) (match &lspace (cell l33 $x) $x) (match &lspace (cell l22 $x) $x))))
        (let $m32 (-ve (div $l32 (* $l33 $l22)))
            (let $add (add-atom &mspace (cell m32 $m32)) $m32)
        )
    )
)

(= (m33)
    (let $l33 (match &lspace (cell l33 $x) $x)
        (let $m33 (div 1.0 $l33)
            (let $add (add-atom &mspace (cell m33 $m33)) $m33)
        )
    )
)

(= (m40)
    (let $l44 (match &lspace (cell l44 $x) $x)
        (let $m40 (-ve (div (sum (inverse-cells-product 4 0)) $l44))
            (let $add (add-atom &mspace (cell m40 $m40)) $m40)
        )
    )
)

(= (m41)
    (let $l44 (match &lspace (cell l44 $x) $x)
        (let $m41 (-ve (div (sum (inverse-cells-product 4 1)) $l44))
            (let $add (add-atom &mspace (cell m41 $m41)) $m41)
        )
    )
)

(= (m42)
    (let $l44 (match &lspace (cell l44 $x) $x)
        (let $m42 (-ve (div (sum (inverse-cells-product 4 2)) $l44))
            (let $add (add-atom &mspace (cell m42 $m42)) $m42)
        )
    )
)

(= (m43)
    (let ($l43 $l44 $l33) (collapse(superpose((match &lspace (cell l43 $x) $x) (match &lspace (cell l44 $x) $x) (match &lspace (cell l33 $x) $x))))
        (let $m43 (-ve (div $l43 (* $l44 $l33)))
            (let $add (add-atom &mspace (cell m43 $m43)) $m43)
        )
    )
)

(= (m44)
    (let $l44 (match &lspace (cell l44 $x) $x)
        (let $m44 (div 1.0 $l44)
            (let $add (add-atom &mspace (cell m44 $m44)) $m44)
        )
    )
)

(= (m50)
    (let $l55 (match &lspace (cell l55 $x) $x)
        (let $m50 (-ve (div (sum (inverse-cells-product 5 0)) $l55))
            (let $add (add-atom &mspace (cell m50 $m50)) $m50)
        )
    )
)

(= (m51)
    (let $l55 (match &lspace (cell l55 $x) $x)
        (let $m51 (-ve (div (sum (inverse-cells-product 5 1)) $l55))
            (let $add (add-atom &mspace (cell m51 $m51)) $m51)
        )
    )
)

(= (m52)
    (let $l55 (match &lspace (cell l55 $x) $x)
        (let $m52 (-ve (div (sum (inverse-cells-product 5 2)) $l55))
            (let $add (add-atom &mspace (cell m52 $m52)) $m52)
        )
    )
)

(= (m53)
    (let $l55 (match &lspace (cell l55 $x) $x)
        (let $m53 (-ve (div (sum (inverse-cells-product 5 3)) $l55))
            (let $add (add-atom &mspace (cell m53 $m53)) $m53)
        )
    )
)

(= (m54)
    (let ($l54 $l55 $l44) (collapse(superpose((match &lspace (cell l54 $x) $x) (match &lspace (cell l55 $x) $x) (match &lspace (cell l44 $x) $x))))
        (let $m54 (-ve (div $l54 (* $l55 $l44)))
            (let $add (add-atom &mspace (cell m54 $m54)) $m54)
        )
    )
)

(= (m55)
    (let $l55 (match &lspace (cell l55 $x) $x)
        (let $m55 (div 1.0 $l55)
            (let $add (add-atom &mspace (cell m55 $m55)) $m55)
        )
    )
)

(= (m60)
    (let $l66 (match &lspace (cell l66 $x) $x)
        (let $m60 (-ve (div (sum (inverse-cells-product 6 0)) $l66))
            (let $add (add-atom &mspace (cell m60 $m60)) $m60)
        )
    )
)

(= (m61)
    (let $l66 (match &lspace (cell l66 $x) $x)
        (let $m61 (-ve (div (sum (inverse-cells-product 6 1)) $l66))
            (let $add (add-atom &mspace (cell m61 $m61)) $m61)
        )
    )
)

(= (m62)
    (let $l66 (match &lspace (cell l66 $x) $x)
        (let $m62 (-ve (div (sum (inverse-cells-product 6 2)) $l66))
            (let $add (add-atom &mspace (cell m62 $m62)) $m62)
        )
    )
)

(= (m63)
    (let $l66 (match &lspace (cell l66 $x) $x)
        (let $m63 (-ve (div (sum (inverse-cells-product 6 3)) $l66))
            (let $add (add-atom &mspace (cell m63 $m63)) $m63)
        )
    )
)

(= (m64)
    (let $l66 (match &lspace (cell l66 $x) $x)
        (let $m64 (-ve (div (sum (inverse-cells-product 6 4)) $l66))
            (let $add (add-atom &mspace (cell m64 $m64)) $m64)
        )
    )
)

(= (m65)
    (let ($l65 $l66 $l55) (collapse(superpose((match &lspace (cell l65 $x) $x) (match &lspace (cell l66 $x) $x) (match &lspace (cell l55 $x) $x))))
        (let $m65 (-ve (div $l65 (* $l66 $l55)))
            (let $add (add-atom &mspace (cell m65 $m65)) $m65)
        )
    )
)

(= (m66)
    (let $l66 (match &lspace (cell l66 $x) $x)
        (let $m66 (div 1.0 $l66)
            (let $add (add-atom &mspace (cell m66 $m66)) $m66)
        )
    )
)

(= (m70)
    (let $l77 (match &lspace (cell l77 $x) $x)
        (let $m70 (-ve (div (sum (inverse-cells-product 7 0)) $l77))
            (let $add (add-atom &mspace (cell m70 $m70)) $m70)
        )
    )
)

(= (m71)
    (let $l77 (match &lspace (cell l77 $x) $x)
        (let $m71 (-ve (div (sum (inverse-cells-product 7 1)) $l77))
            (let $add (add-atom &mspace (cell m71 $m71)) $m71)
        )
    )
)

(= (m72)
    (let $l77 (match &lspace (cell l77 $x) $x)
        (let $m72 (-ve (div (sum (inverse-cells-product 7 2)) $l77))
            (let $add (add-atom &mspace (cell m72 $m72)) $m72)
        )
    )
)

(= (m73)
    (let $l77 (match &lspace (cell l77 $x) $x)
        (let $m73 (-ve (div (sum (inverse-cells-product 7 3)) $l77))
            (let $add (add-atom &mspace (cell m73 $m73)) $m73)
        )
    )
)

(= (m74)
    (let $l77 (match &lspace (cell l77 $x) $x)
        (let $m74 (-ve (div (sum (inverse-cells-product 7 4)) $l77))
            (let $add (add-atom &mspace (cell m74 $m74)) $m74)
        )
    )
)

(= (m75)
    (let $l77 (match &lspace (cell l77 $x) $x)
        (let $m75 (-ve (div (sum (inverse-cells-product 7 5)) $l77))
            (let $add (add-atom &mspace (cell m75 $m75)) $m75)
        )
    )
)

(= (m76)
    (let ($l76 $l77 $l66) (collapse(superpose((match &lspace (cell l76 $x) $x) (match &lspace (cell l77 $x) $x) (match &lspace (cell l66 $x) $x))))
        (let $m76 (-ve (div $l76 (* $l77 $l66)))
            (let $add (add-atom &mspace (cell m76 $m76)) $m76)
        )
    )
)

(= (m77)
    (let $l77 (match &lspace (cell l77 $x) $x)
        (let $m77 (div 1.0 $l77)
            (let $add (add-atom &mspace (cell m77 $m77)) $m77)
        )
    )
)

; !(add-atom &mspace (cell m00 0.055))
; !(add-atom &mspace (cell m10 0.045))
; !(add-atom &mspace (cell m20 01888))
; !(add-atom &mspace (cell m30 0.027))
; !(add-atom &mspace (cell m11 0.055))
; !(add-atom &mspace (cell m21 0.166))
; !(add-atom &mspace (cell m31 0.027))
; !(add-atom &mspace (cell m22 0.1666))
; !(add-atom &mspace (cell m32 -0.055))
; !(inverse-cells-product 4 2)
; !(m42)
; !(add-atom &mspace (cell m21 0.1666))

; (= (m20)
;     (sum (inverse-cells-product 2 0))
; )
; !(m20)

(= (inverse-lmatrice $lmatrice)
    (let ($add $rows $columns) (collapse(superpose((let $atoms (collapse(get-atoms &lspace)) (if (== (size-atom $atoms) 0) (add-lmat-to-lspace $lmatrice) ())) (size-atom $lmatrice) (let $row0 (index-atom $lmatrice 0) (size-atom $row0)))))
    (collapse
        (superpose
            (
                (
                    if (>= (- $rows 1) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (m00) Empty) (if (>= (- $columns 2) 0) 0 Empty) (if (>= (- $columns 3) 0) 0 Empty) (if (>= (- $columns 4) 0) 0 Empty) (if (>= (- $columns 5) 0) 0 Empty) (if (>= (- $columns 6) 0) 0 Empty) (if (>= (- $columns 7) 0) 0 Empty) (if (>= (- $columns 8) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $rows 2) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (m10) Empty) (if (>= (- $columns 2) 0) (m11) Empty) (if (>= (- $columns 3) 0) 0 Empty) (if (>= (- $columns 4) 0) 0 Empty) (if (>= (- $columns 5) 0) 0 Empty) (if (>= (- $columns 6) 0) 0 Empty) (if (>= (- $columns 7) 0) 0 Empty) (if (>= (- $columns 8) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $rows 3) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (m20) Empty) (if (>= (- $columns 2) 0) (m21) Empty) (if (>= (- $columns 3) 0) (m22) Empty) (if (>= (- $columns 4) 0) 0 Empty) (if (>= (- $columns 5) 0) 0 Empty) (if (>= (- $columns 6) 0) 0 Empty) (if (>= (- $columns 7) 0) 0 Empty) (if (>= (- $columns 8) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $rows 4) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (m30) Empty) (if (>= (- $columns 2) 0) (m31) Empty) (if (>= (- $columns 3) 0) (m32) Empty) (if (>= (- $columns 4) 0) (m33) Empty) (if (>= (- $columns 5) 0) 0 Empty) (if (>= (- $columns 6) 0) 0 Empty) (if (>= (- $columns 7) 0) 0 Empty) (if (>= (- $columns 8) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $rows 5) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (m40) Empty) (if (>= (- $columns 2) 0) (m41) Empty) (if (>= (- $columns 3) 0) (m42) Empty) (if (>= (- $columns 4) 0) (m43) Empty) (if (>= (- $columns 5) 0) (m44) Empty) (if (>= (- $columns 6) 0) 0 Empty) (if (>= (- $columns 7) 0) 0 Empty) (if (>= (- $columns 8) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $rows 6) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (m50) Empty) (if (>= (- $columns 2) 0) (m51) Empty) (if (>= (- $columns 3) 0) (m52) Empty) (if (>= (- $columns 4) 0) (m53) Empty) (if (>= (- $columns 5) 0) (m54) Empty) (if (>= (- $columns 6) 0) (m55) Empty) (if (>= (- $columns 7) 0) 0 Empty) (if (>= (- $columns 8) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $rows 7) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (m60) Empty) (if (>= (- $columns 2) 0) (m61) Empty) (if (>= (- $columns 3) 0) (m62) Empty) (if (>= (- $columns 4) 0) (m63) Empty) (if (>= (- $columns 5) 0) (m64) Empty) (if (>= (- $columns 6) 0) (m65) Empty) (if (>= (- $columns 7) 0) (m66) Empty) (if (>= (- $columns 8) 0) 0 Empty)
                            )
                        )
                    )
                    Empty
                )
                (
                    if (>= (- $rows 8) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (m70) Empty) (if (>= (- $columns 2) 0) (m71) Empty) (if (>= (- $columns 3) 0) (m72) Empty) (if (>= (- $columns 4) 0) (m73) Empty) (if (>= (- $columns 5) 0) (m74) Empty) (if (>= (- $columns 6) 0) (m75) Empty) (if (>= (- $columns 7) 0) (m76) Empty) (if (>= (- $columns 8) 0) (m77) Empty)
                            )
                        )
                    )
                    Empty
                )
            )
        )
    )
    )
)

; !(inverse-lmatrice ((2.449489742783178 0 0 0 0 0 0 0) (0.8164965809277261 2.309401076758503 0 0 0 0 0 0) (1.2247448713915892 0.8660254037844386 1.9364916731037085 0 0 0 0 0) (0.8164965809277261 0.5773502691896256 0.2581988897471611 2.2211108331943574 0 0 0 0) (0.4082482904638631 0.2886751345948128 0.12909944487358055 0.2101050788156825 2.38520212753326 0 0 0) (0.4082482904638631 0.2886751345948128 0.12909944487358055 0.2101050788156825 0.288943725663174 2.3676361022313106 0 0) (0.4082482904638631 0.2886751345948128 0.12909944487358055 0.2101050788156825 0.288943725663174 0.2558250873173662 2.353774466105055 0) (0.4082482904638631 0.2886751345948128 0.12909944487358055 0.2101050788156825 0.288943725663174 0.2558250873173662 0.22952676438118122 2.3425566592338467)))

(= (transpose-matrice $matrice)
    (let ($rows $columns) ((size-atom $matrice) (let $row0 (index-atom $matrice 0) (size-atom $row0)))
        (collapse
            (superpose
                (
                    (if (>= (- $columns 1) 0)
                    (collapse(superpose((if (>= (- $rows 1) 0) (let $row0 (index-atom $matrice 0) (index-atom $row0 0)) Empty) (if (>= (- $rows 2) 0) (let $row1 (index-atom $matrice 1) (index-atom $row1 0)) Empty) (if (>= (- $rows 3) 0) (let $row2 (index-atom $matrice 2) (index-atom $row2 0)) Empty) (if (>= (- $rows 4) 0) (let $row3 (index-atom $matrice 3) (index-atom $row3 0)) Empty) (if (>= (- $rows 5) 0) (let $row4 (index-atom $matrice 4) (index-atom $row4 0)) Empty) (if (>= (- $rows 6) 0) (let $row5 (index-atom $matrice 5) (index-atom $row5 0)) Empty) (if (>= (- $rows 7) 0) (let $row6 (index-atom $matrice 6) (index-atom $row6 0)) Empty) (if (>= (- $rows 8) 0) (let $row7 (index-atom $matrice 7) (index-atom $row7 0)) Empty))))
                    Empty                    
                    )
                    (if (>= (- $columns 2) 0)
                    (collapse(superpose((if (>= (- $rows 1) 0) (let $row0 (index-atom $matrice 0) (index-atom $row0 1)) Empty) (if (>= (- $rows 2) 0) (let $row1 (index-atom $matrice 1) (index-atom $row1 1)) Empty) (if (>= (- $rows 3) 0) (let $row2 (index-atom $matrice 2) (index-atom $row2 1)) Empty) (if (>= (- $rows 4) 0) (let $row3 (index-atom $matrice 3) (index-atom $row3 1)) Empty) (if (>= (- $rows 5) 0) (let $row4 (index-atom $matrice 4) (index-atom $row4 1)) Empty) (if (>= (- $rows 6) 0) (let $row5 (index-atom $matrice 5) (index-atom $row5 1)) Empty) (if (>= (- $rows 7) 0) (let $row6 (index-atom $matrice 6) (index-atom $row6 1)) Empty) (if (>= (- $rows 8) 0) (let $row7 (index-atom $matrice 7) (index-atom $row7 1)) Empty))))
                    Empty                    
                    )
                    (if (>= (- $columns 3) 0)
                    (collapse(superpose((if (>= (- $rows 1) 0) (let $row0 (index-atom $matrice 0) (index-atom $row0 2)) Empty) (if (>= (- $rows 2) 0) (let $row1 (index-atom $matrice 1) (index-atom $row1 2)) Empty) (if (>= (- $rows 3) 0) (let $row2 (index-atom $matrice 2) (index-atom $row2 2)) Empty) (if (>= (- $rows 4) 0) (let $row3 (index-atom $matrice 3) (index-atom $row3 2)) Empty) (if (>= (- $rows 5) 0) (let $row4 (index-atom $matrice 4) (index-atom $row4 2)) Empty) (if (>= (- $rows 6) 0) (let $row5 (index-atom $matrice 5) (index-atom $row5 2)) Empty) (if (>= (- $rows 7) 0) (let $row6 (index-atom $matrice 6) (index-atom $row6 2)) Empty) (if (>= (- $rows 8) 0) (let $row7 (index-atom $matrice 7) (index-atom $row7 2)) Empty))))
                    Empty                    
                    )
                    (if (>= (- $columns 4) 0)
                    (collapse(superpose((if (>= (- $rows 1) 0) (let $row0 (index-atom $matrice 0) (index-atom $row0 3)) Empty) (if (>= (- $rows 2) 0) (let $row1 (index-atom $matrice 1) (index-atom $row1 3)) Empty) (if (>= (- $rows 3) 0) (let $row2 (index-atom $matrice 2) (index-atom $row2 3)) Empty) (if (>= (- $rows 4) 0) (let $row3 (index-atom $matrice 3) (index-atom $row3 3)) Empty) (if (>= (- $rows 5) 0) (let $row4 (index-atom $matrice 4) (index-atom $row4 3)) Empty) (if (>= (- $rows 6) 0) (let $row5 (index-atom $matrice 5) (index-atom $row5 3)) Empty) (if (>= (- $rows 7) 0) (let $row6 (index-atom $matrice 6) (index-atom $row6 3)) Empty) (if (>= (- $rows 8) 0) (let $row7 (index-atom $matrice 7) (index-atom $row7 3)) Empty))))
                    Empty                    
                    )
                    (if (>= (- $columns 5) 0)
                    (collapse(superpose((if (>= (- $rows 1) 0) (let $row0 (index-atom $matrice 0) (index-atom $row0 4)) Empty) (if (>= (- $rows 2) 0) (let $row1 (index-atom $matrice 1) (index-atom $row1 4)) Empty) (if (>= (- $rows 3) 0) (let $row2 (index-atom $matrice 2) (index-atom $row2 4)) Empty) (if (>= (- $rows 4) 0) (let $row3 (index-atom $matrice 3) (index-atom $row3 4)) Empty) (if (>= (- $rows 5) 0) (let $row4 (index-atom $matrice 4) (index-atom $row4 4)) Empty) (if (>= (- $rows 6) 0) (let $row5 (index-atom $matrice 5) (index-atom $row5 4)) Empty) (if (>= (- $rows 7) 0) (let $row6 (index-atom $matrice 6) (index-atom $row6 4)) Empty) (if (>= (- $rows 8) 0) (let $row7 (index-atom $matrice 7) (index-atom $row7 4)) Empty))))
                    Empty                    
                    )
                    (if (>= (- $columns 6) 0)
                    (collapse(superpose((if (>= (- $rows 1) 0) (let $row0 (index-atom $matrice 0) (index-atom $row0 5)) Empty) (if (>= (- $rows 2) 0) (let $row1 (index-atom $matrice 1) (index-atom $row1 5)) Empty) (if (>= (- $rows 3) 0) (let $row2 (index-atom $matrice 2) (index-atom $row2 5)) Empty) (if (>= (- $rows 4) 0) (let $row3 (index-atom $matrice 3) (index-atom $row3 5)) Empty) (if (>= (- $rows 5) 0) (let $row4 (index-atom $matrice 4) (index-atom $row4 5)) Empty) (if (>= (- $rows 6) 0) (let $row5 (index-atom $matrice 5) (index-atom $row5 5)) Empty) (if (>= (- $rows 7) 0) (let $row6 (index-atom $matrice 6) (index-atom $row6 5)) Empty) (if (>= (- $rows 8) 0) (let $row7 (index-atom $matrice 7) (index-atom $row7 5)) Empty))))
                    Empty                    
                    )
                    (if (>= (- $columns 7) 0)
                    (collapse(superpose((if (>= (- $rows 1) 0) (let $row0 (index-atom $matrice 0) (index-atom $row0 6)) Empty) (if (>= (- $rows 2) 0) (let $row1 (index-atom $matrice 1) (index-atom $row1 6)) Empty) (if (>= (- $rows 3) 0) (let $row2 (index-atom $matrice 2) (index-atom $row2 6)) Empty) (if (>= (- $rows 4) 0) (let $row3 (index-atom $matrice 3) (index-atom $row3 6)) Empty) (if (>= (- $rows 5) 0) (let $row4 (index-atom $matrice 4) (index-atom $row4 6)) Empty) (if (>= (- $rows 6) 0) (let $row5 (index-atom $matrice 5) (index-atom $row5 6)) Empty) (if (>= (- $rows 7) 0) (let $row6 (index-atom $matrice 6) (index-atom $row6 6)) Empty) (if (>= (- $rows 8) 0) (let $row7 (index-atom $matrice 7) (index-atom $row7 6)) Empty))))
                    Empty                    
                    )
                    (if (>= (- $columns 8) 0)
                    (collapse(superpose((if (>= (- $rows 1) 0) (let $row0 (index-atom $matrice 0) (index-atom $row0 7)) Empty) (if (>= (- $rows 2) 0) (let $row1 (index-atom $matrice 1) (index-atom $row1 7)) Empty) (if (>= (- $rows 3) 0) (let $row2 (index-atom $matrice 2) (index-atom $row2 7)) Empty) (if (>= (- $rows 4) 0) (let $row3 (index-atom $matrice 3) (index-atom $row3 7)) Empty) (if (>= (- $rows 5) 0) (let $row4 (index-atom $matrice 4) (index-atom $row4 7)) Empty) (if (>= (- $rows 6) 0) (let $row5 (index-atom $matrice 5) (index-atom $row5 7)) Empty) (if (>= (- $rows 7) 0) (let $row6 (index-atom $matrice 6) (index-atom $row6 7)) Empty) (if (>= (- $rows 8) 0) (let $row7 (index-atom $matrice 7) (index-atom $row7 7)) Empty))))
                    Empty                    
                    )
                )
            )
        )
    )
)

; !(chol-decomp ((1 0 0 0 0 0 0 0) (0 1 0 0 0 0 0 0) (0 0 1 0 0 0 0 0) (0 0 0 1 0 0 0 0) (0 0 0 0 1 0 0 0) (0 0 0 0 0 1 0 0) (0 0 0 0 0 0 1 0) (0 0 0 0 0 0 0 1)))
; !(get-atoms &lspace)
; !(match &lspace (cell $x $y) (remove-atom &lspace (cell $x $y)))
; !(get-atoms &lspace)
; !(inverse-lmatrice ((1.0 0 0 0 0 0 0 0) (0.0 1.0 0 0 0 0 0 0) (0.0 0.0 1.0 0 0 0 0 0) (0.0 0.0 0.0 1.0 0 0 0 0) (0.0 0.0 0.0 0.0 1.0 0 0 0) (0.0 0.0 0.0 0.0 0.0 1.0 0 0) (0.0 0.0 0.0 0.0 0.0 0.0 1.0 0) (0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0)))
; !(transpose-matrice ((1.0 0 0 0 0 0 0 0) (0.0 1.0 0 0 0 0 0 0) (0.0 0.0 1.0 0 0 0 0 0) (0.0 0.0 0.0 1.0 0 0 0 0) (0.0 0.0 0.0 0.0 1.0 0 0 0) (0.0 0.0 0.0 0.0 0.0 1.0 0 0) (0.0 0.0 0.0 0.0 0.0 0.0 1.0 0) (0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0)))
; !(transpose-matrice (inverse-lmatrice (chol-decomp ((1.0 0 0 0 0 0 0 0) (0.0 1.0 0 0 0 0 0 0) (0.0 0.0 1.0 0 0 0 0 0) (0.0 0.0 0.0 1.0 0 0 0 0) (0.0 0.0 0.0 0.0 1.0 0 0 0) (0.0 0.0 0.0 0.0 0.0 1.0 0 0) (0.0 0.0 0.0 0.0 0.0 0.0 1.0 0) (0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0)))))
; !(match &mspace (cell m22 $x) $x)
; !(match &mspace (cell m32 $x) $x)
; !(chol-decomp ((6 2 3 2 1 1 1 1)
;  (2 6 3 2 1 1 1 1)
;  (3 3 6 2 1 1 1 1)
;  (2 2 2 6 1 1 1 1)
;  (1 1 1 1 6 1 1 1)
;  (1 1 1 1 1 6 1 1)
;  (1 1 1 1 1 1 6 1)
;  (1 1 1 1 1 1 1 6)))

; (= (standard-normal $dim $lambda_)
;     (let $lambda-list (generate-toy-list $lambda_) (map-atom $lambda-list $x (let $dim-list (generate-toy-list $dim) (map-atom $dim-list $y (gauss 1)))))
; )

(= (standard-normal $dim $lambda_)
    (collapse
        (superpose
            (
                (if (>= (- $lambda_ 1) 0)
                (collapse(superpose((if (>= (- $dim 1) 0) (gauss 1) Empty) (if (>= (- $dim 2) 0) (gauss 1) Empty) (if (>= (- $dim 3) 0) (gauss 1) Empty) (if (>= (- $dim 4) 0) (gauss 1) Empty) (if (>= (- $dim 5) 0) (gauss 1) Empty) (if (>= (- $dim 6) 0) (gauss 1) Empty) (if (>= (- $dim 7) 0) (gauss 1) Empty) (if (>= (- $dim 8) 0) (gauss 1) Empty))))
                Empty
                )
                (if (>= (- $lambda_ 2) 0)
                (collapse(superpose((if (>= (- $dim 1) 0) (gauss 1) Empty) (if (>= (- $dim 2) 0) (gauss 1) Empty) (if (>= (- $dim 3) 0) (gauss 1) Empty) (if (>= (- $dim 4) 0) (gauss 1) Empty) (if (>= (- $dim 5) 0) (gauss 1) Empty) (if (>= (- $dim 6) 0) (gauss 1) Empty) (if (>= (- $dim 7) 0) (gauss 1) Empty) (if (>= (- $dim 8) 0) (gauss 1) Empty))))
                Empty
                )
                (if (>= (- $lambda_ 3) 0)
                (collapse(superpose((if (>= (- $dim 1) 0) (gauss 1) Empty) (if (>= (- $dim 2) 0) (gauss 1) Empty) (if (>= (- $dim 3) 0) (gauss 1) Empty) (if (>= (- $dim 4) 0) (gauss 1) Empty) (if (>= (- $dim 5) 0) (gauss 1) Empty) (if (>= (- $dim 6) 0) (gauss 1) Empty) (if (>= (- $dim 7) 0) (gauss 1) Empty) (if (>= (- $dim 8) 0) (gauss 1) Empty))))
                Empty
                )
                (if (>= (- $lambda_ 4) 0)
                (collapse(superpose((if (>= (- $dim 1) 0) (gauss 1) Empty) (if (>= (- $dim 2) 0) (gauss 1) Empty) (if (>= (- $dim 3) 0) (gauss 1) Empty) (if (>= (- $dim 4) 0) (gauss 1) Empty) (if (>= (- $dim 5) 0) (gauss 1) Empty) (if (>= (- $dim 6) 0) (gauss 1) Empty) (if (>= (- $dim 7) 0) (gauss 1) Empty) (if (>= (- $dim 8) 0) (gauss 1) Empty))))
                Empty
                )
                (if (>= (- $lambda_ 5) 0)
                (collapse(superpose((if (>= (- $dim 1) 0) (gauss 1) Empty) (if (>= (- $dim 2) 0) (gauss 1) Empty) (if (>= (- $dim 3) 0) (gauss 1) Empty) (if (>= (- $dim 4) 0) (gauss 1) Empty) (if (>= (- $dim 5) 0) (gauss 1) Empty) (if (>= (- $dim 6) 0) (gauss 1) Empty) (if (>= (- $dim 7) 0) (gauss 1) Empty) (if (>= (- $dim 8) 0) (gauss 1) Empty))))
                Empty
                )
                (if (>= (- $lambda_ 6) 0)
                (collapse(superpose((if (>= (- $dim 1) 0) (gauss 1) Empty) (if (>= (- $dim 2) 0) (gauss 1) Empty) (if (>= (- $dim 3) 0) (gauss 1) Empty) (if (>= (- $dim 4) 0) (gauss 1) Empty) (if (>= (- $dim 5) 0) (gauss 1) Empty) (if (>= (- $dim 6) 0) (gauss 1) Empty) (if (>= (- $dim 7) 0) (gauss 1) Empty) (if (>= (- $dim 8) 0) (gauss 1) Empty))))
                Empty
                )
                (if (>= (- $lambda_ 7) 0)
                (collapse(superpose((if (>= (- $dim 1) 0) (gauss 1) Empty) (if (>= (- $dim 2) 0) (gauss 1) Empty) (if (>= (- $dim 3) 0) (gauss 1) Empty) (if (>= (- $dim 4) 0) (gauss 1) Empty) (if (>= (- $dim 5) 0) (gauss 1) Empty) (if (>= (- $dim 6) 0) (gauss 1) Empty) (if (>= (- $dim 7) 0) (gauss 1) Empty) (if (>= (- $dim 8) 0) (gauss 1) Empty))))
                Empty
                )
                (if (>= (- $lambda_ 8) 0)
                (collapse(superpose((if (>= (- $dim 1) 0) (gauss 1) Empty) (if (>= (- $dim 2) 0) (gauss 1) Empty) (if (>= (- $dim 3) 0) (gauss 1) Empty) (if (>= (- $dim 4) 0) (gauss 1) Empty) (if (>= (- $dim 5) 0) (gauss 1) Empty) (if (>= (- $dim 6) 0) (gauss 1) Empty) (if (>= (- $dim 7) 0) (gauss 1) Empty) (if (>= (- $dim 8) 0) (gauss 1) Empty))))
                Empty
                )
                (if (>= (- $lambda_ 9) 0)
                (collapse(superpose((if (>= (- $dim 1) 0) (gauss 1) Empty) (if (>= (- $dim 2) 0) (gauss 1) Empty) (if (>= (- $dim 3) 0) (gauss 1) Empty) (if (>= (- $dim 4) 0) (gauss 1) Empty) (if (>= (- $dim 5) 0) (gauss 1) Empty) (if (>= (- $dim 6) 0) (gauss 1) Empty) (if (>= (- $dim 7) 0) (gauss 1) Empty) (if (>= (- $dim 8) 0) (gauss 1) Empty))))
                Empty
                )
                (if (>= (- $lambda_ 10) 0)
                (collapse(superpose((if (>= (- $dim 1) 0) (gauss 1) Empty) (if (>= (- $dim 2) 0) (gauss 1) Empty) (if (>= (- $dim 3) 0) (gauss 1) Empty) (if (>= (- $dim 4) 0) (gauss 1) Empty) (if (>= (- $dim 5) 0) (gauss 1) Empty) (if (>= (- $dim 6) 0) (gauss 1) Empty) (if (>= (- $dim 7) 0) (gauss 1) Empty) (if (>= (- $dim 8) 0) (gauss 1) Empty))))
                Empty
                )
            )
        )
    )
)

(= (mat-vec-mul $matrice $vector)
    (let ($mat-rows $mat-dim $vec-dim $lambda_) (collapse(superpose((size-atom $matrice) (let $mat-row0 (index-atom $matrice 0) (size-atom $mat-row0)) (let $vec-row0 (index-atom $vector 0) (size-atom $vec-row0)) (size-atom $vector))))
        (if (== $mat-dim $vec-dim)
            (collapse
                (superpose
                    (
                        (if (>= (- $lambda_ 1) 0)
                        (let $vec-row0 (index-atom $vector 0)
                        (collapse(superpose(
                        (if (>= (- $mat-rows 1) 0) (let $mat-row0 (index-atom $matrice 0) (sum (collapse(superpose((* (index-atom $mat-row0 0) (index-atom $vec-row0 0)) (* (index-atom $mat-row0 1) (index-atom $vec-row0 1)) (* (index-atom $mat-row0 2) (index-atom $vec-row0 2)) (* (index-atom $mat-row0 3) (index-atom $vec-row0 3)) (* (index-atom $mat-row0 4) (index-atom $vec-row0 4)) (* (index-atom $mat-row0 5) (index-atom $vec-row0 5)) (* (index-atom $mat-row0 6) (index-atom $vec-row0 6)) (* (index-atom $mat-row0 7) (index-atom $vec-row0 7))))))) Empty)
                        (if (>= (- $mat-rows 2) 0) (let $mat-row1 (index-atom $matrice 1) (sum (collapse(superpose((* (index-atom $mat-row1 0) (index-atom $vec-row0 0)) (* (index-atom $mat-row1 1) (index-atom $vec-row0 1)) (* (index-atom $mat-row1 2) (index-atom $vec-row0 2)) (* (index-atom $mat-row1 3) (index-atom $vec-row0 3)) (* (index-atom $mat-row1 4) (index-atom $vec-row0 4)) (* (index-atom $mat-row1 5) (index-atom $vec-row0 5)) (* (index-atom $mat-row1 6) (index-atom $vec-row0 6)) (* (index-atom $mat-row1 7) (index-atom $vec-row0 7))))))) Empty)
                        (if (>= (- $mat-rows 3) 0) (let $mat-row2 (index-atom $matrice 2) (sum (collapse(superpose((* (index-atom $mat-row2 0) (index-atom $vec-row0 0)) (* (index-atom $mat-row2 1) (index-atom $vec-row0 1)) (* (index-atom $mat-row2 2) (index-atom $vec-row0 2)) (* (index-atom $mat-row2 3) (index-atom $vec-row0 3)) (* (index-atom $mat-row2 4) (index-atom $vec-row0 4)) (* (index-atom $mat-row2 5) (index-atom $vec-row0 5)) (* (index-atom $mat-row2 6) (index-atom $vec-row0 6)) (* (index-atom $mat-row2 7) (index-atom $vec-row0 7))))))) Empty)
                        (if (>= (- $mat-rows 4) 0) (let $mat-row3 (index-atom $matrice 3) (sum (collapse(superpose((* (index-atom $mat-row3 0) (index-atom $vec-row0 0)) (* (index-atom $mat-row3 1) (index-atom $vec-row0 1)) (* (index-atom $mat-row3 2) (index-atom $vec-row0 2)) (* (index-atom $mat-row3 3) (index-atom $vec-row0 3)) (* (index-atom $mat-row3 4) (index-atom $vec-row0 4)) (* (index-atom $mat-row3 5) (index-atom $vec-row0 5)) (* (index-atom $mat-row3 6) (index-atom $vec-row0 6)) (* (index-atom $mat-row3 7) (index-atom $vec-row0 7))))))) Empty)
                        (if (>= (- $mat-rows 5) 0) (let $mat-row4 (index-atom $matrice 4) (sum (collapse(superpose((* (index-atom $mat-row4 0) (index-atom $vec-row0 0)) (* (index-atom $mat-row4 1) (index-atom $vec-row0 1)) (* (index-atom $mat-row4 2) (index-atom $vec-row0 2)) (* (index-atom $mat-row4 3) (index-atom $vec-row0 3)) (* (index-atom $mat-row4 4) (index-atom $vec-row0 4)) (* (index-atom $mat-row4 5) (index-atom $vec-row0 5)) (* (index-atom $mat-row4 6) (index-atom $vec-row0 6)) (* (index-atom $mat-row4 7) (index-atom $vec-row0 7))))))) Empty)
                        (if (>= (- $mat-rows 6) 0) (let $mat-row5 (index-atom $matrice 5) (sum (collapse(superpose((* (index-atom $mat-row5 0) (index-atom $vec-row0 0)) (* (index-atom $mat-row5 1) (index-atom $vec-row0 1)) (* (index-atom $mat-row5 2) (index-atom $vec-row0 2)) (* (index-atom $mat-row5 3) (index-atom $vec-row0 3)) (* (index-atom $mat-row5 4) (index-atom $vec-row0 4)) (* (index-atom $mat-row5 5) (index-atom $vec-row0 5)) (* (index-atom $mat-row5 6) (index-atom $vec-row0 6)) (* (index-atom $mat-row5 7) (index-atom $vec-row0 7))))))) Empty)
                        (if (>= (- $mat-rows 7) 0) (let $mat-row6 (index-atom $matrice 6) (sum (collapse(superpose((* (index-atom $mat-row6 0) (index-atom $vec-row0 0)) (* (index-atom $mat-row6 1) (index-atom $vec-row0 1)) (* (index-atom $mat-row6 2) (index-atom $vec-row0 2)) (* (index-atom $mat-row6 3) (index-atom $vec-row0 3)) (* (index-atom $mat-row6 4) (index-atom $vec-row0 4)) (* (index-atom $mat-row6 5) (index-atom $vec-row0 5)) (* (index-atom $mat-row6 6) (index-atom $vec-row0 6)) (* (index-atom $mat-row6 7) (index-atom $vec-row0 7))))))) Empty)
                        (if (>= (- $mat-rows 8) 0) (let $mat-row7 (index-atom $matrice 7) (sum (collapse(superpose((* (index-atom $mat-row7 0) (index-atom $vec-row0 0)) (* (index-atom $mat-row7 1) (index-atom $vec-row0 1)) (* (index-atom $mat-row7 2) (index-atom $vec-row0 2)) (* (index-atom $mat-row7 3) (index-atom $vec-row0 3)) (* (index-atom $mat-row7 4) (index-atom $vec-row0 4)) (* (index-atom $mat-row7 5) (index-atom $vec-row0 5)) (* (index-atom $mat-row7 6) (index-atom $vec-row0 6)) (* (index-atom $mat-row7 7) (index-atom $vec-row0 7))))))) Empty))))
                        )
                        Empty)
                        (if (>= (- $lambda_ 2) 0)
                        (let $vec-row1 (index-atom $vector 1)
                        (collapse(superpose(
                        (if (>= (- $mat-rows 1) 0) (let $mat-row0 (index-atom $matrice 0) (sum (collapse(superpose((* (index-atom $mat-row0 0) (index-atom $vec-row1 0)) (* (index-atom $mat-row0 1) (index-atom $vec-row1 1)) (* (index-atom $mat-row0 2) (index-atom $vec-row1 2)) (* (index-atom $mat-row0 3) (index-atom $vec-row1 3)) (* (index-atom $mat-row0 4) (index-atom $vec-row1 4)) (* (index-atom $mat-row0 5) (index-atom $vec-row1 5)) (* (index-atom $mat-row0 6) (index-atom $vec-row1 6)) (* (index-atom $mat-row0 7) (index-atom $vec-row1 7))))))) Empty)
                        (if (>= (- $mat-rows 2) 0) (let $mat-row1 (index-atom $matrice 1) (sum (collapse(superpose((* (index-atom $mat-row1 0) (index-atom $vec-row1 0)) (* (index-atom $mat-row1 1) (index-atom $vec-row1 1)) (* (index-atom $mat-row1 2) (index-atom $vec-row1 2)) (* (index-atom $mat-row1 3) (index-atom $vec-row1 3)) (* (index-atom $mat-row1 4) (index-atom $vec-row1 4)) (* (index-atom $mat-row1 5) (index-atom $vec-row1 5)) (* (index-atom $mat-row1 6) (index-atom $vec-row1 6)) (* (index-atom $mat-row1 7) (index-atom $vec-row1 7))))))) Empty)
                        (if (>= (- $mat-rows 3) 0) (let $mat-row2 (index-atom $matrice 2) (sum (collapse(superpose((* (index-atom $mat-row2 0) (index-atom $vec-row1 0)) (* (index-atom $mat-row2 1) (index-atom $vec-row1 1)) (* (index-atom $mat-row2 2) (index-atom $vec-row1 2)) (* (index-atom $mat-row2 3) (index-atom $vec-row1 3)) (* (index-atom $mat-row2 4) (index-atom $vec-row1 4)) (* (index-atom $mat-row2 5) (index-atom $vec-row1 5)) (* (index-atom $mat-row2 6) (index-atom $vec-row1 6)) (* (index-atom $mat-row2 7) (index-atom $vec-row1 7))))))) Empty)
                        (if (>= (- $mat-rows 4) 0) (let $mat-row3 (index-atom $matrice 3) (sum (collapse(superpose((* (index-atom $mat-row3 0) (index-atom $vec-row1 0)) (* (index-atom $mat-row3 1) (index-atom $vec-row1 1)) (* (index-atom $mat-row3 2) (index-atom $vec-row1 2)) (* (index-atom $mat-row3 3) (index-atom $vec-row1 3)) (* (index-atom $mat-row3 4) (index-atom $vec-row1 4)) (* (index-atom $mat-row3 5) (index-atom $vec-row1 5)) (* (index-atom $mat-row3 6) (index-atom $vec-row1 6)) (* (index-atom $mat-row3 7) (index-atom $vec-row1 7))))))) Empty)
                        (if (>= (- $mat-rows 5) 0) (let $mat-row4 (index-atom $matrice 4) (sum (collapse(superpose((* (index-atom $mat-row4 0) (index-atom $vec-row1 0)) (* (index-atom $mat-row4 1) (index-atom $vec-row1 1)) (* (index-atom $mat-row4 2) (index-atom $vec-row1 2)) (* (index-atom $mat-row4 3) (index-atom $vec-row1 3)) (* (index-atom $mat-row4 4) (index-atom $vec-row1 4)) (* (index-atom $mat-row4 5) (index-atom $vec-row1 5)) (* (index-atom $mat-row4 6) (index-atom $vec-row1 6)) (* (index-atom $mat-row4 7) (index-atom $vec-row1 7))))))) Empty)
                        (if (>= (- $mat-rows 6) 0) (let $mat-row5 (index-atom $matrice 5) (sum (collapse(superpose((* (index-atom $mat-row5 0) (index-atom $vec-row1 0)) (* (index-atom $mat-row5 1) (index-atom $vec-row1 1)) (* (index-atom $mat-row5 2) (index-atom $vec-row1 2)) (* (index-atom $mat-row5 3) (index-atom $vec-row1 3)) (* (index-atom $mat-row5 4) (index-atom $vec-row1 4)) (* (index-atom $mat-row5 5) (index-atom $vec-row1 5)) (* (index-atom $mat-row5 6) (index-atom $vec-row1 6)) (* (index-atom $mat-row5 7) (index-atom $vec-row1 7))))))) Empty)
                        (if (>= (- $mat-rows 7) 0) (let $mat-row6 (index-atom $matrice 6) (sum (collapse(superpose((* (index-atom $mat-row6 0) (index-atom $vec-row1 0)) (* (index-atom $mat-row6 1) (index-atom $vec-row1 1)) (* (index-atom $mat-row6 2) (index-atom $vec-row1 2)) (* (index-atom $mat-row6 3) (index-atom $vec-row1 3)) (* (index-atom $mat-row6 4) (index-atom $vec-row1 4)) (* (index-atom $mat-row6 5) (index-atom $vec-row1 5)) (* (index-atom $mat-row6 6) (index-atom $vec-row1 6)) (* (index-atom $mat-row6 7) (index-atom $vec-row1 7))))))) Empty)
                        (if (>= (- $mat-rows 8) 0) (let $mat-row7 (index-atom $matrice 7) (sum (collapse(superpose((* (index-atom $mat-row7 0) (index-atom $vec-row1 0)) (* (index-atom $mat-row7 1) (index-atom $vec-row1 1)) (* (index-atom $mat-row7 2) (index-atom $vec-row1 2)) (* (index-atom $mat-row7 3) (index-atom $vec-row1 3)) (* (index-atom $mat-row7 4) (index-atom $vec-row1 4)) (* (index-atom $mat-row7 5) (index-atom $vec-row1 5)) (* (index-atom $mat-row7 6) (index-atom $vec-row1 6)) (* (index-atom $mat-row7 7) (index-atom $vec-row1 7))))))) Empty))))
                        )
                        Empty)
                        (if (>= (- $lambda_ 3) 0)
                        (let $vec-row2 (index-atom $vector 2)
                        (collapse(superpose(
                        (if (>= (- $mat-rows 1) 0) (let $mat-row0 (index-atom $matrice 0) (sum (collapse(superpose((* (index-atom $mat-row0 0) (index-atom $vec-row2 0)) (* (index-atom $mat-row0 1) (index-atom $vec-row2 1)) (* (index-atom $mat-row0 2) (index-atom $vec-row2 2)) (* (index-atom $mat-row0 3) (index-atom $vec-row2 3)) (* (index-atom $mat-row0 4) (index-atom $vec-row2 4)) (* (index-atom $mat-row0 5) (index-atom $vec-row2 5)) (* (index-atom $mat-row0 6) (index-atom $vec-row2 6)) (* (index-atom $mat-row0 7) (index-atom $vec-row2 7))))))) Empty)
                        (if (>= (- $mat-rows 2) 0) (let $mat-row1 (index-atom $matrice 1) (sum (collapse(superpose((* (index-atom $mat-row1 0) (index-atom $vec-row2 0)) (* (index-atom $mat-row1 1) (index-atom $vec-row2 1)) (* (index-atom $mat-row1 2) (index-atom $vec-row2 2)) (* (index-atom $mat-row1 3) (index-atom $vec-row2 3)) (* (index-atom $mat-row1 4) (index-atom $vec-row2 4)) (* (index-atom $mat-row1 5) (index-atom $vec-row2 5)) (* (index-atom $mat-row1 6) (index-atom $vec-row2 6)) (* (index-atom $mat-row1 7) (index-atom $vec-row2 7))))))) Empty)
                        (if (>= (- $mat-rows 3) 0) (let $mat-row2 (index-atom $matrice 2) (sum (collapse(superpose((* (index-atom $mat-row2 0) (index-atom $vec-row2 0)) (* (index-atom $mat-row2 1) (index-atom $vec-row2 1)) (* (index-atom $mat-row2 2) (index-atom $vec-row2 2)) (* (index-atom $mat-row2 3) (index-atom $vec-row2 3)) (* (index-atom $mat-row2 4) (index-atom $vec-row2 4)) (* (index-atom $mat-row2 5) (index-atom $vec-row2 5)) (* (index-atom $mat-row2 6) (index-atom $vec-row2 6)) (* (index-atom $mat-row2 7) (index-atom $vec-row2 7))))))) Empty)
                        (if (>= (- $mat-rows 4) 0) (let $mat-row3 (index-atom $matrice 3) (sum (collapse(superpose((* (index-atom $mat-row3 0) (index-atom $vec-row2 0)) (* (index-atom $mat-row3 1) (index-atom $vec-row2 1)) (* (index-atom $mat-row3 2) (index-atom $vec-row2 2)) (* (index-atom $mat-row3 3) (index-atom $vec-row2 3)) (* (index-atom $mat-row3 4) (index-atom $vec-row2 4)) (* (index-atom $mat-row3 5) (index-atom $vec-row2 5)) (* (index-atom $mat-row3 6) (index-atom $vec-row2 6)) (* (index-atom $mat-row3 7) (index-atom $vec-row2 7))))))) Empty)
                        (if (>= (- $mat-rows 5) 0) (let $mat-row4 (index-atom $matrice 4) (sum (collapse(superpose((* (index-atom $mat-row4 0) (index-atom $vec-row2 0)) (* (index-atom $mat-row4 1) (index-atom $vec-row2 1)) (* (index-atom $mat-row4 2) (index-atom $vec-row2 2)) (* (index-atom $mat-row4 3) (index-atom $vec-row2 3)) (* (index-atom $mat-row4 4) (index-atom $vec-row2 4)) (* (index-atom $mat-row4 5) (index-atom $vec-row2 5)) (* (index-atom $mat-row4 6) (index-atom $vec-row2 6)) (* (index-atom $mat-row4 7) (index-atom $vec-row2 7))))))) Empty)
                        (if (>= (- $mat-rows 6) 0) (let $mat-row5 (index-atom $matrice 5) (sum (collapse(superpose((* (index-atom $mat-row5 0) (index-atom $vec-row2 0)) (* (index-atom $mat-row5 1) (index-atom $vec-row2 1)) (* (index-atom $mat-row5 2) (index-atom $vec-row2 2)) (* (index-atom $mat-row5 3) (index-atom $vec-row2 3)) (* (index-atom $mat-row5 4) (index-atom $vec-row2 4)) (* (index-atom $mat-row5 5) (index-atom $vec-row2 5)) (* (index-atom $mat-row5 6) (index-atom $vec-row2 6)) (* (index-atom $mat-row5 7) (index-atom $vec-row2 7))))))) Empty)
                        (if (>= (- $mat-rows 7) 0) (let $mat-row6 (index-atom $matrice 6) (sum (collapse(superpose((* (index-atom $mat-row6 0) (index-atom $vec-row2 0)) (* (index-atom $mat-row6 1) (index-atom $vec-row2 1)) (* (index-atom $mat-row6 2) (index-atom $vec-row2 2)) (* (index-atom $mat-row6 3) (index-atom $vec-row2 3)) (* (index-atom $mat-row6 4) (index-atom $vec-row2 4)) (* (index-atom $mat-row6 5) (index-atom $vec-row2 5)) (* (index-atom $mat-row6 6) (index-atom $vec-row2 6)) (* (index-atom $mat-row6 7) (index-atom $vec-row2 7))))))) Empty)
                        (if (>= (- $mat-rows 8) 0) (let $mat-row7 (index-atom $matrice 7) (sum (collapse(superpose((* (index-atom $mat-row7 0) (index-atom $vec-row2 0)) (* (index-atom $mat-row7 1) (index-atom $vec-row2 1)) (* (index-atom $mat-row7 2) (index-atom $vec-row2 2)) (* (index-atom $mat-row7 3) (index-atom $vec-row2 3)) (* (index-atom $mat-row7 4) (index-atom $vec-row2 4)) (* (index-atom $mat-row7 5) (index-atom $vec-row2 5)) (* (index-atom $mat-row7 6) (index-atom $vec-row2 6)) (* (index-atom $mat-row7 7) (index-atom $vec-row2 7))))))) Empty))))
                        )
                        Empty)
                        (if (>= (- $lambda_ 4) 0)
                        (let $vec-row3 (index-atom $vector 3)
                        (collapse(superpose(
                        (if (>= (- $mat-rows 1) 0) (let $mat-row0 (index-atom $matrice 0) (sum (collapse(superpose((* (index-atom $mat-row0 0) (index-atom $vec-row3 0)) (* (index-atom $mat-row0 1) (index-atom $vec-row3 1)) (* (index-atom $mat-row0 2) (index-atom $vec-row3 2)) (* (index-atom $mat-row0 3) (index-atom $vec-row3 3)) (* (index-atom $mat-row0 4) (index-atom $vec-row3 4)) (* (index-atom $mat-row0 5) (index-atom $vec-row3 5)) (* (index-atom $mat-row0 6) (index-atom $vec-row3 6)) (* (index-atom $mat-row0 7) (index-atom $vec-row3 7))))))) Empty)
                        (if (>= (- $mat-rows 2) 0) (let $mat-row1 (index-atom $matrice 1) (sum (collapse(superpose((* (index-atom $mat-row1 0) (index-atom $vec-row3 0)) (* (index-atom $mat-row1 1) (index-atom $vec-row3 1)) (* (index-atom $mat-row1 2) (index-atom $vec-row3 2)) (* (index-atom $mat-row1 3) (index-atom $vec-row3 3)) (* (index-atom $mat-row1 4) (index-atom $vec-row3 4)) (* (index-atom $mat-row1 5) (index-atom $vec-row3 5)) (* (index-atom $mat-row1 6) (index-atom $vec-row3 6)) (* (index-atom $mat-row1 7) (index-atom $vec-row3 7))))))) Empty)
                        (if (>= (- $mat-rows 3) 0) (let $mat-row2 (index-atom $matrice 2) (sum (collapse(superpose((* (index-atom $mat-row2 0) (index-atom $vec-row3 0)) (* (index-atom $mat-row2 1) (index-atom $vec-row3 1)) (* (index-atom $mat-row2 2) (index-atom $vec-row3 2)) (* (index-atom $mat-row2 3) (index-atom $vec-row3 3)) (* (index-atom $mat-row2 4) (index-atom $vec-row3 4)) (* (index-atom $mat-row2 5) (index-atom $vec-row3 5)) (* (index-atom $mat-row2 6) (index-atom $vec-row3 6)) (* (index-atom $mat-row2 7) (index-atom $vec-row3 7))))))) Empty)
                        (if (>= (- $mat-rows 4) 0) (let $mat-row3 (index-atom $matrice 3) (sum (collapse(superpose((* (index-atom $mat-row3 0) (index-atom $vec-row3 0)) (* (index-atom $mat-row3 1) (index-atom $vec-row3 1)) (* (index-atom $mat-row3 2) (index-atom $vec-row3 2)) (* (index-atom $mat-row3 3) (index-atom $vec-row3 3)) (* (index-atom $mat-row3 4) (index-atom $vec-row3 4)) (* (index-atom $mat-row3 5) (index-atom $vec-row3 5)) (* (index-atom $mat-row3 6) (index-atom $vec-row3 6)) (* (index-atom $mat-row3 7) (index-atom $vec-row3 7))))))) Empty)
                        (if (>= (- $mat-rows 5) 0) (let $mat-row4 (index-atom $matrice 4) (sum (collapse(superpose((* (index-atom $mat-row4 0) (index-atom $vec-row3 0)) (* (index-atom $mat-row4 1) (index-atom $vec-row3 1)) (* (index-atom $mat-row4 2) (index-atom $vec-row3 2)) (* (index-atom $mat-row4 3) (index-atom $vec-row3 3)) (* (index-atom $mat-row4 4) (index-atom $vec-row3 4)) (* (index-atom $mat-row4 5) (index-atom $vec-row3 5)) (* (index-atom $mat-row4 6) (index-atom $vec-row3 6)) (* (index-atom $mat-row4 7) (index-atom $vec-row3 7))))))) Empty)
                        (if (>= (- $mat-rows 6) 0) (let $mat-row5 (index-atom $matrice 5) (sum (collapse(superpose((* (index-atom $mat-row5 0) (index-atom $vec-row3 0)) (* (index-atom $mat-row5 1) (index-atom $vec-row3 1)) (* (index-atom $mat-row5 2) (index-atom $vec-row3 2)) (* (index-atom $mat-row5 3) (index-atom $vec-row3 3)) (* (index-atom $mat-row5 4) (index-atom $vec-row3 4)) (* (index-atom $mat-row5 5) (index-atom $vec-row3 5)) (* (index-atom $mat-row5 6) (index-atom $vec-row3 6)) (* (index-atom $mat-row5 7) (index-atom $vec-row3 7))))))) Empty)
                        (if (>= (- $mat-rows 7) 0) (let $mat-row6 (index-atom $matrice 6) (sum (collapse(superpose((* (index-atom $mat-row6 0) (index-atom $vec-row3 0)) (* (index-atom $mat-row6 1) (index-atom $vec-row3 1)) (* (index-atom $mat-row6 2) (index-atom $vec-row3 2)) (* (index-atom $mat-row6 3) (index-atom $vec-row3 3)) (* (index-atom $mat-row6 4) (index-atom $vec-row3 4)) (* (index-atom $mat-row6 5) (index-atom $vec-row3 5)) (* (index-atom $mat-row6 6) (index-atom $vec-row3 6)) (* (index-atom $mat-row6 7) (index-atom $vec-row3 7))))))) Empty)
                        (if (>= (- $mat-rows 8) 0) (let $mat-row7 (index-atom $matrice 7) (sum (collapse(superpose((* (index-atom $mat-row7 0) (index-atom $vec-row3 0)) (* (index-atom $mat-row7 1) (index-atom $vec-row3 1)) (* (index-atom $mat-row7 2) (index-atom $vec-row3 2)) (* (index-atom $mat-row7 3) (index-atom $vec-row3 3)) (* (index-atom $mat-row7 4) (index-atom $vec-row3 4)) (* (index-atom $mat-row7 5) (index-atom $vec-row3 5)) (* (index-atom $mat-row7 6) (index-atom $vec-row3 6)) (* (index-atom $mat-row7 7) (index-atom $vec-row3 7))))))) Empty))))
                        )
                        Empty)
                        (if (>= (- $lambda_ 5) 0)
                        (let $vec-row4 (index-atom $vector 4)
                        (collapse(superpose(
                        (if (>= (- $mat-rows 1) 0) (let $mat-row0 (index-atom $matrice 0) (sum (collapse(superpose((* (index-atom $mat-row0 0) (index-atom $vec-row4 0)) (* (index-atom $mat-row0 1) (index-atom $vec-row4 1)) (* (index-atom $mat-row0 2) (index-atom $vec-row4 2)) (* (index-atom $mat-row0 3) (index-atom $vec-row4 3)) (* (index-atom $mat-row0 4) (index-atom $vec-row4 4)) (* (index-atom $mat-row0 5) (index-atom $vec-row4 5)) (* (index-atom $mat-row0 6) (index-atom $vec-row4 6)) (* (index-atom $mat-row0 7) (index-atom $vec-row4 7))))))) Empty)
                        (if (>= (- $mat-rows 2) 0) (let $mat-row1 (index-atom $matrice 1) (sum (collapse(superpose((* (index-atom $mat-row1 0) (index-atom $vec-row4 0)) (* (index-atom $mat-row1 1) (index-atom $vec-row4 1)) (* (index-atom $mat-row1 2) (index-atom $vec-row4 2)) (* (index-atom $mat-row1 3) (index-atom $vec-row4 3)) (* (index-atom $mat-row1 4) (index-atom $vec-row4 4)) (* (index-atom $mat-row1 5) (index-atom $vec-row4 5)) (* (index-atom $mat-row1 6) (index-atom $vec-row4 6)) (* (index-atom $mat-row1 7) (index-atom $vec-row4 7))))))) Empty)
                        (if (>= (- $mat-rows 3) 0) (let $mat-row2 (index-atom $matrice 2) (sum (collapse(superpose((* (index-atom $mat-row2 0) (index-atom $vec-row4 0)) (* (index-atom $mat-row2 1) (index-atom $vec-row4 1)) (* (index-atom $mat-row2 2) (index-atom $vec-row4 2)) (* (index-atom $mat-row2 3) (index-atom $vec-row4 3)) (* (index-atom $mat-row2 4) (index-atom $vec-row4 4)) (* (index-atom $mat-row2 5) (index-atom $vec-row4 5)) (* (index-atom $mat-row2 6) (index-atom $vec-row4 6)) (* (index-atom $mat-row2 7) (index-atom $vec-row4 7))))))) Empty)
                        (if (>= (- $mat-rows 4) 0) (let $mat-row3 (index-atom $matrice 3) (sum (collapse(superpose((* (index-atom $mat-row3 0) (index-atom $vec-row4 0)) (* (index-atom $mat-row3 1) (index-atom $vec-row4 1)) (* (index-atom $mat-row3 2) (index-atom $vec-row4 2)) (* (index-atom $mat-row3 3) (index-atom $vec-row4 3)) (* (index-atom $mat-row3 4) (index-atom $vec-row4 4)) (* (index-atom $mat-row3 5) (index-atom $vec-row4 5)) (* (index-atom $mat-row3 6) (index-atom $vec-row4 6)) (* (index-atom $mat-row3 7) (index-atom $vec-row4 7))))))) Empty)
                        (if (>= (- $mat-rows 5) 0) (let $mat-row4 (index-atom $matrice 4) (sum (collapse(superpose((* (index-atom $mat-row4 0) (index-atom $vec-row4 0)) (* (index-atom $mat-row4 1) (index-atom $vec-row4 1)) (* (index-atom $mat-row4 2) (index-atom $vec-row4 2)) (* (index-atom $mat-row4 3) (index-atom $vec-row4 3)) (* (index-atom $mat-row4 4) (index-atom $vec-row4 4)) (* (index-atom $mat-row4 5) (index-atom $vec-row4 5)) (* (index-atom $mat-row4 6) (index-atom $vec-row4 6)) (* (index-atom $mat-row4 7) (index-atom $vec-row4 7))))))) Empty)
                        (if (>= (- $mat-rows 6) 0) (let $mat-row5 (index-atom $matrice 5) (sum (collapse(superpose((* (index-atom $mat-row5 0) (index-atom $vec-row4 0)) (* (index-atom $mat-row5 1) (index-atom $vec-row4 1)) (* (index-atom $mat-row5 2) (index-atom $vec-row4 2)) (* (index-atom $mat-row5 3) (index-atom $vec-row4 3)) (* (index-atom $mat-row5 4) (index-atom $vec-row4 4)) (* (index-atom $mat-row5 5) (index-atom $vec-row4 5)) (* (index-atom $mat-row5 6) (index-atom $vec-row4 6)) (* (index-atom $mat-row5 7) (index-atom $vec-row4 7))))))) Empty)
                        (if (>= (- $mat-rows 7) 0) (let $mat-row6 (index-atom $matrice 6) (sum (collapse(superpose((* (index-atom $mat-row6 0) (index-atom $vec-row4 0)) (* (index-atom $mat-row6 1) (index-atom $vec-row4 1)) (* (index-atom $mat-row6 2) (index-atom $vec-row4 2)) (* (index-atom $mat-row6 3) (index-atom $vec-row4 3)) (* (index-atom $mat-row6 4) (index-atom $vec-row4 4)) (* (index-atom $mat-row6 5) (index-atom $vec-row4 5)) (* (index-atom $mat-row6 6) (index-atom $vec-row4 6)) (* (index-atom $mat-row6 7) (index-atom $vec-row4 7))))))) Empty)
                        (if (>= (- $mat-rows 8) 0) (let $mat-row7 (index-atom $matrice 7) (sum (collapse(superpose((* (index-atom $mat-row7 0) (index-atom $vec-row4 0)) (* (index-atom $mat-row7 1) (index-atom $vec-row4 1)) (* (index-atom $mat-row7 2) (index-atom $vec-row4 2)) (* (index-atom $mat-row7 3) (index-atom $vec-row4 3)) (* (index-atom $mat-row7 4) (index-atom $vec-row4 4)) (* (index-atom $mat-row7 5) (index-atom $vec-row4 5)) (* (index-atom $mat-row7 6) (index-atom $vec-row4 6)) (* (index-atom $mat-row7 7) (index-atom $vec-row4 7))))))) Empty))))
                        )
                        Empty)
                        (if (>= (- $lambda_ 6) 0)
                        (let $vec-row5 (index-atom $vector 5)
                        (collapse(superpose(
                        (if (>= (- $mat-rows 1) 0) (let $mat-row0 (index-atom $matrice 0) (sum (collapse(superpose((* (index-atom $mat-row0 0) (index-atom $vec-row5 0)) (* (index-atom $mat-row0 1) (index-atom $vec-row5 1)) (* (index-atom $mat-row0 2) (index-atom $vec-row5 2)) (* (index-atom $mat-row0 3) (index-atom $vec-row5 3)) (* (index-atom $mat-row0 4) (index-atom $vec-row5 4)) (* (index-atom $mat-row0 5) (index-atom $vec-row5 5)) (* (index-atom $mat-row0 6) (index-atom $vec-row5 6)) (* (index-atom $mat-row0 7) (index-atom $vec-row5 7))))))) Empty)
                        (if (>= (- $mat-rows 2) 0) (let $mat-row1 (index-atom $matrice 1) (sum (collapse(superpose((* (index-atom $mat-row1 0) (index-atom $vec-row5 0)) (* (index-atom $mat-row1 1) (index-atom $vec-row5 1)) (* (index-atom $mat-row1 2) (index-atom $vec-row5 2)) (* (index-atom $mat-row1 3) (index-atom $vec-row5 3)) (* (index-atom $mat-row1 4) (index-atom $vec-row5 4)) (* (index-atom $mat-row1 5) (index-atom $vec-row5 5)) (* (index-atom $mat-row1 6) (index-atom $vec-row5 6)) (* (index-atom $mat-row1 7) (index-atom $vec-row5 7))))))) Empty)
                        (if (>= (- $mat-rows 3) 0) (let $mat-row2 (index-atom $matrice 2) (sum (collapse(superpose((* (index-atom $mat-row2 0) (index-atom $vec-row5 0)) (* (index-atom $mat-row2 1) (index-atom $vec-row5 1)) (* (index-atom $mat-row2 2) (index-atom $vec-row5 2)) (* (index-atom $mat-row2 3) (index-atom $vec-row5 3)) (* (index-atom $mat-row2 4) (index-atom $vec-row5 4)) (* (index-atom $mat-row2 5) (index-atom $vec-row5 5)) (* (index-atom $mat-row2 6) (index-atom $vec-row5 6)) (* (index-atom $mat-row2 7) (index-atom $vec-row5 7))))))) Empty)
                        (if (>= (- $mat-rows 4) 0) (let $mat-row3 (index-atom $matrice 3) (sum (collapse(superpose((* (index-atom $mat-row3 0) (index-atom $vec-row5 0)) (* (index-atom $mat-row3 1) (index-atom $vec-row5 1)) (* (index-atom $mat-row3 2) (index-atom $vec-row5 2)) (* (index-atom $mat-row3 3) (index-atom $vec-row5 3)) (* (index-atom $mat-row3 4) (index-atom $vec-row5 4)) (* (index-atom $mat-row3 5) (index-atom $vec-row5 5)) (* (index-atom $mat-row3 6) (index-atom $vec-row5 6)) (* (index-atom $mat-row3 7) (index-atom $vec-row5 7))))))) Empty)
                        (if (>= (- $mat-rows 5) 0) (let $mat-row4 (index-atom $matrice 4) (sum (collapse(superpose((* (index-atom $mat-row4 0) (index-atom $vec-row5 0)) (* (index-atom $mat-row4 1) (index-atom $vec-row5 1)) (* (index-atom $mat-row4 2) (index-atom $vec-row5 2)) (* (index-atom $mat-row4 3) (index-atom $vec-row5 3)) (* (index-atom $mat-row4 4) (index-atom $vec-row5 4)) (* (index-atom $mat-row4 5) (index-atom $vec-row5 5)) (* (index-atom $mat-row4 6) (index-atom $vec-row5 6)) (* (index-atom $mat-row4 7) (index-atom $vec-row5 7))))))) Empty)
                        (if (>= (- $mat-rows 6) 0) (let $mat-row5 (index-atom $matrice 5) (sum (collapse(superpose((* (index-atom $mat-row5 0) (index-atom $vec-row5 0)) (* (index-atom $mat-row5 1) (index-atom $vec-row5 1)) (* (index-atom $mat-row5 2) (index-atom $vec-row5 2)) (* (index-atom $mat-row5 3) (index-atom $vec-row5 3)) (* (index-atom $mat-row5 4) (index-atom $vec-row5 4)) (* (index-atom $mat-row5 5) (index-atom $vec-row5 5)) (* (index-atom $mat-row5 6) (index-atom $vec-row5 6)) (* (index-atom $mat-row5 7) (index-atom $vec-row5 7))))))) Empty)
                        (if (>= (- $mat-rows 7) 0) (let $mat-row6 (index-atom $matrice 6) (sum (collapse(superpose((* (index-atom $mat-row6 0) (index-atom $vec-row5 0)) (* (index-atom $mat-row6 1) (index-atom $vec-row5 1)) (* (index-atom $mat-row6 2) (index-atom $vec-row5 2)) (* (index-atom $mat-row6 3) (index-atom $vec-row5 3)) (* (index-atom $mat-row6 4) (index-atom $vec-row5 4)) (* (index-atom $mat-row6 5) (index-atom $vec-row5 5)) (* (index-atom $mat-row6 6) (index-atom $vec-row5 6)) (* (index-atom $mat-row6 7) (index-atom $vec-row5 7))))))) Empty)
                        (if (>= (- $mat-rows 8) 0) (let $mat-row7 (index-atom $matrice 7) (sum (collapse(superpose((* (index-atom $mat-row7 0) (index-atom $vec-row5 0)) (* (index-atom $mat-row7 1) (index-atom $vec-row5 1)) (* (index-atom $mat-row7 2) (index-atom $vec-row5 2)) (* (index-atom $mat-row7 3) (index-atom $vec-row5 3)) (* (index-atom $mat-row7 4) (index-atom $vec-row5 4)) (* (index-atom $mat-row7 5) (index-atom $vec-row5 5)) (* (index-atom $mat-row7 6) (index-atom $vec-row5 6)) (* (index-atom $mat-row7 7) (index-atom $vec-row5 7))))))) Empty))))
                        )
                        Empty)
                        (if (>= (- $lambda_ 7) 0)
                        (let $vec-row6 (index-atom $vector 6)
                        (collapse(superpose(
                        (if (>= (- $mat-rows 1) 0) (let $mat-row0 (index-atom $matrice 0) (sum (collapse(superpose((* (index-atom $mat-row0 0) (index-atom $vec-row6 0)) (* (index-atom $mat-row0 1) (index-atom $vec-row6 1)) (* (index-atom $mat-row0 2) (index-atom $vec-row6 2)) (* (index-atom $mat-row0 3) (index-atom $vec-row6 3)) (* (index-atom $mat-row0 4) (index-atom $vec-row6 4)) (* (index-atom $mat-row0 5) (index-atom $vec-row6 5)) (* (index-atom $mat-row0 6) (index-atom $vec-row6 6)) (* (index-atom $mat-row0 7) (index-atom $vec-row6 7))))))) Empty)
                        (if (>= (- $mat-rows 2) 0) (let $mat-row1 (index-atom $matrice 1) (sum (collapse(superpose((* (index-atom $mat-row1 0) (index-atom $vec-row6 0)) (* (index-atom $mat-row1 1) (index-atom $vec-row6 1)) (* (index-atom $mat-row1 2) (index-atom $vec-row6 2)) (* (index-atom $mat-row1 3) (index-atom $vec-row6 3)) (* (index-atom $mat-row1 4) (index-atom $vec-row6 4)) (* (index-atom $mat-row1 5) (index-atom $vec-row6 5)) (* (index-atom $mat-row1 6) (index-atom $vec-row6 6)) (* (index-atom $mat-row1 7) (index-atom $vec-row6 7))))))) Empty)
                        (if (>= (- $mat-rows 3) 0) (let $mat-row2 (index-atom $matrice 2) (sum (collapse(superpose((* (index-atom $mat-row2 0) (index-atom $vec-row6 0)) (* (index-atom $mat-row2 1) (index-atom $vec-row6 1)) (* (index-atom $mat-row2 2) (index-atom $vec-row6 2)) (* (index-atom $mat-row2 3) (index-atom $vec-row6 3)) (* (index-atom $mat-row2 4) (index-atom $vec-row6 4)) (* (index-atom $mat-row2 5) (index-atom $vec-row6 5)) (* (index-atom $mat-row2 6) (index-atom $vec-row6 6)) (* (index-atom $mat-row2 7) (index-atom $vec-row6 7))))))) Empty)
                        (if (>= (- $mat-rows 4) 0) (let $mat-row3 (index-atom $matrice 3) (sum (collapse(superpose((* (index-atom $mat-row3 0) (index-atom $vec-row6 0)) (* (index-atom $mat-row3 1) (index-atom $vec-row6 1)) (* (index-atom $mat-row3 2) (index-atom $vec-row6 2)) (* (index-atom $mat-row3 3) (index-atom $vec-row6 3)) (* (index-atom $mat-row3 4) (index-atom $vec-row6 4)) (* (index-atom $mat-row3 5) (index-atom $vec-row6 5)) (* (index-atom $mat-row3 6) (index-atom $vec-row6 6)) (* (index-atom $mat-row3 7) (index-atom $vec-row6 7))))))) Empty)
                        (if (>= (- $mat-rows 5) 0) (let $mat-row4 (index-atom $matrice 4) (sum (collapse(superpose((* (index-atom $mat-row4 0) (index-atom $vec-row6 0)) (* (index-atom $mat-row4 1) (index-atom $vec-row6 1)) (* (index-atom $mat-row4 2) (index-atom $vec-row6 2)) (* (index-atom $mat-row4 3) (index-atom $vec-row6 3)) (* (index-atom $mat-row4 4) (index-atom $vec-row6 4)) (* (index-atom $mat-row4 5) (index-atom $vec-row6 5)) (* (index-atom $mat-row4 6) (index-atom $vec-row6 6)) (* (index-atom $mat-row4 7) (index-atom $vec-row6 7))))))) Empty)
                        (if (>= (- $mat-rows 6) 0) (let $mat-row5 (index-atom $matrice 5) (sum (collapse(superpose((* (index-atom $mat-row5 0) (index-atom $vec-row6 0)) (* (index-atom $mat-row5 1) (index-atom $vec-row6 1)) (* (index-atom $mat-row5 2) (index-atom $vec-row6 2)) (* (index-atom $mat-row5 3) (index-atom $vec-row6 3)) (* (index-atom $mat-row5 4) (index-atom $vec-row6 4)) (* (index-atom $mat-row5 5) (index-atom $vec-row6 5)) (* (index-atom $mat-row5 6) (index-atom $vec-row6 6)) (* (index-atom $mat-row5 7) (index-atom $vec-row6 7))))))) Empty)
                        (if (>= (- $mat-rows 7) 0) (let $mat-row6 (index-atom $matrice 6) (sum (collapse(superpose((* (index-atom $mat-row6 0) (index-atom $vec-row6 0)) (* (index-atom $mat-row6 1) (index-atom $vec-row6 1)) (* (index-atom $mat-row6 2) (index-atom $vec-row6 2)) (* (index-atom $mat-row6 3) (index-atom $vec-row6 3)) (* (index-atom $mat-row6 4) (index-atom $vec-row6 4)) (* (index-atom $mat-row6 5) (index-atom $vec-row6 5)) (* (index-atom $mat-row6 6) (index-atom $vec-row6 6)) (* (index-atom $mat-row6 7) (index-atom $vec-row6 7))))))) Empty)
                        (if (>= (- $mat-rows 8) 0) (let $mat-row7 (index-atom $matrice 7) (sum (collapse(superpose((* (index-atom $mat-row7 0) (index-atom $vec-row6 0)) (* (index-atom $mat-row7 1) (index-atom $vec-row6 1)) (* (index-atom $mat-row7 2) (index-atom $vec-row6 2)) (* (index-atom $mat-row7 3) (index-atom $vec-row6 3)) (* (index-atom $mat-row7 4) (index-atom $vec-row6 4)) (* (index-atom $mat-row7 5) (index-atom $vec-row6 5)) (* (index-atom $mat-row7 6) (index-atom $vec-row6 6)) (* (index-atom $mat-row7 7) (index-atom $vec-row6 7))))))) Empty))))
                        )
                        Empty)
                        (if (>= (- $lambda_ 8) 0)
                        (let $vec-row7 (index-atom $vector 7)
                        (collapse(superpose(
                        (if (>= (- $mat-rows 1) 0) (let $mat-row0 (index-atom $matrice 0) (sum (collapse(superpose((* (index-atom $mat-row0 0) (index-atom $vec-row7 0)) (* (index-atom $mat-row0 1) (index-atom $vec-row7 1)) (* (index-atom $mat-row0 2) (index-atom $vec-row7 2)) (* (index-atom $mat-row0 3) (index-atom $vec-row7 3)) (* (index-atom $mat-row0 4) (index-atom $vec-row7 4)) (* (index-atom $mat-row0 5) (index-atom $vec-row7 5)) (* (index-atom $mat-row0 6) (index-atom $vec-row7 6)) (* (index-atom $mat-row0 7) (index-atom $vec-row7 7))))))) Empty)
                        (if (>= (- $mat-rows 2) 0) (let $mat-row1 (index-atom $matrice 1) (sum (collapse(superpose((* (index-atom $mat-row1 0) (index-atom $vec-row7 0)) (* (index-atom $mat-row1 1) (index-atom $vec-row7 1)) (* (index-atom $mat-row1 2) (index-atom $vec-row7 2)) (* (index-atom $mat-row1 3) (index-atom $vec-row7 3)) (* (index-atom $mat-row1 4) (index-atom $vec-row7 4)) (* (index-atom $mat-row1 5) (index-atom $vec-row7 5)) (* (index-atom $mat-row1 6) (index-atom $vec-row7 6)) (* (index-atom $mat-row1 7) (index-atom $vec-row7 7))))))) Empty)
                        (if (>= (- $mat-rows 3) 0) (let $mat-row2 (index-atom $matrice 2) (sum (collapse(superpose((* (index-atom $mat-row2 0) (index-atom $vec-row7 0)) (* (index-atom $mat-row2 1) (index-atom $vec-row7 1)) (* (index-atom $mat-row2 2) (index-atom $vec-row7 2)) (* (index-atom $mat-row2 3) (index-atom $vec-row7 3)) (* (index-atom $mat-row2 4) (index-atom $vec-row7 4)) (* (index-atom $mat-row2 5) (index-atom $vec-row7 5)) (* (index-atom $mat-row2 6) (index-atom $vec-row7 6)) (* (index-atom $mat-row2 7) (index-atom $vec-row7 7))))))) Empty)
                        (if (>= (- $mat-rows 4) 0) (let $mat-row3 (index-atom $matrice 3) (sum (collapse(superpose((* (index-atom $mat-row3 0) (index-atom $vec-row7 0)) (* (index-atom $mat-row3 1) (index-atom $vec-row7 1)) (* (index-atom $mat-row3 2) (index-atom $vec-row7 2)) (* (index-atom $mat-row3 3) (index-atom $vec-row7 3)) (* (index-atom $mat-row3 4) (index-atom $vec-row7 4)) (* (index-atom $mat-row3 5) (index-atom $vec-row7 5)) (* (index-atom $mat-row3 6) (index-atom $vec-row7 6)) (* (index-atom $mat-row3 7) (index-atom $vec-row7 7))))))) Empty)
                        (if (>= (- $mat-rows 5) 0) (let $mat-row4 (index-atom $matrice 4) (sum (collapse(superpose((* (index-atom $mat-row4 0) (index-atom $vec-row7 0)) (* (index-atom $mat-row4 1) (index-atom $vec-row7 1)) (* (index-atom $mat-row4 2) (index-atom $vec-row7 2)) (* (index-atom $mat-row4 3) (index-atom $vec-row7 3)) (* (index-atom $mat-row4 4) (index-atom $vec-row7 4)) (* (index-atom $mat-row4 5) (index-atom $vec-row7 5)) (* (index-atom $mat-row4 6) (index-atom $vec-row7 6)) (* (index-atom $mat-row4 7) (index-atom $vec-row7 7))))))) Empty)
                        (if (>= (- $mat-rows 6) 0) (let $mat-row5 (index-atom $matrice 5) (sum (collapse(superpose((* (index-atom $mat-row5 0) (index-atom $vec-row7 0)) (* (index-atom $mat-row5 1) (index-atom $vec-row7 1)) (* (index-atom $mat-row5 2) (index-atom $vec-row7 2)) (* (index-atom $mat-row5 3) (index-atom $vec-row7 3)) (* (index-atom $mat-row5 4) (index-atom $vec-row7 4)) (* (index-atom $mat-row5 5) (index-atom $vec-row7 5)) (* (index-atom $mat-row5 6) (index-atom $vec-row7 6)) (* (index-atom $mat-row5 7) (index-atom $vec-row7 7))))))) Empty)
                        (if (>= (- $mat-rows 7) 0) (let $mat-row6 (index-atom $matrice 6) (sum (collapse(superpose((* (index-atom $mat-row6 0) (index-atom $vec-row7 0)) (* (index-atom $mat-row6 1) (index-atom $vec-row7 1)) (* (index-atom $mat-row6 2) (index-atom $vec-row7 2)) (* (index-atom $mat-row6 3) (index-atom $vec-row7 3)) (* (index-atom $mat-row6 4) (index-atom $vec-row7 4)) (* (index-atom $mat-row6 5) (index-atom $vec-row7 5)) (* (index-atom $mat-row6 6) (index-atom $vec-row7 6)) (* (index-atom $mat-row6 7) (index-atom $vec-row7 7))))))) Empty)
                        (if (>= (- $mat-rows 8) 0) (let $mat-row7 (index-atom $matrice 7) (sum (collapse(superpose((* (index-atom $mat-row7 0) (index-atom $vec-row7 0)) (* (index-atom $mat-row7 1) (index-atom $vec-row7 1)) (* (index-atom $mat-row7 2) (index-atom $vec-row7 2)) (* (index-atom $mat-row7 3) (index-atom $vec-row7 3)) (* (index-atom $mat-row7 4) (index-atom $vec-row7 4)) (* (index-atom $mat-row7 5) (index-atom $vec-row7 5)) (* (index-atom $mat-row7 6) (index-atom $vec-row7 6)) (* (index-atom $mat-row7 7) (index-atom $vec-row7 7))))))) Empty))))
                        )
                        Empty)
                        (if (>= (- $lambda_ 9) 0)
                        (let $vec-row8 (index-atom $vector 8)
                        (collapse(superpose(
                        (if (>= (- $mat-rows 1) 0) (let $mat-row0 (index-atom $matrice 0) (sum (collapse(superpose((* (index-atom $mat-row0 0) (index-atom $vec-row8 0)) (* (index-atom $mat-row0 1) (index-atom $vec-row8 1)) (* (index-atom $mat-row0 2) (index-atom $vec-row8 2)) (* (index-atom $mat-row0 3) (index-atom $vec-row8 3)) (* (index-atom $mat-row0 4) (index-atom $vec-row8 4)) (* (index-atom $mat-row0 5) (index-atom $vec-row8 5)) (* (index-atom $mat-row0 6) (index-atom $vec-row8 6)) (* (index-atom $mat-row0 7) (index-atom $vec-row8 7))))))) Empty)
                        (if (>= (- $mat-rows 2) 0) (let $mat-row1 (index-atom $matrice 1) (sum (collapse(superpose((* (index-atom $mat-row1 0) (index-atom $vec-row8 0)) (* (index-atom $mat-row1 1) (index-atom $vec-row8 1)) (* (index-atom $mat-row1 2) (index-atom $vec-row8 2)) (* (index-atom $mat-row1 3) (index-atom $vec-row8 3)) (* (index-atom $mat-row1 4) (index-atom $vec-row8 4)) (* (index-atom $mat-row1 5) (index-atom $vec-row8 5)) (* (index-atom $mat-row1 6) (index-atom $vec-row8 6)) (* (index-atom $mat-row1 7) (index-atom $vec-row8 7))))))) Empty)
                        (if (>= (- $mat-rows 3) 0) (let $mat-row2 (index-atom $matrice 2) (sum (collapse(superpose((* (index-atom $mat-row2 0) (index-atom $vec-row8 0)) (* (index-atom $mat-row2 1) (index-atom $vec-row8 1)) (* (index-atom $mat-row2 2) (index-atom $vec-row8 2)) (* (index-atom $mat-row2 3) (index-atom $vec-row8 3)) (* (index-atom $mat-row2 4) (index-atom $vec-row8 4)) (* (index-atom $mat-row2 5) (index-atom $vec-row8 5)) (* (index-atom $mat-row2 6) (index-atom $vec-row8 6)) (* (index-atom $mat-row2 7) (index-atom $vec-row8 7))))))) Empty)
                        (if (>= (- $mat-rows 4) 0) (let $mat-row3 (index-atom $matrice 3) (sum (collapse(superpose((* (index-atom $mat-row3 0) (index-atom $vec-row8 0)) (* (index-atom $mat-row3 1) (index-atom $vec-row8 1)) (* (index-atom $mat-row3 2) (index-atom $vec-row8 2)) (* (index-atom $mat-row3 3) (index-atom $vec-row8 3)) (* (index-atom $mat-row3 4) (index-atom $vec-row8 4)) (* (index-atom $mat-row3 5) (index-atom $vec-row8 5)) (* (index-atom $mat-row3 6) (index-atom $vec-row8 6)) (* (index-atom $mat-row3 7) (index-atom $vec-row8 7))))))) Empty)
                        (if (>= (- $mat-rows 5) 0) (let $mat-row4 (index-atom $matrice 4) (sum (collapse(superpose((* (index-atom $mat-row4 0) (index-atom $vec-row8 0)) (* (index-atom $mat-row4 1) (index-atom $vec-row8 1)) (* (index-atom $mat-row4 2) (index-atom $vec-row8 2)) (* (index-atom $mat-row4 3) (index-atom $vec-row8 3)) (* (index-atom $mat-row4 4) (index-atom $vec-row8 4)) (* (index-atom $mat-row4 5) (index-atom $vec-row8 5)) (* (index-atom $mat-row4 6) (index-atom $vec-row8 6)) (* (index-atom $mat-row4 7) (index-atom $vec-row8 7))))))) Empty)
                        (if (>= (- $mat-rows 6) 0) (let $mat-row5 (index-atom $matrice 5) (sum (collapse(superpose((* (index-atom $mat-row5 0) (index-atom $vec-row8 0)) (* (index-atom $mat-row5 1) (index-atom $vec-row8 1)) (* (index-atom $mat-row5 2) (index-atom $vec-row8 2)) (* (index-atom $mat-row5 3) (index-atom $vec-row8 3)) (* (index-atom $mat-row5 4) (index-atom $vec-row8 4)) (* (index-atom $mat-row5 5) (index-atom $vec-row8 5)) (* (index-atom $mat-row5 6) (index-atom $vec-row8 6)) (* (index-atom $mat-row5 7) (index-atom $vec-row8 7))))))) Empty)
                        (if (>= (- $mat-rows 7) 0) (let $mat-row6 (index-atom $matrice 6) (sum (collapse(superpose((* (index-atom $mat-row6 0) (index-atom $vec-row8 0)) (* (index-atom $mat-row6 1) (index-atom $vec-row8 1)) (* (index-atom $mat-row6 2) (index-atom $vec-row8 2)) (* (index-atom $mat-row6 3) (index-atom $vec-row8 3)) (* (index-atom $mat-row6 4) (index-atom $vec-row8 4)) (* (index-atom $mat-row6 5) (index-atom $vec-row8 5)) (* (index-atom $mat-row6 6) (index-atom $vec-row8 6)) (* (index-atom $mat-row6 7) (index-atom $vec-row8 7))))))) Empty)
                        (if (>= (- $mat-rows 8) 0) (let $mat-row7 (index-atom $matrice 7) (sum (collapse(superpose((* (index-atom $mat-row7 0) (index-atom $vec-row8 0)) (* (index-atom $mat-row7 1) (index-atom $vec-row8 1)) (* (index-atom $mat-row7 2) (index-atom $vec-row8 2)) (* (index-atom $mat-row7 3) (index-atom $vec-row8 3)) (* (index-atom $mat-row7 4) (index-atom $vec-row8 4)) (* (index-atom $mat-row7 5) (index-atom $vec-row8 5)) (* (index-atom $mat-row7 6) (index-atom $vec-row8 6)) (* (index-atom $mat-row7 7) (index-atom $vec-row8 7))))))) Empty))))
                        )
                        Empty)
                        (if (>= (- $lambda_ 10) 0)
                        (let $vec-row9 (index-atom $vector 9)
                        (collapse(superpose(
                        (if (>= (- $mat-rows 1) 0) (let $mat-row0 (index-atom $matrice 0) (sum (collapse(superpose((* (index-atom $mat-row0 0) (index-atom $vec-row9 0)) (* (index-atom $mat-row0 1) (index-atom $vec-row9 1)) (* (index-atom $mat-row0 2) (index-atom $vec-row9 2)) (* (index-atom $mat-row0 3) (index-atom $vec-row9 3)) (* (index-atom $mat-row0 4) (index-atom $vec-row9 4)) (* (index-atom $mat-row0 5) (index-atom $vec-row9 5)) (* (index-atom $mat-row0 6) (index-atom $vec-row9 6)) (* (index-atom $mat-row0 7) (index-atom $vec-row9 7))))))) Empty)
                        (if (>= (- $mat-rows 2) 0) (let $mat-row1 (index-atom $matrice 1) (sum (collapse(superpose((* (index-atom $mat-row1 0) (index-atom $vec-row9 0)) (* (index-atom $mat-row1 1) (index-atom $vec-row9 1)) (* (index-atom $mat-row1 2) (index-atom $vec-row9 2)) (* (index-atom $mat-row1 3) (index-atom $vec-row9 3)) (* (index-atom $mat-row1 4) (index-atom $vec-row9 4)) (* (index-atom $mat-row1 5) (index-atom $vec-row9 5)) (* (index-atom $mat-row1 6) (index-atom $vec-row9 6)) (* (index-atom $mat-row1 7) (index-atom $vec-row9 7))))))) Empty)
                        (if (>= (- $mat-rows 3) 0) (let $mat-row2 (index-atom $matrice 2) (sum (collapse(superpose((* (index-atom $mat-row2 0) (index-atom $vec-row9 0)) (* (index-atom $mat-row2 1) (index-atom $vec-row9 1)) (* (index-atom $mat-row2 2) (index-atom $vec-row9 2)) (* (index-atom $mat-row2 3) (index-atom $vec-row9 3)) (* (index-atom $mat-row2 4) (index-atom $vec-row9 4)) (* (index-atom $mat-row2 5) (index-atom $vec-row9 5)) (* (index-atom $mat-row2 6) (index-atom $vec-row9 6)) (* (index-atom $mat-row2 7) (index-atom $vec-row9 7))))))) Empty)
                        (if (>= (- $mat-rows 4) 0) (let $mat-row3 (index-atom $matrice 3) (sum (collapse(superpose((* (index-atom $mat-row3 0) (index-atom $vec-row9 0)) (* (index-atom $mat-row3 1) (index-atom $vec-row9 1)) (* (index-atom $mat-row3 2) (index-atom $vec-row9 2)) (* (index-atom $mat-row3 3) (index-atom $vec-row9 3)) (* (index-atom $mat-row3 4) (index-atom $vec-row9 4)) (* (index-atom $mat-row3 5) (index-atom $vec-row9 5)) (* (index-atom $mat-row3 6) (index-atom $vec-row9 6)) (* (index-atom $mat-row3 7) (index-atom $vec-row9 7))))))) Empty)
                        (if (>= (- $mat-rows 5) 0) (let $mat-row4 (index-atom $matrice 4) (sum (collapse(superpose((* (index-atom $mat-row4 0) (index-atom $vec-row9 0)) (* (index-atom $mat-row4 1) (index-atom $vec-row9 1)) (* (index-atom $mat-row4 2) (index-atom $vec-row9 2)) (* (index-atom $mat-row4 3) (index-atom $vec-row9 3)) (* (index-atom $mat-row4 4) (index-atom $vec-row9 4)) (* (index-atom $mat-row4 5) (index-atom $vec-row9 5)) (* (index-atom $mat-row4 6) (index-atom $vec-row9 6)) (* (index-atom $mat-row4 7) (index-atom $vec-row9 7))))))) Empty)
                        (if (>= (- $mat-rows 6) 0) (let $mat-row5 (index-atom $matrice 5) (sum (collapse(superpose((* (index-atom $mat-row5 0) (index-atom $vec-row9 0)) (* (index-atom $mat-row5 1) (index-atom $vec-row9 1)) (* (index-atom $mat-row5 2) (index-atom $vec-row9 2)) (* (index-atom $mat-row5 3) (index-atom $vec-row9 3)) (* (index-atom $mat-row5 4) (index-atom $vec-row9 4)) (* (index-atom $mat-row5 5) (index-atom $vec-row9 5)) (* (index-atom $mat-row5 6) (index-atom $vec-row9 6)) (* (index-atom $mat-row5 7) (index-atom $vec-row9 7))))))) Empty)
                        (if (>= (- $mat-rows 7) 0) (let $mat-row6 (index-atom $matrice 6) (sum (collapse(superpose((* (index-atom $mat-row6 0) (index-atom $vec-row9 0)) (* (index-atom $mat-row6 1) (index-atom $vec-row9 1)) (* (index-atom $mat-row6 2) (index-atom $vec-row9 2)) (* (index-atom $mat-row6 3) (index-atom $vec-row9 3)) (* (index-atom $mat-row6 4) (index-atom $vec-row9 4)) (* (index-atom $mat-row6 5) (index-atom $vec-row9 5)) (* (index-atom $mat-row6 6) (index-atom $vec-row9 6)) (* (index-atom $mat-row6 7) (index-atom $vec-row9 7))))))) Empty)
                        (if (>= (- $mat-rows 8) 0) (let $mat-row7 (index-atom $matrice 7) (sum (collapse(superpose((* (index-atom $mat-row7 0) (index-atom $vec-row9 0)) (* (index-atom $mat-row7 1) (index-atom $vec-row9 1)) (* (index-atom $mat-row7 2) (index-atom $vec-row9 2)) (* (index-atom $mat-row7 3) (index-atom $vec-row9 3)) (* (index-atom $mat-row7 4) (index-atom $vec-row9 4)) (* (index-atom $mat-row7 5) (index-atom $vec-row9 5)) (* (index-atom $mat-row7 6) (index-atom $vec-row9 6)) (* (index-atom $mat-row7 7) (index-atom $vec-row9 7))))))) Empty))))
                        )
                        Empty)
                    )
                )
            )
            (Error ($mat-dim $vec-dim) DimensionMismatch)
        )
    )
)
; (= (vector)(1 2 3 4 5 4 5 6))
; !(mat-vec-mul ((1.0 0 0 0.0 0.0 0.0 0.0 0.0) (0 1.0 0 0.0 0.0 0.0 0.0 0.0) (0 0 1.0 0.0 0.0 0.0 0.0 0.0) (0 0 0 1.0 0.0 0.0 0.0 0.0) (0 0 0 1.0 0.0 0.0 0.0 0.0) (0 0 0 1.0 0.0 0.0 0.0 0.0) (0 0 0 1.0 0.0 0.0 0.0 0.0)(0 0 0 1.0 0.0 0.0 0.0 0.0)) ((vector)))
; !(size-atom 2)
(= (random-multivariate $mean $cov-matrice $lambda_)
    (let ($decomp-cov-matrice $standard-normals) (collapse(superpose((chol-decomp $cov-matrice) (standard-normal (size-atom $mean) $lambda_))))
        (let $transformed-standard-normals (mat-vec-mul $decomp-cov-matrice $standard-normals)
            (collapse
                (superpose
                    (
                        (if (>= (- $lambda_ 1) 0)
                        (let $trans-stand-norm0 (index-atom $transformed-standard-normals 0)
                        (collapse(superpose(
                        (+ (index-atom $mean 0) (index-atom $trans-stand-norm0 0))
                        (+ (index-atom $mean 1) (index-atom $trans-stand-norm0 1))
                        (+ (index-atom $mean 2) (index-atom $trans-stand-norm0 2))
                        (+ (index-atom $mean 3) (index-atom $trans-stand-norm0 3))
                        (+ (index-atom $mean 4) (index-atom $trans-stand-norm0 4))
                        (+ (index-atom $mean 5) (index-atom $trans-stand-norm0 5))
                        (+ (index-atom $mean 6) (index-atom $trans-stand-norm0 6))
                        (+ (index-atom $mean 7) (index-atom $trans-stand-norm0 7)))))
                        )
                        Empty)
                        (if (>= (- $lambda_ 2) 0)
                        (let $trans-stand-norm1 (index-atom $transformed-standard-normals 1)
                        (collapse(superpose(
                        (+ (index-atom $mean 0) (index-atom $trans-stand-norm1 0))
                        (+ (index-atom $mean 1) (index-atom $trans-stand-norm1 1))
                        (+ (index-atom $mean 2) (index-atom $trans-stand-norm1 2))
                        (+ (index-atom $mean 3) (index-atom $trans-stand-norm1 3))
                        (+ (index-atom $mean 4) (index-atom $trans-stand-norm1 4))
                        (+ (index-atom $mean 5) (index-atom $trans-stand-norm1 5))
                        (+ (index-atom $mean 6) (index-atom $trans-stand-norm1 6))
                        (+ (index-atom $mean 7) (index-atom $trans-stand-norm1 7)))))
                        )
                        Empty)
                        (if (>= (- $lambda_ 3) 0)
                        (let $trans-stand-norm2 (index-atom $transformed-standard-normals 2)
                        (collapse(superpose(
                        (+ (index-atom $mean 0) (index-atom $trans-stand-norm2 0))
                        (+ (index-atom $mean 1) (index-atom $trans-stand-norm2 1))
                        (+ (index-atom $mean 2) (index-atom $trans-stand-norm2 2))
                        (+ (index-atom $mean 3) (index-atom $trans-stand-norm2 3))
                        (+ (index-atom $mean 4) (index-atom $trans-stand-norm2 4))
                        (+ (index-atom $mean 5) (index-atom $trans-stand-norm2 5))
                        (+ (index-atom $mean 6) (index-atom $trans-stand-norm2 6))
                        (+ (index-atom $mean 7) (index-atom $trans-stand-norm2 7)))))
                        )
                        Empty)
                        (if (>= (- $lambda_ 4) 0)
                        (let $trans-stand-norm3 (index-atom $transformed-standard-normals 3)
                        (collapse(superpose(
                        (+ (index-atom $mean 0) (index-atom $trans-stand-norm3 0))
                        (+ (index-atom $mean 1) (index-atom $trans-stand-norm3 1))
                        (+ (index-atom $mean 2) (index-atom $trans-stand-norm3 2))
                        (+ (index-atom $mean 3) (index-atom $trans-stand-norm3 3))
                        (+ (index-atom $mean 4) (index-atom $trans-stand-norm3 4))
                        (+ (index-atom $mean 5) (index-atom $trans-stand-norm3 5))
                        (+ (index-atom $mean 6) (index-atom $trans-stand-norm3 6))
                        (+ (index-atom $mean 7) (index-atom $trans-stand-norm3 7)))))
                        )
                        Empty)
                        (if (>= (- $lambda_ 5) 0)
                        (let $trans-stand-norm4 (index-atom $transformed-standard-normals 4)
                        (collapse(superpose(
                        (+ (index-atom $mean 0) (index-atom $trans-stand-norm4 0))
                        (+ (index-atom $mean 1) (index-atom $trans-stand-norm4 1))
                        (+ (index-atom $mean 2) (index-atom $trans-stand-norm4 2))
                        (+ (index-atom $mean 3) (index-atom $trans-stand-norm4 3))
                        (+ (index-atom $mean 4) (index-atom $trans-stand-norm4 4))
                        (+ (index-atom $mean 5) (index-atom $trans-stand-norm4 5))
                        (+ (index-atom $mean 6) (index-atom $trans-stand-norm4 6))
                        (+ (index-atom $mean 7) (index-atom $trans-stand-norm4 7)))))
                        )
                        Empty)
                        (if (>= (- $lambda_ 6) 0)
                        (let $trans-stand-norm5 (index-atom $transformed-standard-normals 5)
                        (collapse(superpose(
                        (+ (index-atom $mean 0) (index-atom $trans-stand-norm5 0))
                        (+ (index-atom $mean 1) (index-atom $trans-stand-norm5 1))
                        (+ (index-atom $mean 2) (index-atom $trans-stand-norm5 2))
                        (+ (index-atom $mean 3) (index-atom $trans-stand-norm5 3))
                        (+ (index-atom $mean 4) (index-atom $trans-stand-norm5 4))
                        (+ (index-atom $mean 5) (index-atom $trans-stand-norm5 5))
                        (+ (index-atom $mean 6) (index-atom $trans-stand-norm5 6))
                        (+ (index-atom $mean 7) (index-atom $trans-stand-norm5 7)))))
                        )
                        Empty)
                        (if (>= (- $lambda_ 7) 0)
                        (let $trans-stand-norm6 (index-atom $transformed-standard-normals 6)
                        (collapse(superpose(
                        (+ (index-atom $mean 0) (index-atom $trans-stand-norm6 0))
                        (+ (index-atom $mean 1) (index-atom $trans-stand-norm6 1))
                        (+ (index-atom $mean 2) (index-atom $trans-stand-norm6 2))
                        (+ (index-atom $mean 3) (index-atom $trans-stand-norm6 3))
                        (+ (index-atom $mean 4) (index-atom $trans-stand-norm6 4))
                        (+ (index-atom $mean 5) (index-atom $trans-stand-norm6 5))
                        (+ (index-atom $mean 6) (index-atom $trans-stand-norm6 6))
                        (+ (index-atom $mean 7) (index-atom $trans-stand-norm6 7)))))
                        )
                        Empty)
                        (if (>= (- $lambda_ 8) 0)
                        (let $trans-stand-norm7 (index-atom $transformed-standard-normals 7)
                        (collapse(superpose(
                        (+ (index-atom $mean 0) (index-atom $trans-stand-norm7 0))
                        (+ (index-atom $mean 1) (index-atom $trans-stand-norm7 1))
                        (+ (index-atom $mean 2) (index-atom $trans-stand-norm7 2))
                        (+ (index-atom $mean 3) (index-atom $trans-stand-norm7 3))
                        (+ (index-atom $mean 4) (index-atom $trans-stand-norm7 4))
                        (+ (index-atom $mean 5) (index-atom $trans-stand-norm7 5))
                        (+ (index-atom $mean 6) (index-atom $trans-stand-norm7 6))
                        (+ (index-atom $mean 7) (index-atom $trans-stand-norm7 7)))))
                        )
                        Empty)
                        (if (>= (- $lambda_ 9) 0)
                        (let $trans-stand-norm8 (index-atom $transformed-standard-normals 8)
                        (collapse(superpose(
                        (+ (index-atom $mean 0) (index-atom $trans-stand-norm8 0))
                        (+ (index-atom $mean 1) (index-atom $trans-stand-norm8 1))
                        (+ (index-atom $mean 2) (index-atom $trans-stand-norm8 2))
                        (+ (index-atom $mean 3) (index-atom $trans-stand-norm8 3))
                        (+ (index-atom $mean 4) (index-atom $trans-stand-norm8 4))
                        (+ (index-atom $mean 5) (index-atom $trans-stand-norm8 5))
                        (+ (index-atom $mean 6) (index-atom $trans-stand-norm8 6))
                        (+ (index-atom $mean 7) (index-atom $trans-stand-norm8 7)))))
                        )
                        Empty)
                        (if (>= (- $lambda_ 10) 0)
                        (let $trans-stand-norm9 (index-atom $transformed-standard-normals 9)
                        (collapse(superpose(
                        (+ (index-atom $mean 0) (index-atom $trans-stand-norm9 0))
                        (+ (index-atom $mean 1) (index-atom $trans-stand-norm9 1))
                        (+ (index-atom $mean 2) (index-atom $trans-stand-norm9 2))
                        (+ (index-atom $mean 3) (index-atom $trans-stand-norm9 3))
                        (+ (index-atom $mean 4) (index-atom $trans-stand-norm9 4))
                        (+ (index-atom $mean 5) (index-atom $trans-stand-norm9 5))
                        (+ (index-atom $mean 6) (index-atom $trans-stand-norm9 6))
                        (+ (index-atom $mean 7) (index-atom $trans-stand-norm9 7)))))
                        )
                        Empty)
                    )
                )
            )
        )
    )
)

(: range (Number Number Number -> List))
(= (range $start $end $step)
    (if (> $start $end)
        ()
        (let*
            (
                ($next (range (+ $start $step) $end $step))
            )   
            (cons-atom $start $next)
        )
    )
)

;––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
; make-indices: 0-based indices for a list
(: make-indices (List -> List))
(= (make-indices $lst) (range 0 (- (size-atom $lst) 1) 1))
; ! (make-indices (10 30 20))


; remove-index: remove the i-th element
(: remove-index (List Number -> List))
(= (remove-index $lst $i)
   (if (== $i 0)
       (cdr-atom $lst)                       
       (let* (
               ($head (index-atom $lst 0))   
               ($tail (cdr-atom   $lst))    
               ($rest (remove-index $tail (- $i 1))) 
             )
         (cons-atom $head $rest)        
       )
   )
)
; ! (remove-index ((0 10) (1 30) (2 20)) 1)   ; [((0 10) (2 20))]

(: vec-scale (Number List -> List))          
(= (vec-scale $c $v)
   (map-atom                                 
     $v $x
     (* $c $x))                              
)
; ! (vec-scale 0.5  (2 4 6))        ; Expected -> [(1 2 3)]

(: vec-add (List List -> List))            
(= (vec-add $a $b)
   (if (== (size-atom $a) 0)                
       ()
       (let* (
               ($sum  (+ (index-atom $a 0)   
                          (index-atom $b 0)))
               ($tail (vec-add              
                         (cdr-atom $a)
                         (cdr-atom $b)))
             )
         (cons-atom $sum $tail)              
       )
   )
)
; ! (vec-add (1 2 3 4 5 6 7 8) (4 5 6 6 7 6 7 8))          ; Expected -> [(5 7 9)]
