;;this is an attempt for a formal computation of blending using info-theoretic measures and intensional theory

;;define the type of concept
(: Concept Concept)
 ;;function that takes a concept and returns the number of properties that represent it.
 ;;parameter: concept
 ;;return: number of properties

; !(let $q (cdr-atom (InputSpaces (Concept Spider@Man (Property (Legs 1.0) (Intelligence 0.2) (WebBuilding 1.0) (SocialStructure 0.1) (PredatoryBehavior 1.0) (Communication 0.2) (Symbolism 0.5) (PhysicalStrength 0.1))) (Concept Man@Spider (Property (Legs 0.1) (Intelligence 1.0) (WebBuilding 0.0) (SocialStructure 1.0) (PredatoryBehavior 0.3) (Communication 1.0) (Symbolism 0.8) (PhysicalStrength 0.7))))) (car-atom $q))


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

!(get-number-of-properties (Concept Spider@Man (Property (web-creation 1.0) (intelligence 0.4) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
;;retruns 8


;;function that takes a concept and returns the probability of each property that represents it.
;;parameter: concept
;;returns: probability of each property
(: property-probability (-> Concept Number))

(=(property-probability $concept)
    (let*(
        ($numberofprops (get-number-of-properties $concept))
        ($probability (/ 1.0 $numberofprops))
    )
    $probability
    )
    )

!(property-probability (Concept Spider@Man (Property (web-creation 1.0) (intelligence 0.4) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
;;returns 0.125


;;function that returns property degree of a given concept
;;parameter:conceot
;;returns: property degree
(: property-degree (-> Concept Number))
(=(property-degree $concept)
    (let*(
        ($probability (property-probability $concept))
        ($degree (* -1 (log-math 10 $probability)))
    )
    $degree
    )
)

!(property-degree (Concept Spider@Man (Property (web-creation 1.0) (intelligence 0.4) (physical-strength 0.6) (mobility 0.8) (predatory-behavior 1.0) (social-structure 0.2) (symbolism 0.7) (tool-use 0.1))))
;;returns 0.9030899869919434
