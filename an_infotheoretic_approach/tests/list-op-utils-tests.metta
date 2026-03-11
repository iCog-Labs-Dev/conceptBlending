! (register-module! ../../an_infotheoretic_approach)
! (import! &self an_infotheoretic_approach:utils:list-op-utils)
! (import! &self an_infotheoretic_approach:utils:random-list-utils)


; Test tuple-multiply
! (assertEqual
    (list-multiply (0.9 0.9 0.0 0.8 0.2 0.9 0.7 0.7) (0.9 0.9 0.0 0.8 0.2 0.9 0.7 0.7) (mobility intelligence web-creation social-structure predatory-behavior communication symbolism physical-strength))
    ((mobility 0.81) (intelligence 0.81) (web-creation 0.0) (social-structure 0.6400000000000001) (predatory-behavior 0.04000000000000001) (communication 0.81) (symbolism 0.48999999999999994) (physical-strength 0.48999999999999994))
)

; Test min-elements
! (assertEqual
    (min-elements (0.9 0.9 0.0 0.8 0.2 0.9 0.7 0.7) (0.8 0.0 0.6 0.9 0.7 0.3 0.1 0.7) (mobility intelligence web-creation social-structure predatory-behavior communication symbolism physical-strength))
    ((mobility 0.8) (intelligence 0.0) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.3) (symbolism 0.1) (physical-strength 0.7))
)

; Test max-elements
! (assertEqual
    (max-elements (0.9 0.9 0.0 0.8 0.2 0.9 0.7 0.7) (0.8 0.0 0.6 0.9 0.7 0.3 0.1 0.7) (mobility intelligence web-creation social-structure predatory-behavior communication symbolism physical-strength))
    ((mobility 0.9) (intelligence 0.9) (web-creation 0.6) (social-structure 0.9) (predatory-behavior 0.7) (communication 0.9) (symbolism 0.7) (physical-strength 0.7))
)

; Test tuple-substract
! (assertEqual
    (list-substract (0.9030899869919434 0.9030899869919434 0.9030899869919434 0.9030899869919434 0.9030899869919434 0.9030899869919434 0.9030899869919434 0.9030899869919434) (0.3 0.2 0.0 0.5 0.5 0.5 0.7 0.3) (mobility intelligence web-creation social-structure predatory-behavior communication symbolism physical-strength))
    ((mobility 0.6030899869919435) (intelligence 0.7030899869919434) (web-creation 0.9030899869919434) (social-structure 0.4030899869919434) (predatory-behavior 0.4030899869919434) (communication 0.4030899869919434) (symbolism 0.20308998699194347) (physical-strength 0.6030899869919435))
)

;;;; zip-list function TestCases ;;;;

; Test zip-list with non-empty lists
!(assertEqual
  (zip-list (1 2 3) (4 5 6))
  ((1 4) (2 5) (3 6))
)

; Test zip-list with empty lists
!(assertEqual
    (zip-list () ())
    (Error (zip-list () ()) EmptyList)
)

; Test zip-list with lists with un-equal list elements
!(assertEqual
    (zip-list (1 2 3) (4 5))
    (Error (zip-list (1 2 3) (4 5)) LengthMismatch)
)

;;;; remove-list-element function Testcases ;;;;

; Test remove-list-element with a list and a number to be remove from the list

!(assertEqual
    (remove-list-element (1 2 6 4) 4)
    (1 2 6)
)

; Test remove-list-element with an empty list
; Output: An empty list will be returned

!(assertEqual
    (remove-list-element () 4)
    ()
)

; Test remove-list-element with a list with equal elements
; Output: Only one existence will be removed

!(assertEqual
    (remove-list-element (5 5 5 5 5) 5)
    (5 5 5 5)
)

; Test remove-list-element with a list that contains the number to be removed more than once
; Output: Every existence of the number will be removed

!(assertEqual
    (remove-list-element (4 5 5 4 7) 4)
    (5 5 7)
)

; Test remove-list-element with a list that doesn't contains the number to be removed
; Output: Nothing will be removed, and the original list will be returned

!(assertEqual
    (remove-list-element (3 6 4 7 5) 1)
    (3 6 4 7 5)
)

;;;; unzip-list ;;;;

; Test unzip-list with a non-empty list
; Output: two seperate lists that contain the first, and the second elements of the input list respectively

!(assertEqual
    (unzip-list ((2 3) (4 4) (5 4)))
    ((2 4 5) (3 4 4))
)

; Test unzip-list with an empty list
; Output: (Error () EmptyList)

!(assertEqual
    (unzip-list ())
    (Error () EmptyList)
)

;;;; generate-toy-list ;;;;

; Test generate-toy-list to create a toy list of length 5
; Output: a list containing five 1's.

!(assertEqual
    (let $x (generate-toy-list 5) (size-atom $x))
    5
)

; Test generate-toy-list to create a toy-list of length 0(i.e empty list)
; Output: An empty list

!(assertEqual
    (let $x (generate-toy-list 0) (size-atom $x))
    0
)

;;;; merge-list ;;;;

; Test merge-list with two non-empty lists
; Output: A single list that contains all elements of the two input lists

!(assertEqual
    (merge-list (1 2 3 4 5) (3 4 5 6))
    (1 2 3 4 5 3 4 5 6)
)

; Test merge-list with two empty lists
; Output: An empty list

!(assertEqual
    (merge-list () ())
    ()
)

; Test merge-list with one non-empty, and one empty list
; Output: a list with all elements of the non-empty list

!(assertEqual
    (merge-list () (1 2 3 4))
    (1 2 3 4)
)

;;;; random-list-utils ;;;;

; Test random-list-utils to create 2 lists each containing 2 elements with value between 0 and 1.

!(assertEqual
    (let $x (random-list 2 2 0 1) (collapse(superpose((size-atom $x)(let $y (car-atom $x) (size-atom $y))))))
    (2 2)
)

; Test random-list-utils to create 4 lists each containing 3 elements with value between 0 and 1.

!(assertEqual
    (let $x (random-list 4 3 0 1) (collapse(superpose((size-atom $x)(let $y (car-atom $x) (size-atom $y))))))
    (4 3)
)
