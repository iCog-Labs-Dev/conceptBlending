;  ;; Import the conceptual blending module for knowledge representation
! (import! &self conceptual_blending)

 ;; Ask the GPT agent with two explicit concepts for different networks
! (gpt_simplex "Music" "Painting")
! (gpt_mirror "Light" "Wisdom")
! (gpt_single "Nature" "Technology")
! (gpt_double "Emotion" "Mathematics")

 ;; Combine GPT with other agents and workflows
 ;; Store the blended knowledge (GPT response) from each network into the knowledge space
! (add-reduct &self (gpt_simplex "Music" "Painting"))
! (add-reduct &self (gpt_mirror "Light" "Wisdom"))
! (add-reduct &self (gpt_single "Nature" "Technology"))
! (add-reduct &self (gpt_double "Emotion" "Mathematics"))

 ;; Retrieve and list all knowledge stored in the current space
! (match &self ($x) $x)


; --------------------------------------------
;; Test blending with sentences
; ! (gpt_simplex "The melody of a song flows like a river." "A painting captures emotions in colors.")
; ! (gpt_mirror "A bright light reveals hidden truths." "Wisdom is gained through experience.")
; ! (gpt_single "Nature adapts to changes over time." "Technology evolves to meet human needs.")
; ! (gpt_double "Emotions shape our decisions and actions." "Mathematics provides structure and logic to the world.")

; ; Output:
; ; `(simplexBlend (blend melodyFlow emotionColors) emotionalRiver)`
; ; (mirroredConcept (mirror brightLight hiddenTruths wisdom experience) revelationThroughIllumination)
; ; ```
; ; (singleScope (expand nature adapts to changes over time) dynamicResilienceInEcosystemEvolution)
; ; (singleScope (expand technology evolves to meet human needs) adaptiveInnovationInHumanProgress)
; ; ```
; ; (doubleScope (expand emotionsDecisions mathematicsStructure) emotionalLogicFramework)
; ; [()]
; ; [[`, (simplexBlend (blend melodyFlow emotionColors) emotionalRiver), `]]
; ; [[(mirroredConcept (mirror brightLight hiddenTruths wisdom experience) revelationThroughIllumination)]]
; ; [[```, (singleScope (expand nature adapts to changes over time) dynamicResilienceInEcosystemEvolution), (singleScope (expand technology evolves to meet human needs) adaptiveInnovationInHumanProgress), ```]]
; ; [[(doubleScope (expand emotionsDecisions mathematicsStructure) emotionalLogicFramework)]]
; ; []



; --------------------------------------
;; Load the stored knowledge space
! (import! &test_space data)

;; Test blending with sentences from the stored space with pattern matching
; ! (gpt_simplex (match &test_space (nature $x) $x) (match &test_space (emotion $y) $y))

; ; Output: Not getting expected output since the gpt_simplex is being evaluated before match statement
; ; `(simplexBlend (blend (match ModuleSpace(GroundingSpace-top:data) (nature $x) $x) (match ModuleSpace(GroundingSpace-top:data) (emotion $y) $y)) emotionalNature)`
; ; [()]
; ; [()]
; ; [[`, (simplexBlend (blend (match ModuleSpace (GroundingSpace-top:data) (nature $x) $x) (match ModuleSpace (GroundingSpace-top:data) (emotion $y) $y)) emotionalNature), `]]


;; Test blending with sentences from the stored space with pattern matching and using `!` to execute match statements first
; ! (gpt_simplex (!(match &test_space (nature $x) $x)) (!(match &test_space (emotion $y) $y)))

; ; Output: Not getting expected output since the gpt_simplex is being evaluated before match statement
; ; ```
; ; (simplexBlend (blend (! (match ModuleSpace(GroundingSpace-top:data) (nature $x) $x)) (! (match ModuleSpace(GroundingSpace-top:data) (emotion $y) $y))) emotionalNature)
; ; ```
; ; [()]
; ; [()]
; ; [[```, (simplexBlend (blend (! (match ModuleSpace (GroundingSpace-top:data) (nature $x) $x)) (! (match ModuleSpace (GroundingSpace-top:data) (emotion $y) $y))) emotionalNature), ```]]



;; Test blending with sentences from the stored space with `let` since the matches were not being executed first
! (let $knowledge_example (match &test_space (knowledge $y) $y)
    (let $nature_example (match &test_space (nature $x) $x)
        (gpt_simplex $knowledge_example $nature_example)
    )
)

; ; Output: Getting expected result interms of blending the given atoms
; ; (simplexBlend (blend mathematicsPatterns oceanStories) narrativePatterns)
; ; `(simplexBlend (blend mathematics forest) patternEcology)`
; ; `(simplexBlend (blend mathematics riverPath) patternErosion)`
; ; `(simplexBlend (blend philosophy oceanWhispers) existentialTides)`
; ; `(simplexBlend (blend philosophy forest) existentialEcology)`
; ; `(simplexBlend (blend philosophy riverPath) existentialErosion)`
; ; `(simplexBlend (blend historyMemory oceanStories) civilizationWhispers)`
; ; `(simplexBlend (blend historyMemory civilization forestBreathesLife) ecologicalMemory)`
; ; `(simplexBlend (blend historyMemory civilization riverPathCarving) temporalErosion)`
; ; [()]
; ; [()]
; ; [[`, (simplexBlend (blend historyMemory civilization riverPathCarving) temporalErosion), `], [`, (simplexBlend (blend historyMemory civilization forestBreathesLife) ecologicalMemory), `], [`, (simplexBlend (blend historyMemory oceanStories) civilizationWhispers), `], [`, (simplexBlend (blend philosophy riverPath) existentialErosion), `], [`, (simplexBlend (blend philosophy forest) existentialEcology), `], [`, (simplexBlend (blend philosophy oceanWhispers) existentialTides), `], [`, (simplexBlend (blend mathematics riverPath) patternErosion), `], [`, (simplexBlend (blend mathematics forest) patternEcology), `], [(simplexBlend (blend mathematicsPatterns oceanStories) narrativePatterns)]]




; metta function to blend all atoms in a given list
; (= (blend_from_list $network $list)
;     ($network $list $list)
; )


; metta function to blend all atoms in a given lists
; (= (blend_from_lists $network $list1 $list2)
;     ($network $list1 $list2)
; )


; metta function to blend all atoms in given space using let*
; limit input list for testing
(= (blend_from_space $network $space)
    (let*
        (
            ($knowledge-example (match $space (knowledge $y) $y))
            ($nature-example (match $space (nature $x) $x))
        )
        ($network $knowledge-example $nature-example)
    )
)

! (import! &testSpace data)
! (blend_from_space gpt_simplex &testSpace)
