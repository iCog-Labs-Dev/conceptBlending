! (import! &self libs)
; ! (import! &self common-utils)
!(load-ascii &self data/kb_concepts.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/antonym-0_-atlocation-0t-capableof-cs-causes-cs-causesdesire-ky-createdby-az-definedby-0b.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/derivedfrom-ag.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/derivedfrom-gp.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/derivedfrom-pu.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/derivedfrom-uy-distinctfrom-em-desires-pp-etymologicallyrelatedto-ad.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/formof-bg.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/formof-gi.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/formof-ps.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/formof-t_-hasa-1u-hascontext-aa.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/hascontext-de.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/hascontext-pp.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/hasprerequisite-sw-hasproperty-as-hassubevent-bw-isa-ad.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/isa-dp.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/isa-py.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/partof-ft-receivesaction-nz-relatedto-0a.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/relatedto-ab.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/relatedto-bb.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/relatedto-cc.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/relatedto-dd.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/relatedto-ef.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/relatedto-ff.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/relatedto-hh.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/relatedto-jk.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/relatedto-mm.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/relatedto-nn.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/relatedto-pp.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/relatedto-pp2.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/relatedto-rr.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/relatedto-ss.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/relatedto-st.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/relatedto-uu.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/relatedto-wy.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/synonym-de.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/synonym-py-usedfor-br.metta)
 !(load-ascii &self an_infotheoretic_approach/concept-atomspace/usedfor-rt-dbpedia-go.metta)


(= (are-conflicting $item $item2 $terms-antonymity $pre-def-confl)
    (if (or (== ($item $item2) $pre-def-confl) (or (== ($item2 $item) $pre-def-confl) $terms-antonymity))
        1
        0
    )
)

(= (check-i-j-conflict $prop-name-i $prop-name-j $props-antonymity $pre-def-confl)
    (min-atom ((sum (map-atom $pre-def-confl $x (are-conflicting $prop-name-i $prop-name-j $props-antonymity $x))) 1))
)

(=(are-terms-antonyms $term1 $term2)
    (let* (
        ($m (collapse (match &self (Triplet (Antonym $term1 $term2)) $term1)))
        ($n (if (> (size-atom $m) 0) True False))
    )
    $n
)
)

(= (check-props-conflict $props $predefined-conflicts)
    (function 
        (chain (decons-atom $props) $ht
            (unify ($head $tail) $ht
                (chain (eval (map-atom $tail $x (check-i-j-conflict $head $x (are-terms-antonyms $head $x) $predefined-conflicts))) $map-res
                    (chain (sum $map-res) $res
                            (chain (eval (check-props-conflict $tail $predefined-conflicts)) $tail-res
                                (chain (+ $res $tail-res) $result (return $result))
                            )
                        )
                    )
                (return 0)
            )
        )
    )
)



(= (integration-op $blend)
    (let $prop-list (properties-list $blend)
        (let $prop-names (map-atom $prop-list $x (car-atom $x))
            (let $conflicts (check-props-conflict $prop-names (predefined-conflicts))
                (let $conflict-ratio (/ $conflicts (pow-math (size-atom $prop-names) 0.5)) (max-atom (0.0 (- 1.0 $conflict-ratio))))
            )
        )
    )
)

; ! (integration-op cat)
