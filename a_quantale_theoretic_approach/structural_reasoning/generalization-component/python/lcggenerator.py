def build_chain(side, depth, var_offset):
    """
    side: 'c1' or 'c2'
    depth: chain depth (0 means direct to lcg)
    var_offset: starting index for fresh variables

    Returns:
      atoms: list of (≞ ...) strings
      tv_expr: string to be used inside lcg-formula
      next_var_offset: updated offset
    """
    atoms = []

    # depth 0 → direct link
    if depth == 0:
        tv = f"${side}lcgtv"
        atoms.append(f"(≞ (→ ${side} $lcg ()) {tv})")
        return atoms, tv, var_offset

    # depth ≥ 1 → chain + stv
    tvs = []
    prev = f"${side}"

    for i in range(depth):
        var = f"$var{var_offset}"
        tv = f"${prev.strip('$')}{var.strip('$')}tv"
        atoms.append(f"(≞ (→ {prev} {var} ()) {tv})")
        tvs.append(tv)
        prev = var
        var_offset += 1

    tv = f"${prev.strip('$')}lcgtv"
    atoms.append(f"(≞ (→ {prev} $lcg ()) {tv})")
    tvs.append(tv)

    return atoms, f"(stv ({' '.join(tvs)}) ())", var_offset


def generate_lcg_rules(max_depth):
    rules = []

    # ---------- depth 0 (single rule) ----------
    rules.append(
        """(: LCG-DEPTH-0
    (-> (≞ $c1 $c1tv)
        (≞ $c2 $c2tv)
        (≞ $lcg $lcgtv)
        (≞ (→ $c1 $lcg ()) $c1lcgtv)
        (≞ (→ $c2 $lcg ()) $c2lcgtv)
        (≞ (→ $c1 $c2 ($lcg))
            (Method lcg-formula
                $c1tv $c2tv $lcgtv
                $c1lcgtv
                $c2lcgtv)))
)"""
    )

    # ---------- depths ≥ 1 ----------
    for D in range(1, max_depth + 1):
        for d1 in range(D + 1):
            for d2 in range(D + 1):
                if max(d1, d2) != D:
                    continue

                atoms = [
                    "(≞ $c1 $c1tv)",
                    "(≞ $c2 $c2tv)",
                    "(≞ $lcg $lcgtv)"
                ]

                var_offset = 0

                c1_atoms, c1_tv, var_offset = build_chain("c1", d1, var_offset)
                c2_atoms, c2_tv, var_offset = build_chain("c2", d2, var_offset)

                atoms.extend(c1_atoms)
                atoms.extend(c2_atoms)

                rule = f"""(: LCG-D{D}-C1{d1}-C2{d2}
    (-> {' '.join(atoms)}
        (≞ (→ $c1 $c2 ($lcg))
            (Method lcg-formula
                $c1tv $c2tv $lcgtv
                {c1_tv}
                {c2_tv})))
)"""

                rules.append(rule)

    # ---------- wrap everything ----------
    return "(\n" + "\n\n".join(rules) + "\n)"

def generate_nullary_synthesizer():
    return """
        (= (synthesize $query $kb $rb $depth)
        (let*
            (
            ($query ($kb))
            )
            $query
        )
        )
        """

def generate_synthesizer(n):
    """
    Generates an n-ary synthesize rule.
    """
    premises = " ".join([f"$premise{i}" for i in range(1, n + 1)])
    proofs = " ".join([f"$proof{i}" for i in range(1, n + 1)])

    recursive_calls = "\n          ".join(
        [
            f"((: $proof{i} $premise{i}) "
            f"(synthesize (: $proof{i} $premise{i}) $kb $rb $k))"
            for i in range(1, n + 1)
        ]
    )

    return f"""
        (= (synthesize $query $kb $rb (S $k))
        (let* (
                ((: $ructor (-> {premises} $conclusion)) ($rb))
                ((: ($ructor {proofs}) $conclusion) $query)
                {recursive_calls}
                )
            (let (: $finalproof ($measq $finalconc $finalstv))
                $query
                (: $finalproof
                    ($measq $finalconc
                            (let $res (cdr-atom $finalstv)
                                (eval $res)))))
        )
        )
        """

def generate_all_synthesizers(max_depth):
    synthesizers = []

    # 1. Nullary synthesizer
    synthesizers.append(generate_nullary_synthesizer())

    # 2. Compute maximum required arity
    max_premises = 2 * max_depth + 5

    # 3. Unary → max-arity synthesizers
    for n in range(1, max_premises + 1):
        synthesizers.append(generate_synthesizer(n))

    # 4. Wrap everything
    return "\n".join(synthesizers) + "\n"

def generate_lcg_with_synthesizers(max_depth):
    parts = []

    # LCG rules (already wrapped internally)
    parts.append(generate_lcg_rules(max_depth))

    # Synthesizers (wrapped here)
    parts.append(generate_all_synthesizers(max_depth))

    return "\n\n".join(parts)

def generate_lcg_and_write_synthesizers(max_depth, synthesizer_path):
    """
    - Writes synthesizers to `synthesizer_path`
    - Returns LCG rules as a string
    """

    # 1. Generate LCG rules (returned)
    lcg_rules = generate_lcg_rules(max_depth)

    # 2. Generate synthesizers (written to file)
    synthesizers = generate_all_synthesizers(max_depth)
    # with open(synthesizer_path, "w") as f:
    #     f.write(synthesizers)

    return lcg_rules



# print(generate_lcg_and_write_synthesizers(2, "synthesizers.metta"))
