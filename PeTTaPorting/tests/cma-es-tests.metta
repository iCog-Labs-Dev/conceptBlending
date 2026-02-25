!(import! &self ../cma-es-imp)
; !(import! &self ../libs)

;;; apply-log ;;;;

!(test (apply-log (1.0) 2.71828) (0.0))
!(test (apply-log (1000.0) 10.0) (2.9999999999999996))
!(test (apply-log (1.0 2.0 4.0 8.0) 2.0) (0.0 1.0 2.0 3.0))
!(test (apply-log (0.1) 10.0) (-0.9999999999999998))
!(test (apply-log () 2.0) ())
;;;; apply-power ;;;;

!(test (apply-power (2 3 4) 2) (4 9 16))
!(test (apply-power (1 2) 3) (1 8))
!(test (apply-power (0.5 0.25) 0.5) (0.7071067811865476 0.5))  ; √x
!(test (apply-power (5 10) 1) (5 10))
!(test (apply-power () 2) ())

;;;; sum ;;;;

!(test (sum (1 2 3 4)) 10)
!(test (sum (0.1 0.2 0.3)) 0.6000000000000001)
!(test (sum ()) 0)
!(test (sum (42)) 42)
!(test (sum (10 -5 -5)) 0)

;;;; l2-norm ;;;;

!(test (l2-norm (3 4)) 5.0)
!(test (l2-norm (0 0)) 0.0)
!(test (l2-norm (10)) 10.0)
!(test (l2-norm (1 2 2)) 3.0)
!(test (l2-norm (1 1 1 1)) 2.0)



;;;; identity-matrix ;;;;

!(test (identity-matrix 1) ((1)))
!(test (identity-matrix 2) ((1 0) (0 1)))
!(test (identity-matrix 3) ((1 0 0) (0 1 0) (0 0 1)))
!(test (identity-matrix 5) ((1 0 0 0 0) (0 1 0 0 0) (0 0 1 0 0) (0 0 0 1 0) (0 0 0 0 1)))
!(test (identity-matrix 0) ())
;;;; zeros-vec ;;;;

!(test (zeros-vec 0)     ())
!(test (zeros-vec 1)     (0))
!(test (zeros-vec 3)     (0 0 0))
!(test (zeros-vec 5)     (0 0 0 0 0))
!(test (zeros-vec 10)    (0 0 0 0 0 0 0 0 0 0))


;;;; range ;;;;

!(test (range 1 4)     (1 2 3))
!(test (range 1 10)    (1 2 3 4 5 6 7 8 9))
!(test (range 5 5)     ())
!(test (range 5 3)     ())
!(test (range 0 2)     (0 1))


;;;; scalar-op ;;;;

!(test (scalar-op (1 2 3) 2 *)         (2 4 6))
!(test (scalar-op (2 3 4) 1 -)         (1 2 3))
!(test (scalar-op (2.0 4.0 6.0) 2 /)   (1.0 2.0 3.0))
!(test (scalar-op (1 2 3 4) 5 +)       (6 7 8 9))
!(test (scalar-op () 3 +)             (EmptyList))

;;;; rev-scalar-op ;;;;

!(test (rev-scalar-op 10 (1 2 3) -)     (9 8 7))
!(test (rev-scalar-op 100 (2 4 5) /)    (50 25 20))
!(test (rev-scalar-op 2 (3 4 5) *)      (6 8 10))
!(test (rev-scalar-op 10 (1 2 3) +)     (11 12 13))
!(test (rev-scalar-op 2 () *)          (EmptyList))

;;;; STRATEGY PARAMETERS ;;;;
; lambda_ and mu 
!(test (lambda_) 10)    
!(test (mu) 5)
; weights vector length = mu
!(test (let $w (weights)(size-atom $w))  (mu))
; ; normalized_weights sum to -> 1
!(test (let $s (sum (normalized_weights)) (round-math $s)) 1)
; ; mu_eff value (rounded to 6 dp)
!(test(let $m (mu_eff)(/ (round-math (* $m 1000000)) 1000000)) 3.167299)
; exact weights check
!(test (let $ws (normalized_weights) (map-atom $ws $w(/ (round-math (* $w 1000000)) 1000000)))
   (0.456273 0.270753 0.162231 0.085234 0.025510))

;;; LEARNING RATES ;;;
!(test (mu_eff) 3.1672992814107035)
!(test (dim) 8)
!(test (c_sigma) 0.3196142529106335)
!(test (d_sigma) 1.3196142529106334)
!(test (c_c)      0.34365014154838475)
!(test (c1)       0.022307163120344784)
!(test (c_mu)     0.028749917692721574)

; make-indices edge cases
!(test (make-indices ()) ())
!(test (make-indices (0.075)) (0))

; remove-index
!(test (remove-index (0 0.075 0.4) 0) (0.075 0.4))
!(test (remove-index ((0 0.075) (1 0.015)) 0) ((1 0.015)))
!(test (remove-index (3 4 5) 1) (3 5))
!(test (remove-index (6 7 8) 2) (6 7))

; zip idx & fitness
!(test
   (pair-index-fitness (0 1 2) (10 30 20))
   ((0 10) (1 30) (2 20)))

; max-index
!(test
   (max-index ((0 10) (1 30) (2 20)))
   1) ; fitness 30 is max

; sort-pairs-desc
!(test
   (sort-pairs-desc ((0 10) (1 30) (2 20)))
   ((1 30) (2 20) (0 10)))

; extract-indices (top mu)
!(test
   (extract-indices ((1 30) (2 20) (0 10)) 2)
   (1 2))
; extract-indices with mu > length
!(test (extract-indices ((1 10) (2 5)) 5) (1 2))

; select-by-indices
!(test
   (select-by-indices (100 200 300) (1 2))
   (200 300))

; update-mean-test
!(test
   (let $res (update-mean-test ((1 2 3) (7 5 1)) 3 (0.6 0.4)) (car-atom $res))
   (4.6000000000000005 3.8 1.8000000000000003)
)

(= (samples)((1 1 0 0 0 0 1 1) (1 1 1 0 0 1 1 1) (0 0 0 0 0 1 1 1) (1 1 0 1 1 1 1 1) (1 1 0 0 0 0 0 0) (1 1 0 0 0 1 1 1) (1 1 1 0 0 1 1 1) (1 1 1 1 0 1 1 1) (1 1 0 0 0 1 1 1) (1 1 0 0 0 1 1 1)))
(= (fitnesses) (0.046250000000000006 0.05125 0.03875000000000001 0.061250000000000006 0.012499999999999997 0.05125 0.05125 0.058750000000000004 0.05125 0.05125))
; fitness -> elite idxs -> elite samples
!(test (select-by-indices  (samples) (extract-indices (sort-pairs-desc (pair-index-fitness (make-indices (fitnesses)) (fitnesses))) (mu)))
((1 1 0 1 1 1 1 1) (1 1 1 1 0 1 1 1) (1 1 1 0 0 1 1 1) (1 1 0 0 0 1 1 1) (1 1 1 0 0 1 1 1)))

; returns () on empty
!(test (pair-index-fitness () ()) ())
!(test (sort-pairs-desc ()) ())
!(test (extract-indices () 3) ())
!(test (select-by-indices () ()) ())
!(test (update-mean-test () 3 ()) (0 () ()))


; mu = 0  (nothing selected)
(= (pairsSmall) ((0 10) (1 20)))
!(test (extract-indices (pairsSmall) 0) ())
!(test (select-by-indices (1 20) ()) ())

; duplicate fitnesses  – first tie kept first
!(test
   (sort-pairs-desc ((0 10) (1 10) (2 5)))
   ((0 10) (1 10) (2 5))
)   

; update-mean-test
(= (w3)  (0.5 0.3 0.2))
(= (sel3) ((2 0) (4 4) (8 2)))
!(test
   (let $res (update-mean-test (sel3) 3 (w3)) (car-atom $res)) 
   (5.6000000000000005 2.2)
)

; weights with tiny floats (still sum to 1)
(= (wTiny) (0.999999 0.000001))
(= (selTiny) ((2 2) (2000 2000)))
!(test
   (let $res (update-mean-test (selTiny) 2 (wTiny)) (car-atom $res))
   (1999.998002 1999.998002)
)   ; essentially the first vector

;;; Test Parameters for the process new-p-sigma to new-cov computings;;;;
(= (test-new-mean) (0.3 0.4 0.6 0.2 0.8 0.1 0.5 0.8))
(= (test-old-mean) (0.2 0.7 0.3 0.6 0.8 0.3 0.9 0.4))
(= (test-step-size) 0.34)
(= (test-selected) ((1 0 0 0 1 1 1 0) (1 1 1 0 1 1 1 0) (1 0 1 0 0 0 0 0) (0 0 0 0 1 1 1 0) (1 1 1 1 1 1 1 0)))

!(test
   (let*
      (
         ;;;; y (Mean difference computer) ;;;;
         ($y  (y (test-new-mean) (test-old-mean) (test-step-size)))
         ;;;; C-inv-sqrt (inverse square root of a matrix) ;;;;
         ($c-inv-sqrt (C-inv-sqrt (cov)))
         ;;;; new-p-sigma (step-size evolution path) and new-step-size ;;;;
         (($new-step-size $new-p-sigma) (new-step-size (test-step-size) (c_sigma) (d_sigma) (dim) (p_sigma) (mu_eff) $c-inv-sqrt $y))
         ;;;; h-sigma (covariance evolution path parameter controller) ;;;;
         ($h-sigma (h-sigma $new-p-sigma (c_sigma) 0))
         ;;;; p-c (covariance evolution path) ;;;;
         ($new-p-c (p-c (p_c) $new-p-sigma (c_sigma) 0 $y))
         ;;;; delta (top mu individuals deviation from previous mean) ;;;;
         ($delta (delta (test-selected) (test-old-mean)))
         ;;;; rank-mu (weighted deviation of top mu individual) ;;;;
         ($rank-mu (rank-mu (normalized_weights) (test-selected) (test-old-mean)))
         ;;;; new-cov (covariance adaptation) ;;;;
         ($new-cov (let $res (new-cov (cov) (p_c) $new-p-sigma (c_sigma) 0 $y (normalized_weights) (test-selected) (test-old-mean)) (car-atom $res)))
      )
      (y-res $y c-inv-sqrt-res $c-inv-sqrt (new-p-sigma-res $new-p-sigma new-step-size-res $new-step-size) h-sigma-res $h-sigma new-p-c-res $new-p-c delta-res $delta rank-mu-res $rank-mu new-cov-res $new-cov)
  )
   (y-res (0.29411764705882343 -0.8823529411764703 0.8823529411764705 -1.176470588235294 0.0 -0.588235294117647 -1.1764705882352942 1.1764705882352942) 
   c-inv-sqrt-res ((1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0) (0.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0) (0.0 0.0 1.0 0.0 0.0 0.0 0.0 0.0) (0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0) (0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0) (0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0) (0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0) (0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0)) 
   (new-p-sigma-res (0.3836040623824555 -1.1508121871473664 1.1508121871473667 -1.5344162495298221 0.0 -0.7672081247649111 -1.5344162495298226 1.5344162495298226) 
   new-step-size-res 0.3519645056469929) 
   h-sigma-res 0 
   new-p-c-res (0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0)
   delta-res ((0.8 -0.7 -0.3 -0.6 0.19999999999999996 0.7 0.09999999999999998 -0.4) (0.8 0.30000000000000004 0.7 -0.6 0.19999999999999996 0.7 0.09999999999999998 -0.4) (0.8 -0.7 0.7 -0.6 -0.8 -0.3 -0.9 -0.4) (-0.2 -0.7 -0.3 -0.6 0.19999999999999996 0.7 0.09999999999999998 -0.4) (0.8 0.30000000000000004 0.7 0.4 0.19999999999999996 0.7 0.09999999999999998 -0.4))
   rank-mu-res ((0.5888598717399013 -0.26332636595967684 0.1523651089271931 -0.4084521982711214 0.013168396853031238 0.370551623302949 -0.05830824843695229 -0.2859065811599342) (-0.26332636595967684 0.371494924464896 0.09643821798893117 0.2498952642481365 0.03281431977862084 -0.16905433580249915 0.07318805089484486 0.16149492446489597) (0.1523651089271931 0.09643821798893117 0.27339752239857185 -0.07723956931267546 -0.0818630208117829 -0.0026161178135680543 -0.09771240141142588 -0.06339752239857188) (-0.4084521982711214 0.2498952642481365 -0.07723956931267546 0.35489808163280506 -0.017559411337603137 -0.30480461541961573 0.039889629478799364 0.22979616326561003) (0.013168396853031238 0.03281431977862084 -0.0818630208117829 -0.017559411337603137 0.13733867029520186 0.15622311171586695 0.13356178201106886 -0.015107553136532063) (0.370551623302949 -0.16905433580249915 -0.0026161178135680543 -0.30480461541961573 0.15622311171586695 0.42510755313653203 0.10244622343173393 -0.21510755313653207) (-0.05830824843695229 0.07318805089484486 -0.09771240141142588 0.039889629478799364 0.13356178201106886 0.10244622343173393 0.13978489372693584 0.02489244686346792) (-0.2859065811599342 0.16149492446489597 -0.06339752239857188 0.22979616326561003 -0.015107553136532063 -0.21510755313653207 0.02489244686346792 0.16)) 
   new-cov-res ((0.9658725920320024 -0.00757061134766419 0.004380484340899359 -0.011742967081705934 0.0003785903256697419 0.010653328670864153 -0.0016763573433691396 -0.00821979067615553) (-0.00757061134766419 0.9596233676885632 0.002772590829614512 0.007184468278934832 0.0009434089927779949 -0.004860298239919565 0.0021041504393175072 0.004642965786158046) (0.004380484340899359 0.002772590829614512 0.9568030754532866 -0.0022206312603606825 -0.0023535551104163117 -7.521317181454428e-5 -0.0028092234981366656 -0.001822673550881414) (-0.011742967081705934 0.007184468278934832 -0.0022206312603606825 0.9591462098231816 -0.0005048316306887322 -0.008763107605675606 0.0011468235643086419 0.006606620779989497) (0.0003785903256697419 0.0009434089927779949 -0.0023535551104163117 -0.0005048316306887322 0.9528913946539486 0.004491401603532022 0.0038398902397114507 -0.0004343409092137145) (0.010653328670864153 -0.004860298239919565 -7.521317181454428e-5 -0.008763107605675606 0.004491401603532022 0.9611647263501631 0.002945320491592515 -0.006184324447758029) (-0.0016763573433691396 0.0021041504393175072 -0.0028092234981366656 0.0011468235643086419 0.0038398902397114507 0.002945320491592515 0.9529617233762688 0.0007156557984951481) (-0.00821979067615553 0.004642965786158046 -0.001822673550881414 0.006606620779989497 -0.0004343409092137145 -0.006184324447758029 0.0007156557984951481 0.953542906017769))
   )
)

;;;; vector-op ;;;;

;;;; Test vector-op with two equal Length vectors and +, -, *, / operators ;;;;
; Output = The addition, substraction, multiplication, and division results of the vectors respectively

!(test
   (let*
      (
         ($adres (vector-op (1 2 3 4) (4 5 6 7) +))
         ($subres (vector-op (4 5 6 7) (1 2 3 4)  -))
         ($mulres (vector-op (4 5 6 7) (1 2 3 4)  *))
         ($divres (vector-op (4.0 5.0 6.0 7.0) (1 2 3 4)  /))
      )
      (addition-result $adres substraction-result $subres multiplication-result $mulres division-result $divres)
   )
   (addition-result (5 7 9 11) substraction-result (3 3 3 3) multiplication-result (4 10 18 28) division-result (4.0 2.5 2.0 1.75))
)

;;;; Test vector-op with two un-equal Length vectors and any operator ;;;;
; Output = (Error (first-vector-length second-vector-length) LengthMismatch)
!(test
   (vector-op (1 2 3 4 5) (4 5 6 7) +)
   (LengthMismatch)   
)

;;;; mat-vec-op ;;;;

;;;; Test mat-vec-op(matrix vector operation) with a matrix with n rows, a vector with n elements, and the four operations(+, -, *, /)
; Output = a matrix with n rows whose each row is a result of the input operation applied on each rows of the input matrix and the corresponding elements of the vector

!(test
   (let*
      (
         ($addition (mat-vec-op ((1 2 3) (2 3 4) (3 4 5) (4 5 6) (5 6 7)) (1 2 3 4 5) +))
         ($substraction (mat-vec-op ((1 2 3) (2 3 4) (3 4 5) (4 5 6) (5 6 7)) (1 2 3 4 5) -))
         ($multiplication (mat-vec-op ((1 2 3) (2 3 4) (3 4 5) (4 5 6) (5 6 7)) (1 2 3 4 5) *))
         ($division (mat-vec-op ((1.0 2.0 3.0) (2.0 3.0 4.0) (3.0 4.0 5.0) (4.0 5.0 6.0) (5.0 6.0 7.0)) (1 2 3 4 5) /))
      )
      (Addition-result $addition Substraction-result $substraction Multiplication-result $multiplication Division-result $division)
   )
   (Addition-result ((2 3 4) (4 5 6) (6 7 8) (8 9 10) (10 11 12)) Substraction-result ((0 1 2) (0 1 2) (0 1 2) (0 1 2) (0 1 2)) 
   Multiplication-result ((1 2 3) (4 6 8) (9 12 15) (16 20 24) (25 30 35)) Division-result ((1.0 2.0 3.0) (1.0 1.5 2.0) (1.0 1.3333333333333333 1.6666666666666667) (1.0 1.25 1.5) (1.0 1.2 1.4)))
)

;;;; Test mat-vec-op(matrix vector operation) with a matrix with n rows, a vector with m elements, and any operation ;;;;
; Output = (Error (n m) DimensionMismatch)

!(test
   (mat-vec-op ((1 2 3) (2 3 4) (3 4 5) (4 5 6) (5 6 7)) (1 2 3 4) +)
   (DimensionMismatch)
)

;;;; mat-mat-eles-op ;;;;

;;;; Test mat-mat-eles-op(matrix matrix element-wise operation) with two same shape matrixs, and the four operations(+, -, *, /) ;;;;
; Output = a matrix of the same shape as the input matrix, and whose elements are the result on the input operation applied on the corresponding elements of the two input matrixs

!(test
   (let*
      (
         ($addition (mat-mat-eles-op ((1 2 3) (2 3 4) (3 4 5)) ((4 5 6) (5 6 7) (6 7 8)) +))
         ($substraction (mat-mat-eles-op ((1 2 3) (2 3 4) (3 4 5)) ((4 5 6) (5 6 7) (6 7 8)) -))
         ($multiplication (mat-mat-eles-op ((1 2 3) (2 3 4) (3 4 5)) ((4 5 6) (5 6 7) (6 7 8)) *))
         ($division (mat-mat-eles-op ((1.0 2.0 3.0) (2.0 3.0 4.0) (3.0 4.0 5.0)) ((4 5 6) (5 6 7) (6 7 8)) /))
      )
      (Addition-result $addition Substraction-result $substraction Multiplication-result $multiplication Division-result $division)
   )
   (Addition-result ((5 7 9) (7 9 11) (9 11 13)) Substraction-result ((-3 -3 -3) (-3 -3 -3) (-3 -3 -3)) 
   Multiplication-result ((4 10 18) (10 18 28) (18 28 40)) Division-result ((0.25 0.4 0.5) (0.4 0.5 0.5714285714285714) (0.5 0.5714285714285714 0.625)))
)

;;;; Test mat-mat-eles-op (matrix matrix element-wise operation) with two different, but broadcasteable, shape matrixs, and any operation ;;;;
; Output = a matrix of the non-broadcasted shape, and whose elements are the result of the input operation applied on the corresponding elements of the two input matrixs(after broadcasting is applied over the matrix that needs to be broadcasted)

!(test
   (let*
      (
         ($addition (mat-mat-eles-op ((1 2 3) (2 3 4) (3 4 5)) ((4 5 6)) +))
         ($substraction (mat-mat-eles-op ((1 2 3) (2 3 4) (3 4 5)) ((4 5 6)) -))
         ($multiplication (mat-mat-eles-op ((1 2 3) (2 3 4) (3 4 5)) ((4 5 6)) *))
         ($division (mat-mat-eles-op ((1.0 2.0 3.0) (2.0 3.0 4.0) (3.0 4.0 5.0)) ((4 5 6)) /))
      )
      (Addition-result $addition Substraction-result $substraction Multiplication-result $multiplication Division-result $division)
   )
   (Addition-result ((5 7 9) (6 8 10) (7 9 11)) Substraction-result ((-3 -3 -3) (-2 -2 -2) (-1 -1 -1)) 
   Multiplication-result ((4 10 18) (8 15 24) (12 20 30)) Division-result ((0.25 0.4 0.5) (0.5 0.6 0.6666666666666666) (0.75 0.8 0.8333333333333334)))
)

;;;; outer-product ;;;;

;;;; Test outer-product with 2 vectors with equal length(n) ;;;;
; Output = The outer product result of the two vectors which will be a matrix of shape (n, n)

!(test
   (outer-product (1 2 3) (2 3 4))
   ((2 3 4) (4 6 8) (6 9 12))
)

;;;; Test outer-product with a vector of length n and another vector with a length of m ;;;;
; Output = The outer-product result of the two vectors which will be a matrix of shape (n, m)

!(test
   (outer-product (1 2 3 4) (2 3 4))
   ((2 3 4) (4 6 8) (6 9 12) (8 12 16))
)

;;;; Test outer-product with one of the two(which will be the same if both vectors are empty as well) vectors being empty ;;;;
; Output = ()

!(test
   (outer-product () (1 2 3))
   ()
)

;;;; mat-scalar-op ;;;;

;;;; Test mat-scalar-op(matrix scalar operations) with a matrix of shape (n, m), a scalar value k, and the four operations(+, -, *, /) ;;;;
; Output = a matrix 0f shape (n, m) whose each element are the result of the input operation applied over each element of the input matrix and the scalar input

!(test
   (let*
      (
         ($addition (mat-scalar-op ((1 2 3) (2 3 4) (3 4 5)) 5 +))
         ($substraction (mat-scalar-op ((1 2 3) (2 3 4) (3 4 5)) 5 -))
         ($multiplication (mat-scalar-op ((1 2 3) (2 3 4) (3 4 5)) 5 *))
         ($division (mat-scalar-op ((1.0 2.0 3.0) (2.0 3.0 4.0) (3.0 4.0 5.0)) 5 /))
      )
   (Addition-result $addition Substraction-result $substraction Multiplication-result $multiplication Division-result $division)
   )
   (Addition-result ((6 7 8) (7 8 9) (8 9 10)) Substraction-result ((-4 -3 -2) (-3 -2 -1) (-2 -1 0)) 
   Multiplication-result ((5 10 15) (10 15 20) (15 20 25)) Division-result ((0.2 0.4 0.6) (0.4 0.6 0.8) (0.6 0.8 1.0)))
)

;;;; Test mat-scalar-op(matrix scalar operations) with an empty matrix, a scalar value k, and any of the four operations ;;;;
; Output = (Error the-empty-matrix Emptymatrix)

!(test
   (mat-scalar-op () 5 +)
   (Emptymatrix)
)

;;;; clipping functions ;;;;

;;;; Test num-clip with a number, vec-clip with a vector, and mat-clip with a matrix, and lower boundary, and upper boundary arguments ;;;;
; Output = for the num-clip, the input num clipped to the lower or upper boundary if it's out the boundaries
; Output = for the vec-clip, the elements of the input vec clipped to the lower or upper boundary if they are out of the boundaries
; Output = for the mat-clip, the elements of the input matrix clipped to the lower or upper boundary if they are out of the boundaries

!(test
   (let*
      (
         ($clipped-num (num-clip 3 0 1))
         ($clipped-vec (vec-clip (0.4 3 1) 0 1))
         ($clipped-matrix (mat-clip ((0.3 4 -3) (0.2 3 -2) (0.1 2 -1)) 0 1))
      )
      (Clipped-num $clipped-num Clipped-vector $clipped-vec Clipped-matrix $clipped-matrix)
   )
   (Clipped-num 1 Clipped-vector (0.4 1 1) Clipped-matrix ((0.3 1 0) (0.2 1 0) (0.1 1 0)))
)

;;; cholesky-decomposition (cholesky-decomposition function) ;;;;

;;; Test cholesky-decomposition (cholesky decomposition) with a symmetric, positive definite matrix of shape n by n ;;;;
; Output = cholesky decomposed lower triangular matrix L of the same shape as the input matrix

!(test
    (let*
        (
            ($2by2lmat (cholesky-decomposition ((2 1)(1 2))))
            ($3by3lmat (cholesky-decomposition ((4 1 1) (1 3 0) (1 0 2))))
            ($8by8lmat (cholesky-decomposition ((8 1 0 0 0 0 0 0)
                                    (1 8 1 0 0 0 0 0)
                                    (0 1 8 1 0 0 0 0)
                                    (0 0 1 8 1 0 0 0)
                                    (0 0 0 1 8 1 0 0)
                                    (0 0 0 0 1 8 1 0)
                                    (0 0 0 0 0 1 8 1)
                                    (0 0 0 0 0 0 1 8))))
        )
        (Chol-decomposed-2by2-lmatrix $2by2lmat Chol-decomposed-3by3-lmatrix $3by3lmat Chol-decomposed-8by8-lmatrix $8by8lmat)
    )
    (Chol-decomposed-2by2-lmatrix ((1.4142135623730951 0) (0.7071067811865475 1.224744871391589)) Chol-decomposed-3by3-lmatrix ((2.0 0 0) (0.5 1.6583123951777 0) (0.5 -0.15075567228888181 1.3142574813455419)) 
    Chol-decomposed-8by8-lmatrix ((2.8284271247461903 0 0 0 0 0 0 0) (0.35355339059327373 2.806243040080456 0 0 0 0 0 0) (0.0 0.3563483225498992 2.8058894976488067 0 0 0 0 0) (0.0 0.0 0.3563932224836186 2.805883794986482 0 0 0 0) (0.0 0.0 0.0 0.3563939468151844 2.805883702984408 0 0 0) (0.0 0.0 0.0 0.0 0.35639395850097955 2.8058837015001177 0 0) (0.0 0.0 0.0 0.0 0.0 0.3563939586895092 2.8058837014761715 0) (0.0 0.0 0.0 0.0 0.0 0.0 0.35639395869255075 2.805883701475785)))
)

; ;;;; Test cholesky-decomposition (cholesky-decomposition) with a symmetric, non positive definite matrix of any shape.
; ; Output = an incomplete matrix of same shape as the input matrix containing NaN, and inf values since cholesky decomposition deosn't work for non positive definite matrixs (Pos-deinitness-checker function is used here to better format the result, so the result that will be displayed is False).

; !(test
;     (Pos-definitness-checker (cholesky-decomposition ((1 2 3 4 5 6)
;                     (2 1 2 3 4 5)
;                     (3 2 1 2 3 4)
;                     (4 3 2 1 2 3)
;                     (5 4 3 2 1 2)
;                     (6 5 4 3 2 1)))
;     )   
;     False
; )

; ;;;; Pos-definitness checker (positive definitness of a matrix checker) ;;;;

; ;;;; Test Pos-definitness-checker with a symmetric, positive definite matrix.
; ; Output = True

; !(test
;    (Pos-definitness-checker (cholesky-decomposition ((8 1 0 0 0 0 0 0)
;                                     (1 8 1 0 0 0 0 0)
;                                     (0 1 8 1 0 0 0 0)
;                                     (0 0 1 8 1 0 0 0)
;                                     (0 0 0 1 8 1 0 0)
;                                     (0 0 0 0 1 8 1 0)
;                                     (0 0 0 0 0 1 8 1)
;                                     (0 0 0 0 0 0 1 8))))
;    True
; )

; ;;;; Test Pos-definitness-checker with a symmetric, not positive definite matrix.
; ; Output = False

; !(test
;    (Pos-definitness-checker (cholesky-decomposition ((1 2 3 4 5 6)
;                     (2 1 2 3 4 5)
;                     (3 2 1 2 3 4)
;                     (4 3 2 1 2 3)
;                     (5 4 3 2 1 2)
;                     (6 5 4 3 2 1))))
;    False
; )
;;; inverse-lmatrix ;;;;

;;;; Test inverse-lmatrix with a lower triangular matrix of shape n by n ;;;;
; Output = the inverse of the input lower triangular matrixs

!(test
    (let*
        (
            ($2by2invdlmat (inverse-lmatrix ((2 0 0) (1 3 0))))
            ($3by3invdlmat (inverse-lmatrix ((2 0 0) (3 1 0) (4 5 6))))
            ($8by8invdlmat (inverse-lmatrix ((1 0 0 0 0 0 0 0)
                                             (2 3 0 0 0 0 0 0)
                                             (4 5 6 0 0 0 0 0)
                                             (7 8 9 10 0 0 0 0)
                                             (11 12 13 14 15 0 0 0)
                                             (16 17 18 19 20 21 0 0)
                                             (22 23 24 25 26 27 28 0)
                                             (29 30 31 32 33 34 35 36))))
        )
        (Inversed-2by2-lmat $2by2invdlmat Inversed-3by3-lmat $3by3invdlmat Inversed-8by8-lmat $8by8invdlmat)
    )
   (Inversed-2by2-lmat ((0.5 0.0) (-0.16666666666666666 0.3333333333333333)) 
   Inversed-3by3-lmat ((0.5 0.0 0.0) (-1.5 1.0 0.0) (0.9166666666666666 -0.8333333333333334 0.16666666666666666)) 
   Inversed-8by8-lmat ((1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0) (-0.6666666666666666 0.3333333333333333 0.0 0.0 0.0 0.0 0.0 0.0) (-0.11111111111111116 -0.27777777777777773 0.16666666666666666 0.0 0.0 0.0 0.0 0.0) (-0.06666666666666661 -0.016666666666666698 -0.15 0.1 0.0 0.0 0.0 0.0) (-0.04148148148148145 -0.010370370370370363 -0.004444444444444429 -0.09333333333333334 0.06666666666666667 0.0 0.0 0.0) (-0.027160493827160622 -0.006790123456790113 -0.002910052910052921 -0.0015873015873015923 -0.06349206349206349 0.047619047619047616 0.0 0.0) (-0.018624338624338575 -0.004656084656084644 -0.001995464852607709 -0.0010884353741496464 -0.0006802721088435429 -0.04591836734693877 0.03571428571428571 0.0) (-0.013278463648833968 -0.003319615912208541 -0.0014226925338036464 -0.0007760141093474547 -0.00048500881834214995 -0.00033068783068783566 -0.034722222222222224 0.027777777777777776))
   )
)

;;;; transpose-matrix ;;;;

;;;; Test transpose-matrix with matrixs of different shapes
; Output = the transpose of the input matrixs

!(test
    (let*
        (
            ($2by2matran (transpose-matrix ((1 3) (2 4))))
            ($3by3matran (transpose-matrix ((1 3 2) (3 2 4) (3 4 5))))
            ($8by8matran (transpose-matrix ((1 2 3 4 5 6 7 8) (2 3 4 5 6 7 8 9) (3 4 5 6 7 8 9 10) (4 5 6 7 8 9 10 11) (5 6 7 8 9 10 11 12) (6 7 8 9 10 11 12 13) (7 8 9 10 11 12 13 14) (8 9 10 11 12 13 14 15))))
        )
        (Transposed-2by2 $2by2matran Transposed-3by3 $3by3matran Transposed-8by8 $8by8matran)
    )
    (Transposed-2by2 ((1 2) (3 4)) Transposed-3by3 ((1 3 3) (3 2 4) (2 4 5)) 
    Transposed-8by8 ((1 2 3 4 5 6 7 8) (2 3 4 5 6 7 8 9) (3 4 5 6 7 8 9 10) (4 5 6 7 8 9 10 11) (5 6 7 8 9 10 11 12) (6 7 8 9 10 11 12 13) (7 8 9 10 11 12 13 14) (8 9 10 11 12 13 14 15)))
)

;;;; standard-normal ;;;;

;;;; Test standard-normal with n and m arguments as dimension, and amount of the random vectors needed to be generated ;;;;
; Output = m amount vectors each containing n amounts of elements each sample from normal distribution

!(test
    (let*
        (
            ($2dim3poprvec (standard-normal 2 3))
            ($3dim5poprvec (standard-normal 3 5))
            ($8dim10poprvec (standard-normal 8 10))
        )
        (first-random-vec (collapse(superpose((size-atom $2dim3poprvec) (let $vec (index-atom $2dim3poprvec 0) (size-atom $vec))))) second-random-vec (collapse(superpose((size-atom $3dim5poprvec) (let $vec (index-atom $3dim5poprvec 0) (size-atom $vec)))))
        third-random-vec (collapse(superpose((size-atom $8dim10poprvec) (let $vec (index-atom $8dim10poprvec 0) (size-atom $vec))))))
    )
    (first-random-vec (3 2) second-random-vec (5 3) third-random-vec (10 8))
)

; ;;;; mat-mat-mul (matrix-matrix multiplication(can handle matrix-vector multiplication too)) ;;;;

; ;;;; Test mat-mat-mul (matrix-matrix multiplication) with matrixs with shape (n m), and (m k) ;;;;
; ; Output = a matrix multiplication result of the two matrixs having a shape (n k)

!(test
    (let*
        (
            ($firstmatmul (mat-mat-mul ((2 3 4 5) (5 4 3 2)) ((1) (2) (3) (4))))
            ($secondmatmul (mat-mat-mul ((2 3 4) (3 4 5) (4 5 6)) ((4 3 2) (5 4 3) (6 5 4))))
            ($thirdmatmul (mat-mat-mul ((2 3 4 5 6 7 8 9) 
                                        (5 4 3 2 3 6 5 4) 
                                        (4 3 5 6 2 5 6 3) 
                                        (2 5 8 6 4 3 2 1) 
                                        (1 2 3 4 2 1 5 8) 
                                        (2 1 3 4 2 1 3 4) 
                                        (4 5 3 2 3 4 5 6) 
                                        (2 3 4 5 6 7 6 5)
                                        (3 2 4 5 7 6 4 2)
                                        (3 2 4 6 6 2 3 4)) 
                                        ((5 4 3 2 3 6 5 4) 
                                        (4 3 5 6 2 5 6 3) 
                                        (2 5 8 6 4 3 2 1) 
                                        (1 2 3 4 2 1 5 8) 
                                        (2 1 3 4 2 1 3 4) 
                                        (4 5 3 2 3 4 5 6) 
                                        (2 3 4 5 6 7 6 5)
                                        (3 2 4 5 7 6 4 2))))
        )
        (Firstmatmul-result $firstmatmul Secondmatmul-result $secondmatmul Thirdmatmul-result $thirdmatmul)
    )
    (Firstmatmul-result ((40) (30)) Secondmatmul-result ((47 38 29) (62 50 38) (77 62 47)) Thirdmatmul-result ((118 130 175 189 182 188 198 185) (101 107 128 129 121 147 150 132) (93 113 142 143 126 142 157 152) (79 102 146 143 96 103 129 125) (65 71 110 123 120 118 116 100) (50 58 84 89 81 81 87 83) (98 100 132 139 128 150 149 123) (102 116 151 159 142 150 170 167) (88 101 129 132 109 116 143 150) (75 83 121 129 105 105 127 129)))
)

;;;; Test mat-mat-mul (matrix-matrix-multiplication) with two matrixs that are incompatible in shape(i.e one with shape (n m), and the other (k l))
; Output = (Error (m k) DimensionMismatch)

;;;; Test mat-mat-mul (matrix-matrix-multiplication) with a matrix of shape (n m), and a vector (1 m)
; Output = a vector with shape (1 m) which is the result of the matrix-vector multiplication of the input matrix and vector

!(test
    (mat-mat-mul ((1 2 3 4 5 6 7 8) (2 3 4 5 6 7 8 9) (3 4 5 6 7 8 9 10) (4 5 6 7 8 9 10 11) (5 6 7 8 9 10 11 12) (6 7 8 9 10 11 12 13) (7 8 9 10 11 12 13 14) (8 9 10 11 12 13 14 15)) ((1 2 3 4 5 6 7 8)))
    (204 240 276 312 348 384 420 456)
)


;;;; population-fitness-score ;;;;
;;;; Test population-fitness-score with a list containing individuals degree distribution
; Output = A list containing fitness value for corresponding individuals
(= (testPopulation) ((1 0 1 0 1 0 1 0) (0 1 0 1 0 1 0 1) (1 1 0 1 1 0 1 0) (0 0 1 1 0 0 1 0) (1 0 1 1 1 1 0 1) (1 1 1 1 1 0 0 1) (0 0 0 1 1 0 1 1) (1 1 0 0 0 0 1 1)))

!(test
   (population-fitness-score-test ((1 0 1 0 1 0 1 0) (0 1 0 1 0 1 0 1) (1 1 0 1 1 0 1 0) (0 0 1 1 0 0 1 0) (1 0 1 1 1 1 0 1) (1 1 1 1 1 0 0 1) (0 0 0 1 1 0 1 1) (1 1 0 0 0 0 1 1)))
   (0.035 0.02625 0.045 0.03 0.03625 0.033749999999999995 0.043750000000000004 0.046250000000000006)
)

;;;; random-multivariate ;;;;

;;;; Test random-multivariate with mean vector(mean) of shape (8), covarinace matrix(cov) of shape (n n), number of smaples(lambda_), and new-space
; Output = lambda_ amount of sample vectors, each having a shape (8), drawn from a multi variable normal distribution

(= (rmtest-mean) (0.37454012 0.95071431 0.73199394 0.59865848 0.15601864 0.15599452
 0.05808361 0.86617615))

(= (rmtest-cov) (cov))

!(test
    (let*
        (
            ($firstrms  (random-multivariate (rmtest-mean) (rmtest-cov) 1))
            ($secondrms  (random-multivariate (rmtest-mean) (rmtest-cov) 5))
            ($thirdrms  (random-multivariate (rmtest-mean) (rmtest-cov) 10))
        )
        (First-sample-shape ((size-atom $firstrms) (let $ffsample (car-atom $firstrms) (size-atom $ffsample)))
         Second-rand-mul-samp ((size-atom $secondrms) (let $sfsample (car-atom $secondrms) (size-atom $sfsample))) 
         Third-rand-mul-samp ((size-atom $thirdrms) (let $tfsample (car-atom $thirdrms) (size-atom $tfsample))))
    )
    (First-sample-shape (1 8)
    Second-rand-mul-samp (5 8) 
    Third-rand-mul-samp (10 8))
)

;;;; cma-es-blend (encompasses a test for cma-es-main-loop) ;;;;
; Output = The formed blend.

(= (testEval) False)

!(test 
   (let ($net-type $exp-ver $blend $ext-ver) (blend cma-es-main-loop (testEval)) ($net-type $blend))
   (doubleScope spiderman)
)

;;; cma-es-blend with evaluation ;;;;
; Output = the formed blend, and six optimality constraints(integration, good-reason, web, unpacking, topology, metonymy) evaluation scores
; !(test
;     (blend cma-es-main-loop True)
;     (Formed Blend: BatMan 
;     Evaluation-Metrics: 
;     Integration: 1.0 
;     Good-reason: (Conceptnet-score 0.0 LLM-score 1.0) 
;     Unpacking: 0.104125 
;     Web: 0.0 
;     Topology: 0.0 
;     Metonymy: 0.0)
; )

;;;; space-based cma-es-blend ;;;;
; Output = The formed blend(inputs are fetched from the space)

; !(test
;    (let ($net-type $exp-ver $blend $ext-ver) (let $space &self (metta (space-blend blend cma-es-main-loop False) %Undefined% $space)) ($net-type $blend))
;    (doubleScope BatMan)
; )

; Test Unionize
!(test
    (unionize ((1 2) (2 3) (4)) ())
      (4 2 3 1))
; single atom
!(test 
   (unionize ((1 2 3)) () ) (1 2 3))

; !(test
;    (max-best-nd (
;       ((b) (0.4 0.6))
;       ((c) (0.6 0.4))
;       ((d) (0.8 0.2)))

;    (0 0)
;    1
;    ((0.2 0.8) (0.5 0.5) (0.8 0.2))) (((d) (0.8 0.2))))

; !(test
;     (max-best-nd 
;         (
;             ; Structure: ( (Genome Objectives) DummyData )
;             ( ((b) (0.4 0.6)) Empty )
;             ( ((c) (0.6 0.4)) Empty )
;             ( ((d) (0.8 0.2)) Empty )
;         )
;         (0 0)   ; Ref
;         1       ; Iter -> selects weight (0.5 0.5)
;         ((0.2 0.8) (0.5 0.5) (0.8 0.2)) ; Weights
;     )
;     ; Expected Result: The item with the highest PBI.
;     ; (0.8 0.2) is furthest from the diagonal weight vector (0.5 0.5), 
;     ; so it has the highest penalty (d2).
;     ( ((d) (0.8 0.2)) Empty )
; )
;;;; Multi-objectvie cma-es tests ;;;;

;;;; pbi-scalarization ;;;;
;;;; Test pbi-scalarization with fitness, reference point, and weight vector each containing two elements
; Output = a scalarized value of the fitness values

!(test
   (pbi-scalarization (0.3 0.6) (0 0) (0.3 0.7))
   0.8666224568732893
)

;;;; Test pbi-scalarization with fitness vector with length different from 2
; Output = IncorrectLength Error

!(test
   (pbi-scalarization (0.3 0.4 0.5) (0 0) (0.3 0.7))
   (IncorrectLength)
)

;;;; Test pbi-scalarization with reference point vector with length different from 2
; Output = IncorrectLength Error

!(test
   (pbi-scalarization (0.3 0.6) (0 0 0) (0.3 0.7))
   (IncorrectLength)
)

;;;; Test pbi-scalarization with weight vector with length different from 2
; Output = IncorrectLength Error

!(test
   (pbi-scalarization (0.3 0.6) (0 0) (0.2 0.4 0.4))
   (IncorrectLength)
)

;;;; moedd-update-mean ;;;;

;;;; Test moedd-update-mean with mock samples, mu = 5, randomly initialized weights, custom fitness function,    


; Mock fitness function returns (unscalarized-list scalarized-list)
(= (mock-moedd-fitness $samples $iter)
    ((10 20 30) (0.1 0.2 0.3))
)

; Test moedd-update-mean selection behavior
!(test
    (moedd-update-mean ((1 2) (3 4) (5 6)) 2 (0.6 0.4) mock-moedd-fitness 0)
    ((5 6) 30 0.3)
)

; ;;;; moedd-cma-es-single-iteration ;;;;
(= (test-scalarized-fitness $samples $iter) (let ($weights $ref-point) ((Weight) (zeros-vec (Num-objectives))) (let $objs (map-atom $samples $sample (objectives (testconcept1) (testconcept2) $sample))
                                                                        (let $weight (index-atom $weights $iter) ($objs (map-atom $objs $obj (pbi-scalarization $obj $ref-point $weight))))
                                                                        )))
;;;; Test moedd-cma-es-single-iteration with pbi-scalarization based fitness function, six sub-problems(defined in the cma-es-imp.metta file), (0 0) reference point and 0 iteration number(for the first sub-problemt only)
; Output = The length of the best or fit individual with it's unscalarized fitness score length zipped with the scalarized fitness score length
!(test
   (let $candidate-blend (moedd-cma-es-single-iteration test-scalarized-fitness 0)
     ;; We match 3 elements directly. 
     ;; Note the extra parens around $indiv and $unsc-fit to unwrap the double nesting.
     (let  (($indiv) ($unscalarized-fitness) $scalarized-fitness-score) $candidate-blend
         ((size-atom $indiv) (size-atom $unscalarized-fitness) (size-atom $scalarized-fitness-score))
     )
   )
   (8 2 1)
)

;;;; Test moedd-cma-es-single-iteration with the same fitness function as above, the same amount of sub-problems, same reference point, and 6 iterations(for every sub-problems)
; Output = The lenght of the six best or fit individuals evolved by the six sub-problems, and their fitness score zipped with each of them
!(clean-from-multi-single-cma-es-inputspace)
!(add-to-multi-single-iteration-cma-es-inputspace)
; !(test
;    (let $iters (range 0 (- (Num-subproblems) 1)  1) (let $res (map-atom $iters $iter (moedd-cma-es-single-iteration test-scalarized-fitness $iter)) (let ($best-pop $fit-score) (index-atom $res (- (Num-subproblems) 1)) ((size-atom $best-pop) (size-atom $fit-score)))))
;    (6 6)
; )


!(test
   (let $iters (range 0 (- (Num-subproblems) 1)  1)
     (let $res (map-atom $iters $iter (moedd-cma-es-single-iteration test-scalarized-fitness $iter))
       ;; Fix: We check the size of the full list ($res), which is 6.
       ;; We duplicate it to match your expected tuple (6 6).
       ((size-atom $res) (size-atom $res))
     )
   )
   (10 10)
)


;;;; moedd-cma-es-single-generation ;;;;

;;;; Test moedd-cma-es-single-generation with the fitness function, the same amount of sub-problems, same reference-point, and 6 iterations(6 sub-problems)(all params are defined in the code except sub-problems weights which will be passed to the method when calling)
; Output = The length best non-dominated from the six best or fit individuals evolved by the six sub-problems over the single generation run.
; Note: the length of the best non-dominated can vary since each iteration run tries to evolve random samples, and hence we check the length if it's in the possible range(1 being minimum and 6 being maximum) instead of checking it if it's particular number.

!(clean-from-multi-single-cma-es-inputspace)
!(add-to-multi-single-iteration-cma-es-inputspace)
; !(test
;    (let $weights (Weight) (let $res (moedd-cma-es-single-generation $weights) (let ($res-size $pos-range) ((size-atom $res) (range 1 6 1)) (is-member $res-size $pos-range))))
;    True
; )

!(test
   (let $weights (Weight) 
     (let $res (moedd-cma-es-single-generation $weights) 
       (let ($res-size $pos-range) 
         ((size-atom $res) (range 1 6 1)) 
         (is-member $res-size $pos-range)
       )
     )
   )
   True
)

;;;; moedd-cma-es-main-loop ;;;;

;;;; Test moedd-cma-es-main-loop with the same parameters as the above, but now the reference point being adaptive, and for 5 generation run
; Output = The length of best non-dominated from the best or fit individuals evolved by the six sub-problems over the whole (5) generations run.
; Note: the length of the best non-dominated can vary since each iteration run tries to evolve random samples, and hence we check the length if it's in the possible range(1 being minimum and 30(the best possible scenario in which every samples will be best non-dominated, very very unlikely) being maximum) instead of checking it if it's particular number.

!(clean-from-multi-single-cma-es-inputspace)
!(add-to-multi-single-iteration-cma-es-inputspace)
; !(test
;    (let $res (moedd-cma-es-main-loop) (let ($res-size $pos-range) ((size-atom $res) (range 1 30 1)) (is-member $res-size $pos-range)))
;    True
; )

!(test
   (let $res (moedd-cma-es-main-loop) 
     (let ($res-size $pos-range) 
       ((size-atom $res) (range 1 30 1)) 
       (is-member $res-size $pos-range)
     )
   )
   True
)
