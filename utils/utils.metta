; ------------------------------------------------------------
; Function: unNest
; Description:
;   Recursively unwraps nested expressions until it reaches
;   either a Symbol or a Grounded atom.
;   - Uses `superpose` to handle nondeterministic results.
;   - Checks the `get-metatype` of each element.
;   - Calls itself recursively if the element is still an expression.
; ------------------------------------------------------------
(= (unNest $expr)
   (let $el (superpose $expr)  ; Extract one result at a time
      (if (or (== (get-metatype $el) Grounded)  ; Stop if Grounded
              (== (get-metatype $el) Symbol))   ; Stop if Symbol
         $el  ; Return the base atom
         (unNest $el)  ; Otherwise, continue unwrapping
      )
   )
)

; ------------------------------------------------------------
; Function: flatten
; Description:
;   Flattens deeply nested expressions into a single-level list.
;   - Uses `unNest` to remove nested structures.
;   - Uses `collapse` to collect the results into one expression.
; ------------------------------------------------------------
(= (flatten $expr) (collapse (unNest $expr)))

; ------------------------------------------------------------
; Example Test Case: ! (flatten (purpose (primary shelter (temporary tent))))
; Expected Output: (purpose primary shelter temporary tent)
; ------------------------------------------------------------

