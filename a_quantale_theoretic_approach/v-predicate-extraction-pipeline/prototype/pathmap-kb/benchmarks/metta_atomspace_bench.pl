:- dynamic extension_fact/7.

:- initialization(main, main).

load_kbs(Algebraic, Property) :-
    load_files(Algebraic, [silent(true)]),
    load_files(Property, [silent(true)]).

specification(Concept, Perspective, Rows) :-
    findall(sort(Sort, Strength, Confidence, Evidence),
            '&algkb'(:, Evidence,
                     [≞, [has_sort, Evidence, Concept, Perspective, Sort],
                          [stv, Strength, Confidence]]),
            Sorts),
    findall(operation(Operation, Signature, OpStrength, OpConfidence,
                      SigStrength, SigConfidence, Evidence, SignatureEvidence),
            ('&algkb'(:, Evidence,
                      [≞, [has_operation, Evidence, Concept, Perspective, Operation],
                           [stv, OpStrength, OpConfidence]]),
             '&algkb'(:, SignatureEvidence,
                      [≞, [operation_signature, Evidence, Signature],
                           [stv, SigStrength, SigConfidence]])),
            Operations),
    findall(predicate(Predicate, Strength, Confidence, Evidence),
            '&algkb'(:, Evidence,
                     [≞, [has_predicate, Evidence, Concept, Perspective, Predicate],
                          [stv, Strength, Confidence]]),
            Predicates),
    findall(axiom(Axiom, Strength, Confidence, Evidence),
            '&algkb'(:, Evidence,
                     [≞, [has_axiom, Evidence, Concept, Perspective, Axiom],
                          [stv, Strength, Confidence]]),
            Axioms),
    findall(property(PropertyName, PropertyRef, Strength, Confidence, Evidence),
            '&propertyworldkb'(:, Evidence,
                               [≞, [has_scoped_property, Evidence, Concept, Perspective,
                                    PropertyRef, PropertyName],
                                    [stv, Strength, Confidence]]),
            Properties),
    findall(world(PropertyName, World, Strength, Confidence, Evidence),
            ('&propertyworldkb'(:, PropertyEvidence,
                                [≞, [has_scoped_property, PropertyEvidence, Concept,
                                     Perspective, PropertyRef, PropertyName], _]),
             '&propertyworldkb'(:, Evidence,
                                [≞, [scoped_property_holds_in, Evidence, PropertyRef,
                                     Perspective, World],
                                     [stv, Strength, Confidence]])),
            Worlds),
    append([Sorts, Operations, Predicates, Axioms, Properties, Worlds], Rows).

run_iterations(0, _, _, _, 0) :- !.
run_iterations(N, Concept, Perspective, ExpectedCount, Checksum) :-
    specification(Concept, Perspective, Rows),
    length(Rows, ExpectedCount),
    term_hash(Rows, ThisChecksum),
    Next is N - 1,
    run_iterations(Next, Concept, Perspective, ExpectedCount, RestChecksum),
    Checksum is xor(ThisChecksum, RestChecksum).

extend(Count) :-
    forall(between(1, Count, N),
           (atom_concat(extension_sort_, N, Sort),
            atom_concat(extension_evidence_, N, Evidence),
            assertz(extension_fact(extension_source, Evidence, extension_concept,
                                   functional_use, sort, Sort, stv(900, 860))))).

main(Argv) :-
    ( Argv = [Algebraic, Property, ConceptAtom, PerspectiveAtom, IterAtom, ExtendAtom]
    -> true
    ;  format(user_error,
              'usage: swipl -q -f metta_atomspace_bench.pl -- ALG.qlf PROP.qlf CONCEPT PERSPECTIVE ITERATIONS EXTENSIONS~n', []),
       halt(2)
    ),
    atom_number(IterAtom, Iterations),
    atom_number(ExtendAtom, ExtensionCount),
    statistics(walltime, [LoadStart|_]),
    load_kbs(Algebraic, Property),
    statistics(walltime, [LoadEnd|_]),
    LoadMs is LoadEnd - LoadStart,
    specification(ConceptAtom, PerspectiveAtom, WarmRows),
    length(WarmRows, RowCount),
    statistics(walltime, [QueryStart|_]),
    run_iterations(Iterations, ConceptAtom, PerspectiveAtom, RowCount, Checksum),
    statistics(walltime, [QueryEnd|_]),
    QueryMs is QueryEnd - QueryStart,
    QueryUs is (QueryMs * 1000) / Iterations,
    statistics(walltime, [ExtendStart|_]),
    extend(ExtensionCount),
    statistics(walltime, [ExtendEnd|_]),
    ExtendMs is ExtendEnd - ExtendStart,
    statistics(walltime, [ExtensionQueryStart|_]),
    findall(Sort, extension_fact(extension_source, _, extension_concept,
                                  functional_use, sort, Sort, _), ExtensionRows),
    length(ExtensionRows, ExtensionCount),
    statistics(walltime, [ExtensionQueryEnd|_]),
    ExtensionQueryUs is (ExtensionQueryEnd - ExtensionQueryStart) * 1000,
    statistics(globalused, GlobalBytes),
    format('backend=metta_qlf load_ms=~d rows=~d iterations=~d query_total_ms=~d query_mean_us=~2f checksum=~d extension_count=~d extension_ms=~d extension_query_us=~d global_bytes=~d~n',
           [LoadMs, RowCount, Iterations, QueryMs, QueryUs, Checksum,
            ExtensionCount, ExtendMs, ExtensionQueryUs, GlobalBytes]),
    halt.
