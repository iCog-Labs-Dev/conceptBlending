(= (blend-name ($blend-or-concept $blend-name $properties $relations)) $blend-name)

(= (properties-list ($blend-or-concept $blend-name $properties $relations)) (
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

(= (provenance-sources-helper $blend-properties)
    ()
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

(= (concept-relations-op) (isA relatedTo hasProperty atLocation synonym capableOf antonym partOf hasA atLocation))

; Returns a list of relation expressions like (isa feline) (hasa whiskers) ...
(= (get-concept-relations-op $concept $space $n $rel)
    (first-n-elements (collapse(match $space ($rel $concept $target) ($rel $target))) $n)
)

(= (get-concept-relations-op $concept $space $n)
    (let $relations (concept-relations)
        (let $result (map-atom $relations $relation (first-n-elements (collapse(match $space ($relation $concept $target) ($relation $target))) $n))
            (let $fresult (foldl-atom $result () $acc $x (union-atom $acc $x)) (unique-atom $fresult))
        )
    )
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

(= (greater-than-threshold-props $props-list $threshold)
    (let $res (map-atom $props-list $prop (if (>= (index-atom $prop 1) $threshold) ($prop) ()))
        (foldl-atom $res () $acc $x (union-atom $acc $x))
        ; $res
    )
)

(= (blend-dominance-helper $blend-prop-degrees $concept1-prop-degrees $concept2-prop-degrees)
    (if (<= (size-atom $blend-prop-degrees) 0)
        ()
        (let*
            (
                ($c1-head (car-atom $concept1-prop-degrees))
                ($c1-tail (cdr-atom $concept1-prop-degrees))
                ($c2-head (car-atom $concept2-prop-degrees))
                ($c2-tail (cdr-atom $concept2-prop-degrees))
                ($blend-head (car-atom $blend-prop-degrees))
                ($blend-tail (cdr-atom $blend-prop-degrees))
                ($res (if (and (> $blend-head $c1-head) (> $blend-head $c2-head)) 1 0))
                ($tail (blend-dominance-helper $blend-tail $c1-tail $c2-tail))
            )
            (cons-atom $res $tail)
        )
    )
)

(= (prop-names-or-degrees-extractor $props-list $name-or-degree)
    (if (== $name-or-degree degree)
        (map-atom $props-list $prop (index-atom $prop 1))
        (map-atom $props-list $prop (index-atom $prop 0))
    )
)

(= (rel-sim-score $blend-rel $c1-c2-rel)
    (if (== (car-atom $blend-rel) (car-atom $c1-c2-rel))
        (let ($blend-rel-target $c1-c2-rel-target) ((index-atom $blend-rel 1) (index-atom $c1-c2-rel 1))
            (py-call (op-helper-codes.compute_average_pairwise_similarity ( $blend-rel-target $c1-c2-rel-target)))
        )
        0
    )
)

(= (relations-traceability-helper $blend-relations $c1-c2-relations $threshold)
    (if (== (size-atom $blend-relations) 0)
        ()
        (let*
            (
                ($blend-rels-head (car-atom $blend-relations))
                ; ($_ (println! (blend-rels-head $blend-rels-head)))
                ($blend-rels-tail (cdr-atom $blend-relations))
                ($blend-rels-head-score (map-atom $c1-c2-relations $relation (rel-sim-score $blend-rels-head $relation)))
                ($res (let $max-sim-score (max-atom $blend-rels-head-score) (if (>= $max-sim-score $threshold) 1 0)))
                ($tail (relations-traceability-helper $blend-rels-tail $c1-c2-relations $threshold))
            )
            (cons-atom $res $tail)
        )
    )
)

; !(intersection-atom (4 5 6) (4 5 7 8))

; !(greater-than-threshold-props ((intell 0.8) (pyhsic 0.7) (symoblo 0.3) (communic 0.2)) 0.1)
