:- encoding(utf8).

:- getenv('PETTA_HOME', PettaHome),
   directory_file_path(PettaHome, 'src/metta.pl', Metta),
   ensure_loaded(Metta).

:- initialization(main, main).

query_source("(= (worlds-for-property-ref $space $perspective $row)
   (let (property-ref $property-ref) $row
     (collapse
       (match $space
         (world_by_ref $property-ref $perspective $e $world $s $c)
         (world-row $property-ref $world $s $c)))))

(= (property-to-ref $row)
   (let (property $property $property-ref $s $c) $row
     (property-ref $property-ref)))

(= (complete-operation $space $declaration)
   (let (operation-declaration $operation $os $oc $e) $declaration
     (car-atom
       (collapse
         (match $space
           (signature_by_operation $e $se $signature $ss $sc)
           (operation $operation $signature $os $oc $ss $sc))))))

(= (build-algebraic-spec $space $concept $perspective)
   (let* (
     ($sorts
     (collapse
       (match $space
         (sort_by_concept $concept $perspective $e $sort $s $c)
         (sort-row $sort $s $c))))
     ($operation-declarations
     (collapse
       (match $space
         (operation_by_concept $concept $perspective $e $operation $os $oc)
         (operation-declaration $operation $os $oc $e))))
     ($operations (map-atom $operation-declarations (complete-operation $space)))
     ($predicates
     (collapse
       (match $space
         (predicate_by_concept $concept $perspective $e $predicate $s $c)
         (predicate $predicate $s $c))))
     ($axioms
     (collapse
       (match $space
         (axiom_by_concept $concept $perspective $e $axiom $s $c)
         (axiom $axiom $s $c))))
     ($properties
     (collapse
       (match $space
         (property_by_concept $concept $perspective $e $property-ref $property $s $c)
         (property $property $property-ref $s $c))))
     ($property-refs (map-atom $properties property-to-ref))
     ($worlds
      (foldl-atom $property-refs () $acc $property-ref-row
        (append $acc
                (worlds-for-property-ref $space $perspective $property-ref-row)))))
     (specification $sorts $operations $predicates $axioms $properties $worlds)))").

backend_space(self, '&self').
backend_space(mork, '&mork').

load_line(Line, Space) :-
    ( Line == end_of_file -> true
    ; Line == "" -> true
    ; sread(Line, Term),
      'add-atom'(Space, Term, true),
      index_term(Space, Term)
    ).

index_term(Space,
           [:, Evidence,
            [≞, [has_sort, Evidence, Concept, Perspective, Sort],
                 [stv, Strength, Confidence]]]) :- !,
    'add-atom'(Space,
               [sort_by_concept, Concept, Perspective, Evidence, Sort,
                Strength, Confidence], true).
index_term(Space,
           [:, Evidence,
            [≞, [has_operation, Evidence, Concept, Perspective, Operation],
                 [stv, Strength, Confidence]]]) :- !,
    'add-atom'(Space,
               [operation_by_concept, Concept, Perspective, Evidence, Operation,
                Strength, Confidence], true).
index_term(Space,
           [:, SignatureEvidence,
            [≞, [operation_signature, OperationEvidence, Signature],
                 [stv, Strength, Confidence]]]) :- !,
    'add-atom'(Space,
               [signature_by_operation, OperationEvidence, SignatureEvidence,
                Signature, Strength, Confidence], true).
index_term(Space,
           [:, Evidence,
            [≞, [has_predicate, Evidence, Concept, Perspective, Predicate],
                 [stv, Strength, Confidence]]]) :- !,
    'add-atom'(Space,
               [predicate_by_concept, Concept, Perspective, Evidence, Predicate,
                Strength, Confidence], true).
index_term(Space,
           [:, Evidence,
            [≞, [has_axiom, Evidence, Concept, Perspective, Axiom],
                 [stv, Strength, Confidence]]]) :- !,
    'add-atom'(Space,
               [axiom_by_concept, Concept, Perspective, Evidence, Axiom,
                Strength, Confidence], true).
index_term(Space,
           [:, Evidence,
            [≞, [has_scoped_property, Evidence, Concept, Perspective,
                 PropertyRef, Property],
                 [stv, Strength, Confidence]]]) :- !,
    'add-atom'(Space,
               [property_by_concept, Concept, Perspective, Evidence,
                PropertyRef, Property, Strength, Confidence], true).
index_term(Space,
           [:, Evidence,
            [≞, [scoped_property_holds_in, Evidence, PropertyRef, Perspective, World],
                 [stv, Strength, Confidence]]]) :- !,
    'add-atom'(Space,
               [world_by_ref, PropertyRef, Perspective, Evidence, World,
                Strength, Confidence],
               true).
index_term(_, _).

load_prefix(Path, Limit, Space, Loaded) :-
    setup_call_cleanup(
        open(Path, read, Stream, [encoding(utf8)]),
        load_prefix_stream(Stream, Limit, Space, 0, Loaded),
        close(Stream)).

load_prefix_stream(_, 0, _, Loaded, Loaded) :- !.
load_prefix_stream(Stream, Remaining, Space, Acc, Loaded) :-
    read_line_to_string(Stream, Line),
    ( Line == end_of_file
    -> Loaded = Acc
    ;  load_line(Line, Space),
       NextRemaining is Remaining - 1,
       NextAcc is Acc + 1,
       load_prefix_stream(Stream, NextRemaining, Space, NextAcc, Loaded)
    ).

% The selected target's property-world rows are late in the generated file.
% Add lines 401352--401380 after the common prefix so the query exercises worlds.
load_property_world_window(Path, Space, Loaded) :-
    setup_call_cleanup(
        open(Path, read, Stream, [encoding(utf8)]),
        load_line_window(Stream, 1, 401352, 401380, Space, 0, Loaded),
        close(Stream)).

load_line_window(_, LineNo, _, Last, _, Loaded, Loaded) :-
    LineNo > Last, !.
load_line_window(Stream, LineNo, First, Last, Space, Acc, Loaded) :-
    read_line_to_string(Stream, Line),
    ( Line == end_of_file
    -> Loaded = Acc
    ;  ( LineNo >= First
       -> load_line(Line, Space), NextAcc is Acc + 1
       ;  NextAcc = Acc
       ),
       NextLine is LineNo + 1,
       load_line_window(Stream, NextLine, First, Last, Space, NextAcc, Loaded)
    ).

row_count([specification|Groups], Count) :-
    maplist(length, Groups, Counts),
    sum_list(Counts, Count).

group_counts([specification|Groups], Counts) :-
    maplist(length, Groups, Counts).

canonical_result([specification|Groups], [specification|SortedGroups]) :-
    maplist(msort, Groups, SortedGroups).

maybe_print_result(Result) :-
    ( getenv('PETTA_BENCH_PRINT_RESULT', '1')
    -> swrite(Result, Rendered), format('result=~s~n', [Rendered])
    ;  true
    ).

run_queries(0, _, 0) :- !.
run_queries(N, Space, Checksum) :-
    'build-algebraic-spec'(Space, a2, descriptive_property, Rows),
    canonical_result(Rows, CanonicalRows),
    term_hash(CanonicalRows, Hash),
    Next is N - 1,
    run_queries(Next, Space, Rest),
    Checksum is xor(Hash, Rest).

main(Argv) :-
    ( Argv = [BackendAtom, Algebraic, Property, PrefixAtom, IterAtom, mork]
    -> true
    ;  format(user_error,
              'usage: ... petta_space_bench.pl -- self|mork ALG PROP PREFIX ITERATIONS mork~n', []),
       halt(2)
    ),
    backend_space(BackendAtom, Space),
    atom_number(PrefixAtom, Prefix),
    atom_number(IterAtom, Iterations),
    get_time(LoadStart),
    load_prefix(Algebraic, Prefix, Space, AlgebraicLoaded),
    load_prefix(Property, Prefix, Space, PropertyLoaded),
    load_property_world_window(Property, Space, WindowLoaded),
    get_time(LoadEnd),
    query_source(QuerySource),
    process_metta_string(QuerySource, []),
    'build-algebraic-spec'(Space, a2, descriptive_property, WarmRows),
    row_count(WarmRows, RowCount),
    group_counts(WarmRows, GroupCounts),
    canonical_result(WarmRows, CanonicalWarmRows),
    term_hash(CanonicalWarmRows, ResultHash),
    maybe_print_result(CanonicalWarmRows),
    get_time(QueryStart),
    run_queries(Iterations, Space, Checksum),
    get_time(QueryEnd),
    Loaded is AlgebraicLoaded + PropertyLoaded + WindowLoaded,
    LoadMs is (LoadEnd - LoadStart) * 1000,
    QueryTotalMs is (QueryEnd - QueryStart) * 1000,
    QueryMeanUs is QueryTotalMs * 1000 / Iterations,
    statistics(globalused, GlobalBytes),
    format('backend=~w loaded=~d rows=~d groups=~w result_hash=~d load_ms=~2f iterations=~d query_total_ms=~2f query_mean_us=~2f checksum=~d global_bytes=~d~n',
           [BackendAtom, Loaded, RowCount, GroupCounts, ResultHash, LoadMs, Iterations,
            QueryTotalMs, QueryMeanUs, Checksum, GlobalBytes]),
    halt.
