;;define the type of concept

(: concept Concept)
 ;;function that takes a concept and returns the number of properties that represent it.
 ;;parameter: concept
 ;;return: number of properties
(: get-number-of-properties (-> Concept Number))
(=(get-number-of-properties $concept)
    (
        let*(
            
                ($a $concept)
                ($b (superpose $a))
    )
    (if (== (get-metatype $b) Expression)
        (let $c (cdr-atom $b)
            (size-atom $c))
        (empty)
    )
        )
    )

;!(get-number-of-properties (Concept Spider@Man (Property (web-creation 1.0) (intelligence 0.4) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
;;retruns 8