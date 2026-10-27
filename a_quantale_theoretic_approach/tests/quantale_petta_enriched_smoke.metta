!(import! &self a_quantale_theoretic_approach/core_representation/v_enriched)

(= (DiscreteG)
   (VCategory G (W1 W2) (g)
      ((g g (Q (W1 W2) 1.0)))))

(= (DiscreteA)
   (VCategory A (W1 W2) (a)
      ((a a (Q (W1 W2) 1.0)))))

(= (DiscreteB)
   (VCategory B (W1 W2) (b1 b2)
      ((b1 b1 (Q (W1 W2) 1.0))
       (b2 b2 (Q (W1 W2) 1.0)))))

(= (DiscreteC)
   (VCategory C (W1 W2) (c other)
      ((c c (Q (W1 W2) 1.0))
       (other other (Q (W1 W2) 1.0)))))

(= (DiscreteD)
   (VCategory D (W1 W2) (d)
      ((d d (Q (W1 W2) 1.0)))))

(= (ValidChain)
   (VCategory Chain (W1 W2) (x y z)
      ((x x (Q (W1 W2) 1.0))
       (y y (Q (W1 W2) 1.0))
       (z z (Q (W1 W2) 1.0))
       (x y (Q (W1) 0.8))
       (y z (Q (W1) 0.5))
       (x z (Q (W1) 0.5)))))

(= (BrokenChain)
   (VCategory BrokenChain (W1 W2) (x y z)
      ((x x (Q (W1 W2) 1.0))
       (y y (Q (W1 W2) 1.0))
       (z z (Q (W1 W2) 1.0))
       (x y (Q (W1) 0.8))
       (y z (Q (W1) 0.5))
       (x z (Q (W1) 0.3)))))

(= (DuplicateObjects)
   (VCategory DuplicateObjects (W1 W2) (x x)
      ((x x (Q (W1 W2) 1.0)))))

(= (SigmaA)
   (VMorphism sigmaA (DiscreteG) (DiscreteA) ((g a))))

(= (SigmaB)
   (VMorphism sigmaB (DiscreteG) (DiscreteB) ((g b1))))

(= (InA)
   (VMorphism iA (DiscreteA) (DiscreteC) ((a c))))

(= (InB)
   (VMorphism iB (DiscreteB) (DiscreteC) ((b1 c) (b2 other))))

(= (BadInB)
   (VMorphism badIB (DiscreteB) (DiscreteC) ((b1 other) (b2 c))))

(= (ComparisonApex)
   (VCategory X (W1 W2) (x extra)
      ((x x (Q (W1 W2) 1.0))
       (extra extra (Q (W1 W2) 1.0)))))

(= (ComparisonInA)
   (VMorphism comparisonIA (DiscreteA) (ComparisonApex) ((a x))))

(= (ComparisonInB)
   (VMorphism comparisonIB (DiscreteB) (ComparisonApex)
      ((b1 x) (b2 extra))))

(= (ComparisonCocone)
   (VCocone ComparisonCocone
      (SigmaA) (SigmaB) (ComparisonInA) (ComparisonInB)))

(= (UniqueMediator)
   (VMorphism uniqueMediator (DiscreteC) (ComparisonApex)
      ((c x) (other extra))))

(= (GoodVColimit)
   (VColimit GoodVColimit (GoodCocone)
      (MediatingWitnesses
         ((MediatingWitness (ComparisonCocone) (UniqueMediator))))
      (ComparisonScope ((ComparisonCocone)) Exhaustive)))

(= (MissingMediatorVColimit)
   (VColimit MissingMediator (GoodCocone)
      (MediatingWitnesses ())
      (ComparisonScope ((ComparisonCocone)) Exhaustive)))

(= (NonUniqueVColimit)
   (VColimit NonUnique (GoodCocone)
      (MediatingWitnesses
         ((MediatingWitness (ComparisonCocone) (UniqueMediator))
          (MediatingWitness (ComparisonCocone) (UniqueMediator))))
      (ComparisonScope ((ComparisonCocone)) Exhaustive)))

(= (ExtraMapEntry)
   (VMorphism ExtraMapEntry (DiscreteG) (DiscreteA) ((g a) (ghost a))))

(= (GoodCocone)
   (VCocone GoodCocone (SigmaA) (SigmaB) (InA) (InB)))

(= (BadCocone)
   (VCocone BadCocone (SigmaA) (SigmaB) (InA) (BadInB)))

(= (P)
   (VProfunctor P (DiscreteA) (DiscreteB)
      ((a b1 (Q (W1) 0.4))
       (a b2 (Q (W2) 0.7)))))

(= (R)
   (VProfunctor R (DiscreteB) (DiscreteC)
      ((b1 c (Q (W1) 0.9))
       (b2 c (Q (W2) 0.5)))))

(= (T)
   (VProfunctor T (DiscreteC) (DiscreteD)
      ((c d (Q (W1 W2) 0.6)))))

(= (ActionSource)
   (VCategory ActionSource (W1 W2) (a1 a2)
      ((a1 a1 (Q (W1 W2) 1.0))
       (a2 a2 (Q (W1 W2) 1.0))
       (a1 a2 (Q (W1) 0.8)))))

(= (BrokenP)
   (VProfunctor BrokenP (ActionSource) (DiscreteA)
      ((a2 a (Q (W1) 0.8))
       (a1 a (Q (W1) 0.5)))))

(= (MalformedP)
   (VProfunctor MalformedP (DiscreteA) (DiscreteB)
      ((ghost b1 (Q (W1) 0.5)))))

; Every query is expected to evaluate to True. The Python runtime test checks
; that no False or unevaluated contract result is emitted.
!(== (q-join (Q (W1) 0.4) (Q (W2) 0.7)) (Q (W1 W2) 0.7))
!(== (q-meet (Q (W1 W2) 0.4) (Q (W1) 0.7)) (Q (W1) 0.4))
!(ve-vcategory-valid (ValidChain))
!(== (ve-vcategory-valid (BrokenChain)) False)
!(== (ve-vcategory-valid (DuplicateObjects)) False)
!(ve-vmorphism-valid (SigmaA))
!(== (ve-vmorphism-valid (ExtraMapEntry)) False)
!(ve-vcocone-valid (GoodCocone))
!(== (ve-vcocone-valid (BadCocone)) False)
!(ve-vprofunctor-valid (P))
!(== (ve-vprofunctor-valid (BrokenP)) False)
!(== (ve-vprofunctor-valid (MalformedP)) False)
!(let $coend (ve-profunctor-value
       (ve-vprofunctor-compose PThenR (P) (R)) a c)
   (if (== (q-worlds $coend) (W1 W2))
       (if (> (q-degree $coend) 0.359)
           (< (q-degree $coend) 0.361)
           False)
       False))
!(let $coend (ve-coend a c (P) (R))
   (if (== (q-worlds $coend) (W1 W2))
       (if (> (q-degree $coend) 0.359)
           (< (q-degree $coend) 0.361)
           False)
       False))
!(== (ve-coend ghost c (P) (R))
     (VError UnknownCoendSource ghost))
!(== (ve-coend a ghost (P) (R))
     (VError UnknownCoendTarget ghost))
!(== (ve-coend ghost a (MalformedP) (P))
     (VError InvalidFirstProfunctor))
!(== (ve-coend a ghost (P) (MalformedP))
     (VError InvalidAfterProfunctor))
!(== (ve-coend a b1 (P) (P))
     (VError IncompatibleProfunctorComposition))
!(q-equal (ve-coend a other (P) (R)) (q-bottom))
!(let $companion (ve-vmorphism-companion CompanionInA (InA))
   (q-equal
      (ve-profunctor-value $companion a c)
      (Q (W1 W2) 1.0)))
!(let $conjoint (ve-vmorphism-conjoint ConjointInA (InA))
   (q-equal
      (ve-profunctor-value $conjoint c a)
      (Q (W1 W2) 1.0)))
!(ve-vprofunctor-valid (ve-vmorphism-companion CompanionInA (InA)))
!(ve-vprofunctor-valid (ve-vmorphism-conjoint ConjointInA (InA)))
!(ve-vcolimit-valid (GoodVColimit))
!(== (ve-vcolimit-valid (MissingMediatorVColimit)) False)
!(== (ve-vcolimit-valid (NonUniqueVColimit)) False)
!(let* (($p-then-r (ve-vprofunctor-compose PThenRLeft (P) (R)))
        ($left-associated
           (ve-vprofunctor-compose PThenRThenT $p-then-r (T)))
        ($r-then-t (ve-vprofunctor-compose RThenTRight (R) (T)))
        ($right-associated
           (ve-vprofunctor-compose PThenRThenT (P) $r-then-t)))
   (q-equal
      (ve-profunctor-value $left-associated a d)
      (ve-profunctor-value $right-associated a d)))
!(let $identity-a (ve-vprofunctor-identity IdentityA (DiscreteA))
   (q-equal
      (ve-profunctor-value
         (ve-vprofunctor-compose IdentityAThenP $identity-a (P)) a b1)
      (ve-profunctor-value (P) a b1)))
!(let $identity-b (ve-vprofunctor-identity IdentityBRight (DiscreteB))
   (q-equal
      (ve-profunctor-value
         (ve-vprofunctor-compose PThenIdentityB (P) $identity-b) a b2)
      (ve-profunctor-value (P) a b2)))
!(ve-vprofunctor-valid (ve-vprofunctor-identity IdentityB (DiscreteB)))
