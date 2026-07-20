% Declare this file as the 'tick_engine' module and list the predicates it exports.
:- module(tick_engine, [
    % tick_engine_run/5: run the system for a chosen number of ticks, returning the final state and the observer trace.
    tick_engine_run/5,
    % tick_engine_step/3: perform exactly one tick as a two-pass synchronous update.
    tick_engine_step/3,
    % tick_engine_state_get/3: read one construct's current value out of a state.
    tick_engine_state_get/3,
    % tick_engine_trace_ticks/2: list, in order, the tick numbers the observer recorded.
    tick_engine_trace_ticks/2
]).

% Import the list utilities used for membership tests and reversing the trace.
:- use_module(library(lists), [member/2, memberchk/2, reverse/2]).

% A state is an ordered list of Name-Value pairs; this reads one construct's value from it.
% tick_engine_state_get(+State, +Name, -Value): unify Value with the current value of construct Name.
tick_engine_state_get(State, Name, Value) :-
    % Find the Name-Value pair in the state by a deterministic membership check.
    memberchk(Name-Value, State).

% There are three minimal update kinds for the heartbeat; the six manuscript archetypes arrive in a later slice.
% tick_engine_next_value(+Kind, +Name, +ReadState, -NextValue): compute one construct's next value from the read-only state.
% A clock construct advances by exactly one each tick, which is how the engine keeps time.
tick_engine_next_value(clock, Name, ReadState, NextValue) :-
    % Read this construct's own current value from the committed state.
    tick_engine_state_get(ReadState, Name, Current),
    % Add one to that current value to produce the next value.
    NextValue is Current + 1.
% A copy construct takes the CURRENT value of another named construct, never that construct's future.
tick_engine_next_value(copy(Other), _Name, ReadState, NextValue) :-
    % Read the other construct's current value from the committed state.
    tick_engine_state_get(ReadState, Other, NextValue).
% A hold construct keeps its own current value unchanged from one tick to the next.
tick_engine_next_value(hold, Name, ReadState, NextValue) :-
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
