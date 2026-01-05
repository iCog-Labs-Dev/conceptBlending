; ALGSPEC BUILDER WRAPPER (DIRECT MODE)
; =====================================

!(import! &self libs)
!(import! &self knowledge_base)

; Logic
(=(algspec_builder $concept1 $concept2)
   (let $context1 (main-fetch $concept1)
      (let $context2 (main-fetch $concept2)
         
         ; Verify whether we have the ingredients
         (let $_ (println! (format-args ">>> Context Found for {}: {}" ($concept1 $context1)))
             
             ; STEP 1: BYPASSING PREPROCESSING 
             (let $clean_context (format-args "Context for {}: {}. Context for {}: {}." ($concept1 $context1 $concept2 $context2))
                 
                 ; STEP 2: GENERATION
                 (gpt_algspec_builder ($concept1 $clean_context) ($concept2 $clean_context))
             )
         )
      )
   )
)

; EXECUTION
!(println! ">>> STARTING GENERATION...")

; Calling the algspec_builder
!(let $result (algspec_builder house boat)
    (superpose (
        (println! "\n; === FINAL RESULT ===")
        (println! $result)
    ))
)

!(println! ">>> GENERATION FINISHED")