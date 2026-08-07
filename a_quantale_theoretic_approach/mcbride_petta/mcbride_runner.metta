;; =============================================================================
;; McBride Derivative Optimization — MeTTa Runner
;; =============================================================================
;;
;; Implements MeTTa entry points for Section 7 of Goertzel (2026):
;; "Quantale Weakness Based Conceptual Blending"
;;
;; Public functions:
;;   (mcbride-refine $blend $source-a $source-b)
;;       Refine a blend using default η=0.05, steps=20.
;;   (mcbride-emergence $blend $source-a $source-b)
;;       Compute the emergence score σ without refinement.
;;   (quantale-blend-and-refine $name $concept-a $concept-b $mappings)
;;       Full pipeline: colimit pushout then McBride refinement.
;;
;; Requires: mcbride_grounded.register_mcbride_atoms(metta) called before use.
;; =============================================================================

; The colimit engine transitively imports quantale_types and v_predicate.
; Importing them again here duplicates PeTTa rewrite rules and causes an
; exponential number of reductions for quantale-blend-and-refine.
!(import! &self a_quantale_theoretic_approach/structural_reasoning/quantale_colimit_engine)

(= (mcbride-default-eta)   0.05)
(= (mcbride-default-steps) 20)

;; Public: refine with default hyperparameters
(= (mcbride-refine $blend $source-a $source-b)
   (mcbride-refine-with $blend $source-a $source-b
                        (mcbride-default-eta)
                        (mcbride-default-steps)))

;; Internal: dispatches to the grounded Python atom with explicit parameters.
;; Prefer (mcbride-refine ...) for external use.
(= (mcbride-refine-with $blend $source-a $source-b $eta $steps)
   (mcbride-py-refine $blend $source-a $source-b $eta $steps))

(= (mcbride-emergence $blend $source-a $source-b)
   (mcbride-py-emergence $blend $source-a $source-b))

(= (quantale-blend-and-refine $name $concept-a $concept-b $mappings)
   (let $colimit (q-vpredicate-colimit $name $concept-a $concept-b $mappings)
        (mcbride-refine $colimit $concept-a $concept-b)))
