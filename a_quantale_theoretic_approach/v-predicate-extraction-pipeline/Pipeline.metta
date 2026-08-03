;; Public bootstrap for the complete V-predicate extraction pipeline.
;; Keep the query file beside this file (or run from this directory), because
;; PeTTa resolves nested imports and static KB paths from the top-level file.

(= (pipeline-loaded) True)

!(import! &self ../../../PeTTa/lib/lib_import)
!(import! &self synthesizers)
!(import! &self llm)
!(import! &self metta/logging/PipelineLogger)

;; Each large KB is bound exactly once by the public bootstrap.
!(static-import! &algkb kb/generated/AlgebraicSpecificationKB)
!(static-import! &propertyworldkb kb/generated/PropertyWorldKB)

!(import! &self metta/algebraic_spec/AlgebraicSpecificationDataLayer)
!(import! &self metta/algebraic_spec/AlgebraicSpecificationSpace)
!(import! &self metta/property_world/PropertyWorldDataLayer)
