!(import! &self libs)

  !(load-ascii &self concept-atomspace/antonym-0_-atlocation-0t-capableof-cs-causes-cs-causesdesire-ky-createdby-az-definedby-0b.metta)
  !(load-ascii &self concept-atomspace/derivedfrom-ag.metta)
  !(load-ascii &self concept-atomspace/derivedfrom-gp.metta)
  !(load-ascii &self concept-atomspace/derivedfrom-pu.metta)
  !(load-ascii &self concept-atomspace/derivedfrom-uy-distinctfrom-em-desires-pp-etymologicallyrelatedto-ad.metta)
  !(load-ascii &self concept-atomspace/formof-bg.metta)
  !(load-ascii &self concept-atomspace/formof-gi.metta)
  !(load-ascii &self concept-atomspace/formof-ps.metta)
  !(load-ascii &self concept-atomspace/formof-t_-hasa-1u-hascontext-aa.metta)
  !(load-ascii &self concept-atomspace/hascontext-de.metta)
  !(load-ascii &self concept-atomspace/hascontext-pp.metta)
  !(load-ascii &self concept-atomspace/hasprerequisite-sw-hasproperty-as-hassubevent-bw-isa-ad.metta)
  !(load-ascii &self concept-atomspace/isa-dp.metta)
  !(load-ascii &self concept-atomspace/isa-py.metta)
  !(load-ascii &self concept-atomspace/partof-ft-receivesaction-nz-relatedto-0a.metta)
  !(load-ascii &self concept-atomspace/relatedto-ab.metta)
  !(load-ascii &self concept-atomspace/relatedto-bb.metta)
  !(load-ascii &self concept-atomspace/relatedto-cc.metta)
  !(load-ascii &self concept-atomspace/relatedto-dd.metta)
  !(load-ascii &self concept-atomspace/relatedto-ef.metta)
  !(load-ascii &self concept-atomspace/relatedto-ff.metta)
  !(load-ascii &self concept-atomspace/relatedto-hh.metta)
  !(load-ascii &self concept-atomspace/relatedto-jk.metta)
  !(load-ascii &self concept-atomspace/relatedto-mm.metta)
  !(load-ascii &self concept-atomspace/relatedto-nn.metta)
  !(load-ascii &self concept-atomspace/relatedto-pp.metta)
  !(load-ascii &self concept-atomspace/relatedto-pp2.metta)
  !(load-ascii &self concept-atomspace/relatedto-rr.metta)
  !(load-ascii &self concept-atomspace/relatedto-ss.metta)
  !(load-ascii &self concept-atomspace/relatedto-st.metta)
  !(load-ascii &self concept-atomspace/relatedto-uu.metta)
  !(load-ascii &self concept-atomspace/relatedto-wy.metta)
  !(load-ascii &self concept-atomspace/synonym-de.metta)
  !(load-ascii &self concept-atomspace/synonym-py-usedfor-br.metta)
  !(load-ascii &self concept-atomspace/usedfor-rt-dbpedia-go.metta)

; Helper to reorder triplet
(= (reorder-triplet $triplet)
   (let ($rel $concept $target) $triplet
      ($concept $rel $target)
   )
)

; Fetch IsA atoms for a concept
(=(fetch-atom-IsA $concept)
  (let $pairs (match &self (surfaceText (IsA $concept $target) $text)
               (if (== NA $text)
                   (reorder-triplet (IsA $concept $target))
                   ($target $text)
               )
             )
   (if (== $pairs ()) $concept $pairs)
  )
)

; Fetch RelatedTo atoms for a concept
(=(fetch-atom-RelatedTo $concept)
  (let $pairs 
                (match &self (surfaceText (RelatedTo $concept $target) $text)
                       (if (== NA $text)
                           (reorder-triplet (RelatedTo $concept $target))
                           ($target $concept)))
    (if (== $pairs ()) $concept $pairs)))

; Fetch HasProperty atoms for a concept
(=(fetch-atom-HasProperty $concept)
  (let $pairs 
                (match &self (surfaceText (HasProperty $concept $target) $text)
              
                       (if (== NA $text)
                           (reorder-triplet (HasProperty $concept $target))
                           ($target $text)))
    (if (== $pairs ()) $concept $pairs)))


; Main fetch function to get all relevant atoms for a concept
(=(main-fetch $concept)
     (collapse (unique((superpose ((fetch-atom-RelatedTo $concept) (fetch-atom-HasProperty $concept) (fetch-atom-IsA $concept))
     ))))
     
)

; GPT-based Algspec Builder

(=(least_generalization_builder $concept1 $concept2)
     (let ($context1 $context2) ((main-fetch $concept1) (main-fetch $concept2))
        (let ($generated_context) (collapse (gpt_context_preprocessing ($concept1 $context1) ($concept2 $context2)))
            (let ($algspec1 $algspec2) (collapse (gpt_algspec_builder ($concept1 $generated_context) ($concept2 $generated_context)))
           (gpt_generalization_helper ($concept1 $algspec1) ($concept2 $algspec2)))
)
))

!(least_generalization_builder "house" "boat")

; EXPORT TO PYTHON PIPELINE

!(let $genSpec (least_generalization_builder "house" "boat")
    ; Save the generalization with the tag 'Generic'
    (add-atom &self (OutputSpec Generic $genSpec))
)

!(print "Generic Spec saved to AtomSpace.")