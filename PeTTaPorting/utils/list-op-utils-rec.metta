;; ==========================================
;; 1. LIST MATH & COMPARISON
;; ==========================================

;; Element-wise multiplication of two lists, tagged with properties
(= (list-multiply $candidatedegreeval $propertiesvalues $properties)
   (if (or (== $properties ()) (or (== $propertiesvalues ()) (== $candidatedegreeval ()))) 
       ()
       (let* (($p (car-atom $properties))
              ($c (car-atom $candidatedegreeval))
              ($v (car-atom $propertiesvalues))
              ($mult (* $c $v))
              ($rest (list-multiply (cdr-atom $candidatedegreeval) (cdr-atom $propertiesvalues) (cdr-atom $properties))))
             (cons-atom ($p $mult) $rest))))

;; Element-wise minimum of two value lists
(= (min-elements $v1_list $v2_list $props)
   (if (or (== $props ()) (or (== $v1_list ()) (== $v2_list ()))) 
       ()
       (let* (($p (car-atom $props))
              ($v1 (car-atom $v1_list))
              ($v2 (car-atom $v2_list))
              ($minval (min-atom ($v1 $v2)))
              ($rest (min-elements (cdr-atom $v1_list) (cdr-atom $v2_list) (cdr-atom $props))))
             (cons-atom ($p $minval) $rest))))

;; Element-wise maximum of two value lists
(= (max-elements $v1_list $v2_list $props)
   (if (or (== $props ()) (or (== $v1_list ()) (== $v2_list ()))) 
       ()
       (let* (($p (car-atom $props))
              ($v1 (car-atom $v1_list))
              ($v2 (car-atom $v2_list))
              ($maxval (max-atom ($v1 $v2)))
              ($rest (max-elements (cdr-atom $v1_list) (cdr-atom $v2_list) (cdr-atom $props))))
             (cons-atom ($p $maxval) $rest))))

;; Element-wise subtraction with a floor of 0
(= (list-subtract $cand_list $val_list $props)
   (if (or (== $props ()) (or (== $val_list ()) (== $cand_list ()))) 
       ()
       (let* (($p (car-atom $props))
              ($c (car-atom $cand_list))
              ($v (car-atom $val_list))
              ($diff (- $c $v))
              ($final (if (< $diff 0) 0 $diff))
              ($rest (list-subtract (cdr-atom $cand_list) (cdr-atom $val_list) (cdr-atom $props))))
             (cons-atom ($p $final) $rest))))

;; ==========================================
;; 2. LIST TRANSFORMATION
;; ==========================================

;; Pairs elements from two lists: (1 2) (A B) -> ((1 A) (2 B))

(= (zip-list $l1 $l2)
   (if (and (== $l1 ()) (== $l2 ())) 
       (Error (zip-list () ()) EmptyList) 
       (if (not (== (size-atom $l1) (size-atom $l2))) 
           (Error (zip-list $l1 $l2) LengthMismatch)
           (zip-helper $l1 $l2)
       )
   )
)

(= (zip-helper () ()) ()) ;; Pure base case allows list to close
(= (zip-helper $l1 $l2)
   (let* (
       ($h1 (car-atom $l1))
       ($h2 (car-atom $l2))
       ($rest (zip-helper (cdr-atom $l1) (cdr-atom $l2)))
   )
   (cons-atom ($h1 $h2) $rest)
   )
)

;; Separates list of pairs: ((A 1) (B 2)) -> ((A B) (1 2))

(= (unzip-list $list)
   (if (== $list ())
       (Error () EmptyList)
       (unzip-helper $list)
   )
)


(= (unzip-helper ()) (() ()))
(= (unzip-helper $list)
   (let* (
       ($pair (car-atom $list))
       ($left (index-atom $pair 0))
       ($right (index-atom $pair 1))
       (($r-left $r-right) (unzip-helper (cdr-atom $list)))
   )
   ((cons-atom $left $r-left) (cons-atom $right $r-right))
   )
)


;; Tail-Recursive Reverse
(= (reverse-list $list) (reverse-helper $list ()))
(= (reverse-helper () $acc) $acc)
(= (reverse-helper $list $acc)
   (reverse-helper (cdr-atom $list) (cons-atom (car-atom $list) $acc)))


;; Merges two lists (Append l1 to the front of l2)
(= (merge-list () $l2) $l2)
(= (merge-list $l1 $l2)
   (let* (
       ($head (car-atom $l1))
       ($tail (cdr-atom $l1))
       ($rest (merge-list $tail $l2))
   )
   (cons-atom $head $rest)
   )
)


;; ==========================================
;; 3. FILTERING & SEARCHING
;; ==========================================

;; Removes all instances of $val from $list
(= (remove-list-element () $val) ())
(= (remove-list-element $list $val)
    (let* (($head (car-atom $list))
           ($tail (cdr-atom $list))
           ($res (remove-list-element $tail $val))) 
    (if (== $head $val)
        $res 
        (cons-atom $head $res))))


;; Returns a list excluding all occurrences of val

(= (filter-list $list $val)
   (collapse (check-equality $val (superpose $list))))
(= (check-equality $val $target) (if (== $val $target) (empty) $target))

;; Logic checks
(= (all-true ()) True)
(= (all-true $list)
   (if (== (car-atom $list) True) (all-true (cdr-atom $list)) False))

(= (any-true ()) False)
(= (any-true $list)
   (if (== (car-atom $list) True) True (any-true (cdr-atom $list))))

;; Applies sign element-wise: comparelists (1 5) (2 4) > -> (False True)
(= (compare-lists $list1 $list2 $sign)
   (if (or (== $list1 ()) (== $list2 ()))
       ()
       (let* (($h1 (car-atom $list1)) ($t1 (cdr-atom $list1))
              ($h2 (car-atom $list2)) ($t2 (cdr-atom $list2))
              ($head-res ($sign $h1 $h2))
              ($tail-res (compare-lists $t1 $t2 $sign)))
             (cons-atom $head-res $tail-res))))
        
;; Returns True if all elements in list match firstelem, else False
(= (check-all-equal () $firstelem) True)
(= (check-all-equal $list $firstelem)
   (let* (($head (car-atom $list))
          ($tail (cdr-atom $list)))
         (and (== $head $firstelem) (check-all-equal $tail $firstelem))))

;; Test: (check-all-equal (1 1 1) 1) -> True
;; ==========================================
;; 4. GENETIC ALGORITHM / SPACE UTILS
;; ==========================================


;; Get single individual by fitness from space
(= (match-single-individual $space $max)
   (let $inds (collapse (match $space (Individual $x $max) $x))
        (if (== $inds ()) () (car-atom $inds))))

;; Select top N individuals
(= (elite-individuals $list $space $n)
   (if (or (<= $n 0) (== $list ())) ()
       (let* (($max (max-atom $list))
              ($best (match-single-individual $space $max))
              ($rest_list (remove-list-element $list $max))
              ($others (elite-individuals $rest_list $space (- $n 1))))
             (cons-atom $best $others))))

;; Populate space from list
(= (add-list-to-space () $space) ())
(= (add-list-to-space $list $space)
   (let* (($entry (car-atom $list))
          ($_ (add-reduct $space (Individual $entry))))
         (add-list-to-space (cdr-atom $list) $space)))

;; ==========================================
;; 5. MATH & MISC
;; ==========================================

;; Truncate to N decimal places
(= (truncate $num $dec)
   (let $mult (pow-math 10 $dec)
        (/ (trunc-math (* $num $mult)) $mult)))

;; Generates list of N ones
(= (generate-toy-list $n)

    (if (<= $n 0)
        ()  
        (let* 
             (($rest (generate-toy-list (- $n 1))))
             (cons-atom 1 $rest) 
        )
    )
)

