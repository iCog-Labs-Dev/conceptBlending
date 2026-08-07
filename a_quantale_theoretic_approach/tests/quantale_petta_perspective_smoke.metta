!(import! &self a_quantale_theoretic_approach/structural_reasoning/quantale_colimit_engine)

(= (PerspectiveBoat)
   (Concept Boat functional_use
      (V-predicate
         (Property
            (floatsOnWater (WorldSpecSet (W_FERRY W_ROWBOAT)) 0.95)
            (providesTransport (WorldSpecSet (W_FERRY)) 0.80)))))

(= (PerspectiveCar)
   (Concept Car functional_use
      (V-predicate
         (Property
            (travelsOnRoad (WorldSpecSet (W_COMMUTE)) 0.90)
            (providesTransport (WorldSpecSet (W_COMMUTE)) 0.85)))))

(= (StructuralCar)
   (Concept Car structural_composition
      (V-predicate
         (Property
            (hasEngine (WorldSpecSet (W_ENGINE)) 0.88)))))

(= (PerspectiveMappings)
   ((TransportCapability providesTransport providesTransport)))

!(== (v-concept-name (PerspectiveBoat)) Boat)
!(== (v-concept-perspective (PerspectiveBoat)) functional_use)
!(== (v-property-list (PerspectiveBoat))
     ((floatsOnWater (WorldSpecSet (W_FERRY W_ROWBOAT)) 0.95)
      (providesTransport (WorldSpecSet (W_FERRY)) 0.80)))

!(== (v-make-concept EmptyConcept functional_use ())
     (Concept EmptyConcept functional_use
        (V-predicate (Property ()))))

!(== (v-concept-perspective
        (q-rewrite-concept-worlds (PerspectiveBoat) ()))
     functional_use)

!(== (v-concept-perspective
        (q-vpredicate-colimit
           AmphibiousVehicle
           (PerspectiveBoat)
           (PerspectiveCar)
           (PerspectiveMappings)))
     functional_use)

!(== (q-vpredicate-colimit
        InvalidImplicitBlend
        (PerspectiveBoat)
        (StructuralCar)
        ())
     (VError IncompatibleConceptPerspectives
             functional_use structural_composition))

!(== (v-concept-perspective
        (q-vpredicate-colimit
           ExplicitCrossPerspectiveBlend blended_perspective
           (PerspectiveBoat) (StructuralCar) ()))
     blended_perspective)
