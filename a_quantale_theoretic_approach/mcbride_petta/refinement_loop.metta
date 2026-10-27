;; =============================================================================
;; McBride Refinement Loop
;; =============================================================================
;; Implements the iterative gradient ascent from Algorithm 1 (Section 7.3):
;;   Run gradient steps until convergence or max-steps reached.
;;
;; Convergence: |σ(t) - σ(t-1)| < threshold for `patience` consecutive steps.
;; =============================================================================

!(import! &self a_quantale_theoretic_approach/mcbride_petta/gradient_step)

;; Convergence threshold & default patience
(= (mcbride-default-eta)   0.05)
(= (mcbride-default-steps) 20)
(= (mcbride-threshold) 0.0001)
(= (mcbride-patience)  5)

;; Native absolute difference keeps direct PeTTa execution self-contained.
(= (q-abs-diff $a $b)
   (if (>= $a $b)
       (- $a $b)
       (- $b $a)))

;; Use a single guarded rule. Separate base-case equations also unify with the
;; generic recursive equation in PeTTa and create an exponential result tree.
(= (q-refine-loop $blend $source-a $source-b $eta $steps $patience $prev-sigma)
   (if (or (<= $steps 0) (<= $patience 0))
       $blend
       (let* (($next-blend   (q-gradient-step $blend $source-a $source-b $eta))
              ($sigma-new    (q-emergence-tv $source-a $source-b $next-blend))
              ($delta        (q-abs-diff $sigma-new $prev-sigma))
              ($converged    (< $delta (mcbride-threshold)))
              ;; Patience counts consecutive converged steps.
              ($new-patience
                 (if $converged
                     (- $patience 1)
                     (mcbride-patience))))
          (q-refine-loop
             $next-blend $source-a $source-b $eta
             (- $steps 1) $new-patience $sigma-new))))

;; Public entry point with defaults
(= (q-mcbride-refine $blend $source-a $source-b)
   (let $sigma-init (q-emergence-tv $source-a $source-b $blend)
        (q-refine-loop $blend $source-a $source-b
                       (mcbride-default-eta)
                       (mcbride-default-steps)
                       (mcbride-patience)
                       $sigma-init)))

;; Parameterized entry point
(= (q-mcbride-refine-with $blend $source-a $source-b $eta $steps)
   (let $sigma-init (q-emergence-tv $source-a $source-b $blend)
        (q-refine-loop $blend $source-a $source-b $eta $steps (mcbride-patience) $sigma-init)))

;; Trace-bearing refinement for hybrid-search integration. The legacy public
;; operations above continue returning only the refined concept.
(= (q-refine-loop-result
      $blend $source-a $source-b $eta
      $remaining $threshold $patience-limit $patience-left
      $initial-sigma $previous-sigma $steps-taken)
   (if (<= $remaining 0)
       (McBrideRefinementResult MaxSteps $blend
          (McBrideRefinementTrace
             $steps-taken $initial-sigma $previous-sigma 0.0))
       (let* (
          ($next-blend
             (q-gradient-step $blend $source-a $source-b $eta))
          ($next-sigma
             (q-emergence-tv $source-a $source-b $next-blend))
          ($delta (q-abs-diff $next-sigma $previous-sigma))
          ($converged (< $delta $threshold))
          ($next-patience
             (if $converged
                 (- $patience-left 1)
                 $patience-limit))
          ($next-step-count (+ $steps-taken 1)))
          (if (<= $next-patience 0)
              (McBrideRefinementResult Converged $next-blend
                 (McBrideRefinementTrace
                    $next-step-count $initial-sigma $next-sigma $delta))
              (q-refine-loop-result
                 $next-blend $source-a $source-b $eta
                 (- $remaining 1) $threshold
                 $patience-limit $next-patience
                 $initial-sigma $next-sigma $next-step-count)))))

(= (q-mcbride-refine-result-with
      $blend $source-a $source-b
      $eta $steps $threshold $patience)
   (let $initial-sigma
      (q-emergence-tv $source-a $source-b $blend)
      (q-refine-loop-result
         $blend $source-a $source-b $eta
         $steps $threshold $patience $patience
         $initial-sigma $initial-sigma 0)))
