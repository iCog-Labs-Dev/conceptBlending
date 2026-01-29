; =======================================================
;       MASTER CONCEPT BLENDING PIPELINE
; =======================================================

; 1. DIRECT LOAD
!(import! &self extensions)
!(import! &self kb:knowledge_base)

; 2. DEFINE WRAPPERS
(= (generate_specs $c1 $c2)
   (let $context1 (main-fetch $c1)
      (let $context2 (main-fetch $c2)
         (let $clean (format-args "Context {}: {}. Context {}: {}." ($c1 $context1 $c2 $context2))
             (collapse (llm:generate-spec ($c1 $clean) ($c2 $clean)))
         )
      )
   )
)

; --- GENERALIZATION ---

(= (find_generalization $A $B) 
   (llm:generate-gen $A $B)
)

; (= (find_generalization $A $B) (llm:generate-gen $A $B))

; --- MORPHISM (Gluing) ----
(= (find_morphism $G $Target) (llm:find-morph $G $Target))

;--- THE REAL BLENDING (COLIMIT Calculation)
(= (compute_blend $A $B $G $mA $mB) (math:colimit $A $B $G $mA $mB))


; 3. EXECUTE THE PIPELINE
; =======================

!(util:log ">>> [PHASE 1] Generating Specifications...")

!(let $specs (generate_specs virus software)
   (let ($specA $specB) $specs
      
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
                                             
                                             ;STEP 4: Math (colimit)
                                             (let $u8 (util:log "\n>>> [PHASE 4] Computing Final Blend...")
                                                 (let $result (compute_blend $specA $specB $specG $mapA $mapB)
                                                     
                                                     ; FINAL OUTPUT BLOCK
                                                     (let $u9 (println! "\n; ===========================================")
                                                         (let $u10 (println! ";        FINAL BLEND              ")
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
!(util:log "\n>>> PIPELINE FINISHED.")