;; First half of the cross-process validation. The cache path is supplied with
;; ALGEBRAIC_SPEC_SPACE_CACHE by the runner.
!(import! &self ../../metta/logging/PipelineLogger)
!(import! &self ../../metta/algebraic_spec/AlgebraicSpecificationSpace)

!(bind! &persistencebuildcalls (new-space))

(= (build-algebraic-spec $world $perspective)
    (let $_recorded
            (add-atom
                &persistencebuildcalls
                (BuildCall $world $perspective))
        (Concept $world $perspective
            (spec (source first_process)))))

!(ensure-world-algebraic-spec persistent_world functional_use)
!(get-world-algebraic-spec persistent_world functional_use)
!(==
    (collapse
        (match &persistencebuildcalls
            (BuildCall persistent_world functional_use)
            (BuildCall persistent_world functional_use)))
    ((BuildCall persistent_world functional_use)))
