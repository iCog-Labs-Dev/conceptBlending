!(import! &self libs)
!(import! &self utils:extensions)

; Maps the generics space to the input space
(= (find-morphism $specG $specTarget)
   (llm:find-morph $specG $specTarget)
)