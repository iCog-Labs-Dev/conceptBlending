!(import! &self ../../../../../../../PeTTa/lib/lib_import)
!(import! &self ../../../synthesizers)
!(import! &self ../../../llm)
!(import! &self ../../metta/logging/PipelineLogger)
!(static-import! &algkb ../../kb/generated/AlgebraicSpecificationKB)
!(static-import! &propertyworldkb ../../kb/generated/PropertyWorldKB)
!(import! &self ../../metta/algebraic_spec/AlgebraicSpecificationDataLayer)
!(import! &self ../../metta/algebraic_spec/AlgebraicSpecificationSpace)
!(import! &self ../../metta/property_world/PropertyWorldDataLayer)

!(println! "===== unique WorldRefs retain distinct perspectives =====")
!(filter-unique-possible-worlds
    (((WorldRef computer functional_use)
      (WorldRef computer functional_use))
     ((WorldRef computer descriptive_property)
      (WorldRef server functional_use))))

!(println! "===== batch generation stores methods and returns no references =====")
!(store-world-algebraic-spec
    computer functional_use
    (stub-algebraic-spec computer functional_use))
!(store-world-algebraic-spec
    computer descriptive_property
    (stub-algebraic-spec computer descriptive_property))
!(store-world-algebraic-spec
    server functional_use
    (stub-algebraic-spec server functional_use))
!(store-world-algebraic-specifications
    ((WorldRef computer functional_use)
     (WorldRef computer descriptive_property)
     (WorldRef server functional_use)))

!(get-world-algebraic-spec computer functional_use)
!(get-world-algebraic-spec computer descriptive_property)
!(get-world-algebraic-spec server functional_use)

!(println! "===== repeating a cached batch remains a no-op =====")
!(store-world-algebraic-specifications
    ((WorldRef computer functional_use)
     (WorldRef computer descriptive_property)
     (WorldRef server functional_use)))

!(println! "===== a pre-populated specification is also a cache hit =====")
!(store-world-algebraic-spec
    prebuilt_world
    functional_use
    (prebuilt-specification))
!(ensure-world-algebraic-spec prebuilt_world functional_use)
!(get-world-algebraic-spec prebuilt_world functional_use)

!(println! "===== final result contains properties but no specification payload =====")
!(store-world-specs-and-build-concept-result
    computer
    functional_use
    (((process_information) ((computer) (server))))
    ((WorldRef computer functional_use)
     (WorldRef server functional_use)))
