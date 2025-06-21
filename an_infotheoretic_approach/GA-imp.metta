! (import! &self utils:random-list-utils)
! (import! &self info-theoretic)
;! (import! &self utils:GA-utils)

;;;; SPACES ;;;;
!(bind! &fittestindividuals (new-space))


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
        ($nfitindiv (n-fit-individuals $popfitness &fittestindividuals (ELITE_COUNT)))
        )
        $nfitindiv
    )
)
