;; Optional raw-input adapter for candidate optimality. CandidateEvaluation
;; itself accepts cached CandidateOptimalityResult entries without importing
;; this large dependency graph into the four-objective traversal.

!(import! &self CandidateEvaluation)
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
