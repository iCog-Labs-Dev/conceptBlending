;; Requires ExtractorV1ScoringLayer (score-triplet), imported once by PropertyWorldDataLayer.

(= (concept-property-composite $concept $propName)
    (py-call
        (operator.add
            (py-call
                (operator.add
                    (py-call (str $concept))
                    "_"))
            (py-call (str $propName)))))

(= (world-composite $world)
    (py-call
        (operator.add
            (py-call (str $world))
            "_world")))

(= (world-pairs-tv $concept $prop $worlds)
    (if (== $worlds ())
        ()
        (let* (($pair (car-atom $worlds))
               ($world (car-atom $pair)))
            (if (== $world $concept)
                (cons-atom ($world)
                           (world-pairs-tv $concept $prop (cdr-atom $worlds)))
                (let* (($source (concept-property-composite $concept $prop))
                       ($target (world-composite $world))
                       ($degree (score-concept-triple  $source hasContext $target)))
                    (cons-atom (($world) $degree)
                               (world-pairs-tv $concept $prop (cdr-atom $worlds))))))))