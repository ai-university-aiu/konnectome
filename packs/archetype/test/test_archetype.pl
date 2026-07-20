% Load the archetype module under test from the library path.
:- use_module(library(archetype)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% Iterate the integrator N times with a fixed leak factor and a fixed input.
iterate_integrator(0, Activation, _Leak, _Input, Activation) :- !.
% Each step applies the integrator rule and counts down.
iterate_integrator(N, Activation0, Leak, Input, Activation) :-
    % Continue only while ticks remain.
    N > 0,
    % Apply one integrator step.
    archetype_integrator(Activation0, Leak, Input, Activation1),
    % Count this tick down.
    N1 is N - 1,
    % Continue from the new activation.
    iterate_integrator(N1, Activation1, Leak, Input, Activation).

% Iterate the oscillator N times with a fixed frequency and cycle, returning the final phase.
iterate_oscillator(0, Phase, _Freq, _Cycle, Phase) :- !.
% Each step advances the phase and counts down.
iterate_oscillator(N, Phase0, Freq, Cycle, Phase) :-
    % Continue only while ticks remain.
    N > 0,
    % Apply one oscillator step, ignoring the gain here.
    archetype_oscillator(Phase0, Freq, Cycle, Phase1, _Gain),
    % Count this tick down.
    N1 is N - 1,
    % Continue from the new phase.
    iterate_oscillator(N1, Phase1, Freq, Cycle, Phase).

% Iterate the attractor N times with fixed input, memories, and step, returning the final pattern.
iterate_attractor(0, Pattern, _Input, _Stored, _Step, Pattern) :- !.
% Each step moves the pattern toward the nearest memory and counts down.
iterate_attractor(N, Pattern0, Input, Stored, Step, Pattern) :-
    % Continue only while ticks remain.
    N > 0,
    % Apply one attractor step.
    archetype_attractor(Pattern0, Input, Stored, Step, Pattern1),
    % Count this tick down.
    N1 is N - 1,
    % Continue from the new pattern.
    iterate_attractor(N1, Pattern1, Input, Stored, Step, Pattern).

% Two patterns are close enough when every pair of elements is within the tolerance.
patterns_close([], [], _Eps).
% Compare the heads, then recurse on the tails.
patterns_close([X|Xs], [Y|Ys], Eps) :-
    % The elementwise absolute difference is within tolerance.
    abs(X - Y) =< Eps,
    % Recurse on the rest of the patterns.
    patterns_close(Xs, Ys, Eps).

% Open the test block for the archetype pack.
:- begin_tests(archetype).

% TEST OF THE RELAY: a pipe passes what it is given, scaled by gain.
test(relay_scales) :-
    % Four units of input at gain one and a half.
    archetype_relay(4, 1.5, Activation),
    % The output is the input times the gain.
    assertion(Activation =:= 6.0).

% TEST OF THE INTEGRATOR: a bucket fills toward a bound and, with no input, leaks toward zero.
test(integrator_fills_and_leaks) :-
    % Fifty ticks of constant input one at leak nine tenths rise toward the bound of ten.
    iterate_integrator(50, 0, 0.9, 1, Filled),
    % The filled activation is close to but below the bound of ten.
    assertion(Filled > 9.0),
    % And it never exceeds the bound.
    assertion(Filled < 10.0),
    % Fifty ticks of no input from ten decay toward zero.
    iterate_integrator(50, 10, 0.9, 0, Leaked),
    % The leaked activation is near zero.
    assertion(Leaked < 0.1).

% TEST OF THE OSCILLATOR: a metronome keeps time; phase wraps and gain rises and falls once per cycle.
test(oscillator_keeps_time) :-
    % Twelve ticks at frequency one over a cycle of twelve return the phase to its start.
    iterate_oscillator(12, 0, 1, 12, Phase),
    % The phase has wrapped back to zero.
    assertion(abs(Phase - 0) =< 1.0e-9),
    % At phase zero the receptivity peaks at one.
    archetype_oscillator(11, 1, 12, _P0, GainPeak),
    % The peak gain is one.
    assertion(abs(GainPeak - 1.0) =< 1.0e-9),
    % Half a cycle later the receptivity troughs at zero.
    archetype_oscillator(5, 1, 12, _P1, GainTrough),
    % The trough gain is zero.
    assertion(abs(GainTrough - 0.0) =< 1.0e-9).

% TEST OF THE ATTRACTOR: a memory completes from a fragment, converging to the nearer stored pattern.
test(attractor_completes_from_fragment) :-
    % One stored pattern and a competing one.
    Stored = [[1.0, 0.0, 1.0, 0.0], [0.0, 1.0, 0.0, 1.0]],
    % A fragment close to the first stored pattern but corrupted in its last element.
    Fragment = [1.0, 0.0, 1.0, 0.8],
    % Forty steps toward the nearest memory, feeding the fragment as the standing input.
    iterate_attractor(40, Fragment, Fragment, Stored, 0.3, Completed),
    % The pattern has converged to the whole first stored pattern.
    assertion(patterns_close(Completed, [1.0, 0.0, 1.0, 0.0], 0.05)).

% TEST OF THE GATE: a stiff switch holds below threshold, flips above, and then resists flipping back.
test(gate_resists_flipping) :-
    % A sub-threshold drive leaves the mode unchanged.
    archetype_gate(open, 0.3, 0.5, HeldMode),
    % The gate stays open.
    assertion(HeldMode == open),
    % A supra-threshold drive flips the mode.
    archetype_gate(open, 0.7, 0.5, FlippedMode),
    % The gate is now closed.
    assertion(FlippedMode == closed),
    % A later sub-threshold drive does not flip it back.
    archetype_gate(closed, 0.3, 0.5, ResistedMode),
    % The gate resists and stays closed.
    assertion(ResistedMode == closed).

% TEST OF THE COMPARATOR: a scale reports zero when balanced, positive above, negative below.
test(comparator_reports_difference) :-
    % Equal expectation and actual gives zero.
    archetype_comparator(5, 5, Balanced),
    % The balanced error is zero.
    assertion(Balanced =:= 0),
    % An actual above expectation gives a positive error.
    archetype_comparator(5, 8, Above),
    % The error is positive.
    assertion(Above =:= 3),
    % An actual below expectation gives a negative error.
    archetype_comparator(5, 2, Below),
    % The error is negative.
    assertion(Below =:= -3).

% TEST OF THE DISPATCH: each archetype routes to its matching rule and no other (A2.9).
test(dispatch_routes_each_archetype) :-
    % The relay dispatch scales its input by gain.
    archetype_step(relay, _{total_input: 4, gain: 1.5}, RelayOut),
    % Its output activation is six.
    assertion(get_dict(activation, RelayOut, 6.0)),
    % The comparator dispatch reports the difference.
    archetype_step(comparator, _{expected_input: 5, actual_input: 8}, ComparatorOut),
    % Its output activation is the prediction error three.
    assertion(get_dict(activation, ComparatorOut, 3)),
    % The gate dispatch flips above threshold.
    archetype_step(gate, _{mode: open, switch_drive: 0.7, threshold: 0.5}, GateOut),
    % Its output mode is closed.
    assertion(get_dict(mode, GateOut, closed)).

% Close the test block for the archetype pack.
:- end_tests(archetype).
