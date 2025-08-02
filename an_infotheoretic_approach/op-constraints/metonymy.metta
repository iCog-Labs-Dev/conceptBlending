! (import! &self libs)
! (import! &self common-utils)

(= (is-characteristic-part $relation $blend-properties $bled-name) 
    (if (is-list-member (index-atom $relation 1) $blend-properties)
        True
        (is_relation_part_of (index-atom $relation 1) $bled-name)
    )
)

(= (is-semantically-compressed $relation $blend-properties $blend-name $detect-abbreviations $detect-characteristic-parts) 

    (let* (
        ($is-abbrev (is_abbreviation (car-atom $relation)))
        )
        (if (and $detect-abbreviations $is-abbrev)
            True
            (if (is_relation_metonymy (car-atom $relation) (index-atom $relation 1))
                True
                (if (and $detect-characteristic-parts (is-characteristic-part $relation $blend-properties $blend-name))
                    True
                    False
                )
            )
        )
    )
)

(= (compression-indicators) (Syn Metonym Short_HasPart Abbr Contraction))

(= (count-compressed-relations $relations $blend-properties $blend-name $acc)
    (if (< (size-atom $relations) 1)
        $acc
        (let* (($current-rel (car-atom $relations))
               ($remaining-rels (cdr-atom $relations))
               ($is-compressed (is-list-member (car-atom $current-rel) (compression-indicators)))
               ($is-semantically-compressed (is-semantically-compressed $current-rel $blend-properties $blend-name (detect-abbreviations) (detect-characteristic-parts)))
               ($new-acc (if (or $is-compressed $is-semantically-compressed)
                           (+ $acc 1)
                             $acc))
                )
            (count-compressed-relations $remaining-rels $blend-properties $blend-name $new-acc)
        )
    )
)
(= (metonymy-op $blend)
  (let* (
    ($blend-relations (relations-key-value-list $blend))
    (() (println! $blend-relations))
    ; ($blend-relations-inner (car-atom $blend-relations))
    ($total-relations (size-atom $blend-relations))
    (() (println! $total-relations))    
    ($blend-name (blend-name $blend))
    ($blend-properties (properties-list $blend))
    ($compressed-count (count-compressed-relations $blend-relations-inner $blend-properties $blend-name 0))
    ($compressed-count-float (to-float $compressed-count))
  )
    (
        if (> $total-relations 0)
            (/ $compressed-count-float $total-relations)
            0.0
    )
  )
)


; ! (metonymy-op (good_blend))