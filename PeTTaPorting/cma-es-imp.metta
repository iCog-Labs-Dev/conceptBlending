;;;; PARAMETERS ;;;;
!(import! &self utils/random-list-utils)
!(import! &self utils/cma-es-utils)
!(import! &self info-theoretic)
(= (random-list $length $width $lb $ub) 
    (
        collapse(
            superpose(
                (
                    if (>= (- $length 1) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 2) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 3) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 4) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 5) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 6) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 7) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 8) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 9) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 10) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 11) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 12) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 13) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 14) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 15) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 16) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 17) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 18) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 19) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 20) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 21) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 22) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 23) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 24) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 25) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 26) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 27) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 28) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 29) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 30) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 31) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 32) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 33) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 34) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 35) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 36) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 37) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 38) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 39) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 40) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 41) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 42) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 43) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 44) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 45) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 46) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 47) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 48) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 49) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
                (
                    if (>= (- $length 50) 0)
                    (
                        collapse(
                            superpose(
                                (if (>= (- $width 1) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 2) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 3) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 4) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 5) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 6) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 7) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 8) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 9) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 10) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 11) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 12) 0) (random-float &rng $lb $ub) (empty)) (if (>= (- $width 13) 0) (random-float &rng $lb $ub) (empty))                              
                            )
                        )
                    )
                    ((empty))
                )
            )    
        )
    )
)

; !(random-list 51 5 0.0 1.0 )

; !(import! &self op-constraints:op-evaluation)
; !(import! &self space-info-theoretic)

(=(add-reduct $space $atom)
    (let $result $atom (add-atom $space $atom))
)

;;;; INPUT CONCEPTS ;;;;
(= (testconcept1) 
    (Concept Man@Bat (Property (mobility 0.9) (intelligence 0.9) (web-creation 0.0) (social-structure 0.8) (predatory-behavior 0.2) (communication 0.9) (symbolism 0.7) (physical-strength 0.7)))
)
(= (testconcept2) 
    (Concept Bat@Man (Property (mobility 0.8) (intelligence 0.2) (web-creation 1.0) (social-structure 0.3) (predatory-behavior 0.9) (communication 0.4) (symbolism 0.6) (physical-strength 0.3)))
)

(= (Input1) Bat)
(= (Input2) Man)

;;;; PARAMETERS ;;;;
;;;; DIMENSION, INITIAL MEAN, COVARIANCE, AND STEP SIZE
(= (dim) 8)
(= (mean)(let $x (random-list 1 (dim) 0 1) (car-atom $x)))
; !(mean)
(= (cov) (identity-matrice (dim)))
(= (step_size) 1)
(= (e) 2.71828)

;;;; STRATEGY PARAMETERS ;;;;
(= (GENERATIONS) 30)
(= (POPULATION_SIZE) 0)
(= (lambda_) (if (<= (POPULATION_SIZE) 0) (+ 4 (round-math (* 3 (log-math (e) (dim))))) (POPULATION_SIZE)))
(= (mu) (/ (lambda_) 2))
(= (weights) (let ($mu-logged $range-logged)  ((log-math (e) (+ (mu) 0.5)) (let $range (range 1 (+ (mu) 1)) (apply-log $range (e)))) (rev-scalar-op $mu-logged $range-logged -)))
(= (normalized_weights)(scalar-op (weights) (sum (weights)) /))
(= (mu_eff)(/ 1 (sum (apply-power (normalized_weights) 2))))

;;;; LEARNING RATES ;;;;
(= (c_sigma) (let $mu-eff (mu_eff) (/ (+ $mu-eff 2) (+ 5 (+ $mu-eff (dim))))))
(= (d_sigma) (+ 1 (+ (* 2 (max-atom(0 (- (sqrt-math (/ (- (mu_eff) 1) (+ (dim) 1))) 1)))) (c_sigma))))
(= (c_c) (let ($mu-eff $dim) ((mu_eff) (dim)) (/ (+ 4 (/ $mu-eff $dim)) (+ $dim (+ 4 (/ (* 2 $mu-eff) $dim))))))
(= (c1) (/ 2 (+ (pow-math (+ (dim) 1.3) 2) (mu_eff))))
(= (c_mu) (let $mu-eff (mu_eff) (min-atom((- 1 (c1)) (/ (* 2 (+ (- $mu-eff 2) (/ 1 $mu-eff))) (+ (pow-math (+ (dim) 2) 2) $mu-eff))))))

;;;; EVOLUTION PATHS ;;;;
(= (p_c) (zeros-vec (dim)))
(= (p_sigma) (zeros-vec (dim)))

;;;; POPULATION FITNESS SCORE CALCULATION ;;;;
(= (population-fitness-score $population)
    (map-atom $population $x (mu-hqblend $x (concept1) (concept2)))
)

;;;; POPULATION FITNESS SCORE CALCULATION FOR TESTING ;;;;
(= (population-fitness-score-test $population)
    (let*
    ( 
        ($test1 (testconcept1))
        ($test2 (testconcept2))
       ($result (map-atom $population $x (mu-hqblend $x $test1 $test2)))

    )
    $result
    )
)

; !(population-fitness-score-test ((1 0 1 0 1 0 1 0) (0 1 0 1 0 1 0 1) (1 1 0 1 1 0 1 0) (0 0 1 1 0 0 1 0) (1 0 1 1 1 1 0 1) (1 1 1 1 1 0 0 1) (0 0 0 1 1 0 1 1) (1 1 0 0 0 0 1 1)))

(= (update-mean $samples $mu $weights $fitness-fn)
  (let $fitness-score ($fitness-fn $samples)
    (let $fit-ind-pairs (pair-index-fitness (make-indices $fitness-score) $fitness-score)
        (let $desc-sorted-pairs (sort-pairs-desc $fit-ind-pairs)
            (let $extracted-indices (extract-indices $desc-sorted-pairs $mu)
                (let $selected (select-by-indices $samples $extracted-indices)
                    (let $weighted-indiv (mat-vec-op $selected $weights *)
                        ((foldl-atom $weighted-indiv 0 $acc $x (vector-op $x $acc +)) $selected $fitness-score)
                    )
                )
            )
        )
    )
  )
)

; !(update-mean ((2 0) (4 4) (8 2)) 3 (0.5 0.3 0.2) (population-fitness-score-test))


(= (moedd-update-mean $samples $mu $weights $fitness-fn $iter)
  (let ($unscalarized-fit-score $scalarized-fit-score) ($fitness-fn $samples $iter)
    (let $fit-ind-pairs (pair-index-fitness (make-indices $scalarized-fit-score) $scalarized-fit-score)
        (let $desc-sorted-pairs (sort-pairs-desc $fit-ind-pairs)
            (let $extracted-indices (extract-indices $desc-sorted-pairs $mu)
                (let ($selected-sample $selected-fitscore) ((select-by-indices $samples $extracted-indices) (select-by-indices $unscalarized-fit-score $extracted-indices)) ((car-atom $selected-sample) (car-atom $selected-fitscore)))
            )
        )
    )
  )
)

(= (mock-moedd-fitness $samples $iter)
    ((10 20 30) (0.1 0.2 0.3))
)

; Test moedd-update-mean selection behavior
; !(moedd-update-mean ((1 2) (3 4) (5 6)) 2 (0.6 0.4) mock-moedd-fitness 0)
    

(= (update-mean-test $samples $mu $weights)
  (let $fitness-score (population-fitness-score-test $samples)
    (let $fit-ind-pairs (pair-index-fitness (make-indices $fitness-score) $fitness-score)
        (let $desc-sorted-pairs (sort-pairs-desc $fit-ind-pairs)
            (let $extracted-indices (extract-indices $desc-sorted-pairs $mu)
                (let $selected (select-by-indices $samples $extracted-indices)
                    (let $weighted-indiv (mat-vec-op $selected $weights *)
                        ((foldl-atom $weighted-indiv 0 $acc $x (vector-op $x $acc +)) $selected $fitness-score)
                    )
                )
            )
        )
    )
  )
)

; !(update-mean-test ((2 0) (4 4) (8 2)) 3 (0.5 0.3 0.2))  


(= (y $new-mean $old-mean $step-size)
  (let $mean-diff (vector-op $new-mean $old-mean -) (scalar-op $mean-diff $step-size /))
)

; !(y (0.3 0.4 0.6 0.2 0.8 0.1 0.5 0.8) (0.2 0.7 0.3 0.6 0.8 0.3 0.9 0.4) 0.34)


(= (new-p-sigma $c-sigma $p-sigma $mu-eff $c-inv-sqrt $y)
       (let* (
            (($m1-sigma $b2 $vec-mul) (collapse(superpose((- 1 $c-sigma) (sqrt-math (* (* $c-sigma (- 2 $c-sigma)) $mu-eff)) (mat-mat-mul $c-inv-sqrt ($y))))))
            (($m1-sigma-p-sigma $vec-mul-b2) (collapse(superpose((map-atom $p-sigma $ps (* $ps $m1-sigma)) (map-atom $vec-mul $vm (* $vm $b2))))))
            )
            (vector-op $m1-sigma-p-sigma $vec-mul-b2 +)
        )
)

; !(new-p-sigma 0.3196142529106335 (0 0) 3.1672992814107035 ((0 0 0 0 0 0 0) (0 0 0 0 0 0) (0 0 0 0 0) (0 0 0 0) (0 0 0) (0 0) (0)) (0.629276773868858 0.7029813694774427 0.17915574673512397 0.021359372554875078 0.5556770423164838 -1.1102230246251565e-16 -1.3877787807814457e-17 -5.551115123125783e-17))
; !(mat-mat-mul (identity-matrice 3) (0.5 0.4 0.6))
;  !(new-p-sigma 0.3 (0.1 0.2 0.3) 2 (identity-matrice 3) (0.5 0.4 0.6))

; ; ;;;; STEP SIZE ADAPTATION ;;;;
; (= (new-step-size $step-size $c-sigma $d-sigma $dim $p-sigma $mu-eff $c-inv-sqrt $y)
;     (let $new-p-sigma (new-p-sigma $c-sigma $p-sigma $mu-eff $c-inv-sqrt $y)
;             (let $adaptingfactor (pow-math (e) (* (/ $c-sigma $d-sigma) (- (/ (l2-norm $new-p-sigma) (sqrt-math $dim)) 1))) ((* $step-size $adaptingfactor) $new-p-sigma))
;     )
; )

(= (new-step-size $step-size $c-sigma $d-sigma $dim $p-sigma $mu-eff $c-inv-sqrt $y)
        (let* (
            ($new-p-sigma (new-p-sigma $c-sigma $p-sigma $mu-eff $c-inv-sqrt $y))
            ($adaptingfactor (pow-math (e) (* (/ $c-sigma $d-sigma) (- (/ (l2-norm $new-p-sigma) (sqrt-math $dim)) 1))))
            ($adaptXsize (* $step-size $adaptingfactor))

        )
        ($adaptXsize $new-p-sigma)
        
        )

)
; !(new-step-size 1 0.3196142529106335 1.3196142529106334 8 (0 0) 3.1672992814107035 ((0 0 0 0 0 0 0) (0 0 0 0 0 0) (0 0 0 0 0) (0 0 0 0) (0 0 0) (0 0) (0)) (0.629276773868858 0.7029813694774427 0.17915574673512397 0.021359372554875078 0.5556770423164838 -1.110223024625156516 -1.387778780781445717 -5.55111512312578317))


; !(new-step-size 0.5 0.3 1.5 3 (0.2 0.4 0.6) 2 (identity-matrice 3) (0.5 0.4 0.6))
; ; ;;;; COVARIANCE EVOLUTION PATH ADAPTATION ;;;;

(= (h-sigma $p-sigma $c-sigma $gen)
    (1or0 (< (/ (l2-norm $p-sigma) (sqrt-math (- 1 (pow-math (- 1 $c-sigma) (* 2 (+ $gen 1)))))) (+ 1.4 (/ 2 (+ (dim) 1)))))
)

; !(h-sigma (0.2 0.3 0.4) 0.3 5)

(= (p-c $prev-p-c $new-p-sigma $c-sigma $gen $y)
    (let $h-sigma (h-sigma $new-p-sigma $c-sigma $gen)
        (let $c-c (c_c) (vector-op (rev-scalar-op (- 1 $c-c) $prev-p-c *) (rev-scalar-op (* $h-sigma (sqrt-math (* $c-c (* (- 2 $c-c) (mu_eff))))) $y *) +))
    )
)

; !(p-c (0.2 0.3 0.4) (0.5 0.6 0.7) 0.4 5 (0.1 0.2 0.3))

(= (delta $selected $old-mean)
 (mat-mat-eles-op $selected ($old-mean) -)
)

; !(delta ((0.5 0.6 0.7) (0.2 0.3 0.4) (0.1 0.2 0.3)) (0.2 0.3 0.4))

(= (rank-mu $weights $selected $old-mean)
    (let $delta (delta $selected $old-mean)
        (let $zipped (zip-list $weights $delta)
            (let $wmoutp (map-atom $zipped $x (mat-scalar-op (outer-product (index-atom $x 1) (index-atom $x 1)) (index-atom $x 0) *))
                (foldl-atom $wmoutp 0 $acc $x (mat-mat-eles-op $x $acc +))
            )
        )
    )
)

;  !(rank-mu (0.4 0.3 0.3) ((0.5 0.6 0.7) (0.2 0.3 0.4) (0.1 0.2 0.3)) (0.2 0.3 0.4))

(= (new-cov $prev-cov $prev-p-c $new-p-sigma $c-sigma $gen $y $weights $selected $old-mean)
    (let ($new-p-c $rank-mu) ((p-c $prev-p-c $new-p-sigma $c-sigma $gen $y) (rank-mu $weights $selected $old-mean))
        (let ($c1 $c-mu) ((c1) (c_mu))
            (let $upd-mats (collapse(superpose((mat-scalar-op $prev-cov (- (- 1 $c1) $c-mu) *) (mat-scalar-op (outer-product $new-p-c $new-p-c) $c1 *) (mat-scalar-op $rank-mu $c-mu *))))
                ((foldl-atom $upd-mats 0 $acc $x (mat-mat-eles-op $x $acc +)) $new-p-c)
            )
        )
    )
)

; !(new-cov (identity-matrice 3) (0.2 0.3 0.4) (0.5 0.6 0.7) 0.4 5 (0.1 0.2 0.3) (0.4 0.3 0.3) ((0.5 0.6 0.7) (0.2 0.3 0.4) (0.1 0.2 0.3)) (0.2 0.3 0.4))

(= (Thetha) 5.0)


(= (pbi-scalarization $obj $ref $weight)
    (if (and (== (size-atom $obj) 2) (and (== (size-atom $ref) 2) (== (size-atom $weight) 2)))
        (let*
            (
                ($_ (println! Starting-PBI-scalarization))
                ($proc-l2 (+ (l2-norm $weight) 0.000000000001))
                ($norm-weight (scalar-op $weight $proc-l2 /))
                ($diff (vector-op $obj $ref -))
                ($d1 (inner-product $diff $norm-weight))
                ($proj (scalar-op $norm-weight $d1 *))
                ($d2 (l2-norm (vector-op $diff $proj -)))
                ($_ (println! (END OF scalarization------>)))
            )
            (+ $d1 (* (Thetha) $d2))
        )
        (Error ($obj $ref $weight) IncorrectLength)
    )
)

; !(pbi-scalarization (3 4) (1 2) (0.5 0.5))

; (= (max-best-nd $best-nds $ref $iter $weights)
;     (let $weight (index-atom $weights $iter) 
;     (let $res (map-atom $best-nds $best-nd (pbi-scalarization (index-atom $best-nd 1) $ref $weight))
;     (let ($zipped-res $max-val) ((zip-list $best-nds $res) (max-atom $res)) (max-best-nd-helper $max-val $zipped-res))))
; )

(=(max-best-nd $best-nds $ref $iter $weights) 
    (let* (
        ($_ (println! Starting-max-best-nd))
        ($weight (index-atom $weights $iter))
        ; ($_ (println! (calculating results with weight: $weight)))
        ($_ (println! (Best-NDs: (index-atom $best-nds 1) | Weight: $weight | ref: $ref)))
        ($res (map-atom $best-nds $best-nd (pbi-scalarization (index-atom $best-nd 1) $ref $weight)))
        ($_ (println! (Result-----------------------------------------------5)))
        ($zipped-res (zip-list $best-nds $res))
        ($max-val (max-atom $res))
        ($result (max-best-nd-helper $max-val $zipped-res))
    )
    $result
    )
)

;    !(max-best-nd (
;       ((b) (0.4 0.6))
;       ((c) (0.6 0.4))
;       ((d) (0.8 0.2)))

;    (0 0)
;    1
;    ((0.2 0.8) (0.5 0.5) (0.8 0.2)))

!(bind! &single-cma-es-inputspace (new-space))
(= (add-to-single-cma-es-inputspace)
    (add-reduct &single-cma-es-inputspace (Inputs ((mean) (cov) (step_size) (p_sigma) (p_c) () -10000 0 0)))
)

(= (clean-from-single-cma-es-inputspace)
    (collapse (match &single-cma-es-inputspace (Inputs $params) (remove-atom &single-cma-es-inputspace (Inputs $params))))
)

(=(clean-from-space $space)
    (collapse (match $space $X (remove-atom $space $X)))
)

(= (add-concepts)
    (let $concept1 (testconcept1)
        (let $concept2 (testconcept2)
            (collapse(superpose((add-atom &concept-space (= (concept1) $concept1)) (add-atom &concept-space (= (concept2) $concept2)))))
        )
    )
)


!(add-to-single-cma-es-inputspace)
!(add-concepts)

!(bind! &rmspace (new-space))
!(bind! &cispace1 (new-space))
!(bind! &cispace2 (new-space))
!(bind! &cispace3 (new-space))

(= (cma-es-single-iteration $fitness-fn)
    (let ($mean $cov $step-size $p-sigma $p-c $best-pop $best-fitness $gen $stall) (match &single-cma-es-inputspace (Inputs $x) $x)
        (if (>= $stall 5)                         ; patience = 5 gens
          ($best-pop $best-fitness)             
          (let*
            (
                (($normalized-weights $c-sigma $d-sigma $mu $mu-eff $dim $rmspace $cispace1 $cispace2 $cispace3) (collapse(superpose((normalized_weights) (c_sigma) (d_sigma) (mu) (mu_eff) (dim) &rmspace &cispace1 &cispace2 &cispace3))))
                ($samples (mat-clip (random-multivariate $mean (mat-scalar-op $cov (pow-math $step-size 2) *) (lambda_) $rmspace) 0 1))
                (($new-mean $selected $fitness-score) (update-mean $samples $mu $normalized-weights $fitness-fn))
                (($new-best-fitness $new-best-pop) (let $gen-best-fitness (max-atom $fitness-score) (if (>= $gen-best-fitness $best-fitness) ($gen-best-fitness $selected) ($best-fitness $best-pop))))
                ($improved?  (> $new-best-fitness $best-fitness))
                ($new-stall  (if $improved? 0 (+ 1 $stall)))
                (($y $C-inv-sqrt) ((y $new-mean $mean $step-size) (C-inv-sqrt $cov $cispace1 $cispace2 $cispace3)))
                (($new-step-size $new-p-sigma) (new-step-size $step-size $c-sigma $d-sigma $dim $p-sigma $mu-eff $C-inv-sqrt $y))
                (($new-cov $new-p-c) (new-cov $cov $p-c $new-p-sigma $c-sigma $gen $y $normalized-weights $selected $mean))
                ($clean (collapse (match &single-cma-es-inputspace (Inputs $params) (remove-atom &single-cma-es-inputspace (Inputs $params)))))
                ($cleanspace (collapse(superpose((clean-from-space &rmspace) (clean-from-space &cispace1) (clean-from-space &cispace2) (clean-from-space &cispace3)))))
                ($_ (println!(GENERATION $gen |  Max Fitness $new-best-fitness  |  Stall $new-stall)))
            )
            (let $added (add-reduct &single-cma-es-inputspace (Inputs ($new-mean $new-cov $new-step-size $new-p-sigma $new-p-c $new-best-pop $new-best-fitness (+ 1 $gen) $new-stall))) ($new-best-pop $new-best-fitness)))
        )
    )
)

(= (cma-es-main-loop)
    (let $iters (generate-toy-list (GENERATIONS))  
        (map-atom $iters $iter (cma-es-single-iteration population-fitness-score-test))
        )
)

; !(cma-es-main-loop)

(= (moedd-cma-es-single-iteration $fitness-fn $iter)
    (let ($mean $cov $step-size $p-sigma $p-c $best-pop $best-fitness $gen $stall) (match &single-cma-es-inputspace (Inputs $x) $x)
        (let*
        (
            (($normalized-weights $c-sigma $d-sigma $mu $mu-eff $dim $rmspace $cispace1 $cispace2 $cispace3) (collapse(superpose((normalized_weights) (c_sigma) (d_sigma) (mu) (mu_eff) (dim) &rmspace &cispace1 &cispace2 &cispace3))))
            ($samples (mat-clip (random-multivariate $mean (mat-scalar-op $cov (pow-math $step-size 2) *) (lambda_) $rmspace) 0 1))
            (($selected $fitness-score) (moedd-update-mean $samples $mu $normalized-weights $fitness-fn $iter))
            (($new-best-pop $new-best-fitness) ((cons-atom $selected $best-pop) (if (== (get-metatype $best-fitness) Grounded) (cons-atom $fitness-score ()) (cons-atom $fitness-score $best-fitness))))
            ($clean (collapse (match &single-cma-es-inputspace (Inputs $params) (remove-atom &single-cma-es-inputspace (Inputs $params)))))
            ($cleanspace (collapse(superpose((clean-from-space &rmspace) (clean-from-space &cispace1) (clean-from-space &cispace2) (clean-from-space &cispace3)))))
        )
        (let $added (add-reduct &single-cma-es-inputspace (Inputs ($mean $cov $step-size $p-sigma $p-c $new-best-pop $new-best-fitness $gen $stall))) ($new-best-pop $new-best-fitness))
        )
    )
)

;;;; Multi-Objective CMA-ES ;;;;

(= (Num-subproblems) 6)
(= (Num-objectives) 2)
(= (Weight) (let $nos (Num-subproblems) (np-dirichlet (1 1) $nos)))
(= (Moedd-cma-gen) 5)

!(bind! &multi-cma-es-inputspace (new-space))
!(add-reduct &multi-cma-es-inputspace (Inputs ((zeros-vec (Num-objectives)) () 0)))

(= (moedd-cma-es-single-generation $weights)
    (let*
        (
            ($_ (println! ("Starting moedd-cma-es-single-generation")))
            (($ref-point $pop $gen) (match &multi-cma-es-inputspace (Inputs $x) $x))
            ($_ (println! (ref-point $ref-point | Generation $gen | Population Size (size-atom $pop))))
            ($add (add-atom &self (= (scalarized-fitness $samples $iter)
                                        (let* (
                                            ($_ (println! (Calculating scalarized fitness  sample)))
                                            ($objs (map-atom $samples $sample (objectives (testconcept1) (testconcept2) $sample)))
                                            ($_ (println! (Objectives  samples $objs)))
                                            ($weight (index-atom $weights $iter))
                                            ($result ($objs (map-atom $objs $obj (pbi-scalarization $obj $ref-point $weight))))
                                        )
                                        $result

                                        ))))
            ($_ (println! (Finished adding scalarized fitness function to the space----------------------1)))
                                  
            ($iters (let $iters-res (range 0 (- (Num-subproblems) 1)  1) $iters-res))
            ($_ (println! (Iterations $iters)))
            ; ($res1 (map-atom $iters $iter (moedd-cma-es-single-iteration scalarized-fitness $iter)))
            ; ($_ (println! (Results per iteration $res1)))
            ($_ (println! (Starting Evaluation per problem caling the scalazied fitness function----------------------2)))
            (($sol $fit-score) (let $res (map-atom $iters $iter (moedd-cma-es-single-iteration scalarized-fitness $iter)) (index-atom $res (- (Num-subproblems) 1))))
            ($_ (println! (END OF THE EVALUATION OF SOL AND FITSCORE I GUESS--------------------------------->3)))
            ($clean (collapse (match &single-cma-es-inputspace (Inputs $params) (remove-atom &single-cma-es-inputspace (Inputs $params)))))
            ($add (add-reduct &single-cma-es-inputspace (Inputs ((mean) (cov) (step_size) (p_sigma) (p_c) () -10000 0 0))))
            (($new-ref-point $sub-candidates) (collapse(superpose((np-max $ref-point $fit-score 0) (zip-list $sol $fit-score)))))
            ($_ (println! (Sub candidates $sub-candidates)))
            ($best-non-dominated (filter-non-dominated $sub-candidates))
            ($_ (println! (Non dominated $best-non-dominated)))
            ($_ (println! (Calculating survivors based on PBI scalarization (size-atom $best-non-dominated))))
            ($survivors (let $length (size-atom $best-non-dominated) (if (== $length 1) ($best-non-dominated) (map-atom $iters $iter (max-best-nd $best-non-dominated $new-ref-point $iter $weights)))))
            ($_ (println! (Survivors $survivors)))
            ($filtered-surv (unionize $survivors ()))
            ($_ (println! (Filtered survivors $filtered-surv)))
            ($new-pop (union-atom $filtered-surv $pop))
            ($filtered-pop (filter-non-dominated $new-pop))
            ($_ (println! (Generation $gen | Population $filtered-pop)))
            ($clean (collapse(match &self (= (scalarized-fitness $samples $iter) (let $objs (map-atom $samples $sample (objectives (testconcept1) (testconcept2) $sample))
                                                                        (let $weight (index-atom $weights $iter) ($objs (map-atom $objs $obj (pbi-scalarization $obj $ref-point $weight))))
                                                                        )) (remove-atom &self (= (scalarized-fitness $samples $iter) (let $objs (map-atom $samples $sample (objectives (testconcept1) (testconcept2) $sample))
                                                                        (let $weight (index-atom $weights $iter) ($objs (map-atom $objs $obj (pbi-scalarization $obj $ref-point $weight))))
                                                                        ))))))
            ($clean2 (collapse (match &multi-cma-es-inputspace (Inputs $x) (remove-atom &multi-cma-es-inputspace (Inputs $x)))))
        )
        (let $added (add-reduct &multi-cma-es-inputspace (Inputs ($new-ref-point $filtered-pop (+ $gen 1)))) (cleaner $filtered-pop 0))
    )
)

(= (Eval) True)

(= (moedd-cma-es-main-loop)
    (let $weights (Weight) (let $iterations (range 0 (- (Moedd-cma-gen) 1) 1) (map-atom $iterations $iteration (moedd-cma-es-single-generation $weights))))
)

 !(moedd-cma-es-main-loop) 

