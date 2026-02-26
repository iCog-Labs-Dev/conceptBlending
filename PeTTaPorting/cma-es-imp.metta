;;;; PARAMETERS ;;;;
!(import! &self utils/cma-es-utils)
!(import! &self info-theoretic)
!(import! &self "utils/numpy_methods.py")

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

(= (Input1) spider)
(= (Input2) man)

;;;; PARAMETERS ;;;;
;;;; DIMENSION, INITIAL MEAN, COVARIANCE, AND STEP SIZE
(= (dim) 8)
(= (mean)(let $x (random-list 1 (dim) 0 1) (car-atom $x)))
; !(mean)
(= (cov) (identity-matrix (dim)))
(= (step_size) 1)
(= (e) 2.71828)

;;;; STRATEGY PARAMETERS ;;;;
(= (GENERATIONS) 50)
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
    (map-atom $population $x (mu-hqblend $x (eval (concept1)) (eval (concept2))))
)

;;;; POPULATION FITNESS SCORE CALCULATION FOR TESTING ;;;;
(= (population-fitness-score-test $population)
    (let*
    ( 
        ($test1 (testconcept1))
        ($test2 (testconcept2))
       ($result (map-atom $population $x (mu-hqblend $x $test1 $test2)))

    )
    $result
    )
)

(= (update-mean $samples $mu $weights $fitness-fn)
    (let $fitness-score ($fitness-fn $samples)
        (let $fit-ind-pairs (pair-index-fitness (make-indices $fitness-score) $fitness-score)
            (let $desc-sorted-pairs (sort-pairs-desc $fit-ind-pairs)
                (let $extracted-indices (extract-indices $desc-sorted-pairs $mu)
                        (let $selected (select-by-indices $samples $extracted-indices)
                            (let $weighted-indiv (mat-vec-op $selected $weights *)
                                (let $weighted-mean (foldl-atom $weighted-indiv 0 $acc $x (vector-op $x $acc +))
                                    ($weighted-mean $selected $fitness-score)
                                )                                        
                            )
                        )
                )
            )
        )
    )
)

(= (moedd-update-mean $samples $mu $weights $fitness-fn $iter)
  (let ($unscalarized-fit-score $scalarized-fit-score) ($fitness-fn $samples $iter)
    (let $fit-ind-pairs (pair-index-fitness (make-indices $scalarized-fit-score) $scalarized-fit-score)
        (let $desc-sorted-pairs (sort-pairs-desc $fit-ind-pairs)
            (let $extracted-indices (extract-indices $desc-sorted-pairs $mu)
                (let ($selected-sample $selected-unscalarized-fitscore $selected-scalarized-fitscore) ((select-by-indices $samples $extracted-indices) (select-by-indices $unscalarized-fit-score $extracted-indices) (select-by-indices $scalarized-fit-score $extracted-indices)) ((car-atom $selected-sample) (car-atom $selected-unscalarized-fitscore) (car-atom $selected-scalarized-fitscore)))
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
    (let* 
        (
            ($new-p-sigma (new-p-sigma $c-sigma $p-sigma $mu-eff $c-inv-sqrt $y))
            ($adaptingfactor (pow-math (e) (* (/ $c-sigma $d-sigma) (- (/ (l2-norm $new-p-sigma) (sqrt-math $dim)) 1))))
            ($adaptXsize (* $step-size $adaptingfactor))
        )
        ($adaptXsize $new-p-sigma)
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
        (Error ($obj $ref $weight) (IncorrectLength))
    )
)

(=(max-best-nd $best-nds $ref $iter $weights) 
    (let* (
        ($weight (index-atom $weights $iter))
        (($unzipped-best-nds $scalarized-fit-values) (unzip-list $best-nds))
        ($res (map-atom $unzipped-best-nds $best-nd (pbi-scalarization (index-atom $best-nd 1) $ref $weight)))
        ($rezipped-best-nds (zip-list $unzipped-best-nds $scalarized-fit-values))
        ($res-zipped-best-nds (zip-list $rezipped-best-nds $res))
        ($max-val (max-atom $res))
        ($result (max-best-nd-helper $max-val $res-zipped-best-nds))
    )
    $result
    )
)

;;;; Single-Objective CMA-ES ;;;;

; !(add-concepts)

!(bind! &single-cma-es-inputspace (new-space))
(= (add-to-single-cma-es-inputspace)
    (add-reduct &single-cma-es-inputspace (Inputs ((mean) (cov) (step_size) (p_sigma) (p_c) () -10000 0 0)))
)

(= (clean-from-single-cma-es-inputspace)
    (collapse (match &single-cma-es-inputspace (Inputs $params) (remove-atom &single-cma-es-inputspace (Inputs $params))))
)

(=(clean-from-space $space)
    (collapse (match $space $X (remove-atom $space $X)))
)


!(add-to-single-cma-es-inputspace)

(= (cma-es-single-iteration $fitness-fn)
    (let ($mean $cov $step-size $p-sigma $p-c $best-pop $best-fitness $gen $stall) (match &single-cma-es-inputspace (Inputs $x) $x)
        (if (>= $stall 10)                  ; patience = 10 gens
          ($best-pop $best-fitness)             
          (let*
            (
                (($normalized-weights $c-sigma $d-sigma $mu $mu-eff $dim) (collapse(superpose((normalized_weights) (c_sigma) (d_sigma) (mu) (mu_eff) (dim)))))
                ($samples (mat-clip (random-multivariate $mean (mat-scalar-op $cov (pow-math $step-size 2) *) (lambda_)) 0 1))
                (($new-mean $selected $fitness-score) (update-mean $samples $mu $normalized-weights $fitness-fn))
                (($new-best-fitness $new-best-pop) (let $gen-best-fitness (max-atom $fitness-score) (if (>= $gen-best-fitness $best-fitness) ($gen-best-fitness $selected) ($best-fitness $best-pop))))
                ($improved?  (> $new-best-fitness $best-fitness))
                ($new-stall  (if $improved? 0 (+ 1 $stall)))
                (($y $C-inv-sqrt) ((y $new-mean $mean $step-size) (C-inv-sqrt $cov)))
                (($new-step-size $new-p-sigma) (new-step-size $step-size $c-sigma $d-sigma $dim $p-sigma $mu-eff $C-inv-sqrt $y))
                (($new-cov $new-p-c) (new-cov $cov $p-c $new-p-sigma $c-sigma $gen $y $normalized-weights $selected $mean))
                ($clean (collapse (match &single-cma-es-inputspace (Inputs $params) (remove-atom &single-cma-es-inputspace (Inputs $params)))))
                ($_ (println!(GENERATION $gen |  Max Fitness $new-best-fitness  |  Stall $new-stall)))
            )
            (let $added (add-reduct &single-cma-es-inputspace (Inputs ($new-mean $new-cov $new-step-size $new-p-sigma $new-p-c $new-best-pop $new-best-fitness (+ 1 $gen) $new-stall))) ($new-best-pop $new-best-fitness)))
        )
    )
)

(= (cma-es-main-loop)
    (let $iters (generate-toy-list (GENERATIONS))  
        (map-atom $iters $iter (cma-es-single-iteration population-fitness-score))
    )
)

(= (Eval) True)

; !(cma-es-main-loop)
; !(blend cma-es-main-loop (Eval))

!(bind! &multi-single-iteration-cma-es-inputspace (new-space))
(= (add-to-multi-single-iteration-cma-es-inputspace)
    (add-reduct &multi-single-iteration-cma-es-inputspace (Inputs ((mean) (cov) (step_size) (p_sigma) (p_c) () -10000 -10000 0 0)))
)

(= (clean-from-multi-single-cma-es-inputspace)
    (collapse (match &multi-single-iteration-cma-es-inputspace (Inputs $params) (remove-atom &multi-single-iteration-cma-es-inputspace (Inputs $params))))
)

!(add-to-multi-single-iteration-cma-es-inputspace)

(= (moedd-cma-es-single-iteration $fitness-fn $iter)
    (let ($mean $cov $step-size $p-sigma $p-c $best-pop $best-unscalarized-fitness $best-scalarized-fitness $gen $stall) (match &multi-single-iteration-cma-es-inputspace (Inputs $x) $x)
        (let*
        (
            (($normalized-weights $c-sigma $d-sigma $mu $mu-eff $dim) (collapse(superpose((normalized_weights) (c_sigma) (d_sigma) (mu) (mu_eff) (dim)))))
            ($samples (mat-clip (random-multivariate $mean (mat-scalar-op $cov (pow-math $step-size 2) *) (lambda_)) 0 1))
            (($selected $unscalarized-fit-score $scalarized-fitness-score) (moedd-update-mean $samples $mu $normalized-weights $fitness-fn $iter))
            (($new-best-pop $new-best-unscalarized-fitness $new-best-scalarized-fitness) ((cons-atom $selected $best-pop) (if (== (get-metatype $best-unscalarized-fitness) Grounded) (cons-atom $unscalarized-fit-score ()) (cons-atom $unscalarized-fit-score $best-unscalarized-fitness))(if (== (get-metatype $best-scalarized-fitness) Grounded) (cons-atom $scalarized-fitness-score ()) (cons-atom $scalarized-fitness-score $best-scalarized-fitness))))
            ($clean (collapse (match &multi-single-iteration-cma-es-inputspace (Inputs $params) (remove-atom &multi-single-iteration-cma-es-inputspace (Inputs $params)))))
            ($cleanspace (collapse(superpose((clean-from-space &rmspace) (clean-from-space &cispace1) (clean-from-space &cispace2) (clean-from-space &cispace3)))))
        )
        (let $added (add-reduct &multi-single-iteration-cma-es-inputspace (Inputs ($mean $cov $step-size $p-sigma $p-c $new-best-pop $new-best-unscalarized-fitness $new-best-scalarized-fitness $gen $stall))) ($new-best-pop $new-best-unscalarized-fitness $new-best-scalarized-fitness))
        )
    )
)

;;;; Multi-Objective CMA-ES ;;;;

(= (Num-subproblems) 10)
(= (Num-objectives) 2)
(= (Weight) (let $nos (Num-subproblems) (np-dirichlet (1 1) $nos)))
(= (Moedd-cma-gen) 5)

!(bind! &multi-cma-es-inputspace (new-space))
!(add-reduct &multi-cma-es-inputspace (Inputs ((zeros-vec (Num-objectives)) () 0)))

(= (moedd-cma-es-single-generation $weights)
    (let*
        (
            (($ref-point $pop $gen) (match &multi-cma-es-inputspace (Inputs $x) $x))
            ($_ (println! (ref-point $ref-point | Generation $gen | Population Size (size-atom $pop))))
            ($add (add-atom &self (= (scalarized-fitness $samples $iter)
                                        (let* (
                                            ($objs (map-atom $samples $sample (objectives (concept1) (concept2) $sample)))
                                            ($weight (index-atom $weights $iter))
                                            ($result ($objs (map-atom $objs $obj (pbi-scalarization $obj $ref-point $weight))))
                                        )
                                        $result ))))                                  
            ($iters (let $iters-res (range 0 (- (Num-subproblems) 1)  1) $iters-res))
            (($sol $unscalarized-fit-score $scalarized-fit-score) (let $res (map-atom $iters $iter (moedd-cma-es-single-iteration scalarized-fitness $iter)) (index-atom $res (- (Num-subproblems) 1))))
            ($clean (collapse (match &multi-single-iteration-cma-es-inputspace (Inputs $params) (remove-atom &multi-single-iteration-cma-es-inputspace (Inputs $params)))))
            ($add (add-reduct &multi-single-iteration-cma-es-inputspace (Inputs ((mean) (cov) (step_size) (p_sigma) (p_c) () -10000 -10000 0 0))))
            (($new-ref-point $sub-candidates) (collapse(superpose((np-max $ref-point $unscalarized-fit-score 0) (let $first-zip (zip-list $sol $unscalarized-fit-score) (zip-list $first-zip $scalarized-fit-score))))))
            ($best-non-dominated (filter-non-dominated $sub-candidates))
            ($survivors (let $length (size-atom $best-non-dominated) (if (== $length 1) ($best-non-dominated) (map-atom $iters $iter (max-best-nd $best-non-dominated $new-ref-point $iter $weights)))))
            ($filtered-surv (unionize $survivors ()))
            ($new-pop (union-atom $filtered-surv $pop))
            ($filtered-pop (filter-non-dominated $new-pop))
            ($_ (println! (Generation $gen | Population $filtered-pop)))
            ($clean (collapse(match &self (= (scalarized-fitness $samples $iter)
                                        (let* (
                                            ($objs (map-atom $samples $sample (objectives (concept1) (concept2) $sample)))
                                            ($weight (index-atom $weights $iter))
                                            ($result ($objs (map-atom $objs $obj (pbi-scalarization $obj $ref-point $weight))))
                                        )
                                        $result )) (remove-atom &self (= (scalarized-fitness $samples $iter)
                                        (let* (
                                            ($objs (map-atom $samples $sample (objectives (concept1) (concept2) $sample)))
                                            ($weight (index-atom $weights $iter))
                                            ($result ($objs (map-atom $objs $obj (pbi-scalarization $obj $ref-point $weight))))
                                        )
                                        $result ))))))
            ($clean2 (collapse (match &multi-cma-es-inputspace (Inputs $x) (remove-atom &multi-cma-es-inputspace (Inputs $x)))))

        )
        (let $added (add-reduct &multi-cma-es-inputspace (Inputs ($new-ref-point $filtered-pop (+ $gen 1)))) $filtered-pop)
    )
)


(= (moedd-cma-es-main-loop)
    (let $weights (Weight) (let $iterations (range 0 (- (Moedd-cma-gen) 1) 1) (map-atom $iterations $iteration (moedd-cma-es-single-generation $weights))))
)

; !(moedd-cma-es-main-loop)
; !(blend moedd-cma-es-main-loop (Eval))
