;; Requires ExtractorV1ScoringLayer (score-concept-triple) and WorldContextTV
;; (world-pairs-tv), both imported before this file by PropertyWorldDataLayer.

(= (property-pairs-tv $concept $pairs)
   (if (== $pairs ())
       ()
       (let* (($pair (car-atom $pairs))
              ($propName (car-atom $pair))
              ($degree (score-concept-triple $concept hasProperty $propName)))
          (cons-atom ($propName $degree) 
                     (property-pairs-tv $concept (cdr-atom $pairs))))))

(= (attach-tv-to-pairs $concept $pList $tList)
    (if (or (== $pList ()) (== $tList ()))
        ()
        (let* (($pHead (car-atom $pList))
               ($tHead (car-atom $tList))
               ;; Extract property and worlds from pList
               ($wrappedProp (car-atom $pHead))
               ($prop (car-atom $wrappedProp))
               ($worlds (car-atom (cdr-atom $pHead)))
               ;; Extract truth value from tList
               ($tv (car-atom (cdr-atom $tHead)))
               ;; Evaluate the worlds
               ($scoredWorlds (world-pairs-tv $concept $prop $worlds))
               ($propPair (($prop) $tv)))
            (cons-atom (cons-atom $propPair (cons-atom $scoredWorlds ()))
                       (attach-tv-to-pairs $concept (cdr-atom $pList) (cdr-atom $tList))))))