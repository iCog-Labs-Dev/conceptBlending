;; Persistent storage for generated, perspective-aware algebraic
;; specifications. The disk cache hydrates this session-local space at import,
;; and each specification is exposed as a nullary method:
;;
;;   (= (computer-functional_use-spec) (Concept computer functional_use ...))
;;
;; The importing data layer is responsible for building cache misses.

!(bind! &algspecspace (new-space))

(= (algspec-space-py-eval $str)
    (let $dict (py-call (dict))
        (py-call (quote (eval $str $dict $dict)))))

;; Register the disk-cache helpers from either the standalone directory, the
;; legacy dependent-types directory, or the repository root.
;; V_PREDICATE_PIPELINE_ROOT can override discovery in embedded deployments.
!(algspec-space-py-eval "(lambda os,sys,importlib,builtins:(lambda root:(sys.path.insert(0,os.path.join(root,'python','verification')),sys.path.insert(0,os.path.join(root,'python','storage')),setattr(builtins,'load_persisted_algebraic_specs',importlib.import_module('algebraic_spec_space_cache').load_persisted_algebraic_specs),setattr(builtins,'persist_algebraic_spec',importlib.import_module('algebraic_spec_space_cache').persist_algebraic_spec),0)[-1])(os.getenv('V_PREDICATE_PIPELINE_ROOT',os.getcwd() if os.path.isdir(os.path.join(os.getcwd(),'python','storage')) else os.path.join(os.getcwd(),'v-predicate-extraction-pipeline') if os.path.isdir(os.path.join(os.getcwd(),'v-predicate-extraction-pipeline','python')) else os.path.join(os.getcwd(),'metta','pln','dependent-types','v-predicate-extraction-pipeline'))))(__import__('os'),__import__('sys'),__import__('importlib'),__import__('builtins'))")

(= (algspec-space-join3 $left $middle $right)
    (py-call
        (operator.add
            (py-call
                (operator.add
                    (py-call (str $left))
                    (py-call (str $middle))))
            (py-call (str $right)))))

(= (algspec-space-method-name $world $perspective)
    (sread
        (algspec-space-join3
            (algspec-space-join3 $world - $perspective)
            -
            spec)))

;; Remove every previous definition of the same perspective-qualified method.
;; collapse makes the no-existing-definition case reduce to ().
(= (remove-world-algebraic-spec $world $perspective)
    (let $methodName (algspec-space-method-name $world $perspective)
        (collapse
            (match &algspecspace
                (= ($methodName) $oldSpecification)
                (remove-atom
                    &algspecspace
                    (= ($methodName) $oldSpecification))))))

(= (store-world-algebraic-spec-in-memory
        $world $perspective $specification)
    (let* (($methodName
                (algspec-space-method-name $world $perspective))
           ($_removed
                (remove-world-algebraic-spec $world $perspective))
           ($_added
                (add-atom
                    &algspecspace
                    (= ($methodName) $specification))))
        $methodName))

(= (store-world-algebraic-spec
        $world $perspective $specification)
    (let* (($_persisted
                (py-call
                    (builtins.persist_algebraic_spec
                        $world $perspective $specification)))
           ($methodName
                (store-world-algebraic-spec-in-memory
                    $world $perspective $specification))
           ($_logged
                (pipeline-success
                    algebraic_spec_stored
                    $world $perspective $methodName)))
        $methodName))

(= (get-world-algebraic-spec $world $perspective)
    (let $methodName (algspec-space-method-name $world $perspective)
        (match &algspecspace
            (= ($methodName) $specification)
            $specification)))

(= (has-world-algebraic-spec $world $perspective)

        (let $methodName (algspec-space-method-name $world $perspective)
        (if (== (collapse
                    (match &algspecspace
                        (= ($methodName) $specification)
                        $specification))
                ())
            False
            True
            )))


;; Hydrate the session-local space once from the disk cache and from accepted
;; records in AlgebraicSpecificationVerified.jsonl. Loading uses the in-memory
;; operation so startup does not append duplicate persistent records.
(= (load-persisted-world-algebraic-specs ())
    ())
(= (load-persisted-world-algebraic-specs $entries)
    (let* (((CachedAlgebraicSpec
                $world $perspective $specification)
                (car-atom $entries))
           ($_stored
                (store-world-algebraic-spec-in-memory
                    $world $perspective $specification)))
        (load-persisted-world-algebraic-specs
            (cdr-atom $entries))))

(= (hydrate-algebraic-specification-space)
    (let $entries
            (sread
                (py-call
                    (builtins.load_persisted_algebraic_specs)))
        (load-persisted-world-algebraic-specs $entries)))

!(hydrate-algebraic-specification-space)

;; Persist the first generated result. A zero-result build is logged and
;; skipped so one problematic world cannot suppress the final Concept result.
(= (store-built-world-algebraic-spec $world $perspective ())
    (let $_logged
            (pipeline-error
                algebraic_spec_generation_failed
                $world $perspective no_specification_returned)
        False))
(= (store-built-world-algebraic-spec $world $perspective $specifications)
    (store-world-algebraic-spec
        $world $perspective (car-atom $specifications)))

;; Build only on a cache miss. collapse converts a no-result builder call to
;; (), allowing the recursive world-storage stage to continue.
(= (ensure-world-algebraic-spec $world $perspective)
    (if (has-world-algebraic-spec $world $perspective)
        (let* (($methodName
                    (algspec-space-method-name $world $perspective))
               ($_logged
                    (pipeline-success
                        algebraic_spec_cache_hit
                        $world $perspective $methodName)))
            $methodName)
        (let* (($_logged
                    (pipeline-success
                        algebraic_spec_cache_miss
                        $world $perspective building))
               ($specifications
                    (collapse
                        (build-algebraic-spec $world $perspective))))
            (store-built-world-algebraic-spec
                $world $perspective $specifications))))

;; Explicit refresh path that always invokes the builder and replaces the
;; perspective-qualified method.
(= (rebuild-world-algebraic-spec $world $perspective)
    (let* (($_logged
                (pipeline-success
                    algebraic_spec_forced_rebuild
                    $world $perspective rebuilding))
           ($specification
                (build-algebraic-spec $world $perspective)))
        (store-world-algebraic-spec
            $world $perspective $specification)))

(= (list-world-algebraic-spec-methods)
    (get-atoms &algspecspace))
