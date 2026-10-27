; Runtime contract test for mcbride_deriv.metta

!(import! &self a_quantale_theoretic_approach/mcbride_petta/mcbride_deriv)

(= (Boat)
   (Concept Boat (V-predicate (Property
      (floats (WorldSpecSet (W_FERRY)) 0.90)
      (transports (WorldSpecSet (W_FERRY)) 0.80)))))

(= (Car)
   (Concept Car (V-predicate (Property
      (roads (WorldSpecSet (W_COMMUTE)) 0.90)
      (transports (WorldSpecSet (W_COMMUTE)) 0.85)))))

(= (Amphibian)
   (Concept Amphibian (V-predicate (Property
      (floats (WorldSpecSet (W_FERRY)) 0.90)
      (roads (WorldSpecSet (W_COMMUTE)) 0.90)
      (transports (WorldSpecSet (W_FERRY W_COMMUTE)) 0.95)))))

; Test 1: derivative degree for floats is within valid bounds [0, 1]
!(let $d (q-mcbride-deriv-tv floats (Boat) (Car) (Amphibian))
   (assertEqual (and (>= $d 0.0) (<= $d 1.0)) True))

; Test 2: derivative degree for roads is within valid bounds [0, 1]
!(let $d2 (q-mcbride-deriv-tv roads (Boat) (Car) (Amphibian))
   (assertEqual (and (>= $d2 0.0) (<= $d2 1.0)) True))
