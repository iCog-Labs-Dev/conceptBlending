! (register-module! ../../an_infotheoretic_approach)
; !(import! &self an_infotheoretic_approach:utils:cma-es-utils)
!(import! &self an_infotheoretic_approach:cma-es-imp)



;;;; apply-log ;;;;

!(assertEqual (apply-log (1.0) 2.71828) (0.0))
!(assertEqual (apply-log (1000.0) 10.0) (2.9999999999999996))
!(assertEqual (apply-log (1.0 2.0 4.0 8.0) 2.0) (0.0 1.0 2.0 3.0))
!(assertEqual (apply-log (0.1) 10.0) (-0.9999999999999998))
!(assertEqual (apply-log () 2.0) ())
;;;; apply-power ;;;;

!(assertEqual (apply-power (2 3 4) 2) (4 9 16))
!(assertEqual (apply-power (1 2) 3) (1 8))
!(assertEqual (apply-power (0.5 0.25) 0.5) (0.7071067811865476 0.5))  ; √x
!(assertEqual (apply-power (5 10) 1) (5 10))
!(assertEqual (apply-power () 2) ())

;;;; sum ;;;;

!(assertEqual (sum (1 2 3 4)) 10)
!(assertEqual (sum (0.1 0.2 0.3)) 0.6000000000000001)
!(assertEqual (sum ()) 0)
!(assertEqual (sum (42)) 42)
!(assertEqual (sum (10 -5 -5)) 0)

;;;; l2-norm ;;;;

!(assertEqual (l2-norm (3 4)) 5.0)
!(assertEqual (l2-norm (0 0)) 0.0)
!(assertEqual (l2-norm (10)) 10.0)
!(assertEqual (l2-norm (1 2 2)) 3.0)
!(assertEqual (l2-norm (1 1 1 1)) 2.0)



;;;; identity-matrice ;;;;

!(assertEqual (identity-matrice 1) ((1)))
!(assertEqual (identity-matrice 2) ((1 0) (0 1)))
!(assertEqual (identity-matrice 3) ((1 0 0) (0 1 0) (0 0 1)))
!(assertEqual (identity-matrice 5) ((1 0 0 0 0) (0 1 0 0 0) (0 0 1 0 0) (0 0 0 1 0) (0 0 0 0 1)))
!(assertEqual (identity-matrice 0) ())
;;;; zeros-vec ;;;;

!(assertEqual (zeros-vec 0)     ())
!(assertEequal (zeros-vec 1)     (0))
!(assertEqual (zeros-vec 3)     (0 0 0))
!(assertEqual (zeros-vec 5)     (0 0 0 0 0))
!(assertEqual (zeros-vec 10)    (0 0 0 0 0 0 0 0 0 0))


;;;; range ;;;;

!(assertEqual (range 1 4)     (1 2 3))
!(assertEqual (range 1 10)    (1 2 3 4 5 6 7 8 9))
!(assertEqual (range 5 5)     ())
!(assertEqual (range 5 3)     ())
!(assertEqual (range 0 2)     (1 2))


;;;; scalar-op ;;;;

!(assertEqual (scalar-op (1 2 3) 2 *)         (2 4 6))
!(assertEqual (scalar-op (2 3 4) 1 -)         (1 2 3))
!(assertEqual (scalar-op (2.0 4.0 6.0) 2 /)   (1.0 2.0 3.0))
!(assertEqual (scalar-op (1 2 3 4) 5 +)       (6 7 8 9))
!(assertEqual (scalar-op () 3 +)             (Error () EmptyList))

;;;; rev-scalar-op ;;;;

!(assertEqual (rev-scalar-op 10 (1 2 3) -)     (9 8 7))
!(assertEqual (rev-scalar-op 100 (2 4 5) /)    (50.0 25.0 20.0))
!(assertEqual (rev-scalar-op 2 (3 4 5) *)      (6 8 10))
!(assertEqual (rev-scalar-op 10 (1 2 3) +)     (11 12 13))
!(assertEqual (rev-scalar-op 2 () *)          (Error () EmptyList))

;;;; STRATEGY PARAMETERS ;;;;
; lambda_ and mu 
!(assertEqual (lambda_) 10)    
!(assertEqual (mu) 5)
; weights vector length = mu
!(assertEqual (let $w (weights)(size-atom $w))  (mu))
; ; normalized_weights sum to -> 1
!(assertEqual (let $s (sum (normalized_weights)) (round-math $s)) 1.0)
; ; mu_eff value (rounded to 6 dp)
!(assertEqual(let $m (mu_eff)(/ (round-math (* $m 1000000)) 1000000)) 3.167299)
; exact weights check
!(assertEqual (let $ws (normalized_weights) (map-atom $ws $w(/ (round-math (* $w 1000000)) 1000000)))
   (0.456273 0.270753 0.162231 0.085234 0.025510))

;;; LEARNING RATES ;;;
!(assertEqual (mu_eff) 3.1672992814107035)
!(assertEqual (dim) 8)
!(assertEqual (c_sigma) 0.3196142529106335)
!(assertEqual (d_sigma) 1.3196142529106334)
!(assertEqual (c_c)      0.34365014154838475)
!(assertEqual (c1)       0.022307163120344784)
!(assertEqual (c_mu)     0.028749917692721574)

;;;; cma-es-main-loop ;;;;
!(assertEqual 
    (let $x (cma-es-main-loop) ((size-atom $x) (let $y (car-atom $x) (size-atom $y)) (let $z (car-atom $x) (let $s (car-atom $z) (size-atom $s)))))
    (30 5 8)
)

; make-indices edge cases
!(assertEqual (make-indices ()) ())
!(assertEqual (make-indices (0.075)) (0))

; remove-index
!(assertEqual (remove-index (0 0.075 0.4) 0) (0.075 0.4))
!(assertEqual (remove-index ((0 0.075) (1 0.015)) 0) ((1 0.015)))
!(assertEqual (remove-index (3 4 5) 1) (3 5))
!(assertEqual (remove-index (6 7 8) 2) (6 7))

; zip idx & fitness
!(assertEqual
   (pair-index-fitness (0 1 2) (10 30 20))
   ((0 10) (1 30) (2 20)))

; max-index
!(assertEqual
   (max-index ((0 10) (1 30) (2 20)))
   1) ; fitness 30 is max

; sort-pairs-desc
!(assertEqual
   (sort-pairs-desc ((0 10) (1 30) (2 20)))
   ((1 30) (2 20) (0 10)))

; extract-indices (top mu)
!(assertEqual
   (extract-indices ((1 30) (2 20) (0 10)) 2)
   (1 2))
; extract-indices with mu > length
!(assertEqual (extract-indices ((1 10) (2 5)) 5) (1 2))

; select-by-indices
!(assertEqual
   (select-by-indices (100 200 300) (1 2))
   (200 300))

; update-mean
!(assertEqual
   (let $res (update-mean ((1 2 3) (7 5 1)) 3 (0.6 0.4)) (car-atom $res))
   (4.6000000000000005 3.8 1.8000000000000003))

(= (samples)((1 1 0 0 0 0 1 1) (1 1 1 0 0 1 1 1) (0 0 0 0 0 1 1 1) (1 1 0 1 1 1 1 1) (1 1 0 0 0 0 0 0) (1 1 0 0 0 1 1 1) (1 1 1 0 0 1 1 1) (1 1 1 1 0 1 1 1) (1 1 0 0 0 1 1 1) (1 1 0 0 0 1 1 1)))
(= (fitnesses) (0.046250000000000006 0.05125 0.03875000000000001 0.061250000000000006 0.012499999999999997 0.05125 0.05125 0.058750000000000004 0.05125 0.05125))
; fitness -> elite idxs -> elite samples
!(assertEqual (select-by-indices  (samples) (extract-indices (sort-pairs-desc (pair-index-fitness (make-indices (fitnesses)) (fitnesses))) (mu)))
((1 1 0 1 1 1 1 1) (1 1 1 1 0 1 1 1) (1 1 1 0 0 1 1 1) (1 1 0 0 0 1 1 1) (1 1 1 0 0 1 1 1)))


; returns () on empty
!(assertEqual (pair-index-fitness () ()) ())
!(assertEqual (sort-pairs-desc ()) ())
!(assertEqual (extract-indices () 3) ())
!(assertEqual (select-by-indices () ()) ())
!(assertEqual (update-mean () 3 ()) (0.0 () ()))   


; mu = 0  (nothing selected)
(= (pairsSmall) ((0 10) (1 20)))
!(assertEqual (extract-indices (pairsSmall) 0) ())
!(assertEqual (select-by-indices (1 20) ()) ())

; duplicate fitnesses  – first tie kept first
!(assertEqual
   (sort-pairs-desc ((0 10) (1 10) (2 5)))
   ((0 10) (1 10) (2 5)))   

; update-mean
(= (w3)  (0.5 0.3 0.2))
(= (sel3) ((2 0) (4 4) (8 2)))
!(assertEqual
   (let $res (update-mean (sel3) 3 (w3)) (car-atom $res)) 
   (4.800000000000001 2.6))   

; weights with tiny floats (still sum to 1)
(= (wTiny) (0.999999 0.000001))
(= (selTiny) ((2 2) (2000 2000)))
!(assertEqual
   (let $res (update-mean (selTiny) 2 (wTiny)) (car-atom $res))
   (1999.998002 1999.998002))   ; essentially the first vector

;;; Test Parameters for the process new-p-sigma to new-cov computings;;;;
(= (test-new-mean) (0.3 0.4 0.6 0.2 0.8 0.1 0.5 0.8))
(= (test-old-mean) (0.2 0.7 0.3 0.6 0.8 0.3 0.9 0.4))
(= (test-step-size) 0.34)
(= (test-selected) ((1 0 0 0 1 1 1 0) (1 1 1 0 1 1 1 0) (1 0 1 0 0 0 0 0) (0 0 0 0 1 1 1 0) (1 1 1 1 1 1 1 0)))

!(assertEqual
   (let*
      (
         ;;;; y (Mean difference computer) ;;;;
         ($y  (y (test-new-mean) (test-old-mean) (test-step-size)))
         ;;;; C-inv-sqrt (inverse square root of a matrice) ;;;;
         ($c-inv-sqrt (C-inv-sqrt (cov)))
         ;;;; new-p-sigma (step-size evolution path) and new-step-size ;;;;
         (($new-step-size $new-p-sigma) (new-step-size (test-step-size) (c_sigma) (d_sigma) (dim) (p_sigma) (mu_eff) $c-inv-sqrt ($y)))
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
      (y $y c-inv-sqrt $c-inv-sqrt (new-p-sigma $new-p-sigma new-step-size $new-step-size) h-sigma $h-sigma new-p-c $new-p-c delta $delta rank-mu $rank-mu new-cov $new-cov)
  )
  (y (0.29411764705882343 -0.8823529411764703 0.8823529411764705 -1.176470588235294 0.0 -0.588235294117647 -1.1764705882352942 1.1764705882352942) c-inv-sqrt ((1 0 0 0 0 0 0 0) (0 1 0 0 0 0 0 0) (0 0 1 0 0 0 0 0) (0 0 0 1 0 0 0 0) (0 0 0 0 1 0 0 0) (0 0 0 0 0 1 0 0) (0 0 0 0 0 0 1 0) (0 0 0 0 0 0 0 1))
  (new-p-sigma (0.3836040623824555 -1.1508121871473664 1.1508121871473667 -1.5344162495298221 0.0 -0.7672081247649111 -1.5344162495298226 1.5344162495298226) new-step-size 0.3519645056469929)
  h-sigma 0 new-p-c (0 0 0 0 0 0 0 0) delta ((0.8 -0.7 -0.3 -0.6 0.19999999999999996 0.7 0.09999999999999998 -0.4) (0.8 0.30000000000000004 0.7 -0.6 0.19999999999999996 0.7 0.09999999999999998 -0.4) (0.8 -0.7 0.7 -0.6 -0.8 -0.3 -0.9 -0.4) (-0.2 -0.7 -0.3 -0.6 0.19999999999999996 0.7 0.09999999999999998 -0.4) (0.8 0.30000000000000004 0.7 0.4 0.19999999999999996 0.7 0.09999999999999998 -0.4))
  rank-mu ((0.5888598717399013 -0.26332636595967684 0.1523651089271931 -0.4084521982711214 0.013168396853031238 0.370551623302949 -0.05830824843695229 -0.2859065811599342) (-0.26332636595967684 0.371494924464896 0.09643821798893117 0.2498952642481365 0.03281431977862084 -0.16905433580249915 0.07318805089484486 0.16149492446489597) (0.1523651089271931 0.09643821798893117 0.27339752239857185 -0.07723956931267546 -0.0818630208117829 -0.0026161178135680543 -0.09771240141142588 -0.06339752239857188) (-0.4084521982711214 0.2498952642481365 -0.07723956931267546 0.35489808163280506 -0.017559411337603137 -0.30480461541961573 0.039889629478799364 0.22979616326561003) (0.013168396853031238 0.03281431977862084 -0.0818630208117829 -0.017559411337603137 0.13733867029520186 0.15622311171586695 0.13356178201106886 -0.015107553136532063) (0.370551623302949 -0.16905433580249915 -0.0026161178135680543 -0.30480461541961573 0.15622311171586695 0.42510755313653203 0.10244622343173393 -0.21510755313653207) (-0.05830824843695229 0.07318805089484486 -0.09771240141142588 0.039889629478799364 0.13356178201106886 0.10244622343173393 0.13978489372693584 0.02489244686346792) (-0.2859065811599342 0.16149492446489597 -0.06339752239857188 0.22979616326561003 -0.015107553136532063 -0.21510755313653207 0.02489244686346792 0.16))
  new-cov ((0.9658725920320024 -0.00757061134766419 0.004380484340899359 -0.011742967081705934 0.0003785903256697419 0.010653328670864153 -0.0016763573433691396 -0.00821979067615553) (-0.00757061134766419 0.9596233676885632 0.002772590829614512 0.007184468278934832 0.0009434089927779949 -0.004860298239919565 0.0021041504393175072 0.004642965786158046) (0.004380484340899359 0.002772590829614512 0.9568030754532866 -0.0022206312603606825 -0.0023535551104163117 -7.521317181454428e-5 -0.0028092234981366656 -0.001822673550881414) (-0.011742967081705934 0.007184468278934832 -0.0022206312603606825 0.9591462098231816 -0.0005048316306887322 -0.008763107605675606 0.0011468235643086419 0.006606620779989497) (0.0003785903256697419 0.0009434089927779949 -0.0023535551104163117 -0.0005048316306887322 0.9528913946539486 0.004491401603532022 0.0038398902397114507 -0.0004343409092137145) (0.010653328670864153 -0.004860298239919565 -7.521317181454428e-5 -0.008763107605675606 0.004491401603532022 0.9611647263501631 0.002945320491592515 -0.006184324447758029) (-0.0016763573433691396 0.0021041504393175072 -0.0028092234981366656 0.0011468235643086419 0.0038398902397114507 0.002945320491592515 0.9529617233762688 0.0007156557984951481) (-0.00821979067615553 0.004642965786158046 -0.001822673550881414 0.006606620779989497 -0.0004343409092137145 -0.006184324447758029 0.0007156557984951481 0.953542906017769))
  )
)

;;;; vector-op ;;;;

;;;; Test vector-op with two equal Length vectors and +, -, *, / operators ;;;;
; Output = The addition, substraction, multiplication, and division results of the vectors respectively

!(assertEqual
   (let*
      (
         ($adres (vector-op (1 2 3 4) (4 5 6 7) +))
         ($subres (vector-op (4 5 6 7) (1 2 3 4)  -))
         ($mulres (vector-op (4 5 6 7) (1 2 3 4)  *))
         ($divres (vector-op (4.0 5.0 6.0 7.0) (1 2 3 4)  /))
      )
      (addition-result $adres substraction-result $subres multiplication-result $mulres division-result $divres)
   )
   (addition-result (5 7 9 11) substraction-result (3 3 3 3) multiplication-result (4 10 18 28) division-result (4 2.5 2 1.75))   
)

;;;; Test vector-op with two un-equal Length vectors and any operator ;;;;
; Output = (Error (first-vector-length second-vector-length) LengthMismatch)
!(assertEqual
   (vector-op (1 2 3 4 5) (4 5 6 7) +)
   (Error (5 4) LengthMismatch)   
)

;;;; mat-vec-op ;;;;

;;;; Test mat-vec-op(matrice vector operation) with a matrice with n rows, a vector with n elements, and the four operations(+, -, *, /)
; Output = a matrice with n rows whose each row is a result of the input operation applied on each rows of the input matrice and the corresponding elements of the vector

!(assertEqual
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

;;;; Test mat-vec-op(matrice vector operation) with a matrice with n rows, a vector with m elements, and any operation ;;;;
; Output = (Error (n m) DimensionMismatch)

!(assertEqual
   (mat-vec-op ((1 2 3) (2 3 4) (3 4 5) (4 5 6) (5 6 7)) (1 2 3 4) +)
   (Error (5 4) DimensionMismatch)
)

;;;; mat-mat-eles-op ;;;;

;;;; Test mat-mat-eles-op(matrice matrice element-wise operation) with two same shape matrices, and the four operations(+, -, *, /) ;;;;
; Output = a matrice of the same shape as the input matrice, and whose elements are the result on the input operation applied on the corresponding elements of the two input matrices

!(assertEqual
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

;;;; Test mat-mat-eles-op (matrice matrice element-wise operation) with two different, but broadcasteable, shape matrices, and any operation ;;;;
; Output = a matrice of the non-broadcasted shape, and whose elements are the result of the input operation applied on the corresponding elements of the two input matrices(after broadcasting is applied over the matrice that needs to be broadcasted)

!(assertEqual
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
; Output = The outer product result of the two vectors which will be a matrice of shape (n, n)

!(assertEqual
   (outer-product (1 2 3) (2 3 4))
   ((2 3 4) (4 6 8) (6 9 12))
)

;;;; Test outer-product with a vector of length n and another vector with a length of m ;;;;
; Output = The outer-product result of the two vectors which will be a matrice of shape (n, m)

!(assertEqual
   (outer-product (1 2 3 4) (2 3 4))
   ((2 3 4) (4 6 8) (6 9 12) (8 12 16))
)

;;;; Test outer-product with one of the two(which will be the same if both vectors are empty as well) vectors being empty ;;;;
; Output = (Error (first-vector second-vector) EmptyList)

!(assertEqual
   (outer-product () (1 2 3))
   (Error (() (1 2 3)) EmptyList)
)

;;;; mat-scalar-op ;;;;

;;;; Test mat-scalar-op(matrice scalar operations) with a matrice of shape (n, m), a scalar value k, and the four operations(+, -, *, /) ;;;;
; Output = a matrice 0f shape (n, m) whose each element are the result of the input operation applied over each element of the input matrice and the scalar input

!(assertEqual
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

;;;; Test mat-scalar-op(matrice scalar operations) with an empty matrice, a scalar value k, and any of the four operations ;;;;
; Output = (Error the-empty-matrice EmptyMatrice)

!(assertEqual
   (mat-scalar-op () 5 +)
   (Error () EmptyMatrice)
)

;;;; clipping functions ;;;;

;;;; Test num-clip with a number, vec-clip with a vector, and mat-clip with a matrice, and lower boundary, and upper boundary arguments ;;;;
; Output = for the num-clip, the input num clipped to the lower or upper boundary if it's out the boundaries
; Output = for the vec-clip, the elements of the input vec clipped to the lower or upper boundary if they are out of the boundaries
; Output = for the mat-clip, the elements of the input matrice clipped to the lower or upper boundary if they are out of the boundaries

!(assertEqual
   (let*
      (
         ($clipped-num (num-clip 3 0 1))
         ($clipped-vec (vec-clip (0.4 3 1) 0 1))
         ($clipped-matrice (mat-clip ((0.3 4 -3) (0.2 3 -2) (0.1 2 -1)) 0 1))
      )
      (Clipped-num $clipped-num Clipped-vector $clipped-vec Clipped-matrice $clipped-matrice)
   )
   (Clipped-num 1 Clipped-vector (0.4 1 1) Clipped-matrice ((0.3 1 0) (0.2 1 0) (0.1 1 0)))
)
