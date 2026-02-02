; UNIT TEST: GENERATION & GENERALIZATION LOGIC

; 1. Import the Module to be tested
!(import! &self generalization_allly )

; 2. Test Step A: Spec Generation
!(println! ">>> [TEST 1] Testing algspec_builder (House & Boat)...")

!(let $specs (algspec_builder house boat)
   (let ($specA $specB) $specs
      (superpose (
         (println! "; [PASS] Specs generated successfully.")
         ; (println! $specA) ; Uncomment to see full spec
         
         ; 3. Test Step B: Generalization
         !(println! "\n>>> [TEST 2] Testing generalization_builder...")
         
         (let $G (generalization_builder $specA $specB)
             (superpose (
                 (println! "; [PASS] Generalization G found.")
                 (println! "; Result preview:")
                 (println! $G)
             ))
         )
      ))
   )
)