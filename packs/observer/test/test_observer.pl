% Load the observer module under test from the library path.
:- use_module(library(observer)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% A fixed simulation start, so every test is deterministic and reproducible.
observer_test_start("2026-07-20T00:00:00Z").

% Open the test block for the observer pack.
:- begin_tests(observer).

% The reusable tick type is a content-addressed Causalontology occurrent.
test(tick_type_is_content_addressed_occurrent) :-
    % Mint the tick occurrent type identifier.
    observer_tick_type(TickTypeId),
    % Its identifier carries the occurrent scheme prefix.
    assertion(sub_string(TickTypeId, 0, _, _, "occurrent:")).

% Each ordinal tick maps to a deterministic absolute instant, one nominal second apart.
test(tick_instant_advances_one_second_per_tick) :-
    % The fixed simulation start.
    observer_test_start(Start),
    % Tick one is one second after the start.
    observer_tick_instant(Start, 1, InstantOne),
    % Confirm the first instant.
    assertion(InstantOne == "2026-07-20T00:00:01Z"),
    % Tick five is five seconds after the start.
    observer_tick_instant(Start, 5, InstantFive),
    % Confirm the fifth instant.
    assertion(InstantFive == "2026-07-20T00:00:05Z").

% One recorded tick is a well-formed Causalontology token_occurrence.
test(record_tick_is_a_token_occurrence) :-
    % The fixed simulation start.
    observer_test_start(Start),
    % Record tick one.
    observer_record_tick(Start, 1, Record),
    % Its identifier carries the token_occurrence scheme prefix.
    get_dict(id, Record, Id),
    % Confirm the identifier prefix.
    assertion(sub_string(Id, 0, _, _, "token_occurrence:")),
    % Its type field says token_occurrence.
    assertion(get_dict(type, Record, "token_occurrence")),
    % It instantiates the tick occurrent type.
    get_dict(instantiates, Record, TickTypeId),
    % Confirm the instantiated type is an occurrent.
    assertion(sub_string(TickTypeId, 0, _, _, "occurrent:")),
    % Its interval starts at tick one's instant.
    get_dict(interval, Record, Interval),
    % Confirm the interval start.
    assertion(get_dict(start, Interval, "2026-07-20T00:00:01Z")).

% The same tick recorded twice yields the identical content-addressed record.
test(record_is_reproducible) :-
    % The fixed simulation start.
    observer_test_start(Start),
    % Record tick three once.
    observer_record_tick(Start, 3, RecordA),
    % Record tick three again.
    observer_record_tick(Start, 3, RecordB),
    % Read the content-addressed identifier of each record.
    get_dict(id, RecordA, IdA),
    get_dict(id, RecordB, IdB),
    % The identifiers are identical, which is exactly what content-addressing guarantees.
    assertion(IdA == IdB).

% Distinct ticks produce distinct content-addressed identifiers.
test(distinct_ticks_have_distinct_ids) :-
    % The fixed simulation start.
    observer_test_start(Start),
    % Record two different ticks.
    observer_record_tick(Start, 1, RecordOne),
    observer_record_tick(Start, 2, RecordTwo),
    % Read their identifiers.
    get_dict(id, RecordOne, IdOne),
    get_dict(id, RecordTwo, IdTwo),
    % The identifiers differ.
    assertion(IdOne \== IdTwo).

% A whole run of ticks is recorded as one token_occurrence each, all distinct.
test(record_ticks_maps_a_whole_run) :-
    % The fixed simulation start.
    observer_test_start(Start),
    % Record a three-tick run.
    observer_record_ticks(Start, [1, 2, 3], Records),
    % There are three records.
    length(Records, Count),
    % Confirm the count.
    assertion(Count =:= 3),
    % Collect the identifiers.
    findall(Id, (member(Record, Records), get_dict(id, Record, Id)), Ids),
    % Deduplicate them.
    sort(Ids, Unique),
    % All three are distinct.
    length(Unique, UniqueCount),
    % Confirm three distinct identifiers.
    assertion(UniqueCount =:= 3).

% Close the test block for the observer pack.
:- end_tests(observer).
