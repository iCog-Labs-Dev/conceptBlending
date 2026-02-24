(= (semantic-threshold) 0.25)

(= (relation-exists-in-blend $blend-relations $rel-pair)
    (is-list-member $rel-pair $blend-relations)
)

(= (check-relations-loop $rels $rel-type $rel-target $threshold)
  (if (== (size-atom $rels) 0)
      False
      (let* (
          ($head (car-atom $rels))
          ($tail (cdr-atom $rels))
      )
        (if (< (size-atom $head) 2)
            (check-relations-loop $tail $rel-type $rel-target $threshold)
            (let* (
                ($blend-rel-type (car-atom $head))
                ($blend-rel-target (index-atom $head 1))
                ($type-similarity (py-call (op-helper-codes.compute_average_pairwise_similarity ( $blend-rel-type $rel-type )) ))
                ($target-similarity (py-call (op-helper-codes.compute_average_pairwise_similarity ( $blend-rel-target $rel-target )) ))
                ($match (and (> $type-similarity $threshold)
                               (> $target-similarity $threshold)))
            )
              (if $match
                True
                (check-relations-loop $tail $rel-type $rel-target $threshold))
            )
        )
      )
  )
)

(= (score-cross-mapping $relation $blend-relations)
   (let* (
        ($rel-exists (relation-exists-in-blend $relation $blend-relations))
        ($rel-type (car-atom $relation))
        ($rel-target (index-atom $relation 1))
        ($threshold (semantic-threshold))
   )
     (
        if $rel-exists
         1.0
         (
            if (check-relations-loop $blend-relations $rel-type $rel-target $threshold)
                0.8
                0.0
        )
     )
   )
)

(= (crucial-link-integrity-check $blend-props $c1-props $c2-props)
    (let $blend-dominance (blend-dominance-helper $blend-props $c1-props $c2-props)
        (let ($blend-dominance-sum $props-size) ((sum-op $blend-dominance) (size-atom $blend-props))
            (let $dom-ratio (/ $blend-dominance-sum $props-size)
                (- 1 $dom-ratio)
            )
        )
    )
)

(= (web-op $blend $concept1 $concept2)
  (let* 
    (
        (($blend-relations $c1-rels $c2-rels) (collapse(superpose((relations-key-value-list $blend) (relations-key-value-list $concept1) (relations-key-value-list $concept2)))))
        (($blend-props $c1-props $c2-props) (collapse(superpose((properties-list $blend) (properties-list $concept1) (properties-list $concept2)))))
        (($blend-props-degrees $c1-props-degrees $c2-props-degrees) (collapse(superpose((prop-names-or-degrees-extractor $blend-props degree) (prop-names-or-degrees-extractor $c1-props degree) (prop-names-or-degrees-extractor $c2-props degree)))))
        ($c1-c2-rels (let $c1-c2-union (union-atom $c1-rels $c2-rels) (unique-atom $c1-c2-union)))
        ($rels-mapping-scores (map-atom $c1-c2-rels $relation (score-cross-mapping $relation $blend-relations)))
        ($cli-res (crucial-link-integrity-check $blend-props-degrees $c1-props-degrees $c2-props-degrees))
        ($cross-space-mapping-res (let ($sum $score-size) ((sum-op $rels-mapping-scores) (size-atom $rels-mapping-scores)) (/ $sum $score-size)))
        ($result (/ (+ $cli-res $cross-space-mapping-res) 2.0))
    )    
    $result
  )
)

; !(web-op (cross_mappings) (blend))
; Expected output 0.0
