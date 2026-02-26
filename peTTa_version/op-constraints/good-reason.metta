; !(import! &self libs/agents/llm_agent)
; !(import! &self "op-constraints/op-helper-codes.py")

(= (gr-similarity-checker $concept1 $concept2 $threshold)
    (let $sim-val (py-call (op-helper-codes.compute_average_pairwise_similarity ($concept1 $concept2)))
        (if (>= $sim-val $threshold) True False)
    )
)

(=(is-property-justified $property $concept)
    (let* (
        ($cleaned-concept (if (== (get-metatype $concept) Symbol) $concept (car-atom $concept)))
        ($cleaned-property (if (== (get-metatype $property) Symbol) $property (car-atom $property)))
        ($concept-properties (get-concept-relations-op $cleaned-concept &space 5 hasProperty))
        ($direct (let $props-justification (map-atom $concept-properties $prop (gr-similarity-checker (index-atom $prop 1) $cleaned-property (gd-sim-threshold))) (is-list-member True $props-justification)))
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
                if (is-property-justified $property $head)
                1
                (is-provenance-sources-justified $property $tail)
            )
        )
    )
)


(= (conceptnet-justification-helper $prop $blend $blend-props-prov)
    (let ($blend-name $unwrapped-prop) ((blend-name $blend) (car-atom $prop))
        (if (is-property-justified $unwrapped-prop $blend-name)
            1
            (is-provenance-sources-justified $unwrapped-prop (provenance-sources $blend-props-prov))
        )
    )

)

(= (conceptnet-justification $properties $blend $blend-props-prov) 
    (let $justfications (map-atom $properties $prop (conceptnet-justification-helper $prop $blend $blend-props-prov)) $justfications)
)

(= (blend-context $blend $blend-props-prov)
    (let* (
        ($props (properties-list $blend))
        ($blend-relations (relations-key-value-list $blend))
        ($property-name-list (map-atom $props $x (car-atom $x)) )
        ($mapRelations (map-atom $blend-relations $rel ((car-atom $rel) → (index-atom $rel 1))))
        ($provenance-sources (provenance-sources $blend-props-prov))
        
        )
        (
            Properties: $property-name-list
            Relations: $mapRelations
            Sources: $provenance-sources
        )
    )
)



(= (llm-justification $properties $blend $blend-props-prov)
    (let ($blend-name $blend-context) ((blend-name $blend) (blend-context $blend $blend-props-prov)) 
        (eval (py-call (gpt_agents.gpt_good_reason $blend-name $properties $blend-context))) 
    )
)

(= (count-justified $props-list $blend $blend-props-prov)
    (if (== $props-list ())
        0
        (let* 
            (
                ($llm-justification (llm-justification $props-list $blend $blend-props-prov))
                ($llm-result (py-call (op-helper-codes.llm_result ($llm-justification))))
                ($sum-op-llm-justification (sum-op $llm-result))
                ($conceptnet-justification (conceptnet-justification $props-list $blend $blend-props-prov))
                ($sum-op-conceptnet-justification (sum-op $conceptnet-justification))
            )
            (
                $sum-op-conceptnet-justification $sum-op-llm-justification
            )
        )
    )
)


(= (good-reason-op $blend $concept1 $concept2)
    (let* 
        (
            (($blend-props $c1-props $c2-props) (collapse(superpose((properties-list $blend) (properties-list $concept1) (properties-list $concept2)))))
            (($input1 $input2) ((blend-name $concept1) (blend-name $concept2)))
            ($blend-props-with-prov (provenance-helper ($input1 $c1-props) ($input2 $c2-props) $blend-props))
            ($blend-props-above-threshold (greater-than-threshold-props $blend-props (gd-threshold)))
            ($blend-props-above-threshold-count (size-atom $blend-props-above-threshold))
        )
        (
            if (== $blend-props-above-threshold-count 0)
            0.0
            (let $justified-counts (count-justified $blend-props-above-threshold $blend $blend-props-with-prov)
                (let ($conc-net-score $llm-score) (map-atom $justified-counts $count (/ $count $blend-props-above-threshold-count)) (Conceptnet-score $conc-net-score LLM-score $llm-score))
            )
        )
    )
)

(= (gd-threshold) 0.5)
(= (gd-sim-threshold) 0.15)
