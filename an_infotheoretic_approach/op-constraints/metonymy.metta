! (import! &self libs)
; ! (import! &self common-utils)

(= (is-relation-PartOf $term $context)
    (let* (
        ($res (collapse(match &self (Triplet (PartOf $term $context)) ($term $context))))
        )
        (if (> (size-atom $res) 0) True False)
    )
)

; !(is-relation-part-of Apple Tree)

(= (rel-exists-HasA $term $context)
    (let* (
        ($res (collapse(match &self (HasA $context $term) ($context $term))))
        )
        (if (> (size-atom $res) 0) True False)
    )
)

; !(rel-exists-HasA Leaf Tree)

(= (rel-exists-LocatedNear $term $context)
    (let* (
        ($res (collapse(match &self (LocatedNear $term $context) ($term $context))))
        )
        (if (> (size-atom $res) 0) True False)
    )
)
(=(rel-exists-SymbolOf $term $context)
    (let* (
        ($res (collapse(match &self (SymbolOf $term $context) ($term $context))))
        )
        (if (> (size-atom $res) 0) True False)
    )
)

(=(is-relation-metonymy $term1 $term2)
    (let* (
        ($partof (is-relation-part-of $term1 $term2))
        (()(println! ("PartOf: " $partof)))
        ($HasA (rel-exists-HasA $term1 $term2))
        (()(println! ("HasA: " $HasA)))
        ($LocatedNear (rel-exists-LocatedNear $term1 $term2))
        (()(println! ("LocatedNear: " $LocatedNear)))
        ($SymbolOf (rel-exists-SymbolOf $term1 $term2))
        (()(println! ("SymbolOf: " $SymbolOf)))
        ($result (if (or $partof (or $HasA (or $LocatedNear $SymbolOf))) True False))
    )
    $result
    ))


(= (is-characteristic-part $relation $blend-properties $bled-name) 
    (if (is-list-member (index-atom $relation 1) $blend-properties)
        True
        (is-relation-PartOf (index-atom $relation 1) $bled-name)
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
    ($blend-relations (relations-key-value-lists $blend))
    ($total-relations (size-atom $blend-relations))
    ($blend-name (blend-name $blend))
    ($blend-properties (propertiesList $blend))
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


; ! (metonymy-op (good_blend))