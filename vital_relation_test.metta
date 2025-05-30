! (import! &self conceptual_blending)


;! (gpt_vital_relation house boat)

; [(VitalRelations "house" (Space Part-Whole Category Role Possession Material)), 
; (VitalRelations "boat" (Space Category Role Material Part-Whole)), 
; (Intersection (Space Category Role Part-Whole Material))]

(=(extract-intersection $list )
(foldl-atom $list (empty) $acc $item (let ($head $tail) $item
  (if (== $head Intersection) $tail $acc))))

; ! (extract-intersection
;    ((VitalRelations "house" (Space Part-Whole Category Role Possession Material))
;     (VitalRelations "boat" (Space Category Role Material Part-Whole))
;     (Intersection (Space Category Role Part-Whole Material)))
; )

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
            
; (= (apply-vital-weightingg $mu-emergence $vital-types)
;     (map-atom $mu-emergence $pair
;         (chain (eval $pair) ($prop $val) 
;             (if (is-member $prop $vital-types)
;                 (println! ($prop (* 1.5 $val)))  ; boost important properties
;                 ($prop $val)
;             )
;         )
;     )
; )



; ! (map-atom
;     ((mobility 0.1) (category 0.2) (role 0.3))
;     $pair
;     (println! $pair)
; )
 (map-atom
    ()
    $pair
    (let ($prop $val) $pair
        (if (is-member $prop (mobility role possession))
            (println!($prop (* 1.5 $val)))  ; boost important properties
            (println!($prop $val))
    )
)
)
; !(map-atom
;     ((mobility 0.1) (category 0.2) (role 0.3) (possession 0.4) (color 0.5))
;     $pair
;     (let ($prop $val) $pair
;         (if (is-member $prop (mobility role possession))
;             (let($newval (* 1.5 $val))
;                 (println! (tuple $prop $newval))
;                 (tuple $prop $newval)
;             )
;             (let () 
;                 (println! $pair)
;                 $pair
;             )
;         )
;     )
; )

!(apply-vital-weighting
    ((mobility 0.1) (category 0.2) (role 0.3) (possession 0.4) (color 0.5))
    (mobility role possession)
)





