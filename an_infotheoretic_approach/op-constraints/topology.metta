! (import! &self libs)
! (import! &self common-utils)

(= (similarity_threshold) 0.65)

(= (find-similar-known-relation $rel $knowns)
   (if (== (size-atom $knowns) 0)
       ()
       (let* (
           ($head (car-atom $knowns))
           ($tail (cdr-atom $knowns))
           ($type-similarity (get_similarity_score (car-atom $rel) (car-atom $head)))
           ($target-similarity (get_similarity_score (index-atom $rel 1) (index-atom $head 1)))
         )
         (if (and (> $type-similarity (similarity_threshold)) (> $target-similarity (similarity_threshold)))
            $head
             (find-similar-known-relation $rel $tail)
             ))))


(= (normalize-relation $rel $knowns)
   (let* (
       ($match (find-similar-known-relation $rel $knowns))
     )

     (if (== (size-atom $match) 0)
         (let $new $rel
              ($new (cons-atom $new $knowns)))
         ($match $knowns)
         )
    )
)

(= (count-preserved-loop $blend-rels $source-rels $knowns)

   (if (== (size-atom $blend-rels) 0)
       0
       (let* (
           ($head (car-atom $blend-rels))
           ($tail (cdr-atom $blend-rels))
           ($norm-tuple (normalize-relation $head $knowns))
           ($norm (car-atom $norm-tuple))
           ($updated-knowns (cdr-atom $norm-tuple))
           ($rest-count (count-preserved-loop $tail $source-rels (car-atom $updated-knowns)))

         )
            (if (is-list-member $norm $source-rels)
                (+ 1 $rest-count)
                $rest-count
            )
         )
        )
)


(= (topology-op $blend $concept1 $concept2 )
    (let*(
       ($concept1-relations-list (relations-key-value-list $concept1))
        ($concept2-relations-list (relations-key-value-list $concept2))
        ($concept1-relations-inner (car-atom $concept1-relations-list))
        ($concept2-relations-inner (car-atom $concept2-relations-list))
        ($union-relations (union-atom $concept1-relations-inner $concept2-relations-inner))
        ($source-relations (unique-atom $union-relations))
        ($source-relations-size (size-atom $source-relations))
        ($blend-relations-list (relations-key-value-list $blend))
        ($preserved-count (count-preserved-loop (car-atom $blend-relations-list) $source-relations ()))

        ($source-relations-size-decimal (to-float $source-relations-size))
        ($preservation-score (/ $preserved-count $source-relations-size-decimal))
    )(
        $preservation-score
    )
    )
)

; ! (topology-op (good_blend) (concept1) (concept2))