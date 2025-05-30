! (import! &self conceptual_blending)


;! (gpt_vital_relation house boat)

; [(VitalRelations "house" (Space Part-Whole Category Role Possession Material)), 
; (VitalRelations "boat" (Space Category Role Material Part-Whole)), 
; (Intersection (Space Category Role Part-Whole Material))]

(=(extract-intersection $list )
(foldl-atom $list (empty)$acc $item (let ($head $tail) $item
  (if (== $head Intersection) $tail $acc))))

! (extract-intersection
   ((VitalRelations "house" (Space Part-Whole Category Role Possession Material))
    (VitalRelations "boat" (Space Category Role Material Part-Whole))
    (Intersection (Space Category Role Part-Whole Material)))
)



(=(apply-vital-weighting $mu_emergence $vital-types)
    (map-atom $mu_emergence $pair
    (let ($prop $val) $pair
    (if (== $vital-types $prop)
    (tuple $prop (* 1.5 $val))
    (tuple $prop $val)))))
        