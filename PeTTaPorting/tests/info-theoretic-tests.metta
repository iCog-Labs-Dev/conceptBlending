!(import! &self ../info-theoretic)

; Test get-prop-value-pairs
!(test
    (get-prop-value-pairs (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))))
    ((mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))
)

; Test get-property
!(test
    (get-property (mobility 0.9))
    mobility
)

; Test get-properties
!(test
    (get-properties ((web-creation 1.0) (intelligence 0.4) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1)))
    (web-creation intelligence physical-strength mobility predatory-behavior social-structure symbolism tool-use)
)

; Test get-value
!(test
    (get-value (web-creation 0.3))
    0.3
)

; Test get-values
!(test
    (get-values ((mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7)))
    (0.9 0.9 0.0 0.8 0.2 0.9 0.7 0.7)
)

; Test get-values with get-prop-value-pairs
!(test
    (get-values (get-prop-value-pairs (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7)))))
    (0.9 0.9 0.0 0.8 0.2 0.9 0.7 0.7)
)


; Test property-product
!(test
    (property-product ((web-creation 0.1) (intelligence 0.2) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1)) ((web-creation 1.0) (intelligence 0.4) (physical-strength 0.1) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1)))
    ((web-creation 0.1) (intelligence 0.08000000000000002) (physical-strength 0.06) (mobility 0.6400000000000001) (predatory-behavior 1.0) (social-structure 0.04000000000000001) (symbolism 0.48999999999999994) (tool-use 0.010000000000000002))
)

; Test get-number-of-properties
!(test
    (get-number-of-properties (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))))
    8
)

; Test decimal
!(test
    (decimal 1)
    1.0
)

; Test property-probability
!(test
    (property-probability (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))))
    0.125
)

; Test property-degree
!(test
    (property-degree (Concept Spider@Man (Property (web-creation 1.0) (intelligence 0.4) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
    0.9
)

; Test property-min
!(test
    (property-min (Concept Spider@Man (Property (web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))) (Concept Spider@Man (Property (web-creation 1.0) (intelligence 0.4) (physical-strength 0.2) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
    ((web-creation 0.1) (intelligence 0.3) (physical-strength 0.2) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))
)

; Test property-max
!(test
    (property-max (Concept Spider@Man (Property (web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))) (Concept Spider@Man (Property (web-creation 1.0) (intelligence 0.4) (physical-strength 0.2) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
    ((web-creation 1.0) (intelligence 0.4) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))
)

; Test binary-shannon-entropy
!(test (binary-shannon-entropy 0) 0)
!(test (binary-shannon-entropy 0.5) 1.0)

; Test joint-entropy-compute
!(test
   (joint-entropy-compute (0.5 1 0.25 4 5) min)
   (1.0 1.5 0.5 0.5 0.8112781244591328 0 0 0.5 0.5 0))

;Test total correlation entopy
!(test
   (total-correlation-entropy (0.5 0.5 0.5) min)
   0.6666666666666666)
!(test 
   (total-correlation-entropy (0.5 0.5 0.5) max)
   0.3333333333333333)
; Test coherence
!(test (let $res (coherence (color shape size) (0.5 0.25 0.75)) (truncate $res 5)) 0.32954)
!(test (let $res (coherence (a b c) (0.5 0.5 0.5)) (truncate $res 5)) 0.43552)
!(test (let $res (coherence (a b c) (0.1 0.8 0.9)) (truncate $res 5)) 0.56402)

;Test filter-non-dominated 
(= (candidates-list) ((((1 1 1 1 1 1) (7 9.1)) 0.5) (((1 0 1 0 1 0) (2 3)) 1) (((1 1 0 0 1 1) (6 8)) 1.5) (((1 1 1 0 0 0) (2 3)) 0.7) (((1 1 0 0 1 1) (4 6)) 2) (((1 1 1 1 1 0) (8 9)) 0.65) (((0 0 0 0 0 1) (3 5)) 0.98) (((0 0 0 0 1 1) (4 6)) 0.76)))

!(test (filter-non-dominated (candidates-list)) ((((1 1 1 1 1 1) (7 9.1)) 0.5) (((1 1 1 1 1 0) (8 9)) 0.65)))

;;;; objectives ;;;;
;;;; Test objectives with a list containing candidate's degree values, and two input concepts 
; Ouput = mu-hqblend and coherence value for the candidate

(= (infotestconcept1) 
    (Concept Man@Bat (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7)))
)

(= (infotestconcept2) 
    (Concept Bat@Man (Property (mobility 0.8) (intelligence 0.2) (web-creation 1.0) (social-structure 0.3) (predatory-behavior 0.9) (communication 0.4) (symbolism 0.6) (physical-strength 0.3)))
)

(= (testcandidatedegrees)
    (0.4 0.5 0.6 0.3 0.6 0.7 0.8 0.9)
)

!(test
    (let ($mu-hqblend-val $coh-val) (objectives (infotestconcept1) (infotestconcept2) (testcandidatedegrees)) ((truncate $mu-hqblend-val 5) (truncate $coh-val 5)))
    (0.01500 0.33320)
)

;;;; cons-blend-properties(builds property-value pair from concept and propetie values list)

!(test
    (cons-blend-properties (infotestconcept1) (0.9 0.4 0.56 0.3 0.6 0.7 0.9 0.8))
    ((mobility 0.9) (intelligence 0.4) (web-creation 0.56) (social-structure 0.3) (predatory-behavior 0.6) (communication 0.7) (symbolism 0.9) (physical-strength 0.8))
)
