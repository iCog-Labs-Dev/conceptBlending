; ! (import! &self libs)
! (import! &self utils:cma-utils)


(= (sum-lk $L $i $j $k)
   (if (== $k 0)
       0.0
       (let* (
         ($a (nth (nth $L $i) (sub $k 1)))
         ($b (nth (nth $L $j) (sub $k 1)))
         ($prod (mul $a $b))
         ($rest (sum-lk $L $i $j (sub $k 1)))
       )
         (add $prod $rest))))


(= (cholesky-loop $A $L $i $n)
   (if (== $i $n)
       $L
       (cholesky-j-loop $A $L $i 0 $n)))


(= (cholesky-j-loop $A $L $i $j $n)
   (if (> $j $i)
       (cholesky-loop $A $L (add $i 1) $n)
       (let* (
         ($s (sum-lk $L $i $j $j))
         ($nth-row (nth $A $i))
         ($aij (nth $nth-row $j))
         ($val (if (== $i $j)
                   (sqrt-math (sub $aij $s))
                   (div (sub $aij $s) (nth (nth $L $j) $j))))
         ($L-updated (update-matrix-cell $L $i $j $val))
       )
         (cholesky-j-loop $A $L-updated $i (add $j 1) $n)
        )))

(= (cholesky-decomposition $A)
   (let* (($n (size-atom $A))
          ($L (make-matrix $n $n))
            )
            (cholesky-loop $A $L 0 $n)
    )
)

; !(cholesky-decomposition ((6 2 3 2 1 1 1 1)
;  (2 6 3 2 1 1 1 1)
;  (3 3 6 2 1 1 1 1)
;  (2 2 2 6 1 1 1 1)
;  (1 1 1 1 6 1 1 1)
;  (1 1 1 1 1 6 1 1)
;  (1 1 1 1 1 1 6 1)
;  (1 1 1 1 1 1 1 6))
; )

(= (sum-product $L $I $i $j $k $i_max)
   (if (< $k $i_max)
       (+ 
           (* (nth (nth $L $i) $k)
              (nth (nth $I $k) $j)
           )
           (sum-product $L $I $i $j (+ $k 1) $i_max)
       )
       0.0
   )
)

(= (inverse-row $L $I $i $j)
   (if (< $j $i)
       (inverse-row
           $L
           (update-matrix-cell $I $i $j 
              (/ 
                 (- 0.0 (sum-product $L $I $i $j $j $i))
                 (nth (nth $L $i) $i)
              )
           )
           $i
           (+ $j 1)
       )
       
       (update-matrix-cell $I $i $i 
           (/ 1.0 (nth (nth $L $i) $i))
       )
   )
)

(= (inverse-lower-helper $L $I $i)
   (if (< $i (size-atom $L))
       (inverse-lower-helper
           $L
           (inverse-row $L $I $i 0)
           (+ $i 1)
       )
       $I
   )
)

(= (inverse-lower $L)
   (inverse-lower-helper $L (identity-matrix (size-atom $L)) 0)
)

(= (inverse-transpose $A)
   (transpose (inverse-lower $A))
)

(= (transpose $matrix)
   (transpose-helper $matrix (size-atom $matrix) 0)
)


(= (transpose-helper $matrix $cols $j)
   (if (< $j $cols)
        (let* (
            ($ex-col (extract-column $matrix $j))
            ($next (transpose-helper $matrix $cols (+ $j 1)))
        )
            (cons-atom $ex-col $next)
        )
       ()
   )
)


(= (extract-column $matrix $j)
   (if (== (size-atom $matrix) 0)
       ()
       (let* (
            ($nth-val (nth (car-atom $matrix) $j))
            ($next (extract-column (cdr-atom $matrix) $j))
        )
            (cons-atom $nth-val $next)
        )
   )
)

(= (dot $row $vec)
 (if (== $row ())
 0
   (let* (($x (car-atom $row))
          ($xs (cdr-atom $row))
          ($z (car-atom $vec))
          ($zs (cdr-atom $vec)))
     (if (== $x ())
         0
         (+ (* $x $z) (dot $xs $zs))
         )
    )
 )
)

(= (matvec-mul $matrix $vec)
 (if (== $matrix ())
 ()
   (let* (($row (car-atom $matrix))
          ($rest (cdr-atom $matrix)))
     (if (> (size-atom $row) 0) 
        (let* (($dot (dot $row $vec))
          ($next (matvec-mul $rest $vec))
          )
          (cons-atom $dot $next)
          )
         ())
    )
 )
)

!(matvec-mul ((1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0) (0 1.0 0.0 0.0 0.0 0.0 0.0 0.0) (0 0 1.0 0.0 0.0 0.0 0.0 0.0) (0 0 0 1.0 0.0 0.0 0.0 0.0) (0 0 0 0 1.0 0.0 0.0 0.0) (0 0 0 0 0 1.0 0.0 0.0) (0 0 0 0 0 0 1.0 0.0) (0 0 0 0 0 0 0 1.0)) (2 3 3 4 3 2 3 4))

(= (new-p-sigma $c_sigma $p_sigma $mu_eff $c_inv_sqrt $y)
       (let* (
            ($m1-sigma (- 1 $c_sigma))
            ($m1-sigma-p-sigma (map-atom $p_sigma $ps (* $ps $m1-sigma)))
            ($b2 (sqrt-math (* (* $c_sigma (- 2 $c_sigma)) $mu_eff)))
            ($vec-mul (matvec-mul $c_inv_sqrt $y))
            ($vec-mul-b2 (map-atom $vec-mul $vm (* $vm $b2)))
        )
            (vec-clc $m1-sigma-p-sigma $vec-mul-b2 +)

        )
)

;;;;;;;;;;; y 
(= (mean-diff-step $mean $old_mean $step_size)
    (let*(
        ($vec-diff (vec-clc $mean $old_mean -))
        ($y (map-atom $vec-diff
            $vec
            (/ $vec $step_size)
        ))
   ) $y
   )
)
;;;;;;;;;;; y - end

(= (new-step-size $step_size $c_sigma $d_sigma $dim $p_sigma)
       (let* (
            ($cd-sigma (/ $c_sigma $d_sigma))
            ($p-sigma-sqr (map-atom $p_sigma $ps (* $ps $ps)))
            ($norm (sqrt-math (sum $p-sigma-sqr)))
            ($dim-sqr (sqrt-math $dim))
            ($norm-dim (/ $norm $dim-sqr))
            ($norm-dim-m1 (- $norm-dim 1))
            ($cd-norm-dim-m1 (* $cd-sigma $norm-dim-m1))
            ($e 2.718281828459045)
            ($exp (pow-math $e $cd-norm-dim-m1))

        )
        (* $step_size $exp)
        )
)

(= (step5)
    (let* (
        ($y (mean-diff-step (mean) (old_mean) (step_size)))
        ($cholesky (cholesky-decomposition (cov)))
        ($c-inv-sqrt (inverse-transpose $cholesky))
        ($new-p-sigma (new-p-sigma (c_sigma) (p_sigma) (mu_eff) $c-inv-sqrt $y))
        ($new-step-size (new-step-size (step_size) (c_sigma) (d_sigma) (dim) (p_sigma)))
    )
    (y $y cholesky $cholesky c-inv-sqrt $c-inv-sqrt new-p-sigma $new-p-sigma new-step-size $new-step-size)
    )
)

; !(transpose ((0.4082482904638631 0 0 0 0 0 0 0) (-0.1443375672974065 0.43301270189221935 0 0 0 0 0 0) (-0.1936491673103709 -0.19364916731037082 0.5163977794943222 0 0 0 0 0) (-0.09004503377814968 -0.09004503377814961 -0.060030022518766414 0.4502251688907482 0 0 0 0) (-0.03399337948978519 -0.03399337948978516 -0.022662252993190104 -0.03965894273808271 0.41925168037401717 0 0 0) (-0.03009706909616075 -0.030097069096160726 -0.02006471273077382 -0.0351132472788542 -0.051165017463473246 0.4223622029827889 0 0) (-0.027003148750727214 -0.02700314875072719 -0.018002099167151467 -0.03150367354251507 -0.045905352876236254 -0.04590535287623625 0.4248495403447747 0) (-0.024486654974569838 -0.024486654974569824 -0.01632443664971322 -0.02856776413699814 -0.041627313456768705 -0.041627313456768705 -0.0416273134567687 0.4268840183900007)))
; !(mean-diff-step (mean) (old_mean) (step_size))

; !(step5) ; It will take longer time on cholesky & transpose

; Expected Output

; (y (-0.19960242556197227 0.17335879032213014 0.040748194300876485 0.014420968325299417 0.014753270835294967 0.02722716524905113 -0.21532119599618724 -0.02000377024487971) 
; cholesky ((0.35707521644605916 0 0 0 0 0 0 0) (-0.02064500351878554 0.35103328293725844 0 0 0 0 0 0) (0.02208328536066628 0.037842246446903385 0.3605796361298447 0 0 0 0 0) (-0.01704205086134636 0.0019318359054898756 -0.004804719580737934 0.330273729930529 0 0 0 0) (-0.02108689613057322 0.0016608740068908409 -0.021078956760960426 -0.017909695905700046 0.34387631175110994 0 0 0) (0.001721163137887059 0.010569424893254993 0.011566120390002804 0.0033702414678046903 -0.009384537210246166 0.3418301188423875 0 0) (0.001829470290606638 -0.006869042044209485 0.00854934349729806 -0.007572019774697034 -0.01335108732232222 -0.01738238804073887 0.3263989204875843 0) (-0.0010915722571826273 -0.012267484373725967 -0.012324899373403472 -0.007115252094033822 0.005058934254556774 -0.011723249082197826 -0.008911007688015681 0.3257484811896604)) 
; c-inv-sqrt ((2.800530403518114 0.16470506600204976 -0.1888007944417046 0.1407967371520952 0.16669610662946413 -0.009617256668958747 0.0022871422544457594 0.00864680073304392) (0 2.848732723098322 -0.29896986675649434 -0.02101211783916498 -0.03317960347223877 -0.07867096231738079 0.06174800993278326 0.09488398887002662) (0 0 2.773312466375389 0.04034528787227877 0.17209997716624853 -0.08951042901494531 -0.06943248689811135 0.0980178170208294) (0 0 0 3.0277915237471165 0.15769282036331483 -0.025522954028327223 0.07533179943931859 0.06482858366200249) (0 0 0 0 2.9080223493957265 0.07983627668197041 0.12320201734426509 -0.038918674767117606) (0 0 0 0 0 2.9254297526107824 0.15579388274275136 0.10954409370958469) (0 0 0 0 0 0 3.0637356229799124 0.08380997385073326) (0 0 0 0 0 0 0 3.06985314666063)) 
; new-p-sigma (-2.4829858808096215 1.1586145937897967 -1.9809189798007827 0.5176109997708597 0.041122990520034396 0.24881610019665987 -0.7911441607101299 0.28516545661664694) 
; new-step-size 0.12224638563351164)
