!(import! &self "utils/semantic_coorelation.py")


(=(semantic-correlation $properties $degrees)
    (let* (
    ($result (py-call (semantic_coorelation.semantic_similarity $properties $degrees)))
)
    $result
))
