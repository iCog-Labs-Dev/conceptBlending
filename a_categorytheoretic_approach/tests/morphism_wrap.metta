!(import! &self libs)
; Simple wrapper to call the AI for JSON mappings
(= (find_morphism $specG $specTarget)
   (llm:find-morph $specG $specTarget)
)