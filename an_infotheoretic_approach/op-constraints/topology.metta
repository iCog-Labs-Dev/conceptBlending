! (import! &self libs)
; ! (import! &self common-utils)

(= (similarity_threshold) 0.15)

(= (find-similar-known-relation $rel $knowns)
   (if (== (size-atom $knowns) 0)
       ()
       (let* (
           ($head (car-atom $knowns))
           ($tail (cdr-atom $knowns))
           ($type-similarity (let ($rel-type $known-head-type) ((car-atom $rel) (car-atom $head)) (get-similarity-score $rel-type $known-head-type)))
           ($target-similarity (let ($rel-target $known-head-target) ((index-atom $rel 1) (index-atom $head 1)) (get-similarity-score $rel-target $known-head-target)))
         )
         (if (and (> $type-similarity (similarity_threshold)) (> $target-similarity (similarity_threshold)))
            $head
             (find-similar-known-relation $rel $tail)
        )
        )
    )
)


(= (normalize-relation $rel $knowns)
    (let $match (find-similar-known-relation $rel $knowns)
        (if (== (size-atom $match) 0)
        ($rel (cons-atom $rel $knowns))
        ($match $knowns)
        )
    )
)

; !(normalize-relation (RelatedTo hitting) ((RelatedTo hitting) (RelatedTo bird)))

; (= (source-relations-normalizer $source-relations $knowns)
;     (function
;         (chain (decons-atom $source-relations) $ht
;             (unify ($head $tail) $ht
;                 (chain (eval (normalize-relation $head $knowns)) $res
;                     (chain (eval (source-relations-normalizer $tail $upd-knowns)) $tail-res
;                         (chain (cons-atom $norm $tail-res) $res (return $res))
;                     )
;                 )
;                 (return ())
;             )
;         )
;     )
; )

(= (source-relations-normalizer $source-relation $knowns)
    (if (== (size-atom $source-relation) 0)
        ($knowns)
        (let*
            (
                ($sr-head (car-atom $source-relation))
                ($sr-tail (cdr-atom $source-relation))
                (($norm $upd-knowns) (normalize-relation $sr-head $knowns))
                ($tail-res (source-relations-normalizer $sr-tail $upd-knowns))
            )
            (cons-atom $norm $tail-res)
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

(= (topology-op $blend $concept1 $concept2)
    (let*(
       ($concept1-relations-list (relations-key-value-list $concept1))
        ($concept2-relations-list (relations-key-value-list $concept2))
        ($un-norm-source-relations (union-atom $concept1-relations-list $concept2-relations-list))
        (($source-relations $knowns) (let $result (source-relations-normalizer $un-norm-source-relations ()) (let ($source-relations-res $knowns-res) ((indexed-cdr-atom $result (- (size-atom $result) 1)) (index-atom $result (- (size-atom $result) 1))) ((unique-atom $source-relations-res) $knowns-res))))
        ($source-relations-size (size-atom $source-relations))
        ($blend-relations-list (relations-key-value-list $blend))
        ($preserved-count (count-preserved-loop $blend-relations-list $source-relations $knowns))

        ($source-relations-size-decimal (to-float-op $source-relations-size))
        ($preservation-score (/ $preserved-count $source-relations-size-decimal))
        )
        $preservation-score
    )
)

; ! (topology-op (good_blend) (op-concept1) (op-concept2))
