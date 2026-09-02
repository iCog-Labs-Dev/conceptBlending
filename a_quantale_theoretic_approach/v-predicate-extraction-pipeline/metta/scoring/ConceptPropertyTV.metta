!(import! &self metta/scoring/ExtractorV1ScoringLayer)

(= (property-pairs-tv $concept $pairs)
   (if (== $pairs ())
       ()
       (let* ((($propName $perspective) (car-atom $pairs))
              ($degree (score-concept-triple $concept hasProperty $propName))
              ($rest (property-pairs-tv $concept (cdr-atom $pairs))))
          (cons-atom ($propName $degree) $rest))))
