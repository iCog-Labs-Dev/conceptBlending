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

(= (custom-filter-atom $list $var $predicate)
    (let (($op $mid-par $val) $length) ($predicate (size-atom $list))
        (if (== (get-metatype $mid-par) Expression)
            (if (== (size-atom $mid-par) 3)
                (let ($met-name $mid-op $mid-var) $mid-par
                    (collapse(
                        superpose(
                            (if (>= (- $length 1) 0) (let $first-atom (index-atom $list 0) (if (unify $op = True False) (let ($s-op $s-mid-op $s-val) (atom-subst $first-atom $var ($op ($met-name $mid-op $mid-var) $val)) (let $mid-val (cdr-atom $s-mid-op) (let $f-mid-val $mid-val (if (== $f-mid-val $s-val) $first-atom Empty)))) (let ($s-op $s-mid-op $s-val) (atom-subst $first-atom $var ($op ($met-name $mid-op $mid-var) $val)) (let $mid-val (cdr-atom $s-mid-op) (if ($s-op $mid-val $s-val) $first-atom Empty))))) Empty)
                            (if (>= (- $length 2) 0) (let $second-atom (index-atom $list 1) (if (unify $op = True False) (let ($s-op $s-mid-op $s-val) (atom-subst $second-atom $var ($op ($met-name $mid-op $mid-var) $val)) (let $mid-val (cdr-atom $s-mid-op) (let $f-mid-val $mid-val (if (== $f-mid-val $s-val) $second-atom Empty)))) (let ($s-op $s-mid-op $s-val) (atom-subst $second-atom $var ($op ($met-name $mid-op $mid-var) $val)) (let $mid-val (cdr-atom $s-mid-op) (if ($s-op $mid-val $s-val) $second-atom Empty))))) Empty)
                            (if (>= (- $length 3) 0) (let $third-atom (index-atom $list 2) (if (unify $op = True False) (let ($s-op $s-mid-op $s-val) (atom-subst $third-atom $var ($op ($met-name $mid-op $mid-var) $val)) (let $mid-val (cdr-atom $s-mid-op) (let $f-mid-val $mid-val (if (== $mid-val $s-val) $third-atom Empty)))) (let ($s-op $s-mid-op $s-val) (atom-subst $third-atom $var ($op ($met-name $mid-op $mid-var) $val)) (let $mid-val (cdr-atom $s-mid-op) (if ($s-op $mid-val $s-val) $third-atom Empty))))) Empty)
                            (if (>= (- $length 4) 0) (let $fourth-atom (index-atom $list 3) (if (unify $op = True False) (let ($s-op $s-mid-op $s-val) (atom-subst $fourth-atom $var ($op ($met-name $mid-op $mid-var) $val)) (let $mid-val (cdr-atom $s-mid-op) (let $f-mid-val $mid-val (if (== $mid-val $s-val) $fourth-atom Empty)))) (let ($s-op $s-mid-op $s-val) (atom-subst $fourth-atom $var ($op ($met-name $mid-op $mid-var) $val)) (let $mid-val (cdr-atom $s-mid-op) (if ($s-op $mid-val $s-val) $fourth-atom Empty))))) Empty)
                            (if (>= (- $length 5) 0) (let $fifth-atom (index-atom $list 4) (if (unify $op = True False) (let ($s-op $s-mid-op $s-val) (atom-subst $fifth-atom $var ($op ($met-name $mid-op $mid-var) $val)) (let $mid-val (cdr-atom $s-mid-op) (let $f-mid-val $mid-val (if (== $mid-val $s-val) $fifth-atom Empty)))) (let ($s-op $s-mid-op $s-val) (atom-subst $fifth-atom $var ($op ($met-name $mid-op $mid-var) $val)) (let $mid-val (cdr-atom $s-mid-op) (if ($s-op $mid-val $s-val) $fifth-atom Empty))))) Empty)
                            (if (>= (- $length 6) 0) (let $sixth-atom (index-atom $list 5) (if (unify $op = True False) (let ($s-op $s-mid-op $s-val) (atom-subst $sixth-atom $var ($op ($met-name $mid-op $mid-var) $val)) (let $mid-val (cdr-atom $s-mid-op) (let $f-mid-val $mid-val (if (== $mid-val $s-val) $sixth-atom Empty)))) (let ($s-op $s-mid-op $s-val) (atom-subst $sixth-atom $var ($op ($met-name $mid-op $mid-var) $val)) (let $mid-val (cdr-atom $s-mid-op) (if ($s-op $mid-val $s-val) $sixth-atom Empty))))) Empty)
                            (if (>= (- $length 7) 0) (let $seventh-atom (index-atom $list 6) (if (unify $op = True False) (let ($s-op $s-mid-op $s-val) (atom-subst $seventh-atom $var ($op ($met-name $mid-op $mid-var) $val)) (let $mid-val (cdr-atom $s-mid-op) (let $f-mid-val $mid-val (if (== $mid-val $s-val) $seventh-atom Empty)))) (let ($s-op $s-mid-op $s-val) (atom-subst $seventh-atom $var ($op ($met-name $mid-op $mid-var) $val)) (let $mid-val (cdr-atom $s-mid-op) (if ($s-op $mid-val $s-val) $seventh-atom Empty))))) Empty)
                            (if (>= (- $length 8) 0) (let $eigth-atom (index-atom $list 7) (if (unify $op = True False) (let ($s-op $s-mid-op $s-val) (atom-subst $eigth-atom $var ($op ($met-name $mid-op $mid-var) $val)) (let $mid-val (cdr-atom $s-mid-op) (let $f-mid-val $mid-val (if (== $mid-val $s-val) $eigth-atom Empty)))) (let ($s-op $s-mid-op $s-val) (atom-subst $eigth-atom $var ($op ($met-name $mid-op $mid-var) $val)) (let $mid-val (cdr-atom $s-mid-op) (if ($s-op $mid-val $s-val) $eigth-atom Empty))))) Empty)
                            (if (>= (- $length 9) 0) (let $ninth-atom (index-atom $list 8) (if (unify $op = True False) (let ($s-op $s-mid-op $s-val) (atom-subst $ninth-atom $var ($op ($met-name $mid-op $mid-var) $val)) (let $mid-val (cdr-atom $s-mid-op) (let $f-mid-val $mid-val (if (== $mid-val $s-val) $ninth-atom Empty)))) (let ($s-op $s-mid-op $s-val) (atom-subst $ninth-atom $var ($op ($met-name $mid-op $mid-var) $val)) (let $mid-val (cdr-atom $s-mid-op) (if ($s-op $mid-val $s-val) $ninth-atom Empty))))) Empty)
                            (if (>= (- $length 10) 0) (let $tenth-atom (index-atom $list 9) (if (unify $op = True False) (let ($s-op $s-mid-op $s-val) (atom-subst $tenth-atom $var ($op ($met-name $mid-op $mid-var) $val)) (let $mid-val (cdr-atom $s-mid-op) (let $f-mid-val $mid-val (if (== $mid-val $s-val) $tenth-atom Empty)))) (let ($s-op $s-mid-op $s-val) (atom-subst $tenth-atom $var ($op ($met-name $mid-op $mid-var) $val)) (let $mid-val (cdr-atom $s-mid-op) (if ($s-op $mid-val $s-val) $tenth-atom Empty))))) Empty)
                            )
                        )
                    )
                )
                (Error $predicate UnsupportedFormat)           
            )
            (collapse(
                superpose(
                    (if (>= (- $length 1) 0) (let $first-atom (index-atom $list 0) (if (unify $op = True False) (let ($op $st-mid-par $val) (atom-subst $first-atom $var $predicate) (if (== $st-mid-par $val) $first-atom Empty)) (let $subs-atom (atom-subst $first-atom $var $predicate) (if $subs-atom $first-atom Empty)))) Empty)
                    (if (>= (- $length 2) 0) (let $second-atom (index-atom $list 1) (if (unify $op = True False) (let ($op $st-mid-par $val) (atom-subst $second-atom $var $predicate) (if (== $st-mid-par $val) $second-atom Empty)) (let $subs-atom (atom-subst $second-atom $var $predicate) (if $subs-atom $second-atom Empty)))) Empty)
                    (if (>= (- $length 3) 0) (let $third-atom (index-atom $list 2) (if (unify $op = True False) (let ($op $st-mid-par $val) (atom-subst $third-atom $var $predicate) (if (== $st-mid-par $val) $third-atom Empty)) (let $subs-atom (atom-subst $third-atom $var $predicate) (if $subs-atom $third-atom Empty)))) Empty)
                    (if (>= (- $length 4) 0) (let $fourth-atom (index-atom $list 3) (if (unify $op = True False) (let ($op $st-mid-par $val) (atom-subst $fourth-atom $var $predicate) (if (== $st-mid-par $val) $fourth-atom Empty)) (let $subs-atom (atom-subst $fourth-atom $var $predicate) (if $subs-atom $fourth-atom Empty)))) Empty)
                    (if (>= (- $length 5) 0) (let $fifth-atom (index-atom $list 4) (if (unify $op = True False) (let ($op $st-mid-par $val) (atom-subst $fifth-atom $var $predicate) (if (== $st-mid-par $val) $fifth-atom Empty)) (let $subs-atom (atom-subst $fifth-atom $var $predicate) (if $subs-atom $fifth-atom Empty)))) Empty)
                    (if (>= (- $length 6) 0) (let $sixth-atom (index-atom $list 5) (if (unify $op = True False) (let ($op $st-mid-par $val) (atom-subst $sixth-atom $var $predicate) (if (== $st-mid-par $val) $sixth-atom Empty)) (let $subs-atom (atom-subst $sixth-atom $var $predicate) (if $subs-atom $sixth-atom Empty)))) Empty)
                    (if (>= (- $length 7) 0) (let $seventh-atom (index-atom $list 6) (if (unify $op = True False) (let ($op $st-mid-par $val) (atom-subst $seventh-atom $var $predicate) (if (== $st-mid-par $val) $seventh-atom Empty)) (let $subs-atom (atom-subst $seventh-atom $var $predicate) (if $subs-atom $seventh-atom Empty)))) Empty)
                    (if (>= (- $length 8) 0) (let $eigth-atom (index-atom $list 7) (if (unify $op = True False) (let ($op $st-mid-par $val) (atom-subst $eigth-atom $var $predicate) (if (== $st-mid-par $val) $eigth-atom Empty)) (let $subs-atom (atom-subst $eigth-atom $var $predicate) (if $subs-atom $eigth-atom Empty)))) Empty)
                    (if (>= (- $length 9) 0) (let $ninth-atom (index-atom $list 8) (if (unify $op = True False) (let ($op $st-mid-par $val) (atom-subst $ninth-atom $var $predicate) (if (== $st-mid-par $val) $ninth-atom Empty)) (let $subs-atom (atom-subst $ninth-atom $var $predicate) (if $subs-atom $ninth-atom Empty)))) Empty)
                    (if (>= (- $length 10) 0) (let $tenth-atom (index-atom $list 9) (if (unify $op = True False) (let ($op $st-mid-par $val) (atom-subst $tenth-atom $var $predicate) (if (== $st-mid-par $val) $tenth-atom Empty)) (let $subs-atom (atom-subst $tenth-atom $var $predicate) (if $subs-atom $tenth-atom Empty)))) Empty)
                    )
                )
            )
        )
        
    )
)

(= (indexed-cdr-atom $list $index)
    (collapse(
        superpose(
            (if (== 0 $index) Empty (index-atom $list 0))
            (if (== 1 $index) Empty (index-atom $list 1))
            (if (== 2 $index) Empty (index-atom $list 2))
            (if (== 3 $index) Empty (index-atom $list 3))
            (if (== 4 $index) Empty (index-atom $list 4))
            (if (== 5 $index) Empty (index-atom $list 5))
            (if (== 6 $index) Empty (index-atom $list 6))
            (if (== 7 $index) Empty (index-atom $list 7))
            (if (== 8 $index) Empty (index-atom $list 8))
            (if (== 9 $index) Empty (index-atom $list 9))
            (if (== 10 $index) Empty (index-atom $list 10))
            (if (== 11 $index) Empty (index-atom $list 11))
            (if (== 12 $index) Empty (index-atom $list 12))
            (if (== 13 $index) Empty (index-atom $list 13))
            (if (== 14 $index) Empty (index-atom $list 14))
            (if (== 15 $index) Empty (index-atom $list 15))
            (if (== 16 $index) Empty (index-atom $list 16))
        )
    ))
)

(= (provenance-sources $blend-properties)
    (let $props-with-prov (custom-filter-atom $blend-properties $var (> (Method size-atom $var) 1)) (map-atom $props-with-prov $prop (index-atom $prop 1)))
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
