!(register-module! ../libs)
! (import! &self libs)

(= (properties-list (Blend $blend_name $properties $relations)) (
    let $prop_list $properties (cdr-atom $prop_list)
    )
)

(= (blend-name (Blend $blend_name $properties $relations)) 
$blend_name
)


(= (evaluate-property ($prop-name $provenance-list) $blend-name)
   (if (== (size-atom $provenance-list) 0)
       0.0
       (let* (
            ($expanded_provenance 
                (if (expansion-enabled) 
                    (get_expand_provenance $provenance-list)
                    ($provenance-list)
                ))
           ($strength (provenance-strength $prop-name $expanded_provenance $blend-name))
           
       )
        $strength
       )
   )
)

(= (calculate-source-strength $prop-name $source-expr $blend-name)
    (let* (
        ($source-word (car-atom $source-expr))
    )
        (if (== $source-word $blend-name)
            1.0
            (let* (
                ($similarity (get_similarity_score $prop-name $source-word))
                ($is-related (are_related $prop-name $source-word))
            )
                (if $is-related
                     (max-atom ($similarity 0.8))
                     $similarity)
            )
        )
    )
)


(= (max-of-two $a $b)(if (> $a $b) $a $b))
(= (max-in-list ($x)) $x)
(= (max-in-list $list) (max-of-two (car-atom $list) (max-in-list (cdr-atom $list))))



(= (sum ()) 0)
(= (sum $lst)
   (+ (car-atom $lst) (sum (cdr-atom $lst)))
)

(= (provenance-strength $prop-name $provenance-list $blend-name)
    (let* (
        ($scores (map-atom $provenance-list
            $source-expr
            (calculate-source-strength $prop-name $source-expr $blend-name)
        ))

        ($max-score (max-in-list $scores))

        ($min-similarity (min-similarity))
        ($max-strength (
            if (> $max-score $min-similarity) 
                    $max-score
                    0.0
            ))

    )
    $max-strength
    )
)


(= (unpacking_op $good_blend )
    (let*(
        ($props (properties-list $good_blend))
        ($blend-name (blend-name $good_blend))
        ($scores (map-atom $props
                    $p
                    (
                        evaluate-property $p $blend-name
                    )
                )
        )
        ($total_score (sum $scores))
   )
   (
    if (> (size-atom $props) 0) (/ $total_score (size-atom $props)) 0.0
   )
   )
)

(= (good_blend)
    (Blend amphibious_vehicle 
    (Properties  (metal (car)) (floats (boat)) (waterproof ()) )
    (Relations (UsedFor (transportation 1.0)) (HasPartd (engine 0.8)))
    )
)


(= (expansion-enabled) True )
(= (min-similarity) 0.65 )

! (unpacking_op (good_blend))