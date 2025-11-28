!(import! &self ../../PeTTa/lib/lib_prolog)
!(static-import! &space concept-atomspace/antonym_0_atlocation_0t_capableof_cs_causes_cs_causesdesire_ky_createdby)

!(import! &self common-utils)

!(import! &self integration)
!(import! &self metonymy)



(= (op-evaluater $blend $concept1 $concept2)
    (let*
        (
            ($integration-res (integration-op $blend))
            ($metonymy-res (metonymy-op $blend))
        )
        (
            Evaluating Integration OP:- $integration-res
            Evaluating Metonymy OP:- $metonymy-res
        )
    )
)



(= (blend) (Blend SpiderMan (Property (web-creation (Spider)) (intelligence) (physical-strength) (mobility) (predatory-behavior (Spider)) (social-structure) (symbolism) (tool-use)) (Relations (FormOf spiderman) (IsA human) (IsA superhero)))
)

(= (concept1) (Concept Man (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7)) (Relations (RelatedTo person) (RelatedTo man) (RelatedTo boy)))
)

(= (concept2) (Concept Spider (Property (web-creation 1.0) (intelligence 0.4) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1)) (Relations (CapableOf spin_webs) (RelatedTo spider) (IsA arachnid)))
)

!(op-evaluater (blend) (concept1) (concept2))

