! (register-module! ../../conceptBlending)
! (import! &self conceptBlending:utils:expression-man-utils)


; ; Test unNest
; ! (assertEqual
;     (unNest (purpose (primary shelter (temporary tent))))
;     ([purpose, primary, shelter, temporary, tent])
; )

; Test flatten
! (assertEqual
    (flatten (purpose (primary shelter (temporary tent))))
    (purpose primary shelter temporary tent)
)

; Test getValue
! (assertEqual
    (getValue d ((purpose (primary shelter)) (color (b (c (d blue)))) (weight 43)))
    (d blue)
)

; Test setValue
! (assertEqual
    (setValue primary ((purpose (primary shelter)) (color (b (c (d blue)))) (weight 43)) transportation )
    (primary transportation)
)
