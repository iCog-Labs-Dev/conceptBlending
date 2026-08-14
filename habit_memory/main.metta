(= (hide $value) (empty))

!(let $import-memory (import! &self memory) (empty))
!(let $import-real-embeddings (import! &self "real_embeddings.py") (empty))
!(let $import-embeddings (import! &self embeddings) (empty))
!(let $import-habit-memory (import! &self habit_memory) (empty))
!(let $import-scoring (import! &self peircean_scoring) (empty))
!(let $import-step-3 (import! &self past_history_strengths) (empty))
!(let $import-step-4 (import! &self candidate_generation) (empty))
!(let $import-step-5 (import! &self winner_selection) (empty))
!(let $import-persist (import! &self "persist_memory.py") (empty))

; No direct historica
; (= (concept-1) (climbing webs venomous))
; (= (concept-2) (intelligence tools walking))

; (= (concept-1) (alpha beta))
; (= (concept-2) (gamma delta))

; Established Connection
;(= (concept-1) (intelligence climbing webs))
;(= (concept-2) (tools agility insects))

(= (concept-1) (access_internet calculate_data compute_information do_word_processing))
(= (concept-2) (drive_around_town travel_to_shops carrying_groceries))

(= (main)
   (let* (($step-1 (println! (--- STEP 1: Initial Source Concepts Declared ---)))
          ($show-c1 (println! (Concept 1 Properties: (concept-1))))
          ($show-c2 (println! (Concept 2 Properties: (concept-2))))
          ($memory (memory-from-imported-history))
          ($step-2 (println! (--- STEP 2: Habit Memory Loaded From memory.metta ---)))
          ($step-2-count (println! (Historical Habit Entries Loaded: (list-length (habit-memory-history $memory)))))
          ($step-2-runtime (println! (Runtime Habit Memory: (habit-memory-history $memory))))
          ($step-3 (check-past-history-strengths $memory (concept-1) (concept-2)))
          ($candidate-result (generate-and-evaluate-candidates $memory (concept-1) (concept-2)))
          ($step-5 (select-and-reinforce-winner $memory $candidate-result (concept-1) (concept-2))))
      ()))


!(hide (main))
