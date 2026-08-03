;; End-to-end logging smoke test. Run with verifier modes off to exercise the
;; complete deterministic pipeline without purchasing model calls.
!(import! &self ../../../../../../../PeTTa/lib/lib_import)
!(import! &self ../../../synthesizers)
!(import! &self ../../../llm)
!(import! &self ../../metta/logging/PipelineLogger)
!(static-import! &algkb ../../kb/generated/AlgebraicSpecificationKB)
!(static-import! &propertyworldkb ../../kb/generated/PropertyWorldKB)
!(import! &self ../../metta/algebraic_spec/AlgebraicSpecificationDataLayer)
!(import! &self ../../metta/algebraic_spec/AlgebraicSpecificationSpace)
!(import! &self ../../metta/property_world/PropertyWorldDataLayer)

;; A world name can collide with a registered PeTTa callable. Logger details
;; must preserve the returned list as data instead of reducing its head.
!(let $details (sread "(library surfing_web search_engine)")
    (pipeline-success worlds_verified find_information functional_use $details))

!(build-concept-property-world-specifications
    pipeline_smoke_concept functional_use)
