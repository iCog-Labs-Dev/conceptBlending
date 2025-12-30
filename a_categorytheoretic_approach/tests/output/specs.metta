; ---------------------------------------------------------
; SPECIFICATION 1: BOAT (Weighted)
; ---------------------------------------------------------
(Concept Boat
 (spec
  (sorts (
    (Object 1.0) (Structure 0.9) ((< Boat Structure) 1.0) (Enclosure 0.9) 
    (Space 0.8) (Compartment 0.7) (Human 0.8) (Dwelling 0.8) (Medium 0.7)
  ))
  (ops (
    ((: self Boat) 1.0) ((: occupant Human) 0.8) ((: interiorSpace Space) 0.9) 
    ((: compartment Compartment) 0.7) ((: water Medium) 0.7)
  ))
  (preds (
    ((isConstructedEnclosure Boat) 0.9) ((providesShelter Boat) 0.95) 
    ((providesSecurity Boat) 0.9) ((hasInteriorSpace Boat Space) 0.9) 
    ((hasCompartment Boat Compartment) 0.7) ((isDwelling Boat) 0.8) 
    ((containsBelongings Boat) 0.7) ((facilitatesActivities Boat) 0.7) 
    ((isPlaceOfBelonging Boat) 0.6) ((isJourneyBase Boat) 1.0) 
    ((designedForMovementOn Boat Medium) 1.0)
  ))
  (axioms (
    ((isConstructedEnclosure (self)) 0.9) ((providesShelter (self)) 0.95) 
    ((providesSecurity (self)) 0.9) ((hasInteriorSpace (self) (interiorSpace)) 0.9) 
    ((hasCompartment (self) (compartment)) 0.7) ((isDwelling (self)) 0.8) 
    ((containsBelongings (self)) 0.7) ((facilitatesActivities (self)) 0.7) 
    ((isPlaceOfBelonging (self)) 0.6) ((isJourneyBase (self)) 1.0) 
    ((designedForMovementOn (self) (water)) 1.0)
  ))
 )
)

; ---------------------------------------------------------
; SPECIFICATION 2: HOUSE (Weighted)
; ---------------------------------------------------------
(Concept House
 (spec
  (sorts (
    (Object 1.0) (Structure 0.9) ((< House Structure) 1.0) (Enclosure 0.9) 
    (Space 0.8) (Compartment 0.7) (Human 0.8) (Dwelling 0.8) (Location 0.7)
  ))
  (ops (
    ((: self House) 1.0) ((: occupant Human) 0.8) ((: interiorSpace Space) 0.9) 
    ((: compartment Compartment) 0.7) ((: land Location) 0.7)
  ))
  (preds (
    ((isConstructedEnclosure House) 0.9) ((providesShelter House) 0.95) 
    ((providesSecurity House) 0.9) ((hasInteriorSpace House Space) 0.9) 
    ((hasCompartment House Compartment) 0.7) ((isDwelling House) 0.8) 
    ((containsBelongings House) 0.7) ((facilitatesActivities House) 0.7) 
    ((isPlaceOfBelonging House) 0.6) ((isJourneyBase House) 0.4) 
    ((fixedToLand House Location) 1.0)
  ))
  (axioms (
    ((isConstructedEnclosure (self)) 0.9) ((providesShelter (self)) 0.95) 
    ((providesSecurity (self)) 0.9) ((hasInteriorSpace (self) (interiorSpace)) 0.9) 
    ((hasCompartment (self) (compartment)) 0.7) ((isDwelling (self)) 0.8) 
    ((containsBelongings (self)) 0.7) ((facilitatesActivities (self)) 0.7) 
    ((isPlaceOfBelonging (self)) 0.6) ((fixedToLand (self) (land)) 1.0)
  ))
 )
)