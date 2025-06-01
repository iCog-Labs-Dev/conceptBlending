! (import! &self conceptual_blending)


;  ! (gpt_vital_relation house boat)

; [(VitalRelations "house" (Space Part-Whole Category Role Possession Material)), 
; (VitalRelations "boat" (Space Category Role Material Part-Whole)), 
; (Intersection (Space Category Role Part-Whole Material))]
; !(let* (($list (gpt_vital_relation house boat))
; ($intersect (extract-intersection $list))
;     )
;     $intersect
; )

(=(extract-intersection $list )
        (foldl-atom $list (empty) $acc $item
            (let ($head $tail) $item
              (if (== $head Intersection)
               ($tail)
                $acc
               )
            )
        )
)

;  !(extract-intersection 
;  ((Intersection (Space Role Part-Whole Category))))

!(let* (($input ((gpt_vital_relation house boat)))
        ;  (() (println! $input))
         ($intersected (extract-intersection $input))
          (() (println! $intersected))
)
 (println! $intersected)
 )

(= (is-member $item $list)
    (foldl-atom $list False $acc $element
        (or $acc (== $item $element))
    )
)

(=(temp ($prop $val) $vital-types)( if (is-member $prop $vital-types)
                 ($prop (* 1.5 $val))  ; boost important properties
                ($prop $val)
            ))

(= (apply-vital-weighting $mu-emergence $vital-types)(
    collapse (temp (superpose $mu-emergence) $vital-types)
))
            

; !(apply-vital-weighting
;     ((mobility 0.1) (category 0.2) (role 0.3) (possession 0.4) (color 0.5))
;     (mobility role possession)
; )

