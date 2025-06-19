! (import! &self utils:random-list-initializer)

;;;; PARAMETERS ;;;;
(= (POP_SIZE) 50)
(= (GENES) 8)
(= (GENERATIONS) 30)
(= (ELITE_COUNT) 3)
(= (CROSSOVER_RATE) 0.9)
;; Mutation_rate, Initial_Mutation_STD, and Mutation_Decay respectively
(= (MUTATION_PARAM) (0.1 0.5 0.95))
;; Initial_SBX_STD, and SBX_ETA_Growth respectively
(= (ETA_PARAM) (2 1.05))

;;;; INITIAL POPULATION ;;;;
!(random-list (POP_SIZE) (GENES) 0 1)


; Roulette Wheel Selection 
(: roulette-select (List List -> Any))
(= (roulette-select $population $fitnesses)
   (let* (
           ($w-max (max-atom $fitnesses))          ; highest fitness 
           ($n     (size-atom $population))        ; list length     
         )
     (roulette-loop $population $fitnesses $w-max $n)))

 (: roulette-loop (List List Number Number -> Any))
    (= (roulette-loop $pop $fits $w-max $n)
    (let* (
            ($i (random-int &rng 0 $n)) 
            ($r (random-float &rng 0 1))                       
            ($fit-i (index-atom  $fits $i))          
            )
    (if (< $r (/ $fit-i $w-max))                
        (index-atom $pop $i)
        (roulette-loop $pop $fits $w-max $n))))
; Output [4]