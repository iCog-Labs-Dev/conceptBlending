(= (blend-name ($blend-or-concept $blend-name $properties $relations)) $blend-name)

(= (properties-list (Blend $blend-name $properties $relations)) (
    let $prop-list $properties (cdr-atom $prop-list)
    )
)

(= (relations-key-value-list ($blend-or-concept $blend-name $properties $relations))
    (cdr-atom $relations)
)

(: to-float (-> Number Number))
(= (to-float-op $x) (+ $x 0.0))

(= (detect-characteristic-parts) True )

(= (size-checker $x)
    (size-atom $x)
)

(= (custom-filter-atom $list $predicate)
    (if (== (size-atom $predicate) 3)
        (let $result 
            (let ($method $op $val) $predicate
                (map-atom $list $element (collapse (let $res ($op $element $val) (if $res $element (empty)))))
            )
            (let $fresult (foldl-atom $result () $acc $x (union-atom $acc $x)) (unique-atom $fresult))
        )
        (if (== (size-atom $predicate) 4)
            (let $result 
                (let ($method $op $op-atom $val) $predicate
                    (map-atom $list $element (collapse (let $ime-res ($op-atom $element) (let $res ($op $ime-res $val) (if $res $element (empty))))))
                )
                (let $fresult (foldl-atom $result () $acc $x (union-atom $acc $x)) (unique-atom $fresult))
            )
            ()
        )
    )
)

(= (indexed-cdr-atom-helper $list $index)
    (if (<= $index 0)
        ()
        (let*
            (
                ($head (car-atom $list))
                ($tail (cdr-atom $list))
                ($new-idx (- $index 1))
                ($res (indexed-cdr-atom $tail $new-idx))
            )
            (cons-atom $head $res)
        )
    )
)

(= (indexed-cdr-atom $list $index)
    (let $nindex (if (> $index (size-atom $list)) (size-atom $list) $index) (indexed-cdr-atom-helper $list $nindex))
)

(= (provenance-sources $blend-properties)
    (let $props-with-prov (custom-filter-atom $blend-properties (Method > size-atom 1)) (map-atom $props-with-prov $prop (index-atom $prop 1)))
)

(= (predefined-conflicts)
    ((hot cold) (liquid solid) (alive dead) (floats metald) (floats sinks) (on off) (open close) (true false) (win lose))
)

(= (cross_mappings)(
        (relation_type RelatedTo
            (
                (concept_a_relation (RelatedTo man))
                (concept_b_relation (RelatedTo mammal))
            )
            (confidence 1.0)
        )
        (relation_type AtLocation
            (
                (concept_a_relation (AtLocation city))
                (concept_b_relation (AtLocation cave))
            )
            (confidence 1.0)
        )
    )
)

(= (concept-relation-mapping ($relation $rel-type ($concept-a-relation $concept-b-relation) $confidence))
    ($concept-a-relation $concept-b-relation)
)

(= (sum-op $lst)
   (if (== (get-metatype $lst) Expression) (foldl-atom $lst 0 $acc $x (+ $acc $x)) $lst)
)

; Check if item is in source list
(= (is-list-member $item ())
   False)
(= (is-list-member $item $source)
   (if (== $item (car-atom $source))
       True
       (is-list-member $item (cdr-atom $source))
   )
)

(= (max-of-two $a $b)(if (> $a $b) $a $b))
(= (max-in-list ($x)) $x)
(= (max-in-list $list) (max-of-two (car-atom $list) (max-in-list (cdr-atom $list))))
; The expected output is the max number from the list

(= (first-n-elements-helper-op $list $n)
   (if (<= $n 0)
      ()
      (let*
         (
            ($head (car-atom $list))
            ($tail (cdr-atom $list))
            ($new-n (- $n 1))
            ($res (first-n-elements-helper $tail $new-n))
         )
         (cons-atom $head $res)
      )
   )
)

(= (first-n-elements-op $list $n)
   (let $nn (if (> $n (size-atom $list)) (size-atom $list) $n) (first-n-elements-helper $list $nn))
)

(= (Provrelations) (isA relatedTo hasProperty synonym))

(= (get-provenances $concept $space $n)
    (let $relations (Provrelations) 
        (let $result (map-atom $relations $relation (first-n-elements-op (collapse(match $space ($relation $concept $target) $target)) $n))
            (let $fresult (foldl-atom $result () $acc $x (union-atom $acc $x)) (unique-atom $fresult))
        )
    )
)
