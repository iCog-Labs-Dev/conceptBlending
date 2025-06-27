!(register-module! ../libs)
! (import! &self libs)
! (import! &self common-utils)


(= (emergents-filter ())
   ())
(= (emergents-filter $items)
    (let* (
        ($head (car-atom $items))
        ($tail (cdr-atom $items))
    )
       (if (== (size-atom $head) 1)
       (let* (
            ($next-emergent (emergents-filter $tail))
        )
        (cons-atom $head $next-emergent)
       )
        (emergents-filter $tail)
       )
    
    )
)


(= (is-provenance-sources-justified $property $provenance-sources)
    (if (== $provenance-sources ())
        False
        (let* (
            ($head (car-atom $provenance-sources))
            ($tail (cdr-atom $provenance-sources))
            )
            (
                if(is_property_justified ($property) $head)
                True
                (is-provenance-sources-justified $property $tail)
            )
        )
    )
)


(= (conceptnet-justification $property $blend) 
       (if(is_property_justified $property (blend-name $blend))
        True
        (is-provenance-sources-justified $property (provenance-sources (properties-list $blend)))
       )

)

(= (blend-context $blend)
        (let* (
            ($props (properties-list $blend))
            ($blend-relations (relations-key-value-list $blend))
            ($blend-relations-inner (car-atom $blend-relations))

            ($property-name-list (map-atom $props $x (car-atom $x)) )
            ($mapRelations (map-atom $blend-relations-inner $rel ((car-atom $rel) → (index-atom $rel 1))))
            ($provenance-sources(provenance-sources $props))
            
            )
            (
                Properties: $property-name-list \n
                Relations: $mapRelations \n
                Sources: $provenance-sources \n
            )
        )
    
)

(= (default-prompt $property $blend $context)
   (
      Evaluate the property $property in the blend concept $blend :\n
      $context \n\n
      Please provide a JSON response with the following fields:\n
      - justified: boolean (true if the property is justified in the blend)\n
      - reason: a brief explanation supporting the justification\n\n
      Example response:\n
      {\n
        \justified\: true,\n
        \reason\: \The property logically follows from the combination of the source concepts.\\n
      }
   )
)

(= (is-justified $property $blend)
   (if (conceptnet-justification $property $blend)
       True
       (good_reason_llm (default-prompt $property (blend-name $blend) (blend-context $blend)))
   )
)

(= (count-justified $emergents_list $blend)
    (if (== $emergents_list ())
        0
        (let* (($head (car-atom $emergents_list))
               ($tail (cdr-atom $emergents_list))
               ($is-just (is-justified (car-atom $head) $blend))
               ($rest-count (count-justified $tail $blend)))
            (if $is-just
                (+ 1.0 $rest-count) ; 1.0 to ensure float
                $rest-count
            )
        )
    )
)
(= (good_reason_op $blend)
  (let* (
    ($blend-properties (properties-list $blend))
    ($emergents (emergents-filter $blend-properties)) ; TODO: should be replaced by filter-atom
    ($emergent-count (size-atom $emergents))
  )
    (if (== $emergent-count 0)
        1.0
        (let* (($justified-count (count-justified $emergents $blend))
               ($score (/ $justified-count $emergent-count)))
              $score
        )
    )
  )
)

! (good_reason_op (good_blend))