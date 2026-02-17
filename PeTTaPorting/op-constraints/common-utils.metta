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

(= (detect-abbreviations) True )

(= (detect-characteristic-parts) True )

(= (size-checker $x)
    (size-atom $x)
)

(= (custom-filter-atom $list $predicate)
    (if (== (size-atom $predicate) 3)
        (let (($method $op $val) $length) ($predicate (size-atom $list))
            (collapse(
                superpose(
                    (if (>= (- $length 1) 0) (let $first-atom (index-atom $list 0)  (let $res ($op $first-atom $val) (if $res $first-atom (empty)))) (empty))
                    (if (>= (- $length 2) 0) (let $second-atom (index-atom $list 1)  (let $res ($op $second-atom $val) (if $res $second-atom (empty)))) (empty))
                    (if (>= (- $length 3) 0) (let $third-atom (index-atom $list 2)  (let $res ($op $third-atom $val) (if $res $third-atom (empty)))) (empty))
                    (if (>= (- $length 4) 0) (let $fourth-atom (index-atom $list 3)  (let $res ($op $fourth-atom $val) (if $res $fourth-atom (empty)))) (empty))
                    (if (>= (- $length 5) 0) (let $fifth-atom (index-atom $list 4)  (let $res ($op $fifth-atom $val) (if $res $fifth-atom (empty)))) (empty))
                    (if (>= (- $length 6) 0) (let $sixth-atom (index-atom $list 5)  (let $res ($op $sixth-atom $val) (if $res $sixth-atom (empty)))) (empty))
                    (if (>= (- $length 7) 0) (let $seventh-atom (index-atom $list 6)  (let $res ($op $seventh-atom $val) (if $res $seventh-atom (empty)))) (empty))
                    (if (>= (- $length 8) 0) (let $eigth-atom (index-atom $list 7)  (let $res ($op $eigth-atom $val) (if $res $eigth-atom (empty)))) (empty))
                    (if (>= (- $length 9) 0) (let $ninth-atom (index-atom $list 8)  (let $res ($op $ninth-atom $val) (if $res $ninth-atom (empty)))) (empty))
                    (if (>= (- $length 10) 0) (let $tenth-atom (index-atom $list 9)  (let $res ($op $tenth-atom $val) (if $res $tenth-atom (empty)))) (empty))
                    )
                )
            )
        )
        (if (== (size-atom $predicate) 4)
            (let (($method $op $op-atom $val) $length) ($predicate (size-atom $list))
                (collapse(
                    superpose(
                        (if (>= (- $length 1) 0) (let $first-atom (index-atom $list 0)  (let $ime-res ($op-atom $first-atom) (let $res ($op $ime-res $val) (if $res $first-atom (empty))))) (empty))
                        (if (>= (- $length 2) 0) (let $second-atom (index-atom $list 1)  (let $ime-res ($op-atom $second-atom) (let $res ($op $ime-res $val) (if $res $second-atom (empty))))) (empty))
                        (if (>= (- $length 3) 0) (let $third-atom (index-atom $list 2)  (let $ime-res ($op-atom $third-atom) (let $res ($op $ime-res $val) (if $res $third-atom (empty))))) (empty))
                        (if (>= (- $length 4) 0) (let $fourth-atom (index-atom $list 3)  (let $ime-res ($op-atom $fourth-atom) (let $res ($op $ime-res $val) (if $res $fourth-atom (empty))))) (empty))
                        (if (>= (- $length 5) 0) (let $fifth-atom (index-atom $list 4)  (let $ime-res ($op-atom $fifth-atom) (let $res ($op $ime-res $val) (if $res $fifth-atom (empty))))) (empty))
                        (if (>= (- $length 6) 0) (let $sixth-atom (index-atom $list 5)  (let $ime-res ($op-atom $sixth-atom) (let $res ($op $ime-res $val) (if $res $sixth-atom (empty))))) (empty))
                        (if (>= (- $length 7) 0) (let $seventh-atom (index-atom $list 6)  (let $ime-res ($op-atom $seventh-atom) (let $res ($op $ime-res $val) (if $res $seventh-atom (empty))))) (empty))
                        (if (>= (- $length 8) 0) (let $eigth-atom (index-atom $list 7)  (let $ime-res ($op-atom $eigth-atom) (let $res ($op $ime-res $val) (if $res $eigth-atom (empty))))) (empty))
                        (if (>= (- $length 9) 0) (let $ninth-atom (index-atom $list 8)  (let $ime-res ($op-atom $ninth-atom) (let $res ($op $ime-res $val) (if $res $ninth-atom (empty))))) (empty))
                        (if (>= (- $length 10) 0) (let $tenth-atom (index-atom $list 9)  (let $ime-res ($op-atom $tenth-atom) (let $res ($op $ime-res $val)(if $res $tenth-atom (empty))))) (empty))
                        )
                    )
                )
            )
            (empty)
        )
    )
)

(= (indexed-cdr-atom $list $index)
    (collapse(
        superpose(
            (if (== 0 $index) (empty) (index-atom $list 0))
            (if (== 1 $index) (empty) (index-atom $list 1))
            (if (== 2 $index) (empty) (index-atom $list 2))
            (if (== 3 $index) (empty) (index-atom $list 3))
            (if (== 4 $index) (empty) (index-atom $list 4))
            (if (== 5 $index) (empty) (index-atom $list 5))
            (if (== 6 $index) (empty) (index-atom $list 6))
            (if (== 7 $index) (empty) (index-atom $list 7))
            (if (== 8 $index) (empty) (index-atom $list 8))
            (if (== 9 $index) (empty) (index-atom $list 9))
            (if (== 10 $index) (empty) (index-atom $list 10))
            (if (== 11 $index) (empty) (index-atom $list 11))
            (if (== 12 $index) (empty) (index-atom $list 12))
            (if (== 13 $index) (empty) (index-atom $list 13))
            (if (== 14 $index) (empty) (index-atom $list 14))
            (if (== 15 $index) (empty) (index-atom $list 15))
            (if (== 16 $index) (empty) (index-atom $list 16))
        )
    ))
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
