;; =============================================================================
;; McBride Derivative — ∂_p σ_{A,B}(C)
;; =============================================================================
;; Implements Equation 49 from Goertzel (2026):
;;   ∂_p σ_{A,B}(C) = (I_A(C) ⊗ I_B(C)) ⇒ ((w(A) ⊗ w(B)) ⇒ φ(p))
;; =============================================================================

!(import! &self a_quantale_theoretic_approach/mcbride_petta/emergence)

;; McBride derivative for a single property
(= (q-mcbride-deriv $prop-name $source-a $source-b $blend)
   (let* (($universe (v-world-universe $blend))
          ($ia       (q-pattern-intensity $source-a $blend))
          ($ib       (q-pattern-intensity $source-b $blend))
          ($ia-ib    (q-tensor $ia $ib))
          ($w-a      (q-weakness $source-a))
          ($w-b      (q-weakness $source-b))
          ($w-a-b    (q-tensor $w-a $w-b))
          ($phi-p    (q-phi-uniform $prop-name $universe))
          ($inner    (q-residuation $w-a-b $phi-p $universe)))
      (q-residuation $ia-ib $inner $universe)))

;; TV component of the derivative — the scalar gradient for the update step
(= (q-mcbride-deriv-tv $prop-name $source-a $source-b $blend)
   (q-degree (q-mcbride-deriv $prop-name $source-a $source-b $blend)))

;; Compute derivatives for all properties in the blend
(= (q-all-derivs $props $source-a $source-b $blend)
   (if (== $props ())
       ()
       (let* (($head (car-atom $props))
              ($tail (cdr-atom $props))
              ($prop-name (v-property-name $head))
              ($deriv (q-mcbride-deriv $prop-name $source-a $source-b $blend)))
          (cons-atom ($prop-name $deriv)
                     (q-all-derivs $tail $source-a $source-b $blend)))))

(= (q-mcbride-all-derivs $source-a $source-b $blend)
   (q-all-derivs (v-property-list $blend) $source-a $source-b $blend))
