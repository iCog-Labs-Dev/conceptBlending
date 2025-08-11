
! (register-module! ../../an_infotheoretic_approach)
; ! (import! &self an_infotheoretic_approach:libs)
!(import! &self libs)

; Test vital relation extracting agent
; !(let* (
;     ($x (gpt_vital_relation "Boat"))
;     ($y (gpt_vital_relation "House"))
;     )
;     (let $t (union-atom $x $y) (unique-atom $t))
; )
;; Output: [(Category Part-Whole Role Representation Material Identity)]

; Test vector extracting agent
; ! (gpt_vector "Spider" "Man" "(Category Part-Whole Role Representation Material Identity)")
;; Output: [((Concept Spider@Man (Property (web-spinning 1.0) (intelligence 0.3) (physical-strength 0.2) (agility 0.8) (symbolism 0.7) (predatory-behavior 0.9) (social-structure 0.2) (lifespan 0.1))) (Concept Man@Spider (Property (web-spinning 0.0) (intelligence 0.9) (physical-strength 0.8) (agility 0.6) (symbolism 0.5) (predatory-behavior 0.3) (social-structure 0.9) (lifespan 0.8))))]


; Test network selector agent
; !(assertEqual
;     (gpt_network_selector "Spider@Man")
;     gpt_double
; )

; Output: [gpt_double]

; Test double scope blending agent
; ! (gpt_double "Spider@Man" "((web-creation 0.0) (intelligence 0.5030899869919434) (physical-strength 0.30308998699194345) (mobility 0.10308998699194338) (predatory-behavior 0.0) (social-structure 0.7030899869919434) (symbolism 0.20308998699194347) (tool-use 0.8030899869919434))")
;; Output: [(doubleScope (expand Spider Man) SpiderMan (extended ArachnidHero))]
