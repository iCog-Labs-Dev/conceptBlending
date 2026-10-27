(= (hide $value) (empty))

!(let $import-memory (import! &self ../memory) (empty))
!(let $import-real-embeddings (import! &self "../real_embeddings.py") (empty))
!(let $import-embeddings (import! &self ../embeddings) (empty))
!(let $import-habit-memory (import! &self ../habit_memory) (empty))
!(let $import-scoring (import! &self ../peircean_scoring) (empty))

!(test (habit-weighted-joint 0.8 0.5 0.2 1.0)
       0.6000000000000001)

!(test (habit-weighted-joint-from-memory
          (memory-from-imported-history)
          intelligence
          tools
          0.8
          0.5
          0.2)
       0.5339339238274099)

!(test (habit-weighted-weakness
          (memory-from-imported-history)
          0.2
          ((intelligence tools 0.8 0.5)
           (climbing intelligence 0.4 0.5)))
       0.7495797520455454)

!(test (habit-bonus (memory-from-imported-history) (climbing intelligence agility tools))
       1.759159182538904)

!(test (weighted-habit-bonus-pairs
          (memory-from-imported-history)
          ((intelligence tools 0.8)
           (climbing agility 0.7)))
       1.0377318135473597)

!(test (habit-break-pair (memory-from-imported-history) climbing intelligence 0.7)
       0.6452396012365259)

!(test (habit-break
          (memory-from-imported-history)
          ((climbing intelligence 0.7)
           (intelligence tools 0.5)))
       0.8104047916680013)

!(test (peircean-blend-quality 0.6 2.0 0.7 0.5)
       1.3399999999999999)

!(test (score-peircean-quality
          (memory-from-imported-history)
          (climbing intelligence agility tools)
          ((climbing intelligence 0.7))
          0.6
          0.5)
       1.1845434297706474)
