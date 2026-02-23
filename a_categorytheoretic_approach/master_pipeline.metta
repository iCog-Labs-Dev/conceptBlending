; =======================================================
;        MASTER CONCEPT BLENDING PIPELINE
; =======================================================

; 1. DIRECT LOAD
!(import! &self extensions)
!(import! &self kb:knowledge_base)

; [INIT] Start Timer
!(util:start-monitor)

; 2. DEFINE WRAPPERS (Using the extensions.py names)
(= (generate_specs $c1 $c2)
   ; extensions.py handles both preprocessing and building inside llm:generate-spec
   (collapse (llm:generate-spec $c1 $c2))
)

(= (find_generalization $A $B) (llm:generate-gen $A $B))
(= (find_morphism $G $Target) (llm:find-morph $G $Target))
(= (compute_blend $A $B $G $mA $mB) (math:colimit $A $B $G $mA $mB))

; 3. EXECUTE THE PIPELINE
; =======================

!(util:log ">>> [PHASE 1] Generating Specifications...")

!(let $specs (generate_specs house boat)
   (block
      (let ($specA $specB) $specs
          
          ; --- Log Individual Specs to File ---
          (let $logA1 (util:log "\n; ================= SPEC A ===================")
             (let $logA2 (util:log $specA)
                (let $logB1 (util:log "\n; ================= SPEC B ===================")
                   (let $logB2 (util:log $specB)
          
                      ; STEP 1: Add to AtomSpace
                      (let $u1 (add-atom &self $specA)
                         (let $u2 (add-atom &self $specB)
                             (let $u3 (util:log "; ---> Specs Generated.")
                                 
                                 ; STEP 2: Generalization
                                 (let $u4 (util:log "\n>>> [PHASE 2] Finding Shared Generalization (G)...")
                                     (let $specG (find_generalization $specA $specB)
                                         (let $u5 (util:log "; ---> Generalization Found.")
                                             
                                             ; STEP 3: Morphisms
                                             (let $u6 (util:log "\n>>> [PHASE 3] Finding Morphisms (Mapping)...")
                                                 (let $mapA (find_morphism $specG $specA)
                                                     (let $mapB (find_morphism $specG $specB)
                                                         (let $u7 (util:log "; ---> Maps Acquired (JSON).")
                                                             
                                                             ; STEP 4: Math (colimit)
                                                             (let $u8 (util:log "\n>>> [PHASE 4] Computing Final Blend...")
                                                                 (let $result (compute_blend $specA $specB $specG $mapA $mapB)
                                                                     
                                                                     ; FINAL OUTPUT BLOCK 
                                                                     (let $u9 (util:log "\n; ===========================================")
                                                                         (let $u10 (util:log ";         FINAL BLEND              ")
                                                                             (let $u11 (util:log "; ===========================================")
                                                                                 (util:log $result)
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
      )
   )
)

!(util:log "\n>>> PIPELINE FINISHED.")
!(util:end-monitor)