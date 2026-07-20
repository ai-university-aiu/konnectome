% Declare this file as the 'connection_graph' module and list the predicates it exports.
:- module(connection_graph, [
    % connection_graph_incoming/3: the interfaces arriving at a destination construct.
    connection_graph_incoming/3,
    % connection_graph_total_input/4: the total weighted input arriving at a construct.
    connection_graph_total_input/4,
    % connection_graph_state_get/3: read one construct's current activation from a state.
    connection_graph_state_get/3,
    % connection_graph_step/4: one two-pass synchronous tick of a network over the graph.
    connection_graph_step/4,
    % connection_graph_run/6: run a network for a chosen number of ticks.
    connection_graph_run/6
]).

% Import list utilities for membership and reversing the trace.
:- use_module(library(lists), [memberchk/2, reverse/2]).
% Import the apply utilities for filtering interfaces and folding their contributions.
:- use_module(library(apply), [include/3, foldl/4]).
% Reuse the relay archetype rule; a transmissive interface conveys, scaled by gain.
:- use_module(library(archetype), [archetype_relay/3]).

% The connection graph is the connectome as data: a list of directed, weighted, delayed
% interfaces, each marked transmissive (it conveys a signal) or computational (it computes one).
% An interface is the term interface(From, To, Weight, Delay, Kind). This slice honours a delay of
% one tick, which is the natural delay of the two-pass synchronous update; longer delay lines are a
% later refinement. Only transmissive interfaces convey input here; computational interfaces are
% recorded in the data but contribute no gathered input yet.

% A state is an ordered list of Name-Value pairs; this reads one construct's activation from it.
% connection_graph_state_get(+State, +Name, -Value): unify Value with construct Name's activation.
connection_graph_state_get(State, Name, Value) :-
    % Find the Name-Value pair in the state by a deterministic membership check.
    memberchk(Name-Value, State).

% connection_graph_targets(+To, +Interface): the interface arrives at destination To.
connection_graph_targets(To, interface(_From, To, _Weight, _Delay, _Kind)).

% connection_graph_incoming(+Graph, +To, -Incoming): the interfaces arriving at To.
connection_graph_incoming(Graph, To, Incoming) :-
    % Keep only the interfaces whose destination is To.
    include(connection_graph_targets(To), Graph, Incoming).

% connection_graph_accumulate(+Activations, +Interface, +Acc0, -Acc): add one interface's contribution.
connection_graph_accumulate(Activations, interface(From, _To, Weight, _Delay, Kind), Acc0, Acc) :-
    % A transmissive interface conveys its source's activation, scaled by weight; others convey nothing yet.
    ( Kind == transmissive
      -> connection_graph_state_get(Activations, From, SourceActivation),
         Acc is Acc0 + Weight * SourceActivation
      ;  Acc = Acc0
    ).

% connection_graph_total_input(+Graph, +To, +Activations, -TotalInput): the weighted sum into To.
connection_graph_total_input(Graph, To, Activations, TotalInput) :-
    % Find the interfaces arriving at the destination.
    connection_graph_incoming(Graph, To, Incoming),
    % Sum each incoming interface's weighted contribution, starting from zero.
    foldl(connection_graph_accumulate(Activations), Incoming, 0, TotalInput).

% connection_graph_next(+Kind, +Name, +Graph, +State, -NextActivation): one construct's next activation.
% A source construct holds its current activation, representing a clamped sensory input.
connection_graph_next(source, Name, _Graph, State, NextActivation) :-
    % Read and keep the source's current activation.
    connection_graph_state_get(State, Name, NextActivation).
% A relay construct gathers its total weighted input and passes it, scaled by its gain.
connection_graph_next(relay(Gain), Name, Graph, State, NextActivation) :-
    % Gather the total weighted input arriving at this construct.
    connection_graph_total_input(Graph, Name, State, TotalInput),
    % Apply the relay archetype rule to that input.
    archetype_relay(TotalInput, Gain, NextActivation).

% connection_graph_step(+Graph, +Constructs, +State, -NextState): one two-pass synchronous tick.
connection_graph_step(Graph, Constructs, State, NextState) :-
    % First pass: compute every construct's next activation from the current state only.
    findall(Name-NextActivation,
            % For each construct in the network, taken in turn.
            ( member(construct(Name, Kind), Constructs),
              % Compute its next activation from the read-only state and the graph.
              connection_graph_next(Kind, Name, Graph, State, NextActivation) ),
            NextPairs),
    % Second pass: commit all next activations at once into a canonical state.
    keysort(NextPairs, NextState).

% connection_graph_run(+Graph, +Constructs, +InitialState, +NumTicks, -FinalState, -Trace): run the network.
connection_graph_run(Graph, Constructs, InitialState, NumTicks, FinalState, Trace) :-
    % Refuse a negative tick count; time never runs backward.
    NumTicks >= 0,
    % Put the initial state into canonical sorted order.
    keysort(InitialState, StartState),
    % Drive the loop from tick zero with an empty trace accumulator.
    connection_graph_loop(0, NumTicks, Graph, Constructs, StartState, [], ReverseTrace, FinalState),
    % Reverse the accumulated trace so the earliest tick comes first.
    reverse(ReverseTrace, Trace).

% connection_graph_loop(+Tick, +NumTicks, +Graph, +Constructs, +State, +Acc, -Trace, -Final): the loop.
% Base case: stop once the requested number of ticks has been reached.
connection_graph_loop(Tick, NumTicks, _Graph, _Constructs, State, Acc, Acc, State) :-
    % Stop when the tick counter has reached or passed the requested count.
    Tick >= NumTicks,
    % Commit to the base case.
    !.
% Recursive case: advance one synchronous tick and record it.
connection_graph_loop(Tick, NumTicks, Graph, Constructs, State, Acc, Trace, Final) :-
    % Continue only while ticks remain.
    Tick < NumTicks,
    % Perform one two-pass synchronous network step.
    connection_graph_step(Graph, Constructs, State, NextState),
    % Increment the tick counter.
    NextTick is Tick + 1,
    % Record this tick's full network snapshot and continue.
    connection_graph_loop(NextTick, NumTicks, Graph, Constructs, NextState,
                          [tick_record(NextTick, NextState)|Acc], Trace, Final).
