; ===============================================\========
;       MASTER CONCEPT BLENDING PIPELINE\
; ===============================================\========

; 1. DIRECT LOAD OF EXTENSIONS
!(import! &self extensions)
!(import! &self knowledge_base)

; 2. DEFINE WRAPPERS LOCALLY

; --- A. Spec Generation ---
(= (generate_specs $c1 $c2)
   (let $context1 (main-fetch $c1)
      (let $context2 (main-fetch $c2)
         (let $clean (format-args "Context {}: {}. Context {}: {}." ($c1 $context1 $c2 $context2))
             (collapse (llm:generate-spec ($c1 $clean) ($c2 $clean)))
         )
      )
   )
)

; B. Generalization 
(= (find_generalization $A $B)
   (llm:generate-gen $A $B)
)

; C. Morphism (The Glue) 
(= (find_morphism $G $Target)
   (llm:find-morph $G $Target)
)

; D. Math Engine 
(= (compute_blend $A $B $G $mA $mB) 
   (math:colimit $A $B $G $mA $mB)
)

; 3. EXECUTE THE PIPELINE
; =======================

!(util:log ">>> [PHASE 1] Generating Specifications...")

!(let $specs (generate_specs house boat)
   (let ($specA $specB) $specs
      (superpose (
         ; 1. Save Specs
         !(add-atom &self $specA)
         !(add-atom &self $specB)
         (util:log "; ---> Specs Generated.")

         !(util:log "\n>>> [PHASE 2] Finding Shared Generalization (G)...")
         
         ; 2. Find G
         (let $specG (find_generalization $specA $specB)
            (superpose (
               (util:log "; ---> Generalization Found.")

               !(util:log "\n>>> [PHASE 3] Finding Morphisms (Mapping)...")
               
               ; 3. Finding Morphisms
               (let $mapA (find_morphism $specG $specA)
                  (let $mapB (find_morphism $specG $specB)
                     (superpose (
                        (util:log "; ---> Maps Acquired (JSON).")

                        !(util:log "\n>>> [PHASE 4] Computing Final Blend...")
                        
                        ; 4. Compute Colimit
                        (let $result (compute_blend $specA $specB $specG $mapA $mapB)
                           (superpose (
                              (println! "\n; ===========================================")
                              (println! ";        FINAL HOUSEBOAT BLEND              ")
                              (println! "; ===========================================")
                              (println! $result)
                           ))
                        )
                     ))
                  )
               )
            ))
         )
      ))
   )
)