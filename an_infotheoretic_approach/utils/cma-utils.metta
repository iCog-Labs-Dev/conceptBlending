
;;;;;;;;;;;;;;;;; This will be removed once the integration with other steps completed ;;;;;;;;;;;;;;;;;
(= (mean)(0.1532438268 0.9115322169 0.7726675964 0.9960517035 0.9919923562 1.0 0.9721099589 0.9872805715))
(= (old_mean) (0.1747789218 0.8928285463 0.7682712759 0.994495826 0.9904006266 0.9970624626 0.9953409512 0.9894387772))
(= (step_size)0.10788994642409189)
(= (dim) 8)
(= (c_sigma)0.3196142529106334)
(= (d_sigma)1.3196142529106334)
(= (p_sigma)(-2.6246439804 0.8142997543 -3.1543030904 0.707512709 0.023392001 0.2815181204 0.1050022151 0.5368394431))
(= (mu_eff)3.1672992814107017)
(= (cov)(( 0.1275027102 -0.0073718191  0.0078853939 -0.006085294  -0.007529608
   0.0006145847  0.0006532585 -0.0003897734)
 (-0.0073718191  0.1236505819  0.0128279785  0.0010299719  0.0010183611
   0.0036746865 -0.0024490318 -0.0042837598)
 ( 0.0078853939  0.0128279785  0.1319373811 -0.0020357235 -0.0080034593
   0.0046084872  0.0028631799 -0.0049324424)
 (-0.006085294   0.0010299719 -0.0020357235  0.1093979855 -0.0054512511
   0.0010486165 -0.0025863642 -0.0022958593)
 (-0.007529608   0.0010183611 -0.0080034593 -0.0054512511  0.1194634131
  -0.0035500213 -0.0046857078  0.0021295188)
 ( 0.0006145847  0.0036746865  0.0046084872  0.0010486165 -0.0035500213
   0.1171957085 -0.0058126198 -0.0043529058)
 ( 0.0006532585 -0.0024490318  0.0028631799 -0.0025863642 -0.0046857078
  -0.0058126198  0.1071976117 -0.0027415316)
 (-0.0003897734 -0.0042837598 -0.0049324424 -0.0022958593  0.0021295188
  -0.0043529058 -0.0027415316  0.1067087191)))
;;;;;;;;;;;;;;;;; Temporary static variables end here ;;;;;;;;;;;;;;;;;



(= (sub $a $b) (- $a $b))
(= (div $a $b) (/ $a $b))
(= (mul $a $b) (* $a $b))
(= (add $a $b) (+ $a $b))

(= (sum ()) 0)
(= (sum $lst)
   (+ (car-atom $lst) (sum (cdr-atom $lst)))
)


(= (nth $x 0) (car-atom $x))
(= (nth $x $n)
   (nth (cdr-atom $x) (sub $n 1))
   )

(= (vec-clc $a $b $op)
    (if (== (size-atom $a) 0)
    ()
    (if (== (size-atom $a) (size-atom $b))
        (let*(
            ($a-head (car-atom $a))
            ($b-head (car-atom $b))
            ($next-res (vec-clc (cdr-atom $a) (cdr-atom $b) $op))
            ($result ($op $a-head $b-head))

        )
            (cons-atom $result $next-res
            )
        )
        (params are not equal)
    )
   )
  )
   

(= (identity-matrix $n)
   (if (== $n 0)
       ()
       (let* (($gen-iden (gen-identity-row 0 $n))
            ($identity-matrix (identity-matrix-helper 1 $n))
                )
                (cons-atom $gen-iden $identity-matrix)
        )
   )
)

(= (identity-matrix-helper $i $n)
   (if (< $i $n)
        (let* (($gen-iden (gen-identity-row $i $n))
            ($identity-matrix (identity-matrix-helper (+ $i 1) $n))
                )
                (cons-atom $gen-iden $identity-matrix)
        )
       ()
   )
)

(= (gen-identity-row $i $n)
   (gen-identity-row-helper $i $n 0)
)

(= (gen-identity-row-helper $i $n $j)
   (if (< $j $n)
        (let* (($k (if (== $i $j) 1.0 0.0))
            ($gen-row (gen-identity-row-helper $i $n (+ $j 1)))
                )
                (cons-atom $k $gen-row)
        )
       ()
   )
)


(= (make-row $n)
   (if (== $n 0)
       ()
       (let* (($sub (- $n 1))
            ($next (make-row $sub))
            )
            (cons-atom 0 $next)
        )
       ))


(= (make-matrix $rows $cols)
   (if (== $rows 0)
       ()
       (let* (($cols-row (make-row $cols))
            ($sub (- $rows 1))
            ($next (make-matrix $sub $cols))
            )
            (cons-atom $cols-row $next)
        )
    )
)

(= (update-matrix-row $rows $i $new-row)
   (let* (
     ($head (car-atom $rows))
     ($tail (cdr-atom $rows))
   )
     (if (== $i 0)
         (cons-atom $new-row $tail)
         (let* (
           ($updated-tail (update-matrix-row $tail (sub $i 1) $new-row))
         )
           (cons-atom $head $updated-tail)))))

(= (update-matrix-cell $rows $i $j $val)
   (let* (($row (nth $rows $i))
         ($new-row (update-row-cell $row $j $val)))
     (update-matrix-row $rows $i $new-row)
    )
)

(= (update-row-cell $row 0 $val)
   (let* (
     ($xs (cdr-atom $row))
   )
     (cons-atom $val $xs)))

(= (update-row-cell $row $j $val)
   (let* (
     ($x (car-atom $row))
     ($xs (cdr-atom $row))
     ($updated-tail (update-row-cell $xs (sub $j 1) $val))
   )
     (cons-atom $x $updated-tail)))

!(make-matrix 8 8)