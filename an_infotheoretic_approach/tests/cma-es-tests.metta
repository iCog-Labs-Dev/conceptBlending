! (register-module! ../../an_infotheoretic_approach)
!(import! &self an_infotheoretic_approach:utils:cma-es-utils)

;;;; apply-log ;;;;

; Base-2 log of powers of 2
! (apply-log (1 2 4 8 16) 2)
; → [0.0 1.0 2.0 3.0 4.0]

; Base-e log of e, e^2, e^3
! (apply-log (2.71828 7.38905 20.0855) 2.71828)
; → [1.0 2.0 3.0]

; Log base 10 of 10, 100, 1000
! (apply-log (10 100 1000) 10)
; → [1.0 2.0 3.0]

; Log of 1s should be 0
! (apply-log (1 1 1) 10)
; → [0.0 0.0 0.0]

; Log of increasing values, base 5
! (apply-log (5 25 125 625) 5)
; → [1.0 2.0 3.0 4.0]

;;;; apply-power ;;;;

; Square a list of numbers
! (apply-power (1 2 3 4 5) 2)
; → [1.0 4.0 9.0 16.0 25.0]

; Cube values
! (apply-power (2 3 4) 3)
; → [8.0 27.0 64.0]

; Raise to 0 — should be 1s
! (apply-power (10 100 1000) 0)
; → [1.0 1.0 1.0]

; Negative exponent
! (apply-power (1 2 4) -1)
; → [1.0 0.5 0.25]

; Fractional exponent (square root)
! (apply-power (4 9 16 25) 0.5)
; → [2.0 3.0 4.0 5.0]

;;;; sum ;;;;

; Sum integers
! (sum (1 2 3 4))
; → [10]

; Sum decimals
! (sum (0.5 1.5 2.0))
; → [4.0]

; Sum 0s
! (sum (0 0 0 0))
; → [0]

; Single element
! (sum (100))
; → [100]

; Empty list
! (sum ())
; → [0]

;;;; l2-norm ;;;;

; Classic 3-4-5 triangle
! (l2-norm (3 4))
; → [5.0]

; 3D norm
! (l2-norm (1 2 2))
; → [3.0]

; All ones
! (l2-norm (1 1 1 1))
; → [2.0]

; Large values
! (l2-norm (10 20 30))
; → [37.4166...]

; Empty vector
! (l2-norm ())
; → [0]

;;;; identity-matrice ;;;;

; Identity matrix of size 1
! (identity-matrice 1)
; → [(1)]

; Size 2
! (identity-matrice 2)
; → [(1 0) (0 1)]

; Size 3
! (identity-matrice 3)
; → [(1 0 0) (0 1 0) (0 0 1)]

; Size 5
! (identity-matrice 5)
; → [(1 0 0 0 0) (0 1 0 0 0) (0 0 1 0 0) (0 0 0 1 0) (0 0 0 0 1)]

; Upper boundary (10)
! (identity-matrice 10)
; → [(1 0 0 ... 0) ... (0 0 ... 1)]

;;;; zeros-vec ;;;;

; Length 0: should return an empty list
! (zeros-vec 0)
; → [()]

; Length 1: one zero
! (zeros-vec 1)
; → [(0)]

; Length 3: three zeros
! (zeros-vec 3)
; → [(0 0 0)]

; Length 5: five zeros
! (zeros-vec 5)
; → [(0 0 0 0 0)]

; Edge test (e.g. 10)
! (zeros-vec 10)
; → [(0 0 0 0 0 0 0 0 0 0)]

;;;; range ;;;;

; Simple range 1–4
! (range 1 4)
; → [(1 2 3)]

; Full span 1–10
! (range 1 10)
; → [(1 2 3 4 5 6 7 8 9)]

; lb == ub → empty
! (range 5 5)
; → [()]

; lb > ub → empty (invalid range)
! (range 5 3)
; → [()]

; Lower edge
! (range 0 2)
; → [(1)]

;;;; scalar-op ;;;;

; Multiply vector by 2
! (scalar-op (1 2 3) 2 *)

; → [(2 4 6)]

; Subtract 1 from each
! (scalar-op (2 3 4) 1 -)
; → [(1 2 3)]

; Divide by 2
! (scalar-op (2.0 4.0 6.0) 2 /)
; → [(1.0 2.0 3.0)]

; Add 5
! (scalar-op (1 2 3 4) 5 +)
; → [(6 7 8 9)]

; Edge case: empty list
! (scalar-op () 3 +)
; → [()]

;;;; rev-scalar-op ;;;;

; Subtract each from 10
! (rev-scalar-op 10 (1 2 3) -)
; → [(9 8 7)]

; Divide 100 by each value
! (rev-scalar-op 100 (2 4 5) /)
; → [(50.0 25.0 20.0)]

; Multiply 2 by each
! (rev-scalar-op 2 (3 4 5) *)
; → [(6 8 10)]

; Add 10 to each (scalar first)
! (rev-scalar-op 10 (1 2 3) +)
; → [(11 12 13)]

; Edge case: empty vector
! (rev-scalar-op 2 () *)
; → [()]