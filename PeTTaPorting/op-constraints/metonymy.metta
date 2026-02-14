; !(import! op-constraints/common-utils)

(= (is-relation-part-of $term $context)
    (let* (
        ($res (collapse(match &space (relation (PartOf $term $context) PartOf) ($term $context))))
        )
        (if (> (size-atom $res) 0) True False)
    )
)

(=(is-abbreviation $term) 
    (let* (
        ($relation (collapse(match &space (target (IsA $term $fullformed) $abbriv) (car-atom $abbriv))))
        ($result (if (== (abbreviation) $relation) True False))
    )
    $result
    )
)

(= (rel-exists-HasA $term $context)
    (let* (
        ($res (collapse(match &space (relation (HasA $context $term) HasA) ($context $term))))
        )
        (if (> (size-atom $res) 0) True False)
    )
)

(= (rel-exists-LocatedNear $term $context)
    (let* (
        ($res (collapse(match &space (relation (LocatedNear $term $context) LocatedNear) ($term $context))))
        )
        (if (> (size-atom $res) 0) True False)
    )
)

(=(rel-exists-SymbolOf $term $context)
    (let* (
        ($res (collapse(match &space (relation (SymbolOf $term $context) SymbolOf) ($term $context))))
        )
        (if (> (size-atom $res) 0) True False)
    )
)

(=(is-relation-metonymy $term1 $term2)
    (let* (
        ($partof (is-relation-part-of $term1 $term2))
        ($HasA (rel-exists-HasA $term1 $term2))
        ($LocatedNear (rel-exists-LocatedNear $term1 $term2))
        ($SymbolOf (rel-exists-SymbolOf $term1 $term2))
        ($result (if (or $partof (or $HasA (or $LocatedNear $SymbolOf))) True False))
    )
    $result
    ))

(= (is-characteristic-part $relation $blend-properties $bled-name) 
    (if (is-list-member (index-atom $relation 1) $blend-properties)
        True
        (is-relation-part-of (index-atom $relation 1) $bled-name)
    )
)

(= (is-semantically-compressed $relation $blend-properties $blend-name $detect-abbreviations $detect-characteristic-parts) 

    (let* (
        ($is-abbrev (is-abbreviation (car-atom $relation)))
        )
        (if (and $detect-abbreviations $is-abbrev)
            True
            (if (is-relation-metonymy (car-atom $relation) (index-atom $relation 1))
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
    ($total-relations (size-atom $blend-relations))
    ($blend-name (blend-name $blend))
    ($blend-properties (properties-list $blend))
    ($compressed-count (count-compressed-relations $blend-relations $blend-properties $blend-name 0))
    ($compressed-count-float (to-float-op $compressed-count))
  )
    (
        if (> $total-relations 0)
            (/ $compressed-count-float $total-relations)
            0.0
    )
  )
)
