;; =============================================================================
;; Emergence (Synergy) — σ_{A,B}(C)
;; =============================================================================
;; Implements Definition 3.5 / Equation 18 from Goertzel (2026):
;;   σ_{A,B}(C) = (I_A(C) ⊗ I_B(C)) ⇒ I_{A,B}(C)
;;
;; σ ≥ e (unit) iff the blend is genuinely synergistic.
;; =============================================================================

!(import! &self a_quantale_theoretic_approach/mcbride_petta/pattern_intensity)

;; Emergence with uniform valuation (default)
(= (q-emergence $source-a $source-b $blend)
   (let* (($universe (v-world-universe $blend))
          ($ia   (q-pattern-intensity $source-a $blend))
          ($ib   (q-pattern-intensity $source-b $blend))
          ($iab  (q-joint-pattern-intensity $source-a $source-b $blend))
          ($ia-ib (q-tensor $ia $ib)))
      (q-residuation $ia-ib $iab $universe)))

;; Emergence with TV-proportional valuation
(= (q-emergence-tv-valuation $source-a $source-b $blend)
   (let* (($universe (v-world-universe $blend))
          ($ia   (q-pattern-intensity-tv $source-a $blend))
          ($ib   (q-pattern-intensity-tv $source-b $blend))
          ($iab  (q-joint-pattern-intensity-tv $source-a $source-b $blend))
          ($ia-ib (q-tensor $ia $ib)))
      (q-residuation $ia-ib $iab $universe)))

;; Emergence with explicit valuation function
(= (q-emergence-with $source-a $source-b $blend $valuation-fn)
   (let* (($universe (v-world-universe $blend))
          ($ia   (q-pattern-intensity-with $source-a $blend $valuation-fn))
          ($ib   (q-pattern-intensity-with $source-b $blend $valuation-fn))
          ($iab  (q-joint-pattern-intensity-with $source-a $source-b $blend $valuation-fn))
          ($ia-ib (q-tensor $ia $ib)))
      (q-residuation $ia-ib $iab $universe)))

;; Extract just the TV (degree) component of emergence
(= (q-emergence-tv $source-a $source-b $blend)
   (q-degree (q-emergence $source-a $source-b $blend)))

;; Check emergence criterion: σ ≥ e (Proposition 3.6)
(= (q-has-emergence $source-a $source-b $blend)
   (>= (q-emergence-tv $source-a $source-b $blend) 1.0))
