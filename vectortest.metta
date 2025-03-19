
! (register-module! ../conceptBlending)
! (import! &self conceptual_blending)
! (import! &self conceptBlending:utils:utils)

! (getValue d ((purpose (primary shelter)) (color (b (c (d blue)))) (weight 43)))



;! (gpt_vector "Spider" "Man")
;! (gpt_vector "Bat" "Man")
;! (gpt_vector "messi" "ronaldo")
;! (gpt_vector "music" "painitng")


!(let* ( ($c (gpt_vector "Spider" "Man") )($s (car-atom $c)))$s)