;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; CMA-ES implementation using Python Numpy bindings ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; A Covariance Matrix Adaptation Evolution Strategy (CMA-ES)
;; implementation in Metta using Python Numpy for numerical computations.
;; This implementation follows the standard CMA-ES algorithm structure.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;-----------------------------------
; Python & Numpy bindings
;-----------------------------------
!(import! &self main)
!(bind! np (py-atom numpy))
!(bind! np_rand (py-atom numpy.random.rand))
!(bind! np_sqrt (py-atom numpy.sqrt))
!(bind! np_identity (py-atom numpy.identity))
!(bind! np_subtract (py-atom numpy.subtract))
!(bind! np_multiply (py-atom numpy.multiply))
!(bind! np_divide (py-atom numpy.divide))
!(bind! np_add (py-atom numpy.add))
!(bind! np_sum (py-atom numpy.sum))
!(bind! np_log (py-atom numpy.log))
!(bind! np_arange (py-atom numpy.arange))
!(bind! np_matmul (py-atom numpy.matmul))
!(bind! np_int8 (py-atom numpy.int8))
!(bind! np_zeros (py-atom numpy.zeros))
!(bind! np_take (py-atom numpy.take))
!(bind! np_size (py-atom numpy.size))
!(bind! np_power (py-atom numpy.power))
!(bind! np_dot (py-atom numpy.dot))
!(bind! np_inv (py-atom numpy.linalg.inv))
!(bind! np_max (py-atom numpy.max))
!(bind! np_min (py-atom numpy.min))
!(bind! np_exp (py-atom numpy.exp))
!(bind! np_multivariate_normal (py-atom numpy.random.multivariate_normal))
!(bind! np_apply_along_axis (py-atom numpy.apply_along_axis))
!(bind! np_argsort (py-atom numpy.argsort))
!(bind! np_cholesky (py-atom numpy.linalg.cholesky))
!(bind! np_norm (py-atom numpy.linalg.norm))
!(bind! np_outer (py-atom numpy.outer))
!(bind! np_argmin (py-atom numpy.argmin))

;-----------------------------------
; Helper functions for CMA-ES calculations
;-----------------------------------

(= (compute_weights $pop_size)
        (let $w
                (np_subtract (np_log (+ $pop_size 0.5)) (np_log (np_arange 1 (+ $pop_size 1))))
                (np_divide $w (np_sum $w))))

(= (compute_mu_eff $weights)
        (np_divide 1.0 (np_sum (np_power $weights 2))))

(= (compute_c_sigma $n_params $mu_eff)
        (np_divide (+ $mu_eff 2) (+ 5 (+ $n_params $mu_eff))))

(= (compute_d_sigma $n_params $mu_eff $c_sigma)
        (+ (+ 1 $c_sigma)
           (* 2 (np_max (py-list (0.0 (- (np_sqrt (np_divide (- $mu_eff 1) (+ $n_params 1))) 1)))))))

(= (compute_c_c $n_params $mu_eff)
        (np_divide (+ 4 (np_divide $mu_eff $n_params)) (+ $n_params (+ 4 (* 2 (np_divide $mu_eff $n_params))))))

(= (compute_c1 $n_params $mu_eff)
        (/ 2 (+ (np_power (+ $n_params 1.3) 2) $mu_eff)))

(= (compute_c_mu $n_params $mu_eff $c1)
        (np_min (py-list (
                        (- 1 $c1)
                        (np_divide (np_multiply 2 (np_add (np_subtract $mu_eff 2) (np_divide 1 $mu_eff)))
                                           (np_add (np_power (np_add $n_params 2) 2) $mu_eff))))))


(= (compute_elites $samples $fitness_values $weights)
        (let* (
                        ($sorted_idx (np_argsort $fitness_values)))
                (np_take $samples (np_take $sorted_idx (np_arange (np_size $weights))) (np_int8 0))))

(= (compute_new_mean $weights $elites)
        (np_dot $weights $elites))

(= (compute_y $new_mean $mean)
        (np_subtract $new_mean $mean))

(= (compute_inv_sqrt_cov $cov)
        (py-dot (np_inv (np_cholesky $cov)) T))

(= (compute_p_sigma_new $p_sigma $c_sigma $mu_eff $inv_sqrt_cov $y $sigma)
        (np_add
                (np_multiply (- 1 $c_sigma) $p_sigma)
                (np_multiply
                        (np_sqrt (np_multiply $c_sigma (np_multiply (np_subtract 2 $c_sigma) $mu_eff)))
                        (np_matmul $inv_sqrt_cov (np_divide $y $sigma)))))

(= (compute_sigma_new $sigma $d_sigma $c_sigma $n_params $p_sigma_new)
        (np_multiply $sigma
                (np_exp (np_multiply $d_sigma (np_multiply (np_subtract (np_divide (np_norm $p_sigma_new) (np_sqrt $n_params)) 1) $c_sigma)))))

(= (compute_h_sigma $p_sigma_new $c_sigma $n_params $i)
        (let $tv
                (< (np_divide (np_norm $p_sigma_new) (np_sqrt (np_subtract 1 (np_power (- 1 $c_sigma) (np_add (* 2 $i) 1)))))
                   (+ 1.4 (np_divide 2 (+ $n_params 1))))
                (if $tv 1 0)))

(= (compute_p_c_new $p_c $c_c $h_sigma $mu_eff $y $sigma)
        (np_add
                (np_multiply (np_subtract 1 $c_c) $p_c)
                (np_multiply $h_sigma (np_multiply (np_sqrt (np_multiply $c_c (np_multiply (np_subtract 2 $c_c) $mu_eff))) (np_divide $y $sigma)))))

(= (compute_armtp $elites $mean $sigma_new)
        (np_divide (np_subtract $elites $mean) $sigma_new))

(= (compute_cov_new $cov $c_mu $c1 $p_c_new $h_sigma $c_c $weights $armtp)
        (np_add
                (np_multiply (np_subtract 1 (np_subtract $c_mu $c1)) $cov)
                (np_add
                        (np_multiply $c1
                                (np_add
                                        (np_outer $p_c_new $p_c_new)
                                        (np_multiply (np_multiply (np_subtract 1 $h_sigma) $c_c)
                                                                  (np_multiply (np_subtract 2 $c_c) $cov))))
                        (np_multiply $c_mu (np_dot (np_multiply $weights (py-dot $armtp T)) $armtp)))))

(= (compute_new_best_w $samples $fitness_values)
        (np_take $samples (np_argmin $fitness_values) (np_int8 0)))


;-----------------------------------
; CMA-ES algorithm

;; CMA-ES main loop
(= (cma_es_loop $fitness_fn $n_params $max_iter $pop_size $mean $cov $sigma $weights $mu_eff $c_sigma $d_sigma $c_c $c1 $c_mu $p_c $p_sigma $best_w $i)
    (if (>= $i $max_iter)
        ($best_w (np_subtract 1.0 ($fitness_fn $best_w)))
        (let* (
                ; Sample offspring
                ($samples (np_multivariate_normal $mean (np_multiply $cov (np_power $sigma 2)) $pop_size))

                ; Evaluate fitness
                ($fitness_values (np_apply_along_axis $fitness_fn 1 $samples))
                ($elites (compute_elites $samples $fitness_values $weights))

                ; Recompute mean
                ($new_mean (compute_new_mean $weights $elites))

                ; update evolution paths
                ($y (compute_y $new_mean $mean))
                ($inv_sqrt_cov (compute_inv_sqrt_cov $cov))
                ($p_sigma_new (compute_p_sigma_new $p_sigma $c_sigma $mu_eff $inv_sqrt_cov $y $sigma))
                ($sigma_new (compute_sigma_new $sigma $d_sigma $c_sigma $n_params $p_sigma_new))
                ($h_sigma (compute_h_sigma $p_sigma_new $c_sigma $n_params $i))
                ($p_c_new (compute_p_c_new $p_c $c_c $h_sigma $mu_eff $y $sigma))

                ; Covariance update
                ($armtp (compute_armtp $elites $mean $sigma_new))
                ($cov_new (compute_cov_new $cov $c_mu $c1 $p_c_new $h_sigma $c_c $weights $armtp))
                ($new_best_w (compute_new_best_w $samples $fitness_values)))
            (cma_es_loop $fitness_fn $n_params $max_iter $pop_size $new_mean $cov_new $sigma_new $weights $mu_eff $c_sigma $d_sigma $c_c $c1 $c_mu $p_c_new $p_sigma_new $new_best_w (+ $i 1)))))

;; CMA-ES main 
;; Parameters:
;;    fitness: A function that takes an individual (list of parameters) and returns its fitness score
;;    n_params: Number of parameters (dimensions) of the individuals
;;    max_iter: Maximum number of iterations (generations)
;;    pop_size: Population size (number of individuals per generation)
(= (cma_es $fitness $n_params $max_iter $pop_size)
    (let* (
            ; Initial mean, step size (sigma), and covariance
            ($mean (np_rand $n_params))
            ($cov (np_identity $n_params))
            ($sigma 0.3)

            ; CMA constants
            ($weights (compute_weights $pop_size))
            ($mu_eff (compute_mu_eff $weights))
            ($c_sigma (compute_c_sigma $n_params $mu_eff))
            ($d_sigma (compute_d_sigma $n_params $mu_eff $c_sigma))
            ($c_c (compute_c_c $n_params $mu_eff))
            ($c1 (compute_c1 $n_params $mu_eff))
            ($c_mu (compute_c_mu $n_params $mu_eff $c1))
            ($p_c (np_zeros $n_params))
            ($p_sigma (np_zeros $n_params)))
        (cma_es_loop $fitness $n_params $max_iter $pop_size $mean $cov $sigma $weights $mu_eff $c_sigma $d_sigma $c_c $c1 $c_mu $p_c $p_sigma Nil 0)))


; !(cma_es fitness! 5 10 10)