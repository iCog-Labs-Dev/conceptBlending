;; Second half of the cross-process validation. The persisted method must be
;; hydrated before ensure is called, so this fallback builder must remain idle.
!(import! &self ../../metta/logging/PipelineLogger)
!(import! &self ../../metta/algebraic_spec/AlgebraicSpecificationSpace)

!(bind! &persistencebuildcalls (new-space))

(= (build-algebraic-spec $world $perspective)
    (let $_recorded
            (add-atom
                &persistencebuildcalls
                (UnexpectedBuildCall $world $perspective))
        (Concept $world $perspective
            (spec (source second_process)))))

!(has-world-algebraic-spec persistent_world functional_use)
!(ensure-world-algebraic-spec persistent_world functional_use)
!(get-world-algebraic-spec persistent_world functional_use)
!(==
    (collapse
        (match &persistencebuildcalls
            (UnexpectedBuildCall persistent_world functional_use)
            (UnexpectedBuildCall persistent_world functional_use)))
    ())
