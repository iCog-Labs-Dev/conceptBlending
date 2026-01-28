; SMALL KB - With Triplet Structure
(surfaceText (IsA house building) A_house_is_a_building)
(surfaceText (RelatedTo house family) Houses_are_for_families)
(surfaceText (HasProperty house expensive) Houses_are_expensive)
(surfaceText (HasProperty house stationary) Houses_do_not_move)
(surfaceText (RelatedTo house land) Houses_are_built_on_land)

; BOAT DATA 
(surfaceText (IsA boat vehicle) A_boat_is_a_vehicle)
(surfaceText (RelatedTo boat water) Boats_go_on_water)
(surfaceText (HasProperty boat buoyant) Boats_float)

; --- ADDING SYMMETRY ---
(surfaceText (HasProperty boat expensive) Boats_are_expensive)
(surfaceText (RelatedTo boat sailors) Boats_are_for_sailors) 

; DICE DATA
(surfaceText (IsA dice cube) Dice_are_cubes)
(surfaceText (IsA dice randomized_generator) Dice_generate_random_numbers)