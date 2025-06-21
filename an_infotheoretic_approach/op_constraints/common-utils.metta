
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
