! (register-module! ../../an_infotheoretic_approach)
! (import! &self an_infotheoretic_approach:info-theoretic)


; Test get-prop-value-pairs
! (assertEqual
    (get-prop-value-pairs (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))))
    ((mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))
)

; Test get-property
! (assertEqual
    (get-property (mobility 0.9))
    mobility
)

; Test get-properties
! (assertEqual
    (get-properties ((web-creation 1.0) (intelligence 0.4) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1)))
    (web-creation intelligence physical-strength mobility predatory-behavior social-structure symbolism tool-use)
)

; Test get-value
! (assertEqual
    (get-value (web-creation 0.3))
    0.3
)

; Test get-values
! (assertEqual
    (get-values ((mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7)))
    (0.9 0.9 0.0 0.8 0.2 0.9 0.7 0.7)
)

; Test get-values with get-prop-value-pairs
! (assertEqual
    (get-values (get-prop-value-pairs (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7)))))
    (0.9 0.9 0.0 0.8 0.2 0.9 0.7 0.7)
)


; Test property-product
! (assertEqual
    (property-product ((web-creation 0.1) (intelligence 0.2) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1)) ((web-creation 1.0) (intelligence 0.4) (physical-strength 0.1) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1)))
    ((web-creation 0.1) (intelligence 0.08000000000000002) (physical-strength 0.06) (mobility 0.6400000000000001) (predatory-behavior 1.0) (social-structure 0.04000000000000001) (symbolism 0.48999999999999994) (tool-use 0.010000000000000002))
)

; Test get-number-of-properties
! (assertEqual
    (get-number-of-properties (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))))
    8
)

; Test decimal
! (assertEqual
    (decimal 1)
    1.0
)

; Test property-probability
! (assertEqual
    (property-probability (Concept Man@Spider (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))))
    0.125
)

; Test property-degree
! (assertEqual
    (property-degree (Concept Spider@Man (Property (web-creation 1.0) (intelligence 0.4) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
    0.9
)

; Test property-min
! (assertEqual
    (property-min (Concept Spider@Man (Property (web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))) (Concept Spider@Man (Property (web-creation 1.0) (intelligence 0.4) (physical-strength 0.2) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
    ((web-creation 0.1) (intelligence 0.3) (physical-strength 0.2) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))
)

; Test property-max
! (assertEqual
    (property-max (Concept Spider@Man (Property (web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))) (Concept Spider@Man (Property (web-creation 1.0) (intelligence 0.4) (physical-strength 0.2) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
    ((web-creation 1.0) (intelligence 0.4) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))
)

; Test binary-shannon-entropy
! (assertEqual (binary-shannon-entropy 0) 0)
! (assertEqual (binary-shannon-entropy 0.5) 1)

; Test joint-entropy-compute
!(assertEqual
   (joint-entropy-compute (0.5 1 0.25 4 5) min)
   (0.5 0.5 1.5 1.0 0.0 0.0 0.8112781244591328 0.5 0.5 0.0))

;Test total correlation entopy
!(assertEqual
   (total-correlation-entropy (0.5 0.5 0.5) min)
   0.6666666666666666)
!(assertEqual 
   (total-correlation-entropy (0.5 0.5 0.5) max)
   0.3333333333333333)
; Test coherence
!(assertEqual (coherence (color shape size) (0.5 0.25 0.75)) 0.3295405403204763)
!(assertEqual (coherence (a b c) (0.5 0.5 0.5)) 0.43552176654338837)
!(assertEqual (coherence (a b c) (0.1 0.8 0.9)) 0.5640286632357537)

;Test filter-non-dominated 
(= (candidates-list) (((1 1 1 1 1 1) (7 9.1)) ((1 0 1 0 1 0) (2 3)) ((1 1 0 0 1 1) (6 8)) ((1 1 1 0 0 0) (2 3)) ((1 1 0 0 1 1) (4 6)) ((1 1 1 1 1 0) (8 9)) ((0 0 0 0 0 1) (3 5)) ((0 0 0 0 1 1) (4 6))))
!(assertEqual (filter-non-dominated (candidates-list)) (((1 1 1 1 1 0) (8 9)) ((1 1 1 1 1 1) (7 9.1))))