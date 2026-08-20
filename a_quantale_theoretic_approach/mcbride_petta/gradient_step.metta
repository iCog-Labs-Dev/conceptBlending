;; =============================================================================
;; McBride Gradient Step — apply_gradient_step
;; =============================================================================
;; Implements the natural gradient update from Equation 53:
;;   deg^(t+1)(p,C) = deg^(t) + η · deg · (1-deg) · ∂^tv_p σ
;; =============================================================================

!(import! &self a_quantale_theoretic_approach/mcbride_petta/mcbride_deriv)

;; Natural-gradient TV update. Keep this native so the module works when it
;; is loaded directly by the `petta` CLI without Python atom registration.
(= (q-clamp-tv $degree)
   (if (< $degree 0.10)
       0.10
       (if (> $degree 0.99)
           0.99
           $degree)))

(= (q-natural-gradient-tv-step $current-deg $deriv-tv $eta)
   (q-clamp-tv
      (+ $current-deg
         (* $eta (* (* $current-deg (- 1.0 $current-deg)) $deriv-tv)))))

;; Update a single property: compute derivative and apply the TV step.
(= (q-update-property $prop-entry $source-a $source-b $blend $eta)
   (let* (($prop-name   (v-property-name $prop-entry))
          ($worlds      (v-property-worlds $prop-entry))
          ($current-deg (v-property-degree $prop-entry))
          ($deriv-tv    (q-mcbride-deriv-tv $prop-name $source-a $source-b $blend))
          ($new-deg     (q-natural-gradient-tv-step $current-deg $deriv-tv $eta)))
      ($prop-name (WorldSpecSet $worlds) $new-deg)))

;; Update all properties in a list
(= (q-update-props $props $source-a $source-b $blend $eta)
   (if (== $props ())
       ()
       (cons-atom
          (q-update-property (car-atom $props) $source-a $source-b $blend $eta)
          (q-update-props (cdr-atom $props) $source-a $source-b $blend $eta))))

;; Apply one full gradient step to the blend — returns updated concept
(= (q-gradient-step $blend $source-a $source-b $eta)
   (let* (($blend-name (v-concept-name $blend))
          ($props      (v-property-list $blend))
          ($updated-props (q-update-props $props $source-a $source-b $blend $eta)))
      (v-remake-concept $blend $blend-name $updated-props)))
