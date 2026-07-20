% Load the connection_graph module under test from the library path.
:- use_module(library(connection_graph)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% Open the test block for the connection_graph pack.
:- begin_tests(connection_graph).

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

% Close the test block for the connection_graph pack.
:- end_tests(connection_graph).
