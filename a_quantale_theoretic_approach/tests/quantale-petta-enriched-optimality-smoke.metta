!(import! &self a_quantale_theoretic_approach/optimality/enriched_optimality_constraints)

(= (OptG)
   (VCategory OptG (W) (g) ((g g (Q (W) 1.0)))))
(= (OptA)
   (VCategory OptA (W) (a) ((a a (Q (W) 1.0)))))
(= (OptB)
   (VCategory OptB (W) (b) ((b b (Q (W) 1.0)))))
(= (OptC)
   (VCategory OptC (W) (c) ((c c (Q (W) 1.0)))))
(= (OptX)
   (VCategory OptX (W) (x) ((x x (Q (W) 1.0)))))

(= (OptSigmaA) (VMorphism OptSigmaA (OptG) (OptA) ((g a))))
(= (OptSigmaB) (VMorphism OptSigmaB (OptG) (OptB) ((g b))))
(= (OptInA) (VMorphism OptInA (OptA) (OptC) ((a c))))
(= (OptInB) (VMorphism OptInB (OptB) (OptC) ((b c))))
(= (OptBackA) (VMorphism OptBackA (OptC) (OptA) ((c a))))
(= (OptBackB) (VMorphism OptBackB (OptC) (OptB) ((c b))))
(= (InvalidOptInA) (VMorphism InvalidOptInA (OptA) (OptC) ((a ghost))))
(= (OptCocone)
   (VCocone OptCocone (OptSigmaA) (OptSigmaB) (OptInA) (OptInB)))

(= (OptCompareInA) (VMorphism OptCompareInA (OptA) (OptX) ((a x))))
(= (OptCompareInB) (VMorphism OptCompareInB (OptB) (OptX) ((b x))))
(= (OptComparison)
   (VCocone OptComparison
      (OptSigmaA) (OptSigmaB) (OptCompareInA) (OptCompareInB)))
(= (OptMediator) (VMorphism OptMediator (OptC) (OptX) ((c x))))
(= (OptVColimit)
   (VColimit OptVColimit (OptCocone)
      (MediatingWitnesses
         ((MediatingWitness (OptComparison) (OptMediator))))
      (ComparisonScope ((OptComparison)) Exhaustive)))

(= (RelationA)
   (vr-make R functional_use (OptA)
      ((a a (Q (W) 0.8))) (SourceConcept A)))
(= (RelationB)
   (vr-make R functional_use (OptB)
      ((b b (Q (W) 0.7))) (SourceConcept B)))
(= (RelationC)
   (vr-make R functional_use (OptC)
      ((c c (Q (W) 0.9))) (BlendConcept C)))
(= (WeakRelationC)
   (vr-make R functional_use (OptC)
      ((c c (Q (W) 0.4))) (BlendConcept WeakC)))

(= (FamilyA)
   (VitalRelationFamily functional_use (OptA) ((RelationA))))
(= (FamilyB)
   (VitalRelationFamily functional_use (OptB) ((RelationB))))
(= (FamilyC)
   (VitalRelationFamily functional_use (OptC) ((RelationC))))
(= (WeakFamilyC)
   (VitalRelationFamily functional_use (OptC) ((WeakRelationC))))
(= (EmptyFamilyA)
   (VitalRelationFamily functional_use (OptA) ()))

(= (OptCandidate)
   (Concept C functional_use
      (V-predicate
         (Property ((supported (WorldSpecSet (W)) 0.8))))))

(= (OptCorrespondences)
   ((VitalRelationCorrespondence SharedR R R R (Q (W) 1.0))))
(= (HalfWeightCorrespondences)
   ((VitalRelationCorrespondence SharedR R R R (Q (W) 0.5))))
(= (OptPropertyEvidence)
   ((PropertyEvidence supported (Q (W) 0.9)
      (SourceContributions A B))))
(= (OptRelevanceEvidence)
   ((RelevantEvidence purpose (Q (W) 0.8) (Q (W) 1.0))))

(= (CompleteContext)
   (VOptimalityContext
      (OptCandidate) (OptVColimit)
      (FamilyA) (FamilyB) (FamilyC)
      (OptCorrespondences)
      (OptSigmaA) (OptSigmaB) (OptInA) (OptInB)
      (OptBackA) (OptBackB)
      (OptPropertyEvidence) (OptRelevanceEvidence)))

(= (BlockedContext)
   (VOptimalityContext
      (OptCandidate) (OptVColimit)
      (FamilyA) (FamilyB) (FamilyC)
      ()
      (OptSigmaA) (OptSigmaB) (OptInA) (OptInB)
      () ()
      () ()))

(= (HalfWebContext)
   (VOptimalityContext
      (OptCandidate) (OptVColimit)
      (FamilyA) (FamilyB) (FamilyC)
      (HalfWeightCorrespondences)
      (OptSigmaA) (OptSigmaB) (OptInA) (OptInB)
      (OptBackA) (OptBackB)
      (OptPropertyEvidence) (OptRelevanceEvidence)))

(= (CompleteInputs)
   (VOptimalityInputs
      (OptCandidate) (OptVColimit)
      (FamilyA) (FamilyB) (FamilyC)
      (OptCorrespondences)
      (OptSigmaA) (OptSigmaB) (OptInA) (OptInB)
      (OptBackA) (OptBackB)
      (OptPropertyEvidence) (OptRelevanceEvidence)))

(= (WrongOptSigmaA)
   (VMorphism WrongOptSigmaA (OptG) (OptB) ((g b))))
(= (WrongGenericTargetInputs)
   (VOptimalityInputs
      (OptCandidate) (OptVColimit)
      (FamilyA) (FamilyB) (FamilyC)
      (OptCorrespondences)
      (WrongOptSigmaA) (OptSigmaB) (OptInA) (OptInB)
      (OptBackA) (OptBackB)
      (OptPropertyEvidence) (OptRelevanceEvidence)))

; All queries must evaluate to True.
!(== (q-constraint-status
       (q-vcolimit-integration-op (OptVColimit) (W)))
     Evaluated)
!(== (q-degree
       (q-constraint-value
          (q-vcolimit-integration-op (OptVColimit) (W))))
     1.0)
!(== (q-constraint-status
       (q-vcolimit-integration-op () (W)))
     Blocked)
!(== (q-degree
       (q-constraint-value
          (q-topology-op
             (FamilyA) (FamilyB) (FamilyC) (OptInA) (OptInB))))
     1.0)
!(== (q-degree
       (q-constraint-value
          (q-topology-op
             (FamilyA) (FamilyB) (WeakFamilyC) (OptInA) (OptInB))))
     0.5)
!(== (q-constraint-status
       (q-topology-op
          (EmptyFamilyA) (FamilyB) (FamilyC) (OptInA) (OptInB)))
     Blocked)
!(== (q-constraint-status
       (q-topology-op
          (FamilyA) (FamilyB) (FamilyC) (InvalidOptInA) (OptInB)))
     Blocked)
!(== (q-degree
       (q-constraint-value
          (q-web-op
             (OptCorrespondences)
             (FamilyA) (FamilyB) (FamilyC) (OptInA) (OptInB))))
     1.0)
!(== (q-constraint-status
       (q-web-op ()
          (FamilyA) (FamilyB) (FamilyC) (OptInA) (OptInB)))
     Blocked)
!(== (q-degree
       (q-constraint-value
          (q-unpacking-op
             (OptInA) (OptBackA) (OptInB) (OptBackB) (W))))
     1.0)
!(== (q-constraint-status
       (q-unpacking-op (OptInA) () (OptInB) () (W)))
     Blocked)
!(== (q-constraint-status
       (q-unpacking-op () () (OptInB) (OptBackB) (W)))
     Blocked)
!(== (q-degree
       (q-constraint-value
          (q-good-reason-provenance-op
             (OptCandidate) (OptPropertyEvidence))))
     1.0)
!(== (q-constraint-status
       (q-good-reason-provenance-op (OptCandidate) ()))
     Blocked)
!(== (q-constraint-status
       (q-good-reason-provenance-op
          (OptCandidate)
          ((PropertyEvidence supported (Q (W) 0.9) ()))))
     Blocked)
!(== (q-degree
       (q-constraint-value
          (q-metonymic-tightening-op
             (FamilyA) (FamilyB) (FamilyC)
             (OptSigmaA) (OptSigmaB) (OptInA) (OptInB))))
     1.0)
!(let $weak-score
   (q-degree
      (q-constraint-value
         (q-metonymic-tightening-op
            (FamilyA) (FamilyB) (WeakFamilyC)
            (OptSigmaA) (OptSigmaB) (OptInA) (OptInB))))
   (if (> $weak-score 0.714)
       (< $weak-score 0.715)
       False))
!(== (q-degree
       (q-constraint-value
          (q-relevance-evidence-op (OptRelevanceEvidence) (W))))
     0.8)
!(== (q-constraint-status
       (q-relevance-evidence-op () (W)))
     Blocked)
!(== (q-constraint-status
       (q-relevance-evidence-op
          ((RelevantEvidence invalid (Q (OTHER) 0.8) (Q (W) 1.0)))
          (W)))
     Blocked)
!(let (VOptimalityResult $status $results $value)
      (q-enriched-optimality-evaluator (CompleteContext))
   (if (== $status Evaluated)
       (== (q-degree $value) 0.8)
       False))
!(let (VOptimalityResult $status $results $value)
      (q-enriched-optimality-evaluator (BlockedContext))
   (if (== $status Blocked)
       (== (q-degree $value) 0.0)
       False))
!(let (VOptimalityResult $status $results $value)
      (q-enriched-optimality-evaluator (HalfWebContext))
   (if (== $status Evaluated)
       (let $degree (q-degree $value)
          (if (> $degree 0.399)
              (< $degree 0.401)
              False))
       False))
!(q-context-valid (q-build-optimality-context (CompleteInputs)))
!(let $transported
      (q-context-transported-family-a
         (q-build-optimality-context (CompleteInputs)))
   (== (q-degree
          (vr-value
             (vr-family-find R (vr-family-relations $transported))
             c c))
       0.8))
!(== (q-build-optimality-context (WrongGenericTargetInputs))
     (VOptimalityContextError GenericToATargetMismatch))
!(let (VOptimalityResult $status $results $value)
      (q-enriched-optimality-evaluator (WrongGenericTargetInputs))
   (if (== $status Blocked)
       (== (q-degree $value) 0.0)
       False))
!(let* (
   ($shared (q-build-optimality-context (CompleteInputs)))
   ((VOptimalityResult $raw-status $raw-results $raw-value)
      (q-enriched-optimality-evaluator (CompleteInputs)))
   ((VOptimalityResult $shared-status $shared-results $shared-value)
      (q-enriched-optimality-evaluator $shared)))
   (if (== $raw-status $shared-status)
       (== $raw-value $shared-value)
       False))
