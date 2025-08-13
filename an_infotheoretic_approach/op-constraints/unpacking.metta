! (import! &self libs)
; ! (import! &self common-utils)


(= (evaluate-property ($prop-name $provenance-list) $blend-name)
   (if (== (size-atom $provenance-list) 0)
       0.0
       (let $expanded-provenance (if (expansion-enabled) (get-expand-provenance $provenance-list) ($provenance-list)) (provenance-strength $prop-name $expanded-provenance $blend-name))           
    )
)

(= (provenance-strength $prop-name $provenance-list $blend-name)
    (let $scores (map-atom $provenance-list $source-expr (calculate-source-strength $prop-name $source-expr $blend-name))
        (let $max-score (max-in-list $scores)
            (if (> $max-score (min-similarity)) $max-score 0.0)
        )
    )
)

(= (calculate-source-strength $prop-name $source-expr $blend-name)
    (let $source-word (car-atom $source-expr)
        (if (== $source-word $blend-name) 1
            (let ($similarity $is-related) ((get-similarity-score $prop-name $source-word) (are-related $prop-name $source-word)) 
                (if $is-related (max-aton ($similarity 0.8)) $similarity)
            )
        )
    )
)

(= (unpacking-op $good-blend )
    (let ($props $blend-name) ((properties-list $good-blend) (blend-name $good-blend))
        (let $mapped-props (map-atom $props $prop  (if (> (size-atom $prop) 1) $prop ((car-atom $prop) ())))
            (let $scores (map-atom $mapped-props $p (evaluate-property $p $blend-name))
                (let $prop-size (size-atom $props) (if (> $prop-size 0) (/ (sum-op $scores) $prop-size) 0.0))
            )
        )
    )
)

(= (expansion-enabled) True )
(= (min-similarity) 0.1)

; ! (unpacking-op (good_blend))