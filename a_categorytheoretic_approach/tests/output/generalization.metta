; ---------------------------------------------------------
; GENERALIZED CONCEPT (G): House@Boat
; ---------------------------------------------------------
(Concept House@Boat 
 (spec 
  (sorts (
    (Object 1) (Structure 0.9) ((< House@Boat Structure) 1) 
    (Enclosure 0.9) (Space 0.8) (Compartment 0.7) 
    (Human 0.8) (Dwelling 0.8) (Environment 0.7)
  )) 
  (ops (
    ((: self House@Boat) 1) ((: occupant Human) 0.8) 
    ((: interiorSpace Space) 0.9) ((: compartment Compartment) 0.7) 
    ((: environment Environment) 0.7)
  )) 
  (preds (
    ((isConstructedEnclosure House@Boat) 0.9) 
    ((providesShelter House@Boat) 0.95) 
    ((providesSecurity House@Boat) 0.9) 
    ((hasInteriorSpace House@Boat Space) 0.9) 
    ((hasCompartment House@Boat Compartment) 0.7) 
    ((isDwelling House@Boat) 0.8) 
    ((containsBelongings House@Boat) 0.7) 
    ((facilitatesActivities House@Boat) 0.7) 
    ((isPlaceOfBelonging House@Boat) 0.6) 
    ((isJourneyBase House@Boat) 0.7) 
    ((interactsWithEnvironment House@Boat Environment) 1.0)
  )) 
  (axioms (
    ((isConstructedEnclosure (self)) 0.9) 
    ((providesShelter (self)) 0.95) 
    ((providesSecurity (self)) 0.9) 
    ((hasInteriorSpace (self) (interiorSpace)) 0.9) 
    ((hasCompartment (self) (compartment)) 0.7) 
    ((isDwelling (self)) 0.8) 
    ((containsBelongings (self)) 0.7) 
    ((facilitatesActivities (self)) 0.7) 
    ((isPlaceOfBelonging (self)) 0.6) 
    ((isJourneyBase (self)) 0.7) 
    ((interactsWithEnvironment (self) (environment)) 1.0)
  ))
 )
)