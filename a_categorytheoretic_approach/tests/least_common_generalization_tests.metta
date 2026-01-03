!(import! &self libs)
!(import! &self algspec_builder_tests)

; GPT-based Generalization Builder

(=(least_generalization_builder $concept1 $concept2)
    (let ($algspec1 $algspec2) (collapse (algspec_builder $concept1 $concept2))
        (gpt_generalization_helper $algspec1 $algspec2)
    )
)

; !(least_generalization_builder Bat Man)
