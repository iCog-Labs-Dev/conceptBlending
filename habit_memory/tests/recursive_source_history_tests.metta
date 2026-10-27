(= (hide $value) (empty))

!(let $import-memory (import! &self ../memory) (empty))
!(let $import-real-embeddings (import! &self "../real_embeddings.py") (empty))
!(let $import-embeddings (import! &self ../embeddings) (empty))
!(let $import-habit-memory (import! &self ../habit_memory) (empty))

(Concept test-six-property-history
  (HabitCount 2)
  (V-predicate
    (Property
      (p1 (WorldSpecSet (w1)) 0.1)
      (p2 (WorldSpecSet (w1 w2)) 0.2)
      (p3 (WorldSpecSet ()) 0.3)
      (p4 (WorldSpecSet (w4)) 0.4)
      (p5 (WorldSpecSet (w5)) 0.5)
      (p6 (WorldSpecSet (w6)) 0.6))))

!(test (property-names
          ((p1 (WorldSpecSet (w1)) 0.1)
           (p2 (WorldSpecSet (w1 w2)) 0.2)
           (p3 (WorldSpecSet ()) 0.3)
           (p4 (WorldSpecSet (w4)) 0.4)
           (p5 (WorldSpecSet (w5)) 0.5)
           (p6 (WorldSpecSet (w6)) 0.6)))
       (p1 p2 p3 p4 p5 p6))

!(test (get-habit-strength (memory-from-imported-history) p1 p6)
       0.8079999671446233)

!(test (property-count (memory-from-imported-history) p1)
       2)
