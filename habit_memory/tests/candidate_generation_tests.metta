(= (hide $value) (empty))

!(let $import-memory (import! &self ../memory) (empty))
!(let $import-real-embeddings (import! &self "../real_embeddings.py") (empty))
!(let $import-embeddings (import! &self ../embeddings) (empty))
!(let $import-habit-memory (import! &self ../habit_memory) (empty))
!(let $import-scoring (import! &self ../peircean_scoring) (empty))
!(let $import-step-3 (import! &self ../past_history_strengths) (empty))
!(let $import-step-4 (import! &self ../candidate_generation) (empty))

!(test (first-sorted-property (climbing webs venomous)) climbing)
!(test (first-sorted-property (intelligence tools walking)) intelligence)

!(test (generated-core-blend (climbing webs venomous) (intelligence tools walking))
       (climbing intelligence))

!(test (generated-core-blends (climbing webs venomous) (intelligence tools walking))
       ((climbing intelligence)
        (climbing tools)
        (climbing walking)
        (venomous intelligence)
        (venomous tools)
        (venomous walking)
        (webs intelligence)
        (webs tools)
        (webs walking)))

!(test (best-core-blend (memory-from-imported-history) (climbing webs venomous) (intelligence tools walking))
       (webs intelligence))

!(test (discover-extensions (memory-from-imported-history) (webs intelligence))
       (insects sticky tools))

!(test (habit-bonus (memory-from-imported-history) (climbing intelligence))
       0.07822914109067729)
!(test (habit-bonus (memory-from-imported-history) (climbing intelligence agility tools))
       1.759159182538904)

!(test (candidate-generation-result (memory-from-imported-history) (climbing webs venomous) (intelligence tools walking))
       (candidate-result (webs intelligence) 0.10184501150620233 (webs intelligence insects sticky tools) 3.3700673148201883))

!(test (candidate-generation-result (memory-from-imported-history) (alpha beta) (gamma delta))
       (candidate-result (alpha gamma) 0.14500242570026217 (alpha gamma) 0.14500242570026217))
