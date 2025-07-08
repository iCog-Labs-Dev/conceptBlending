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
; (= (weights)(norm-weights (raw-weights (mu-calc (lambda-calc 0 6)))))

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

; !(cma-strategy 0 6)      


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
(= (mean)(let $x (random-list 1 (dim) 0 1) (car-atom $x)))
(= (cov) (identity-matrice (dim)))
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
; !(normalized_weights)
; !(mu_eff)
; !(c_sigma)
; !(d_sigma)
; !(c_c)
; !(c1)
; !(c_mu)
; !(p_c)
; !(p_sigma)


; !(random-multivariate (mean) (mat-scalar-op (cov) (pow-math (step_size) 2) *) 10)
; !(standard-normal 8 10)

;––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
; pair-index-fitness: zip indices and fitnesses
(: pair-index-fitness (List List -> List))
(= (pair-index-fitness $inds $fits)
   (map-atom $inds $i
     ($i (index-atom $fits $i))
   )
)
; ! (pair-index-fitness (make-indices (10 30 20)) (10 30 20)) ; [((0 10) (1 30) (2 20))]

; find-max-helper: helper to find index of max fitness
(: find-max-helper (List Number Number Number -> Number))
(= (find-max-helper $pairs $i $max-idx $maxval)
   (if (== $i (size-atom $pairs))
       $max-idx
       (let*
         (
           ($pair (index-atom $pairs $i))   ; (idx fitness)
           ($val  (index-atom $pair 1))     ; fitness
         )
         (if (> $val $maxval)
             (find-max-helper $pairs (+ $i 1) $i   $val)
             (find-max-helper $pairs (+ $i 1) $max-idx $maxval)
         )
       )
   )
)

; max-index: find index of highest-fitness pair
(: max-index (List -> Number))
(= (max-index $pairs)
   (let*
     (
       ($first (index-atom $pairs 0))
       ($start (index-atom $first 1))
     )
     (find-max-helper $pairs 1 0 $start)
   )
)
; ! (max-index ((0 10) (1 30) (2 20)))  ; [1]

; sort-pairs-desc
(: sort-pairs-desc (List -> List))
(= (sort-pairs-desc $pairs)
   (if (< (size-atom $pairs) 2)       
       $pairs                         
       (let* (
               ($idx        (max-index    $pairs))       
               ($maxPair    (index-atom   $pairs $idx)) 
               ($rest       (remove-index $pairs $idx))  
               ($sorted-rest (sort-pairs-desc $rest))   
             )
         (cons-atom $maxPair $sorted-rest)           
       )
   )
)
; ! (sort-pairs-desc ((0 10) (1 30) (2 20)))  ; [((1 30) (2 20) (0 10))]

; extract-indices: take top mu indices
(: extract-indices (List Number -> List))
(= (extract-indices $pairs $mu)
   (if (or (== $mu 0) (== (size-atom $pairs) 0))
       ()
       (let*
         (
           ($first-pair (index-atom $pairs 0))
           ($idx         (index-atom $first-pair 0))
           ($rest        (remove-index $pairs 0))
           ($tail        (extract-indices $rest (- $mu 1)))
         )
         (cons-atom $idx $tail)
       )
   )
)
; ! (extract-indices ((1 30) (2 20) (0 10)) 2) ; [(1 2)]

; select-by-indices: pick samples by indices
(: select-by-indices (List List -> List))
(= (select-by-indices $samples $indices)
   (if (== (size-atom $indices) 0)
       ()
       (let* (
               ($first-i (index-atom $indices 0))
               ($item    (index-atom $samples $first-i))
               ($rest    (select-by-indices $samples (cdr-atom $indices)))
             )
         (cons-atom $item $rest)
       )
   )
)
; ! (select-by-indices (5 6 7) (1 2))  

; Full pipeline test with literals
; (= (fitnesses) (10 30 20))
; (= (samples)   (4  5  6))
; (= (mu)        2)

(= (fitnesses) (0.0675 0.0475 0.045  0.1175 0.0625 0.085  0.0225 0.035 0.0325 0.0725))
(= (samples) ((1 0 0 0 0 1 1 1) (1 0 0 1 1 1 1 0) (1 0 0 1 0 0 1 1) (0 0 0 1 1 1 0 1) (1 0 0 1 1 1 1 1) (1 0 0 1 1 0 1 0) (1 0 0 1 1 1 1 1) (1 0 0 1 1 1 0 1) (1 0 0 1 0 0 0 1) (1 0 0 1 0 1 0 1)))
; (= (mu)        6)

; ! (pair-index-fitness (make-indices (fitnesses)) (fitnesses))
; ! (sort-pairs-desc (pair-index-fitness  (make-indices (fitnesses)) (fitnesses)))
; ! (extract-indices (sort-pairs-desc (pair-index-fitness (make-indices (fitnesses)) (fitnesses))) (mu))
; ! (select-by-indices (samples) (extract-indices(sort-pairs-desc (pair-index-fitness(make-indices (fitnesses)) (fitnesses)))(mu)))

(: update-mean (List List -> List))
(= (update-mean $w $sel)
   (if (== (size-atom $w) 0)             
       ()                                  
       (let* (
               ($scaled                 
                 (vec-scale
                   (index-atom $w   0)
                   (index-atom $sel 0)))
               ($rest                     
                 (update-mean
                   (cdr-atom $w)
                   (cdr-atom $sel)))
             )
         (if (== (size-atom $rest) 0)
             $scaled                       
             (vec-add $scaled $rest))      
       )
   )
)
; ! (update-mean (1)        ((5)))           ; Expected -> [(5)]
(= (old_mean) (0.97539962 0.2234363  0.51327389 0.73508769 0.51021857 0.26006022 0.54089707 0.32556931))
(= (mean) (update-mean (weights) (samples)  ))         
!(mean)


