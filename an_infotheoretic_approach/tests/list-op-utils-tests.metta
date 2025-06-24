! (register-module! ../../an_infotheoretic_approach)
! (import! &self an_infotheoretic_approach:utils:list-op-utils)


; Test tuple-multiply
! (assertEqual
    (list-multiply (0.9 0.9 0.0 0.8 0.2 0.9 0.7 0.7) (0.9 0.9 0.0 0.8 0.2 0.9 0.7 0.7) (mobility intelligence web-creation social-structure predatory-behavior communication symbolism physical-strength))
    ((mobility 0.81) (intelligence 0.81) (web-creation 0.0) (social-structure 0.6400000000000001) (predatory-behavior 0.04000000000000001) (communication 0.81) (symbolism 0.48999999999999994) (physical-strength 0.48999999999999994))
)

; Test min-elements
! (assertEqual
    (min-elements (0.9 0.9 0.0 0.8 0.2 0.9 0.7 0.7) (0.8 0.0 0.6 0.9 0.7 0.3 0.1 0.7) (mobility intelligence web-creation social-structure predatory-behavior communication symbolism physical-strength))
    ((mobility 0.8) (intelligence 0.0) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.3) (symbolism 0.1) (physical-strength 0.7))
)

; Test max-elements
! (assertEqual
    (max-elements (0.9 0.9 0.0 0.8 0.2 0.9 0.7 0.7) (0.8 0.0 0.6 0.9 0.7 0.3 0.1 0.7) (mobility intelligence web-creation social-structure predatory-behavior communication symbolism physical-strength))
    ((mobility 0.9) (intelligence 0.9) (web-creation 0.6) (social-structure 0.9) (predatory-behavior 0.7) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))
)

; Test tuple-substract
! (assertEqual
    (list-substract (0.9030899869919434 0.9030899869919434 0.9030899869919434 0.9030899869919434 0.9030899869919434 0.9030899869919434 0.9030899869919434 0.9030899869919434) (0.3 0.2 0.0 0.5 0.5 0.5 0.7 0.3) (mobility intelligence web-creation social-structure predatory-behavior communication symbolism physical-strength))
    ((mobility 0.6030899869919435) (intelligence 0.7030899869919434) (web-creation 0.9030899869919434) (social-structure 0.4030899869919434) (predatory-behavior 0.4030899869919434) (communication 0.4030899869919434) (symbolism 0.20308998699194347) (physical-strength 0.6030899869919435))
)
