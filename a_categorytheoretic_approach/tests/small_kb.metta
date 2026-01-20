; SMALL KB - With Triplet Structure
; =====================================================
; 1. HOUSE & BOAT 
; =====================================================

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


; ======================================================
; 2. EXPERIMENT B: BIOLOGICAL VS DIGITAL (VIRUS + SOFTWARE)
; ======================================================
(surfaceText (Triplet (IsA virus microorganism)) "A virus is a microorganism")
(surfaceText (Triplet (RelatedTo virus host_cell)) "Viruses infect host cells")
(surfaceText (Triplet (Action virus replicate)) "Viruses replicate themselves")
(surfaceText (Triplet (HasProperty virus biological)) "Viruses are biological entities")
(surfaceText (Triplet (CausedBy virus sickness)) "Viruses cause sickness")

(surfaceText (Triplet (IsA software computer_code)) "Software is computer code")
(surfaceText (Triplet (RelatedTo software hardware)) "Software runs on hardware")
(surfaceText (Triplet (Action software execute)) "Software executes instructions")
(surfaceText (Triplet (HasProperty software digital)) "Software is a digital entity")
(surfaceText (Triplet (CausedBy software glitch)) "Software can cause glitches")

; ======================================================
; 3. EXPERIMENT C: MYTHOLOGICAL (HORSE + BIRD)
; ======================================================

(surfaceText (Triplet (IsA horse mammal)) "A horse is a mammal")
(surfaceText (Triplet (HasPart horse hooves)) "Horses have hooves")
(surfaceText (Triplet (Locomotion horse gallop)) "Horses gallop on land")
(surfaceText (Triplet (RelatedTo horse pasture)) "Horses live in pastures")
(surfaceText (Triplet (HasProperty horse heavy)) "Horses are heavy")

(surfaceText (Triplet (IsA bird avian)) "A bird is an avian")
(surfaceText (Triplet (HasPart bird wings)) "Birds have wings")
(surfaceText (Triplet (Locomotion bird fly)) "Birds fly in the air")
(surfaceText (Triplet (RelatedTo bird nest)) "Birds live in nests")
(surfaceText (Triplet (HasProperty bird light)) "Birds are light")

; ======================================================
; 4. EXPERIMENT D: CONCEPTUAL (TIME + MONEY)
; ======================================================

(surfaceText (Triplet (IsA time resource)) "Time is a resource")
(surfaceText (Triplet (Action time pass)) "Time passes inevitably")
(surfaceText (Triplet (CanBe time wasted)) "Time can be wasted")
(surfaceText (Triplet (CanBe time saved)) "Time can be saved")

(surfaceText (Triplet (IsA money asset)) "Money is an asset")
(surfaceText (Triplet (Action money circulate)) "Money circulates in economy")
(surfaceText (Triplet (CanBe money spent)) "Money can be spent")
(surfaceText (Triplet (CanBe money invested)) "Money can be invested")