! (import! &self libs)
; ! (import! &self common-utils)
!(bind! &concept-space (new-space))
!(load-ascii &concept-space data/kb_concepts.metta)

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


(= (relation-exists-in-blend $blend-relations $rel-pair)
    (is-list-member $rel-pair $blend-relations)
)

(= (check-relations-loop $rels $a-type $a-target $b-type $b-target $threshold)
  (if (== (size-atom $rels) 0)
      False
      (let* (
          ($head (car-atom $rels))
          ($tail (cdr-atom $rels))
      )
        (if (< (size-atom $head) 2)
            (check-relations-loop $tail $a-type $a-target $b-type $b-target $threshold)
            (let* (
                ($rel-type (car-atom $head))
                ($rel-target (index-atom $head 1))
                ($a-type-similarity (get-similarity-score $rel-type $a-type))
                ($a-target-similarity (get-similarity-score $rel-target $a-target))
                ($b-type-similarity (get-similarity-score $rel-type $b-type))
                ($b-target-similarity (get-similarity-score $rel-target $b-target))
                ($match-a (and (> $a-type-similarity $threshold)
                               (> $a-target-similarity $threshold)))
                ($match-b (and (> $b-type-similarity $threshold)
                               (> $b-target-similarity $threshold)))
            )
              (if (and $match-a $match-b)
                True
                (check-relations-loop $tail $a-type $a-target $b-type $b-target $threshold))
            )
        )
      )
  )
)

(= (semantic-threshold) 0.1)

(= (score-cross-mapping $blend-relations $a-kv-inner $b-kv-inner)
   (let* (
        ($a-exists (relation-exists-in-blend $blend-relations $a-kv-inner))
        ($b-exists (relation-exists-in-blend $blend-relations $b-kv-inner))
        ($a-type (car-atom $a-kv-inner))
        ($a-target (index-atom $a-kv-inner 1))
        ($b-type (car-atom $b-kv-inner))
        ($b-target (index-atom $b-kv-inner 1))
        ($threshold (semantic-threshold))
   )
     (
        if (and $a-exists $b-exists)
         1.0
         (
            if (check-relations-loop $blend-relations $a-type $a-target $b-type $b-target $threshold)
                0.8
                0.0
        )
     )
   )
)

(= (calc-score-cross-mapping $mapping $blend-relations)
  (let ($a $b) (concept-relation-mapping $mapping)
    (let ($a-kv $b-kv) ((cdr-atom $a) (cdr-atom $b))
      (let $score (score-cross-mapping $blend-relations (car-atom $a-kv) (car-atom $b-kv)) $score)
    )
  )
)




(= (web-op $cross-mappings $blend)
  (let* 
    (
        ($blend-relations (relations-key-value-list $blend))
        ($scores (map-atom $cross-mappings $mapping (calc-score-cross-mapping $mapping $blend-relations)))
        ($sum (sum-op $scores))
        ($count (size-atom $scores))
        ($average (/ $sum $count))
        ($result (min-atom (1.0 $average)))
    )
    $result
  )
)

; ! (web-op (cross_mappings) (good_blend))