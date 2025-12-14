!(import! &self "utils/semantic_coorelation.py")




; !(semantic-coorelation (intelligence physical-strength agility) (0.3 0.7 0.6))

; !(py-call (semantic_coorelation.semantic_similarity
;            (web-creation intelligence physical-strength)
;             (0.3 0.7 0.6)
;            )
;            )

(=(semantic-coorelation $properties $degrees)
    (let* (
    ($result (py-call (semantic_coorelation.semantic_similarity $properties $degrees)))
)
    $result
))

!(semantic-coorelation (intelligence physical-strength agility) (0.3 0.7 0.6))
