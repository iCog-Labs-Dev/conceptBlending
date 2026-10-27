; Perspective-aware V-predicate concept shape:
;   (Concept Name Perspective
;     (V-predicate
;       (Property
;         (prop (WorldSpecSet (W1 W2)) degree)
;         ...)))
;
; The legacy (Concept Name (V-predicate ...)) shape remains readable so older
; fixtures and callers continue to work. New construction should use the
; three-argument v-make-concept and retain the perspective explicitly.
;
; Some generated PeTTa functions use (Property $props) where $props is already
; a list.  v-property-list normalizes both representations.

(= (v-concept-name (Concept $name $perspective $body))
   $name)
(= (v-concept-name (Concept $name $body))
   $name)

(= (v-concept-perspective (Concept $name $perspective $body))
   $perspective)
(= (v-concept-perspective (Concept $name $body))
   ())

(= (v-normalize-property-tail $raw)
   (if (== (size-atom $raw) 1)
       (let $first (car-atom $raw)
          (if (== (get-metatype $first) Expression)
              $first
              $raw))
       $raw))

(= (v-property-list
      (Concept $name $perspective (V-predicate $property-block)))
   (v-normalize-property-tail (cdr-atom $property-block)))
(= (v-property-list (Concept $name (V-predicate $property-block)))
   (v-normalize-property-tail (cdr-atom $property-block)))

(= (v-property-name ($prop-name (WorldSpecSet $worlds) $degree))
   $prop-name)

(= (v-property-worlds ($prop-name (WorldSpecSet $worlds) $degree))
   $worlds)

(= (v-property-degree ($prop-name (WorldSpecSet $worlds) $degree))
   $degree)

(= (v-property-quantale ($prop-name (WorldSpecSet $worlds) $degree))
   (Q $worlds $degree))

(= (v-make-property $prop-name (Q $worlds $degree))
   ($prop-name (WorldSpecSet $worlds) $degree))

(= (v-make-concept $name $perspective $properties)
   (Concept $name $perspective (V-predicate (Property $properties))))

; Legacy constructor retained for callers that do not yet carry perspective.
(= (v-make-concept $name $properties)
   (Concept $name (V-predicate (Property $properties))))

; Reconstruct a V-predicate while preserving whether its source concept is
; perspective-aware. This is used by structural transformations that replace
; properties without changing the concept's scope.
(= (v-remake-concept
      (Concept $old-name $perspective $old-body) $new-name $properties)
   (v-make-concept $new-name $perspective $properties))
(= (v-remake-concept
      (Concept $old-name $old-body) $new-name $properties)
   (v-make-concept $new-name $properties))

(= (v-find-property $prop-name $properties)
   (if (== $properties ())
       ()
       (let* (($head (car-atom $properties))
              ($tail (cdr-atom $properties)))
          (if (== (v-property-name $head) $prop-name)
              $head
              (v-find-property $prop-name $tail)))))

(= (v-property-exists $prop-name $properties)
   (not (== (v-find-property $prop-name $properties) ())))

(= (v-world-universe-from-properties $properties)
   (if (== $properties ())
       ()
       (let* (($head (car-atom $properties))
              ($tail (cdr-atom $properties))
              ($head-worlds (v-property-worlds $head))
              ($tail-worlds (v-world-universe-from-properties $tail)))
          (unique-atom (union-atom $head-worlds $tail-worlds)))))

(= (v-world-universe $concept)
   (v-world-universe-from-properties (v-property-list $concept)))
