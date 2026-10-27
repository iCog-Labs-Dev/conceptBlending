(= (hide $value) (empty))

!(let $import-memory (import! &self ../memory) (empty))
!(let $import-real-embeddings (import! &self "../real_embeddings.py") (empty))
!(let $import-embeddings (import! &self ../embeddings) (empty))
!(let $import-habit-memory (import! &self ../habit_memory) (empty))
!(let $import-scoring (import! &self ../peircean_scoring) (empty))
!(let $import-step-3 (import! &self ../past_history_strengths) (empty))
!(let $import-step-4 (import! &self ../candidate_generation) (empty))
!(let $import-step-5 (import! &self ../winner_selection) (empty))

(= (seed-memory-for-test)
   (habit-memory
      ((intelligence tools language)
       (intelligence tools strategy)
       (intelligence tools engineering)
       (intelligence tools logic)
       (climbing agility balance)
       (climbing agility vertical)
       (climbing agility ropes)
       (webs insects sticky))))

!(test (select-winner (core) 0.0 (expanded) 2.0)
       (expanded))
!(test (select-winner (core) 1.0 (expanded) 1.0)
       (core))

!(test (register-successful-blend (habit-memory ((a b c))) (x y))
       (habit-memory ((a b c) (x y))))

!(test (get-habit-strength
       (register-successful-blend (seed-memory-for-test) (climbing intelligence agility tools))
       climbing
       intelligence)
       0.1282291410906773)

!(test (select-and-reinforce-winner-runtime
          (seed-memory-for-test)
          (candidate-result (climbing intelligence) 0.0 (climbing intelligence agility tools) 2.0)
          (climbing webs venomous)
          (intelligence tools walking))
       (selection-result
          (climbing intelligence agility tools)
          (habit-memory
             ((intelligence tools language)
              (intelligence tools strategy)
              (intelligence tools engineering)
              (intelligence tools logic)
              (climbing agility balance)
              (climbing agility vertical)
              (climbing agility ropes)
              (webs insects sticky)
              (climbing intelligence agility tools)))))
