; GENERALIZATION WRAPPER
!(import! &self libs)
!(import! &self knowledge_base)

; 1. Load the Specs we just saved
!(load-ascii &self output/specs.metta)

; 2. Define the Generalizer Logic
(=(least_generalization_builder $concept1 $concept2)
    ; Fetch the specs directly from AtomSpace (OutputSpec isn't needed if we load the file directly)
    (let $specA (match &self (Concept House $x) (Concept House $x))
        (let $specB (match &self (Concept Boat $y) (Concept Boat $y))
            (gpt_generalization_helper ("House" $specA) ("Boat" $specB))
        )
    )
)

; 3. Run and Print
!(println! ">>> Generating Generalization (finding shared structure)...")
!(let $res (least_generalization_builder "House" "Boat")
    (superpose (
        (println! "\n; ================= GENERALIZATION (G) =================")
        (println! $res)
        (println! "")
    ))
)