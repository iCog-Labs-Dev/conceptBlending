; unNest function
; @description Recursively processes an expression to break down nested structures by applying the superpose operation.
;              It evaluates the metatype of the superposed expression and returns it unchanged if it is either 'Grounded'
;              or 'Symbol'. Otherwise, it recursively calls unNest on the expression to further decompose it. This function
;              is essential for simplifying complex nested expressions into their atomic components.
; @param $expr The input expression to be unnested, which can be a nested structure or a single element.
; @return The unnested expression, which is either a 'Grounded' or 'Symbol' metatype if the expression is atomic,
;         or the result of recursively unnesting if the expression contains nested elements
; @note This function leverages superpose to handle the elements of the expression and uses metatype checking to determine
;       whether recursion is necessary. It preserves atomic elements ('Grounded' or 'Symbol') and is a key step in preparing
;       nested structures for further processing, such as flattening.

(= (unNest $expr)
   (let $el (superpose $expr)
      (if (or (== (get-metatype $el) Grounded)  (== (get-metatype $el) Symbol))
         $el
         (unNest $el)
      )
   )
)

; flatten function
; @description Transforms a nested expression into a flat list by first unnesting it with the unNest function and then
;              collapsing the result into a single-level structure. This is particularly useful for converting complex,
;              hierarchical conceptual structures into a linear format for easier processing or analysis.
; @param $expr The input expression to be flattened, which may contain nested elements.
; @return A flat list containing all elements from the unnested expression, with no nesting. For example,
;         (flatten (purpose (primary shelter (temporary tent)))) returns [(purpose primary shelter temporary tent)].
; @note This function depends on unNest to recursively break down the expression, followed by collapse to produce a
;       one-dimensional list. It is ideal for tasks in conceptual blending where a simplified, linear representation
;       of a nested structure is needed.

(= (flatten $expr) (collapse (unNest $expr)))