; ALGSPEC BUILDER (ROBUST MODE)
!(import! &self libs)
!(import! &self knowledge_base)

; Logic
(=(algspec_builder $concept1 $concept2)
     (let ($context1 $context2) ((main-fetch $concept1) (main-fetch $concept2))
        (let ($generated_context) (collapse (gpt_context_preprocessing ($concept1 $context1) ($concept2 $context2)))
           (gpt_algspec_builder ($concept1 $generated_context) ($concept2 $generated_context)))
))`

; EXECUTION & ROBUST PRINTING

!(println! ">>> STARTING GENERATION...")

; We use 'case' (or match) to handle the result safely
!(let $result (algspec_builder "house" "boat")
    (superpose (
        ; Case 1: It returned a tuple (Correct)
        (match &self (is-tuple $result) 
            (let ($specA $specB) $result
                (superpose (
                    (println! "\n; ================= HOUSE =================")
                    (println! $specA)
                    (println! "\n; ================= BOAT ==================")
                    (println! $specB)
                ))
            )
        )
        
        ; Case 2: It returned a list or just the atoms directly (Fallback)
        (println! "\n; === RAW RESULT (Fallback View) ===")
        (println! $result)
    ))
)