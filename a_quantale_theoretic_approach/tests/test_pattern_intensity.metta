; Runtime contract test for pattern_intensity.metta

!(import! &self a_quantale_theoretic_approach/mcbride_petta/pattern_intensity)

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

; Test 1: pattern intensity degree is within valid bounds [0, 1]
!(let $ia (q-degree (q-pattern-intensity (Boat) (Amphibian)))
   (assertEqual (and (>= $ia 0.0) (<= $ia 1.0)) True))

; Test 2: joint pattern intensity degree is within valid bounds [0, 1]
!(let $iab (q-degree (q-joint-pattern-intensity (Boat) (Car) (Amphibian)))
   (assertEqual (and (>= $iab 0.0) (<= $iab 1.0)) True))
