
(= (concept1)
    (Concept car 
    (Properties  (metal (car)) (hasWheels (car)))
    (Relations (UsedFor (transportation 0.9)) (HasPart (engine 0.8)))
    )
)

(= (concept2)
    (Concept boat 
    (Properties  (floats (boat)) (waterproof (boat)))
    (Relations (UsedFor (transportation 0.9)) (UsedFor (recreation 0.7)))
    )
)

(= (good_blend)
    (Blend amphibious_vehicle 
    (Properties  (metal (car)) (floats (boat)) (waterproof))
    (Relations (UsedFor (transportation 1.0)) (Short_HasPart (engine 0.8)))
    )
)

(= (blend-name ($blend_or_concept $blend_name $properties $relations)) $blend_name )

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

(= (relation-key-value $relations) (
    (let*(
        ($relation-type (map-atom $relations $relation ((car-atom $relation)(get-property (index-atom $relation 1))) ))
    )
        $relation-type
    )
)
)
; relation-key-value (UsedFor (transportation 0.9))
; Expected output (UsedFor transportation)


(: to-float (-> Number Number))
(= (to-float $x) (+ $x 0.0))

(= (detect-abbreviations) True )

(= (detect-characteristic-parts) True )


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


(= (predefined-conflicts)
    ((hot cold) (liquid solid) (alive dead) (floats metald) (floats sinks) (on off) (open close) (true false) (win lose))
)

(= (cross_mappings)(
        (relation_type UsedFor 
            (
                (concept_a_relation  (UsedFor (transportation 0.9)))
                (concept_b_relation  (UsedFor (transportation 0.9)))
            )
            (confidence 1.0)
        )
    )
)

(= (concept-relation-mapping ($relation $rel-type ($concept_a_relation $concept_b_relation) $confidence))(
    $concept_a_relation $concept_b_relation
)
)


(= (sum ()) 0)
(= (sum $lst)
   (+ (car-atom $lst) (sum (cdr-atom $lst)))
)
; Expected output sum of list of numbers


; Check if item is in source list
(= (is-list-member $item ())
   False)
(= (is-list-member $item $source)
   (if (== $item (car-atom $source))
       True
       (is-list-member $item (cdr-atom $source))
   )
)


(= (max-of-two $a $b)(if (> $a $b) $a $b))
(= (max-in-list ($x)) $x)
(= (max-in-list $list) (max-of-two (car-atom $list) (max-in-list (cdr-atom $list))))
; The expected output is the max number from the list
