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

(= (prepare-network-call $str2)
    (py-call (operator.add gpt_agents. $str2))
)
