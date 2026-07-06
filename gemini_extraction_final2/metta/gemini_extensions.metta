; =======================================================
; gemini_extraction/metta/gemini_extensions.metta
;
; Registers the unified V-Quantale pipeline as one MeTTa atom.
;
; Usage: !(import! &self gemini_extraction:python:gemini_atoms)
;        !(gemini:vq-blend house boat)
;
; This runs the full InfoTheoretic + Categoric + Quantale pipeline
; and returns one CASL V-predicate result atom.
; =======================================================

!(import! &self gemini_extraction:python:gemini_atoms)

; Full unified pipeline — one call, one output
(= (gemini:blend $c1 $c2)
   (gemini:vq-blend $c1 $c2)
)

; Example:
; !(gemini:blend house boat)
; !(gemini:blend "Solar Energy" "Water Purification")
