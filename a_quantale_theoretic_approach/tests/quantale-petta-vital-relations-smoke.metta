!(import! &self a_quantale_theoretic_approach/optimality/vital_relations)

(= (RelationCategory)
   (VCategory RelationCategory (W1 W2) (cause effect whole)
      ((cause cause (Q (W1 W2) 1.0))
       (effect effect (Q (W1 W2) 1.0))
       (whole whole (Q (W1 W2) 1.0)))))

(= (OtherCategory)
   (VCategory OtherCategory (W1 W2) (other)
      ((other other (Q (W1 W2) 1.0)))))

(= (BlendRelationCategory)
   (VCategory BlendRelationCategory (W1 W2)
      (blend_cause blend_effect blend_whole extra)
      ((blend_cause blend_cause (Q (W1 W2) 1.0))
       (blend_effect blend_effect (Q (W1 W2) 1.0))
       (blend_whole blend_whole (Q (W1 W2) 1.0))
       (extra extra (Q (W1 W2) 1.0)))))

(= (SourceToBlend)
   (VMorphism SourceToBlend
      (RelationCategory) (BlendRelationCategory)
      ((cause blend_cause)
       (effect blend_effect)
       (whole blend_whole))))

(= (CauseEffect)
   (vr-make CauseEffect functional_use (RelationCategory)
      ((cause effect (Q (W1) 0.8)))
      (SourceConcept Boat)))

(= (PartWhole)
   (vr-make PartWhole functional_use (RelationCategory)
      ((effect whole (Q (W2) 0.7)))
      (SourceConcept Boat)))

(= (StrongBlendCauseEffect)
   (vr-make CauseEffect functional_use (BlendRelationCategory)
      ((blend_cause blend_effect (Q (W1) 0.9)))
      (BlendConcept AmphibiousVehicle)))

(= (WeakBlendCauseEffect)
   (vr-make CauseEffect functional_use (BlendRelationCategory)
      ((blend_cause blend_effect (Q (W1) 0.4)))
      (BlendConcept WeakVehicle)))

(= (StrongBlendPartWhole)
   (vr-make PartWhole functional_use (BlendRelationCategory)
      ((blend_effect blend_whole (Q (W2) 0.8)))
      (BlendConcept AmphibiousVehicle)))

(= (CrossCategoryRelation)
   (VitalRelation CrossCategory functional_use
      (VProfunctor CrossCategory
         (RelationCategory) (OtherCategory)
         ((cause other (Q (W1) 0.5))))
      (SourceConcept Invalid)))

(= (MissingPerspectiveRelation)
   (vr-make CauseEffect () (RelationCategory)
      ((cause effect (Q (W1) 0.8)))
      (SourceConcept Invalid)))

(= (WrongPerspectiveRelation)
   (vr-make Similarity structural_composition (RelationCategory)
      ((cause whole (Q (W1 W2) 0.4)))
      (SourceConcept Invalid)))

(= (ValidFamily)
   (VitalRelationFamily functional_use (RelationCategory)
      ((CauseEffect) (PartWhole))))

(= (DuplicateFamily)
   (VitalRelationFamily functional_use (RelationCategory)
      ((CauseEffect) (CauseEffect))))

(= (MixedPerspectiveFamily)
   (VitalRelationFamily functional_use (RelationCategory)
      ((CauseEffect) (WrongPerspectiveRelation))))

(= (SourceFamily)
   (VitalRelationFamily functional_use (RelationCategory)
      ((CauseEffect) (PartWhole))))

(= (StrongBlendFamily)
   (VitalRelationFamily functional_use (BlendRelationCategory)
      ((StrongBlendCauseEffect) (StrongBlendPartWhole))))

(= (MissingBlendRelationFamily)
   (VitalRelationFamily functional_use (BlendRelationCategory)
      ((StrongBlendPartWhole))))

; Every query is expected to evaluate to True.
!(== (vr-name (CauseEffect)) CauseEffect)
!(== (vr-perspective (CauseEffect)) functional_use)
!(== (vr-provenance (CauseEffect)) (SourceConcept Boat))
!(== (vr-source-category (CauseEffect)) (RelationCategory))
!(== (vr-target-category (CauseEffect)) (RelationCategory))
!(== (vr-value (CauseEffect) cause effect) (Q (W1) 0.8))
!(vr-valid (CauseEffect))
!(vr-family-valid (ValidFamily))
!(== (vr-valid (CrossCategoryRelation)) False)
!(== (vr-valid (MissingPerspectiveRelation)) False)
!(== (vr-family-valid (DuplicateFamily)) False)
!(== (vr-family-valid (MixedPerspectiveFamily)) False)
!(ve-vmorphism-valid (SourceToBlend))
!(vr-valid (vr-pushforward (CauseEffect) (SourceToBlend)))
!(== (vr-value
       (vr-pushforward (CauseEffect) (SourceToBlend))
       blend_cause blend_effect)
     (Q (W1) 0.8))
!(== (q-degree
       (vr-relation-preservation-score
          (CauseEffect) (StrongBlendCauseEffect) (SourceToBlend)))
     1.0)
!(== (q-degree
       (vr-relation-preservation-score
          (CauseEffect) (WeakBlendCauseEffect) (SourceToBlend)))
     0.5)
!(vr-family-valid
    (vr-pushforward-family (SourceFamily) (SourceToBlend)))
!(== (q-degree
       (vr-family-preservation-score
          (SourceFamily) (StrongBlendFamily) (SourceToBlend)))
     1.0)
!(== (q-degree
       (vr-family-preservation-score
          (SourceFamily) (MissingBlendRelationFamily) (SourceToBlend)))
     0.0)
