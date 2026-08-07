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
!(ve-vprofunctor-valid (ve-vprofunctor-identity IdentityB (DiscreteB)))
