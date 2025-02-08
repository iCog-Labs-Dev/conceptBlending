 ;; Import the conceptual blending module for knowledge representation
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
