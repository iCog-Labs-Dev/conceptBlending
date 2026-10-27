; Adapter from indexed atomspace evidence to the existing habit-memory formulas.

(= (atomspace-property-count $property ()) 0)
(= (atomspace-property-count $property
      (cons (PropertyCount $name $count) $remaining))
   (if (== $property $name)
       $count
       (atomspace-property-count $property $remaining)))

(= (atomspace-pair-count $left $right ()) 0)
(= (atomspace-pair-count $left $right
      (cons (PairCount $a $b $count) $remaining))
   (if (or (and (== $left $a) (== $right $b))
           (and (== $left $b) (== $right $a)))
       $count
       (atomspace-pair-count $left $right $remaining)))

(= (make-atomspace-habit-memory $memory
      (AtomspaceHabitEvidence
         (PropertyCounts $property-counts)
         (PairCounts $pair-counts)
         (EvidenceCount $total)
         (Index $index)))
   (atomspace-habit-memory
      $memory $property-counts $pair-counts $total $index))

(= (property-count
      (atomspace-habit-memory $memory $property-counts $pair-counts $total $index)
      $property)
   (+ (property-count $memory $property)
      (atomspace-property-count $property $property-counts)))

(= (pair-count
      (atomspace-habit-memory $memory $property-counts $pair-counts $total $index)
      $left $right)
   (+ (pair-count $memory $left $right)
      (atomspace-pair-count $left $right $pair-counts)))

(= (habit-strength-jaccard
      (atomspace-habit-memory $memory $property-counts $pair-counts $total $index)
      $left $right)
   (calculate-jaccard-strength
      (property-count
         (atomspace-habit-memory $memory $property-counts $pair-counts $total $index)
         $left)
      (property-count
         (atomspace-habit-memory $memory $property-counts $pair-counts $total $index)
         $right)
      (pair-count
         (atomspace-habit-memory $memory $property-counts $pair-counts $total $index)
         $left $right)))

(= (habit-strength-pmi
      (atomspace-habit-memory $memory $property-counts $pair-counts $total $index)
      $left $right)
   (calculate-pmi-strength
      (property-count
         (atomspace-habit-memory $memory $property-counts $pair-counts $total $index)
         $left)
      (property-count
         (atomspace-habit-memory $memory $property-counts $pair-counts $total $index)
         $right)
      (pair-count
         (atomspace-habit-memory $memory $property-counts $pair-counts $total $index)
         $left $right)
      (+ (list-length (habit-memory-history $memory)) $total)))

(= (get-habit-strength
      (atomspace-habit-memory $memory $property-counts $pair-counts $total $index)
      $left $right)
   (combine-habit-strengths
      (habit-strength-jaccard
         (atomspace-habit-memory $memory $property-counts $pair-counts $total $index)
         $left $right)
      (habit-strength-pmi
         (atomspace-habit-memory $memory $property-counts $pair-counts $total $index)
         $left $right)
      (habit-strength-embedding $left $right)))

(= (augment-habit-memory-from-atomspace $memory $properties)
   (make-atomspace-habit-memory
      $memory
      (sread (py-call
         (builtins.habit_load_evidence (repr (reduce $properties)))))))
