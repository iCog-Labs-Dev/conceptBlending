; 1. Ontology of Contradictions
; These are the "Laws" that cannot be broken.

; Opposing Properties (Axiom Level)
(contradicts isFixed isMobile)
(contradicts isSolid isLiquid)
(contradicts isDead isAlive)

; Disjoint Types (Sort/Op Level)
; An object cannot belong to two trees that don't mix
(disjoint-types Land Water)
(disjoint-types Natural Artifact)

;2. Symmetry Rules

; If A contradicts B, then B contradicts A.
(= (are-contradictory $a $b)
   (or (match &self (contradicts $a $b) True)
       (match &self (contradicts $b $a) True)))

(= (are-disjoint $t1 $t2)
   (or (match &self (disjoint-types $t1 $t2) True)
       (match &self (disjoint-types $t2 $t1) True)))


;3. The Validator Function

; This function scans the blend for violations.
(= (check-consistency $blend_name)
   (let $conflict
        (collapse
            (union
                ; Check A: Property Contradictions
                ; Find an object $x that has two conflicting predicates $p1 and $p2
                (match &self
                    (,
                       (axioms ( ... ($p1 $x) ... )) ; Look inside axioms
                       (axioms ( ... ($p2 $x) ... ))
                       (True (are-contradictory $p1 $p2))
                    )
                    (Error (Logical Contradiction: $x cannot be both $p1 and $p2))
                )

                ; Check B: Type Contradictions
                ; Find an object $x defined as two disjoint types
                (match &self
                    (,
                       (ops ( ... (: $x $type1) ... )) ; Look inside ops
                       (ops ( ... (: $x $type2) ... ))
                       (True (are-disjoint $type1 $type2))
                    )
                    (Error (Ontological Error: $x cannot be both $type1 and $type2))
                )
            )
        )
        ; If $conflict is empty (()), return True. Otherwise return the Error.
        (if (== $conflict ()) True $conflict)
   )
)

; Helper to search inside lists
(= (member $x ($x $rest)) True)
(= (member $x ($y $rest)) (member $x $rest))