;;;; CMA-ES(Convolution Matrix Adaptation Evolution Strategy) Implementation.

!(import! &self utils:random-list-utils)
!(import! &self utils:cma-es-utils)
!(import! &self utils:list-op-utils)

(: lambda-calc (Number Number -> Number))
(= (lambda-calc $population_size $dim)
   (if (== $population_size 0)                                      
       (+ 4
          (floor-math (* 3 (log-math 2.718281828459045 $dim))))     
       $population_size))    
; !(lambda-calc 0 6)

(: mu-calc (Number -> Number))
(= (mu-calc $lambda) (floor-math (/ $lambda 2)))
; !(mu-calc (lambda-calc 0 6))

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
; !(range 1 7 1) 

(: raw-weights (Number -> List))
(= (raw-weights $mu)
   (let* (
          ($idxs  (range 1 $mu 1))                             
          ($const (log-math 2.718281828459045 (+ $mu 0.5)))
         )
         (map-atom $idxs $i
                   (- $const (log-math 2.718281828459045 $i)))))    
; !(raw-weights (mu-calc (lambda-calc 0 6)))

(: norm-weights (List -> List))
(= (norm-weights $w_raw)
   (let* (
          ($sum_w  (foldl-atom $w_raw 0 $acc $x (+ $acc $x)))
         )
         (map-atom $w_raw $w (/ $w $sum_w))))
; !(norm-weights (raw-weights (mu-calc (lambda-calc 0 6))))

(: mu-eff (List -> Number))
(= (mu-eff $weights)
   (let* (
           ($squares (map-atom $weights $w (* $w $w)))
           ($sum_sq (foldl-atom $squares 0 $acc $x (+ $acc $x)))
         )
         (/ 1 $sum_sq)))
; !(mu-eff(norm-weights (raw-weights (mu-calc (lambda-calc 0 6)))))


(: cma-strategy (Number Number -> Tuple))
(= (cma-strategy $population_size $dim)
   (let* (
          ($lambda  (lambda-calc $population_size $dim))
          ($mu      (mu-calc      $lambda))
          ($w_raw   (raw-weights  $mu))
          ($weights (norm-weights $w_raw))
          ($mu_eff  (mu-eff       $weights))
         )
         ($lambda $mu $weights $mu_eff)))

!(cma-strategy 0 6)      


; ======== LEARNING RATE CALCULATIONS ========
(= (compute-learning-rates $dim $mu_eff)
   (let* ; 1. c_sigma calculation
        $c_sigma (/ (+ $mu_eff 2.0) (+ $dim $mu_eff 5.0))

        ; 2. d_sigma calculation
        $inner_term1 (/ (- $mu_eff 1.0) (+ $dim 1.0))
        $sqrt_term (sqrt-math $inner_term1)
        $max_term (max-atom (0.0 (- $sqrt_term 1.0)))
        $d_sigma (+ 1.0 (+ (* 2.0 $max_term) $c_sigma))

        ; 3. c_c calculation
        $c_c_num (+ 4.0 (/ $mu_eff $dim))
        $c_c_den (+ $dim 4.0 (* 2.0 (/ $mu_eff $dim)))
        $c_c (/ $c_c_num $c_c_den)

        ; 4. c1 calculation
        $dim_term (pow-math (+ $dim 1.3) 2.0)
        $c1_den (+ $dim_term $mu_eff)
        $c1 (/ 2.0 $c1_den)

        ; 5. c_mu calculation
        $c_mu_term1 (- 1.0 $c1)
        $c_mu_num (* 2.0 (+ (- $mu_eff 2.0) (/ 1.0 $mu_eff)))
        $c_mu_den (+ (pow-math (+ $dim 2.0) 2.0) $mu_eff)
        $c_mu_term2 (/ $c_mu_num $c_mu_den)
        $c_mu (min-atom ($c_mu_term1 $c_mu_term2))

        ; Return all parameters as a list
        (list $c_sigma $d_sigma $c_c $c1 $c_mu)))


;;;; PARAMETERS ;;;;

;;;; DIMENSION, INITIAL MEAN, COVARIANCE, AND STEP SIZE

(= (dim) 8)
; (= (mean)(let $x (random-list 1 (dim) 0 1) (car-atom $x)))
; (= (cov) (identity-matrice (dim)))
(= (step_size) 20)
(= (e) 2.71828)

;;;; STRATEGY PARAMETERS ;;;;

(= (lambda_) (+ 4 (round-math (* 3 (log-math (e) (dim))))))
(= (mu) (/ (lambda_) 2))
(= (weights) (let ($mu-logged $range-logged)  ((log-math (e) (+ (mu) 0.5)) (let $range (range 1 (+ (mu) 1)) (apply-log $range (e)))) (rev-scalar-op $mu-logged $range-logged -)))
(= (normalized_weights)(scalar-op (weights) (sum (weights)) /))
(= (mu_eff)(/ 1 (sum (apply-power (normalized_weights) 2))))

;;;; LEARNING RATES ;;;;
(= (c_sigma) (let $mu-eff (mu_eff) (/ (+ $mu-eff 2) (+ 5 (+ $mu-eff (dim))))))
(= (d_sigma) (+ 1 (+ (* 2 (max-atom(0 (- (sqrt-math (/ (- (mu_eff) 1) (+ (dim) 1))) 1)))) (c_sigma))))
(= (c_c) (let ($mu-eff $dim) ((mu_eff) (dim)) (/ (+ 4 (/ $mu-eff $dim)) (+ $dim (+ 4 (/ (* 2 $mu-eff) $dim))))))
(= (c1) (/ 2 (+ (pow-math (+ (dim) 1.3) 2) (mu_eff))))
(= (c_mu) (let $mu-eff (mu_eff) (min-atom((- 1 (c1)) (/ (* 2 (+ (- $mu-eff 2) (/ 1 $mu-eff))) (+ (pow-math (+ (dim) 2) 2) $mu-eff))))))

;;;; EVOLUTION PATHS ;;;;
(= (p_c) (zeros-vec (dim)))
(= (p_sigma) (zeros-vec (dim)))

; !(mean)
; !(cov)
; !(lambda_)
; !(mu)
; !(weights)
; !(normalized-weights)
; !(mu_eff)
; !(c_sigma)
; !(d_sigma)
; !(c_c)
; !(c1)
; !(c_mu)
; !(p_c)
; !(p_sigma)
