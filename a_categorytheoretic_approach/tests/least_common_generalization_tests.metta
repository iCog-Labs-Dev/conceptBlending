!(import! &self libs)
!(import! &self algspec_builder_tests)

; GPT-based Generalization Builder

(=(least_generalization_builder $concept1 $concept2)
     (let ($context1 $context2) ((main-fetch $concept1) (main-fetch $concept2))
        (let ($generated_context) (collapse (gpt_context_preprocessing ($concept1 $context1) ($concept2 $context2)))
            (let ($algspec1 $algspec2) (collapse (gpt_algspec_builder ($concept1 $generated_context) ($concept2 $generated_context)))
           (gpt_generalization_helper ($concept1 $algspec1) ($concept2 $algspec2)))
)
))

!(least_generalization_builder "house" "boat")


;; EXPORT TO PYTHON PIPELINE
;
;!(let $genSpec (least_generalization_builder "house" "boat")
;    ; Save the generalization with the tag 'Generic'
;    (add-atom &self (OutputSpec Generic $genSpec))
;)
;
;!(print "Generic Spec saved to AtomSpace.")