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

; !(gpt_network_selector "Light@Wisdom" "Light@Wisdom") ;; returns [gpt_double]
; !(gpt_network_selector "Teacher@Guide" "Teacher@Guide");; returns [gpt_simplex]
; !(gpt_network_selector "Emotion@Mathematics" "Emotion@Mathematics");; returns [gpt_double]
; !(gpt_network_selector "Sun@Clock" "Sun@Clock")  ;; [gpt_mirror] 

; ! (gpt_mirror "River@TrafficFlow" ((fluidity 0.9) (flow-direction 0.9) (obstacles 0.8) (volume 0.7) (navigation 0.6) (control 0.5) (pathways 0.9) (feedback 0.6)))
; ! (gpt_simplex "Spider@Man" ((web-creation 0.0) (intelligence 0.5) (physical-strength 0.3) (mobility 0.1) (predatory-behavior 0.0) (social-structure 0.7) (symbolism 0.2) (tool-use 0.8)))
; ! (gpt_single "War@Game" ((strategy 0.8) (rules 0.7) (opponents 0.6) (risk 0.9) (victory 0.8) (loss 0.7) (engagement 0.6) (psychology 0.7)))
