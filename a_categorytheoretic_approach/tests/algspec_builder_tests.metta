
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

!(algspec_builder "house" "boat")

;; EXPORT SECTION FOR THE PIPELINE
;
;!(print ">>> Generating Algebraic Specs (Calling LLM)...")
;
;; 1. Force evaluation of the builder
;!(let $result (eval (algspec_builder "house" "boat"))
;    
;    ; 2. Check if we got a valid tuple ($A $B)
;    (let ($specA $specB) $result
;        (superpose (
;            ; Save House Spec
;            (add-atom &self (OutputSpec House $specA))
;            (println! (format-args "Saved House Spec: {} chars" ((len-atom $specA))))
;            
;            ; Save Boat Spec
;            (add-atom &self (OutputSpec Boat $specB))
;            (println! (format-args "Saved Boat Spec: {} chars" ((len-atom $specB))))
;        ))
;    )
;)
;
;!(print "Specs for House and Boat saved to AtomSpace.")