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

(assert-equal (zeros-vec 0)     (()))
(assert-equal (zeros-vec 1)     ((0)))
(assert-equal (zeros-vec 3)     ((0 0 0)))
(assert-equal (zeros-vec 5)     ((0 0 0 0 0)))
(assert-equal (zeros-vec 10)    ((0 0 0 0 0 0 0 0 0 0)))


;;;; range ;;;;

(assert-equal (range 1 4)     ((1 2 3)))
(assert-equal (range 1 10)    ((1 2 3 4 5 6 7 8 9)))
(assert-equal (range 5 5)     (()))
(assert-equal (range 5 3)     (()))
(assert-equal (range 0 2)     ((1)))


;;;; scalar-op ;;;;

(assert-equal (scalar-op (1 2 3) 2 *)         ((2 4 6)))
(assert-equal (scalar-op (2 3 4) 1 -)         ((1 2 3)))
(assert-equal (scalar-op (2.0 4.0 6.0) 2 /)   ((1.0 2.0 3.0)))
(assert-equal (scalar-op (1 2 3 4) 5 +)       ((6 7 8 9)))
(assert-equal (scalar-op () 3 +)             (()))

;;;; rev-scalar-op ;;;;

(assert-equal (rev-scalar-op 10 (1 2 3) -)     ((9 8 7)))
(assert-equal (rev-scalar-op 100 (2 4 5) /)    ((50.0 25.0 20.0)))
(assert-equal (rev-scalar-op 2 (3 4 5) *)      ((6 8 10)))
(assert-equal (rev-scalar-op 10 (1 2 3) +)     ((11 12 13)))
(assert-equal (rev-scalar-op 2 () *)          (()))


;;; LEARNING RATES ;;;
!(assertEqual (mu_eff) 3.1672992814107035)
!(assertEqual (dim) 8)
!(assertEqual (c_sigma) 0.3196142529106335)
!(assertEqual (d_sigma) 1.3196142529106334)
!(assertEqual (c_c)      0.34365014154838475)
!(assertEqual (c1)       0.022307163120344784)
!(assertEqual (c_mu)     0.028749917692721574)

;;; MAIN LOOP ;;;
!(assertEqual 
    (let $x (cma-es-main-loop) ((size-atom $x) (let $y (car-atom $x) (size-atom $y))))
    (5 8)
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

