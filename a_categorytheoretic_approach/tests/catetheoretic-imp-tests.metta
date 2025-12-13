!(register-module! a_categorytheoretic_approach)

!(import! &self a_categorytheoretic_approach:catetheoretic-imp.metta)
!(import! &self a_categorytheoretic_approach:tests:example-test-case.metta)
;------------Blend Evalation Matrix Test------------



; House + Boat

;infovalue
!(assertEqual 
      (let $spec house_boat 
      (let $house_boat_blend (index-atom $spec 3)
      (infoValue $house_boat_blend)
       )) 340)

;compression
!(assertEqual 
      (let $spec house_boat 
      (let ($lcg $blend) ((index-atom $spec 2) (index-atom $spec 3))
      (compression $lcg $blend)
       )) 340)

;imbalance
!(assertEqual 
      (let $spec house_boat 
      (let ($concept1_spec $concept2_spec) ((index-atom $spec 0) (index-atom $spec 1))
      (imbalance $concept1_spec $concept2_spec)
       )) 340)
;value
!(assertEqual 
      (let $spec house_boat 
      (let ($concept1_spec $concept2_spec $lcg $blend) ((index-atom $spec 0) (index-atom $spec 1) (index-atom $spec 2) (index-atom $spec 3))
      (let ($infovalue $compression $imbalance) 
      ((infovalue $blend) (compression $lcg $blend) (imbalance $concept1_spec $concept2_spec))
       ))) 340)


!(bind! (house_spec boat_spec house_boat_lcg house_boat_blend)  
        (add spec1 house boat))


!(bind! (man_spec bat_spec man_bat_lcg man_bat_blend)  
        (add spec1 man bat))

; Physics + Mathematics
!(bind! (physics_spec math_spec physics_math_lcg physics_math_blend)  
        (add spec1 physics mathematics))


; Surgeon + Butcher
!(bind! (surgeon_spec butcher_spec surgeon_butcher_lcg surgeon_butcher_blend)  
        (add spec1 surgeon butcher))

; Bird + Airplane 
!(bind! (bird_spec airplane_spec bird_airplane_lcg bird_airplane_blend)  
        (add spec1 bird airplane))


(assertEqual (infoValue blend) 340)
(assertEqual (compression lcg blend) some value)

(assertEqual (imbalance spec_1 spec_2) some value)
(assertEqual (value spec_1 spec_2 lcg blend) some value)



;------------Helper Functions Test------------


;------------Algebraic specification Builders Structure Test------------
!(assertEqual (add-atom &self (algspec_builder dice cube)) expected_structure)


;------------Least Common Generalization specification Builders Structure Test------------



;------------Amalgam specification Builders Structure Test------------