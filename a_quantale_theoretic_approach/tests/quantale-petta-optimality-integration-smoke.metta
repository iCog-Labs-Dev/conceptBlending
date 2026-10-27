!(import! &self a_quantale_theoretic_approach/optimality/optimality-integration)

(= (IG) (VCategory IG (W) (g) ((g g (Q (W) 1.0)))))
(= (IA) (VCategory IA (W) (a) ((a a (Q (W) 1.0)))))
(= (IB) (VCategory IB (W) (b) ((b b (Q (W) 1.0)))))
(= (IC) (VCategory IC (W) (c) ((c c (Q (W) 1.0)))))
(= (IX) (VCategory IX (W) (x) ((x x (Q (W) 1.0)))))

(= (ISigmaA) (VMorphism ISigmaA (IG) (IA) ((g a))))
(= (ISigmaB) (VMorphism ISigmaB (IG) (IB) ((g b))))
(= (IInA) (VMorphism IInA (IA) (IC) ((a c))))
(= (IInB) (VMorphism IInB (IB) (IC) ((b c))))
(= (IBackA) (VMorphism IBackA (IC) (IA) ((c a))))
(= (IBackB) (VMorphism IBackB (IC) (IB) ((c b))))
(= (IWrongSigmaA) (VMorphism IWrongSigmaA (IG) (IB) ((g b))))

(= (ICocone) (VCocone ICocone (ISigmaA) (ISigmaB) (IInA) (IInB)))
(= (ICompareInA) (VMorphism ICompareInA (IA) (IX) ((a x))))
(= (ICompareInB) (VMorphism ICompareInB (IB) (IX) ((b x))))
(= (IComparison)
   (VCocone IComparison
      (ISigmaA) (ISigmaB) (ICompareInA) (ICompareInB)))
(= (IMediator) (VMorphism IMediator (IC) (IX) ((c x))))
(= (IVColimit)
   (VColimit IVColimit (ICocone)
      (MediatingWitnesses
         ((MediatingWitness (IComparison) (IMediator))))
      (ComparisonScope ((IComparison)) Exhaustive)))

(= (IRelationA)
   (vr-make R functional_use (IA)
      ((a a (Q (W) 0.8))) (SourceConcept A)))
(= (IRelationB)
   (vr-make R functional_use (IB)
      ((b b (Q (W) 0.7))) (SourceConcept B)))
(= (IRelationC)
   (vr-make R functional_use (IC)
      ((c c (Q (W) 0.9))) (BlendConcept Vehicle)))
(= (IFamilyA)
   (VitalRelationFamily functional_use (IA) ((IRelationA))))
(= (IFamilyB)
   (VitalRelationFamily functional_use (IB) ((IRelationB))))
(= (IFamilyC)
   (VitalRelationFamily functional_use (IC) ((IRelationC))))

(= (ICandidate)
   (Concept vehicle functional_use
      (V-predicate
         (Property ((supported (WorldSpecSet (W)) 0.8))))))
(= (IColimitResult)
   (QuantaleVPredicateColimitResult
      (WorldSpecs ())
      (Blend (ICandidate))
      (WorldMap ())
      (PropertyContributionMap ())))
(= (IColimitWithContributions)
   (QuantaleVPredicateColimitResult
      (WorldSpecs ())
      (Blend (ICandidate))
      (WorldMap ())
      (PropertyContributionMap
         ((A ((supported (WorldSpecSet (W)) 0.8)))
          (B ((supported (WorldSpecSet (W)) 0.7)))))))
(= (IPreparation)
   (structural-blend-preparation
      vehicle functional_use
      (SourceVPredicates ())
      (SourceAlgebraicSpecifications ())
      (GenericSpaceAlgebraicSpecification ())
      (EnrichmentStatus
         (PropertyTruthScalars Ready)
         (EnrichedHomValues Ready)
         (VColimitCheck Ready))))
(= (IWrappedPreparation)
   (Prepare-structural-result ((IPreparation))))

(= (IArtifacts)
   (OptimalityEnrichmentArtifacts
      (IVColimit) (IFamilyA) (IFamilyB) (IFamilyC)
      ((VitalRelationCorrespondence SharedR R R R (Q (W) 1.0)))
      (ISigmaA) (ISigmaB) (IInA) (IInB)
      (IBackA) (IBackB)
      ((PropertyEvidence supported (Q (W) 0.9)
         (SourceContributions A B)))
      ((RelevantEvidence purpose (Q (W) 0.8) (Q (W) 1.0)))))
(= (IInvalidArtifacts)
   (OptimalityEnrichmentArtifacts
      (IVColimit) (IFamilyA) (IFamilyB) (IFamilyC)
      ((VitalRelationCorrespondence SharedR R R R (Q (W) 1.0)))
      (IWrongSigmaA) (ISigmaB) (IInA) (IInB)
      (IBackA) (IBackB)
      ((PropertyEvidence supported (Q (W) 0.9)
         (SourceContributions A B)))
      ((RelevantEvidence purpose (Q (W) 0.8) (Q (W) 1.0)))))
(= (IAutoProvenanceArtifacts)
   (OptimalityEnrichmentArtifacts
      (IVColimit) (IFamilyA) (IFamilyB) (IFamilyC)
      ((VitalRelationCorrespondence SharedR R R R (Q (W) 1.0)))
      (ISigmaA) (ISigmaB) (IInA) (IInB)
      (IBackA) (IBackB)
      ()
      ((RelevantEvidence purpose (Q (W) 0.8) (Q (W) 1.0)))))

!(let (OptimalityIntegrationResult $status $value $context)
      (q-prepare-integrated-optimality-context
         (IPreparation) (IColimitResult) (IArtifacts))
   (== $status Ready))
!(let (OptimalityIntegrationResult $status $value $context)
      (q-prepare-integrated-optimality-context
         (IWrappedPreparation) (IColimitResult) (IArtifacts))
   (== $status Ready))
!(let (VOptimalityResult $status $results $value)
      (q-evaluate-integrated-optimality
         (IPreparation) (IColimitResult) (IArtifacts))
   (if (== $status Evaluated)
       (== (q-degree $value) 0.8)
       False))
!(let (VOptimalityResult $status $results $value)
      (q-evaluate-integrated-optimality
         (IPreparation) (IColimitResult) ())
   (if (== $status Blocked)
       (== (q-degree $value) 0.0)
       False))
!(let $wrong-perspective
      (structural-blend-preparation
         vehicle visual
         (SourceVPredicates ())
         (SourceAlgebraicSpecifications ())
         (GenericSpaceAlgebraicSpecification ())
         (EnrichmentStatus ()))
   (let (OptimalityIntegrationResult $status $value $reason)
        (q-prepare-integrated-optimality-context
           $wrong-perspective (IColimitResult) (IArtifacts))
      (== $status Blocked)))
!(let $wrong-name
      (structural-blend-preparation
         transport functional_use
         (SourceVPredicates ())
         (SourceAlgebraicSpecifications ())
         (GenericSpaceAlgebraicSpecification ())
         (EnrichmentStatus ()))
   (let (OptimalityIntegrationResult $status $value $reason)
        (q-prepare-integrated-optimality-context
           $wrong-name (IColimitResult) (IArtifacts))
      (== $status Blocked)))
!(let (OptimalityIntegrationResult $status $value $reason)
      (q-prepare-integrated-optimality-context
         (IPreparation) (IColimitResult) (IInvalidArtifacts))
   (if (== $status Blocked)
       (== (q-degree $value) 0.0)
       False))
!(let (VOptimalityResult $status $results $value)
      (q-evaluate-integrated-optimality
         (IPreparation)
         (IColimitWithContributions)
         (IAutoProvenanceArtifacts))
   (if (== $status Evaluated)
       (== (q-degree $value) 0.8)
       False))
!(let (VOptimalityResult $status $results $value)
      (q-evaluate-integrated-optimality
         (IPreparation) (IColimitResult) (IAutoProvenanceArtifacts))
   (if (== $status Blocked)
       (== (q-degree $value) 0.0)
       False))
