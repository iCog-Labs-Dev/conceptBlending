!(import! &self a_quantale_theoretic_approach/structural_reasoning/quantale_colimit_engine)

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

(= (PropertyMappings)
   ((TransportCapability providesTransport providesTransport)))

; Many-to-many world mapping: two Boat worlds and one Car world collapse to
; one blended transport scenario before property colimit is computed.
(= (WorldSpecClusters)
   ((TransportScenario W_TRANSPORT_BLEND (W_FERRY W_ROWBOAT W_COMMUTE))))

(= (WorldSpecRegistry)
   ((WorldSpec W_FERRY
      (independent-spec
         (sorts (Vessel Human WaterRoute))
         (ops ((: ferry Vessel) (: alice Human) (: river WaterRoute)))
         (preds ((afloat Vessel WaterRoute) (carries Vessel Human)))
         (axioms ((afloat ferry river) (carries ferry alice)))))

    (WorldSpec W_ROWBOAT
      (independent-spec
         (sorts (Artifact WaterBody))
         (ops ((: rowboat Artifact) (: lake WaterBody)))
         (preds ((floating Artifact WaterBody) (unoccupied Artifact)))
         (axioms ((floating rowboat lake) (unoccupied rowboat)))))

    (WorldSpec W_COMMUTE
      (independent-spec
         (sorts (Vehicle Person Road))
         (ops ((: car Vehicle) (: bob Person) (: highway Road)))
         (preds ((movesOn Vehicle Road) (carries Vehicle Person)))
         (axioms ((movesOn car highway) (carries car bob)))))

    (WorldSpec W_TOY_BOAT
      (independent-spec
         (sorts (Toy Paint))
         (ops ((: toyBoat Toy) (: redPaint Paint)))
         (preds ((miniatureBoat Toy) (painted Toy Paint)))
         (axioms ((miniatureBoat toyBoat) (painted toyBoat redPaint)))))))

!(q-rewrite-concept-worlds (Boat) (WorldSpecClusters))

!(q-vpredicate-integrated-colimit
   AmphibiousVehicle
   (Boat)
   (Car)
   (PropertyMappings)
   (WorldSpecClusters)
   (WorldSpecRegistry))

!(v-world-universe
   (q-integrated-colimit-blend
      (q-vpredicate-integrated-colimit
         AmphibiousVehicle
         (Boat)
         (Car)
         (PropertyMappings)
         (WorldSpecClusters)
         (WorldSpecRegistry))))
