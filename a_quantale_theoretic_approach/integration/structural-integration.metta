;; V-predicate extraction -> generic-space construction integration.
;;
;; Enriched Hom construction is deliberately not synthesized here. The result
;; records that boundary explicitly so a future Hom pipeline can fill it.

!(import! &self ../../../PeTTa/lib/lib_import)

!(import! &self "python/integration_support.py")
!(integration_support.configure_component_roots)

;; Minimal Python evaluator required by the V-predicate data-layer bootstrap.
(= (py-eval $str)
   (let $dict (py-call (dict))
      (py-call (quote (eval $str $dict $dict)))))

;; V-predicate extraction pipeline bootstrap. Its legacy llm.metta facade is
;; not needed: verification modules call the official Python SDK directly.
!(import! &self ../v-predicate-extraction-pipeline/synthesizers)
!(import! &self ../v-predicate-extraction-pipeline/metta/logging/PipelineLogger)
!(static-import! &algkb
    ../v-predicate-extraction-pipeline/kb/generated/AlgebraicSpecificationKB)
!(static-import! &propertyworldkb
    ../v-predicate-extraction-pipeline/kb/generated/PropertyWorldKB)
!(import! &self
    ../v-predicate-extraction-pipeline/metta/algebraic_spec/AlgebraicSpecificationDataLayer)
!(import! &self
    ../v-predicate-extraction-pipeline/metta/algebraic_spec/AlgebraicSpecificationSpace)
!(import! &self
    ../v-predicate-extraction-pipeline/metta/property_world/PropertyWorldDataLayer)

;; Generalization component bootstrap. The extraction-pipeline synthesizer is
;; compatible with the generalizer, so it is loaded only once above.
!(import! &self
    ../structural_reasoning/generalization-component/metta/Common)
!(import! &self
    ../structural_reasoning/generalization-component/metta/GeneralizationDTLhelper)
!(import! &self
    ../structural_reasoning/generalization-component/metta/GeneralizationDTL)
!(static-import! &kb
    ../structural_reasoning/generalization-component/kb/lcg_kb)
!(import! &self
    "../structural_reasoning/generalization-component/python/generalization_event_logger.py")
!(import! &self
    ../structural_reasoning/generalization-component/metta/logging/GeneralizationLogger)
!(import! &self
    "../structural_reasoning/generalization-component/python/lcggenerator.py")
!(import! &self
    "../structural_reasoning/generalization-component/python/generalization_support.py")
!(import! &self
    ../structural_reasoning/generalization-component/metta/GeneralizationPipeline)
!(import! &self metta/structural-integration-pipeline)
