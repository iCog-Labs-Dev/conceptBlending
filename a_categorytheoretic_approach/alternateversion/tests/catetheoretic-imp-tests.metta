!(register-module! ../../../a_categorytheoretic_approach)
!(import! &self a_categorytheoretic_approach:alternateversion:catetheoretic-imp)
!(import! &self a_categorytheoretic_approach:alternateversion:utils:helper)

;------------------------House_Boat Example Used For Testing Evaluation Matrix------------------
!(bind! house_boat ((Concept house
 (spec
  (sorts
   (Object 1)
   (Medium 1)
   ((< House Object) 1)    
   ((< Person Object) 1)   
   ((< Land Medium) 1)     
  )
  (ops
   ((: a_house House) 10)  
   ((: a_person Person) 10)
   ((: the_land Land) 10)  
  )
  (preds
   ((provides_shelter House Person) 5)
   ((is_located_on House Medium) 5)
   ((is_stationarconcept2 House) 5)
   ((has_living_space House) 5)
   ((offers_privacconcept2 House) 5)
  )
  (axioms
   ((provides_shelter a_house a_person) 10)
   ((is_located_on a_house the_land) 10)
   ((is_stationarconcept2 a_house) 10)
   ((has_living_space a_house) 10)
   ((offers_privacconcept2 a_house) 10)
  )
 )
)

(Concept boat
 (spec
  (sorts
   (Object 1)
   (Medium 1)
   ((< Boat Object) 1)
   ((< Person Object) 1)
   ((< Water Medium) 1)
  )
  (ops
   ((: a_boat Boat) 10)
   ((: a_person Person) 10)
   ((: the_water Water) 10)
  )
  (preds
   ((provides_shelter Boat Person) 5)
   ((is_located_on Boat Medium) 5)
   ((is_mobile Boat) 5)
   ((has_living_space Boat) 5)
   ((offers_privacconcept2 Boat) 5)
   ((can_float Boat Medium) 5)
   ((can_navigate Boat Medium) 5)
  )
  (axioms
   ((provides_shelter a_boat a_person) 10)
   ((is_located_on a_boat the_water) 10)
   ((is_mobile a_boat) 10)
   ((has_living_space a_boat) 10)
   ((offers_privacconcept2 a_boat) 10)
   ((can_float a_boat the_water) 10)
   ((can_navigate a_boat the_water) 10)
  )
 )
)


(Concept house@boat_Generic
 (spec
  (sorts
   (Object 1)
   (Medium 1)
   ((< HabitableObject Object) 1)
   ((< Person Object) 1)
   ((< Surface Medium) 1)
  )
  (ops
   ((: a_habitable_object HabitableObject) 10)
   ((: a_person Person) 10)
   ((: the_surface Surface) 10)
  )
  (preds
   ((provides_shelter HabitableObject Person) 5)
   ((is_located_on HabitableObject Surface) 5)
   ((has_living_space HabitableObject) 5)
   ((offers_privacconcept2 HabitableObject) 5)
  )
  (axioms
   ((provides_shelter a_habitable_object a_person) 10)
   ((is_located_on a_habitable_object the_surface) 10)
   ((has_living_space a_habitable_object) 10)
   ((offers_privacconcept2 a_habitable_object) 10)
   ((is_located_on a_habitable_object the_surface) 10)
   ((has_living_space a_habitable_object) 10)
   ((offers_privacconcept2 a_habitable_object) 10)
   ((offers_privacconcept2 a_habitable_object) 10)
  )
 )
 )
 (Concept boat@house_Blend (spec (sorts (Object 2) (Medium 2) ((< HabitableObject Object) 2)
 ((< Person Object) 2) ((< Surface Medium) 2) ((< Boat HabitableObject) 1) ((< House HabitableObject) 1) ((< Water Surface) 1) ((< Land Surface) 1)) (ops ((: a_habitable_object HabitableObject) 20) ((: a_person Person) 20) ((: the_surface Surface) 20) ((: a_boat Boat) 10) ((: a_house House) 10) ((: the_water Water) 10) ((: the_land Land) 10)) (preds ((provides_shelter HabitableObject Person) 10) ((is_located_on HabitableObject Surface) 10) ((has_living_space HabitableObject) 10) ((offers_privacconcept2 HabitableObject) 10) ((is_mobile Boat) 5) ((can_float Boat Medium) 5) ((can_navigate Boat Medium) 5) ((is_stationarconcept2 House) 5)) (axioms ((provides_shelter a_habitable_object a_person) 20) ((is_located_on a_habitable_object the_surface) 20) ((has_living_space a_habitable_object) 20) ((offers_privacconcept2 a_habitable_object) 20) ((is_mobile a_boat) 10) ((can_float a_boat the_water) 10) ((can_navigate a_boat the_water) 10) ((is_stationarconcept2 a_house) 10))))
))

;return house_boat concepts for testing
(=(house-boat) house_boat)
-------------------------------------------------------------------------------------------------------------


;------------Blend Evaluation Matrix Test------------
;infovalue
!(assertEqual 
      (let $spec (house-boat)
      (let $house_boat_blend (index-atom $spec 3)
      (infoValue $house_boat_blend)
       )) 294)

;compression
!(assertEqual 
      (let $spec (house-boat)
      (let ($lcg $blend) ((index-atom $spec 2) (index-atom $spec 3))
      (compression $lcg $blend)
       )) 14)

;imbalance
!(assertEqual 
      (let $spec (house-boat) 
      (let ($concept1_spec $concept2_spec) ((index-atom $spec 0) (index-atom $spec 1))
      (imbalance $concept1_spec $concept2_spec)
       )) 15)

;value
!(assertEqual 
      (let $spec (house-boat)
      (let ($concept1_spec $concept2_spec $lcg $blend) ((index-atom $spec 0) (index-atom $spec 1) (index-atom $spec 2) (index-atom $spec 3))
      
               (value $concept1_spec $concept2_spec $lcg $blend)
        )) 293)



;------------Algebraic specification Builders Structure Test------------


!(assertEqual (func-algspec House Boat) 
              (match &self (, (Concept House (spec $sort $op $pred $axiom)) (Concept Boat (spec $sort $op $pred $axiom))) ((Concept House (spec $sort $op $pred $axiom)) (Concept Boat (spec $sort $op $pred $axiom)))))

 
;------------Least Common Generalization specification Builders Structure Test------------


!(assertEqual (func-lcg House Boat) 
              (match &self (Concept Generic_House@Boat (spec $sort $op $pred $axiom)) (Concept Generic_House@Boat (spec $sort $op $pred $axiom))) )



;------------Amalgam specification Builders Structure Test------------

!(assertEqual (func-blend House Boat) 
              (match &self (Concept Blend_House@Boat (spec $sort $op $pred $axiom)) (Concept Blend_House@Boat (spec $sort $op $pred $axiom))))