! (import! &self libs)
! (import! &self common-utils)


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


(= (unpacking-op $good_blend )
    (let*(
        ($props (properties-list $good_blend))
        ($blend-name (blend-name $good_blend))
        ($mapped-props (map-atom $props $prop
        (if (> (size-atom $prop) 1)
           $prop
            ((car-atom $prop) ())
            )))
        ($scores (map-atom $mapped-props
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

(= (expansion-enabled) True )
(= (min-similarity) 0.65 )

; ! (unpacking-op (good_blend))