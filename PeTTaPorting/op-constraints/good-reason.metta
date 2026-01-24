!(import! &self ../libs/agents/llm_agent)
!(import! &self "op-helper-codes.py")

(=(is-property-justified $concept $property)
    (let* (
        ($cleaned-concept (if (== (get-metatype $concept) Symbol) $concept (car-atom $concept)))
        ($cleaned-property (if (== (get-metatype $property) Symbol) $property (car-atom $property)))
        ($concept-properties (collapse(match &space (hasProperty $cleaned-concept $var) $var)))
        ($direct (is-list-member $cleaned-property $concept-properties))
    )
    $direct
    )
)

(= (is-provenance-sources-justified $property $provenance-sources)
    (if (== $provenance-sources ())
        0
        (let* (
            ($head (car-atom $provenance-sources))
            ($tail (cdr-atom $provenance-sources))
            )
            (
                if(is-property-justified ($property) $head)
                1
                (is-provenance-sources-justified $property $tail)
            )
        )
    )
)


(= (conceptnet-justification-helper $prop $blend)
    (let ($blend-name $unwrapped-prop) ((blend-name $blend) (car-atom $prop))
        (if (is-property-justified $unwrapped-prop $blend-name)
            1
            (is-provenance-sources-justified $unwrapped-prop (provenance-sources (properties-list $blend)))
        )
    )

)

(= (conceptnet-justification $properties $blend) 
    (let $justfications (map-atom $properties $prop (conceptnet-justification-helper $prop $blend)) $justfications)
)

(= (default-prompt $properties $blend $context)
   (
    Evaluate the properties $properties in the blend concept $blend . \n
    **Context:** $context \n \n
    **Instructions:** \n
    Please respond only in JSON format with the following fields: \n

    result: a space-separated list of 1's and 0's enclosed in parentheses. Each position corresponds to the properties listed in the first sentence above (the $properties list), not the ones in the context. \n
        - 1 = the property is justified in the blend. \n
        - 0 = the property is not justified. \n

    reason: a brief explanation supporting the justification pattern in result.
    **Formatting rules:**
    1. The result must be exactly in the form: "(1 0 1 0 ...)", No Python lists, commas, or other formats.
    2. The number of entries in result must exactly match the number of properties in $properties .
    3. The justification in reason must match the pattern in result.

    **Example**
    {
        "result": "(1 0 1 0 1 1 1 0)",
        "reason": "The first, third, fifth, sixth, and seventh properties logically follow from the combination of the source concepts, while the others do not."
    }
   )
)


(= (blend-context $blend)
        (let* (
            ($props (properties-list $blend))
            ($blend-relations (relations-key-value-list $blend))
            ($property-name-list (map-atom $props $x (car-atom $x)) )
            ($mapRelations (map-atom $blend-relations $rel ((car-atom $rel) → (index-atom $rel 1))))
            ($provenance-sources(provenance-sources $props))
            
            )
            (
                Properties: $property-name-list \n
                Relations: $mapRelations \n
                Sources: $provenance-sources \n
            )
        )
    
)



(= (llm-justification $properties $blend)
    (let ($blend-name $blend-context) ((blend-name $blend) (blend-context $blend)) 
        (let $default-prompt (default-prompt $properties $blend-name $blend-context) 
            ; (good-reason-llm $default-prompt)
            (useGPT (py-str $default-prompt))
        )
    )
)

(= (count-justified $emergents-list $blend)
    (if (== $emergents-list ())
        0
        (let* 
            (
                ($llm-justification (llm-justification $emergents-list $blend))
                ($llm-result (py-call (op-helper-codes.llm_result ($llm-justification))))

                ($sum-op-llm-justification (sum-op $llm-result))
                ($conceptnet-justification (conceptnet-justification $emergents-list $blend))
                ($sum-op-conceptnet-justification (sum-op $conceptnet-justification))

            )
            (
                $sum-op-conceptnet-justification $sum-op-llm-justification
            )
        )
    )
)


(= (good-reason-op $blend)
    (let* 
        (
            ($blend-properties (properties-list $blend))
            ($emergents (custom-filter-atom $blend-properties  (Method <= size-atom 1)))
            ($emergent-count (size-atom $emergents))
        )
        (
            if (== $emergent-count 0)
            1.0
            (let $justified-counts (count-justified $emergents $blend)
                (let ($conc-net-score $llm-score) (map-atom $justified-counts $count (/ $count $emergent-count)) (Conceptnet-score $conc-net-score LLM-score $llm-score))
            )
        )
    )
)
