; SMALL KB - With Triplet Structure
(surfaceText (Triplet (IsA house building)) "A house is a building")
(surfaceText (Triplet (RelatedTo house family)) "Houses are for families")
(surfaceText (Triplet (HasProperty house expensive)) "Houses are expensive")
(surfaceText (Triplet (HasProperty house stationary)) "Houses do not move")
(surfaceText (Triplet (RelatedTo house land)) "Houses are built on land")

; BOAT DATA 
(surfaceText (Triplet (IsA boat vehicle)) "A boat is a vehicle")
(surfaceText (Triplet (RelatedTo boat water)) "Boats go on water")
(surfaceText (Triplet (HasProperty boat buoyant)) "Boats float")

; --- ADDING SYMMETRY ---
(surfaceText (Triplet (HasProperty boat expensive)) "Boats are expensive")
(surfaceText (Triplet (RelatedTo boat sailors)) "Boats are for sailors") 

; DICE DATA
(surfaceText (Triplet (IsA dice cube)) "Dice are cubes")
(surfaceText (Triplet (IsA dice randomized_generator)) "Dice generate random numbers")