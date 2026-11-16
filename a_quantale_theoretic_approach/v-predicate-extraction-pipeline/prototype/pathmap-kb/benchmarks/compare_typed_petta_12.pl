:- encoding(utf8).

:- getenv('PETTA_HOME', PettaHome),
   directory_file_path(PettaHome, 'src/metta.pl', Metta),
   ensure_loaded(Metta).

:- initialization(main, main).

% Expose the compiled MeTTa triplet predicates as one PeTTa space without copying millions of
% terms into another dynamic predicate.
'&qlf'(:, Evidence, Atom) :- '&algkb'(:, Evidence, Atom).
'&qlf'(:, Evidence, Atom) :- '&propertyworldkb'(:, Evidence, Atom).
:- dynamic '&qlf'/6.
:- dynamic '&qlf'/7.
:- dynamic '&qlf'/8.

build_secondary_indexes :-
    forall('&algkb'(:, Evidence, Atom), index_algebra_atom(Evidence, Atom)),
    forall('&propertyworldkb'(:, Evidence, Atom), index_property_atom(Evidence, Atom)).

index_algebra_atom(Evidence,
                   [≞, [has_sort, Evidence, Concept, Perspective, Sort],
                        [stv, Strength, Confidence]]) :- !,
    assertz('&qlf'(sort_by_concept, Concept, Perspective, Evidence, Sort,
                   Strength, Confidence)).
index_algebra_atom(Evidence,
                   [≞, [has_operation, Evidence, Concept, Perspective, Operation],
                        [stv, Strength, Confidence]]) :- !,
    assertz('&qlf'(operation_by_concept, Concept, Perspective, Evidence, Operation,
                   Strength, Confidence)).
index_algebra_atom(SignatureEvidence,
                   [≞, [operation_signature, OperationEvidence, Signature],
                        [stv, Strength, Confidence]]) :- !,
    assertz('&qlf'(signature_by_operation, OperationEvidence, SignatureEvidence,
                   Signature, Strength, Confidence)).
index_algebra_atom(Evidence,
                   [≞, [has_predicate, Evidence, Concept, Perspective, Predicate],
                        [stv, Strength, Confidence]]) :- !,
    assertz('&qlf'(predicate_by_concept, Concept, Perspective, Evidence, Predicate,
                   Strength, Confidence)).
index_algebra_atom(Evidence,
                   [≞, [has_axiom, Evidence, Concept, Perspective, Axiom],
                        [stv, Strength, Confidence]]) :- !,
    assertz('&qlf'(axiom_by_concept, Concept, Perspective, Evidence, Axiom,
                   Strength, Confidence)).
index_algebra_atom(_, _).

index_property_atom(Evidence,
                    [≞, [has_scoped_property, Evidence, Concept, Perspective,
                         PropertyRef, Property],
                         [stv, Strength, Confidence]]) :- !,
    assertz('&qlf'(property_by_concept, Concept, Perspective, Evidence,
                   PropertyRef, Property, Strength, Confidence)).
index_property_atom(Evidence,
                    [≞, [scoped_property_holds_in, Evidence, PropertyRef,
                         Perspective, World],
                         [stv, Strength, Confidence]]) :- !,
    assertz('&qlf'(world_by_ref, PropertyRef, Perspective, Evidence, World,
                   Strength, Confidence)).
index_property_atom(_, _).

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

query(1, functional_use, computer).
query(2, functional_use, phone).
query(3, functional_use, mobile_phone).
query(4, functional_use, digital_television).
query(5, functional_use, letter).
query(6, functional_use, broom).
query(7, taxonomic_kind, dog).
query(8, taxonomic_kind, computer).
query(9, artifact_kind, computer).
query(10, spatial_context, hospital).
query(11, descriptive_property, human).
query(12, functional_use, computer).

preload_perspectives :-
    forall(member(Perspective-Concept,
                  [functional_use-computer,
                   taxonomic_kind-dog,
                   artifact_kind-computer,
                   spatial_context-hospital,
                   descriptive_property-human]),
           'pathmap-query-algebra'(comparison, Perspective, Concept, sort, _)).

row_count([specification|Groups], Count) :-
    maplist(length, Groups, Counts),
    sum_list(Counts, Count).

group_counts([specification|Groups], Counts) :-
    maplist(length, Groups, Counts).

run_comparison(_, [], 0.0, 0.0).
run_comparison(Phase, [Id-Perspective-Concept|Rest], PathTotalMs, PettaTotalMs) :-
    get_time(PathStart),
    'pathmap-build-specification'(comparison, Perspective, Concept, PathRows),
    get_time(PathEnd),
    row_count(PathRows, PathCount),
    group_counts(PathRows, PathGroups),
    PathMs is (PathEnd - PathStart) * 1000.0,

    get_time(PettaStart),
    'build-algebraic-spec'('&qlf', Concept, Perspective, PettaRows),
    get_time(PettaEnd),
    row_count(PettaRows, PettaCount),
    group_counts(PettaRows, PettaGroups),
    PettaMs is (PettaEnd - PettaStart) * 1000.0,

    ( PathCount =:= PettaCount,
      PathGroups == PettaGroups
    -> true
    ;  throw(error(result_shape_mismatch(Id, Perspective, Concept,
                                         PathGroups, PettaGroups), _))
    ),
    Speedup is PettaMs / PathMs,
    format('phase=~w query=~d perspective=~w concept=~w rows=~d pathmap_ms=~6f petta_ms=~3f speedup=~2f~n',
           [Phase, Id, Perspective, Concept, PathCount, PathMs, PettaMs, Speedup]),
    run_comparison(Phase, Rest, PathRestMs, PettaRestMs),
    PathTotalMs is PathMs + PathRestMs,
    PettaTotalMs is PettaMs + PettaRestMs.

main(Argv) :-
    ( Argv = [AlgebraicQlf, PropertyQlf, IndexRoot]
    -> true
    ;  format(user_error,
              'usage: compare_typed_petta_12.pl ALGEBRAIC.qlf PROPERTY.qlf INDEX_ROOT~n', []),
       halt(2)
    ),

    get_time(PettaLoadStart),
    load_files(AlgebraicQlf, [silent(true)]),
    load_files(PropertyQlf, [silent(true)]),
    get_time(PettaQlfLoadEnd),
    build_secondary_indexes,
    get_time(PettaLoadEnd),
    query_source(Source),
    process_metta_string(Source, []),

    'pathmap-open!'(comparison, IndexRoot, _),
    get_time(PathLoadStart),
    preload_perspectives,
    get_time(PathLoadEnd),

    findall(Id-Perspective-Concept, query(Id, Perspective, Concept), Queries),
    run_comparison(first, Queries, PathFirstMs, PettaFirstMs),
    run_comparison(warm, Queries, PathWarmMs, PettaWarmMs),

    PettaQlfLoadMs is (PettaQlfLoadEnd - PettaLoadStart) * 1000.0,
    PettaSecondaryIndexMs is (PettaLoadEnd - PettaQlfLoadEnd) * 1000.0,
    PettaLoadMs is PettaQlfLoadMs + PettaSecondaryIndexMs,
    PathLoadMs is (PathLoadEnd - PathLoadStart) * 1000.0,
    PathEndToEndMs is PathLoadMs + PathFirstMs,
    PettaEndToEndMs is PettaLoadMs + PettaFirstMs,
    FirstSpeedup is PettaFirstMs / PathFirstMs,
    WarmSpeedup is PettaWarmMs / PathWarmMs,
    EndToEndSpeedup is PettaEndToEndMs / PathEndToEndMs,
    format('collective phase=first queries=12 pathmap_query_ms=~6f petta_query_ms=~3f speedup=~2f~n',
           [PathFirstMs, PettaFirstMs, FirstSpeedup]),
    format('collective phase=warm queries=12 pathmap_query_ms=~6f petta_query_ms=~3f speedup=~2f~n',
           [PathWarmMs, PettaWarmMs, WarmSpeedup]),
    format('end_to_end phase=first pathmap_load_ms=~3f petta_load_ms=~3f pathmap_total_ms=~3f petta_total_ms=~3f speedup=~2f~n',
           [PathLoadMs, PettaLoadMs, PathEndToEndMs, PettaEndToEndMs, EndToEndSpeedup]),
    format('petta_load_breakdown qlf_ms=~3f secondary_index_ms=~3f~n',
           [PettaQlfLoadMs, PettaSecondaryIndexMs]),
    'pathmap-close!'(comparison, _),
    halt.
