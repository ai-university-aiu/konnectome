% Load the connection_graph module under test from the library path.
:- use_module(library(connection_graph)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).
% Load the neuromodulator_bus module, used to build a bus that sets relay gains.
:- use_module(library(neuromodulator_bus)).

% Open the test block for the connection_graph pack.
:- begin_tests(connection_graph).

% The bus sets a modulated relay's gain: the output scales with the modulator's level.
test(the_bus_sets_a_modulated_relay_gain) :-
    % A source a feeds b, a relay whose gain the bus sets.
    Graph = [interface(a, b, 3, 1, transmissive)],
    Constructs = [construct(a, source), construct(b, relay_modulated(1, gain))],
    % A bus carrying a gain level of two.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, gain, 2, Bus),
    % One modulated tick.
    connection_graph_step_modulated(Graph, Constructs, [a-1, b-0], Bus, Next),
    % Total input to b is three; effective gain is base one times bus two; b becomes six.
    connection_graph_state_get(Next, b, ValueB),
    % Confirm the bus-set gain.
    assertion(ValueB =:= 6).

% Depleting the gain modulator silences a modulated relay.
test(depleting_the_gain_modulator_silences_the_relay) :-
    % The same source and modulated relay.
    Graph = [interface(a, b, 3, 1, transmissive)],
    Constructs = [construct(a, source), construct(b, relay_modulated(1, gain))],
    % An empty bus, so the gain modulator reads zero.
    neuromodulator_bus_new(Bus),
    % One modulated tick.
    connection_graph_step_modulated(Graph, Constructs, [a-1, b-0], Bus, Next),
    % With zero gain, the relay is silent.
    connection_graph_state_get(Next, b, ValueB),
    % Confirm the silence.
    assertion(ValueB =:= 0).

% The total weighted input is the sum of each incoming transmissive interface's weighted source.
test(total_weighted_input_sums_incoming) :-
    % Two interfaces arrive at c, from a with weight two and from b with weight three.
    Graph = [interface(a, c, 2, 1, transmissive), interface(b, c, 3, 1, transmissive)],
    % Gather the total input at c given the source activations.
    connection_graph_total_input(Graph, c, [a-1, b-2, c-0], Total),
    % The total is two times one plus three times two, which is eight.
    assertion(Total =:= 8).

% A construct with no incoming interfaces receives zero input.
test(no_incoming_is_zero_input) :-
    % An empty graph delivers nothing to x.
    connection_graph_total_input([], x, [x-5], Total),
    % The total input is zero.
    assertion(Total =:= 0).

% A signal presented at a source reaches its target after exactly the number of one-tick hops.
test(signal_propagates_one_hop_per_tick) :-
    % A three-hop chain from a through b and c to d, each interface a one-tick transmissive link.
    Graph = [interface(a, b, 1, 1, transmissive),
             interface(b, c, 1, 1, transmissive),
             interface(c, d, 1, 1, transmissive)],
    % a is a clamped source; b, c, and d are unit-gain relays.
    Constructs = [construct(a, source), construct(b, relay(1)),
                  construct(c, relay(1)), construct(d, relay(1))],
    % The signal starts as a one at a, with the rest silent.
    Initial = [a-1, b-0, c-0, d-0],
    % Run the network for three ticks and capture the trace.
    connection_graph_run(Graph, Constructs, Initial, 3, _Final, Trace),
    % Bind the three recorded snapshots directly.
    Trace = [tick_record(1, S1), tick_record(2, S2), tick_record(3, S3)],
    % The target d is silent at tick one.
    assertion(connection_graph_state_get(S1, d, 0)),
    % The target d is still silent at tick two.
    assertion(connection_graph_state_get(S2, d, 0)),
    % The target d carries the signal at tick three, and nowhere sooner.
    assertion(connection_graph_state_get(S3, d, 1)),
    % The signal front is at b after one tick.
    assertion(connection_graph_state_get(S1, b, 1)),
    % The signal front is at c after two ticks.
    assertion(connection_graph_state_get(S2, c, 1)).

% A computational interface conveys no gathered input yet (it is recorded but does not transmit here).
test(computational_interface_conveys_nothing_yet) :-
    % One transmissive and one computational interface arrive at c.
    Graph = [interface(a, c, 2, 1, transmissive), interface(b, c, 5, 1, computational)],
    % Gather the total input at c.
    connection_graph_total_input(Graph, c, [a-1, b-9, c-0], Total),
    % Only the transmissive interface contributes: two times one is two.
    assertion(Total =:= 2).

% With every delay at one tick, the delay-line run matches the plain synchronous run exactly.
test(all_delays_one_matches_the_synchronous_run) :-
    % A three-hop chain whose every interface carries the natural one-tick delay.
    Graph = [interface(a, b, 2, 1, transmissive),
             interface(b, c, 3, 1, transmissive),
             interface(c, d, 1, 1, transmissive)],
    % a is a clamped source; b, c, and d are relays with assorted gains.
    Constructs = [construct(a, source), construct(b, relay(1)),
                  construct(c, relay(2)), construct(d, relay(1))],
    % The signal starts as a one at a, with the rest silent.
    Initial = [a-1, b-0, c-0, d-0],
    % Run the same network both ways for four ticks.
    connection_graph_run(Graph, Constructs, Initial, 4, PlainFinal, PlainTrace),
    connection_graph_run_delayed(Graph, Constructs, Initial, 4, DelayedFinal, DelayedTrace),
    % The delayed run reproduces the plain run exactly, state for state.
    assertion(PlainFinal == DelayedFinal),
    % And tick for tick along the whole trace.
    assertion(PlainTrace == DelayedTrace).

% A two-tick delay delivers the signal on the second tick, and nowhere sooner.
test(a_two_tick_delay_delivers_on_the_second_tick) :-
    % A single interface from a to b carrying a two-tick delay.
    Graph = [interface(a, b, 1, 2, transmissive)],
    Constructs = [construct(a, source), construct(b, relay(1))],
    % Run for two ticks and capture the trace.
    connection_graph_run_delayed(Graph, Constructs, [a-1, b-0], 2, _Final, Trace),
    % Bind the two recorded snapshots directly.
    Trace = [tick_record(1, S1), tick_record(2, S2)],
    % The target b is silent at tick one; the signal is still in transit.
    assertion(connection_graph_state_get(S1, b, 0)),
    % The target b carries the signal at tick two, exactly when the delay dictates.
    assertion(connection_graph_state_get(S2, b, 1)).

% Chained delays add: a two-tick hop then a three-tick hop arrive at tick five exactly.
test(chained_delays_arrive_at_the_summed_tick) :-
    % A chain from a to b in two ticks, then b to c in three ticks.
    Graph = [interface(a, b, 1, 2, transmissive),
             interface(b, c, 1, 3, transmissive)],
    Constructs = [construct(a, source), construct(b, relay(1)), construct(c, relay(1))],
    % Run for five ticks and capture the trace.
    connection_graph_run_delayed(Graph, Constructs, [a-1, b-0, c-0], 5, _Final, Trace),
    % Bind the five recorded snapshots directly.
    Trace = [tick_record(1, S1), tick_record(2, S2), tick_record(3, S3),
             tick_record(4, S4), tick_record(5, S5)],
    % The far target c is silent through tick four.
    assertion(connection_graph_state_get(S1, c, 0)),
    assertion(connection_graph_state_get(S2, c, 0)),
    assertion(connection_graph_state_get(S3, c, 0)),
    assertion(connection_graph_state_get(S4, c, 0)),
    % The far target c carries the signal at tick five: two plus three, and nowhere sooner.
    assertion(connection_graph_state_get(S5, c, 1)).

% The interface weight scales the delivered value, not the value in transit.
test(the_weight_scales_the_delivered_value) :-
    % A single interface from a to b with weight three and a two-tick delay.
    Graph = [interface(a, b, 3, 2, transmissive)],
    Constructs = [construct(a, source), construct(b, relay(1))],
    % Run for two ticks.
    connection_graph_run_delayed(Graph, Constructs, [a-1, b-0], 2, Final, _Trace),
    % The delivered signal arrives scaled by the weight: one times three is three.
    connection_graph_state_get(Final, b, ValueB),
    % Confirm the weighted delivery.
    assertion(ValueB =:= 3).

% A value already in transit is preserved even if the source changes afterward.
test(a_value_in_transit_is_preserved) :-
    % A single interface from a to b with a two-tick delay.
    Graph = [interface(a, b, 1, 2, transmissive)],
    Constructs = [construct(a, source), construct(b, relay(1))],
    % Build the empty delay lines for the graph.
    connection_graph_delay_lines_new(Graph, Lines0),
    % One delayed step with the source at one: the one enters the line.
    connection_graph_step_delayed(Constructs, [a-1, b-0], Lines0, State1, Lines1),
    % Silence the source by hand before the next step.
    connection_graph_state_get(State1, b, Mid),
    % The target is still silent while the one is in transit.
    assertion(Mid =:= 0),
    % One more delayed step with the source forced to zero.
    connection_graph_step_delayed(Constructs, [a-0, b-0], Lines1, State2, _Lines2),
    % The original one, already in transit, still arrives.
    connection_graph_state_get(State2, b, ValueB),
    % Confirm the preserved delivery.
    assertion(ValueB =:= 1).

% A computational interface conveys nothing through the delayed path either.
test(a_computational_interface_conveys_nothing_delayed) :-
    % One transmissive and one computational interface arrive at c, both with two-tick delays.
    Graph = [interface(a, c, 2, 2, transmissive),
             interface(b, c, 5, 2, computational)],
    Constructs = [construct(a, source), construct(b, source), construct(c, relay(1))],
    % Run for two ticks with both sources lit.
    connection_graph_run_delayed(Graph, Constructs, [a-1, b-9, c-0], 2, Final, _Trace),
    % Only the transmissive interface delivers: two times one is two.
    connection_graph_state_get(Final, c, ValueC),
    % Confirm the computational interface stayed silent.
    assertion(ValueC =:= 2).

% A delay below one tick is refused; a signal never arrives before it is sent.
test(a_delay_below_one_is_refused, error(domain_error(delay_of_at_least_one_tick, 0))) :-
    % An interface claiming a zero-tick hop.
    connection_graph_delay_lines_new([interface(a, b, 1, 0, transmissive)], _Lines).

% A construct kind the delayed step does not know is refused aloud, never silently dropped.
test(an_unknown_kind_is_refused_by_the_delayed_step,
     error(domain_error(delayed_step_construct_kind, relay_modulated(1, gain)))) :-
    % A modulated relay belongs to the modulated step, not the delayed step.
    Graph = [interface(a, b, 1, 2, transmissive)],
    Constructs = [construct(a, source), construct(b, relay_modulated(1, gain))],
    % Build the delay lines for the graph.
    connection_graph_delay_lines_new(Graph, Lines),
    % The delayed step refuses the kind by name instead of shrinking the state.
    connection_graph_step_delayed(Constructs, [a-1, b-0], Lines, _Next, _NextLines).

% A construct kind the plain step does not know is refused aloud too.
test(an_unknown_kind_is_refused_by_the_plain_step,
     error(domain_error(plain_step_construct_kind, mystery))) :-
    % A kind no step has ever heard of.
    connection_graph_step([], [construct(b, mystery)], [b-0], _Next).

% A source name absent from the state is refused aloud; a delay line never vanishes in silence.
test(a_missing_source_is_refused_by_the_delayed_step,
     error(existence_error(construct_activation, ghost))) :-
    % A delay line whose source is not in the state.
    connection_graph_delay_lines_new([interface(ghost, b, 1, 3, transmissive)], Lines),
    % The delayed step refuses the missing source instead of destroying the line.
    connection_graph_step_delayed([construct(b, relay(1))], [b-0], Lines, _Next, _NextLines).

% A bad delay is refused even on a computational interface, which carries no line.
test(a_bad_delay_on_a_computational_interface_is_refused,
     error(domain_error(delay_of_at_least_one_tick, -7))) :-
    % A computational interface claiming a negative delay.
    connection_graph_delay_lines_new([interface(a, b, 1, -7, computational)], _Lines).

% Close the test block for the connection_graph pack.
:- end_tests(connection_graph).
