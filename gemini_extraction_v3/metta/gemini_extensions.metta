; =======================================================
; gemini_extraction/metta/gemini_extensions.metta
;
; Registers Gemini-backed alternatives to the llm: atoms
; used in the existing pipeline.
;
; Usage: !(import! &self gemini_extraction:metta:gemini_extensions)
;
; Provides:
;   gemini:generate-spec  -- alternative to llm:generate-spec
;   gemini:generate-gen   -- alternative to llm:generate-gen
;   gemini:find-morph     -- alternative to llm:find-morph
;   gemini:colimit        -- alternative to math:colimit
;
; These atoms are registered via Python (same pattern as extensions.py).
; See gemini_extraction/python/gemini_atoms.py for the registration code.
;
; To run the full pipeline with Gemini instead of OpenAI, import this
; file and call (gemini:pipeline $concept1 $concept2) -- or swap
; individual atoms in master_pipeline.metta by replacing llm: with gemini:
; =======================================================

!(import! &self gemini_extraction:python:gemini_atoms)

; ── Wrappers matching the calling convention of master_pipeline.metta ─────────

; Stage 1: Spec generation (mirrors generate_specs in master_pipeline.metta)
(= (gemini:generate-specs $c1 $c2)
   (let $context1 (let $fetched1 (main-fetch $c1) (cons-atom Context $fetched1))
      (let $context2 (let $fetched2 (main-fetch $c2) (cons-atom Context $fetched2))
         (collapse (gemini:generate-spec ($c1 $context1) ($c2 $context2)))
      )
   )
)

; Stage 2: Generalization (mirrors find_generalization in master_pipeline.metta)
(= (gemini:find-generalization $specA $specB)
   (gemini:generate-gen $specA $specB)
)

; Stage 3: Morphism (mirrors find_morphism in master_pipeline.metta)
(= (gemini:find-morphism $specG $specTarget)
   (gemini:find-morph $specG $specTarget)
)

; Stage 4: Colimit / Blend (mirrors compute_blend in master_pipeline.metta)
(= (gemini:compute-blend $specA $specB $specG $morphA $morphB)
   (gemini:colimit $specA $specB $specG $morphA $morphB)
)

; ── Full pipeline (drop-in for master_pipeline.metta) ─────────────────────────

(= (gemini:pipeline $c1 $c2)
   (let $specs (gemini:generate-specs $c1 $c2)
      (let ($specA $specB) $specs
         (let $specG (gemini:find-generalization $specA $specB)
            (let $morphA (gemini:find-morphism $specG $specA)
               (let $morphB (gemini:find-morphism $specG $specB)
                  (gemini:compute-blend $specA $specB $specG $morphA $morphB)
               )
            )
         )
      )
   )
)

; ── Example call ──────────────────────────────────────────────────────────────
; !(gemini:pipeline house boat)
; !(gemini:pipeline "Solar Energy" "Water Purification")
