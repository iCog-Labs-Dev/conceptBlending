;;;; CMA-ES(Convolution Matrix Adaptation Evolution Strategy) Implementation.




(: lambda-calc (Number Number -> Number))
(= (lambda-calc $population_size $dim)
   (if (== $population_size 0)                                      
       (+ 4
          (floor-math (* 3 (log-math 2.718281828459045 $dim))))     
       $population_size))    
                                           
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

(: raw-weights (Number -> List))
(= (raw-weights $mu)
   (let* (
          ($idxs  (range 1 $mu 1))                             
          ($const (log-math 2.718281828459045 (+ $mu 0.5)))
         )
         (map-atom $idxs $i
                   (- $const (log-math 2.718281828459045 $i)))))    

(: mu-calc (Number -> Number))
(= (mu-calc $lambda) (floor-math (/ $lambda 2)))

(: norm-weights (List -> List))
(= (norm-weights $w_raw)
   (let* (
          ($sum_w  (foldl-atom $w_raw 0 $acc $x (+ $acc $x)))
         )
         (map-atom $w_raw $w (/ $w $sum_w))))

(: mu-eff (List -> Number))
(= (mu-eff $weights)
   (let* (
           ($squares (map-atom $weights $w (* $w $w)))
           ($sum_sq (foldl-atom $squares 0 $acc $x (+ $acc $x)))
         )
         (/ 1 $sum_sq)))


        