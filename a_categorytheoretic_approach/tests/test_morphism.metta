; UNIT TEST: MORPHISM LOGIC (SIMPLIFIED)
; ======================================
!(register-module! &self ../../a_categorytheoretic_approach)
!(import! &self a_categorytheoretic_approach:utils:extensions)

; 2. Define Dummy Data
(= (get-test-G) 
   (superpose ((Concept Generic (spec (sorts ((Medium 1.0))) (ops ((:on Medium))))))))
(= (get-test-A) 
   (superpose ((Concept Boat (spec (sorts ((Water 1.0))) (ops ((:on Water))))))))

; 3. EXECUTION
!(println! ">>> [TEST] Calling llm:find-morph directly...")

!(let $specG (get-test-G)
   (let $specA (get-test-A)
      ; Call the registered atom directly to test connectivity
      (let $result (llm:find-morph $specG $specA)
          (println! "Generated Morphisim:" $result)         
      )
   )
)
