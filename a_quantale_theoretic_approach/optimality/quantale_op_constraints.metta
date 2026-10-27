!(import! &self a_quantale_theoretic_approach/structural_reasoning/quantale_colimit_engine)

; Quantale OP constraints over property-level V-predicate colimits.
;
; The five-argument legacy evaluator cannot supply enriched categories,
; VColimit certificates, vital relations, or reconstruction maps. Those fields
; are now reported as Pending/Blocked instead of receiving neutral unit values.
; Use q-enriched-optimality-evaluator for the complete evidence-aware path.

(= (q-legacy-constraint-evaluated $name $value $evidence)
   (VConstraintResult $name Evaluated $value $evidence))
(= (q-legacy-constraint-blocked $name $universe $reason)
   (VConstraintResult $name Blocked (Q () 0.0) $reason))
(= (q-legacy-constraint-pending $name $universe $reason)
   (VConstraintResult $name Pending (Q () 0.0) $reason))

(= (q-op-universe $candidate $canonical)
   (unique-atom (union-atom (v-world-universe $candidate)
                            (v-world-universe $canonical))))

(= (q-integration-op $candidate $canonical)
   (q-equivalence-score $candidate $canonical))

; Good Reason: every candidate property should be supported by the canonical
; property colimit, which itself is built from source contributions.
(= (q-good-reason-op $candidate $canonical)
   (let* (($candidate-properties (v-property-list $candidate))
          ($canonical-properties (v-property-list $canonical))
          ($universe (q-op-universe $candidate $canonical)))
      (q-hom-properties $candidate-properties $canonical-properties $universe)))

(= (q-unpacking-op $candidate $canonical)
   (q-legacy-constraint-blocked
      Unpacking (q-op-universe $candidate $canonical)
      MissingBlendToSourceReconstructions))

(= (q-topology-op $candidate $concept-a $concept-b)
   (q-legacy-constraint-blocked
      Topology
      (unique-atom (union-atom (v-world-universe $candidate)
                               (union-atom (v-world-universe $concept-a)
                                           (v-world-universe $concept-b))))
      MissingVitalRelationFamilies))

(= (q-web-op $candidate $concept-a $concept-b)
   (q-legacy-constraint-blocked
      Web
      (unique-atom (union-atom (v-world-universe $candidate)
                               (union-atom (v-world-universe $concept-a)
                                           (v-world-universe $concept-b))))
      MissingCrossSpaceCorrespondences))

(= (q-metonymic-tightening-op $candidate $concept-a $concept-b)
   (q-legacy-constraint-blocked
      MetonymicTightening
      (unique-atom (union-atom (v-world-universe $candidate)
                               (union-atom (v-world-universe $concept-a)
                                           (v-world-universe $concept-b))))
      MissingGenericMediatedRelationPaths))

(= (q-weight-for-property $prop-name $weights)
   (if (== $weights ())
       0.0
       (let* (($head (car-atom $weights))
              ($tail (cdr-atom $weights))
              ($weighted-prop (index-atom $head 0))
              ($weight (index-atom $head 1)))
          (if (== $prop-name $weighted-prop)
              $weight
              (q-weight-for-property $prop-name $tail)))))

(= (q-relevance-from-properties $properties $weights $universe)
   (if (== $properties ())
       (q-bottom)
       (let* (($head (car-atom $properties))
              ($tail (cdr-atom $properties))
              ($prop-name (v-property-name $head))
              ($weight (q-weight-for-property $prop-name $weights))
              ($head-relevance (q-tensor (q-score $weight $universe)
                                         (v-property-quantale $head)))
              ($tail-relevance (q-relevance-from-properties $tail $weights $universe)))
          (q-join $head-relevance $tail-relevance))))

(= (q-relevance-op $candidate $weights)
   (if (== $weights ())
       (q-unit (v-world-universe $candidate))
       (q-relevance-from-properties (v-property-list $candidate)
                                    $weights
                                    (v-world-universe $candidate))))

(= (q-opt-product $integration $topology $web $unpacking $good-reason $tightening $relevance)
   (q-tensor $integration
      (q-tensor $topology
         (q-tensor $web
            (q-tensor $unpacking
               (q-tensor $good-reason
                  (q-tensor $tightening $relevance)))))))

(= (q-op-evaluater $candidate $concept-a $concept-b $mappings $relevance-weights)
   (let* (($canonical (q-vpredicate-colimit QuantaleCanonicalBlend $concept-a $concept-b $mappings))
          ($universe (q-op-universe $candidate $canonical))
          ($integration
             (q-legacy-constraint-pending
                Integration $universe
                (RequiresVColimitCertificate
                   (LegacyPropertyScore
                      (q-integration-op $candidate $canonical)))))
          ($topology (q-topology-op $candidate $concept-a $concept-b))
          ($web (q-web-op $candidate $concept-a $concept-b))
          ($unpacking (q-unpacking-op $candidate $canonical))
          ($good-reason
             (q-legacy-constraint-evaluated
                GoodReason
                (q-good-reason-op $candidate $canonical)
                LegacyCanonicalPropertySupport))
          ($tightening (q-metonymic-tightening-op $candidate $concept-a $concept-b))
          ($relevance
             (if (== $relevance-weights ())
                 (q-legacy-constraint-blocked
                    Relevance $universe MissingRelevanceEvidence)
                 (q-legacy-constraint-evaluated
                    Relevance
                    (q-relevance-op $candidate $relevance-weights)
                    LegacyPropertyWeights)))
          ($results
             ($integration $topology $web $unpacking
              $good-reason $tightening $relevance)))
      (QuantaleOPResult
         (Status Blocked)
         (Canonical $canonical)
         $integration $topology $web $unpacking
         $good-reason $tightening $relevance
         (Opt (q-bottom) 0.0))))

(= (q-op-evaluator $candidate $concept-a $concept-b $mappings $relevance-weights)
   (q-op-evaluater $candidate $concept-a $concept-b $mappings $relevance-weights))
