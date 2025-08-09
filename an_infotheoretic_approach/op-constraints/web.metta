! (import! &self libs)
; ! (import! &self common-utils)


(= (relation-exists-in-blend $blend-relations $rel-pair)
    (is-list-member $rel-pair $blend-relations)
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
                ($a-type-similarity (get-similarity-score $rel-type $a-type))
                ($a-target-similarity (get-similarity-score $rel-target $a-target))
                ($b-type-similarity (get-similarity-score $rel-type $b-type))
                ($b-target-similarity (get-similarity-score $rel-target $b-target))
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

(= (semantic-threshold) 0.1)

(= (score-cross-mapping $blend-relations $a-kv-inner $b-kv-inner)
   (let* (
        ($a-exists (relation-exists-in-blend $blend-relations $a-kv-inner))
        ($b-exists (relation-exists-in-blend $blend-relations $b-kv-inner))
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

(= (calc-score-cross-mapping $mapping $blend-relations)
  (let ($a $b) (concept-relation-mapping $mapping)
    (let ($a-kv $b-kv) ((cdr-atom $a) (cdr-atom $b))
      (let $score (score-cross-mapping $blend-relations (car-atom $a-kv) (car-atom $b-kv)) $score)
    )
  )
)

(= (web-op $cross-mappings $blend)
  (let* 
    (
        ($blend-relations (relations-key-value-list $blend))
        ($scores (map-atom $cross-mappings $mapping (calc-score-cross-mapping $mapping $blend-relations)))
        ($sum (sum-op $scores))
        ($count (size-atom $scores))
        ($average (/ $sum $count))
        ($result (min-atom (1.0 $average)))
        
    )
    $result
  )
)

; ! (web-op (cross_mappings) (good_blend))