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

; Test mu-emergence calculating function
; ! (assertEqual
;     (mu-emergence 0.9030899869919434 (property-max (Concept Spider@Man (Property (web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))) (Concept Spider@Man (Property (web-creation 1.0) (intelligence 0.4) (physical-strength 0.2) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1)))))
;     ((web-creation 0.0) (intelligence 0.5030899869919434) (physical-strength 0.30308998699194345) (mobility 0.10308998699194338) (predatory-behavior 0.0) (social-structure 0.7030899869919434) (symbolism 0.20308998699194347) (tool-use 0.8030899869919434))
; )

; ! (let*(
;         ($concept1 (Concept Spider@Man (Property (web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
;         ($concept2 (Concept Spider@Man (Property (web-creation 1.0) (intelligence 0.4) (physical-strength 0.2) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
;         ($degree (property-degree $concept1))
;         ($max (property-max $concept1 $concept2))
;     )
;     (assertEqual
;         (mu-emergence $degree $max)
;         ; ((web-creation 0.0) (intelligence 0.5030899869919434) (physical-strength 0.30308998699194345) (mobility 0.10308998699194338) (predatory-behavior 0.0) (social-structure 0.7030899869919434) (symbolism 0.20308998699194347) (tool-use 0.8030899869919434))
;         ((web-creation 0.0) (intelligence 0.5) (physical-strength 0.30000000000000004) (mobility 0.09999999999999998) (predatory-behavior 0.0) (social-structure 0.7) (symbolism 0.20000000000000007) (tool-use 0.8))
;     )
; )

; Test mu-hqblend calculating function
; ! (let*(
;         ($concept1 (Concept Spider@Man (Property (web-creation 0.1) (intelligence 0.3) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
;         ($concept2 (Concept Spider@Man (Property (web-creation 1.0) (intelligence 0.4) (physical-strength 0.2) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
;         ($degree (property-degree $concept1))
;         ($max (property-max $concept1 $concept2))
;         ($min (property-min $concept1 $concept2))
;         ($calculated-mu-emergence (mu-emergence $degree $max))
;     )
;     (assertEqual
;         (mu-hqblend $calculated-mu-emergence $min)
;         0.08125000000000002
;     )
; )

; Test blend(the main) function
;!(blend "Bat" "Man")
;; Output: [(doubleScope (expand Bat Man) BatMan (extended NocturnalSymbolicHero))]
