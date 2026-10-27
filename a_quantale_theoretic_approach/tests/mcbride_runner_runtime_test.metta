; End-to-end runtime test for mcbride_runner.metta
; Tests native PeTTa dispatch of McBride optimization functions.

; Imports are relative to this tests directory so the documented command
; `petta mcbride_runner_runtime_test.metta` works from here. Load dependencies
; explicitly because PeTTa resolves transitive import paths against the
; process working directory rather than the imported file's directory.

!(import! &self a_quantale_theoretic_approach/mcbride_petta/mcbride_runner)

(= (Boat)
   (Concept Boat
      (V-predicate
         (Property
            (floatsOnWater (WorldSpecSet (W_FERRY W_ROWBOAT)) 0.95)
            (providesTransport (WorldSpecSet (W_FERRY)) 0.80)))))

(= (Car)
   (Concept Car
      (V-predicate
         (Property
            (travelsOnRoad (WorldSpecSet (W_COMMUTE)) 0.90)
            (providesTransport (WorldSpecSet (W_COMMUTE)) 0.85)))))

(= (TransportMappings)
   ((TransportCapability providesTransport providesTransport)))

; Test 1: mcbride-emergence returns degree in valid range [0, 1]
!(let* (($blend (q-vpredicate-colimit Amphibian (Boat) (Car) (TransportMappings)))
        ($emerg (q-degree (mcbride-emergence $blend (Boat) (Car)))))
   (test (and (>= $emerg 0.0) (<= $emerg 1.0)) True))

; Test 2: quantale-blend-and-refine creates concept with properties
!(let $refined (quantale-blend-and-refine Amphibian (Boat) (Car) (TransportMappings))
   (test (v-concept-name $refined) Amphibian))

; Test 3: mcbride-refine produces non-empty blend result
!(let* (($blend (q-vpredicate-colimit Amphibian (Boat) (Car) (TransportMappings)))
        ($refined (mcbride-refine $blend (Boat) (Car))))
   (test (== (v-property-list $refined) ()) False))
