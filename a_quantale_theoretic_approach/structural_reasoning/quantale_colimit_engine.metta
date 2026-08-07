!(import! &self a_quantale_theoretic_approach/structural_reasoning/q_logic_operations)
!(import! &self a_quantale_theoretic_approach/structural_reasoning/world_spec_colimit)

; Property-level V-predicate colimit.
;
; Mapping format:
;   ((GenericProperty SourceAProperty SourceBProperty) ...)
;
; The first PeTTa version mirrors the Python property-colimit:
;   - source properties are renamed through generic-space identifications
;   - mapped/colliding values are joined with quantale join
;   - independent properties are freely carried into the blend

(= (q-unified-property-name $source-a-prop $source-b-prop)
   (if (== $source-a-prop $source-b-prop)
       $source-a-prop
       (Unified $source-a-prop $source-b-prop)))

(= (q-map-a-property-name $prop-name $mappings)
   (if (== $mappings ())
       $prop-name
       (let* (($head (car-atom $mappings))
              ($tail (cdr-atom $mappings))
              ($source-a-prop (index-atom $head 1))
              ($source-b-prop (index-atom $head 2)))
          (if (== $prop-name $source-a-prop)
              (q-unified-property-name $source-a-prop $source-b-prop)
              (q-map-a-property-name $prop-name $tail)))))

(= (q-map-b-property-name $prop-name $mappings)
   (if (== $mappings ())
       $prop-name
       (let* (($head (car-atom $mappings))
              ($tail (cdr-atom $mappings))
              ($source-a-prop (index-atom $head 1))
              ($source-b-prop (index-atom $head 2)))
          (if (== $prop-name $source-b-prop)
              (q-unified-property-name $source-a-prop $source-b-prop)
              (q-map-b-property-name $prop-name $tail)))))

(= (q-rename-a-properties $properties $mappings)
   (if (== $properties ())
       ()
       (let* (($head (car-atom $properties))
              ($tail (cdr-atom $properties))
              ($mapped-name (q-map-a-property-name (v-property-name $head) $mappings))
              ($mapped-prop (v-make-property $mapped-name (v-property-quantale $head)))
              ($rest (q-rename-a-properties $tail $mappings)))
          (cons-atom $mapped-prop $rest))))

(= (q-rename-b-properties $properties $mappings)
   (if (== $properties ())
       ()
       (let* (($head (car-atom $properties))
              ($tail (cdr-atom $properties))
              ($mapped-name (q-map-b-property-name (v-property-name $head) $mappings))
              ($mapped-prop (v-make-property $mapped-name (v-property-quantale $head)))
              ($rest (q-rename-b-properties $tail $mappings)))
          (cons-atom $mapped-prop $rest))))

(= (q-upsert-property $property $properties)
   (if (== $properties ())
       (cons-atom $property ())
       (let* (($head (car-atom $properties))
              ($tail (cdr-atom $properties))
              ($prop-name (v-property-name $property))
              ($head-name (v-property-name $head)))
          (if (== $prop-name $head-name)
              (let* (($joined-q (q-join (v-property-quantale $head)
                                        (v-property-quantale $property)))
                     ($joined-prop (v-make-property $head-name $joined-q)))
                 (cons-atom $joined-prop $tail))
              (cons-atom $head (q-upsert-property $property $tail))))))

(= (q-merge-property-lists $merged $properties)
   (if (== $properties ())
       $merged
       (let* (($head (car-atom $properties))
              ($tail (cdr-atom $properties))
              ($next-merged (q-upsert-property $head $merged)))
          (q-merge-property-lists $next-merged $tail))))

; Derive the blend perspective when both inputs have the same scope. Legacy
; concepts have perspective (), and continue to produce the legacy shape.
; Different input perspectives require the explicit five-argument operation.
(= (q-vpredicate-colimit $blend-name $concept-a $concept-b $mappings)
   (let* (($perspective-a (v-concept-perspective $concept-a))
          ($perspective-b (v-concept-perspective $concept-b)))
      (if (== $perspective-a $perspective-b)
          (let* (($props-a (v-property-list $concept-a))
                 ($props-b (v-property-list $concept-b))
                 ($renamed-a (q-rename-a-properties $props-a $mappings))
                 ($renamed-b (q-rename-b-properties $props-b $mappings))
                 ($merged (q-merge-property-lists $renamed-a $renamed-b)))
             (if (== $perspective-a ())
                 (v-make-concept $blend-name $merged)
                 (v-make-concept $blend-name $perspective-a $merged)))
          (VError IncompatibleConceptPerspectives
                  $perspective-a $perspective-b))))

; Explicit output perspective for cross-perspective blends or callers that
; choose a new perspective for the blend.
(= (q-vpredicate-colimit
      $blend-name $blend-perspective $concept-a $concept-b $mappings)
   (let* (($props-a (v-property-list $concept-a))
          ($props-b (v-property-list $concept-b))
          ($renamed-a (q-rename-a-properties $props-a $mappings))
          ($renamed-b (q-rename-b-properties $props-b $mappings))
          ($merged (q-merge-property-lists $renamed-a $renamed-b)))
      (v-make-concept $blend-name $blend-perspective $merged)))

(= (q-colimit-contribution-map $concept-a $concept-b $mappings)
   ((A (q-rename-a-properties (v-property-list $concept-a) $mappings))
    (B (q-rename-b-properties (v-property-list $concept-b) $mappings))))

(= (q-rewrite-property-worlds $property $world-clusters)
   (let* (($prop-name (v-property-name $property))
          ($worlds (v-property-worlds $property))
          ($degree (v-property-degree $property))
          ($rewritten-worlds (ws-rewrite-worlds $worlds $world-clusters)))
      (v-make-property $prop-name (Q $rewritten-worlds $degree))))

(= (q-rewrite-properties-worlds $properties $world-clusters)
   (if (== $properties ())
       ()
       (let* (($head (car-atom $properties))
              ($tail (cdr-atom $properties))
              ($rewritten-head (q-rewrite-property-worlds $head $world-clusters))
              ($rewritten-tail (q-rewrite-properties-worlds $tail $world-clusters)))
          (cons-atom $rewritten-head $rewritten-tail))))

(= (q-rewrite-concept-worlds $concept $world-clusters)
   (v-remake-concept
      $concept
      (v-concept-name $concept)
      (q-rewrite-properties-worlds
         (v-property-list $concept) $world-clusters)))

(= (q-integrated-colimit-blend
      (QuantaleVPredicateColimitResult
         (WorldSpecs $world-specs)
         (Blend $blend)
         (WorldMap $world-map)
         (PropertyContributionMap $property-map)))
   $blend)

(= (q-vpredicate-integrated-colimit
      $blend-name
      $concept-a
      $concept-b
      $property-mappings
      $world-clusters
      $world-spec-registry)
   (let* (($rewritten-a (q-rewrite-concept-worlds $concept-a $world-clusters))
          ($rewritten-b (q-rewrite-concept-worlds $concept-b $world-clusters))
          ($blend (q-vpredicate-colimit $blend-name $rewritten-a $rewritten-b $property-mappings))
          ($final-worlds (v-world-universe $blend))
          ($final-world-specs (ws-specs-for-worlds $final-worlds
                                                   $world-clusters
                                                   $world-spec-registry))
          ($world-map (ws-world-colimit-map $world-clusters))
          ($property-map (q-colimit-contribution-map $rewritten-a
                                                     $rewritten-b
                                                     $property-mappings)))
      (QuantaleVPredicateColimitResult
         (WorldSpecs $final-world-specs)
         (Blend $blend)
         (WorldMap $world-map)
         (PropertyContributionMap $property-map))))

(= (q-vpredicate-colimit-with-worldspecs
      $blend-name
      $concept-a
      $concept-b
      $property-mappings
      $world-clusters
      $world-spec-registry)
   (q-vpredicate-integrated-colimit
      $blend-name
      $concept-a
      $concept-b
      $property-mappings
      $world-clusters
      $world-spec-registry))
