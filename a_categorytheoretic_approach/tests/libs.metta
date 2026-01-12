
!(import! &self extensions)

; 1. Define Standard Aliases
(= (algspec_builder $c1 $c2)      (llm:generate-spec $c1 $c2))
(= (generalization_builder $A $B) (llm:generate-gen $A $B))
(= (morphism_finder $G $T)        (llm:find-morph $G $T))
(= (pushout_computer $A $B $G $mA $mB) (math:colimit $A $B $G $mA $mB))