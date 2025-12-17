!(import! &self libs)
!(import! &self algspec_builder_tests)

; GPT-based Amalgam Builder
(=(amalgam_builder $concept1 $concept2)
        (let ($algspec1 $algspec2) (collapse (algspec_builder $concept1 $concept2))
            (let $generalized_algspec (collapse (gpt_generalization_helper $algspec1 $algspec2))
                (gpt_amalgam_builder $algspec1 $algspec2 $generalized_algspec) 
            )
        )
)

