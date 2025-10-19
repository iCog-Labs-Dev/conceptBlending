
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




; ;;;; Concept-Atomspace ;;;;

;;;; Test if the concept atomspace can be fully loaded and relations and concepts tied with concept **abandon** can be retrieved
; Output = all relations and concepts tied with concept **abandon**

(assertEqual
    (collapse(match &self ($r abandon $t) ($r $t)))
    ((Antonym acquire) (Antonym arrogate) (Antonym embrace) (Antonym engage) (Antonym gain) (Antonym join) (Antonym maintain) (Antonym retain) (Antonym unite) (EtymologicallyRelatedTo ban) (EtymologicallyRelatedTo banal) (EtymologicallyRelatedTo forleave) (EtymologicallyRelatedTo forlet) (IsA unrestraint) (RelatedTo abandonment) (RelatedTo abandonment) (RelatedTo artificial) (RelatedTo constraint) (RelatedTo freedom) (RelatedTo impulses) (RelatedTo inhibitions) (RelatedTo relinquishment) (RelatedTo abandonware) (RelatedTo adhere) (RelatedTo banish) (RelatedTo cast_out) (RelatedTo desert) (RelatedTo desist) (RelatedTo discontinue) (RelatedTo exercise) (RelatedTo expel) (RelatedTo follow) (RelatedTo forsake) (RelatedTo give_up) (RelatedTo insurer) (RelatedTo interest) (RelatedTo lapse) (RelatedTo reject) (RelatedTo relinquish) (RelatedTo renounce) (RelatedTo right) (RelatedTo subdue) (RelatedTo surrender) (RelatedTo take_control) (RelatedTo title) (RelatedTo total_loss) (RelatedTo yield))
)

;;;; Test if all the properties of the triplet ** (Antonym abandon acquire))** can be retrieved
; Output = all properties of the triplet ** (Antonym abandon acquire))** with their values

(assertEqual
    (collapse(match &self ($p (Antonym accept refuse) $v) ($p $v)))
    ((source accept) (surfaceText accept_is_the_opposite_of_refuse) (dataset 'dataset':_'/d/verbosity'_'license':_'cc:by/4.0'_'sources':_[{'contributor':_'/s/resource/verbosity'}]_'surfaceEnd':_'refuse'_'surfaceStart':_'accept') (weight 0.329) (relation Antonym) (target refuse))
)


;;;; Test if the compsoite query **(match &self (,  (Antonym abandon $t))  (Antonym $t $t2))) (Antonym $t $t2))** works on the atomspace
; Output = Triplets with relation **Antonym** of all the target concepts of concept abandon


!(assertEqual
    (collapse(match &self (, (Antonym abandon $t) (Antonym $t $t2)) (Antonym $t $t2)))
    ((Antonym acquire abandon) (Antonym arrogate abandon) (Antonym arrogate abdicate) (Antonym arrogate relinquish) (Antonym arrogate renounce) (Antonym engage disengage) (Antonym gain loosing) (Antonym gain lose) (Antonym gain lose_weight) (Antonym gain loss) (Antonym gain loss) (Antonym gain lost) (Antonym gain reduce) (Antonym gain waste) (Antonym gain weight) (Antonym join apart) (Antonym join leave) (Antonym join opt) (Antonym join opt_out) (Antonym join out) (Antonym join part) (Antonym join quit) (Antonym join separate) (Antonym join split) (Antonym join split_apart) (Antonym join meet) (Antonym maintain abandon) (Antonym unite divide))
)

