!(register-module! ../libs)
! (import! &self libs)
! (import! &self common-utils)


(= (relation-exists-in-blend $blend-relations $concept-relation)
  (let* (
    ($rel-pair (car-atom $concept-relation))
  )
    (or
      (is-list-member $rel-pair $blend-relations)  ; TODO: should be replaced with filter-atom
      False
    )
  )

)

(= (check-relations-loop $rels $a-type $a-target $b-type $b-target $threshold)
  (if (== (size-atom $rels) 0)
      False
      (let* (
          ($head (car-atom $rels))
          ($tail (cdr-atom $rels))
      )
        (if (< (size-atom $head) 2)
            (check-relations-loop $tail $a-type $a-target $b-type $b-target $threshold)
            (let* (
                ($rel-type (car-atom $head))
                ($rel-target (index-atom $head 1))
                ($a-type-similarity (get_similarity_score $rel-type $a-type))
                ($a-target-similarity (get_similarity_score $rel-target $a-target))
                ($b-type-similarity (get_similarity_score $rel-type $b-type))
                ($b-target-similarity (get_similarity_score $rel-target $b-target))
                ($match-a (and (> $a-type-similarity $threshold)
                               (> $a-target-similarity $threshold)))
                ($match-b (and (> $b-type-similarity $threshold)
                               (> $b-target-similarity $threshold)))
            )
              (if (and $match-a $match-b)
                True
                (check-relations-loop $tail $a-type $a-target $b-type $b-target $threshold))
            )
        )
      )
  )
)

(= (semantic-threshold) 0.75)

(= (score-cross-mapping $blend-relations $a-kv $b-kv)
   (let* (
        ($a-exists (relation-exists-in-blend $blend-relations $a-kv))
        ($b-exists (relation-exists-in-blend $blend-relations $b-kv))
        
        ($a-kv-inner (car-atom $a-kv))
        ($b-kv-inner (car-atom $b-kv))

        ($a-type (car-atom $a-kv-inner))
        ($a-target (index-atom $a-kv-inner 1))
        ($b-type (car-atom $b-kv-inner))
        ($b-target (index-atom $b-kv-inner 1))
        ($threshold (semantic-threshold))
   )
     (
        if (and $a-exists $b-exists)
         1.0
         (
            if (check-relations-loop $blend-relations $a-type $a-target $b-type $b-target $threshold)
                0.8
                0.0
        )
     )
   )
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


! (web_op (cross_mappings) (good_blend))