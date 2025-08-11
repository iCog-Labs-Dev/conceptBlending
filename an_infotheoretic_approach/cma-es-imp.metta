;;;; CMA-ES(Convolution Matrix Adaptation Evolution Strategy) Implementation.

!(import! &self libs)
!(import! &self utils:random-list-utils)
!(import! &self utils:cma-es-utils)
!(import! &self info-theoretic)
!(import! &self op-constraints:op-evaluation)
!(import! &self space-info-theoretic)

;;;; SPACE GETTER METHOD ;;;;
(= (get-space) (new-space))

;;;; INPUT CONCEPTS ;;;;
(= (testconcept1) 
    (Concept Man@Bat (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7)))
)
(= (testconcept2) 
    (Concept Bat@Man (Property (mobility 0.8) (intelligence 0.2) (web-creation 1.0) (social-structure 0.3) (predatory-behavior 0.9) (communication 0.4) (symbolism 0.6) (physical-strength 0.3)))
)

(= (Input1) Bat)
(= (Input2) Man)

;;;; PARAMETERS ;;;;

;;;; DIMENSION, INITIAL MEAN, COVARIANCE, AND STEP SIZE
(= (dim) 8)
(= (mean)(let $x (random-list 1 (dim) 0 1) (car-atom $x)))
(= (cov) (identity-matrice (dim)))
(= (step_size) 20)
(= (e) 2.71828)

;;;; STRATEGY PARAMETERS ;;;;
(= (GENERATIONS) 30)
(= (POPULATION_SIZE) 0)
(= (lambda_) (if (<= (POPULATION_SIZE) 0) (+ 4 (round-math (* 3 (log-math (e) (dim))))) (POPULATION_SIZE)))
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

;;;; POPULATION FITNESS SCORE CALCULATION FOR TESTING ;;;;
(= (population-fitness-score-test $population)
    (map-atom $population $x (mu-hqblend $x (testconcept1) (testconcept2)))
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
             (find-max-helper $pairs (+ $i 1) $i $val)
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
                ($idx        (max-index $pairs))
                ($maxPair    (index-atom $pairs $idx)) 
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
    (
        if (or (== $mu 0) (== (size-atom $pairs) 0))
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
    (
        if (== (size-atom $indices) 0)
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

(= (update-mean $samples $mu $weights)
  (let $fitness-score (population-fitness-score $samples)
    (let $fit-ind-pairs (pair-index-fitness (make-indices $fitness-score) $fitness-score)
        (let $desc-sorted-pairs (sort-pairs-desc $fit-ind-pairs)
            (let $extracted-indices (extract-indices $desc-sorted-pairs $mu)
                (let $selected (select-by-indices $samples $extracted-indices)
                    (let $weighted-indiv (mat-vec-op $selected $weights *)
                        ((foldl-atom $weighted-indiv 0 $acc $x (vector-op $x $acc +)) $selected $fitness-score)
                    )
                )
            )
        )
    )
  )
)


(= (update-mean-test $samples $mu $weights)
  (let $fitness-score (population-fitness-score-test $samples)
    (let $fit-ind-pairs (pair-index-fitness (make-indices $fitness-score) $fitness-score)
        (let $desc-sorted-pairs (sort-pairs-desc $fit-ind-pairs)
            (let $extracted-indices (extract-indices $desc-sorted-pairs $mu)
                (let $selected (select-by-indices $samples $extracted-indices)
                    (let $weighted-indiv (mat-vec-op $selected $weights *)
                        ((foldl-atom $weighted-indiv 0 $acc $x (vector-op $x $acc +)) $selected $fitness-score)
                    )
                )
            )
        )
    )
  )
)

;;;; STEP SIZE EVOLUTION PATH ADAPTATION ;;;;

(= (y $new-mean $old-mean $step-size)
  (let $mean-diff (vector-op $new-mean $old-mean -) (scalar-op $mean-diff $step-size /))
)

(= (new-p-sigma $c-sigma $p-sigma $mu-eff $c-inv-sqrt $y)
       (let* (
            (($m1-sigma $b2 $vec-mul) (collapse(superpose((- 1 $c-sigma) (sqrt-math (* (* $c-sigma (- 2 $c-sigma)) $mu-eff)) (mat-mat-mul $c-inv-sqrt ($y))))))
            (($m1-sigma-p-sigma $vec-mul-b2) (collapse(superpose((map-atom $p-sigma $ps (* $ps $m1-sigma)) (map-atom $vec-mul $vm (* $vm $b2))))))
            )
            (vector-op $m1-sigma-p-sigma $vec-mul-b2 +)
        )
)

;;;; STEP SIZE ADAPTATION ;;;;

(= (new-step-size $step-size $c-sigma $d-sigma $dim $p-sigma $mu-eff $c-inv-sqrt $y)
    (let $new-p-sigma (new-p-sigma $c-sigma $p-sigma $mu-eff $c-inv-sqrt $y)
            (let $adaptingfactor (pow-math (e) (* (/ $c-sigma $d-sigma) (- (/ (l2-norm $new-p-sigma) (sqrt-math $dim)) 1))) ((* $step-size $adaptingfactor) $new-p-sigma))
    )
)

;;;; COVARIANCE EVOLUTION PATH ADAPTATION ;;;;

(= (h-sigma $p-sigma $c-sigma $gen)
    (1or0 (< (/ (l2-norm $p-sigma) (sqrt-math (- 1 (pow-math (- 1 $c-sigma) (* 2 (+ $gen 1)))))) (+ 1.4 (/ 2 (+ (dim) 1)))))
)

(= (p-c $prev-p-c $new-p-sigma $c-sigma $gen $y)
    (let $h-sigma (h-sigma $new-p-sigma $c-sigma $gen)
        (let $c-c (c_c) (vector-op (rev-scalar-op (- 1 $c-c) $prev-p-c *) (rev-scalar-op (* $h-sigma (sqrt-math (* $c-c (* (- 2 $c-c) (mu_eff))))) $y *) +))
    )
)

(= (delta $selected $old-mean)
 (mat-mat-eles-op $selected ($old-mean) -)
)

(= (rank-mu $weights $selected $old-mean)
    (let $delta (delta $selected $old-mean)
        (let $zipped (zip-list $weights $delta)
            (let $wmoutp (map-atom $zipped $x (mat-scalar-op (outer-product (index-atom $x 1) (index-atom $x 1)) (index-atom $x 0) *))
                (foldl-atom $wmoutp 0 $acc $x (mat-mat-eles-op $x $acc +))
            )
        )
    )
)

(= (new-cov $prev-cov $prev-p-c $new-p-sigma $c-sigma $gen $y $weights $selected $old-mean)
    (let ($new-p-c $rank-mu) ((p-c $prev-p-c $new-p-sigma $c-sigma $gen $y) (rank-mu $weights $selected $old-mean))
        (let ($c1 $c-mu) ((c1) (c_mu))
            (let $upd-mats (collapse(superpose((mat-scalar-op $prev-cov (- (- 1 $c1) $c-mu) *) (mat-scalar-op (outer-product $new-p-c $new-p-c) $c1 *) (mat-scalar-op $rank-mu $c-mu *))))
                ((foldl-atom $upd-mats 0 $acc $x (mat-mat-eles-op $x $acc +)) $new-p-c)
            )
        )
    )
)

!(bind! &inputspace (get-space))
!(add-reduct &inputspace (Inputs ((mean) (cov) (step_size) (p_sigma) (p_c) () -10000 0 0)))
!(add-concepts)

(= (cma-es-single-iteration)
    (let ($mean $cov $step-size $p-sigma $p-c $best-pop $best-fitness $gen $stall) (match &inputspace (Inputs $x) $x)
        (if (>= $stall 5)                         ; patience = 5 gens
          ($best-pop $best-fitness)             
          (let*
            (
                (($normalized-weights $c-sigma $d-sigma $mu $mu-eff $dim $rmspace $cispace1 $cispace2 $cispace3) (collapse(superpose((normalized_weights) (c_sigma) (d_sigma) (mu) (mu_eff) (dim) (get-space) (get-space) (get-space) (get-space)))))
                ($samples (mat-clip (random-multivariate $mean (mat-scalar-op $cov (pow-math $step-size 2) *) (lambda_) $rmspace) 0 1))
                (($new-mean $selected $fitness-score) (update-mean $samples $mu $normalized-weights))
                (($new-best-fitness $new-best-pop) (let $gen-best-fitness (max-atom $fitness-score) (if (>= $gen-best-fitness $best-fitness) ($gen-best-fitness $selected) ($best-fitness $best-pop))))
                ($improved?  (> $new-best-fitness $best-fitness))
                ($new-stall  (if $improved? 0 (+ 1 $stall)))
                (($y $C-inv-sqrt) ((y $new-mean $mean $step-size) (C-inv-sqrt $cov $cispace1 $cispace2 $cispace3)))
                (($new-step-size $new-p-sigma) (new-step-size $step-size $c-sigma $d-sigma $dim $p-sigma $mu-eff $C-inv-sqrt $y))
                (($new-cov $new-p-c) (new-cov $cov $p-c $new-p-sigma $c-sigma $gen $y $normalized-weights $selected $mean))
                ($clean (collapse (match &inputspace (Inputs $params) (remove-atom &inputspace (Inputs $params)))))
                (() (println!(GENERATION $gen |  Max Fitness $new-best-fitness  |  Stall $new-stall)))
            )
            (let $added (add-reduct &inputspace (Inputs ($new-mean $new-cov $new-step-size $new-p-sigma $new-p-c $new-best-pop $new-best-fitness (+ 1 $gen) $new-stall))) ($new-best-pop $new-best-fitness)))
        )
    )
)

(= (cma-es-main-loop)
    (let $iters (generate-toy-list (GENERATIONS))  (map-atom $iters $iter (cma-es-single-iteration)))
)

(= (Eval) True)


; !(blend cma-es-main-loop (Eval))

; !(space-blend blend cma-es-main-loop (Eval))
