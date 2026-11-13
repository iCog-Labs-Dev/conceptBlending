pathmap_text(Value, Text) :-
    ( string(Value) -> Text = Value
    ; atom(Value) -> atom_string(Value, Text)
    ; number(Value) -> number_string(Value, Text)
    ; throw(error(type_error(pathmap_text, Value), _))
    ).

pathmap_request(Fields, Request) :-
    maplist(pathmap_text, Fields, TextFields),
    atomics_to_string(TextFields, "\t", Request).

pathmap_response(Response, _) :-
    sub_string(Response, 0, 5, _, "ERR: "), !,
    sub_string(Response, 5, _, 0, Message),
    throw(error(pathmap_kb_error(Message), _)).
pathmap_response(Response, Result) :-
    sread(Response, Result).

pathmap_typed(Command, Fields, Result) :-
    pathmap_request(Fields, Request),
    ( pathmap_kb_typed(Command, Request, Result)
    -> true
    ;  throw(error(pathmap_kb_error("typed query failed"), _))
    ).

'pathmap-open!'(Handle, Root, Result) :-
    pathmap_request([Handle, Root], Request),
    pathmap_kb("open", Request, Response),
    pathmap_response(Response, Result).

'pathmap-close!'(Handle, Result) :-
    pathmap_request([Handle], Request),
    pathmap_kb("close", Request, Response),
    pathmap_response(Response, Result).

'pathmap-query-algebra'(Handle, Perspective, Concept, Family, Result) :-
    pathmap_typed("query-algebra", [Handle, Perspective, Concept, Family], Result).

'pathmap-query-properties'(Handle, Perspective, Concept, Result) :-
    pathmap_typed("query-properties", [Handle, Perspective, Concept], Result).

'pathmap-query-worlds'(Handle, Perspective, Concept, Property, Result) :-
    pathmap_typed("query-worlds", [Handle, Perspective, Concept, Property], Result).

'pathmap-build-specification'(Handle, Perspective, Concept, Result) :-
    pathmap_typed("build-specification", [Handle, Perspective, Concept], Result).

:- library('pathmap_kb_ffi', 'pathmaplib.so', Library),
   ( exists_file(Library)
   -> use_foreign_library(Library)
   ;  throw(error(existence_error(file, Library), _))
   ).
