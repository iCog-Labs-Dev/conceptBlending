; Runtime contract test for emergence.metta

!(import! &self a_quantale_theoretic_approach/mcbride_petta/emergence)

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

; Test 1: emergence degree is within valid bounds [0, 1]
!(let $sigma (q-emergence-tv (Boat) (Car) (Amphibian))
   (assertEqual (and (>= $sigma 0.0) (<= $sigma 1.0)) True))

; Test 2: emergence with tv valuation returns degree within [0, 1]
!(let $sigma-tv (q-degree (q-emergence-tv-valuation (Boat) (Car) (Amphibian)))
   (assertEqual (and (>= $sigma-tv 0.0) (<= $sigma-tv 1.0)) True))
