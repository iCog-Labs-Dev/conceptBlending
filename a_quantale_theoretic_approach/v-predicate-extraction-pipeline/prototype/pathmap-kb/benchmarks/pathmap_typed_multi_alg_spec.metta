; Multiple algebraic-specification builds through pathmap_kb_ffi's typed path.
; Build the FFI first with: cd /home/wdufera/PeTTa/pathmap_kb_ffi && bash build.sh
; Run from PeTTa with:
;   /home/wdufera/PeTTa/run.sh /home/wdufera/conceptBlending/a_quantale_theoretic_approach/v-predicate-extraction-pipeline/prototype/pathmap-kb/benchmarks/pathmap_typed_multi_alg_spec.metta

!(pathmap-open! typed-kb "/home/wdufera/conceptBlending/a_quantale_theoretic_approach/v-predicate-extraction-pipeline/prototype/pathmap-kb/index-full")

; Real functional-use concepts from the complete shard set.
!(pathmap-build-specification typed-kb functional_use computer)
!(pathmap-build-specification typed-kb functional_use phone)
!(pathmap-build-specification typed-kb functional_use mobile_phone)
!(pathmap-build-specification typed-kb functional_use digital_television)
!(pathmap-build-specification typed-kb functional_use letter)
!(pathmap-build-specification typed-kb functional_use broom)

; The same index can switch perspectives while retaining the typed FFI path.
!(pathmap-build-specification typed-kb taxonomic_kind dog)
!(pathmap-build-specification typed-kb taxonomic_kind computer)
!(pathmap-build-specification typed-kb artifact_kind computer)
!(pathmap-build-specification typed-kb spatial_context hospital)
!(pathmap-build-specification typed-kb descriptive_property human)

; Repeat the largest query to exercise the fully warm typed/cached path.
!(pathmap-build-specification typed-kb functional_use computer)

!(pathmap-close! typed-kb)
