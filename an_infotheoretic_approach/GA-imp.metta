!(import! &self libs)
!(import! &self utils:random-list-utils)
!(import! &self info-theoretic)
!(import! &self utils:GA-utils)

;; ==== SEED FOR REPRODUCIBILITY ====
! (bind! np-rnd (py-atom numpy.random))

;;;; SPACES ;;;;
!(bind! &individuals (new-space))

;;;; SPACE GETTER METHOD ;;;;
(= (get-space) (new-space))

;;;; PARAMETERS ;;;;
(= (POP_SIZE) 50)
(= (GENES) 8)
(= (GENERATIONS) 15)
(= (ELITE_COUNT) 3)
(= (CROSSOVER_RATE) 0.9)
;; Initial_Mutation_STD, and Mutation_Decay respectively
(= (MUTATION_PARAM) (0.5 0.95))
(= (MUTATION_RATE) 0.5)
(= (random)((py-dot np-rnd random)))
(= (gauss $std) ((py-dot np-rnd normal) 0 $std))
;; Initial_SBX_ETA, and SBX_ETA_Growth respectively
(= (ETA_PARAM) (2 1.05))

;;;; INPUT CONCEPTS ;;;;
(= (testconcept1) 
    (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7)))
)
(= (testconcept2) 
    (Concept Spider@Man (Property (mobility 0.8) (intelligence 0.2) (web-creation 1.0) (social-structure 0.3) (predatory-behavior 0.9) (communication 0.4) (symbolism 0.6) (physical-strength 0.3)))
)

(= (Input1) "Bat")
(= (Input2) "Man")

;;;; POPULATION INITIALIZER FUNCTION ;;;;
(= (initialize-population) (random-list (POP_SIZE) (GENES) 0 1))

;;;; POPULATION FITNESS SCORE CALCULATION ;;;;
(= (population-fitness-score $population) 
    (map-atom $population $x (mu-hqblend $x (concept1) (concept2)))
)

; Roulette Wheel Selection 
(: roulette-select (List List -> Number))
(= (roulette-select $population $fitnesses)
   (let* (
           ($popSize (size-atom $population))
           ($fitSize (size-atom $fitnesses))
         )
     (if (or (== $popSize 0) (== $fitSize 0))
         (Error (quote (roulette-select $population $fitnesses)) EmptyList)
         
         (if (not (== $popSize $fitSize))
             (Error (quote (roulette-select $population $fitnesses)) LengthMismatch)
             
             (let* (
                     ($w-max (max-atom $fitnesses))
                   )
               (if (== $w-max 0)
                   (Error (quote (roulette-select $population $fitnesses)) ZeroMaxFitness)
                   
                   (roulette-loop $population $fitnesses $w-max $popSize)
               )
             )
         )
     )
   )
)

 (: roulette-loop (List List Number Number -> Any))
    (= (roulette-loop $pop $fits $w-max $n)
    (let* (
            ($i (random-int &rng 0 $n)) 
            ($r (random-float &rng 0 1))                       
            ($fit-i (index-atom  $fits $i))
        )
        (if (< $r (/ $fit-i $w-max))                
            (index-atom $pop $i)
            (roulette-loop $pop $fits $w-max $n)
        )
    )
)

;;;; NON_DETERMINISTIC IMPLEMENTATION OF SBX CROSSOVER ;;;;
(=(sbx-genes ($x1 $x2) $eta)
    (
        if (and (<= (random) 0.5) (> (abs-math(- $x1 $x2)) 1e-14))
        (let* 
            (
                (($xl $xh) (collapse(superpose((min-atom ($x1 $x2)) (max-atom ($x1 $x2))))))
                ($rand (random))
                ($beta  (+ 1.0 (* 2.0 (/ $xl (- $xh $xl)))))
                ($alpha (- 2.0 (pow-math $beta (- 0.0 (+ $eta 1.0)))))
                ($betaq (if (<= $rand (/ 1.0 $alpha))
                            (pow-math (* $rand $alpha) (/ 1.0 (+ $eta 1.0)))
                            (pow-math (/ 1.0 (- 2.0 ( * $rand $alpha))) (/ 1.0 (+ $eta 1.0)))))
                (($c1 $c2) (collapse(superpose((max-atom ((min-atom ((/ (- (+ $xl $xh) (* $betaq (- $xh $xl))) 2.0) 1.0)) 0.0)) (max-atom ((min-atom ((/ (+ (+ $xl $xh) (* $betaq (- $xh $xl))) 2.0) 1.0)) 0.0))))))
            ) 
            ($c1 $c2)
        )
        ($x1 $x2)
    )
)

(= (sbx-crossover-individuals $list1 $list2 $eta)
    (let*
        (
            ($zipped (zip-list $list1 $list2))
            ($crossedovergenes (map-atom $zipped $x (sbx-genes $x $eta)))
            ($unzipped (unzip-list $crossedovergenes))
        )
        $unzipped
    )
)

;;;; NON_DETERMINSTIC MUTATION IMPLEMENTATION ;;;;

;; ==== MUTATE GENE ====
(: mutate-gene (Number Number -> Number))
(= (mutate-gene $gene $std)
   (
        if (< (random) (MUTATION_RATE))
        (clamp (+ $gene (gauss $std)))
        $gene
   )
)

(= (mutate-individual $genes $std)
    (collapse(mutate-gene (superpose $genes) $std))
)

;;;; NEW POPULATION POPULATING LOOP ;;;;
(= (populate-two-child $population $fitness $eta $std)
    (let* 
        (
            (($parent1 $parent2) (collapse(superpose((roulette-select $population $fitness) (roulette-select $population $fitness)))))
            (($child1 $child2) (if (> (random) (CROSSOVER_RATE)) ($parent1 $parent2) (sbx-crossover-individuals $parent1 $parent2 $eta)))
            ; (() (println! "Running Mutation"))
            (($mutated-child1 $mutated-child2) (collapse(superpose((mutate-individual $child1 $std) (mutate-individual $child2 $std)))))
        )
        ($mutated-child1 $mutated-child2)
    )
)

(= (populate-new-population $population $fitness $elitepop $eta $std)
    (let*
        (
            ($toy-list (generate-toy-list (round-math (/ (decimal (- (POP_SIZE) (ELITE_COUNT))) 2.0))))
            ($new-pop (map-atom $toy-list $x (populate-two-child $population $fitness $eta $std)))
            ($unzipped-new-pop (unzip-list $new-pop))
            ($merged-new-pop (merge-list (index-atom $unzipped-new-pop 0) (index-atom $unzipped-new-pop 1)))
            ($merged-new-pop-elites (merge-list $merged-new-pop $elitepop))
        )
        $merged-new-pop-elites
    )
)

!(bind! &inputspace (get-space))
!(add-reduct &inputspace (Inputs ((initialize-population) (ETA_PARAM) (MUTATION_PARAM) 0 -10000 0)))

!(add-concepts)

(= (GA-single-iteration)
    (let ($population ($init-eta $eta-growth) ($init-mut-std $mut-decay) $generation-number $best-fitness $stall) 
     (match &inputspace (Inputs $x) $x)
     (if (>= $stall 3)
            ($population $best-fitness)
        (let* (
            ($popfitness (population-fitness-score $population))
            ($zippedpopfit (zip-list $population $popfitness))
            ($add (add-list-to-space $zippedpopfit &individuals))
            ($elites (elite-individuals $popfitness &individuals (ELITE_COUNT)))
            ($new-population (populate-new-population $population $popfitness $elites $init-eta $init-mut-std))
            ($new-population-clipped (if (== (size-atom $new-population) (POP_SIZE)) $new-population (cdr-atom $new-population)))
            (($upd-eta $upd-mut-std)(collapse (superpose ( (* $init-eta $eta-growth) (* $init-mut-std $mut-decay) ))))
            ($max-fitness (max-atom $popfitness))
            ($new-best-fitness (if (> $max-fitness $best-fitness) $max-fitness $best-fitness))
            ($new-stall (if (> $max-fitness $best-fitness) 0 (+ 1 $stall)))
            ($clean (collapse (match &inputspace (Inputs $params) (remove-atom &inputspace (Inputs $params)))))
            (() (println! (GENERATION $generation-number | Max Fitness $max-fitness | Stall $new-stall)))
        )
        (let $added (add-reduct &inputspace (Inputs ($new-population-clipped ($upd-eta $eta-growth) ($upd-mut-std $mut-decay) (+ 1 $generation-number) $new-best-fitness $new-stall))) ($new-population $max-fitness)))
     )
  )   
)

(= (GA-main-loop)
    (let $iters (generate-toy-list (GENERATIONS)) (map-atom $iters $iter (GA-single-iteration)))
)

!(blend GA-main-loop)