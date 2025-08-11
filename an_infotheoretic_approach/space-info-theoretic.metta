; !(import! &self libs)
!(bind! &concept-space (new-space))
; !(bind! &generic-space (new-space))
; !(bind! &blended-space (new-space))


(= (add-data $data $space $external-space)
    (
        ((py-atom libs.to_file) (py-tuple ($external-space $data)))
        (add-reduct $space (Concept $data))
    )
)

(= (add-inputs-space $input1 $input2)
    (collapse(superpose((add-atom &self (= (space-Input1) $input1)) (add-atom &self (= (space-Input2) $input2)))))
)

(= (n-concepts $list $amount)
    (function
        (chain (eval (== $amount 0)) $tf
            (unify $tf False
                (chain (decons-atom $list) $ht
                    (unify ($head $tail) $ht
                        (chain (eval (- $amount 1)) $upd-amount
                            (chain (eval (n-concepts $tail $upd-amount)) $tail-res
                                (chain (cons-atom $head $tail-res) $res (return $res))
                            )
                        )
                        (return ())
                    )
                )
                (return ())
            )
        )
    )
)

(= (get-concepts $amount)
    (let $concepts (collapse(get-atoms &concept-space))
        (let $uni-concepts (unique-atom $concepts)
            (n-concepts $uni-concepts $amount)
        )
    )
)

(= (add-space-concepts)
    (let ($concept1 $concept2) (vec-extraction (space-Input1) (space-Input2))
        (collapse(superpose((add-atom &self (= (concept1) $concept1)) (add-atom &self (= (concept2) $concept2)))))
    )
)

;;;; Load the stored concepts from knowledge base

!(load-ascii &concept-space data/kb_concepts.metta)

;;;; space based blending function ;;;;
(= (space-blend $blend $GAorCMA $eval)
        (let $concepts (get-concepts 2)
            (let ($concept1 $concept2) $concepts
                (let ($input1 $input2) ((index-atom $concept1 1) (index-atom $concept2 1))
                    (let $added-inputs (add-inputs-space $input1 $input2)
                        (let $added-concepts (add-space-concepts)
                            ($blend $GAorCMA $eval)
                        )
                    )
                )
            )
        )
)
