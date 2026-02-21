!(import! &self "utils/semantic_coorelation.py")


(=(semantic-correlation $properties $degrees)
    (let* (
    ($result (py-call (semantic_coorelation.semantic_similarity $properties $degrees)))
)
    $result
))


(= (concept-relations) (isA relatedTo hasProperty atLocation synonym capableOf antonym partOf hasA atLocation))

; Returns a list of relation expressions like (isa feline) (hasa whiskers) ...
(= (get-concept-relations $concept $space $n)
    (let $relations (concept-relations) 
        (let $result (map-atom $relations $relation (first-n-elements (collapse(match $space ($relation $concept $target) ($relation $target))) $n))
            (let $fresult (foldl-atom $result () $acc $x (union-atom $acc $x)) (unique-atom $fresult))
        )
    )
)

(= (format-result $target $text $rel $concept)
   (if (== $text nA)
       ($concept $rel $target)
       ($concept $rel $target $text)
   )
)

(= (fetch-context $concept $space $n)
    (let $relations (concept-relations) 
        (let $result (map-atom $relations $relation (first-n-elements (collapse(match $space (surfaceText ($relation $concept $target) $text) (format-result $target $text $relation $concept))) $n))
            (let $fresult (foldl-atom $result () $acc $x (union-atom $acc $x)) (unique-atom $fresult))
        )
    )
)

;; ==========================================
;;  Property Comparison Helper
;; ==========================================
;; Extracts property at index from both inputs and returns the winner.
;; Format returned: (WinnerName PropName WinnerValue)
(= (compare-concepts-prop-val ($input1 $props1) ($input2 $props2) $index)
   (let* (($p1 (index-atom $props1 $index))
          ($p2 (index-atom $props2 $index))
          ($prop-name (car-atom $p1))
          ($v1 (index-atom $p1 1))
          ($v2 (index-atom $p2 1)))
     (if (>= $v1 $v2) 
         ($input1 $prop-name $v1) 
         ($input2 $prop-name $v2))))

;; ==========================================
;; Provenance Implementation
;; ==========================================

(= (provenance-helper ($input1 $concept1props) ($input2  $concept2props) ($blend $blendprops))   
   (provenance-recursive ($input1 $concept1props) ($input2  $concept2props) $blendprops 0)
)

(= (provenance-recursive ($input1 $concept1props) ($input2  $concept2props) $blendprops $idx)
   (if (>= $idx (size-atom $blendprops))
       () 
       (let* 
            (
                (($gcn $gcp $gcpv) (compare-concepts-prop-val ($input1 $concept1props) ($input2  $concept2props) $idx))
                ($blend-prop (index-atom $blendprops $idx))
                ($blend-prop-name (car-atom $blend-prop))
                ($blend-prop-val  (index-atom $blend-prop 1))
                ($current-entry (if (>= $blend-prop-val $gcpv) 
                                    ($blend-prop-name) 
                                    ($blend-prop-name ($gcn))))
                ($rest (provenance-recursive ($input1 $concept1props) ($input2  $concept2props) $blendprops (+ $idx 1)))
            )
            (cons-atom $current-entry $rest)
       )
    )
)

(= (prepare-network-call $str2)
    (py-call (operator.add gpt_agents. $str2))
)
