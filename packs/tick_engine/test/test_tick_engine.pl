% Load the tick_engine module under test from the library path.
:- use_module(library(tick_engine)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% Open the test block for the tick_engine pack.
:- begin_tests(tick_engine).

% A run of zero ticks changes nothing and records no ticks.
test(zero_ticks_is_identity) :-
    % Run a single clock construct for zero ticks.
    tick_engine_run([construct(clock, clock)], [clock-0], 0, Final, Trace),
    % The final state equals the initial state exactly.
    assertion(Final == [clock-0]),
    % The observer recorded no ticks at all.
    assertion(Trace == []).

% A clock construct advances by exactly one each tick, so after five ticks it reads five: it keeps time.
test(clock_keeps_time) :-
    % Run a clock construct for five ticks starting from zero.
    tick_engine_run([construct(clock, clock)], [clock-0], 5, Final, _Trace),
    % After five ticks the clock reads exactly five.
    assertion(Final == [clock-5]).

% The observer records exactly one numbered snapshot per tick, one through N, in order.
test(observer_records_each_tick_once_in_order) :-
    % Run a clock construct for four ticks.
    tick_engine_run([construct(clock, clock)], [clock-0], 4, _Final, Trace),
    % Project the trace down to its tick numbers.
    tick_engine_trace_ticks(Trace, Numbers),
    % The recorded tick numbers are exactly one through four in order.
    assertion(Numbers == [1,2,3,4]).

% The two passes never interleave: a follower that copies a clock sees the clock's past, never its future.
test(no_construct_reads_a_neighbours_future) :-
    % Build a clock and a follower that copies the clock's current value each tick.
    Constructs = [construct(clock, clock), construct(follower, copy(clock))],
    % Run both from zero for three ticks.
    tick_engine_run(Constructs, [clock-0, follower-0], 3, Final, _Trace),
    % After three ticks the clock reads three.
    assertion(tick_engine_state_get(Final, clock, 3)),
    % The follower reads two, lagging by exactly one, which proves it saw the clock's past, not its future.
    assertion(tick_engine_state_get(Final, follower, 2)).

% Snapshot by snapshot, the follower holds the clock's value from the START of each tick, confirming synchrony.
test(synchronous_update_lags_by_one_each_tick) :-
    % Build the same clock-and-follower pair.
    Constructs = [construct(clock, clock), construct(follower, copy(clock))],
    % Run for two ticks and capture the observer trace.
    tick_engine_run(Constructs, [clock-0, follower-0], 2, _Final, Trace),
    % Bind the two recorded snapshots directly, outside any assertion, so their states are usable.
    Trace = [tick_record(1, FirstSnapshot), tick_record(2, SecondSnapshot)],
    % In tick one the follower still holds the clock's starting value, zero.
    assertion(tick_engine_state_get(FirstSnapshot, follower, 0)),
    % In tick one the clock has advanced to one.
    assertion(tick_engine_state_get(FirstSnapshot, clock, 1)),
    % In tick two the follower holds the clock's value from the end of tick one, which was one.
    assertion(tick_engine_state_get(SecondSnapshot, follower, 1)),
    % In tick two the clock has advanced to two.
    assertion(tick_engine_state_get(SecondSnapshot, clock, 2)).

% The run is reproducible: identical inputs yield an identical final state and an identical trace.
test(run_is_reproducible) :-
    % Build a clock-and-follower pair.
    Constructs = [construct(clock, clock), construct(follower, copy(clock))],
    % Run it once for six ticks.
    tick_engine_run(Constructs, [clock-0, follower-0], 6, FinalA, TraceA),
    % Run it again with exactly the same inputs.
    tick_engine_run(Constructs, [clock-0, follower-0], 6, FinalB, TraceB),
    % The two final states are identical.
    assertion(FinalA == FinalB),
    % The two traces are identical.
    assertion(TraceA == TraceB).

% A hold construct keeps its value unchanged across many ticks.
test(hold_construct_is_constant) :-
    % Run a single hold construct for ten ticks starting from the value seven.
    tick_engine_run([construct(memory, hold)], [memory-7], 10, Final, _Trace),
    % After ten ticks the held value is still seven.
    assertion(Final == [memory-7]).

% Close the test block for the tick_engine pack.
:- end_tests(tick_engine).
