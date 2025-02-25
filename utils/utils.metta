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



; deep-member function
; @description Recursively checks if a target atom exists within a potentially nested expression, determining membership
;              by flattening the expression, collapsing its non-deterministic results, and folding over the flattened list
;              to check for equality with the target. This function is optimized for handling complex, nested structures
;              in conceptual blending, such as verifying the presence of specific roles or elements in mental spaces.
; @param $item The atom (e.g., symbol, number) to search for within the expression, such as 'shelter' or '3'.
; @param $expr The expression (potentially nested) to search within, which can include lists, atoms, or sub-expressions,
;              such as (purpose (primary shelter (temporary tent))) or (list 1 (list 2 (list 3 4)) 5).
; @return Bool: True if the target atom is found at any level of the expression, False otherwise.
; @note This function leverages flatten, superpose, collapse, and foldl-atom from the MeTTa Standard Library to process
;       nested structures efficiently. It is ideal for Phase 1 (Defining Core Data Structures) and
;       subsequent phases in conceptual blending, such as checking roles (e.g., shelter in (purpose (primary shelter)))

(: deep-member (-> Atom Expression Bool))
(= (deep-member $item $expr)
   (let $flat (flatten $expr)
       (foldl-atom $flat False $acc $x
         (or $acc (== $x $item))
       )
   )
)

