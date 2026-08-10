% Load the tick_engine module under test from the library path.
:- use_module(library(tick_engine)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).
% Load the mode register, because every construct now answers through one.
:- use_module(library(mode_register)).

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

% SLICE 39: every construct the heartbeat runs answers through its own mode register, and today
% every one of those registers holds exactly one mode - a register of one, stated proudly.
test(every_heartbeat_construct_kind_is_a_register_of_one) :-
    % The three construct kinds the heartbeat knows.
    Kinds = [clock, copy(other), hold],
    % Each has a register of one whose current mode names the construct's own rule.
    forall(member(Kind, Kinds),
           % The register exists, holds one mode, and files this very kind as that mode's rule.
           ( mode_register_of_construct_kind(Kind, Automaton),
             mode_register_size(Automaton, 1),
             mode_register_current_rule(Automaton, Kind) )).

% SLICE 43: THE TICKS-PER-SECOND CONVENTION, DECISION-2. These tests assert the decision, which is
% what a recorded decision is entitled to: a mechanism answers a question, a decision closes one.

% The convention is declared, it is one hundred ticks to the nominal second, and it lives in one place.
test(the_convention_is_one_hundred_ticks_to_the_second) :-
    % Read the convention out of its single home.
    tick_engine_ticks_per_second(TicksPerSecond),
    % konnectome calls one hundred ticks one second, so one tick is ten nominal milliseconds.
    assertion(TicksPerSecond == 100).

% THE REASON THE RATE IS THIS RATE: every corpus constant in the cognitive cluster lands on a whole
% tick, so no slice built to those constants has to round, and rounding is where invented numbers enter.
test(every_corpus_wall_clock_constant_is_a_whole_number_of_ticks) :-
    % The corpus's own quantities, each paired with the tick count this convention gives it.
    Constants = [300-30, 100-10, 1000-100, 500-50, 2000-200],
    % Each converts exactly, and the conversion is the one the whole build must use.
    forall(member(Milliseconds-ExpectedTicks, Constants),
           % Convert the wall-clock duration and check it against the expected whole tick count.
           ( tick_engine_ticks_from_milliseconds(Milliseconds, Ticks),
             Ticks == ExpectedTicks )).

% A duration that does not land on a tick boundary is REFUSED ALOUD and never silently rounded.
test(a_duration_between_two_ticks_is_refused_rather_than_rounded) :-
    % Five milliseconds is half a tick under this convention, so it has no whole-tick answer.
    catch(tick_engine_ticks_from_milliseconds(5, _Ticks), Error, true),
    % The refusal names the offending duration rather than guessing a tick count for it.
    assertion(Error = error(domain_error(whole_tick_duration, 5), _)).

% THE UNBOUND-WRONG-JUDGEMENT LENS: an unbound duration would invent both a duration and a tick count.
test(an_unbound_duration_is_refused_at_the_conversion) :-
    % Ask for the tick count of a duration nobody supplied.
    catch(tick_engine_ticks_from_milliseconds(_Unbound, _Ticks), Error, true),
    % It is refused as an instantiation fault rather than answered.
    assertion(Error = error(instantiation_error, _)).

% An unbound tick count is refused in the reading-back direction for exactly the same reason.
test(an_unbound_tick_count_is_refused_at_the_inverse) :-
    % Ask for the duration of a tick count nobody supplied.
    catch(tick_engine_milliseconds_from_ticks(_Unbound, _Milliseconds), Error, true),
    % It is refused rather than answered.
    assertion(Error = error(instantiation_error, _)).

% The two directions are exact inverses, which is what makes a tick count readable back as a duration.
test(the_conversion_round_trips_exactly) :-
    % Take a corpus-shaped duration in whole ticks.
    tick_engine_ticks_from_milliseconds(300, Ticks),
    % Read it back as a duration.
    tick_engine_milliseconds_from_ticks(Ticks, Milliseconds),
    % The duration that comes back is the duration that went in.
    assertion(Milliseconds == 300).

% WHAT DECISION-2 DOES NOT DO, pinned so a later reader cannot assume it did: THE SCHEDULER IS
% UNCHANGED. The convention is a conversion for stating durations, not a clock the engine consults.
test(the_convention_does_not_move_the_scheduler_by_a_single_count) :-
    % Run the heartbeat exactly as every earlier slice ran it.
    tick_engine_run([construct(clock, clock)], [clock-0], 5, Final, Trace),
    % The clock still counts ticks and not milliseconds: five ticks reads five, not five hundred.
    assertion(Final == [clock-5]),
    % Project the trace down to its tick numbers.
    tick_engine_trace_ticks(Trace, Numbers),
    % The tick numbers are still ordinals, untouched by the convention.
    assertion(Numbers == [1,2,3,4,5]).

% Close the test block for the tick_engine pack.
:- end_tests(tick_engine).
