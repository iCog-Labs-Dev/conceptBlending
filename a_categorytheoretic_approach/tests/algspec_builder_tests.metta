
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

; !(algspec_builder Bat Man)



!(algspec_builder "house" "boat")


; EXPORT SECTION FOR THE PIPELINE

!(let ($specA $specB) (algspec_builder "house" "boat")
    (superpose (
        ; Save "House" spec with a tag we can query later
        (add-atom &self (OutputSpec House $specA))
        
        ; Save "Boat" spec
        (add-atom &self (OutputSpec Boat $specB))
    ))
)

!(print " Specs for House and Boat saved to AtomSpace.")