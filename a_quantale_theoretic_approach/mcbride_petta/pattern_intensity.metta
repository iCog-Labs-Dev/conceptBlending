;; =============================================================================
;; Pattern Intensity — I_A(C) and I_{A,B}(C)
;; =============================================================================
;; Implements Definitions 3.3 and 3.4 from Goertzel (2026):
;;   I_A(C) = w(A) ⇒ w(C)
;;   I_{A,B}(C) = (w(A) ⊗ w(B)) ⇒ w(C)
;; =============================================================================

!(import! &self a_quantale_theoretic_approach/mcbride_petta/weakness)

;; Pattern intensity: how much does blend C contain the pattern of source A?
(= (q-pattern-intensity $source $blend)
   (let* (($universe (v-world-universe $blend))
          ($w-source (q-weakness $source))
          ($w-blend  (q-weakness $blend)))
      (q-residuation $w-source $w-blend $universe)))

;; Joint pattern intensity: contribution from both sources
(= (q-joint-pattern-intensity $source-a $source-b $blend)
   (let* (($universe (v-world-universe $blend))
          ($w-a      (q-weakness $source-a))
          ($w-b      (q-weakness $source-b))
          ($w-both   (q-tensor $w-a $w-b))
          ($w-blend  (q-weakness $blend)))
      (q-residuation $w-both $w-blend $universe)))

;; Pattern intensity with TV-proportional valuation
(= (q-pattern-intensity-tv $source $blend)
   (let* (($universe (v-world-universe $blend))
          ($w-source (q-weakness-tv $source))
          ($w-blend  (q-weakness-tv $blend)))
      (q-residuation $w-source $w-blend $universe)))

(= (q-joint-pattern-intensity-tv $source-a $source-b $blend)
   (let* (($universe (v-world-universe $blend))
          ($w-a      (q-weakness-tv $source-a))
          ($w-b      (q-weakness-tv $source-b))
          ($w-both   (q-tensor $w-a $w-b))
          ($w-blend  (q-weakness-tv $blend)))
      (q-residuation $w-both $w-blend $universe)))

;; Versions with explicit valuation function
(= (q-pattern-intensity-with $source $blend $valuation-fn)
   (let* (($universe (v-world-universe $blend))
          ($w-source (q-weakness-with $source $valuation-fn))
          ($w-blend  (q-weakness-with $blend $valuation-fn)))
      (q-residuation $w-source $w-blend $universe)))

(= (q-joint-pattern-intensity-with $source-a $source-b $blend $valuation-fn)
   (let* (($universe (v-world-universe $blend))
          ($w-a      (q-weakness-with $source-a $valuation-fn))
          ($w-b      (q-weakness-with $source-b $valuation-fn))
          ($w-both   (q-tensor $w-a $w-b))
          ($w-blend  (q-weakness-with $blend $valuation-fn)))
      (q-residuation $w-both $w-blend $universe)))
