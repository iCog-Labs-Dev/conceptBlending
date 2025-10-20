!(import! &self libs)

!(assertEqualToResult
(gpt_algspec_builder House Boat)
((Concept House (spec (sorts (Medium (< House Object) (< Person Object))) (ops ((: house House) (: resident Person) (: land Medium))) (preds ((occupies Person House) (locatedOn Object Medium))) (axioms ((occupies (resident house)) (locatedOn (house land)))))), (Concept Boat (spec (sorts (Medium (< Boat Object) (< Person Object))) (ops ((: boat Boat) (: passenger Person) (: water Medium))) (preds ((occupies Person Boat) (locatedOn Object Medium))) (axioms ((occupies (passenger boat)) (locatedOn (boat water)))))))
)