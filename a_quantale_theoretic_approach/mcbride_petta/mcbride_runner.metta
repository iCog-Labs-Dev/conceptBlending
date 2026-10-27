;; =============================================================================
;; McBride Derivative Optimization — MeTTa Runner
;; =============================================================================
;;
;; Public functions:
;;   (mcbride-refine $blend $source-a $source-b)
;;   (mcbride-refine-with $blend $source-a $source-b $eta $steps)
;;   (mcbride-emergence $blend $source-a $source-b)
;;   (quantale-blend-and-refine $name $concept-a $concept-b $mappings)
;; =============================================================================

!(import! &self a_quantale_theoretic_approach/mcbride_petta/refinement_loop)

;; Public: refine with default hyperparameters using native PeTTa logic
(= (mcbride-refine $blend $source-a $source-b)
   (q-mcbride-refine $blend $source-a $source-b))

;; Public: refine with explicit parameters using native PeTTa logic
(= (mcbride-refine-with $blend $source-a $source-b $eta $steps)
   (q-mcbride-refine-with $blend $source-a $source-b $eta $steps))

;; Public: compute emergence score natively in PeTTa
(= (mcbride-emergence $blend $source-a $source-b)
   (q-emergence $source-a $source-b $blend))

;; Public: full pipeline — colimit pushout then McBride refinement
(= (quantale-blend-and-refine $name $concept-a $concept-b $mappings)
   (let $colimit (q-vpredicate-colimit $name $concept-a $concept-b $mappings)
        (mcbride-refine $colimit $concept-a $concept-b)))
