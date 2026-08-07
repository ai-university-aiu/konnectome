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
    % connection_graph_step_modulated/5: a tick whose relay gains are set by the neuromodulatory bus.
    connection_graph_step_modulated/5,
    % connection_graph_run/6: run a network for a chosen number of ticks.
    connection_graph_run/6,
    % connection_graph_delay_lines_new/2: build the empty delay lines for a graph.
    connection_graph_delay_lines_new/2,
    % connection_graph_step_delayed/5: one synchronous tick that honours multi-tick delays.
    connection_graph_step_delayed/5,
    % connection_graph_run_delayed/6: run a delay-honouring network for a chosen number of ticks.
    connection_graph_run_delayed/6,
    % connection_graph_step_delayed_modulated/6: a delayed tick whose relay gains the bus sets per territory.
    connection_graph_step_delayed_modulated/6
]).

% Import list utilities for membership and reversing the trace.
:- use_module(library(lists), [memberchk/2, reverse/2]).
% Import the apply utilities for filtering interfaces, folding contributions, and checking delays.
:- use_module(library(apply), [include/3, foldl/4, maplist/2]).
% Reuse the relay archetype rule; a transmissive interface conveys, scaled by gain.
:- use_module(library(archetype), [archetype_relay/3]).
% Reuse the neuromodulatory bus to read the gain a modulator sets for a construct's own territory.
:- use_module(library(neuromodulator_bus), [neuromodulator_bus_level_territory/4]).

% The connection graph is the connectome as data: a list of directed, weighted, delayed
% interfaces, each marked transmissive (it conveys a signal) or computational (it computes one).
% An interface is the term interface(From, To, Weight, Delay, Kind). The plain step honours a delay
% of one tick, which is the natural delay of the two-pass synchronous update; the delayed step and
% run below honour the full multi-tick Delay field through per-interface delay lines. Only
% transmissive interfaces convey input in either path; computational interfaces are recorded in the
% data but contribute no gathered input yet.

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

% A construct of a kind the plain step does not know is refused aloud, never silently dropped.
connection_graph_next(Kind, _Name, _Graph, _State, _NextActivation) :-
    % Only a clamped source and a fixed-gain relay belong to the plain step.
    Kind \== source,
    % A relay with any gain also belongs to the plain step.
    Kind \= relay(_),
    % Refuse the unknown kind by name, so the state can never shrink in silence.
    throw(error(domain_error(plain_step_construct_kind, Kind), _)).

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

% connection_graph_next_modulated(+Kind, +Name, +Graph, +State, +Bus, -NextActivation): a bus-aware update.
% A source construct still holds its current activation.
connection_graph_next_modulated(source, Name, _Graph, State, _Bus, NextActivation) :-
    % Read and keep the source's current activation.
    connection_graph_state_get(State, Name, NextActivation).
% A relay with a fixed gain behaves as before, ignoring the bus.
connection_graph_next_modulated(relay(Gain), Name, Graph, State, _Bus, NextActivation) :-
    % Gather the total weighted input and pass it, scaled by the fixed gain.
    connection_graph_total_input(Graph, Name, State, TotalInput),
    % Apply the relay archetype rule.
    archetype_relay(TotalInput, Gain, NextActivation).
% A modulated relay's effective gain is its base gain scaled by a modulator's level on the bus.
connection_graph_next_modulated(relay_modulated(BaseGain, Modulator), Name, Graph, State, Bus, NextActivation) :-
    % Gather the total weighted input arriving at this construct.
    connection_graph_total_input(Graph, Name, State, TotalInput),
    % Read the modulator's level in this construct's OWN territory; an unset territory reads the diffuse field.
    neuromodulator_bus_level_territory(Bus, Modulator, Name, Level),
    % The effective gain is the base gain scaled by that level.
    EffectiveGain is BaseGain * Level,
    % Apply the relay archetype rule with the current, bus-set gain.
    archetype_relay(TotalInput, EffectiveGain, NextActivation).

% A construct of a kind the modulated step does not know is refused aloud, never silently dropped.
connection_graph_next_modulated(Kind, _Name, _Graph, _State, _Bus, _NextActivation) :-
    % Only a clamped source belongs to the modulated step among the plain kinds.
    Kind \== source,
    % A relay with any fixed gain also belongs.
    Kind \= relay(_),
    % A relay whose gain the bus sets also belongs.
    Kind \= relay_modulated(_, _),
    % Refuse the unknown kind by name, so the state can never shrink in silence.
    throw(error(domain_error(modulated_step_construct_kind, Kind), _)).

% connection_graph_step_modulated(+Graph, +Constructs, +State, +Bus, -NextState): a bus-modulated tick.
connection_graph_step_modulated(Graph, Constructs, State, Bus, NextState) :-
    % First pass: compute every construct's next activation, letting the bus set relay gains.
    findall(Name-NextActivation,
            % For each construct in the network, taken in turn.
            ( member(construct(Name, Kind), Constructs),
              % Compute its next activation from the read-only state, the graph, and the bus.
              connection_graph_next_modulated(Kind, Name, Graph, State, Bus, NextActivation) ),
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

% A DELAY LINE is a per-interface first-in-first-out buffer holding the values still in transit
% along that interface. For an interface with a delay of D ticks the buffer holds D minus one
% values, because the final hop is delivered by the synchronous step itself; with a one-tick delay
% the buffer is empty and the delayed step reproduces the plain step exactly. Each tick, the value
% the source emits enters the back of the buffer and the value at the front is delivered, so a
% signal arrives after exactly the number of ticks the interface's delay dictates, and nowhere
% sooner. A delay line is the term delay_line(From, To, Weight, Buffer).

% connection_graph_zeros(+Count, -Zeros): a list of Count zeros, the silence seeding a new line.
% Base case: zero zeros is the empty list.
connection_graph_zeros(0, []) :-
    % Commit to the base case.
    !.
% Recursive case: one zero, then the rest.
connection_graph_zeros(Count, [0|Rest]) :-
    % Continue only while zeros remain to be laid down.
    Count > 0,
    % Count down by one.
    Next is Count - 1,
    % Lay down the remaining zeros.
    connection_graph_zeros(Next, Rest).

% connection_graph_check_delay(+Interface): refuse an interface whose delay is impossible.
connection_graph_check_delay(interface(_From, _To, _Weight, Delay, _Kind)) :-
    % A signal never arrives before it is sent: refuse a delay below one tick.
    (   integer(Delay), Delay >= 1
    ->  true
    ;   throw(error(domain_error(delay_of_at_least_one_tick, Delay), _))
    ).

% connection_graph_delay_line(+Interface, -Line): build one interface's empty delay line.
connection_graph_delay_line(interface(From, To, Weight, Delay, _Kind),
                            delay_line(From, To, Weight, Buffer)) :-
    % The buffer carries the in-transit values: the delay minus the synchronous final hop.
    BufferLength is Delay - 1,
    % Seed the line with silence.
    connection_graph_zeros(BufferLength, Buffer).

% connection_graph_transmissive(+Interface): the interface is transmissive.
connection_graph_transmissive(interface(_From, _To, _Weight, _Delay, transmissive)).

% connection_graph_delay_lines_new(+Graph, -Lines): the empty delay lines for a whole graph.
connection_graph_delay_lines_new(Graph, Lines) :-
    % Every interface's delay is checked, computational ones included; a bad delay is a bad
    % graph, whether or not the interface carries a line.
    maplist(connection_graph_check_delay, Graph),
    % Only transmissive interfaces convey signals, so only they carry delay lines.
    include(connection_graph_transmissive, Graph, Transmissive),
    % Build one silence-seeded line per transmissive interface.
    findall(Line,
            % For each transmissive interface, taken in turn.
            ( member(Interface, Transmissive),
              % Build its empty delay line.
              connection_graph_delay_line(Interface, Line) ),
            Lines).

% connection_graph_advance_line(+State, +Line, -Delivery, -NextLine): move one line one tick.
connection_graph_advance_line(State, delay_line(From, To, Weight, Buffer),
                              delivery(To, Weight, Delivered),
                              delay_line(From, To, Weight, NextBuffer)) :-
    % The value the source emits this tick is its current activation; a missing source is
    % refused aloud, so a delay line and its in-transit values can never vanish in silence.
    (   connection_graph_state_get(State, From, Emitted)
    ->  true
    ;   throw(error(existence_error(construct_activation, From), _))
    ),
    % The emitted value joins the back of the queue of values in transit.
    append(Buffer, [Emitted], Queue),
    % The value at the front of the queue is delivered this tick; the rest stay in transit.
    Queue = [Delivered|NextBuffer].

% connection_graph_delivery_targets(+To, +Delivery): the delivery arrives at destination To.
connection_graph_delivery_targets(To, delivery(To, _Weight, _Delivered)).

% connection_graph_accumulate_delivery(+Delivery, +Acc0, -Acc): add one delivery's contribution.
connection_graph_accumulate_delivery(delivery(_To, Weight, Delivered), Acc0, Acc) :-
    % The delivered value arrives scaled by the interface's weight.
    Acc is Acc0 + Weight * Delivered.

% connection_graph_total_delivered(+Deliveries, +To, -TotalInput): the weighted sum delivered to To.
connection_graph_total_delivered(Deliveries, To, TotalInput) :-
    % Keep only the deliveries arriving at the destination.
    include(connection_graph_delivery_targets(To), Deliveries, Arriving),
    % Sum each arriving delivery's weighted contribution, starting from zero.
    foldl(connection_graph_accumulate_delivery, Arriving, 0, TotalInput).

% connection_graph_next_delayed(+Kind, +Name, +Deliveries, +State, -NextActivation): a delayed update.
% A source construct holds its current activation, representing a clamped sensory input.
connection_graph_next_delayed(source, Name, _Deliveries, State, NextActivation) :-
    % Read and keep the source's current activation.
    connection_graph_state_get(State, Name, NextActivation).
% A relay construct gathers its total delivered input and passes it, scaled by its gain.
connection_graph_next_delayed(relay(Gain), Name, Deliveries, _State, NextActivation) :-
    % Gather the total weighted input delivered to this construct this tick.
    connection_graph_total_delivered(Deliveries, Name, TotalInput),
    % Apply the relay archetype rule to that input.
    archetype_relay(TotalInput, Gain, NextActivation).

% A construct of a kind the delayed step does not know is refused aloud, never silently dropped.
connection_graph_next_delayed(Kind, _Name, _Deliveries, _State, _NextActivation) :-
    % Only a clamped source belongs to the delayed step among the known kinds.
    Kind \== source,
    % A relay with any fixed gain also belongs.
    Kind \= relay(_),
    % Refuse the unknown kind by name, so the state can never shrink in silence.
    throw(error(domain_error(delayed_step_construct_kind, Kind), _)).

% connection_graph_step_delayed(+Constructs, +State, +Lines, -NextState, -NextLines): one delayed tick.
connection_graph_step_delayed(Constructs, State, Lines, NextState, NextLines) :-
    % First pass, part one: advance every delay line one tick from the current state only.
    findall(Delivery-NextLine,
            % For each delay line, taken in turn.
            ( member(Line, Lines),
              % Take in the source's emission and give out the value whose time has come.
              connection_graph_advance_line(State, Line, Delivery, NextLine) ),
            Advanced),
    % Split the advanced pairs into this tick's deliveries and the lines' next buffers.
    findall(Delivery, member(Delivery-_, Advanced), Deliveries),
    findall(NextLine, member(_-NextLine, Advanced), NextLines),
    % First pass, part two: compute every construct's next activation from the deliveries.
    findall(Name-NextActivation,
            % For each construct in the network, taken in turn.
            ( member(construct(Name, Kind), Constructs),
              % Compute its next activation from the read-only state and the deliveries.
              connection_graph_next_delayed(Kind, Name, Deliveries, State, NextActivation) ),
            NextPairs),
    % Second pass: commit all next activations at once into a canonical state.
    keysort(NextPairs, NextState).

% connection_graph_run_delayed(+Graph, +Constructs, +InitialState, +NumTicks, -FinalState, -Trace).
connection_graph_run_delayed(Graph, Constructs, InitialState, NumTicks, FinalState, Trace) :-
    % Refuse a negative tick count; time never runs backward.
    NumTicks >= 0,
    % Build the empty, silence-seeded delay lines for the graph.
    connection_graph_delay_lines_new(Graph, Lines),
    % Put the initial state into canonical sorted order.
    keysort(InitialState, StartState),
    % Drive the loop from tick zero with an empty trace accumulator.
    connection_graph_loop_delayed(0, NumTicks, Constructs, StartState, Lines,
                                  [], ReverseTrace, FinalState),
    % Reverse the accumulated trace so the earliest tick comes first.
    reverse(ReverseTrace, Trace).

% connection_graph_loop_delayed(+Tick, +NumTicks, +Constructs, +State, +Lines, +Acc, -Trace, -Final).
% Base case: stop once the requested number of ticks has been reached.
connection_graph_loop_delayed(Tick, NumTicks, _Constructs, State, _Lines, Acc, Acc, State) :-
    % Stop when the tick counter has reached or passed the requested count.
    Tick >= NumTicks,
    % Commit to the base case.
    !.
% Recursive case: advance one delayed synchronous tick and record it.
connection_graph_loop_delayed(Tick, NumTicks, Constructs, State, Lines, Acc, Trace, Final) :-
    % Continue only while ticks remain.
    Tick < NumTicks,
    % Perform one delay-honouring synchronous network step.
    connection_graph_step_delayed(Constructs, State, Lines, NextState, NextLines),
    % Increment the tick counter.
    NextTick is Tick + 1,
    % Record this tick's full network snapshot and continue.
    connection_graph_loop_delayed(NextTick, NumTicks, Constructs, NextState, NextLines,
                                  [tick_record(NextTick, NextState)|Acc], Trace, Final).

% connection_graph_next_delayed_modulated(+Kind, +Name, +Deliveries, +State, +Bus, -Next): delayed, bus-aware.
% A source construct holds its current activation, representing a clamped sensory input.
connection_graph_next_delayed_modulated(source, Name, _Deliveries, State, _Bus, NextActivation) :-
    % Read and keep the source's current activation.
    connection_graph_state_get(State, Name, NextActivation).
% A relay with a fixed gain gathers its delivered input and ignores the bus, as ever.
connection_graph_next_delayed_modulated(relay(Gain), Name, Deliveries, _State, _Bus, NextActivation) :-
    % Gather the total weighted input delivered to this construct this tick.
    connection_graph_total_delivered(Deliveries, Name, TotalInput),
    % Apply the relay archetype rule to that input.
    archetype_relay(TotalInput, Gain, NextActivation).
% A modulated relay's gain is set, at the tick of delivery, by its own territory's modulator level.
connection_graph_next_delayed_modulated(relay_modulated(BaseGain, Modulator), Name, Deliveries, _State, Bus, NextActivation) :-
    % Gather the total weighted input delivered to this construct this tick.
    connection_graph_total_delivered(Deliveries, Name, TotalInput),
    % Read the modulator's level in this construct's OWN territory; an unset territory reads the diffuse field.
    neuromodulator_bus_level_territory(Bus, Modulator, Name, Level),
    % The effective gain is the base gain scaled by that level, read at delivery time.
    EffectiveGain is BaseGain * Level,
    % Apply the relay archetype rule with the current, bus-set gain.
    archetype_relay(TotalInput, EffectiveGain, NextActivation).

% A construct of a kind the delayed modulated step does not know is refused aloud, never silently dropped.
connection_graph_next_delayed_modulated(Kind, _Name, _Deliveries, _State, _Bus, _NextActivation) :-
    % Only a clamped source belongs among the plain kinds.
    Kind \== source,
    % A relay with any fixed gain also belongs.
    Kind \= relay(_),
    % A relay whose gain the bus sets also belongs.
    Kind \= relay_modulated(_, _),
    % Refuse the unknown kind by name, so the state can never shrink in silence.
    throw(error(domain_error(delayed_modulated_step_construct_kind, Kind), _)).

% connection_graph_step_delayed_modulated(+Constructs, +State, +Lines, +Bus, -NextState, -NextLines).
connection_graph_step_delayed_modulated(Constructs, State, Lines, Bus, NextState, NextLines) :-
    % First pass, part one: advance every delay line one tick from the current state only.
    findall(Delivery-NextLine,
            % For each delay line, taken in turn.
            ( member(Line, Lines),
              % Take in the source's emission and give out the value whose time has come.
              connection_graph_advance_line(State, Line, Delivery, NextLine) ),
            Advanced),
    % Split the advanced pairs into this tick's deliveries and the lines' next buffers.
    findall(Delivery, member(Delivery-_, Advanced), Deliveries),
    findall(NextLine, member(_-NextLine, Advanced), NextLines),
    % First pass, part two: compute every construct's next activation from the deliveries and the bus.
    findall(Name-NextActivation,
            % For each construct in the network, taken in turn.
            ( member(construct(Name, Kind), Constructs),
              % Compute its next activation from the read-only state, the deliveries, and the bus.
              connection_graph_next_delayed_modulated(Kind, Name, Deliveries, State, Bus, NextActivation) ),
            NextPairs),
    % Second pass: commit all next activations at once into a canonical state.
    keysort(NextPairs, NextState).
