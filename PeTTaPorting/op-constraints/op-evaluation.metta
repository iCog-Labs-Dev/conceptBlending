!(import! &self ../../PeTTa/lib/lib_prolog)
!(static-import! &space concept-atomspace/antonym-0_-atlocation-0t-capableof-cs-causes-cs-causesdesire-ky-createdby-az-definedby-0b)
!(static-import! &space concept-atomspace/derivedfrom-ag)
!(static-import! &space concept-atomspace/derivedfrom-gp)
!(static-import! &space concept-atomspace/derivedfrom-pu)
!(static-import! &space concept-atomspace/derivedfrom-uy-distinctfrom-em-desires-pp-etymologicallyrelatedto-ad)
!(static-import! &space concept-atomspace/formof-bg)
!(static-import! &space concept-atomspace/formof-gi)
!(static-import! &space concept-atomspace/formof-ps)
!(static-import! &space concept-atomspace/formof-t_-hasa-1u-hascontext-aa)
!(static-import! &space concept-atomspace/hascontext-de)
!(static-import! &space concept-atomspace/hascontext-pp)
!(static-import! &space concept-atomspace/hasprerequisite-sw-hasproperty-as-hassubevent-bw-isa-ad)
!(static-import! &space concept-atomspace/isa-dp)
!(static-import! &space concept-atomspace/isa-py)
!(static-import! &space concept-atomspace/partof-ft-receivesaction-nz-relatedto-0a)
!(static-import! &space concept-atomspace/relatedto-ab)
!(static-import! &space concept-atomspace/relatedto-bb)
!(static-import! &space concept-atomspace/relatedto-cc)
!(static-import! &space concept-atomspace/relatedto-dd)
!(static-import! &space concept-atomspace/relatedto-ef)
!(static-import! &space concept-atomspace/relatedto-ff)
!(static-import! &space concept-atomspace/relatedto-hh)
!(static-import! &space concept-atomspace/relatedto-jk)
!(static-import! &space concept-atomspace/relatedto-mm)
!(static-import! &space concept-atomspace/relatedto-nn)
!(static-import! &space concept-atomspace/relatedto-pp)
!(static-import! &space concept-atomspace/relatedto-pp2)
!(static-import! &space concept-atomspace/relatedto-rr)
!(static-import! &space concept-atomspace/relatedto-ss)
!(static-import! &space concept-atomspace/relatedto-st)
!(static-import! &space concept-atomspace/relatedto-uu)
!(static-import! &space concept-atomspace/relatedto-wy)
!(static-import! &space concept-atomspace/synonym-de)
!(static-import! &space concept-atomspace/synonym-py-usedfor-br)
!(static-import! &space concept-atomspace/usedfor-rt-dbpedia-go)

!(static-import! &space concept-atomspace/additionals)

!(import! &self common-utils)

!(import! &self integration)
!(import! &self metonymy)
!(import! &self unpacking)
!(import! &self web)
!(import! &self topology)

(= (op-evaluater $blend $concept1 $concept2)
    (let*
        (
            ($integration-res (integration-op $blend))
            ($metonymy-res (metonymy-op $blend))
            ($unpacking-res (unpacking-op $blend))
            ($web-res (web-op (cross_mappings) $blend))
            ($topology-res (topology-op $blend $concept1 $concept2))
        )
        (
            Evaluating Integration OP:- $integration-res
            Evaluating Metonymy OP:- $metonymy-res
            Evaluating Unpacking OP:- $unpacking-res
            Evaluating Web OP:- $web-res
            Evaluating Topology OP:- $topology-res
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
