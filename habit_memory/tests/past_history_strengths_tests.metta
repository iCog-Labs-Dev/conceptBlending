(= (hide $value) (empty))

!(let $import-memory (import! &self ../memory) (empty))
!(let $import-real-embeddings (import! &self "../real_embeddings.py") (empty))
!(let $import-embeddings (import! &self ../embeddings) (empty))
!(let $import-habit-memory (import! &self ../habit_memory) (empty))
!(let $import-step-3 (import! &self ../past_history_strengths) (empty))

!(test (property-count (memory-from-imported-history) intelligence) 4)
!(test (property-count (memory-from-imported-history) climbing) 3)
!(test (property-count (memory-from-imported-history) unknown) 0)

!(test (pair-count (memory-from-imported-history) intelligence tools) 4)
!(test (pair-count (memory-from-imported-history) tools intelligence) 4)
!(test (pair-count (memory-from-imported-history) climbing agility) 3)
!(test (pair-count (memory-from-imported-history) climbing intelligence) 0)

!(test (get-habit-strength (memory-from-imported-history) intelligence tools) 0.6696696191370491)
!(test (get-habit-strength (memory-from-imported-history) climbing agility) 0.7171373117681716)
!(test (get-habit-strength (memory-from-imported-history) climbing intelligence) 0.07822914109067729)

!(test (cross-connections-found (memory-from-imported-history) (climbing webs venomous) (intelligence tools walking)) True)
!(test (cross-connections-found (memory-from-imported-history) (intelligence climbing webs) (tools agility insects)) True)
