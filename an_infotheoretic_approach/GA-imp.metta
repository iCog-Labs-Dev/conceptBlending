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
