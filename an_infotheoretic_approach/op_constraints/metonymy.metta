!(register-module! ../libs)
! (import! &self libs)
! (import! &self common-utils)

(= (check-indicators-recursive $rel-type-str $indicators)
    (if (< (size-atom $indicators) 1)
        False
        (let* (($current-indicator (car-atom $indicators))
               ($remaining-indicators (cdr-atom $indicators)))
            (
                if (== $rel-type-str $current-indicator)
                    True
                    (check-indicators-recursive $rel-type-str $remaining-indicators)
            )
        )
    )
)

(= (compression-indicators) (Syn Metonym Short_HasPart Abbr Contraction))

(= (is-compressed $relation)
    (let* (($rel-type-str (car-atom $relation))
           ($indicators (compression-indicators)))
        (check-indicators-recursive $rel-type-str $indicators)
        
    )
)


(= (is-target-in-properties-name $target $blend-properties)
    (if (< (size-atom $blend-properties) 1)
        False
        (let* (($current-rel (car-atom $blend-properties))
               ($remaining-rels (cdr-atom $blend-properties))

               )

            (
                if (== $target (car-atom $current-rel))
                    True
                    (is-target-in-properties-name $target $remaining-rels)
            )
        )
    )
)

(= (is-characteristic-part $relation $blend-properties $bled-name) 
(let* (
        ($is-target-in-rel (is-target-in-properties-name (index-atom $relation 1) $blend-properties))
            )
            (if (== $is-target-in-rel True)
                True
                (is_relation_part_of (index-atom $relation 1) $bled-name)
            )
    )
)

(= (is-semantically-compressed $relation $blend-properties $blend-name $detect-abbreviations $detect-characteristic-parts) 

    (let* (
        ($is-abbrev (is_abbreviation (car-atom $relation)))
        ($is-metonymy (is_relation_metonymy (car-atom $relation) (index-atom $relation 1)))
        
        )
        (if (and $detect-abbreviations $is-abbrev)
            True
            (if (== $is-metonymy True)
                True
                (if (and $detect-characteristic-parts (is-characteristic-part $relation $blend-properties $blend-name))
                    True
                    False
                )
            )
        )
    )
)


(= (count-compressed-relations $relations $blend-properties $blend-name $acc)
    (if (< (size-atom $relations) 1)
        $acc
        (let* (($current-rel (car-atom $relations))
               ($remaining-rels (cdr-atom $relations))
               ($is-compressed (is-compressed $current-rel))
               ($is-semantically-compressed (is-semantically-compressed $current-rel $blend-properties $blend-name (detect-abbreviations) (detect-characteristic-parts)))
               ($new-acc (if (or $is-compressed $is-semantically-compressed)
                           (+ $acc 1)
                             $acc))
                )
            (count-compressed-relations $remaining-rels $blend-properties $blend-name $new-acc)
        )
    )
)
(= (metonymy_op $blend)
  (let* (
    ($blend-relations (relations-key-value-list $blend))
    ($blend-relations-inner (car-atom $blend-relations))
    ($total-relations (size-atom $blend-relations-inner))    
    ($blend-name (blend-name (good_blend)))
    ($blend-properties (properties-list (good_blend)))
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


! (metonymy_op (good_blend))