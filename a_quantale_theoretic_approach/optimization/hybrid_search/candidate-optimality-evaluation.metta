;; Optional raw-input adapter for candidate optimality. candidate-evaluation
;; itself accepts cached CandidateOptimalityResult entries without importing
;; this large dependency graph into the four-objective traversal.

!(import! &self a_quantale_theoretic_approach/optimization/hybrid_search/candidate-evaluation)
!(import! &self a_quantale_theoretic_approach/optimality/enriched_optimality_constraints)

(= (hs-materialize-optimality-entry
      (CandidateOptimalityInput
         $subproblem $individual $candidate $inputs))
   (CandidateOptimalityResult
      $subproblem $individual $candidate
      (q-enriched-optimality-evaluator $inputs)))

(= (hs-materialize-optimality-entries ()) ())
(= (hs-materialize-optimality-entries (cons $input $remaining))
   (cons-atom
      (hs-materialize-optimality-entry $input)
      (hs-materialize-optimality-entries $remaining)))
