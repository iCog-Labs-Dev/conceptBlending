! (register-module! ../../an_infotheoretic_approach)
!(import! &self an_infotheoretic_approach:GA-imp)
!(import! &self libs)

;;;; SPACE BINDING AND POPULATING ;;;;
!(bind! &testspace (new-space))
!(add-atom &testspace (Individual (0.2 0.3) 0.1))
!(add-atom &testspace (Individual (0.2 0.3) 0.1))
!(add-atom &testspace (Individual (0.2 0.3) 0.1))
!(add-atom &testspace (Individual (0.2 0.4) 0.4))
!(add-atom &testspace (Individual (0.2 0.1) 0.05))
!(add-atom &testspace (Individual (0.2 0.65) 0.5))
!(add-atom &testspace (Individual (0.2 0.7) 0.6))
!(add-atom &testspace (Individual (0.2 0.8) 0.7))

;;;; add-list-to-space ;;;;

; Test add-list-to-space with a non-empty list of lists, and a space
; Output: all the elements or lists in the list will be added into the space

!(assertEqual
    (add-list-to-space ((1 2) (3 4) (6 9)) &testspace)
    (() () ())
) 

; Test add-list-to-space with an empty list, and a space
; Output: (Error () EmptyList)

!(assertEqual
    (add-list-to-space () &testspace)
    (Error () EmptyList)
)

;;;; match-single-individual ;;;;

; Test match-single-individual with a space that contains redundent data
; Output: returns a single atom that matched using match

!(assertEqual
    (match-single-individual &testspace 0.1)
    (0.2 0.3)
)

; ; Test match-single-individual with a value that deosn't exist in the space
; ; Output: Empty List

!(assertEqual
    (match-single-individual &testspace 0.2)
    ()
)

;;;; elite-individuals ;;;;

; Test elite-individuals with a space that contains individual-fitness pair, a list that contains fitness scores, and 3 elites to be returned
; Output: 3 top fitted individuals(i.e 3 elites)

!(assertEqual
    (elite-individuals (0.1 0.4 0.05 0.5 0.6 0.7) &testspace 3)
    ((0.2 0.8) (0.2 0.7) (0.2 0.65))
)

; Test elite-individuals with a space that contains individual-fitness  pair, a list that contains fitness scores, and 2 elites to be returned
; Output: 2 top fitted individuals(i.e 2 elites)

!(assertEqual
    (elite-individuals (0.1 0.4 0.05 0.5 0.6 0.7) &testspace 2)
    ((0.2 0.8) (0.2 0.7))
)

; Test elite-individuals with a space containing individual-fitness pair, empty list, and 2 elites to be returned
; Output: (Error () EmptyList)

!(assertEqual
    (elite-individuals () &testspace 2)
    (Error () EmptyList)
)

; Test elite-individuals with an empty space, a list containing fitness scores, and 2 elites to be returned
; Output: (Error &testspace EmptySpace)
; INFO: Make sure to comment out the add-atom lines at the top

; !(assertEqual
;     (elite-individuals (0.1 0.3) &testspace 2)
;     (Error &testspace EmptySpace)
; )

; Test elite-individuals with a non-empty space, a list containing 2 fitness scores, and 3 elites to be returned
; Output: 2 elites will be returned as we have only two fitness scores that we can use to match with individual-fitness pairs exist in the space
; INFO: empty list will be returned if the fitness score match isn't found in the space

!(assertEqual
    (elite-individuals (0.1 0.3) &testspace 3)
    (() (0.2 0.3))
)

;;;; sbx-genes ;;;;

; Test sbx-gene with a pair of two gene values, and eta
; Output: A pair of two gene values on which simulated binary crossover operation applied

!(assertEqual
    (let $x (sbx-genes (0.3 0.6) 2) (size-atom $x))
    2
)

;;;; sbx-crossover-individuals ;;;;

; Test sbx-crossover-individuals with two lists each containing 8 genes(parents), and eta
; Output: A pair of two lists each containing 8 genes(offsprings)

!(assertEqual
    (let ($x $y) (sbx-crossover-individuals (0.3 0.5 0.3 0.7 0.8 0.3 0.45 0.665) (0.23 0.54 0.66 0.7 0.12 0.65 0.7 0.8) 2) (collapse(superpose((size-atom $x) (size-atom $y)))))
    (8 8)
)

;;;; GA-blend ;;;;
;; INFO: The testing of this function applies for populate-two-child, populate-new-population, GA-single-iteration, and GA-main-loop too as it's(the main loop depends on the proper functioning of the two functions)

; Test GA-blend with two input concepts,  50 population size, ETA parameters, Mutation parameters, and 30 generations
; Output: The blend concept of the two input concepts.

!(assertEqual 
   (let ($net-type $exp-ver $blend $ext-ver) (let $space &self (metta (blend GA-main-loop) %Undefined% $space)) ($net-type $blend))
   (doubleScope BatMan)
)

;;;; GA-blend with evaluation ;;;;
; Output = the formed blend, and six optimality constraints(integration, good-reason, web, unpacking, topology, metonymy) evaluation scores
; !(assertEqual
;     (blend GA-main-loop True)
;     (Formed Blend: BatMan 
;     Evaluation-Metrics: 
;     Integration: 1.0 
;     Good-reason: (Conceptnet-score 0.0 LLM-score 0.75) 
;     Unpacking: 0.0 
;     Web: 0.0 
;     Topology: 0.0 
;     Metonymy: 0.0)
; )

;;;; space-based GA-blend ;;;;
; Output = The formed blend(inputs are fetched from the space)

; !(assertEqual
;    (let ($net-type $exp-ver $blend $ext-ver) (let $space &self (metta (space-blend blend GA-main-loop False) %Undefined% $space)) ($net-type $blend))
;    (doubleScope BatMan)
; )
