% Declare this file as the 'tick_engine' module and list the predicates it exports.
:- module(tick_engine, [
    % tick_engine_run/5: run the system for a chosen number of ticks, returning the final state and the observer trace.
    tick_engine_run/5,
    % tick_engine_step/3: perform exactly one tick as a two-pass synchronous update.
    tick_engine_step/3,
    % tick_engine_state_get/3: read one construct's current value out of a state.
    tick_engine_state_get/3,
    % tick_engine_trace_ticks/2: list, in order, the tick numbers the observer recorded.
    tick_engine_trace_ticks/2,
    % tick_engine_ticks_per_second/1: THE CONVENTION - how many ticks konnectome calls one second.
    tick_engine_ticks_per_second/1,
    % tick_engine_ticks_from_milliseconds/2: the sole conversion from a wall-clock quantity into ticks.
    tick_engine_ticks_from_milliseconds/2,
    % tick_engine_milliseconds_from_ticks/2: the exact inverse, for reading a tick count back as a duration.
    tick_engine_milliseconds_from_ticks/2
]).

% Import the list utilities used for membership tests and reversing the trace.
:- use_module(library(lists), [member/2, memberchk/2, reverse/2]).
% Import the type checker that refuses a hole or a wrong shape aloud, used by the two conversions.
:- use_module(library(error), [must_be/2, domain_error/2]).
% Read every construct's rule through its own mode register; a construct IS its register's current mode.
:- use_module(library(mode_register), [mode_register_construct_rule/2]).

% A state is an ordered list of Name-Value pairs; this reads one construct's value from it.
% tick_engine_state_get(+State, +Name, -Value): unify Value with the current value of construct Name.
tick_engine_state_get(State, Name, Value) :-
    % Find the Name-Value pair in the state by a deterministic membership check.
    memberchk(Name-Value, State).

% There are three minimal update kinds for the heartbeat; the six manuscript archetypes arrive in a later slice.
% EVERY CONSTRUCT NOW ANSWERS THROUGH ITS OWN MODE REGISTER. A construct kind is no longer a rule
% the engine dispatches on directly; it is a HYBRID AUTOMATON whose register names the mode the
% construct is in, and whose per-mode transfer function is the rule that holds while that mode holds.
% Today every register holds exactly one mode - a register of one, stated proudly - so the rule read
% back out is the rule that went in, and the heartbeat does not change by a single count.
% tick_engine_next_value(+Kind, +Name, +ReadState, -NextValue): read the register, then apply the rule.
tick_engine_next_value(Kind, Name, ReadState, NextValue) :-
    % Read the rule that holds under this construct's current mode.
    mode_register_construct_rule(Kind, Rule),
    % Apply that rule to the read-only state.
    tick_engine_apply(Rule, Name, ReadState, NextValue).

% tick_engine_apply(+Rule, +Name, +ReadState, -NextValue): compute one construct's next value from the read-only state.
% A clock construct advances by exactly one each tick, which is how the engine keeps time.
tick_engine_apply(clock, Name, ReadState, NextValue) :-
    % Read this construct's own current value from the committed state.
    tick_engine_state_get(ReadState, Name, Current),
    % Add one to that current value to produce the next value.
    NextValue is Current + 1.
% A copy construct takes the CURRENT value of another named construct, never that construct's future.
tick_engine_apply(copy(Other), _Name, ReadState, NextValue) :-
    % Read the other construct's current value from the committed state.
    tick_engine_state_get(ReadState, Other, NextValue).
% A hold construct keeps its own current value unchanged from one tick to the next.
tick_engine_apply(hold, Name, ReadState, NextValue) :-
    % Read this construct's current value, which becomes its unchanged next value.
    tick_engine_state_get(ReadState, Name, NextValue).

% The FIRST PASS computes every next value while reading only the committed current state.
% tick_engine_compute_all(+Constructs, +ReadState, -NextPairs): first pass — gather every Name-NextValue pair.
tick_engine_compute_all(Constructs, ReadState, NextPairs) :-
    % Collect one Name-NextValue pair for each construct, preserving registry order.
    findall(Name-NextValue,
            % For each construct in the registry, taken in turn.
            ( member(construct(Name, Kind), Constructs),
              % Compute that construct's next value from the read-only state.
              tick_engine_next_value(Kind, Name, ReadState, NextValue) ),
            NextPairs).

% The SECOND PASS commits every computed next value at once into a fresh, canonical state.
% tick_engine_commit(+NextPairs, -NextState): second pass — sort the pairs into a canonical committed state.
tick_engine_commit(NextPairs, NextState) :-
    % Sort the pairs by construct name so the state is canonical and reproducible.
    keysort(NextPairs, NextState).

% One tick is the two passes run strictly in order, which is what makes the update synchronous.
% tick_engine_step(+Constructs, +State, -NextState): advance the whole system by exactly one tick.
tick_engine_step(Constructs, State, NextState) :-
    % First pass: compute every construct's next value from the current state only.
    tick_engine_compute_all(Constructs, State, NextPairs),
    % Second pass: commit all next values together, so no construct ever saw a neighbour's future.
    tick_engine_commit(NextPairs, NextState).

% Running the system means stepping it a fixed number of ticks and recording each tick.
% tick_engine_run(+Constructs, +InitialState, +NumTicks, -FinalState, -Trace): run for NumTicks ticks.
tick_engine_run(Constructs, InitialState, NumTicks, FinalState, Trace) :-
    % Refuse a negative tick count; time never runs backward.
    NumTicks >= 0,
    % Put the initial state into canonical sorted order before the first tick.
    keysort(InitialState, StartState),
    % Drive the loop from tick zero with an empty trace accumulator.
    tick_engine_loop(0, NumTicks, Constructs, StartState, [], ReverseTrace, FinalState),
    % Reverse the accumulated trace so the earliest tick comes first.
    reverse(ReverseTrace, Trace).

% The loop base case stops once the requested number of ticks has been reached.
% tick_engine_loop(+Tick, +NumTicks, +Constructs, +State, +TraceAcc, -TraceOut, -FinalState): the tick loop.
tick_engine_loop(Tick, NumTicks, _Constructs, State, TraceAcc, TraceAcc, State) :-
    % Stop when the tick counter has reached or passed the requested number of ticks.
    Tick >= NumTicks,
    % Commit to this base case so the recursive clause is not also tried.
    !.
% The loop recursive case advances one tick, records it, and continues.
tick_engine_loop(Tick, NumTicks, Constructs, State, TraceAcc, TraceOut, FinalState) :-
    % Continue only while the tick counter is still below the requested number of ticks.
    Tick < NumTicks,
    % Perform one two-pass synchronous update to get the next state.
    tick_engine_step(Constructs, State, NextState),
    % Increment the tick counter by one.
    NextTick is Tick + 1,
    % The passive observer records this tick as a full snapshot of the new state.
    Record = tick_record(NextTick, NextState),
    % Continue the loop from the next tick with the record prepended to the accumulator.
    tick_engine_loop(NextTick, NumTicks, Constructs, NextState, [Record|TraceAcc], TraceOut, FinalState).

% The observer's trace can be projected down to just its ordered tick numbers.
% tick_engine_trace_ticks(+Trace, -TickNumbers): list the recorded tick numbers in order.
tick_engine_trace_ticks(Trace, TickNumbers) :-
    % Collect the tick number from each recorded snapshot, in trace order.
    findall(Number, member(tick_record(Number, _Snapshot), Trace), TickNumbers).

% ---------------------------------------------------------------------------
% THE TICKS-PER-SECOND CONVENTION (konnectome build slice 43, DECISION-2)
% ---------------------------------------------------------------------------
%
% KONNECTOME HAS NO SECONDS AND THE CORPUS COUNTS IN THEM. Every quantity in the cognitive cluster
% the corpus specifies is WALL-CLOCK - ignition near three hundred milliseconds, admission in the low
% hundreds, unrehearsed decay in seconds, a board wiped on task switch in under a second - and a
% settling time read as confidence is wall-clock too. konnectome's tick, by contrast, is
% DIMENSIONLESS-ORDINAL: it is the count of two-pass synchronous updates this engine has performed,
% and nothing in this pack sleeps, measures, or consults a real clock. Until a conversion is written
% down, NONE of those corpus constants can be built to WITHOUT SOMEBODY INVENTING A NUMBER, which is
% the one thing this build has refused to do since slice 39.
%
% THE CONVENTION IS KONNECTOME'S OWN DECISION AND MUST NEVER BE PRESENTED AS THE CORPUS'S. The corpus
% supplies durations; it says nothing whatever about how often a synthetic mind should update. The
% choice below is therefore recorded in the ledger as DECISION-2, with its reasons and with the list
% of what it does NOT decide, in the shape DECISION-1 established.
%
% WHAT IS DECLARED: ONE HUNDRED TICKS TO THE NOMINAL SECOND, so one tick is ten nominal milliseconds.
%
% THE THREE REASONS, ALL KONNECTOME'S OWN. FIRST, IT MAKES EVERY CORPUS CONSTANT A WHOLE NUMBER OF
% TICKS: three hundred milliseconds is thirty ticks exactly, one hundred is ten, one second is a
% hundred. A rate that left a corpus constant sitting between two ticks would force a rounding, and a
% rounding is an invented number wearing a small coat. SECOND, IT IS THE COARSEST RATE THAT DOES SO,
% and coarsest is the honest choice: the corpus states these quantities to a hundred-millisecond
% grain, so a finer tick would claim a precision the source does not have. THIRD, IT COSTS THE
% RUNNING MACHINE NOTHING AND IS THEREFORE REVERSIBLE: the scheduler stays dimensionless, no existing
% behaviour moves by a single count, and every duration in konnectome that is ever expressed in real
% units passes through the ONE conversion below - so a later session that must restate the rate has
% exactly one predicate to change and one test to re-read.
%
% A DURATION THAT IS NOT A WHOLE NUMBER OF TICKS IS REFUSED ALOUD RATHER THAN ROUNDED. That refusal
% is the load-bearing half of this slice. Rounding is where invented numbers enter a build silently:
% a caller asks for five milliseconds, receives "one tick" without being told, and a constant that
% was the corpus's has quietly become konnectome's. domain_error(whole_tick_duration, Milliseconds)
% says so instead, and the caller must then decide in the open.

% tick_engine_ticks_per_second(-TicksPerSecond): THE CONVENTION, stated once and read everywhere.
tick_engine_ticks_per_second(100).

% tick_engine_ticks_from_milliseconds(+Milliseconds, -Ticks): convert a wall-clock duration to ticks.
tick_engine_ticks_from_milliseconds(Milliseconds, Ticks) :-
    % Refuse an unbound duration aloud; a hole here would invent a duration and a tick count with it.
    must_be(nonneg, Milliseconds),
    % Read the convention rather than restating the number, so there is exactly one place it lives.
    tick_engine_ticks_per_second(TicksPerSecond),
    % A duration in milliseconds is that many thousandths of a second, so scale before dividing.
    Scaled is Milliseconds * TicksPerSecond,
    % A duration that does not land exactly on a tick boundary is refused rather than rounded.
    (   Scaled mod 1000 =:= 0
    ->  % It lands exactly, so the whole number of ticks is the scaled value over a thousand.
        Ticks is Scaled // 1000
    ;   % It does not land, and the refusal names the offending duration rather than guessing for it.
        domain_error(whole_tick_duration, Milliseconds)
    ).

% tick_engine_milliseconds_from_ticks(+Ticks, -Milliseconds): read a tick count back as a duration.
tick_engine_milliseconds_from_ticks(Ticks, Milliseconds) :-
    % Refuse an unbound tick count aloud, for the same reason the forward direction does.
    must_be(nonneg, Ticks),
    % Read the convention from its one home.
    tick_engine_ticks_per_second(TicksPerSecond),
    % Every tick count is exactly expressible as a duration, so this direction never refuses.
    Milliseconds is Ticks * 1000 // TicksPerSecond.
