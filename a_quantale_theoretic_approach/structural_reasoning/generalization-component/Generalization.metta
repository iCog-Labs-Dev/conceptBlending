;; Public bootstrap for the Cartesian algebraic-spec generalization component.
;; Keep query files beside this file because PeTTa resolves nested imports and
;; static KB paths from the top-level file.

!(import! &self ../../../../PeTTa/lib/lib_import)
;; Import modules
!(import! &self metta/Common)
!(import! &self metta/GeneralizationDTLhelper)
!(import! &self metta/GeneralizationDTL)
!(static-import! &kb kb/lcg_kb)
!(import! &self metta/synthesizers)
!(import! &self "python/generalization_event_logger.py")
!(import! &self metta/logging/GeneralizationLogger)
!(import! &self "python/lcggenerator.py")
!(import! &self "python/generalization_support.py")
!(import! &self metta/GeneralizationPipeline)
; !(let $lcgs (py-call (lcggenerator.generate_lcg_rules 2)) (let $slcgs (sread $lcgs) (superpose $slcgs)))
