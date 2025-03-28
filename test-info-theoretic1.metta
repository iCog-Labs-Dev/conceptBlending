! (import! &self conceptual_blending)
! (import! &self info-theoretic1)


; ! (let*(
;         ($concepts (gpt_vector "messi" "ronaldo"))
;         ($concept1 (car-atom $concepts))
;         ($wrapped-concept2 (cdr-atom $concepts))
;         ($concept2 (car-atom $wrapped-concept2))
;         ($degree (property-degree $concept1))
;         ($max (property-max $concept1 $concept2))
;         ($calculated-mu-emergence (mu-emergence $degree $max))
;         ($min (property-min $concept1 $concept2))
;         ($calculated-mu-hqblend (mu-hqblend $calculated-mu-emergence $min))
;     )
;     ($calculated-mu-hqblend $concept1 $concept2)
; )

!(gpt_network_selector "Light@Wisdom" "Light@Wisdom") ;; returns [gpt_double]
!(gpt_network_selector "Teacher@Guide" "Teacher@Guide");; returns [gpt_simplex]
!(gpt_network_selector "Emotion@Mathematics" "Emotion@Mathematics");; returns [gpt_double]
!(gpt_network_selector "Sun@Clock" "Sun@Clock")  ;; [gpt_mirror] 