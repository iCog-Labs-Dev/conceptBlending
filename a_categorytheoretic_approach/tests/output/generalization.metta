
; ---------------------------------------------------------
; 🔗 GENERALIZATION (Shared Structure)
; ---------------------------------------------------------
(Concept House@Boat 
  (spec 
    (sorts (Object (< HabitableStructure Object) (< Person Object) (< Environment Object) (< Location Object))) 
    (ops ((: habitable_unit HabitableStructure) (: inhabitant Person) (: water Environment) (: station_point Location))) 
    (preds ((inhabits Person HabitableStructure) (on Object Environment) (isMobile Object) (isShelter Object) (isHabitable Object) (locatedAt Object Location))) 
    (axioms ((inhabits inhabitant habitable_unit) (on habitable_unit water) (isMobile habitable_unit) (isShelter habitable_unit) (isHabitable habitable_unit) (locatedAt habitable_unit station_point)))
  )
)
