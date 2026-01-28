; =======================================================
;       MASTER CONCEPT BLENDING PIPELINE
; =======================================================

!(import! &self extensions)
!(import! &self kb:knowledge_base)

; Algebraic specification Builder
(= (generate-specs $c1 $c2)
    (let $context1 (let $fetchedcont1 (main-fetch $c1) (cons-atom Context $fetchedcont1))
        (let $context2 (let $fetchedcont2 (main-fetch $c2) (cons-atom Context $fetchedcont2))
            (llm:generate-spec ($c1 $context1) ($c2 $context2))
        )
    )
)

; Generalization Handler
(= (find-generalization $specA $specB) 
   (llm:generate-gen $specA $specB)
)

; Morphism Finder(Mappings between generic space and each input spaces)
(= (find-morphism $specG $specTarget)
   (llm:find-morph $specG $specTarget)
)

;--- BLENDING COMPUTER (COLIMIT Calculation)
(= (compute-blend $A $B $G $mA $mB) (math:colimit $A $B $G $mA $mB))


; INTEGRATED PIPELINE
; =======================

(= (main $concept1 $concept2)
    (let $p1 (util:log ">>> [PHASE 1] Generating Specifications...")
        (let $specs (generate_specs house boat)
            (let ($specA $specB) $specs
                ; STEP 1: Add to AtomSpace
                (let $u1 (add-atom &self $specA)
                    (let $u2 (add-atom &self $specB)
                        (let $u3 (util:log "; ---> Specs Generated.")
                            
                            ; STEP 2: Generalization
                            (let $u4 (util:log "\n>>> [PHASE 2] Finding Shared Generalization (G)...")
                                (let $specG (find_generalization $specA $specB)
                                    (let $u5 (util:log "; ---> Generalization Found (Debug Mode).")
                                        
                                        ; STEP 3: Morphisms
                                        (let $u6 (util:log "\n>>> [PHASE 3] Finding Morphisms (Mapping)...")
                                            (let $mapA (find_morphism $specG $specA)
                                                (let $mapB (find_morphism $specG $specB)
                                                    (let $u7 (util:log "; ---> Maps Acquired (JSON).")
                                                        
                                                        ;STEP 4: Math (colimit)
                                                        (let $u8 (util:log "\n>>> [PHASE 4] Computing Final Blend...")
                                                            (let $result (compute_blend $specA $specB $specG $mapA $mapB)
                                                                
                                                                ; FINAL OUTPUT BLOCK
                                                                (let $u9 (println! "\n; ===========================================")
                                                                    (let $u10 (println! ";        FINAL HOUSEBOAT BLEND              ")
                                                                        (let $u11 (println! "; ===========================================")
                                                                            (println! $result)
                                                                        )
                                                                    )
                                                                )
                                                            )
                                                        )
                                                    )
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )
    )
)

!(util:log ">>> [PHASE 1] Generating Specifications...")
; !(generate-specs house boat)
; !(find-generalization (concept house spec) (concept boat spec))
!(llm:generate-spec house boat)
; !(main house boat)

!(util:log "\n>>> PIPELINE FINISHED.")
