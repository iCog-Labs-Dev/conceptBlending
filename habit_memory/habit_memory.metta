; KR1/KR2: Peircean habit memory representation and operations.

(= (new-habit-memory)
   (habit-memory ()))

(= (repeat-blend $count $blend)
   (if (<= $count 0)
       ()
       (cons $blend (repeat-blend (- $count 1) $blend))))

(= (property-names ())
   ())
(= (property-names (cons ($property-name $world-spec-set $degree) $remaining-properties))
   (cons $property-name (property-names $remaining-properties)))

(= (v-predicate-property-names $v-predicate)
   (property-names (cdr-atom (car-atom (cdr-atom $v-predicate)))))

(= (flatten-history-results ())
   ())
(= (flatten-history-results (cons $entry $remaining-results))
   (if (is-expr $entry)
       (append $entry (flatten-history-results $remaining-results))
       (flatten-history-results $remaining-results)))

(= (source-historical-blend-results)
   (collapse
      (match &self
         (Concept $concept-name
            (HabitCount $count)
            $v-predicate)
         (repeat-blend $count (v-predicate-property-names $v-predicate)))))

(= (source-historical-blends)
   (flatten-history-results (source-historical-blend-results)))

(= (clean-history ())
   ())
(= (clean-history (cons $blend $remaining-history))
   (if (is-expr $blend)
       (cons $blend (clean-history $remaining-history))
       (clean-history $remaining-history)))

(= (memory-from-imported-history)
   (habit-memory (clean-history (source-historical-blends))))

(= (register-successful-blend (habit-memory $history) $blend)
   (habit-memory (append $history ($blend))))

(= (register-successful-blends $memory ())
   $memory)
(= (register-successful-blends $memory (cons $blend $remaining-blends))
   (register-successful-blends
      (register-successful-blend $memory $blend)
      $remaining-blends))

(= (habit-memory-history (habit-memory $history))
   $history)

(= (list-length ())
   0)
(= (list-length (cons $head $tail))
   (+ 1 (list-length $tail)))

(= (property-count-in-history $property ())
   0)
(= (property-count-in-history $property (cons $blend $remaining-history))
   (+ (if (and (is-expr $blend)
               (is-member $property $blend))
          1
          0)
      (property-count-in-history $property $remaining-history)))

(= (pair-count-in-history $property-a $property-b ())
   0)
(= (pair-count-in-history $property-a $property-b (cons $blend $remaining-history))
   (+ (if (and (is-expr $blend)
               (and (is-member $property-a $blend)
                    (is-member $property-b $blend)))
          1
          0)
      (pair-count-in-history $property-a $property-b $remaining-history)))

(= (property-count (habit-memory $history) $property)
   (property-count-in-history $property $history))

(= (pair-count (habit-memory $history) $property-a $property-b)
   (if (== $property-a $property-b)
       0
       (pair-count-in-history $property-a $property-b $history)))

(= (calculate-jaccard-strength $count-u $count-v $count-uv)
   (if (or (== $count-u 0) (== $count-v 0))
       0.0
       (let $denominator (- (+ $count-u $count-v) $count-uv)
            (if (== $denominator 0)
                0.0
                (/ $count-uv $denominator)))))

(= (calculate-pmi-strength $count-u $count-v $count-uv $total-count)
   (if (or (== $total-count 0)
           (or (== $count-u 0)
               (or (== $count-v 0)
                   (== $count-uv 0))))
       0.0
       (let $ratio (/ (* $count-uv $total-count)
                      (* $count-u $count-v))
            (if (<= $ratio 1)
                0.0
                (log-math 2 $ratio)))))

(= (normalize-positive-pmi $pmi-score)
   (if (<= $pmi-score 0)
       0.0
       (/ $pmi-score (+ 1 $pmi-score))))

; Habit-strength metric weights.
; Tune these to change how M_P balances historical co-occurrence,
; statistical association, and semantic similarity.
(= (habit-strength-jaccard-weight)
   0.4)
(= (habit-strength-pmi-weight)
   0.3)
(= (habit-strength-embedding-weight)
   0.3)

(= (habit-strength-weights)
   (weights
      (Jaccard (habit-strength-jaccard-weight))
      (PMI (habit-strength-pmi-weight))
      (Embedding (habit-strength-embedding-weight))))

(= (print-habit-strength-weights)
   (println! (Active M_P Weights: (habit-strength-weights))))

(= (combine-weighted-habit-strengths
      $jaccard-score
      $pmi-score
      $embedding-score
      $jaccard-weight
      $pmi-weight
      $embedding-weight)
   (let $weight-total (+ $jaccard-weight
                         (+ $pmi-weight $embedding-weight))
        (if (<= $weight-total 0)
            0.0
            (/ (+ (* $jaccard-weight $jaccard-score)
                  (+ (* $pmi-weight (normalize-positive-pmi $pmi-score))
                     (* $embedding-weight $embedding-score)))
               $weight-total))))

(= (combine-habit-strengths $jaccard-score $pmi-score $embedding-score)
   (combine-weighted-habit-strengths
      $jaccard-score
      $pmi-score
      $embedding-score
      (habit-strength-jaccard-weight)
      (habit-strength-pmi-weight)
      (habit-strength-embedding-weight)))

(= (property-count (decayed-habit-memory $gamma $memory) $property)
   (property-count $memory $property))

(= (pair-count (decayed-habit-memory $gamma $memory) $property-a $property-b)
   (pair-count $memory $property-a $property-b))

(= (habit-strength-jaccard (habit-memory $history) $property-a $property-b)
   (calculate-jaccard-strength
      (property-count (habit-memory $history) $property-a)
      (property-count (habit-memory $history) $property-b)
      (pair-count (habit-memory $history) $property-a $property-b)))

(= (habit-strength-jaccard (decayed-habit-memory $gamma $memory) $property-a $property-b)
   (* $gamma (habit-strength-jaccard $memory $property-a $property-b)))

(= (habit-strength-pmi (habit-memory $history) $property-a $property-b)
   (calculate-pmi-strength
      (property-count (habit-memory $history) $property-a)
      (property-count (habit-memory $history) $property-b)
      (pair-count (habit-memory $history) $property-a $property-b)
      (list-length $history)))

(= (habit-strength-pmi (decayed-habit-memory $gamma $memory) $property-a $property-b)
   (* $gamma (habit-strength-pmi $memory $property-a $property-b)))

(= (habit-strength-combined $memory $property-a $property-b)
   (combine-habit-strengths
      (habit-strength-jaccard $memory $property-a $property-b)
      (habit-strength-pmi $memory $property-a $property-b)
      (habit-strength-embedding $property-a $property-b)))

(= (get-habit-strength (habit-memory $history) $property-a $property-b)
   (habit-strength-combined (habit-memory $history) $property-a $property-b))

(= (get-habit-strength (decayed-habit-memory $gamma $memory) $property-a $property-b)
   (habit-strength-combined (decayed-habit-memory $gamma $memory) $property-a $property-b))

(= (append-all-blends ())
   ())
(= (append-all-blends (cons $blend $remaining-blends))
   (if (is-expr $blend)
       (append $blend (append-all-blends $remaining-blends))
       (append-all-blends $remaining-blends)))

(= (memory-properties $memory)
   (unique-atom (append-all-blends (habit-memory-history $memory))))

(= (memory-properties (decayed-habit-memory $gamma $memory))
   (memory-properties $memory))

(= (apply-habit-decay $memory $gamma)
   (decayed-habit-memory $gamma $memory))

(= (reinforce-selected-blend $memory $winner)
   (register-successful-blend $memory $winner))

(= (reinforce-nondominated-blends $memory $front)
   (register-successful-blends $memory $front))
