!(import! &self ../../PeTTa/lib/lib_import)
!(let $temp (static-import! &space concept-atomspace/antonym-0_-atlocation-0t-capableof-cs-causes-cs-causesdesire-ky-createdby-az-definedby-0b) (empty))
!(let $temp (static-import! &space concept-atomspace/derivedfrom-ag) (empty))
!(let $temp (static-import! &space concept-atomspace/derivedfrom-gp) (empty))
!(let $temp (static-import! &space concept-atomspace/derivedfrom-pu) (empty))
!(let $temp (static-import! &space concept-atomspace/derivedfrom-uy-distinctfrom-em-desires-pp-etymologicallyrelatedto-ad) (empty))
!(let $temp (static-import! &space concept-atomspace/formof-bg) (empty))
!(let $temp (static-import! &space concept-atomspace/formof-gi) (empty))
!(let $temp (static-import! &space concept-atomspace/formof-ps) (empty))
!(let $temp (static-import! &space concept-atomspace/formof-t_-hasa-1u-hascontext-aa) (empty))
!(let $temp (static-import! &space concept-atomspace/hascontext-de) (empty))
!(let $temp (static-import! &space concept-atomspace/hascontext-pp) (empty))
!(let $temp (static-import! &space concept-atomspace/hasprerequisite-sw-hasproperty-as-hassubevent-bw-isa-ad) (empty))
!(let $temp (static-import! &space concept-atomspace/isa-dp) (empty))
!(let $temp (static-import! &space concept-atomspace/isa-py) (empty))
!(let $temp (static-import! &space concept-atomspace/partof-ft-receivesaction-nz-relatedto-0a) (empty))
!(let $temp (static-import! &space concept-atomspace/relatedto-ab) (empty))
!(let $temp (static-import! &space concept-atomspace/relatedto-bb) (empty))
!(let $temp (static-import! &space concept-atomspace/relatedto-cc) (empty))
!(let $temp (static-import! &space concept-atomspace/relatedto-dd) (empty))
!(let $temp (static-import! &space concept-atomspace/relatedto-ef) (empty))
!(let $temp (static-import! &space concept-atomspace/relatedto-ff) (empty))
!(let $temp (static-import! &space concept-atomspace/relatedto-hh) (empty))
!(let $temp (static-import! &space concept-atomspace/relatedto-jk) (empty))
!(let $temp (static-import! &space concept-atomspace/relatedto-mm) (empty))
!(let $temp (static-import! &space concept-atomspace/relatedto-nn) (empty))
!(let $temp (static-import! &space concept-atomspace/relatedto-pp) (empty))
!(let $temp (static-import! &space concept-atomspace/relatedto-pp2) (empty))
!(let $temp (static-import! &space concept-atomspace/relatedto-rr) (empty))
!(let $temp (static-import! &space concept-atomspace/relatedto-ss) (empty))
!(let $temp (static-import! &space concept-atomspace/relatedto-st) (empty))
!(let $temp (static-import! &space concept-atomspace/relatedto-uu) (empty))
!(let $temp (static-import! &space concept-atomspace/relatedto-wy) (empty))
!(let $temp (static-import! &space concept-atomspace/synonym-de) (empty))
!(let $temp (static-import! &space concept-atomspace/synonym-py-usedfor-br) (empty))
!(let $temp (static-import! &space concept-atomspace/usedfor-rt-dbpedia-go) (empty))

!(let $temp (static-import! &space concept-atomspace/additionals) (empty))

!(import! &self "op-helper-codes.py")

!(import! &self common-utils)

!(import! &self integration)
!(import! &self metonymy)
!(import! &self unpacking)
!(import! &self web)
!(import! &self topology)
!(import! &self good-reason)

(= (op-evaluater $blend $concept1 $concept2)
    (let*
        (
            ($integration-res (integration-op $blend))
            ($metonymy-res (metonymy-op $blend))
            ($unpacking-res (unpacking-op $blend))
            ($web-res (web-op (cross_mappings) $blend))
            ($topology-res (topology-op $blend $concept1 $concept2))
            ($good-reason-res (good-reason-op $blend))
        )
        (
            Evaluating Integration OP:- $integration-res
            Evaluating Metonymy OP:- $metonymy-res
            Evaluating Unpacking OP:- $unpacking-res
            Evaluating Web OP:- $web-res
            Evaluating Topology OP:- $topology-res
            Evaluating Good-Reason OP:- $good-reason-res
        )
    )
)

(= (blend) (Blend spiderMan (Property (web_creation (spider)) (intelligence) (physical_strength) (mobility) (predatory_behavior (spider)) (social_structure) (symbolism) (tool_use)) (Relations (formOf spiderman) (isA human) (isA superhero)))
)

(= (concept1) (Concept man (Property (mobility 0.9) (intelligence 0.9) (web_creation 0.0) (social_structure 0.8) (predatory_behavior 0.2) (communication 0.9) (symbolism 0.7) (physical_strength 0.7)) (Relations (relatedTo person) (relatedTo man) (relatedTo boy)))
)

(= (concept2) (Concept spider (Property (web_creation 1.0) (intelligence 0.4) (physical_strength 0.6) (mobility 0.8) (predatory_behavior 1.0) (social_structure 0.2) (symbolism 0.7) (communication 0.1)) (Relations (capableOf spin_webs) (relatedTo spider) (isA arachnid)))
)

!(op-evaluater (blend) (concept1) (concept2))
