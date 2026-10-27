!(import! &self ../../../../../../../PeTTa/lib/lib_import)
!(import! &self ../../../synthesizers)
!(import! &self ../../../llm)
!(import! &self ../../metta/logging/PipelineLogger)
!(static-import! &algkb ../../kb/generated/AlgebraicSpecificationKB)
!(static-import! &propertyworldkb ../../kb/generated/PropertyWorldKB)
!(import! &self ../../metta/algebraic_spec/AlgebraicSpecificationDataLayer)
!(import! &self ../../metta/algebraic_spec/AlgebraicSpecificationSpace)
!(import! &self ../../metta/property_world/PropertyWorldDataLayer)

; !(println! "===== raw KB properties remain available for inspection =====")
; !(query-concept-properties-from-kb car functional_use)

; !(println! "===== public properties pass through final verification (max 10) =====")
; !(query-concept-properties computer functional_use)
; !(size-atom (query-concept-properties computer functional_use))

; !(println! "===== internal property refs remain available =====")
; !(query-concept-property-refs computer functional_use)

; !(println! "===== low-level scoped worlds by PropertyRef =====")
; !(query-property-worlds-by-ref
;     (PropertyRef property_key_computer_functional_use_process_information
;                  process_information functional_use)
;     functional_use)

; !(println! "===== raw global ranked worlds remain available (max 15) =====")
; !(query-property-worlds-from-kb access_internet functional_use)
; !(size-atom
;     (query-property-worlds-from-kb access_internet functional_use))

; !(println! "===== public global worlds pass through final verification (max 3) =====")
 ;!(query-property-worlds access_internet functional_use)
 ;!(size-atom (query-property-worlds access_internet functional_use))

; !(println! "===== ranking helpers merge duplicates and cap output =====")
; !(scored-world-names
;     (take-ranked-worlds
;         (rank-scored-worlds
;             (merge-scored-worlds
;                 ((ScoredWorld weak_world functional_use 0.40 0.80 1)
;                  (ScoredWorld shared_world functional_use 0.72 0.70 1)
;                  (ScoredWorld strong_world functional_use 0.90 0.90 1)
;                  (ScoredWorld shared_world information_computational 0.80 0.85 1))
;                 ())
;             ())
;         2))

; !(println! "===== pure stable world deduplication remains available =====")
; !(filter-unique-possible-worlds
;     (((WorldRef computer functional_use)
;       (WorldRef server functional_use))
;      ((WorldRef server functional_use)
;       (WorldRef computer economic_ownership)
;       (WorldRef data_center functional_use))))

; !(println! "===== pure stable property deduplication remains available =====")
; !(filter-unique-properties
;     ((PropertyRef functional_process process_information functional_use)
;      (PropertyRef information_process process_information information_computational)
;      (PropertyRef functional_store store_information functional_use)))

;; Stand-in verifies that the final builder consumes verified names and
;; dispatches every unique world under its effective perspective.
; (= (build-algebraic-spec $world $perspective)
;     (stub-algebraic-spec $world $perspective))

!(println! "===== final builder consumes verified properties and worlds =====")
!(build-concept-property-world-specifications phone functional_use)
;!(get-world-algebraic-spec phone functional_use)
;!(list-world-algebraic-spec-methods)
