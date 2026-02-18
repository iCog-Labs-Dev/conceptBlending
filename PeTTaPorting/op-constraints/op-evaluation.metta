!(import! &self ../../PeTTa/lib/lib_import)
!(let $temp (static-import! &space op-constraints/concept-atomspace/antonym-0_-atlocation-0t-capableof-cs-causes-cs-causesdesire-ky-createdby-az-definedby-0b) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/derivedfrom-ag) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/derivedfrom-gp) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/derivedfrom-pu) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/derivedfrom-uy-distinctfrom-em-desires-pp-etymologicallyrelatedto-ad) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/formof-bg) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/formof-gi) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/formof-ps) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/formof-t_-hasa-1u-hascontext-aa) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/hascontext-de) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/hascontext-pp) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/hasprerequisite-sw-hasproperty-as-hassubevent-bw-isa-ad) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/isa-dp) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/isa-py) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/partof-ft-receivesaction-nz-relatedto-0a) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/relatedto-ab) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/relatedto-bb) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/relatedto-cc) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/relatedto-dd) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/relatedto-ef) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/relatedto-ff) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/relatedto-hh) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/relatedto-jk) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/relatedto-mm) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/relatedto-nn) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/relatedto-pp) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/relatedto-pp2) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/relatedto-rr) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/relatedto-ss) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/relatedto-st) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/relatedto-uu) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/relatedto-wy) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/synonym-de) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/synonym-py-usedfor-br) (empty))
!(let $temp (static-import! &space op-constraints/concept-atomspace/usedfor-rt-dbpedia-go) (empty))

; ; !(let $temp (static-import! &space concept-atomspace/additionals) (empty))

!(import! &self "op-constraints/op-helper-codes.py")

!(import! &self op-constraints/common-utils)

!(import! &self op-constraints/integration)
!(import! &self op-constraints/metonymy)
!(import! &self op-constraints/unpacking)
!(import! &self op-constraints/web)
!(import! &self op-constraints/topology)
!(import! &self op-constraints/good-reason)


(= (op-evaluater $blend $concept1 $concept2)
    (let*
        (
            ($_ (println! (Calc Integration-op value)))
            ($integration-res (integration-op $blend))
            ($_ (println! (Integration-op Value: $integration-res)))
            ($_ (println! (Calc Metonymy-op Value)))
            ($metonymy-res (metonymy-op $blend))
            ($_ (println! (Metonymy-op Value: $metonymy-res)))
            ($_ (println! (Calc Unpacking-op Value)))
            ($unpacking-res (unpacking-op $blend))
            ($_ (println! (Unpacking Value: $unpacking-res)))
            ($_ (println! (Calc Web-op Value)))
            ($web-res (web-op (cross_mappings) $blend))
            ($_ (println! (Web-op Value: $web-res)))
            ($_ (println! (Calc Topology-op Value)))
            ($topology-res (topology-op $blend $concept1 $concept2))
            ($_ (println! (Toplogy-op Value: $topology-res)))
            ($_ (println! (Calc Good-reason Value)))
            ($good-reason-res (good-reason-op $blend))
            ($_ (println! (Good-reason Value: $good-reason-res)))
        )
        (
            $integration-res
            $metonymy-res
            $unpacking-res
            $web-res
            $topology-res
            $good-reason-res
        )
    )
)

; !(py-call (op-helper-codes.get_word_associations bat))

; (= (blend) (Blend spiderMan (Property (web_creation (spider)) (intelligence) (physical_strength) (mobility) (predatory_behavior (spider)) (social_structure) (symbolism) (tool_use)) (Relations (formOf spiderman) (isA human) (isA superhero)))
; )

; (= (concept1) (Concept man (Property (mobility 0.9) (intelligence 0.9) (web_creation 0.0) (social_structure 0.8) (predatory_behavior 0.2) (communication 0.9) (symbolism 0.7) (physical_strength 0.7)) (Relations (relatedTo person) (relatedTo man) (relatedTo boy)))
; )

; (= (concept2) (Concept spider (Property (web_creation 1.0) (intelligence 0.4) (physical_strength 0.6) (mobility 0.8) (predatory_behavior 1.0) (social_structure 0.2) (symbolism 0.7) (communication 0.1)) (Relations (capableOf spin_webs) (relatedTo spider) (isA arachnid)))
; )

; !(op-evaluater (blend) (concept1) (concept2))
