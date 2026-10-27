!(import! &self a_quantale_theoretic_approach/optimality/quantale_op_constraints)

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

(= (RelevanceWeights)
   ((providesTransport 1.0)
    (floatsOnWater 0.8)))

!(q-vpredicate-colimit AmphibiousVehicle (Boat) (Car) (TransportMappings))

!(q-op-evaluater
   (q-vpredicate-colimit AmphibiousVehicle (Boat) (Car) (TransportMappings))
   (Boat)
   (Car)
   (TransportMappings)
   (RelevanceWeights))
