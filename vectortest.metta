
! (register-module! ../conceptBlending)
! (import! &self conceptual_blending)
! (import! &self conceptBlending:utils:utils)
! (import! &self conceptBlending:info-theoretic)

; ! (getValue d ((purpose (primary shelter)) (color (b (c (d blue)))) (weight 43)))



; ! (gpt_vector "Spider" "Man")
;! (gpt_vector "Bat" "Man")
;! (gpt_vector "messi" "ronaldo")
;! (gpt_vector "music" "painitng")


; !(let* ( ($c (gpt_vector "Spider" "Man") )($s (car-atom $c)))$s)
!(let $i (gpt_vector "Spider" "Man") (get-number-of-properties $i))

!(
    let* (
        ($c (gpt_vector "Spider" "Man"))
        ($s (superpose $c))
        ($ff (collapse $s))
        ($ee (car-atom $ff))
        ($oo (cdr-atom $ee))
        ($zz (cdr-atom $oo))
        ; ($head (get-metatype $pp))

        
        
       



      
    )
  $zz
    
)
