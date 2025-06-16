
(= (get-property $prop-value-pair)
    (let ($x $y) $prop-value-pair $x)
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

(= (relations-key-value-list ($blend_or_concept $blend_name $properties $relations)) (
    (let*(
        ($prop_list (cdr-atom $relations))
        ($relation-type (map-atom $prop_list $x ((car-atom $x) (get-property (index-atom $x 1))) ))
    )
        $relation-type
    )
)
)


(= (list-member $item ())
   False)
(= (list-member $item $source)
   (if (== $item (car-atom $source))
       True
       (list-member $item (cdr-atom $source))
   )
)
(=
(relation-exists-in-blend $blend-relations $concept-relation)
  (let* (
    ($rel-pair (car-atom $concept-relation))
  )
    (or
      (list-member $rel-pair $blend-relations)
      False
    )
  )

)
(= (score-cross-mapping $blend-relations $a-kv $b-kv)
   (let* (
       ($a-exists (relation-exists-in-blend $blend-relations $a-kv))
       ($b-exists (relation-exists-in-blend $blend-relations $b-kv))
   )
     (
        if (and $a-exists $b-exists)
         1.0
         0.8
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

(= (web_op $cross_mappings $blend)
  (let* (
    ($blend-relations (relations-key-value-list $blend))
    ($scores (map-atom $cross_mappings
        $mapping
        (let* (
            (($a $b) (concept-relation-mapping $mapping))
            ($a-kv (relation-key-value (cdr-atom $a)))
            ($b-kv (relation-key-value (cdr-atom $b)))
            ($score (score-cross-mapping (car-atom $blend-relations) (car-atom $a-kv) (car-atom $b-kv)))
        )
          $score
        )
    ))
    ($sum (sum $scores))
    ($count (size-atom $scores))
    ($average (/ $sum $count))
    ($result (min-atom (1.0 $average)))
    
  )
    $result
  )
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

(= (good_blend)
    (Blend amphibious_vehicle 
    (Properties  (metal (car)) (floats (boat)) (waterproof))
    (Relations (UsedFor (transportation 1.0)) (HasPartd (engine 0.8)))
    )
)

! (web_op (cross_mappings) (good_blend))