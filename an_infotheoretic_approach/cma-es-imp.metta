;;;; CMA-ES(Convolution Matrix Adaptation Evolution Strategy) Implementation.

!(import! &self utils:random-list-utils)
!(import! &self utils:cma-es-utils)
!(import! &self info-theoretic)

;;;; INPUT CONCEPTS ;;;;
(= (concept1) 
    (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7)))
)
(= (concept2) 
    (Concept Spider@Man (Property (mobility 0.8) (intelligence 0.2) (web-creation 1.0) (social-structure 0.3) (predatory-behavior 0.9) (communication 0.4) (symbolism 0.6) (physical-strength 0.3)))
)

;;;; NOT USED LEARNING RATE COMPUTING METHODS ;;;;
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

;;;; POPULATION FITNESS SCORE CALCULATION ;;;;
(= (population-fitness-score $population) 
    (map-atom $population $x (mu-hqblend $x (concept1) (concept2)))
)

;;;; RECOMBINATION(UPDATE MEAN) ;;;;

; pair-index-fitness: zip indices and fitnesses
(: pair-index-fitness (List List -> List))
(= (pair-index-fitness $inds $fits)
   (map-atom $inds $i
     ($i (index-atom $fits $i))
   )
)

; find-max-helper: helper to find index of max fitness
(: find-max-helper (List Number Number Number -> Number))
(= (find-max-helper $pairs $i $max-idx $maxval)
   (if (== $i (size-atom $pairs))
       $max-idx
       (let*
         (
           ($pair (index-atom $pairs $i))   
           ($val  (index-atom $pair 1))     
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
            (vector-op $scaled $rest +)
        )      
       )
   )
)

;;;; STEP SIZE EVOLUTION PATH ADAPTATION ;;;;

(= (y $new-mean $old-mean $step-size)
  (let $mean-diff (vector-op $new-mean $old-mean -) (scalar-op $mean-diff $step-size /))
)

(= (new-p-sigma $c-sigma $p-sigma $mu-eff $c_inv_sqrt $y)
       (let* (
            (($m1-sigma $b2 $vec-mul) (collapse(superpose((- 1 $c-sigma) (sqrt-math (* (* $c-sigma (- 2 $c-sigma)) $mu-eff)) (let $mat-vec-prod (mat-mat-mul $c_inv_sqrt $y) (car-atom $mat-vec-prod))))))
            (($m1-sigma-p-sigma $vec-mul-b2) (collapse(superpose((map-atom $p-sigma $ps (* $ps $m1-sigma)) (map-atom $vec-mul $vm (* $vm $b2))))))
            )
            (vector-op $m1-sigma-p-sigma $vec-mul-b2 +)
        )
)

;;;; STEP SIZE ADAPTATION ;;;;

(= (new-step-size $step-size $c-sigma $d-sigma $dim $p-sigma)
    (let $adaptingfactor (pow-math (e) (* (/ $c-sigma $d-sigma) (- (/ (l2-norm $p-sigma) (sqrt-math $dim)) 1))) (* $step-size $adaptingfactor))
)

;;;; COVARIANCE EVOLUTION PATH ADAPTATION ;;;;
(= (h-sigma $p-sigma $c-sigma $gen)
    (1or0 (< (/ (l2-norm $p-sigma) (sqrt-math (- 1 (pow-math (- 1 $c-sigma) (* 2 (+ $gen 1)))))) (+ 1.4 (/ 2 (+ (dim) 1)))))
)

(= (p-c $prev-p-c $h-sigma $y)
    (let $c-c (c_c) (vector-op (rev-scalar-op (- 1 $c-c) $prev-p-c *) (rev-scalar-op (* $h-sigma (sqrt-math (* $c-c (* (- 2 $c-c) (mu_eff))))) $y *) +))
)

;;;; COVARIANCE MATRIX ADAPTATION ;;;;

(= (delta $selected $old-mean)
 (mat-mat-eles-op $selected ($old-mean) -)
)

(= (rank-mu $weights $delta)
    (let $zipped (zip-list $weights $delta)
        (let $wmoutp (map-atom $zipped $x (mat-scalar-op (outer-product (index-atom $x 1) (index-atom $x 1)) (index-atom $x 0) *))
            (foldl-atom $wmoutp 0 $acc $x (mat-mat-eles-op $x $acc +))
        )
    )
)

(= (new-cov $prev-cov $p-c $rank-mu)
    (let ($c1 $c-mu) ((c1) (c_mu))
        (let $upd-mats (collapse(superpose((mat-scalar-op $prev-cov (- (- 1 $c1) $c-mu) *) (mat-scalar-op (outer-product $p-c $p-c) $c1 *) (mat-scalar-op $rank-mu $c-mu *))))
            (foldl-atom $upd-mats 0 $acc $x (mat-mat-eles-op $x $acc +))
        )
    )
)

!(let*
    (
        (($normalized-weights $old-mean $old-cov $old-step-size) (collapse(superpose((normalized_weights) (mean) (cov) (step_size)))))
        ($samples (mat-clip (random-multivariate $old-mean (mat-scalar-op $old-cov (pow-math $old-step-size 2) *) (lambda_)) 0 1))
        ($fitness-score (population-fitness-score $samples))
        ($fitness-idx-pair (pair-index-fitness (make-indices $fitness-score) $fitness-score))
        ($selected (select-by-indices $samples (extract-indices (sort-pairs-desc $fitness-idx-pair) (mu))))
        ($new-mean (update-mean $normalized-weights $selected))
        (($y $C-inv-sqrt) ((y $new-mean $old-mean $old-step-size) (transpose-matrice (inverse-lmatrice (chol-decomp $old-cov)))))
        (($c-sigma $d-sigma $p-sigma) (collapse(superpose((c_sigma) (d_sigma) (p_sigma)))))
        ($new-p-sigma (new-p-sigma $c-sigma $p-sigma (mu_eff) $C-inv-sqrt ($y)))
        ($new-step-size (new-step-size $old-step-size $c-sigma $d-sigma (dim) $new-p-sigma))
        ($h-sigma (h-sigma $new-p-sigma $c-sigma 0))
        (($new-p-c $delta) ((p-c (p_c) $h-sigma $y) (delta $selected $old-mean)))
        ($rank-mu (rank-mu $normalized-weights $delta))
        ($new-cov (new-cov $old-cov $new-p-c $rank-mu))

    )
    (Old-mean $old-mean | New-mean $new-mean ||| Old-cov $old-cov | New-cov $new-cov ||| Old-step-size $old-step-size | New-step-size $new-step-size ||| Selected-individuals $selected)
)
