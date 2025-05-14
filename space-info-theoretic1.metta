! (register-module! ../../conceptBlending)
! (import! &self conceptBlending:libs)
! (import! &self info-theoretic)



; metta function to add given expressions to space and file(external file)
(= (add-data $data $space $external-space)
    (
        ((py-atom conceptual_blending.to_file) (py-tuple ($external-space $data)))
        (add-reduct $space $data)
    )
)
; ! (add-data (Concept Bater) &self "../kb_concepts.metta")


; --------------------------------------
; ;; Load the stored concepts from knowledge base
! (import! &input-space kb_concepts)


! (add-data (Concept Bat) &input-space "../kb_concepts.metta")
! (add-data (Concept Man) &input-space "../kb_concepts.metta")
! (add-data (Concept Spider) &input-space "../kb_concepts.metta")
; ! (add-data (Concept House) &input-space "../kb_concepts.metta")
; ! (add-data (Concept Music) &input-space "../kb_concepts.metta")

; ! (match &input-space (Concept $x) $x)



; --------------------------------------
! (import! &generic-space kb_generic_space)
! (import! &blended-space kb_blended_space)


; metta function to blend given inputs and populate generic and blended spaces
(= (blend_to_space $input1 $input2)
    (if (not (== $input1 $input2))
        (let*(
            ($concepts (gpt_vector $input1 $input2))
            ($concept1 (car-atom $concepts))
            ($wrapped-concept2 (cdr-atom $concepts))
            ($concept2 (car-atom $wrapped-concept2))
            ($degree (property-degree $concept1))
            ($max (property-max $concept1 $concept2))
            ($calculated-mu-emergence (mu-emergence $degree $max))
            ($min (property-min $concept1 $concept2))
            ($calculated-mu-hqblend (mu-hqblend $calculated-mu-emergence $min))
            ($unwrapped-concepts (cdr-atom $concept1))
            ($concept-pair (car-atom $unwrapped-concepts))
        )
            (if (> $calculated-mu-hqblend 0)
                (let*(
                    ($network (gpt_network_selector $concept-pair))
                )
                    (if (not (noreduce-eq $network None))
                        (let*(
                            ($blended ($network $concept-pair $calculated-mu-emergence))
                        )
                            (
                                (add-data $concept1 &generic-space "../kb_generic_space.metta")
                                (add-data $concept2 &generic-space "../kb_generic_space.metta")
                                (add-data $blended &blended-space "../kb_blended_space.metta")
                            )
                        )
                        (empty)
                    )
                )
                (empty)
            )
        )
        (empty)
    )
)
; ! (blend_to_space Bat Man)


; metta function to blend all atoms in a given lists
(= (blend_from_lists $list1 $list2)
    (blend_to_space $list1 $list2)
)


; metta function to blend all atoms in given space
(= (blend_from_space $space)
    (let*(
        ($list-of-inputs1 (match $space (Concept $x) $x))
        ($list-of-inputs2 (match $space (Concept $y) $y))
    )
        (blend_from_lists $list-of-inputs1 $list-of-inputs2)
    )
)
! (blend_from_space &input-space)
