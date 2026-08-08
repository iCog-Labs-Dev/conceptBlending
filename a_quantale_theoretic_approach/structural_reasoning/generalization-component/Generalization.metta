;; Public bootstrap for the Cartesian algebraic-spec generalization component.
;; Keep query files beside this file because PeTTa resolves nested imports and
;; static KB paths from the top-level file.

!(import! &self ../../../../PeTTa/lib/lib_import)
;; Import modules
!(import! &self metta/Common)
!(import! &self metta/GeneralizationDTLhelper)
!(import! &self metta/GeneralizationDTL)
!(static-import! &kb kb/lcg_kb)
!(import! &self metta/synthesizers)
!(import! &self "python/generalization_event_logger.py")
!(import! &self metta/logging/GeneralizationLogger)
!(import! &self "python/lcggenerator.py")
!(import! &self "python/generalization_support.py")
; !(let $lcgs (py-call (lcggenerator.generate_lcg_rules 2)) (let $slcgs (sread $lcgs) (superpose $slcgs)))
!(println! "KB loaded")
(: Predicate Type)
(: → (-> Predicate %Undefined% Expression Type))
(: water Predicate)
(: land Predicate)
(: medium Predicate)
(: surface Predicate)

(: kb (-> Atom))
(= (kb) (get-atoms &kb))
(: rb (-> Atom))
; (= (rb) (double-depth-lcg-rule))
(= (rb) (let $lcgs (py-call (lcggenerator.generate_lcg_and_write_synthesizers 2 "synthesizers.metta")) (let $slcgs (sread $lcgs) (eval (superpose $slcgs)))))
; !(rb)

;; Enumerate every acyclic taxonomy branch.  The previous implementation only
;; advanced when a node had exactly one successor and therefore stopped at the
;; first genuine branch in the KB.
(= (generalization-path-member $concept $path)
    (if (== $path ())
        False
        (if (== $concept (car-atom $path))
            True
            (generalization-path-member $concept (cdr-atom $path)))))

(= (generalization-successors $concept $kb)
    (collapse
        (let (: $proof (≞ (→ $concept $gen ()) (stv $s $c))) ($kb)
            (GeneralizationStep $gen (stv $s $c)))))

(= (generalization-path-list-member $path $paths)
    (if (== $paths ())
        False
        (if (== $path (car-atom $paths))
            True
            (generalization-path-list-member $path (cdr-atom $paths)))))

(= (generalization-path-union $left $right)
    (if (== $left ())
        $right
        (let* (
            ($path (car-atom $left))
            ($rest (generalization-path-union (cdr-atom $left) $right)))
            (if (generalization-path-list-member $path $rest)
                $rest
                (cons-atom $path $rest)))))

(= (generalization-expand-steps $steps $kb $remaining $path)
    (if (== $steps ())
        ()
        (let* (
            ((GeneralizationStep $gen $tv) (car-atom $steps))
            ($rest (cdr-atom $steps))
            ($rest-paths (generalization-expand-steps $rest $kb $remaining $path))
            ($branch-paths
                (if (generalization-path-member $gen $path)
                    ()
                    (generalization-expand-path
                        $gen $kb (- $remaining 1) (union-atom $path (-> $gen))))))
            (generalization-path-union $branch-paths $rest-paths))))

(= (generalization-expand-path $concept $kb $remaining $path)
    (if (<= $remaining 0)
        (cons-atom $path ())
        (let $steps (generalization-successors $concept $kb)
            (if (== $steps ())
                (cons-atom $path ())
                (generalization-expand-steps $steps $kb $remaining $path)))))

;; Keep the original public signature.  Its result is now a list of paths.
(= (generalization-path-finder $concept $kb $max-depth $counter $result)
    (generalization-expand-path $concept $kb (- $max-depth $counter) $result))

;; Weighted paths retain the edge evidence needed to produce graph-derived
;; LCG truth values when standalone concept truth atoms are unavailable.
(= (weighted-path-member $concept $path)
    (if (== $path ())
        False
        (let (GeneralizationStep $node $tv) (car-atom $path)
            (if (== $concept $node)
                True
                (weighted-path-member $concept (cdr-atom $path))))))

(= (weighted-generalization-expand-steps $steps $kb $remaining $path)
    (if (== $steps ())
        ()
        (let* (
            ((GeneralizationStep $gen $tv) (car-atom $steps))
            ($rest (cdr-atom $steps))
            ($rest-paths
                (weighted-generalization-expand-steps
                    $rest $kb $remaining $path))
            ($branch-paths
                (if (weighted-path-member $gen $path)
                    ()
                    (weighted-generalization-expand-path
                        $gen $kb (- $remaining 1)
                        (union-atom $path ((GeneralizationStep $gen $tv)))))))
            (generalization-path-union $branch-paths $rest-paths))))

(= (weighted-generalization-expand-path $concept $kb $remaining $path)
    (if (<= $remaining 0)
        (cons-atom $path ())
        (let $steps (generalization-successors $concept $kb)
            (if (== $steps ())
                (cons-atom $path ())
                (weighted-generalization-expand-steps
                    $steps $kb $remaining $path)))))

(= (weighted-generalization-path-finder $concept $kb $max-depth)
    (weighted-generalization-expand-path
        $concept $kb $max-depth
        ((GeneralizationStep $concept (stv 1 1)))))

(= (proof-generator $concept)
    (if (== (get-metatype $concept) Symbol) (py-call (operator.add $concept m)) ())
)

(= (proof-generator $concept1 $concept2)
    (if (and (== (get-metatype $concept1) Symbol) (== (get-metatype $concept2) Symbol)) (let $c1c2 (py-call (operator.add $concept1 $concept2)) (proof-generator $c1c2)) ())
)

(= (add-generalization-edge $space $left $right $tv)
    (let $proof (proof-generator $left $right)
        (add-atom $space (: $proof (≞ (→ $left $right ()) $tv)))))

(= (install-lcg-segment $space $lcg (Path $left $right $left-tv $right-tv))
    (if (== $right ())
        (add-generalization-edge $space $left $lcg $left-tv)
        (let* (
            ;; Preserve the observed edge. Repair is monotonic: the validated
            ;; LCG bridge augments the taxonomy rather than deleting evidence.
            ($_ (add-generalization-edge $space $left $lcg $left-tv))
            ($_ (add-generalization-edge $space $lcg $right $right-tv)))
            True)))

(= (install-lcg-repair $space $repair)
    (if (== $repair ())
        ()
        (let (LCGRepair $lcg $path1 $path2) $repair
            (let* (
                ($lcg-proof (proof-generator $lcg))
                ($_ (install-lcg-segment $space $lcg $path1))
                ($_ (install-lcg-segment $space $lcg $path2))
                ($_ (add-atom $space (: $lcg-proof (≞ $lcg (stv 0.5 0.5))))))
                $lcg))))

(= (propose-lcg-repair $concept1 $concept2 $kb $max-depth)
    (let* (
        ($paths1 (generalization-path-finder $concept1 $kb $max-depth 0 ($concept1)))
        ($paths2 (generalization-path-finder $concept2 $kb $max-depth 0 ($concept2)))
        ($repair-text
            (py-call (generalization_support.repair_lcg
                $concept1 $concept2 $paths1 $paths2 $kb True)))
        ($repair (sread $repair-text)))
        $repair))

(= (repair-missing-lcg $concept1 $concept2 $kb $space $max-depth)
    (install-lcg-repair $space
        (propose-lcg-repair $concept1 $concept2 $kb $max-depth)))

(= (lcg-repair-proof $concept1 $concept2 ()) ())
(= (lcg-repair-proof
        $concept1 $concept2
        (LCGRepair $lcg
            (Path $left1 $right1 (stv $s1 $c1) $right-tv1)
            (Path $left2 $right2 (stv $s2 $c2) $right-tv2)))
    (let $proof (proof-generator $concept1 $concept2)
        (: $proof
            (≞ (→ $concept1 $concept2 ($lcg))
                (stv (min $s1 $s2) (min $c1 $c2))))))

(= (repair-missing-lcg-proof $concept1 $concept2 $kb $max-depth)
    (lcg-repair-proof $concept1 $concept2
        (propose-lcg-repair $concept1 $concept2 $kb $max-depth)))

(= (graph-lcg-proofs $concept1 $concept2 $kb $max-depth)
    (let* (
        ($paths1 (weighted-generalization-path-finder
            $concept1 $kb $max-depth))
        ($paths2 (weighted-generalization-path-finder
            $concept2 $kb $max-depth))
        ($proof-text (py-call (generalization_support.graph_lcg_proofs
            $concept1 $concept2 $paths1 $paths2))))
        (sread $proof-text)))

(= (cached-lcg-proofs $concept1 $concept2 $kb)
    (let* (
        ($repair-text
            (py-call (generalization_support.lookup_cached_lcg_repair
                $concept1 $concept2 $kb)))
        ($repair (sread $repair-text)))
        (if (== $repair ())
            ()
            (let $proof (lcg-repair-proof $concept1 $concept2 $repair)
                (cons-atom $proof ())))))

(= (pair-lcg $concept1 $concept2 $kb $space $max-depth)
    (let $cached (cached-lcg-proofs $concept1 $concept2 $kb)
        (if (not (== $cached ()))
            $cached
            (let $res (collapse (synthesize (: $proof (≞ (→ $concept1 $concept2 ($lcg)) $tv)) $space rb (S Z)))
                (if (== $res ())
                    (let $graph-proofs
                        (graph-lcg-proofs $concept1 $concept2 $kb $max-depth)
                        (if (== $graph-proofs ())
                            (let $repair-proof
                                (repair-missing-lcg-proof
                                    $concept1 $concept2 $kb $max-depth)
                                (if (== $repair-proof ())
                                    ()
                                    (cons-atom $repair-proof ())))
                            $graph-proofs))
                    (let $normalized-text
                        (py-call (generalization_support.normalize_lcg_proofs
                            $concept1 $concept2 $res))
                        (sread $normalized-text))))))
)

(= (get-alg-spec-part $alg-spec $perspective $part)
    (let (Concept $concept-name $perspective (spec (sorts $sorts) (ops $ops) (preds $preds) (axioms $axioms))) $alg-spec
        (if (== $part sorts)
            $sorts
            (if (== $part ops)
                $ops
                (if (== $part preds)
                    $preds
                    $axioms
                )
            )
        )
    )
)

(= (resolve-pair-request (PairRequest $request-id $left $right) $kb $space $max-depth)
    (if (== $left $right)
        ((PairResolution $request-id $left (stv 1 1)))
        (let* (
            ($proofs (pair-lcg $left $right $kb $space $max-depth))
            ($resolution-text
                (py-call (generalization_support.resolutions_from_proofs
                    $request-id $left $right $proofs))))
            (sread $resolution-text))))

(= (resolve-pair-requests $requests $kb $space $max-depth)
    (if (== $requests ())
        ()
        (union-atom
            (resolve-pair-request (car-atom $requests) $kb $space $max-depth)
            (resolve-pair-requests (cdr-atom $requests) $kb $space $max-depth))))

(= (generalize-algebraic-spec-with-kb
        $generic-name $perspective $c1-alg-spec $c2-alg-spec
        $kb $space $max-depth)
    (let* (
        ($plan-text
            (py-call (generalization_support.build_cartesian_plan
                $perspective $c1-alg-spec $c2-alg-spec)))
        ($plan (sread $plan-text))
        ((GeneralizationPlan (PairRequests $requests) (PairCounts $counts)) $plan)
        ($resolutions
            (resolve-pair-requests $requests $kb $space $max-depth))
        ($spec-text
            (py-call (generalization_support.assemble_cartesian_spec
                $generic-name $perspective $c1-alg-spec $c2-alg-spec
                (PairResolutions $resolutions)))))
        (sread $spec-text)))

(= (generalize-algebraic-spec $generic-name $perspective $c1-alg-spec $c2-alg-spec)
    (let* (
        ($max-depth 10)
        ($cached-text
            (py-call (generalization_support.lookup_generic_algebraic_spec
                $generic-name $perspective
                $c1-alg-spec $c2-alg-spec $max-depth)))
        ($cached (sread $cached-text)))
        (if (== $cached ())
            (let* (
                ($specification
                    (generalize-algebraic-spec-with-kb
                        $generic-name $perspective
                        $c1-alg-spec $c2-alg-spec
                        kb &kb $max-depth))
                ($_persisted
                    (py-call
                        (generalization_support.persist_generic_algebraic_spec
                            $generic-name $perspective
                            $c1-alg-spec $c2-alg-spec $max-depth
                            $specification))))
                $specification)
            $cached)))

(= (main-lcg $generic-name $perspective $c1-alg-spec $c2-alg-spec)
    (let* (
        ($_run (generalization-start $generic-name $perspective))
        ($specification
            (generalize-algebraic-spec
                $generic-name $perspective $c1-alg-spec $c2-alg-spec))
        ($_finished
            (generalization-finish
                success $generic-name $perspective
                generic_space_returned)))
        $specification))

; See GeneralizationExample.metta for an executable example.

; !(get-atoms &kb)

;!(pair-lcg cat dog kb &kb 10)

; !(get-atoms &kb)
