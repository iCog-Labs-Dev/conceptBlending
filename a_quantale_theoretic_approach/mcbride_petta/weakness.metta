;; =============================================================================
;; Quantale Weakness Function — w(C)
;; =============================================================================
;; Implements Definition 3.2 from Goertzel (2026):
;;   w(C) = ⊕_{p ∈ Props} φ(p) ⊗ mC(p)
;;
;; φ(p) is the valuation of property p — its prior importance.
;; Two valuations are provided:
;;   (q-phi-uniform $prop $universe)    — unit for all p (equal weight)
;;   (q-phi-tv-for-props $prop $props)  — use property's own TV as salience
;; =============================================================================

!(import! &self a_quantale_theoretic_approach/structural_reasoning/quantale_colimit_engine)

;; Uniform valuation: φ(p) = unit — all properties equally salient
(= (q-phi-uniform $prop $universe)
   (q-unit $universe))

;; TV-proportional valuation helper: φ(p) = mC(p) — concept's own TV is salience
(= (q-phi-tv-for-props $prop $properties)
   (let $entry (v-find-property $prop $properties)
      (if (== $entry ())
          (q-bottom)
          (v-property-quantale $entry))))

;; Single property weakness contribution with uniform valuation
(= (q-prop-weakness-contrib $prop-entry $universe $valuation-fn)
   (q-tensor ($valuation-fn (v-property-name $prop-entry) $universe)
             (v-property-quantale $prop-entry)))

;; Accumulate weakness over a list of properties using ⊕ (uniform valuation)
(= (q-weakness-accum $props $universe $valuation-fn)
   (if (== $props ())
       (q-bottom)
       (q-join
          (q-prop-weakness-contrib (car-atom $props) $universe $valuation-fn)
          (q-weakness-accum (cdr-atom $props) $universe $valuation-fn))))

;; Accumulate weakness over a list of properties using ⊕ (TV-proportional valuation)
(= (q-weakness-accum-tv $remaining $universe $all-props)
   (if (== $remaining ())
       (q-bottom)
       (let* (($head (car-atom $remaining))
              ($tail (cdr-atom $remaining))
              ($prop-name (v-property-name $head))
              ($phi (q-phi-tv-for-props $prop-name $all-props))
              ($contrib (q-tensor $phi (v-property-quantale $head))))
          (q-join $contrib (q-weakness-accum-tv $tail $universe $all-props)))))

;; Main weakness function — uniform valuation
(= (q-weakness $concept)
   (let* (($props    (v-property-list $concept))
          ($universe (v-world-universe $concept)))
      (q-weakness-accum $props $universe q-phi-uniform)))

;; Weakness function — TV-proportional valuation
(= (q-weakness-tv $concept)
   (let* (($props    (v-property-list $concept))
          ($universe (v-world-universe $concept)))
      (q-weakness-accum-tv $props $universe $props)))

;; Weakness with explicit valuation function
(= (q-weakness-with $concept $valuation-fn)
   (let* (($props    (v-property-list $concept))
          ($universe (v-world-universe $concept)))
      (q-weakness-accum $props $universe $valuation-fn)))
