!(register-module! ../libs)
! (import! &self libs)

(= (get-property $prop-value-pair)
    (let ($x $y) $prop-value-pair (car-atom $y))
)

(= (relations-key-value-list ($blend_or_concept $blend_name $properties $relations)) (
    (let*(
        ($prop_list (cdr-atom $relations))
        ($relation-type (map-atom $prop_list $x ((car-atom $x) (get-property $x)) ))
    )
        $relation-type
    )
)
)
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

(= (list-member $item ())
   0)
(= (list-member $item $source)
   (if (== $item (car-atom $source))
       1
       (list-member $item (cdr-atom $source))
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
           ($is-preserved (list-member $norm $source-rels))
           ($rest-count (count-preserved-loop $tail $source-rels (car-atom $updated-knowns)))

         )
         (+ $is-preserved $rest-count)
         )
        )
)


(= (topology_op $blend $concept1 $concept2 )
    (let*(
        ($blend-prop-list (properties-list $blend))
        ($concept1-relations-list (relations-key-value-list $concept1))
        ($concept2-relations-list (relations-key-value-list $concept2))
        ($concept1-relations-inner (car-atom $concept1-relations-list))
        ($concept2-relations-inner (car-atom $concept2-relations-list))
        ($union-relations (union-atom $concept1-relations-inner $concept2-relations-inner))
        ($source-relations (unique-atom $union-relations))
        ($source-relations-size (size-atom $source-relations))
        ($blend-relations-list (relations-key-value-list $blend))
        ($preserved-count (count-preserved-loop (car-atom $blend-relations-list) $source-relations ()))

        ($source-relations-size-decimal (+ 0.00000000000000001 $source-relations-size))
        ($preservation-score (/ $preserved-count $source-relations-size-decimal)
        )
    )(
        $preservation-score
    )
    )
)

(= (good_blend)
    (Blend amphibious_vehicle 
    (Properties  (metal (car)) (floats (boat)) (waterproof))
    (Relations (UsedFor (transportation 1.0)) (HasPartd (engine 0.8)))
    )
)

(= (concept1)
    (Concept car 
    (Properties  (metal (car)) (hasWheels (car)))
    (Relations (UsedFor (transportation 0.9)) (HasPart (engine 0.8)))
    )
)

(= (concept2)
    (Concept boat 
    (Properties  (floats (boat)) (waterproof (boat)))
    (Relations (UsedFor (transportation 0.9)) (UsedFor (recreation 0.7)))
    )
)

! (topology_op (good_blend) (concept1) (concept2))