;; Deterministic smoke test for the public bootstrap and both relocated KBs.
!(import! &self Pipeline)

!(pipeline-loaded)
!(property-world-formula (stv 0.8 0.9) (stv 0.5 0.7))
!(query-concept-properties-from-kb computer functional_use)
!(query-property-worlds-from-kb process_information functional_use)
;; Callable-named worlds must remain data when wrapped for final output.
!(wrap-world-names (sread "(library surfing_web search_engine)"))
!(build-concept-property-world-specifications computer functional_use)
