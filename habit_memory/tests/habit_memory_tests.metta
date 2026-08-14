(= (hide $value) (empty))

!(let $import-memory (import! &self ../memory) (empty))
!(let $import-real-embeddings (import! &self "../real_embeddings.py") (empty))
!(let $import-embeddings (import! &self ../embeddings) (empty))
!(let $import-habit-memory (import! &self ../habit_memory) (empty))

!(test (new-habit-memory) (habit-memory ()))

!(test (habit-memory-history (memory-from-imported-history))
       ((intelligence tools language)
        (intelligence tools strategy)
        (intelligence tools engineering)
        (intelligence tools logic)
        (climbing agility balance)
        (climbing agility vertical)
        (climbing agility ropes)
        (webs insects sticky)
        (access_internet carrying_groceries)
        (access_internet carrying_groceries)))

!(test (property-count (memory-from-imported-history) tools) 4)
!(test (pair-count (memory-from-imported-history) intelligence tools) 4)
!(test (habit-strength-jaccard (memory-from-imported-history) intelligence tools) 1)
!(test (habit-strength-pmi (habit-memory ((a b) (a b) (a c) (d e))) a b)
       0.4150374992788437)
!(test (habit-strength-pmi (habit-memory ((a b) (a c) (d e))) a e)
       0.0)
!(test (habit-strength-pmi (decayed-habit-memory 0.5 (habit-memory ((a b) (a b) (a c) (d e)))) a b)
       0.20751874963942185)
!(test (normalize-positive-pmi 1.0)
       0.5)
!(test (combine-weighted-habit-strengths 0.6 1.0 0.3 0.4 0.3 0.3)
       0.48)
!(test (combine-weighted-habit-strengths 0.6 1.0 0.3 0.0 0.0 0.0)
       0.0)

!(test (get-habit-strength
          (reinforce-selected-blend (memory-from-imported-history) (climbing intelligence agility tools))
          climbing
          intelligence)
       0.1282291410906773)

!(test (reinforce-nondominated-blends
          (new-habit-memory)
          ((a b) (b c)))
       (habit-memory ((a b) (b c))))

!(test (apply-habit-decay (memory-from-imported-history) 0.9)
       (decayed-habit-memory 0.9 (memory-from-imported-history)))

!(test (get-habit-strength
          (apply-habit-decay (memory-from-imported-history) 0.9)
          intelligence
          tools)
       0.6218697250714571)
