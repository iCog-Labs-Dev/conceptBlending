(Concept BlendedConcept 
 (spec
  (sorts ((< Environment Object) (< House_Boat Object) (< Location Object) (< Person Object) Object))
  (ops ((: house_boat House_Boat) (: mooring_anchorage Location) (: resident_occupant Person) (: water Environment)))
  (preds ((inhabits Person House_Boat) (isHabitable Object) (isMobile Object) (isShelter Object) (locatedAt Object Location) (on Object Environment)))
  (axioms ((inhabits resident_occupant house_boat) (isHabitable house_boat) (isMobile house_boat) (isShelter house_boat) (locatedAt house_boat mooring_anchorage) (on house_boat water)))
 )
)