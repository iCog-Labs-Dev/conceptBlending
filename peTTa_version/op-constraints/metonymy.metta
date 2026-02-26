; !(import! op-constraints/common-utils)

(= (rel-score $target $blend-name)
    (let $res (py-call (op-helper-codes.compute_average_pairwise_similarity ( $target $blend-name)))
        (if (> $res (met-sim-threshold)) True False)
    )
)

(= (is-characteristic-part $target $blend-properties)
    (let $blend-prop-names (map-atom $blend-properties $prop (car-atom $prop)) (is-list-member $target $blend-prop-names))
)

(= (is-semantically-compressed $target $blend-properties $blend-name $detect-characteristic-parts) 
    (if (rel-score $target $blend-name)
        True
        (if (and $detect-characteristic-parts (is-characteristic-part $target $blend-properties))
            True
            False
        )
    )
)

(= (metonymy-indicators) (relatedTo synonym formOf hasA partOf atLocation))

(= (count-compressed-relations $relations $blend-properties $blend-name $acc)
    (if (< (size-atom $relations) 1)
        $acc
        (let* (($current-rel (car-atom $relations))
               ($remaining-rels (cdr-atom $relations))
               ($target (index-atom $current-rel 1))
               ($is-met-indicator (is-list-member (car-atom $current-rel) (metonymy-indicators)))
               ($is-semantically-compressed (if $is-met-indicator (is-semantically-compressed $target $blend-properties $blend-name (detect-characteristic-parts)) False))
               ($new-acc (if $is-semantically-compressed
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

(= (met-sim-threshold) 0.2)
