; Runtime contract test for weakness.metta

!(import! &self a_quantale_theoretic_approach/mcbride_petta/weakness)

(= (TestConceptA)
   (Concept A (V-predicate (Property
      (hot    (WorldSpecSet (W_FIRE)) 0.27)
      (bright (WorldSpecSet (W_FIRE)) 0.26)))))

(= (TestConceptOneP)
   (Concept A1 (V-predicate (Property
      (hot (WorldSpecSet (W_FIRE)) 0.27)))))

(= (EmptyConcept)
   (Concept Empty (V-predicate (Property))))

; Test 1: weakness of empty concept is bottom (degree 0.0)
!(assertEqual
   (q-degree (q-weakness (EmptyConcept)))
   0.0)

; Test 2: weakness degree is within valid quantale bounds [0, 1]
!(let $w (q-degree (q-weakness (TestConceptA)))
   (assertEqual (and (>= $w 0.0) (<= $w 1.0)) True))

; Test 3: weakness increases monotonically when properties accumulate
!(let* (($w1 (q-degree (q-weakness (TestConceptOneP))))
        ($w2 (q-degree (q-weakness (TestConceptA)))))
   (assertEqual (>= $w2 $w1) True))
