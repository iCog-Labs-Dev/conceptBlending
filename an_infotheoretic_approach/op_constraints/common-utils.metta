
(= (good_blend)
    (Blend amphibious_vehicle 
    (Properties  (metal (car)) (floats (boat)) (waterproof))
    (Relations (UsedFor (transportation 1.0)) (Short_HasPart (engine 0.8)))
    )
)

(= (detect-abbreviations) True )

(= (detect-characteristic-parts) True )

(= (get-property $prop-value-pair)
    (let ($x $y) $prop-value-pair $x)
)

(= (properties-list (Blend $blend_name $properties $relations)) (
    let $prop_list $properties (cdr-atom $prop_list)
    )
)

(= (relations-key-value-list ($blend_or_concept $blend_name $properties $relations)) (
    (let*(
        ($prop_list (cdr-atom $relations))
        ($relation-type (map-atom $prop_list $x ((car-atom $x) (get-property (index-atom $x 1))) ))
    )
        $relation-type
    )
)
)

(: to-float (-> Number Number))
(= (to-float $x) (+ $x 0.0))


(= (blend-name ($blend_or_concept $blend_name $properties $relations)) $blend_name )




(= (remove-none $list)
  (if (== (size-atom $list) 0)
      ()
      (let* (
          ($head (car-atom $list))
          ($tail (cdr-atom $list))
        )
        (if (== $head None)
            (remove-none $tail)
            (let* (
                ($next-head (remove-none $tail))
            )
            (cons-atom $head $next-head)
            )
        )
      )
  )
)

(= (provenance-sources $blend-properties)
    (let* (
        ($mapped (map-atom $blend-properties $prop
        (if (> (size-atom $prop) 1)
           (index-atom $prop 1)
            (None))))
        ($filtered (map-atom $mapped $prov (car-atom $prov)))
        ($provenance (remove-none $filtered))

    )
        $provenance 
    )
)
