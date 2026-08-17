;; PeTTa imports rules but does not transitively run a module's eager `!`
;; initializers, so validation initializes the Python boundary explicitly.
!(import! &self ../../../../PeTTa/lib/lib_import)
!(import! &self ../../../integration/python/integration_support.py)
!(integration_support.configure_component_roots)
!(import! &self ../HybridSearchInitialization)

(= (fixture-compact-a)
   (Concept boat functional_use
      (Properties ((move_on_water) ((boat) (ferry))))))
(= (fixture-compact-b)
   (Concept car functional_use
      (Properties ((move_on_land) ((car) (bus))))))

(= (fixture-property-resolutions)
   (PairResolutions
      ((PairResolution
         (PropertyPairId move_on_water move_on_land)
         locomotion (stv 0.8 0.7)))))

(= (fixture-world-mappings)
   (WorldMappings
      ((GenericWorldMapping
         vehicle locomotion move_on_water move_on_land boat car)
       (GenericWorldMapping
         transport locomotion move_on_water move_on_land ferry bus))))

!(let* (
   ($source-a (hs-enrich-compact (fixture-compact-a) 11))
   ($source-b (hs-enrich-compact (fixture-compact-b) 12))
   ($generic
      (hs-generic-result-from-mappings
         vehicle functional_use
         (fixture-property-resolutions) (fixture-world-mappings) 13))
   ($strengths
      (HabitStrengths
         ((HabitStrength
            locomotion move_on_water move_on_land 0.8))))
   ($target
      (hs-habit-target-from-strengths
         $source-a $source-b $generic $strengths 0.5))
   ($populations
      (hs-sample-five-populations $generic $target 19)))
   (let $_population-count-test
      (test (hs-population-count $populations) 5)
      (test (hs-individual-counts $populations) (10 10 10 10 10))))

!(let* (
   ($source-a (hs-enrich-compact (fixture-compact-a) 11))
   ($source-b (hs-enrich-compact (fixture-compact-b) 12))
   ($requests
      (hs-world-pair-requests
         $source-a $source-b (fixture-property-resolutions))))
   (test (size-atom (hs-request-list $requests)) 4))
