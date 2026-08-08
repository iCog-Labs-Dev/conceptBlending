;; Minimal local algebraic vocabulary required by the generalization rules.
;; These declarations make the component independent of metta/common while
;; preserving the same representations used by the surrounding PLN code.

;; A measured proposition/event with an associated truth value.
(: ≞ (-> $event $tv Type))

;; Truth-value constructors referenced by generated LCG rules. Runtime input
;; and output specifications intentionally retain the compact (stv s c) form.
(: TruthValue Type)
(: Bl (-> Bool TruthValue))
(: Pr (-> Number TruthValue))
(: STV (-> %Undefined% %Undefined% TruthValue))
