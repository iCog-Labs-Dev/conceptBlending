!(import! &self Generalization)

(= (input-spec1)
    (quote (Concept home functional_use
        (spec
            (sorts (
                (house (stv 0.96 0.92))
                (person (stv 0.92 0.88))
                (dwelling_state (stv 0.88 0.82))
            ))
            (ops (
                ((operation occupy_house (arrow house person dwelling_state)) (stv 0.91 0.86))
                ((operation inspect_house (arrow house dwelling_state)) (stv 0.83 0.77))
                ((operation tend_house_garden (arrow house dwelling_state)) (stv 0.68 0.58))
            ))
            (preds (
                ((provides_shelter house person) (stv 0.94 0.89))
                ((habitable house) (stv 0.88 0.82))
            ))
            (axioms (
                ((forall ((h house) (p person))
                    (=> (provides_shelter h p) (habitable h)))
                    (stv 0.90 0.84))
            ))
        )
    ))
)

(= (input-spec2)
    (quote (Concept cabin functional_use
        (spec
            (sorts (
                (cabin (stv 0.93 0.89))
                (person (stv 0.89 0.84))
                (dwelling_state (stv 0.91 0.80))
            ))
            (ops (
                ((operation occupy_cabin (arrow cabin person dwelling_state)) (stv 0.87 0.81))
                ((operation inspect_cabin (arrow cabin dwelling_state)) (stv 0.86 0.73))
                ((operation heat_cabin_stove (arrow cabin dwelling_state)) (stv 0.72 0.61))
            ))
            (preds (
                ((provides_shelter cabin person) (stv 0.90 0.85))
                ((habitable cabin) (stv 0.84 0.78))
            ))
            (axioms (
                ((forall ((h cabin) (p person))
                    (=> (provides_shelter h p) (habitable h)))
                    (stv 0.86 0.79))
            ))
        )
    ))
)

!(main-lcg building functional_use (input-spec1) (input-spec2))
