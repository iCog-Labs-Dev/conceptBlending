
(= (length ()) 0)
(= (length $x) (+ 1 (length (cdr-atom $x))))

(= (head $list) (car-atom $list))

(: toFloat (-> Number Number))
(= (toFloat $x) (- (+ $x 0.1) 0.1))

(= (sum ()) 0.0)
(= (sum $lst) (+ (head $lst) (sum (cdr-atom $lst))))




(= (jaccard-distance $set1 $set2)
   (let* (
           ($inter  (length (intersection-atom $set1 $set2)))
           (() (println! $inter))
           ($union1 (length (union-atom $set1 $set2)))
           ($union2 (- $union1 $inter))
           (() (println! $union2))
         )
         (if (== $union2 0)
             0.0
             (- 1.0 (/ (toFloat $inter) $union2)))))


;; map-jaccard: for a given individual, return its Jaccard distance to each item in the list
(= (map-jaccard $ind $lst)
   (if (== (length $lst) 0)
       ()
       (let* (
              ($first (head $lst))
              ($rest  (cdr-atom $lst))
              ($d     (jaccard-distance $ind $first))
              ($tail  (map-jaccard $ind $rest))
            )
            (cons-atom $d $tail))))

; !(map-jaccard (dog pet animal loyal)
;               ((car engine vehicle wheels)))

; !(map-jaccard (dog pet animal loyal)
;               ((fish water gills animal)
;                (car engine vehicle wheels)))
; !(map-jaccard (dog pet animal loyal)
;               ((cat pet animal independent)))



(= (avg-distance $ind $lst)
   (let* (
           ($distances (map-jaccard $ind $lst))
           ($total     (sum $distances))
           ($count     (length $distances))
         )
         (if (== $count 0)
             0.0
             (/ $total $count))))

; !(avg-distance (dog pet animal loyal)
;    ((cat pet animal independent)
;     (fish water gills animal)
;     (car engine vehicle wheels)))
(= (list-others $item ()) ())
(= (list-others $item $lst)
   (if (== $item (car-atom $lst))
       (list-others $item (cdr-atom $lst))             ; skip this one
       ((car-atom $lst)                  ; keep this one
        (list-others $item (cdr-atom $lst))) ; continue recursion
   ))




;; Main entry: just takes one argument (the population)
(= (compute-diversity $population)
   (let* (
           ($fullpop $population)               ; fix full population
         )
         (compute-diversity-helper $population $fullpop)))

;; Helper: recursive but still has access to $fullpop
(= (compute-diversity-helper () $fullpop) ())
(= (compute-diversity-helper $pop $fullpop)
   (let* (
           ($ind    (head $pop))                  
           ($rest   (cdr-atom $pop))              
           ($others (list-others $ind $fullpop))  
           ($score  (avg-distance $ind $others))  
           ($pair   (cons-atom $ind ($score)))    
           ($tail   (compute-diversity-helper $rest $fullpop))
         )
         (cons-atom $pair $tail)))

!(compute-diversity 
   ((dog pet animal loyal)
    (cat pet animal independent)
    (fish water gills animal)
    (car engine vehicle wheels)))
