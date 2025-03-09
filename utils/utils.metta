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

; getValue function
; @description Recursively retrieves the value associated with a target key in a nested association list by leveraging
;              non-deterministic computation. This function  extracts the key from
;              each pair, and returns the full pair (key-value) if the key matches
;              It is designed to support conceptual blending tasks by accessing nested roles or properties
;              in mental spaces, handling deeply nested structures effectively.
; @param $key The symbol (e.g., 'd', 'purpose') to search for in the association list, representing a key in a mental
;             space's role or property mapping.
; @param $list The expression representing the association list (e.g., ((purpose (primary shelter)) (color (b (c (d blue))))
;               (weight 43))), which may contain nested pairs where values can be atoms or complex nested expressions.
; @return Expression: The full pair (list $key $value) if the key is found (e.g., (d blue)), or implicitly () if the key
;                    is not found (not explicitly returned but assumed due to recursive termination in MeTTa).
;@example ! (getValue d ((purpose (primary shelter)) (color (b (c (d blue)))) (weight 43))) returns (d blue)

(= (getValue $key $list)
    (let*
        (
            ($el (superpose $list))
            ($k1 (car-atom $el))
        )
        (if (== $k1 $key)
            $el
            (let $t (cdr-atom $el)
                (getValue $key $t)
            )
        )

    )
)



; setValue function
; @description Updates or sets a new value for a specified key in an association list by retrieving the existing key-value
;              pair using getValue and replacing the value with a new one, creating a new key-value pair. This function
;              supports conceptual blending tasks by dynamically modifying roles or properties in mental spaces, handling
;              nested structures effectively.
; @param $key The symbol (e.g., 'color', 'purpose') identifying the key in the association list whose value needs to be
;             updated or set, representing a role or property in a mental space.
; @param $list The expression representing the association list (e.g., ((purpose (primary shelter)) (color (b (c (d blue))))
;               (weight 43))), which may contain nested pairs where values can be atoms or complex nested expressions.
; @param $nval The new value (e.g., 'white', a nested expression) to associate with the specified key, replacing the
;              existing value or creating a new pair if the key doesn’t exist.
; @return Expression: A new key-value pair representing the updated or newly set association (e.g., (color white))
; @note . Ideal for Phase 1 (Defining Core Data Structures) and beyond in updating roles or properties (e.g., setting color white for a
;       mental space element) or modifying LLM outputs


(= (setValue $key $list $nval)
    (let*
        (
            (($key $oval) (getValue $key $list))
            ($newPair (cons-atom $key ($nval)))
        )
        $newPair)
)

; ! (setValue primary ((purpose (primary shelter)) (color (b (c (d blue)))) (weight 43)) transportation ) returns (primary transportation)





