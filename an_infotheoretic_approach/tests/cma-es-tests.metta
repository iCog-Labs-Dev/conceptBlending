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
    (let $x (cma-es-main-loop (mean) (cov) (step_size) (p_sigma) (p_c) () 0) ((size-atom $x) (let $y (car-atom $x) (size-atom $y))))
    (10 8)
)
