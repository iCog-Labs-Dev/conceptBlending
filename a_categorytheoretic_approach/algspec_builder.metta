!(import! &self libs)
!(import! &self kb:knowledge_base)
!(import! &self extensions)

; Logic
(= (generate-specs $c1 $c2)
    (let $context1 (let $fetchedcont1 (main-fetch $c1) (cons-atom Context $fetchedcont1))
        (let $context2 (let $fetchedcont2 (main-fetch $c2) (cons-atom Context $fetchedcont2))
            (llm:generate-spec ($c1 $context1) ($c2 $context2))      
        )
    )
)

; EXECUTION
; !(println! ">>> STARTING GENERATION...")

; Calling the algspec_builder
; !(let $result (generate_specs house boat)
;     (println! "Generated Specification:" $result)
; )

; !(println! ">>> GENERATION FINISHED")