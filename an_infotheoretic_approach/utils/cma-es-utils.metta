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

(= (call-lik $i $k)
    (
        superpose(
            (if (== $i 1) (match &lspace (l10 $x) $x) Empty)
            (if (== $i 2) (superpose((if (== $k 0) (match &lspace (l20 $x) $x) Empty) (if (== $k 1) (match &lspace (l21 $x) $x) Empty))) Empty)
            (if (== $i 3) (superpose((if (== $k 0) (match &lspace (l30 $x) $x) Empty) (if (== $k 1) (match &lspace (l31 $x) $x) Empty) (if (== $k 2) (match &lspace (l32 $x) $x) Empty))) Empty)
            (if (== $i 4) (superpose((if (== $k 0) (match &lspace (l40 $x) $x) Empty) (if (== $k 1) (match &lspace (l41 $x) $x) Empty) (if (== $k 2) (match &lspace (l42 $x) $x) Empty) (if (== $k 3) (match &lspace (l43 $x) $x) Empty))) Empty)
            (if (== $i 5) (superpose((if (== $k 0) (match &lspace (l50 $x) $x) Empty) (if (== $k 1) (match &lspace (l51 $x) $x) Empty) (if (== $k 2) (match &lspace (l52 $x) $x) Empty) (if (== $k 3) (match &lspace (l53 $x) $x) Empty) (if (== $k 4) (match &lspace (l54 $x) $x) Empty))) Empty)
            (if (== $i 6) (superpose((if (== $k 0) (match &lspace (l60 $x) $x) Empty) (if (== $k 1) (match &lspace (l61 $x) $x) Empty) (if (== $k 2) (match &lspace (l62 $x) $x) Empty) (if (== $k 3) (match &lspace (l63 $x) $x) Empty) (if (== $k 4) (match &lspace (l64 $x) $x) Empty) (if (== $k 5) (match &lspace (l65 $x) $x) Empty))) Empty)
            (if (== $i 7) (superpose((if (== $k 0) (match &lspace (l70 $x) $x) Empty) (if (== $k 1) (match &lspace (l71 $x) $x) Empty) (if (== $k 2) (match &lspace (l72 $x) $x) Empty) (if (== $k 3) (match &lspace (l73 $x) $x) Empty) (if (== $k 4) (match &lspace (l74 $x) $x) Empty) (if (== $k 5) (match &lspace (l75 $x) $x) Empty) (if (== $k 6) (match &lspace (l76 $x) $x) Empty))) Empty)
        )
    )
)

(= (call-ljk $j $k)
    (
        superpose(
            (if (== $j 1) (match &lspace (l00 $x) $x) Empty)
            (if (== $j 2) (superpose((if (== $k 0) (match &lspace (l20 $x) $x) Empty) (if (== $k 1) (match &lspace (l21 $x) $x) Empty))) Empty)
            (if (== $j 3) (superpose((if (== $k 0) (match &lspace (l30 $x) $x) Empty) (if (== $k 1) (match &lspace (l31 $x) $x) Empty) (if (== $k 2) (match &lspace (l32 $x) $x) Empty))) Empty)
            (if (== $j 4) (superpose((if (== $k 0) (match &lspace (l40 $x) $x) Empty) (if (== $k 1) (match &lspace (l41 $x) $x) Empty) (if (== $k 2) (match &lspace (l42 $x) $x) Empty) (if (== $k 3) (match &lspace (l43 $x) $x) Empty))) Empty)
            (if (== $j 5) (superpose((if (== $k 0) (match &lspace (l50 $x) $x) Empty) (if (== $k 1) (match &lspace (l51 $x) $x) Empty) (if (== $k 2) (match &lspace (l52 $x) $x) Empty) (if (== $k 3) (match &lspace (l53 $x) $x) Empty) (if (== $k 4) (match &lspace (l54 $x) $x) Empty))) Empty)
            (if (== $j 6) (superpose((if (== $k 0) (match &lspace (l60 $x) $x) Empty) (if (== $k 1) (match &lspace (l61 $x) $x) Empty) (if (== $k 2) (match &lspace (l62 $x) $x) Empty) (if (== $k 3) (match &lspace (l63 $x) $x) Empty) (if (== $k 4) (match &lspace (l64 $x) $x) Empty) (if (== $k 5) (match &lspace (l65 $x) $x) Empty))) Empty)
            (if (== $j 7) (superpose((if (== $k 0) (match &lspace (l70 $x) $x) Empty) (if (== $k 1) (match &lspace (l71 $x) $x) Empty) (if (== $k 2) (match &lspace (l72 $x) $x) Empty) (if (== $k 3) (match &lspace (l73 $x) $x) Empty) (if (== $k 4) (match &lspace (l74 $x) $x) Empty) (if (== $k 5) (match &lspace (l75 $x) $x) Empty) (if (== $k 6) (match &lspace (l76 $x) $x) Empty))) Empty)
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

(= (l00 $cov-matrice)
    (let $a0 (index-atom $cov-matrice 0)
        (let $a00 (index-atom $a0 0)
            (let $l00 (sqrt-math $a00)
                (let $add (add-atom &lspace (l00 $l00)) $l00)
            )
        )
    )
)

(= (l10 $cov-matrice)
    (let ($a1 $l00) ((index-atom $cov-matrice 1) (match &lspace (l00 $x) $x))
        (let $a10 (index-atom $a1 0)
            (let $l10 (/ $a10 $l00)
                (let $add (add-atom &lspace (l10 $l10)) $l10)
            )
        )
    )
)

(= (l11 $cov-matrice)
    (let ($a1 $l10) ((index-atom $cov-matrice 1) (match &lspace (l10 $x) $x))
        (let $l11 (sqrt-math (let $a11 (index-atom $a1 1) (- $a11 (pow-math $l10 2))))
            (let $add (add-atom &lspace (l11 $l11)) $l11)
        )
    )
)

(= (l20 $cov-matrice)
    (let ($a2 $l00) ((index-atom $cov-matrice 2) (match &lspace (l00 $x) $x))
        (let $a20 (index-atom $a2 0)
            (let $l20 (/ $a20 $l00)
                (let $add (add-atom &lspace (l20 $l20)) $l20)
            )
        )
    )
)

(= (l21 $cov-matrice)
    (let ($a2 $l10 $l11 $l20) (collapse(superpose((index-atom $cov-matrice 2) (match &lspace (l10 $x) $x) (match &lspace (l11 $x) $x) (match &lspace (l20 $x) $x))))
        (let $a21 (index-atom $a2 1)
            (let $l21 (/ (- $a21 (* $l20 $l10)) $l11)
                (let $add (add-atom &lspace (l21 $l21)) $l21)
            )
        )
    )
)

(= (l22 $cov-matrice)
    (let $a2 (index-atom $cov-matrice 2)
        (let $l22 (sqrt-math (let $a22 (index-atom $a2 2) (- $a22 (sum (cells-product 2 2))))) 
            (let $add (add-atom &lspace (l22 $l22)) $l22)
        )
    )
)

(= (l30 $cov-matrice)
    (let ($a3 $l00) ((index-atom $cov-matrice 3) (match &lspace (l00 $x) $x))
        (let $a30 (index-atom $a3 0)
            (let $l30 (/ $a30 $l00)
                (let $add (add-atom &lspace (l30 $l30)) $l30)
            )
        )
    )
)

(= (l31 $cov-matrice)
    (let ($a3 $l30 $l10 $l11) (collapse(superpose((index-atom $cov-matrice 3) (match &lspace (l30 $x) $x) (match &lspace (l10 $x) $x) (match &lspace (l11 $x) $x))))
        (let $a31 (index-atom $a3 1)
            (let $l31 (/ (- $a31 (* $l30 $l10)) $l11)
                (let $add (add-atom &lspace (l31 $l31)) $l31)
            )
        )
    )
)

(= (l32 $cov-matrice)
    (let ($a3 $l22) ((index-atom $cov-matrice 3) (match &lspace (l22 $x) $x))
        (let $a33 (index-atom $a3 2)
            (let $l32 (/ (- $a33 (sum (cells-product 3 2))) $l22)
                (let $add (add-atom &lspace (l32 $l32)) $l32)
            )
        )
    )
)

(= (l33 $cov-matrice)
    (let $a3 (index-atom $cov-matrice 3)
        (let $l33 (sqrt-math (let $a33 (index-atom $a3 3) (- $a33 (sum (cells-product 3 3)))))
            (let $add (add-atom &lspace (l33 $l33)) $l33)
        )
    )
)

(= (l40 $cov-matrice)
    (let ($a4 $l00) ((index-atom $cov-matrice 4) (match &lspace (l00 $x) $x))
        (let $a40 (index-atom $a4 0) 
            (let $l40 (/ $a40 $l00)
                (let $add (add-atom &lspace (l40 $l40)) $l40)
            )
        )
    )
)

(= (l41 $cov-matrice)
    (let ($a4 $l40 $l10 $l11) (collapse(superpose((index-atom $cov-matrice 4) (match &lspace (l40 $x) $x) (match &lspace (l10 $x) $x) (match &lspace (l11 $x) $x)))) 
        (let $a41 (index-atom $a4 1)
            (let $l41 (/ (- $a41 (* $l40 $l10)) $l11)
                (let $add (add-atom &lspace (l41 $l41)) $l41)
            )
        )
    )
)

(= (l42 $cov-matrice)
    (let ($a4 $l22) ((index-atom $cov-matrice 4) (match &lspace (l22 $x) $x))
        (let $a42 (index-atom $a4 2)
            (let $l42 (/ (- $a42 (sum (cells-product 4 2))) $l22)
                (let $add (add-atom &lspace (l42 $l42)) $l42)
            )
        )
    )
)

(= (l43 $cov-matrice)
    (let ($a4 $l33) ((index-atom $cov-matrice 4) (match &lspace (l33 $x) $x))
        (let $a43 (index-atom $a4 3)
            (let $l43 (/ (- $a43 (sum (cells-product 4 3))) $l33)
                (let $add (add-atom &lspace (l43 $l43)) $l43)
            )
        )
    )
)

(= (l44 $cov-matrice)
    (let $a4 (index-atom $cov-matrice 4)
        (let $l44 (sqrt-math (let $a44 (index-atom $a4 4) (- $a44 (sum (cells-product 4 4)))))
            (let $add (add-atom &lspace (l44 $l44)) $l44)
        )
    )
)

(= (l50 $cov-matrice)
    (let ($a5 $l00) ((index-atom $cov-matrice 5) (match &lspace (l00 $x) $x))
        (let $a50 (index-atom $a5 0)
            (let $l50 (/ $a50 $l00)
                (let $add (add-atom &lspace (l50 $l50)) $l50)
            )
        )
    )
)

(= (l51 $cov-matrice)
    (let ($a5 $l50 $l10 $l11) (collapse (superpose ((index-atom $cov-matrice 5) (match &lspace (l50 $x) $x) (match &lspace (l10 $x) $x) (match &lspace (l11 $x) $x))))
        (let $a51 (index-atom $a5 1)
            (let $l51 (/ (- $a51 (* $l50 $l10)) $l11)
                (let $add (add-atom &lspace (l51 $l51)) $l51)
            )
        )
    )
)

(= (l52 $cov-matrice)
    (let ($a5 $l22) ((index-atom $cov-matrice 5) (match &lspace (l22 $x) $x))
        (let $a52 (index-atom $a5 2)
            (let $l52 (/ (- $a52 (sum (cells-product 5 2))) $l22)
                (let $add (add-atom &lspace (l52 $l52)) $l52)
            )
        )
    )
)

(= (l53 $cov-matrice)
    (let ($a5 $l33) ((index-atom $cov-matrice 5) (match &lspace (l33 $x) $x))
        (let $a53 (index-atom $a5 3)
            (let $l53 (/ (- $a53 (sum (cells-product 5 3))) $l33)
                (let $add (add-atom &lspace (l53 $l53)) $l53)
            )
        )
    )
)

(= (l54 $cov-matrice)
    (let ($a5 $l44) ((index-atom $cov-matrice 5) (match &lspace (l44 $x) $x))
        (let $a54 (index-atom $a5 4)
            (let $l54 (/ (- $a54 (sum (cells-product 5 4))) $l44)
                (let $add (add-atom &lspace (l54 $l54)) $l54)
            )
        )
    )
)

(= (l55 $cov-matrice)
    (let $a5 (index-atom $cov-matrice 5)
        (let $l55 (sqrt-math (let $a55 (index-atom $a5 5) (- $a55 (sum (cells-product 5 5)))))
            (let $add (add-atom &lspace (l55 $l55)) $l55)
        )
    )
)

(= (l60 $cov-matrice)
    (let ($a6 $l00) ((index-atom $cov-matrice 6) (match &lspace (l00 $x) $x))
        (let $a60 (index-atom $a6 0)
            (let $l60 (/ $a60 $l00)
                (let $add (add-atom &lspace (l60 $l60)) $l60)
            )
        )
    )
)

(= (l61 $cov-matrice)
    (let ($a6 $l60 $l10 $l11) (collapse (superpose ((index-atom $cov-matrice 6) (match &lspace (l60 $x) $x) (match &lspace (l10 $x) $x) (match &lspace (l11 $x) $x))))
        (let $a61 (index-atom $a6 1)
            (let $l61 (/ (- $a61 (* $l60 $l10)) $l11)
                (let $add (add-atom &lspace (l61 $l61)) $l61)
            )
        )
    )
)

(= (l62 $cov-matrice)
    (let ($a6 $l22) ((index-atom $cov-matrice 6) (match &lspace (l22 $x) $x))
        (let $a62 (index-atom $a6 2)
            (let $l62 (/ (- $a62 (sum (cells-product 6 2))) $l22)
                (let $add (add-atom &lspace (l62 $l62)) $l62)
            )
        )
    )
)

(= (l63 $cov-matrice)
    (let ($a6 $l33) ((index-atom $cov-matrice 6) (match &lspace (l33 $x) $x))
        (let $a63 (index-atom $a6 3)
            (let $l63 (/ (- $a63 (sum (cells-product 6 3))) $l33)
                (let $add (add-atom &lspace (l63 $l63)) $l63)
            )
        )
    )
)

(= (l64 $cov-matrice)
    (let ($a6 $l44) ((index-atom $cov-matrice 6) (match &lspace (l44 $x) $x))
        (let $a64 (index-atom $a6 4)
            (let $l64 (/ (- $a64 (sum (cells-product 6 4))) $l44)
                (let $add (add-atom &lspace (l64 $l64)) $l64)
            )
        )
    )
)

(= (l65 $cov-matrice)
    (let ($a6 $l55) ((index-atom $cov-matrice 6) (match &lspace (l55 $x) $x))
        (let $a65 (index-atom $a6 5)
            (let $l65 (/ (- $a65 (sum (cells-product 6 5))) $l55)
                (let $add (add-atom &lspace (l65 $l65)) $l65)
            )
        )
    )
)

(= (l66 $cov-matrice)
    (let $a6 (index-atom $cov-matrice 6)
        (let $l66 (sqrt-math (let $a66 (index-atom $a6 6) (- $a66 (sum (cells-product 6 6)))))
            (let $add (add-atom &lspace (l66 $l66)) $l66)
        )
    )
)

(= (l70 $cov-matrice)
    (let ($a7 $l00) ((index-atom $cov-matrice 7) (match &lspace (l00 $x) $x))
        (let $a70 (index-atom $a7 0)
            (let $l70 (/ $a70 $l00)
                (let $add (add-atom &lspace (l70 $l70)) $l70)
            )
        )
    )
)

(= (l71 $cov-matrice)
    (let ($a7 $l70 $l10 $l11) (collapse (superpose ((index-atom $cov-matrice 7) (match &lspace (l70 $x) $x) (match &lspace (l10 $x) $x) (match &lspace (l11 $x) $x))))
        (let $a71 (index-atom $a7 1)
            (let $l71 (/ (- $a71 (* $l70 $l10)) $l11)
                (let $add (add-atom &lspace (l71 $l71)) $l71)
            )
        )
    )
)

(= (l72 $cov-matrice)
    (let ($a7 $l22) ((index-atom $cov-matrice 7) (match &lspace (l22 $x) $x))
        (let $a72 (index-atom $a7 2)
            (let $l72 (/ (- $a72 (sum (cells-product 7 2))) $l22)
                (let $add (add-atom &lspace (l72 $l72)) $l72)
            )
        )
    )
)

(= (l73 $cov-matrice)
    (let ($a7 $l33) ((index-atom $cov-matrice 7) (match &lspace (l33 $x) $x))
        (let $a73 (index-atom $a7 3)
            (let $l73 (/ (- $a73 (sum (cells-product 7 3))) $l33)
                (let $add (add-atom &lspace (l73 $l73)) $l73)
            )
        )
    )
)

(= (l74 $cov-matrice)
    (let ($a7 $l44) ((index-atom $cov-matrice 7) (match &lspace (l44 $x) $x))
        (let $a74 (index-atom $a7 4)
            (let $l74 (/ (- $a74 (sum (cells-product 7 4))) $l44)
                (let $add (add-atom &lspace (l74 $l74)) $l74)
            )
        )
    )
)

(= (l75 $cov-matrice)
    (let ($a7 $l55) ((index-atom $cov-matrice 7) (match &lspace (l55 $x) $x))
        (let $a75 (index-atom $a7 5)
            (let $l75 (/ (- $a75 (sum (cells-product 7 5))) $l55)
                (let $add (add-atom &lspace (l75 $l75)) $l75)
            )
        )
    )
)

(= (l76 $cov-matrice)
    (let ($a7 $l66) ((index-atom $cov-matrice 7) (match &lspace (l66 $x) $x))
        (let $a76 (index-atom $a7 6)
            (let $l76 (/ (- $a76 (sum (cells-product 7 6))) $l66)
                (let $add (add-atom &lspace (l76 $l76)) $l76)
            )
        )
    )
)

(= (l77 $cov-matrice)
    (let $a7 (index-atom $cov-matrice 7)
        (let $l77 (sqrt-math (let $a77 (index-atom $a7 7) (- $a77 (sum (cells-product 7 7)))))
            (let $add (add-atom &lspace (l77 $l77)) $l77)
        )
    )
)

(= (chol-decomp $cov-matrice)
    (let ($rows $columns) ((size-atom $cov-matrice) (let $row1 (index-atom $cov-matrice 0) (size-atom $row1)))
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
        (
            if (and (not (== $mat-dim $vec-dim)) (not (== $mat-dim $mat-rows)))
            (Error ($mat-dim $vec-dim) DimensionMismatch)
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
        )
    )
)

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
