; STEP 3 & 4: MORPHISMS AND BLENDING
!(import! &self extensions)

; 1. Load saved data
!(util:log ">>> Loading Saved Specs & Generalization...")
!(load-ascii &self output/specs.metta)
!(load-ascii &self output/generalization.metta)

; 2. Retrieve concepts
!(let $specA (match &self (Concept House $x) (Concept House $x))
   (let $specB (match &self (Concept Boat $y) (Concept Boat $y))
      (let $specG (match &self (Concept House@Boat $z) (Concept House@Boat $z))
      
         (superpose (
             !(util:log ">>> Finding Morphisms (Mappings)...")
             
             ; 3. Find Morphisms
             !(let $mapA (llm:find-morph ($specG "Generic") ($specA "Specific"))
                 (let $mapB (llm:find-morph ($specG "Generic") ($specB "Specific"))
                     
                     (superpose (
                         !(util:log "   -> Morphisms found.")
                         !(util:log ">>> Computing Colimit (The Blend)...")
                         
                         ; 4. Compute Blend
                         !(let $final_blend (math:colimit $specA $specB $specG $mapA $mapB)
                             (superpose (
                                 !(util:log "")
                                 !(util:log " FINAL BLENDED CONCEPT ")
                                 !(util:log "==================================================")
                                 !(util:log $final_blend)
                                 !(util:log "==================================================")
                                 !(util:save "output/final_blend.metta" $final_blend)
                             )) 
                         )
                     ))
                 )
             )
         ))
      )
   )
)