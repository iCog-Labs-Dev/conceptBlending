;;;; CMA-ES(Convolution Matrix Adaptation Evolution Strategy) Implementation.




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


