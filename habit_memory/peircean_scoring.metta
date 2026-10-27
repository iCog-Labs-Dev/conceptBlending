; KR3: Peircean habit-based scoring methods

(= (habit-weighted-joint $mu-u $mu-v $lambda-p $habit-strength)
   (+ (* $mu-u $mu-v)
      (* $lambda-p $habit-strength)))

(= (habit-weighted-joint-from-memory $memory $u $v $mu-u $mu-v $lambda-p)
   (habit-weighted-joint
      $mu-u
      $mu-v
      $lambda-p
      (get-habit-strength $memory $u $v)))

(= (habit-weighted-weakness $memory $lambda-p ())
   0.0)
(= (habit-weighted-weakness $memory $lambda-p (cons ($u $v $mu-u $mu-v) $remaining-pairs))
   (+ (habit-weighted-joint-from-memory $memory $u $v $mu-u $mu-v $lambda-p)
      (habit-weighted-weakness $memory $lambda-p $remaining-pairs)))

(= (sum-habit-strength-to-rest $memory $property ())
   0.0)
(= (sum-habit-strength-to-rest $memory $property (cons $next-property $remaining-properties))
   (+ (get-habit-strength $memory $property $next-property)
      (sum-habit-strength-to-rest $memory $property $remaining-properties)))

(= (habit-bonus-from-list $memory ())
   0.0)
(= (habit-bonus-from-list $memory (cons $property $remaining-properties))
   (+ (sum-habit-strength-to-rest $memory $property $remaining-properties)
      (habit-bonus-from-list $memory $remaining-properties)))

(= (habit-bonus $memory $candidate-properties)
   (habit-bonus-from-list $memory $candidate-properties))

(= (weighted-habit-bonus-pairs $memory ())
   0.0)
(= (weighted-habit-bonus-pairs $memory (cons ($u $v $weight) $remaining-pairs))
   (+ (* (get-habit-strength $memory $u $v) $weight)
      (weighted-habit-bonus-pairs $memory $remaining-pairs)))

(= (habit-break-pair $memory $u $v $emergence-score)
   (* (- 1 (get-habit-strength $memory $u $v))
      $emergence-score))

(= (habit-break $memory ())
   0.0)
(= (habit-break $memory (cons ($u $v $emergence-score) $remaining-pairs))
   (+ (habit-break-pair $memory $u $v $emergence-score)
      (habit-break $memory $remaining-pairs)))

(= (peircean-blend-quality $alpha $habit-bonus-score $habit-break-score $synergy)
   (+ (* $alpha $habit-bonus-score)
      (* (* (- 1 $alpha) $habit-break-score) $synergy)))

(= (score-peircean-quality $memory $candidate $habit-break-pairs $alpha $synergy)
   (peircean-blend-quality
      $alpha
      (habit-bonus $memory $candidate)
      (habit-break $memory $habit-break-pairs)
      $synergy))

(= (evaluate-habit-candidate $memory $candidate)
   (habit-bonus $memory $candidate))

(= (evaluate-peircean-candidate $memory $candidate $habit-break-pairs $alpha $synergy)
   (score-peircean-quality $memory $candidate $habit-break-pairs $alpha $synergy))
