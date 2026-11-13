:- encoding(utf8).

:- getenv('PETTA_HOME', PettaHome),
   directory_file_path(PettaHome, 'src/metta.pl', Metta),
   ensure_loaded(Metta).

:- initialization(main, main).

load_line(Line) :-
    ( Line == end_of_file -> true
    ; Line == "" -> true
    ; sread(Line, Term),
      'add-atom'('&mork', Term, true)
    ).

load_prefix(Path, Limit, Loaded) :-
    setup_call_cleanup(
        open(Path, read, Stream, [encoding(utf8)]),
        load_prefix_stream(Stream, Limit, 0, Loaded),
        close(Stream)).

load_prefix_stream(_, 0, Loaded, Loaded) :- !.
load_prefix_stream(Stream, Remaining, Acc, Loaded) :-
    read_line_to_string(Stream, Line),
    ( Line == end_of_file
    -> Loaded = Acc
    ;  load_line(Line),
       NextRemaining is Remaining - 1,
       NextAcc is Acc + 1,
       load_prefix_stream(Stream, NextRemaining, NextAcc, Loaded)
    ).

load_property_world_window(Path, Loaded) :-
    setup_call_cleanup(
        open(Path, read, Stream, [encoding(utf8)]),
        load_line_window(Stream, 1, 401352, 401380, 0, Loaded),
        close(Stream)).

load_line_window(_, LineNo, _, Last, Loaded, Loaded) :-
    LineNo > Last, !.
load_line_window(Stream, LineNo, First, Last, Acc, Loaded) :-
    read_line_to_string(Stream, Line),
    ( Line == end_of_file
    -> Loaded = Acc
    ;  ( LineNo >= First
       -> load_line(Line), NextAcc is Acc + 1
       ;  NextAcc = Acc
       ),
       NextLine is LineNo + 1,
       load_line_window(Stream, NextLine, First, Last, NextAcc, Loaded)
    ).

mm2_rule(Run, sort,
    [exec, [Run, sort],
     [',', [':', E, ['≞', [has_sort, E, a2, descriptive_property, Sort], [stv, S, C]]]],
     [',', [mm2_result, sort, Sort, S, C]]]).

mm2_rule(Run, operation,
    [exec, [Run, operation],
     [',',
      [':', E, ['≞', [has_operation, E, a2, descriptive_property, Operation], [stv, OS, OC]]],
      [':', _SE, ['≞', [operation_signature, E, Signature], [stv, SS, SC]]]],
     [',', [mm2_result, operation, Operation, Signature, OS, OC, SS, SC]]]).

mm2_rule(Run, predicate,
    [exec, [Run, predicate],
     [',', [':', E, ['≞', [has_predicate, E, a2, descriptive_property, Predicate], [stv, S, C]]]],
     [',', [mm2_result, predicate, Predicate, S, C]]]).

mm2_rule(Run, axiom,
    [exec, [Run, axiom],
     [',', [':', E, ['≞', [has_axiom, E, a2, descriptive_property, Axiom], [stv, S, C]]]],
     [',', [mm2_result, axiom, Axiom, S, C]]]).

mm2_rule(Run, property,
    [exec, [Run, property],
     [',', [':', E, ['≞', [has_scoped_property, E, a2, descriptive_property, Ref, Property], [stv, S, C]]]],
     [',', [mm2_result, property, Property, Ref, S, C]]]).

mm2_rule(Run, world,
    [exec, [Run, world],
     [',',
      [':', PE, ['≞', [has_scoped_property, PE, a2, descriptive_property, Ref, Property], _PTV]],
      [':', WE, ['≞', [scoped_property_holds_in, WE, Ref, descriptive_property, World], [stv, S, C]]]],
     [',', [mm2_result, world, Property, World, S, C]]]).

add_iteration_rules(Run) :-
    forall(member(Family, [sort, operation, predicate, axiom, property, world]),
           (mm2_rule(Run, Family, Rule),
            ( getenv('PETTA_BENCH_PRINT_RULES', '1')
            -> swrite(Rule, Rendered), format('rule=~s~n', [Rendered])
            ;  true
            ),
            'add-atom'('&mork', Rule, true))).

prepare_rules(Iterations) :-
    forall(between(1, Iterations, Run), add_iteration_rules(Run)).

result_pattern([mm2_result, sort, _, _, _]).
result_pattern([mm2_result, operation, _, _, _, _, _, _]).
result_pattern([mm2_result, predicate, _, _, _]).
result_pattern([mm2_result, axiom, _, _, _]).
result_pattern([mm2_result, property, _, _, _, _]).
result_pattern([mm2_result, world, _, _, _, _]).

result_rows(Rows) :-
    findall(Row,
            (result_pattern(Pattern), match('&mork', Pattern, Pattern, Row)),
            RawRows),
    sort(RawRows, Rows).

result_group_counts(Rows, Counts) :-
    findall(Count,
            (member(Family, [sort, operation, predicate, axiom, property, world]),
             include({Family}/[Row]>>(Row = [mm2_result, Family|_]), Rows, FamilyRows),
             length(FamilyRows, Count)),
            Counts).

main(Argv) :-
    ( Argv = [Algebraic, Property, PrefixAtom, IterAtom, mork]
    -> true
    ;  format(user_error,
              'usage: ... petta_mm2_bench.pl -- ALG PROP PREFIX ITERATIONS mork~n', []),
       halt(2)
    ),
    atom_number(PrefixAtom, Prefix),
    atom_number(IterAtom, Iterations),
    get_time(LoadStart),
    load_prefix(Algebraic, Prefix, AlgebraicLoaded),
    load_prefix(Property, Prefix, PropertyLoaded),
    load_property_world_window(Property, WindowLoaded),
    get_time(LoadEnd),
    add_iteration_rules(0),
    'mm2-exec'('&mork', 1000000000, true),
    prepare_rules(Iterations),
    get_time(QueryStart),
    'mm2-exec'('&mork', 1000000000, true),
    get_time(QueryEnd),
    result_rows(Rows),
    length(Rows, RowCount),
    result_group_counts(Rows, GroupCounts),
    term_hash(Rows, ResultHash),
    Loaded is AlgebraicLoaded + PropertyLoaded + WindowLoaded,
    LoadMs is (LoadEnd - LoadStart) * 1000,
    QueryTotalMs is (QueryEnd - QueryStart) * 1000,
    QueryMeanUs is QueryTotalMs * 1000 / Iterations,
    statistics(globalused, GlobalBytes),
    format('backend=mm2 loaded=~d rows=~d groups=~w result_hash=~d load_ms=~2f iterations=~d query_total_ms=~2f query_mean_us=~2f global_bytes=~d~n',
           [Loaded, RowCount, GroupCounts, ResultHash, LoadMs, Iterations,
            QueryTotalMs, QueryMeanUs, GlobalBytes]),
    ( GroupCounts == [6, 1, 5, 1, 2, 9] -> halt ; halt(1) ).
