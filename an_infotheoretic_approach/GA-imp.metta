! (import! &self utils:random-list-utils)
! (import! &self info-theoretic)

;; ==== SEED FOR REPRODUCIBILITY ====
! (bind! np-rnd (py-atom numpy.random))
; ! ((py-dot np-rnd seed) 42)

;;;; SPACES ;;;;
!(bind! &fittestindividuals (new-space))

;;;; PARAMETERS ;;;;
(= (POP_SIZE) 50)
(= (GENES) 8)
(= (GENERATIONS) 30)
(= (ELITE_COUNT) 3)
(= (CROSSOVER_RATE) 0.9)
;; Mutation_rate, Initial_Mutation_STD, and Mutation_Decay respectively
(= (MUTATION_PARAM) (0.5 0.95))
(= (MUTATION_RATE) 0.5)
(= (random)((py-dot np-rnd random)))
(= (gauss $std) ((py-dot np-rnd normal) 0 $std))
;; Initial_SBX_STD, and SBX_ETA_Growth respectively
(= (ETA_PARAM) (2 1.05))
;!(gauss 0.5)
;;;; INITIAL POPULATION ;;;;
; !(random-list (POP_SIZE) (GENES) 0 1)


; Roulette Wheel Selection 
(: roulette-select (List List -> Any))
(= (roulette-select $population $fitnesses)
   (
      let* (
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
; Output [0.8]


;; Helper Function to get the second element of the Pair
(= (get-second $pair)
   (let* (($cdr (cdr-atom $pair))) ; extract tail of the pair
        (car-atom $cdr)           ; head of the tail is second element
   )
)

(=(sbx_crossover $p1 $p2 $eta)
(if (> 0.5 (CROSSOVER_RATE))
    ($p1 $p2) 
    (sbx_gene $p1 $p2 $eta)
 ))

(=(sbx_gene $x1 $x2 $eta)
(if (<= (abs-math(- $x1 $x2)) 1e-14)
( $x1 $x2)
(let* (
    ($xl (min-atom ($x1 $x2)))
    ($xh (max-atom ($x1 $x2)))
    ($rand (random))
    ($beta (+ 1.0 (* 2.0 (/ $xl (- $xh $xl)))))
    ($alpha (- 2.0 (pow-math $beta (- 0.0 (+ $eta 1.0)))))
    ; (() (println! $alpha))
    ($betaq (if (<= $rand (/ 1.0 $alpha))
                (pow-math (* $rand $alpha) (/ 1.0 (+ $eta 1.0)))
                (pow-math (/ 1.0 (- 2.0 ( * $rand $alpha))) (/ 1.0 (+ $eta 1.0)))))
    ; (() (println! ("BE"$betaq)))
    ($c1 (max-atom ((min-atom ((/ (- (+ $xl $xh) (* $betaq (- $xh $xl))) 2.0) 1.0)) 0.0)))
    ; (() (println! $c1))
    ($c2 (max-atom ((min-atom ((/ (+ (+ $xl $xh) (* $betaq (- $xh $xl))) 2.0) 1.0)) 0.0)))
)
($c1 $c2)
)
)
)
;; Base Case
(= (sbx_crossover_list () () $eta)
   ( () () )  ;; return two empty lists
)
(= (sbx_crossover_list $list1 $list2 $eta)
   (let* (
      ($x1 (car-atom $list1))
    ;   (() (println! ("X1" $x1)))
      ($x2 (car-atom $list2))
    ;   (() (println! ("X2" $x2)))
      ($t1 (cdr-atom $list1))
    ;   (() (println!( "T1"$t1 )))
      ($t2 (cdr-atom $list2))
    ;   (() (println!( "T2"$t2 )))
      ($pair (sbx_crossover $x1 $x2 $eta))
      ;  (() (println!( "pair" $pair )))
      ($c1 (first-from-pair $pair))
      ;  (() (println! ("C1"$c1)))
      ($c2 (get-second $pair))
      ;  (() (println! ("C2"$c2)))
      ($rest (sbx_crossover_list $t1 $t2 $eta))
      ;  (() (println! ("rest" $rest)))
      ($rest1 (first-from-pair $rest))
      ; (() (println! ("rest1" $rest1)))
      ($rest2 (get-second $rest))
      ; (() (println! ("rest2" $rest2)))
   )
   ((cons-atom $c1 $rest1) (cons-atom $c2 $rest2)))
)

; ! (sbx_crossover_list 
;      (0.8049752249385809 0.00860769711541609 0.5493969678679462 0.48351403591210507)
;      (0.04314990236803995 0.8138311131947542 0.6047275456474215 0.018442968436819696)
;      2.0
; )

; Example Output
;[((0.09033706260063018 0.03160994601048184 0.5507596758996745 0.06223446850446518) (0.7577880647059907 0.7908288642996885 0.6033648376156933 0.4397225358444596))]



;; ==== CLAMP FUNCTION ====
(: clamp (Number -> Number))
(= (clamp $x)
   (if (< $x 0) 0 (if (> $x 1) 1 $x))
)

;; ==== MUTATE GENE ====
(: mutate_gene (Number Number -> Number))
(= (mutate_gene $gene $std)
   (if (< (random) (MUTATION_RATE))
       (clamp (+ $gene (gauss $std)))
       $gene
   )
)

;; ==== MUTATE LIST ====
(: mutate_list (List Number -> List))
(= (mutate_list () $std) ())
(= (mutate_list $genes $std)
   (let* (
          ($head (car-atom $genes))
          ($tail (cdr-atom $genes))
          ($mutated-head (mutate_gene $head $std))
          ($mutated-tail (mutate_list $tail $std))
       )
       (cons-atom $mutated-head $mutated-tail)
   )
)


;; ==== Output ====

;[((0.14657740354356366 0.5 0.7104228400171473 0.1 0.33858887366361495 0.6384209255140325 0.7 0.8413943283960914))]

(= (initial-population) (random-list (POP_SIZE) (GENES) 0 1))

;;;; INPUT CONCEPTS ;;;;
(= (concept1) 
    (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7)))
)
(= (concept2) 
    (Concept Spider@Man (Property (mobility 0.8) (intelligence 0.2) (web-creation 1.0) (social-structure 0.3) (predatory-behavior 0.9) (communication 0.4) (symbolism 0.6) (physical-strength 0.3)))
)

;;;; POPULATION FITNESS SCORE CALCULATION ;;;;
;!(mu-hqblend (0.9030899869919434 0.9030899869919434 0.9030899869919434 0.9030899869919434 0.9030899869919434 0.9030899869919434 0.9030899869919434 0.9030899869919434) (concept1) (concept2))

(= (population-fitness-score $population) 
    (map-atom $population $x (mu-hqblend $x (concept1) (concept2)))
)

;;;; NEW POPULATION POPULATING LOOP ;;;;
(= (populate-new-population $population $fitness $elitepop $eta $std $emplist)
    (
      if (>= (size-atom $emplist) (POP_SIZE))
      $elitepop
      (
        let* (
          (($parent1 $parent2) (collapse(superpose((roulette-select $population $fitness) (roulette-select $population $fitness)))))
          (($child1 $child2) (sbx_crossover_list $parent1 $parent2 $eta))
          (($mutated-child1 $mutated-child2) (collapse(superpose((mutate_list $child1 $std) (mutate_list $child2 $std)))))
          (() (println! ("Mutated childs" $mutated-child1 $mutated-child2)))
          ($newpoplist (chain (cons-atom $mutated-child1 $emplist) $x (cons-atom $mutated-child2 $x)))
          ($new-population (populate-new-population $population $fitness $elitepop $eta $std $newpoplist))
        )
        (chain (cons-atom $mutated-child1 $new-population) $x (cons-atom $mutated-child2 $x))
      )
    )
)

;!(population-fitness-score (initial-population))

;!(initial-population)

;!(let $population (initial-population) (zip-list $population (population-fitness-score $population)))


!(let $population (initial-population) 
    (let* (
        ($popfitness (population-fitness-score $population))
        (() (println! $popfitness))
        ($zippedpopfit (zip-list $population $popfitness))
        (() (println! $zippedpopfit))
        ($added (add-list-element-to-space $zippedpopfit &fittestindividuals))
        ($nfitindiv (n-fit-individuals1 $popfitness &fittestindividuals (ELITE_COUNT)))
        ; ($rempopnum (- (POP_SIZE) (size-atom $nfitindiv)))
        (($mutstd $mutdecay) (MUTATION_PARAM))
        (($initeta $etagrowth) (ETA_PARAM))
        ($new-population (populate-new-population $population $popfitness $nfitindiv $initeta $mutstd ()))
        )
        $new-population
    )
)
