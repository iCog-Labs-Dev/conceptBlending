
; ---------------------------------------------------------
; ⛵ BOAT SPECIFICATION
; ---------------------------------------------------------
(Concept Boat 
 (spec 
  (sorts (Object (< Boat Object) (< Person Object) (< Space Object) (< DomesticArea Space) (< StructuralPart Object) (< Envelope StructuralPart) (< Base StructuralPart) (< MovementState Object) (< ExternalCondition Object) (< DomesticActivity Object) (< Medium Object))) 
  (ops ((: boat Boat) (: passenger Person) (: hull Base) (: deckCabin Envelope) (: cabin DomesticArea) (: galley DomesticArea) (: waterWeather ExternalCondition) (: mobile MovementState) (: water Medium) (: sleeping DomesticActivity) (: cooking DomesticActivity))) 
  (preds ((providesEnclosedSpaceFor Boat Person) (offersProtectionFrom Boat ExternalCondition) (containsAreaFor Boat DomesticArea DomesticActivity) (hasStructuralEnvelope Boat Envelope) (servesAsSanctuaryFor Boat Person) (hasMovementState Boat MovementState) (hasBaseForStability Boat Base) (facilitatesOccupancyBy Boat Person) (locatedIn Boat Medium))) 
  (axioms ((providesEnclosedSpaceFor boat passenger) (offersProtectionFrom boat waterWeather) (containsAreaFor boat cabin sleeping) (containsAreaFor boat galley cooking) (hasStructuralEnvelope boat deckCabin) (servesAsSanctuaryFor boat passenger) (hasMovementState boat mobile) (hasBaseForStability boat hull) (facilitatesOccupancyBy boat passenger) (locatedIn boat water)))
 )
)

; ---------------------------------------------------------
; 🏠 HOUSE SPECIFICATION
; ---------------------------------------------------------
(Concept House 
 (spec 
  (sorts (Object (< House Object) (< Person Object) (< Space Object) (< DomesticArea Space) (< StructuralPart Object) (< Envelope StructuralPart) (< Base StructuralPart) (< MovementState Object) (< ExternalCondition Object) (< DomesticActivity Object) (< Medium Object))) 
  (ops ((: house House) (: resident Person) (: foundation Base) (: wallsRoof Envelope) (: livingRoom DomesticArea) (: kitchen DomesticArea) (: weather ExternalCondition) (: stationary MovementState) (: land Medium) (: dailyLiving DomesticActivity) (: cooking DomesticActivity))) 
  (preds ((providesEnclosedSpaceFor House Person) (offersProtectionFrom House ExternalCondition) (containsAreaFor House DomesticArea DomesticActivity) (hasStructuralEnvelope House Envelope) (servesAsSanctuaryFor House Person) (hasMovementState House MovementState) (hasBaseForStability House Base) (facilitatesOccupancyBy House Person) (locatedIn House Medium))) 
  (axioms ((providesEnclosedSpaceFor house resident) (offersProtectionFrom house weather) (containsAreaFor house livingRoom dailyLiving) (containsAreaFor house kitchen cooking) (hasStructuralEnvelope house wallsRoof) (servesAsSanctuaryFor house resident) (hasMovementState house stationary) (hasBaseForStability house foundation) (facilitatesOccupancyBy house resident) (locatedIn house land)))
 )
)
