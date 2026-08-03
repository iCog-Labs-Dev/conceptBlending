!(import! &self ../../../../../../../PeTTa/lib/lib_import)
!(import! &self ../../metta/logging/PipelineLogger)
!(import! &self ../../metta/algebraic_spec/AlgebraicSpecificationSpace)

!(bind! &algspecbuildcalls (new-space))

(= (build-algebraic-spec $world $perspective)
    (let $_recorded
            (add-atom &algspecbuildcalls
                (BuildCall $world $perspective))
        (stub-algebraic-spec $world $perspective)))

!(println! "===== perspective-qualified method name =====")
!(algspec-space-method-name computer functional_use)

!(println! "===== first stored specification =====")
!(store-world-algebraic-spec
    computer
    functional_use
    (Concept computer functional_use (spec first_version)))
!(get-world-algebraic-spec computer functional_use)
!(has-world-algebraic-spec computer functional_use)

!(println! "===== another perspective has an independent method =====")
!(store-world-algebraic-spec
    computer
    descriptive_property
    (Concept computer descriptive_property (spec descriptive_version)))
!(get-world-algebraic-spec computer descriptive_property)

!(println! "===== replacement leaves exactly one functional-use definition =====")
!(store-world-algebraic-spec
    computer
    functional_use
    (Concept computer functional_use (spec replacement_version)))
!(get-world-algebraic-spec computer functional_use)
!(size-atom
    (collapse
        (match &algspecspace
            (= (computer-functional_use-spec) $specification)
            $specification)))

!(println! "===== stored method equations =====")
!(list-world-algebraic-spec-methods)

!(println! "===== ensure builds a missing specification only once =====")
!(ensure-world-algebraic-spec cached_world functional_use)
!(ensure-world-algebraic-spec cached_world functional_use)
!(size-atom
    (collapse
        (match &algspecbuildcalls
            (BuildCall cached_world functional_use)
            (BuildCall cached_world functional_use))))

!(println! "===== another perspective is an independent cache entry =====")
!(ensure-world-algebraic-spec cached_world descriptive_property)
!(size-atom
    (collapse
        (match &algspecbuildcalls
            (BuildCall cached_world descriptive_property)
            (BuildCall cached_world descriptive_property))))

!(println! "===== forced rebuild invokes the builder again =====")
!(rebuild-world-algebraic-spec cached_world functional_use)
!(size-atom
    (collapse
        (match &algspecbuildcalls
            (BuildCall cached_world functional_use)
            (BuildCall cached_world functional_use))))
