;; sample categorized concepts in a structured way

;; Nature concepts
! (add-reduct &self (nature "A river carves its path through mountains over time."))
! (add-reduct &self (nature "A forest breathes life into the world."))
! (add-reduct &self (nature "The ocean whispers stories to the shore."))

;; Innovation concepts
! (add-reduct &self (innovation "Innovation is the art of solving problems in new ways."))
! (add-reduct &self (innovation "Technology bridges the gap between imagination and reality."))
! (add-reduct &self (innovation "Creativity fuels the evolution of ideas."))

;; Emotion concepts
! (add-reduct &self (emotion "Love is the gravity that holds people together."))
! (add-reduct &self (emotion "Fear is the shadow cast by the unknown."))
! (add-reduct &self (emotion "Happiness is the light that brightens the soul."))

;; Knowledge and abstraction concepts
! (add-reduct &self (knowledge "Mathematics provides the foundation for understanding patterns."))
! (add-reduct &self (knowledge "Philosophy seeks meaning in the questions we ask."))
! (add-reduct &self (knowledge "History is the memory of civilization."))

;; Retrieve all stored knowledge
! (match &self ($x $y) ($x $y))
