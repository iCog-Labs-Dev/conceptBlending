; Load the final verifier from either a dependent-types working directory or
; the repository root. V_PREDICATE_PIPELINE_ROOT can override discovery.
!(py-eval "(lambda os,sys,importlib,builtins:(lambda root:(sys.path.insert(0,os.path.join(root,'python','storage')),sys.path.insert(0,os.path.join(root,'python','verification')),setattr(builtins,'verify_algebraic_spec',importlib.import_module('algebraic_spec_verifier').verify_algebraic_spec),setattr(builtins,'load_verified_algebraic_spec',importlib.import_module('algebraic_spec_verifier').load_verified_algebraic_spec),0)[-1])(os.getenv('V_PREDICATE_PIPELINE_ROOT',os.getcwd() if os.path.isdir(os.path.join(os.getcwd(),'python','verification')) else os.path.join(os.getcwd(),'v-predicate-extraction-pipeline') if os.path.isdir(os.path.join(os.getcwd(),'v-predicate-extraction-pipeline','python')) else os.path.join(os.getcwd(),'metta','pln','dependent-types','v-predicate-extraction-pipeline'))))(__import__('os'),__import__('sys'),__import__('importlib'),__import__('builtins'))")

;; Data-layer algebraic specification builder.
;;
;; AlgebraicSpecificationKB.metta is generated from ConceptNet-style relation
;; files. The generator normalizes raw relations into perspective-tagged:
;;   has_sort
;;   has_operation
;;   operation_signature
;;   has_predicate
;;   has_axiom
;;
;; The synthesizer remains responsible for fetching only the features that
;; match the requested concept and perspective. Perspective matching is
;; generated in AlgebraicSpecificationKB.metta and loaded into &algkb, so a broad request such as
;; descriptive_property can collect narrow perspectives such as
;; physical_attribute, safety_risk, and information_computational.

;; Keep returned specifications readable while leaving the generated KB rich.
;; Each spec section is capped independently at retrieval time.

(= (max-spec-items)
    (S (S (S (S (S
    (S (S (S (S (S
    (S (S (S (S (S Z))))))))))))))))

(= (take-spec-items Z $items) ())
(= (take-spec-items (S $n) $items)
    (if (== $items ())
        ()
        (cons-atom
            (car-atom $items)
            (take-spec-items $n (cdr-atom $items)))))

(= (limit-spec-items $items)
    (take-spec-items (max-spec-items) $items))

(= (spec-feature-formula (stv $featureS $featureC)
                         (stv $perspectiveS $perspectiveC))
    (stv (* $featureS $perspectiveS)
         (min $featureC $perspectiveC)))

(= (spec-operation-formula (stv $featureS $featureC)
                           (stv $signatureS $signatureC)
                           (stv $perspectiveS $perspectiveC))
    (stv (* $featureS (* $signatureS $perspectiveS))
         (min $featureC (min $signatureC $perspectiveC))))

(: spec-sort-rule (-> Atom))
(= (spec-sort-rule)
    (: SpecSort
        (-> (≞ (has_sort $edge $concept $featurePerspective $sort) $featureTv)
            (≞ (perspective_match $requestedPerspective $featurePerspective $perspectiveClass) $perspectiveTv)
            (≞ (spec-sort $concept $requestedPerspective $perspectiveClass $sort)
                (Method spec-feature-formula $featureTv $perspectiveTv)))))

(: spec-operation-rule (-> Atom))
(= (spec-operation-rule)
    (: SpecOperation
        (-> (≞ (has_operation $edge $concept $featurePerspective $operation) $featureTv)
            (≞ (operation_signature $edge $signature) $signatureTv)
            (≞ (perspective_match $requestedPerspective $featurePerspective $perspectiveClass) $perspectiveTv)
            (≞ (spec-operation $concept $requestedPerspective $perspectiveClass (operation $operation $signature))
                (Method spec-operation-formula $featureTv $signatureTv $perspectiveTv)))))

(: spec-predicate-rule (-> Atom))
(= (spec-predicate-rule)
    (: SpecPredicate
        (-> (≞ (has_predicate $edge $concept $featurePerspective $predicate) $featureTv)
            (≞ (perspective_match $requestedPerspective $featurePerspective $perspectiveClass) $perspectiveTv)
            (≞ (spec-predicate $concept $requestedPerspective $perspectiveClass $predicate)
                (Method spec-feature-formula $featureTv $perspectiveTv)))))

(: spec-axiom-rule (-> Atom))
(= (spec-axiom-rule)
    (: SpecAxiom
        (-> (≞ (has_axiom $edge $concept $featurePerspective $axiom) $featureTv)
            (≞ (perspective_match $requestedPerspective $featurePerspective $perspectiveClass) $perspectiveTv)
            (≞ (spec-axiom $concept $requestedPerspective $perspectiveClass $axiom)
                (Method spec-feature-formula $featureTv $perspectiveTv)))))

(: spec-rb (-> Atom))
(= (spec-rb)
    (superpose
        ((spec-sort-rule)
         (spec-operation-rule)
         (spec-predicate-rule)
         (spec-axiom-rule))))


(= (clean-spec-sort (: $proof (≞ (spec-sort $concept $perspective $perspectiveClass $sort) $tv)))
    (cons-atom $sort (cons-atom $tv ())))
(= (clean-spec-operation (: $proof (≞ (spec-operation $concept $perspective $perspectiveClass $operation) $tv)))
    (cons-atom $operation (cons-atom $tv ())))
(= (clean-spec-predicate (: $proof (≞ (spec-predicate $concept $perspective $perspectiveClass $predicate) $tv)))
    (cons-atom $predicate (cons-atom $tv ())))
(= (clean-spec-axiom (: $proof (≞ (spec-axiom $concept $perspective $perspectiveClass $axiom) $tv)))
    (cons-atom $axiom (cons-atom $tv ())))

(= (clean-spec-sorts ()) ())
(= (clean-spec-sorts $items)
    (cons-atom
        (clean-spec-sort (car-atom $items))
        (clean-spec-sorts (cdr-atom $items))))

(= (clean-spec-operations ()) ())
(= (clean-spec-operations $items)
    (cons-atom
        (clean-spec-operation (car-atom $items))
        (clean-spec-operations (cdr-atom $items))))

(= (clean-spec-predicates ()) ())
(= (clean-spec-predicates $items)
    (cons-atom
        (clean-spec-predicate (car-atom $items))
        (clean-spec-predicates (cdr-atom $items))))

(= (clean-spec-axioms ()) ())
(= (clean-spec-axioms $items)
    (cons-atom
        (clean-spec-axiom (car-atom $items))
        (clean-spec-axioms (cdr-atom $items))))

(= (synthesize-spec-sorts $concept $perspective)
    (clean-spec-sorts
        (limit-spec-items
            (collapse
                (synthesize
                    (: $proof (≞ (spec-sort $concept $perspective $perspectiveClass $sort) $tv))
                    &algkb
                    spec-rb
                    (S Z))))))

(= (synthesize-spec-operations $concept $perspective)
    (clean-spec-operations
        (limit-spec-items
            (collapse
                (synthesize
                    (: $proof (≞ (spec-operation $concept $perspective $perspectiveClass $operation) $tv))
                    &algkb
                    spec-rb
                    (S Z))))))

(= (synthesize-spec-predicates $concept $perspective)
    (clean-spec-predicates
        (limit-spec-items
            (collapse
                (synthesize
                    (: $proof (≞ (spec-predicate $concept $perspective $perspectiveClass $predicate) $tv))
                    &algkb
                    spec-rb
                    (S Z))))))

(= (synthesize-spec-axioms $concept $perspective)
    (clean-spec-axioms
        (limit-spec-items
            (collapse
                (synthesize
                    (: $proof (≞ (spec-axiom $concept $perspective $perspectiveClass $axiom) $tv))
                    &algkb
                    spec-rb
                    (S Z))))))

(= (build-algebraic-spec-unverified $concept $perspective)
    (let* (($sorts (synthesize-spec-sorts $concept $perspective))
           ($operations (synthesize-spec-operations $concept $perspective))
           ($predicates (synthesize-spec-predicates $concept $perspective))
           ($axioms (synthesize-spec-axioms $concept $perspective)))
        (Concept $concept $perspective
            (spec
                (sorts $sorts)
                (ops $operations)
                (preds $predicates)
                (axioms $axioms)))))

(= (verify-built-algebraic-spec $concept $perspective $candidate)
    (let $verifiedText
                (py-call
                    (builtins.verify_algebraic_spec
                        $concept
                        $perspective
                        $candidate))
        (sread $verifiedText)))

(= (build-algebraic-spec $concept $perspective)
    (let* (($_started
                (pipeline-success
                    algebraic_spec_generation_started
                    $concept $perspective generating))
           ($candidate
                (build-algebraic-spec-unverified $concept $perspective))
           ($_generated
                (pipeline-success
                    algebraic_spec_generated
                    $concept $perspective candidate_ready))
           ($verified
                (verify-built-algebraic-spec
                    $concept $perspective $candidate))
           ($_verified
                (pipeline-success
                    algebraic_spec_verified
                    $concept $perspective verified)))
        $verified))

(= (load-verified-algebraic-spec $concept $perspective)
    (sread
        (py-call
            (builtins.load_verified_algebraic_spec
                $concept
                $perspective))))

; !(println! "===== Data-layer local spec: socialize under behavioral_process =====")
;!(build-algebraic-spec-unverified sending_e_mail functional_use)
;!(build-algebraic-spec-unverified computer functional_use)
; !(build-algebraic-spec lawyer economic_ownership)

; !(println! "===== Data-layer local spec: socialize under prerequisite_action =====")
; !(build-algebraic-spec socialize prerequisite_action)

; !(println! "===== Data-layer local spec: start_fire under behavioral_process =====")
; !(build-algebraic-spec start_fire behavioral_process)

; !(println! "===== Data-layer local spec: start_fire under prerequisite_action =====")
; !(build-algebraic-spec start_fire prerequisite_action)

; !(println! "===== Data-layer local spec: computer under taxonomic_classification =====")
; !(build-algebraic-spec computer taxonomic_classification)

; !(println! "===== Data-layer local spec: abstract_computer_file under information_computational =====")
; !(build-algebraic-spec abstract_computer_file information_computational)

; !(println! "===== Data-layer local spec: car under functional_use =====")
; !(build-algebraic-spec car functional_use)

; !(println! "===== Data-layer local spec: human under taxonomic_classification =====")
; !(build-algebraic-spec human taxonomic_classification)

; !(build-algebraic-spec human descriptive_property)
; !(build-algebraic-spec theorem structural_composition)

; !(build-algebraic-spec human behavioral_process)
; !(build-algebraic-spec write information_computational)
; !(println! "===== Data-layer local spec: car under economic_ownership =====")
; !(build-algebraic-spec car economic_ownership)

; !(println! "===== Data-layer local spec: computer under descriptive_property with fallback =====")
; !(build-algebraic-spec computer descriptive_property)

; !(println! "===== Data-layer missing parts: computer under descriptive_property =====")
; !(missing-spec-parts computer descriptive_property)

;; This is intentionally not executed during local tests because it calls Gemini
;; when any section is missing:
;; !(build-algebraic-spec-with-fallback unknown_concept descriptive_property)
