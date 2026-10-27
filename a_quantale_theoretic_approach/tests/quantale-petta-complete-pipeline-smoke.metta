!(import! &self a_quantale_theoretic_approach/integration/complete-blend-pipeline)

; Compact V-predicates emitted by extraction before GNN scalar assignment.
(= (PipelineCompactBoat)
   (Concept boat functional_use
      (Properties ((move_on_water) ((boat) (ferry))))))
(= (PipelineCompactCar)
   (Concept car functional_use
      (Properties ((move_on_land) ((car) (bus))))))

; Algebraic specifications consumed by the real Cartesian generalizer.
(= (PipelineBoatSpec)
   (Concept boat functional_use
      (spec
         (sorts ((boat (stv 0.95 0.90)) (cargo (stv 0.80 0.70))))
         (ops (((operation move_boat (arrow boat cargo boat))
                  (stv 0.90 0.80))))
         (preds (((usable boat) (stv 0.88 0.77))))
         (axioms (((=> true (usable boat)) (stv 0.80 0.70)))))))
(= (PipelineCarSpec)
   (Concept car functional_use
      (spec
         (sorts ((car (stv 0.92 0.85)) (cargo (stv 0.90 0.65))))
         (ops (((operation move_car (arrow car cargo car))
                  (stv 0.85 0.75))))
         (preds (((usable car) (stv 0.82 0.72))))
         (axioms (((=> true (usable car)) (stv 0.75 0.65)))))))

; Scalar-bearing source V-predicates supplied at the explicit GNN boundary.
(= (PipelineEnrichedBoat)
   (Concept boat functional_use
      (V-predicate
         (Property ((supported (WorldSpecSet (W)) 0.8))))))
(= (PipelineEnrichedCar)
   (Concept car functional_use
      (V-predicate
         (Property ((supported (WorldSpecSet (W)) 0.7))))))
(= (PipelinePropertyMappings) ((shared_support supported supported)))
(= (PipelineWorldClusters) ())
(= (PipelineWorldSpecs)
   ((WorldSpec W
      (independent-spec
         (sorts (vehicle))
         (ops ())
         (preds ((supported vehicle)))
         (axioms ())))))

; Enriched-Hom/relation fixture stands at the future Hom pipeline boundary.
(= (PG) (VCategory PG (W) (g) ((g g (Q (W) 1.0)))))
(= (PA) (VCategory PA (W) (a) ((a a (Q (W) 1.0)))))
(= (PB) (VCategory PB (W) (b) ((b b (Q (W) 1.0)))))
(= (PC) (VCategory PC (W) (c) ((c c (Q (W) 1.0)))))
(= (PX) (VCategory PX (W) (x) ((x x (Q (W) 1.0)))))
(= (PSigmaA) (VMorphism PSigmaA (PG) (PA) ((g a))))
(= (PSigmaB) (VMorphism PSigmaB (PG) (PB) ((g b))))
(= (PInA) (VMorphism PInA (PA) (PC) ((a c))))
(= (PInB) (VMorphism PInB (PB) (PC) ((b c))))
(= (PBackA) (VMorphism PBackA (PC) (PA) ((c a))))
(= (PBackB) (VMorphism PBackB (PC) (PB) ((c b))))
(= (PCocone) (VCocone PCocone (PSigmaA) (PSigmaB) (PInA) (PInB)))
(= (PCompareInA) (VMorphism PCompareInA (PA) (PX) ((a x))))
(= (PCompareInB) (VMorphism PCompareInB (PB) (PX) ((b x))))
(= (PComparison)
   (VCocone PComparison
      (PSigmaA) (PSigmaB) (PCompareInA) (PCompareInB)))
(= (PMediator) (VMorphism PMediator (PC) (PX) ((c x))))
(= (PVColimit)
   (VColimit PVColimit (PCocone)
      (MediatingWitnesses
         ((MediatingWitness (PComparison) (PMediator))))
      (ComparisonScope ((PComparison)) Exhaustive)))
(= (PRelationA)
   (vr-make R functional_use (PA)
      ((a a (Q (W) 0.8))) (SourceConcept boat)))
(= (PRelationB)
   (vr-make R functional_use (PB)
      ((b b (Q (W) 0.7))) (SourceConcept car)))
(= (PRelationC)
   (vr-make R functional_use (PC)
      ((c c (Q (W) 0.9))) (BlendConcept vehicle)))
(= (PFamilyA)
   (VitalRelationFamily functional_use (PA) ((PRelationA))))
(= (PFamilyB)
   (VitalRelationFamily functional_use (PB) ((PRelationB))))
(= (PFamilyC)
   (VitalRelationFamily functional_use (PC) ((PRelationC))))
(= (PipelineArtifacts)
   (OptimalityEnrichmentArtifacts
      (PVColimit) (PFamilyA) (PFamilyB) (PFamilyC)
      ((VitalRelationCorrespondence SharedR R R R (Q (W) 1.0)))
      (PSigmaA) (PSigmaB) (PInA) (PInB)
      (PBackA) (PBackB)
      ()
      ((RelevantEvidence purpose (Q (W) 0.8) (Q (W) 1.0)))))

(= (RunPipeline $enriched-a $enriched-b $artifacts)
   (q-run-complete-blend-pipeline
      vehicle functional_use
      (PipelineCompactBoat) (PipelineCompactCar)
      (PipelineBoatSpec) (PipelineCarSpec)
      $enriched-a $enriched-b
      (PipelinePropertyMappings)
      (PipelineWorldClusters) (PipelineWorldSpecs)
      $artifacts))

; No scalar-bearing predicates: the real structural stage runs and the result
; stops at the GNN boundary without pretending a colimit was constructed.
!(let (CompleteBlendPipelineResult
          $status (StructuralPreparation $structural)
          (VPredicateColimit $colimit) (Optimality $optimality))
      (RunPipeline () () ())
   (if (== $status Pending)
       (if (== $colimit ())
           (== (q-preparation-perspective $structural) functional_use)
           False)
       False))


; Scalars present, Hom artifacts absent: structural and colimit producers run,
; then the optimality stage reports Blocked with bottom.
!(let (CompleteBlendPipelineResult
          $status (StructuralPreparation $structural)
          (VPredicateColimit $colimit)
          (Optimality (VOptimalityResult $opt-status $results $value)))
      (RunPipeline (PipelineEnrichedBoat) (PipelineEnrichedCar) ())
   (if (== $status Blocked)
       (if (== (v-concept-name (q-colimit-result-blend $colimit)) vehicle)
           (== (q-degree $value) 0.0)
           False)
       False))

; All boundaries supplied: one call runs generalization, world-aware quantale
; colimit, shared-context construction, double coends, and all constraints.
!(let (CompleteBlendPipelineResult
          $status (StructuralPreparation $structural)
          (VPredicateColimit $colimit)
          (Optimality (VOptimalityResult $opt-status $results $value)))
      (RunPipeline
         (PipelineEnrichedBoat) (PipelineEnrichedCar) (PipelineArtifacts))
   (if (== $status Evaluated)
       (if (== $opt-status Evaluated)
           (if (== (v-concept-perspective
                      (q-colimit-result-blend $colimit))
                   functional_use)
               (== (q-degree $value) 0.8)
               False)
           False)
       False))
