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

; (: scalar-op (-> Expression Number Atom Expression))
(= (scalar-op $vector $num $op)
    (collapse
        (superpose
            (
                ($op (index-atom $vector 0) $num)
                ($op (index-atom $vector 1) $num)
                ($op (index-atom $vector 2) $num)
                ($op (index-atom $vector 3) $num)
                ($op (index-atom $vector 4) $num)
                ($op (index-atom $vector 5) $num)
                ($op (index-atom $vector 6) $num)
                ($op (index-atom $vector 7) $num)
                ($op (index-atom $vector 8) $num)
                ($op (index-atom $vector 9) $num)
            )
        )
    )
)

; (: rev-scalar-op (-> Number Expression Atom Expression))
(= (rev-scalar-op $num $vector $op)
    (collapse
        (superpose
            (
                ($op $num (index-atom $vector 0))
                ($op $num (index-atom $vector 1))
                ($op $num (index-atom $vector 2))
                ($op $num (index-atom $vector 3))
                ($op $num (index-atom $vector 4))
                ($op $num (index-atom $vector 5))
                ($op $num (index-atom $vector 6))
                ($op $num (index-atom $vector 7))
                ($op $num (index-atom $vector 8))
                ($op $num (index-atom $vector 9))
            )
        )
    )
)

(= (l00 $cov-matrice)
    (let $x (index-atom $cov-matrice 0) (sqrt-math (index-atom $x 0)))
)

(= (l10 $cov-matrice)
    (let $x (index-atom $cov-matrice 1) (/ (index-atom $x 0) (l00 $cov-matrice)))
)

(= (l11 $cov-matrice)
    (let $x (index-atom $cov-matrice 1) (sqrt-math (let $y (index-atom $x 1) (- $y (pow-math (l10 $cov-matrice) 2)))))
)

(= (l20 $cov-matrice)
    (let $x (index-atom $cov-matrice 2) (/ (index-atom $x 0) (l00 $cov-matrice)))
)

(= (l21 $cov-matrice)
    (let $x (index-atom $cov-matrice 2) (let $y (index-atom $x 1) (/ (- $y (* (l20 $cov-matrice) (l10 $cov-matrice))) (l11 $cov-matrice))))
)

(= (l22 $cov-matrice)
    (let $x (index-atom $cov-matrice 2) (sqrt-math (let $y (index-atom $x 2) (- $y (sum (apply-power ((l20 $cov-matrice) (l21 $cov-matrice)) 2))))))
)

(= (l30 $cov-matrice)
    (let $x (index-atom $cov-matrice 3) (/ (index-atom $x 0) (l00 $cov-matrice)))
)

(= (l40 $cov-matrice)
    (let $x (index-atom $cov-matrice 4) (/ (index-atom $x 0) (l00 $cov-matrice)))
)

(= (l50 $cov-matrice)
    (let $x (index-atom $cov-matrice 5) (/ (index-atom $x 0) (l00 $cov-matrice)))
)

(= (l60 $cov-matrice)
    (let $x (index-atom $cov-matrice 6) (/ (index-atom $x 0) (l00 $cov-matrice)))
)

(= (l70 $cov-matrice)
    (let $x (index-atom $cov-matrice 7) (/ (index-atom $x 0) (l00 $cov-matrice)))
)

(= (l31 $cov-matrice)
    (let $x (index-atom $cov-matrice 3) (let $y (index-atom $x 1) (/ (- $y (* (l30 $cov-matrice) (l10 $cov-matrice))) (l11 $cov-matrice))))
)

(= (l32 $cov-matrice)
    ()
)

(= (l33 $cov-matrice)

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
                                (if (>= (- $columns 1) (l00 $cov-matrice) Empty)) (if (>= (- $columns 2) 0 Empty)) (if (>= (- $columns 3) 0 Empty)) (if (>= (- $columns 4) 0 Empty)) (if (>= (- $columns 5) 0 Empty)) (if (>= (- $columns 6) 0 Empty)) (if (>= (- $columns 7) 0 Empty)) (if (>= (- $columns 8) 0 Empty))
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
                                (if (>= (- $columns 1) (l00 $cov-matrice) Empty)) (if (>= (- $columns 2) 0 Empty)) (if (>= (- $columns 3) 0 Empty)) (if (>= (- $columns 4) 0 Empty)) (if (>= (- $columns 5) 0 Empty)) (if (>= (- $columns 6) 0 Empty)) (if (>= (- $columns 7) 0 Empty)) (if (>= (- $columns 8) 0 Empty))
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
                                (if (>= (- $columns 1) (l00 $cov-matrice) Empty)) (if (>= (- $columns 2) 0 Empty)) (if (>= (- $columns 3) 0 Empty)) (if (>= (- $columns 4) 0 Empty)) (if (>= (- $columns 5) 0 Empty)) (if (>= (- $columns 6) 0 Empty)) (if (>= (- $columns 7) 0 Empty)) (if (>= (- $columns 8) 0 Empty))
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
                                (if (>= (- $columns 1) (l00 $cov-matrice) Empty)) (if (>= (- $columns 2) 0 Empty)) (if (>= (- $columns 3) 0 Empty)) (if (>= (- $columns 4) 0 Empty)) (if (>= (- $columns 5) 0 Empty)) (if (>= (- $columns 6) 0 Empty)) (if (>= (- $columns 7) 0 Empty)) (if (>= (- $columns 8) 0 Empty))
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
                                (if (>= (- $columns 1) (l00 $cov-matrice) Empty)) (if (>= (- $columns 2) 0 Empty)) (if (>= (- $columns 3) 0 Empty)) (if (>= (- $columns 4) 0 Empty)) (if (>= (- $columns 5) 0 Empty)) (if (>= (- $columns 6) 0 Empty)) (if (>= (- $columns 7) 0 Empty)) (if (>= (- $columns 8) 0 Empty))
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

; !(chol-decomp ((6 2 3)
;  (2 6 3)
;  (3 3 6)))

(= (random-multivariate $cov-matrice)
    ()
)

; !(scalar-op (1 2 3) 3 *)
; !(rev-scalar-op 3 (1 2 3) *)
;!(range 1 8)

; !(identity-matrice 10)

; !(l2-norm (1 2 3 4))

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




