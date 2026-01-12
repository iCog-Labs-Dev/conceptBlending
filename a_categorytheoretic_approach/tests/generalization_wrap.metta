!(import! &self libs)
!(import! &self knowledge_base)

; 1. DEFINE BUILDER
(= (algspec_builder $concept1 $concept2)
   (let $context1 (main-fetch $concept1)
      (let $context2 (main-fetch $concept2)
         (let $clean_context (format-args "Context for {}: {}. Context for {}: {}." ($concept1 $context1 $concept2 $context2))
             (collapse (gpt_algspec_builder ($concept1 $clean_context) ($concept2 $clean_context)))
         )
      )
   )
)

; 2. DEFINE GENERALIZER
(= (generalization_builder $specA $specB)
   (gpt_generalization_helper $specA $specB)
)