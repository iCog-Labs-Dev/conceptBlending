;; Evaluate the one-time Python registration without importing llm.metta,
;; whose client state is unrelated to this verifier.
(= (property-world-py-eval $str)
    (let $dict (py-call (dict))
        (py-call (quote (eval $str $dict $dict)))))
!(property-world-py-eval "(lambda os,sys,importlib,builtins:(lambda root:(sys.path.insert(0,os.path.join(root,'python','storage')),sys.path.insert(0,os.path.join(root,'python','verification')),setattr(builtins,'verify_concept_properties',importlib.import_module('property_world_verifier').verify_concept_properties),setattr(builtins,'verify_property_worlds',importlib.import_module('property_world_verifier').verify_property_worlds),0)[-1])(os.getenv('V_PREDICATE_PIPELINE_ROOT',os.getcwd() if os.path.isdir(os.path.join(os.getcwd(),'python','verification')) else os.path.join(os.getcwd(),'v-predicate-extraction-pipeline') if os.path.isdir(os.path.join(os.getcwd(),'v-predicate-extraction-pipeline','python')) else os.path.join(os.getcwd(),'metta','pln','dependent-types','v-predicate-extraction-pipeline'))))(__import__('os'),__import__('sys'),__import__('importlib'),__import__('builtins'))")

;; Scoped, perspective-aware property/world data layer.

(= (property-world-formula (stv $featureS $featureC)
                           (stv $perspectiveS $perspectiveC))
    (stv (* $featureS $perspectiveS)
         (min $featureC $perspectiveC)))

(= (world-perspective-formula (stv $worldS $worldC)
                              (stv $perspectiveS $perspectiveC))
    (stv (* $worldS $perspectiveS)
         (min $worldC $perspectiveC)))

;; Global property-name retrieval joins the property evidence, its perspective
;; match, the world evidence, and the world's effective perspective. The world
;; edge carries most of the score because it already combines property/world
;; evidence in the generated KB.
(= (global-world-formula (stv $propertyS $propertyC)
                         (stv $propertyPerspectiveS $propertyPerspectiveC)
                         (stv $worldS $worldC))
    (stv (* $propertyPerspectiveS
            (+ (* 0.35 $propertyS) (* 0.65 $worldS)))
         (min $propertyC
              (min $propertyPerspectiveC $worldC))))

(: scoped-property-query-rule (-> Atom))
(= (scoped-property-query-rule)
    (: ScopedPropertyQuery
        (-> (≞ (has_scoped_property $edge $concept $featurePerspective
                                    $propertyId $propertyName) $featureTv)
            (≞ (perspective_match $requestedPerspective $featurePerspective
                                  $perspectiveClass) $perspectiveTv)
            (≞ (scoped_property_for $concept $requestedPerspective
                    (PropertyRef $propertyId $propertyName $featurePerspective))
                (Method property-world-formula $featureTv $perspectiveTv)))))

(: scoped-world-query-rule (-> Atom))
(= (scoped-world-query-rule)
    (: ScopedWorldQuery
        (-> (≞ (scoped_property_holds_in $edge $propertyId
                                          $effectivePerspective $world) $worldTv)
            (≞ (perspective_match $requestedPerspective $effectivePerspective
                                  $perspectiveClass) $perspectiveTv)
            (≞ (world_ref_for $propertyId $requestedPerspective
                              (WorldRef $world $effectivePerspective))
                (Method world-perspective-formula $worldTv $perspectiveTv)))))

(: global-world-query-rule (-> Atom))
(= (global-world-query-rule)
    (: GlobalWorldQuery
        (-> (≞ (has_scoped_property $propertyEdge $concept
                                    $featurePerspective $propertyId
                                    $propertyName) $propertyTv)
            (≞ (perspective_match $requestedPerspective $featurePerspective
                                  $propertyPerspectiveClass)
                $propertyPerspectiveTv)
            (≞ (scoped_property_holds_in $worldEdge $propertyId
                                          $effectivePerspective $world) $worldTv)
            (≞ (global_world_for $propertyName $requestedPerspective
                                 (WorldRef $world $effectivePerspective))
                (Method global-world-formula
                        $propertyTv $propertyPerspectiveTv
                        $worldTv)))))

(: scoped-property-rb (-> Atom))
(= (scoped-property-rb) (scoped-property-query-rule))
(: scoped-world-rb (-> Atom))
(= (scoped-world-rb) (scoped-world-query-rule))
(: global-world-rb (-> Atom))
(= (global-world-rb) (global-world-query-rule))

(= (clean-property-ref-result
        (: $proof (≞ (scoped_property_for $concept $perspective $propertyRef) $tv)))
    $propertyRef)
(= (clean-world-ref-result
        (: $proof (≞ (world_ref_for $propertyId $perspective $worldRef) $tv)))
    $worldRef)
(= (clean-scored-global-world-result
        (: $proof
           (≞ (global_world_for $propertyName $perspective
                                (WorldRef $world $effectivePerspective))
              (stv $strength $confidence))))
    (ScoredWorld $world $effectivePerspective $strength $confidence 1))

(= (clean-property-ref-results $items)
    (if (== $items ())
        ()
        (cons-atom
            (clean-property-ref-result (car-atom $items))
            (clean-property-ref-results (cdr-atom $items)))))
(= (clean-world-ref-results $items)
    (if (== $items ())
        ()
        (cons-atom
            (clean-world-ref-result (car-atom $items))
            (clean-world-ref-results (cdr-atom $items)))))
(= (clean-scored-global-world-results $items)
    (if (== $items ())
        ()
        (cons-atom
            (clean-scored-global-world-result (car-atom $items))
            (clean-scored-global-world-results (cdr-atom $items)))))

;; Internal Stage 1: concept + perspective -> scoped PropertyRefs.
(= (query-concept-property-refs $concept $perspective)
    (clean-property-ref-results
        (collapse
            (synthesize
                (: $proof
                   (≞ (scoped_property_for $concept $perspective $propertyRef) $tv))
                &propertyworldkb scoped-property-rb (S Z)))))

;; Public Stage 1: expose only property names and their effective perspectives.
(= (property-ref-pairs $propertyRefs)
    (if (== $propertyRefs ())
        ()
        (let (PropertyRef $propertyId $propertyName $effectivePerspective)
                (car-atom $propertyRefs)
            (cons-atom
                (cons-atom
                    $propertyName
                    (cons-atom $effectivePerspective ()))
                (property-ref-pairs (cdr-atom $propertyRefs))))))

(= (query-concept-properties-from-kb $concept $perspective)
    (property-ref-pairs
        (query-concept-property-refs $concept $perspective)))

(= (verify-concept-properties $concept $perspective $candidate)
    (let $verifiedText
        (py-call
            (builtins.verify_concept_properties
                $concept $perspective $candidate))
        (sread $verifiedText)))

(= (query-concept-properties $concept $perspective)
    (let* (($candidate
                (query-concept-properties-from-kb $concept $perspective))
           ($_extracted
                (pipeline-success
                    properties_extracted
                    $concept $perspective $candidate))
           ($verified
                (verify-concept-properties
                    $concept $perspective $candidate))
           ($_verified
                (pipeline-success
                    properties_verified
                    $concept $perspective $verified)))
        $verified))

;; Stage 2: one scoped property + the same requested perspective -> WorldRefs.
(= (query-property-world-refs
        (PropertyRef $propertyId $propertyName $effectivePerspective)
        $requestedPerspective)
    (clean-world-ref-results
        (collapse
            (synthesize
                (: $proof
                   (≞ (world_ref_for $propertyId $requestedPerspective $worldRef) $tv))
                &propertyworldkb scoped-world-rb (S Z)))))

(= (world-ref-names $worldRefs)
    (if (== $worldRefs ())
        ()
        (let (WorldRef $world $perspective) (car-atom $worldRefs)
            (cons-atom $world (world-ref-names (cdr-atom $worldRefs))))))

(= (query-property-worlds-by-ref $propertyRef $requestedPerspective)
    (world-ref-names
        (query-property-world-refs $propertyRef $requestedPerspective)))

;; Global property-name retrieval helpers. Duplicate worlds are merged by
;; name. The strongest evidence is retained and independent support contributes
;; a small capped ranking bonus.
(= (merge-scored-world
        (ScoredWorld $world $perspective $strength $confidence $support)
        $items)
    (if (== $items ())
        ((ScoredWorld $world $perspective $strength $confidence $support))
        (let (ScoredWorld $existingWorld $existingPerspective
                          $existingStrength $existingConfidence $existingSupport)
                (car-atom $items)
            (if (== $world $existingWorld)
                (cons-atom
                    (if (== $strength (max $strength $existingStrength))
                        (ScoredWorld $world $perspective
                                     $strength (max $confidence $existingConfidence)
                                     (+ $support $existingSupport))
                        (ScoredWorld $existingWorld $existingPerspective
                                     $existingStrength
                                     (max $confidence $existingConfidence)
                                     (+ $support $existingSupport)))
                    (cdr-atom $items))
                (cons-atom
                    (car-atom $items)
                    (merge-scored-world
                        (ScoredWorld $world $perspective
                                     $strength $confidence $support)
                        (cdr-atom $items)))))))

(= (merge-scored-worlds $candidates $result)
    (if (== $candidates ())
        $result
        (merge-scored-worlds
            (cdr-atom $candidates)
            (merge-scored-world (car-atom $candidates) $result))))

(= (scored-world-rank
        (ScoredWorld $world $perspective $strength $confidence $support))
    (+ $strength (* 0.02 (min $support 5))))

(= (scored-world-before $left $right)
    (let* (($leftRank (scored-world-rank $left))
           ($rightRank (scored-world-rank $right)))
        (if (== $leftRank $rightRank)
            (let* (((ScoredWorld $leftWorld $leftPerspective
                                 $leftStrength $leftConfidence $leftSupport)
                        $left)
                   ((ScoredWorld $rightWorld $rightPerspective
                                 $rightStrength $rightConfidence $rightSupport)
                        $right))
                (and (not (== $leftConfidence $rightConfidence))
                     (== $leftConfidence
                         (max $leftConfidence $rightConfidence))))
            (if (== $leftRank (max $leftRank $rightRank))
                True
                False))))

(= (insert-scored-world $candidate $ranked)
    (if (== $ranked ())
        ($candidate)
        (if (scored-world-before $candidate (car-atom $ranked))
            (cons-atom $candidate $ranked)
            (cons-atom
                (car-atom $ranked)
                (insert-scored-world $candidate (cdr-atom $ranked))))))

(= (rank-scored-worlds $items $ranked)
    (if (== $items ())
        $ranked
        (rank-scored-worlds
            (cdr-atom $items)
            (insert-scored-world (car-atom $items) $ranked))))

(= (take-ranked-worlds $items $remaining)
    (if (or (== $items ()) (== $remaining 0))
        ()
        (cons-atom
            (car-atom $items)
            (take-ranked-worlds (cdr-atom $items) (- $remaining 1)))))

(= (scored-world-names $items)
    (if (== $items ())
        ()
        (let (ScoredWorld $world $perspective $strength $confidence $support)
                (car-atom $items)
            (cons-atom $world (scored-world-names (cdr-atom $items))))))

(= (query-global-property-world-candidates $propertyName $requestedPerspective)
    (clean-scored-global-world-results
        (collapse
            (synthesize
                (: $proof
                   (≞ (global_world_for $propertyName $requestedPerspective
                                        $worldRef) $tv))
                &propertyworldkb global-world-rb (S Z)))))

(= (query-property-worlds-from-kb $propertyName $requestedPerspective)
    (scored-world-names
        (take-ranked-worlds
            (rank-scored-worlds
                (merge-scored-worlds
                    (query-global-property-world-candidates
                        $propertyName $requestedPerspective)
                    ())
                ())
            15)))

(= (verify-property-worlds $propertyName $perspective $candidate)
    (let $verifiedText
        (py-call
            (builtins.verify_property_worlds
                $propertyName $perspective $candidate))
        (sread $verifiedText)))

(= (query-property-worlds $propertyName $perspective)
    (let* (($candidate
                (query-property-worlds-from-kb
                    $propertyName $perspective))
           ($_extracted
                (pipeline-success
                    worlds_extracted
                    $propertyName $perspective $candidate))
           ($verified
                (verify-property-worlds
                    $propertyName $perspective $candidate))
           ($_verified
                (pipeline-success
                    worlds_verified
                    $propertyName $perspective $verified)))
        $verified))

;; Pure stable list deduplication. This function performs no KB query.
(= (world-ref-member (WorldRef $world $perspective) $items)
    (if (== $items ())
        False
        (let (WorldRef $existingWorld $existingPerspective) (car-atom $items)
            (if (and (== $world $existingWorld)
                     (== $perspective $existingPerspective))
                True
                (world-ref-member
                    (WorldRef $world $perspective)
                    (cdr-atom $items))))))

(= (append-world-ref $items $worldRef)
    (if (== $items ())
        ($worldRef)
        (cons-atom
            (car-atom $items)
            (append-world-ref (cdr-atom $items) $worldRef))))

(= (add-unique-world-ref $worldRef $result)
    (if (world-ref-member $worldRef $result)
        $result
        (append-world-ref $result $worldRef)))

(= (dedupe-one-world-list $worlds $result)
    (if (== $worlds ())
        $result
        (dedupe-one-world-list
            (cdr-atom $worlds)
            (add-unique-world-ref (car-atom $worlds) $result))))

(= (dedupe-world-lists $worldLists $result)
    (if (== $worldLists ())
        $result
        (dedupe-world-lists
            (cdr-atom $worldLists)
            (dedupe-one-world-list (car-atom $worldLists) $result))))

(= (filter-unique-possible-worlds $worldLists)
    (dedupe-world-lists $worldLists ()))

;; A broad perspective can match the same public property through multiple
;; effective child perspectives. Preserve the first (KB priority order) so the
;; final representation contains each public property exactly once.
(= (property-ref-member
        (PropertyRef $propertyId $propertyName $perspective) $items)
    (if (== $items ())
        False
        (let (PropertyRef $existingId $existingName $existingPerspective)
                (car-atom $items)
            (if (== $propertyName $existingName)
                True
                (property-ref-member
                    (PropertyRef $propertyId $propertyName $perspective)
                    (cdr-atom $items))))))

(= (append-property-ref $items $propertyRef)
    (if (== $items ())
        ($propertyRef)
        (cons-atom
            (car-atom $items)
            (append-property-ref (cdr-atom $items) $propertyRef))))

(= (dedupe-property-refs $items $result)
    (if (== $items ())
        $result
        (let $propertyRef (car-atom $items)
            (dedupe-property-refs
                (cdr-atom $items)
                (if (property-ref-member $propertyRef $result)
                    $result
                    (append-property-ref $result $propertyRef))))))

(= (filter-unique-properties $propertyRefs)
    (dedupe-property-refs $propertyRefs ()))

(= (collect-property-world-lists $propertyRefs $perspective)
    (if (== $propertyRefs ())
        ()
        (cons-atom
            (query-property-world-refs (car-atom $propertyRefs) $perspective)
            (collect-property-world-lists (cdr-atom $propertyRefs) $perspective))))

(= (wrap-world-ref-names $worldRefs)
    (if (== $worldRefs ())
        ()
        (let (WorldRef $world $effectivePerspective) (car-atom $worldRefs)
            (cons-atom
                (cons-atom $world ())
                (wrap-world-ref-names (cdr-atom $worldRefs))))))

(= (build-property-world-pairs $propertyRefs $requestedPerspective)
    (if (== $propertyRefs ())
        ()
        (let* (((PropertyRef $propertyId $propertyName $effectivePerspective)
                    (car-atom $propertyRefs))
               ($worldRefs (query-property-world-refs
                              (car-atom $propertyRefs) $requestedPerspective))
               ($worldNames (wrap-world-ref-names $worldRefs))
               ($rest (build-property-world-pairs
                        (cdr-atom $propertyRefs) $requestedPerspective)))
            (cons-atom
                (cons-atom
                    (cons-atom $propertyName ())
                    (cons-atom $worldNames ()))
                $rest))))

(= (build-world-algebraic-spec-pairs $worldRefs)
    (if (== $worldRefs ())
        ()
        (let* (((WorldRef $world $effectivePerspective) (car-atom $worldRefs))
               ($specification
                    (build-algebraic-spec $world $effectivePerspective))
               ($rest (build-world-algebraic-spec-pairs (cdr-atom $worldRefs))))
            (cons-atom
                (($world $effectivePerspective) $specification)
                $rest))))

(= (report-world-algebraic-spec-ensure $world $perspective ())
    (let $_logged
            (pipeline-error
                algebraic_spec_ensure_failed
                $world $perspective generation_or_storage_returned_no_result)
        False))
(= (report-world-algebraic-spec-ensure $world $perspective $results)
    True)

;; Ensure every unique world's specification exists. Cache hits do not call
;; build-algebraic-spec.
(= (store-world-algebraic-specifications ())
    ())
(= (store-world-algebraic-specifications $worldRefs)
    (let* (((WorldRef $world $effectivePerspective)
                (car-atom $worldRefs))
           ($worldMetaType (get-metatype (quote $world)))
           ($_callableWorldLogged
                (if (== $worldMetaType Grounded)
                    (pipeline-error
                        algebraic_spec_skipped_callable_symbol
                        $world $effectivePerspective
                        world_name_conflicts_with_registered_function)
                    True))
           ($ensureResults
                (if (== $worldMetaType Grounded)
                    (cons-atom False ())
                    (collapse
                        (ensure-world-algebraic-spec
                            $world $effectivePerspective))))
           ($_checked
                (report-world-algebraic-spec-ensure
                    $world $effectivePerspective $ensureResults)))
        (store-world-algebraic-specifications
            (cdr-atom $worldRefs))))

(= (rebuild-world-algebraic-specifications ())
    ())
(= (rebuild-world-algebraic-specifications $worldRefs)
    (let* (((WorldRef $world $effectivePerspective)
                (car-atom $worldRefs))
           ($_rebuilt
                (rebuild-world-algebraic-spec
                    $world $effectivePerspective)))
        (rebuild-world-algebraic-specifications
            (cdr-atom $worldRefs))))

(= (store-world-specs-and-build-concept-result
        $concept $requestedPerspective $finalPropertyWorldPairs $uniqueWorldRefs)
    (let* (($_stored
                (store-world-algebraic-specifications $uniqueWorldRefs))
           ($result
                (Concept $concept $requestedPerspective
                    $finalPropertyWorldPairs))
           ($_finished
                (pipeline-finish
                    success $concept $requestedPerspective $result)))
        $result))

(= (build-concept-property-world-specifications-unverified
        $concept $requestedPerspective)
    (let* (($propertyRefs
                (filter-unique-properties
                    (query-concept-property-refs
                        $concept $requestedPerspective)))
           ($propertyPairs
                (build-property-world-pairs $propertyRefs $requestedPerspective))
           ($worldLists
                (collect-property-world-lists $propertyRefs $requestedPerspective))
           ($uniqueWorldRefs (filter-unique-possible-worlds $worldLists))
           ($worldSpecifications
                (build-world-algebraic-spec-pairs $uniqueWorldRefs)))
        (Concept $concept $requestedPerspective
            (cons-atom Properties $propertyPairs)
            (cons-atom PossibleWorldsWithAlgebraicSpecifications
                       $worldSpecifications))))

;; Verified final builder: at most 10 verified properties and at most 3
;; verified global worlds for each property.
(= (wrap-world-names $worlds)
    (if (== $worlds ())
        ()
        (cons-atom
            (cons-atom (car-atom $worlds) ())
            (wrap-world-names (cdr-atom $worlds)))))

(= (build-verified-property-world-pairs $propertyPairs $requestedPerspective)
    (if (== $propertyPairs ())
        ()
        (let* ((($propertyName $effectivePerspective)
                    (car-atom $propertyPairs))
               ($worlds
                    (query-property-worlds
                        $propertyName $requestedPerspective))
               ($rest
                    (build-verified-property-world-pairs
                        (cdr-atom $propertyPairs) $requestedPerspective)))
            (cons-atom
                (cons-atom
                    (cons-atom $propertyName ())
                    (cons-atom (wrap-world-names $worlds) ()))
                $rest))))

(= (world-names-to-refs $worlds $effectivePerspective)
    (if (== $worlds ())
        ()
        (cons-atom
            (WorldRef (car-atom $worlds) $effectivePerspective)
            (world-names-to-refs
                (cdr-atom $worlds) $effectivePerspective))))

(= (collect-verified-world-lists $propertyPairs $requestedPerspective)
    (if (== $propertyPairs ())
        ()
        (let* ((($propertyName $effectivePerspective)
                    (car-atom $propertyPairs))
               ($worlds
                    (query-property-worlds
                        $propertyName $requestedPerspective))
               ($worldRefs
                    (world-names-to-refs $worlds $effectivePerspective))
               ($rest
                    (collect-verified-world-lists
                        (cdr-atom $propertyPairs) $requestedPerspective)))
            (cons-atom $worldRefs $rest))))

(= (build-concept-property-world-specifications
        $concept $requestedPerspective)
    (let* (($_runId
                (pipeline-start $concept $requestedPerspective))
           ($propertyPairs
                (query-concept-properties $concept $requestedPerspective))
           ($_propertiesReady
                (pipeline-success
                    property_stage_completed
                    $concept $requestedPerspective $propertyPairs))
           ($propertyWorldPairs
                (build-verified-property-world-pairs
                    $propertyPairs $requestedPerspective))
           ($_worldStageReady
                (pipeline-success
                    property_world_pairs_built
                    $concept $requestedPerspective $propertyWorldPairs))
            ;($_ (println! (propworldpair $propertyWorldPairs)))
            ($finalPropertyWorldPairs (cons Properties $propertyWorldPairs))
            ;($_ (println! (finalpropworld $finalPropertyWorldPairs)))
           ($worldLists
                (collect-verified-world-lists
                    $propertyPairs $requestedPerspective))
            ;($_ (println! (worldlists $worldLists)))
           ($uniqueWorldRefs
                (filter-unique-possible-worlds $worldLists))
           ($_worldsDeduplicated
                (pipeline-success
                    worlds_deduplicated
                    $concept $requestedPerspective $uniqueWorldRefs))
            ;($_ (println! (uniqueworldref $uniqueWorldRefs)))
            ;($_ (println! (Algspecspacecontent (collapse (get-atoms &algspecspace)))))
                )
        (store-world-specs-and-build-concept-result
        $concept $requestedPerspective $finalPropertyWorldPairs $uniqueWorldRefs)
    )
)
