!(import! &self Generalization)

!(bind! &branch-kb (new-space))
!(add-atom &branch-kb (: rootm (≞ root (stv 0.9 0.8))))
!(add-atom &branch-kb (: leftm (≞ left (stv 0.9 0.8))))
!(add-atom &branch-kb (: rightm (≞ right (stv 0.9 0.8))))
!(add-atom &branch-kb (: topm (≞ top (stv 0.8 0.7))))
!(add-atom &branch-kb (: root_leftm (≞ (→ root left ()) (stv 0.9 0.8))))
!(add-atom &branch-kb (: root_rightm (≞ (→ root right ()) (stv 0.8 0.7))))
!(add-atom &branch-kb (: left_topm (≞ (→ left top ()) (stv 0.7 0.6))))
!(add-atom &branch-kb (: right_topm (≞ (→ right top ()) (stv 0.6 0.5))))
(= (branch-kb) (get-atoms &branch-kb))

!(collapse (generalization-path-finder root branch-kb 2 0 (root)))

!(collapse (install-lcg-repair &branch-kb
    (LCGRepair shared
        (Path left top (stv 0.75 0.65) (stv 0.70 0.60))
        (Path right top (stv 0.72 0.62) (stv 0.68 0.58)))))

!(collapse (generalization-path-finder root branch-kb 3 0 (root)))

!(collapse
    (resolve-pair-request
        (PairRequest validation_pair left right)
        branch-kb &branch-kb 3))

!(collapse (main-lcg vehicle functional_use
        (Concept boat functional_use
            (spec
                (sorts ((boat (stv 0.95 0.90)) (cargo (stv 0.80 0.70))))
                (ops (((operation move_boat (arrow boat cargo boat)) (stv 0.90 0.80))))
                (preds (((usable boat) (stv 0.88 0.77))))
                (axioms (((=> true (usable boat)) (stv 0.80 0.70))))))
        (Concept car functional_use
            (spec
                (sorts ((car (stv 0.92 0.85)) (cargo (stv 0.90 0.65))))
                (ops (((operation move_car (arrow car cargo car)) (stv 0.85 0.75))))
                (preds (((usable car) (stv 0.82 0.72))))
                (axioms (((=> true (usable car)) (stv 0.75 0.65))))))))
