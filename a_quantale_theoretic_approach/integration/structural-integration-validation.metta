;; PeTTa currently requires eager component initializers at the top level.
;; structural-integration.metta is the corresponding production bootstrap.
!(import! &self ../../../PeTTa/lib/lib_import)
!(import! &self "python/integration_support.py")
!(integration_support.configure_component_roots)
(= (py-eval $str)
   (let $dict (py-call (dict))
      (py-call (quote (eval $str $dict $dict)))))
!(import! &self ../v-predicate-extraction-pipeline/synthesizers)
!(import! &self ../v-predicate-extraction-pipeline/metta/logging/PipelineLogger)
!(static-import! &algkb ../v-predicate-extraction-pipeline/kb/generated/AlgebraicSpecificationKB)
!(static-import! &propertyworldkb ../v-predicate-extraction-pipeline/kb/generated/PropertyWorldKB)
!(import! &self ../v-predicate-extraction-pipeline/metta/algebraic_spec/AlgebraicSpecificationDataLayer)
!(import! &self ../v-predicate-extraction-pipeline/metta/algebraic_spec/AlgebraicSpecificationSpace)
!(import! &self ../v-predicate-extraction-pipeline/metta/property_world/PropertyWorldDataLayer)
!(import! &self ../structural_reasoning/generalization-component/metta/Common)
!(import! &self ../structural_reasoning/generalization-component/metta/GeneralizationDTLhelper)
!(import! &self ../structural_reasoning/generalization-component/metta/GeneralizationDTL)
!(static-import! &kb ../structural_reasoning/generalization-component/kb/lcg_kb)
!(import! &self "../structural_reasoning/generalization-component/python/generalization_event_logger.py")
!(import! &self ../structural_reasoning/generalization-component/metta/logging/GeneralizationLogger)
!(import! &self "../structural_reasoning/generalization-component/python/lcggenerator.py")
!(import! &self "../structural_reasoning/generalization-component/python/generalization_support.py")
!(import! &self ../structural_reasoning/generalization-component/metta/GeneralizationPipeline)
!(import! &self metta/structural-integration-pipeline)
(= (integration-left-vp)
   (Concept boat functional_use
      (Properties
         ((move_on_water) ((boat) (ferry))))))

(= (integration-right-vp)
   (Concept car functional_use
      (Properties
         ((move_on_land) ((car) (bus))))))

(= (integration-left-spec)
   (Concept boat functional_use
      (spec
         (sorts ((boat (stv 0.95 0.90)) (cargo (stv 0.80 0.70))))
         (ops (((operation move_boat (arrow boat cargo boat))
                  (stv 0.90 0.80))))
         (preds (((usable boat) (stv 0.88 0.77))))
         (axioms (((=> true (usable boat)) (stv 0.80 0.70)))))))

(= (integration-right-spec)
   (Concept car functional_use
      (spec
         (sorts ((car (stv 0.92 0.85)) (cargo (stv 0.90 0.65))))
         (ops (((operation move_car (arrow car cargo car))
                  (stv 0.85 0.75))))
         (preds (((usable car) (stv 0.82 0.72))))
         (axioms (((=> true (usable car)) (stv 0.75 0.65)))))))

!(println!
   (Prepare-structural-result
      (collapse
         (prepare-structural-blend-from-texts
            vehicle functional_use
            (repr (reduce (integration-left-vp)))
            (repr (reduce (integration-right-vp)))
            (repr (reduce (integration-left-spec)))
            (repr (reduce (integration-right-spec)))))))
