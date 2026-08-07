; Runtime contract test for mcbride_runner.metta.
;
; The grounded operations are replaced with deterministic test doubles because
; the runner's responsibility is to dispatch to them with the correct arguments.
; The combined operation still executes the real quantale colimit implementation.

(= (mcbride-py-refine
      (Concept $blend-name $blend-body)
      (Concept $source-a-name $source-a-body)
      (Concept $source-b-name $source-b-body)
      $eta
      $steps)
   (Refined
      (BlendName $blend-name)
      (BlendBody $blend-body)
      (SourceNames $source-a-name $source-b-name)
      (Eta $eta)
      (Steps $steps)))

(= (mcbride-py-emergence
      (Concept $blend-name $blend-body)
      (Concept $source-a-name $source-a-body)
      (Concept $source-b-name $source-b-body))
   (EmergenceScore
      $blend-name
      $source-a-name
      $source-b-name
      0.625))

!(import! &self a_quantale_theoretic_approach/mcbride_petta/mcbride_runner)

(= (Boat)
   (Concept Boat
      (V-predicate
         (Property
            (floatsOnWater (WorldSpecSet (W_FERRY W_ROWBOAT)) 0.95)
            (providesTransport (WorldSpecSet (W_FERRY)) 0.80)
            (hasColor (WorldSpecSet (W_TOY_BOAT)) 0.30)))))

(= (Car)
   (Concept Car
      (V-predicate
         (Property
            (travelsOnRoad (WorldSpecSet (W_COMMUTE)) 0.90)
            (providesTransport (WorldSpecSet (W_COMMUTE)) 0.85)))))

!(mcbride-refine (Boat) (Boat) (Car))
!(mcbride-refine-with (Boat) (Boat) (Car) 0.10 3)
!(mcbride-emergence (Boat) (Boat) (Car))
; The combined operation is invoked by a dedicated test query so its full
; colimit result can be asserted independently.
!(quantale-blend-and-refine TestBlend (Boat) (Car)
   ((TransportCapability providesTransport providesTransport)))
