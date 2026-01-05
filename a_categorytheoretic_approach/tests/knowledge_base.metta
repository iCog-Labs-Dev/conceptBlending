; SHARED KNOWLEDGE BASE
; This file loads the data and defines the fetch functions ONCE.

!(import! &self libs)

; ============================================================
; 1. LOAD DATA
; ============================================================
; !(load-ascii &self concept-atomspace/antonym-0_-atlocation-0t-capableof-cs-causes-cs-causesdesire-ky-createdby-az-definedby-0b.metta)
; !(load-ascii &self concept-atomspace/derivedfrom-ag.metta)
; !(load-ascii &self concept-atomspace/derivedfrom-gp.metta)
; !(load-ascii &self concept-atomspace/derivedfrom-pu.metta)
; !(load-ascii &self concept-atomspace/derivedfrom-uy-distinctfrom-em-desires-pp-etymologicallyrelatedto-ad.metta)
; !(load-ascii &self concept-atomspace/formof-bg.metta)
; !(load-ascii &self concept-atomspace/formof-gi.metta)
; !(load-ascii &self concept-atomspace/formof-ps.metta)
; !(load-ascii &self concept-atomspace/formof-t_-hasa-1u-hascontext-aa.metta)
; !(load-ascii &self concept-atomspace/hascontext-de.metta)
; !(load-ascii &self concept-atomspace/hascontext-pp.metta)
; !(load-ascii &self concept-atomspace/hasprerequisite-sw-hasproperty-as-hassubevent-bw-isa-ad.metta)
; !(load-ascii &self concept-atomspace/isa-dp.metta)
; !(load-ascii &self concept-atomspace/isa-py.metta)
; !(load-ascii &self concept-atomspace/partof-ft-receivesaction-nz-relatedto-0a.metta)
; !(load-ascii &self concept-atomspace/relatedto-ab.metta)
; !(load-ascii &self concept-atomspace/relatedto-bb.metta)
; !(load-ascii &self concept-atomspace/relatedto-cc.metta)
; !(load-ascii &self concept-atomspace/relatedto-dd.metta)
; !(load-ascii &self concept-atomspace/relatedto-ef.metta)
; !(load-ascii &self concept-atomspace/relatedto-ff.metta)
; !(load-ascii &self concept-atomspace/relatedto-hh.metta)
; !(load-ascii &self concept-atomspace/relatedto-jk.metta)
; !(load-ascii &self concept-atomspace/relatedto-mm.metta)
; !(load-ascii &self concept-atomspace/relatedto-nn.metta)
; !(load-ascii &self concept-atomspace/relatedto-pp.metta)
; !(load-ascii &self concept-atomspace/relatedto-pp2.metta)
; !(load-ascii &self concept-atomspace/relatedto-rr.metta)
; !(load-ascii &self concept-atomspace/relatedto-ss.metta)
; !(load-ascii &self concept-atomspace/relatedto-st.metta)
; !(load-ascii &self concept-atomspace/relatedto-uu.metta)
; !(load-ascii &self concept-atomspace/relatedto-wy.metta)
; !(load-ascii &self concept-atomspace/synonym-de.metta)
; !(load-ascii &self concept-atomspace/synonym-py-usedfor-br.metta)
; !(load-ascii &self concept-atomspace/usedfor-rt-dbpedia-go.metta)

!(import! &self small_kb)

; ============================================================
; 2. DEFINE HELPER FUNCTIONS
; ============================================================

(= (format-result $target $text)
   (if (== $text NA)
       ($target "NA")
       ($target $text)
   )
)

; Fetch IsA atoms 
(= (fetch-atom-IsA $c)
   (match &self 
       (surfaceText (Triplet (IsA $c $target)) $text)
       (format-result $target $text)
   )
)

;Fetch Is-RelatedTo atoms
(= (fetch-atom-RelatedTo $c)
   (match &self 
       (surfaceText (Triplet (RelatedTo $c $target)) $text)
       (format-result $target $text)
   )
)

; Fetch HasProperty atoms 
(= (fetch-atom-HasProperty $c)
   (match &self 
       (surfaceText (Triplet (HasProperty $c $target)) $text)
       (format-result $target $text)
   )
)

; Main fetch function 
(= (main-fetch $c)
   (collapse 
       (unique 
           (superpose (
               (fetch-atom-RelatedTo $c) 
               (fetch-atom-HasProperty $c) 
               (fetch-atom-IsA $c)
           ))
       )
   )
)

!(println! "--- TESTING HOUSE FETCH ---")
!(main-fetch house)

