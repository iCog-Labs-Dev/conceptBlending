
!(import! &self libs)
!(import! &self helper)

; GPT-based Algspec Builder

(=(algspec_builder $concept1 $concept2)
     (let ($context1 $context2) ((main-fetch $concept1) (main-fetch $concept2))
        (let ($generated_context) (collapse (gpt_context_preprocessing $concept1 $context1 $concept2 $context2))
           (gpt_algspec_builder $concept1 $concept2 $generated_context) 
           )
           )
)


