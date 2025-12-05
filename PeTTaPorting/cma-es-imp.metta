;;;; PARAMETERS ;;;;
!(import! &self utils/random-list-utils)
!(import! &self utils/cma-es-utils)
!(import! &self info-theoretic)
; !(import! &self op-constraints:op-evaluation)
; !(import! &self space-info-theoretic)

(=(add-reduct $space $atom)
    (let $result $atom (add-atom $space $atom))
)

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
(= (step_size) 1)
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
    (let*
    ( 
        ($test1 (testconcept1))
        ($test2 (testconcept2))
        ; ($_ (println! ($test1 $test2)))
       ($result (map-atom $population $x (mu-hqblend $x $test1 $test2)))

    )
    $result
    )
)

; !(population-fitness-score-test ((1 0 1 0 1 0 1 0) (0 1 0 1 0 1 0 1) (1 1 0 1 1 0 1 0) (0 0 1 1 0 0 1 0) (1 0 1 1 1 1 0 1) (1 1 1 1 1 0 0 1) (0 0 0 1 1 0 1 1) (1 1 0 0 0 0 1 1)))

(= (update-mean $samples $mu $weights $fitness-fn)
  (let $fitness-score ($fitness-fn $samples)
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

; !(update-mean ((2 0) (4 4) (8 2)) 3 (0.5 0.3 0.2) (population-fitness-score-test))


(= (moedd-update-mean $samples $mu $weights $fitness-fn $iter)
  (let ($unscalarized-fit-score $scalarized-fit-score) ($fitness-fn $samples $iter)
    (let $fit-ind-pairs (pair-index-fitness (make-indices $scalarized-fit-score) $scalarized-fit-score)
        (let $desc-sorted-pairs (sort-pairs-desc $fit-ind-pairs)
            (let $extracted-indices (extract-indices $desc-sorted-pairs $mu)
                (let ($selected-sample $selected-fitscore) ((select-by-indices $samples $extracted-indices) (select-by-indices $unscalarized-fit-score $extracted-indices)) ((car-atom $selected-sample) (car-atom $selected-fitscore)))
            )
        )
    )
  )
)

(= (mock-moedd-fitness $samples $iter)
    ((10 20 30) (0.1 0.2 0.3))
)

; Test moedd-update-mean selection behavior
; !(moedd-update-mean ((1 2) (3 4) (5 6)) 2 (0.6 0.4) mock-moedd-fitness 0)
    

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

; !(update-mean-test ((2 0) (4 4) (8 2)) 3 (0.5 0.3 0.2))  


(= (y $new-mean $old-mean $step-size)
  (let $mean-diff (vector-op $new-mean $old-mean -) (scalar-op $mean-diff $step-size /))
)

; !(y (0.3 0.4 0.6 0.2 0.8 0.1 0.5 0.8) (0.2 0.7 0.3 0.6 0.8 0.3 0.9 0.4) 0.34)


(= (new-p-sigma $c-sigma $p-sigma $mu-eff $c-inv-sqrt $y)
       (let* (
            ($_ (println! (Executing....)))
            (($m1-sigma $b2 $vec-mul) (collapse(superpose((- 1 $c-sigma) (sqrt-math (* (* $c-sigma (- 2 $c-sigma)) $mu-eff)) (mat-mat-mul $c-inv-sqrt ($y))))))
            ($_ (println! (M1 Sigma $m1-sigma B2 $b2 Vec Mul $vec-mul)))
            (($m1-sigma-p-sigma $vec-mul-b2) (collapse(superpose((map-atom $p-sigma $ps (* $ps $m1-sigma)) (map-atom $vec-mul $vm (* $vm $b2))))))
            )
            (vector-op $m1-sigma-p-sigma $vec-mul-b2 +)
        )
)

!(mat-mat-mul ((0 0 0 0 0 0 0) (0 0 0 0 0 0) (0 0 0 0 0) (0 0 0 0) (0 0 0) (0 0) (0)) ((0.629276773868858 0.7029813694774427 0.17915574673512397 0.021359372554875078 0.5556770423164838 -1.1102230246251565e-16 -1.3877787807814457e-17 -5.551115123125783e-17)) )
; !(new-p-sigma 0.3196142529106335 (0 0) 3.1672992814107035 ((0 0 0 0 0 0 0) (0 0 0 0 0 0) (0 0 0 0 0) (0 0 0 0) (0 0 0) (0 0) (0)) (0.629276773868858 0.7029813694774427 0.17915574673512397 0.021359372554875078 0.5556770423164838 -1.1102230246251565e-16 -1.3877787807814457e-17 -5.551115123125783e-17))
; !(mat-mat-mul (identity-matrice 3) (0.5 0.4 0.6))
;  !(new-p-sigma 0.3 (0.1 0.2 0.3) 2 (identity-matrice 3) (0.5 0.4 0.6))

; ; ;;;; STEP SIZE ADAPTATION ;;;;
; (= (new-step-size $step-size $c-sigma $d-sigma $dim $p-sigma $mu-eff $c-inv-sqrt $y)
;     (let $new-p-sigma (new-p-sigma $c-sigma $p-sigma $mu-eff $c-inv-sqrt $y)
;             (let $adaptingfactor (pow-math (e) (* (/ $c-sigma $d-sigma) (- (/ (l2-norm $new-p-sigma) (sqrt-math $dim)) 1))) ((* $step-size $adaptingfactor) $new-p-sigma))
;     )
; )

(= (new-step-size $step-size $c-sigma $d-sigma $dim $p-sigma $mu-eff $c-inv-sqrt $y)
        (let* (
            ($_ (println! (Executing New Step Size Adaptation)))
            ($new-p-sigma (new-p-sigma $c-sigma $p-sigma $mu-eff $c-inv-sqrt $y))
            ($_ (println! (New P Sigma Inside Step Size Adaptation $new-p-sigma)))
            
            ($adaptingfactor (pow-math (e) (* (/ $c-sigma $d-sigma) (- (/ (l2-norm $new-p-sigma) (sqrt-math $dim)) 1))))
            ($_ (println! (Adapting Factor $adaptingfactor)))
            ($adaptXsize (* $step-size $adaptingfactor))
            ($_ (println! (Adapted Step Size Before Returning $adaptXsize)))

        )
        ($adaptXsize $new-p-sigma)
        
        )

)
; !(new-step-size 1 0.3196142529106335 1.3196142529106334 8 (0 0) 3.1672992814107035 ((0 0 0 0 0 0 0) (0 0 0 0 0 0) (0 0 0 0 0) (0 0 0 0) (0 0 0) (0 0) (0)) (0.629276773868858 0.7029813694774427 0.17915574673512397 0.021359372554875078 0.5556770423164838 -1.110223024625156516 -1.387778780781445717 -5.55111512312578317))


; !(new-step-size 0.5 0.3 1.5 3 (0.2 0.4 0.6) 2 (identity-matrice 3) (0.5 0.4 0.6))
; ; ;;;; COVARIANCE EVOLUTION PATH ADAPTATION ;;;;

(= (h-sigma $p-sigma $c-sigma $gen)
    (1or0 (< (/ (l2-norm $p-sigma) (sqrt-math (- 1 (pow-math (- 1 $c-sigma) (* 2 (+ $gen 1)))))) (+ 1.4 (/ 2 (+ (dim) 1)))))
)

; !(h-sigma (0.2 0.3 0.4) 0.3 5)

(= (p-c $prev-p-c $new-p-sigma $c-sigma $gen $y)
    (let $h-sigma (h-sigma $new-p-sigma $c-sigma $gen)
        (let $c-c (c_c) (vector-op (rev-scalar-op (- 1 $c-c) $prev-p-c *) (rev-scalar-op (* $h-sigma (sqrt-math (* $c-c (* (- 2 $c-c) (mu_eff))))) $y *) +))
    )
)

; !(p-c (0.2 0.3 0.4) (0.5 0.6 0.7) 0.4 5 (0.1 0.2 0.3))

(= (delta $selected $old-mean)
 (mat-mat-eles-op $selected ($old-mean) -)
)

; !(delta ((0.5 0.6 0.7) (0.2 0.3 0.4) (0.1 0.2 0.3)) (0.2 0.3 0.4))

(= (rank-mu $weights $selected $old-mean)
    (let $delta (delta $selected $old-mean)
        (let $zipped (zip-list $weights $delta)
            (let $wmoutp (map-atom $zipped $x (mat-scalar-op (outer-product (index-atom $x 1) (index-atom $x 1)) (index-atom $x 0) *))
                (foldl-atom $wmoutp 0 $acc $x (mat-mat-eles-op $x $acc +))
            )
        )
    )
)

;  !(rank-mu (0.4 0.3 0.3) ((0.5 0.6 0.7) (0.2 0.3 0.4) (0.1 0.2 0.3)) (0.2 0.3 0.4))

(= (new-cov $prev-cov $prev-p-c $new-p-sigma $c-sigma $gen $y $weights $selected $old-mean)
    (let ($new-p-c $rank-mu) ((p-c $prev-p-c $new-p-sigma $c-sigma $gen $y) (rank-mu $weights $selected $old-mean))
        (let ($c1 $c-mu) ((c1) (c_mu))
            (let $upd-mats (collapse(superpose((mat-scalar-op $prev-cov (- (- 1 $c1) $c-mu) *) (mat-scalar-op (outer-product $new-p-c $new-p-c) $c1 *) (mat-scalar-op $rank-mu $c-mu *))))
                ((foldl-atom $upd-mats 0 $acc $x (mat-mat-eles-op $x $acc +)) $new-p-c)
            )
        )
    )
)

; !(new-cov (identity-matrice 3) (0.2 0.3 0.4) (0.5 0.6 0.7) 0.4 5 (0.1 0.2 0.3) (0.4 0.3 0.3) ((0.5 0.6 0.7) (0.2 0.3 0.4) (0.1 0.2 0.3)) (0.2 0.3 0.4))

(= (Thetha) 5.0)


(= (pbi-scalarization $obj $ref $weight)
    (if (and (== (size-atom $obj) 2) (and (== (size-atom $ref) 2) (== (size-atom $weight) 2)))
        (let*
            (
                ($proc-l2 (+ (l2-norm $weight) 0.000000000001))
                ($norm-weight (scalar-op $weight $proc-l2 /))
                ($diff (vector-op $obj $ref -))
                ($d1 (inner-product $diff $norm-weight))
                ($proj (scalar-op $norm-weight $d1 *))
                ($d2 (l2-norm (vector-op $diff $proj -)))
            )
            (+ $d1 (* (Thetha) $d2))
        )
        (Error ($obj $ref $weight) IncorrectLength)
    )
)

; !(pbi-scalarization (3 4) (1 2) (0.5 0.5))

(= (max-best-nd $best-nds $ref $iter $weights)
    (let $weight (index-atom $weights $iter) (let $res (map-atom $best-nds $best-nd (pbi-scalarization (index-atom $best-nd 1) $ref $weight)) (let ($zipped-res $max-val) ((zip-list $best-nds $res) (max-atom $res)) (max-best-nd-helper $max-val $zipped-res))))
)

;    !(max-best-nd (
;       ((b) (0.4 0.6))
;       ((c) (0.6 0.4))
;       ((d) (0.8 0.2)))

;    (0 0)
;    1
;    ((0.2 0.8) (0.5 0.5) (0.8 0.2)))

!(bind! &single-cma-es-inputspace (new-space))
(= (add-to-single-cma-es-inputspace)
    (add-reduct &single-cma-es-inputspace (Inputs ((mean) (cov) (step_size) (p_sigma) (p_c) () -10000 0 0)))
)

!(add-to-single-cma-es-inputspace)
(= (clean-from-single-cma-es-inputspace)
    (collapse (match &single-cma-es-inputspace (Inputs $params) (remove-atom &single-cma-es-inputspace (Inputs $params))))
)
!(add-to-single-cma-es-inputspace)
!(add-concepts)

!(bind! &rmspace (new-space))
!(bind! &cispace1 (new-space))
!(bind! &cispace2 (new-space))
!(bind! &cispace3 (new-space))

(= (cma-es-single-iteration $fitness-fn)
    (let ($mean $cov $step-size $p-sigma $p-c $best-pop $best-fitness $gen $stall) (match &single-cma-es-inputspace (Inputs $x) $x)
        (if (>= $stall 5)                         ; patience = 5 gens
          ($best-pop $best-fitness)             
          (let*
            (
                (($normalized-weights $c-sigma $d-sigma $mu $mu-eff $dim $rmspace $cispace1 $cispace2 $cispace3) (collapse(superpose((normalized_weights) (c_sigma) (d_sigma) (mu) (mu_eff) (dim) (get-space) (get-space) (get-space) (get-space)))))
                ($samples (mat-clip (random-multivariate $mean (mat-scalar-op $cov (pow-math $step-size 2) *) (lambda_) $rmspace) 0 1))
                (($new-mean $selected $fitness-score) (update-mean $samples $mu $normalized-weights $fitness-fn))
                (($new-best-fitness $new-best-pop) (let $gen-best-fitness (max-atom $fitness-score) (if (>= $gen-best-fitness $best-fitness) ($gen-best-fitness $selected) ($best-fitness $best-pop))))
                ($improved?  (> $new-best-fitness $best-fitness))
                ($new-stall  (if $improved? 0 (+ 1 $stall)))
                (($y $C-inv-sqrt) ((y $new-mean $mean $step-size) (C-inv-sqrt $cov $cispace1 $cispace2 $cispace3)))
                (($new-step-size $new-p-sigma) (new-step-size $step-size $c-sigma $d-sigma $dim $p-sigma $mu-eff $C-inv-sqrt $y))
                (($new-cov $new-p-c) (new-cov $cov $p-c $new-p-sigma $c-sigma $gen $y $normalized-weights $selected $mean))
                ($clean (collapse (match &single-cma-es-inputspace (Inputs $params) (remove-atom &single-cma-es-inputspace (Inputs $params)))))
                (() (println!(GENERATION $gen |  Max Fitness $new-best-fitness  |  Stall $new-stall)))
            )
            (let $added (add-reduct &single-cma-es-inputspace (Inputs ($new-mean $new-cov $new-step-size $new-p-sigma $new-p-c $new-best-pop $new-best-fitness (+ 1 $gen) $new-stall))) ($new-best-pop $new-best-fitness)))
        )
    )
)
