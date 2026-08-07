% Load the plasticity_engine module under test from the library path.
:- use_module(library(plasticity_engine)).
% Load the neuromodulator_bus module, used to set the dopamine third factor.
:- use_module(library(neuromodulator_bus)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% Two numbers are close enough when their difference is within a tiny tolerance (floating-point safe).
plasticity_test_close(A, B) :-
    % Compare within a tolerance, since exact decimal fractions are not exact in binary floating point.
    abs(A - B) =< 1.0e-9.

% Open the test block for the plasticity_engine pack.
:- begin_tests(plasticity_engine).

% The weight change is the product of the two activities and the third factor, scaled by the rate.
test(weight_change_is_product_of_activities_and_third_factor) :-
    % Both ends fully active, full dopamine, one-tenth learning rate.
    plasticity_engine_weight_change(1, 1, 1, 0.1, ChangeOne),
    % The change is one-tenth.
    assertion(plasticity_test_close(ChangeOne, 0.1)),
    % Stronger activities and half dopamine.
    plasticity_engine_weight_change(2, 3, 0.5, 0.1, ChangeTwo),
    % The change is two times three, times one half, times one tenth, which is three tenths.
    assertion(plasticity_test_close(ChangeTwo, 0.3)).

% Coincident activity plus dopamine strengthens the connecting weight (the learning test of A4.4).
test(coincidence_and_dopamine_strengthen_the_weight) :-
    % A bus carrying a full dopamine reward.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus),
    % One transmissive interface with a starting weight of one half.
    Interfaces0 = [interface(a, b, 0.5, 1, transmissive)],
    % Both ends active together.
    plasticity_engine_step(Interfaces0, [a-1, b-1], Bus, 0.1, Interfaces),
    % Read back the learned interface.
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    % The weight grew by the three-factor change to six tenths.
    assertion(plasticity_test_close(Weight, 0.6)).

% Without dopamine there is no learning, even when both ends are active (the three-factor property).
test(no_dopamine_means_no_learning) :-
    % A bus with no dopamine, so the third factor reads zero.
    neuromodulator_bus_new(Bus),
    % One transmissive interface.
    Interfaces0 = [interface(a, b, 0.5, 1, transmissive)],
    % Both ends active, but no reward signal.
    plasticity_engine_step(Interfaces0, [a-1, b-1], Bus, 0.1, Interfaces),
    % Read back the interface.
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    % The weight is unchanged; coincidence alone does not learn.
    assertion(Weight =:= 0.5).

% If one end is silent there is no coincidence, so no learning, even with dopamine present.
test(an_inactive_end_means_no_learning) :-
    % A bus carrying full dopamine.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus),
    % One transmissive interface.
    Interfaces0 = [interface(a, b, 0.5, 1, transmissive)],
    % The receiving end is silent.
    plasticity_engine_step(Interfaces0, [a-1, b-0], Bus, 0.1, Interfaces),
    % Read back the interface.
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    % The weight is unchanged; both ends must fire together.
    assertion(Weight =:= 0.5).

% A computational interface does not learn; only transmissive weights change.
test(a_computational_interface_does_not_learn) :-
    % A bus carrying full dopamine and both ends active.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus),
    % One computational interface.
    Interfaces0 = [interface(a, b, 0.5, 1, computational)],
    % Step the learning rule.
    plasticity_engine_step(Interfaces0, [a-1, b-1], Bus, 0.1, Interfaces),
    % Read back the interface.
    Interfaces = [interface(a, b, Weight, 1, computational)],
    % The computational weight is unchanged.
    assertion(Weight =:= 0.5).

% A fresh trace store carries a zero trace for each transmissive interface and none for computational ones.
test(a_new_trace_store_is_zero_for_transmissive_interfaces_only) :-
    % One transmissive and one computational interface.
    Interfaces = [interface(a, b, 0.5, 1, transmissive), interface(b, c, 0.5, 1, computational)],
    % Build the fresh trace store.
    plasticity_engine_trace_new(Interfaces, Traces),
    % Exactly the transmissive interface carries a trace, and it starts at zero.
    assertion(Traces == [(a-b)-0]).

% One tick of coincident activity writes the coincidence into the trace.
test(the_trace_accumulates_the_coincidence) :-
    % One transmissive interface with a fresh zero trace.
    Interfaces = [interface(a, b, 0.5, 1, transmissive)],
    plasticity_engine_trace_new(Interfaces, Traces0),
    % Both ends active together for one tick, with a nine-tenths fading factor.
    plasticity_engine_trace_step(Interfaces, [a-1, b-1], 0.9, Traces0, Traces),
    % The trace holds the full coincidence of one.
    Traces = [(a-b)-Trace],
    assertion(plasticity_test_close(Trace, 1.0)).

% Without fresh coincidence the trace fades by the fading factor each tick.
test(the_trace_fades_without_coincidence) :-
    % One transmissive interface whose trace already holds one.
    Interfaces = [interface(a, b, 0.5, 1, transmissive)],
    % Two silent ticks at a nine-tenths fading factor.
    plasticity_engine_trace_step(Interfaces, [a-0, b-0], 0.9, [(a-b)-1], TracesOne),
    plasticity_engine_trace_step(Interfaces, [a-0, b-0], 0.9, TracesOne, TracesTwo),
    % The trace has faded to nine tenths, then to eighty-one hundredths.
    TracesOne = [(a-b)-TraceOne],
    assertion(plasticity_test_close(TraceOne, 0.9)),
    TracesTwo = [(a-b)-TraceTwo],
    assertion(plasticity_test_close(TraceTwo, 0.81)).

% The manuscript's test: a reward arriving one tick AFTER the activity still strengthens the weight.
test(a_reward_one_tick_late_still_strengthens_the_weight) :-
    % One transmissive interface with a starting weight of one half and a fresh trace.
    Interfaces0 = [interface(a, b, 0.5, 1, transmissive)],
    plasticity_engine_trace_new(Interfaces0, Traces0),
    % Tick one: both ends active together, no reward yet.
    plasticity_engine_trace_step(Interfaces0, [a-1, b-1], 0.9, Traces0, TracesOne),
    % Tick two: both ends silent, and the trace fades to nine tenths.
    plasticity_engine_trace_step(Interfaces0, [a-0, b-0], 0.9, TracesOne, TracesTwo),
    % The reward arrives now, one tick late, as full dopamine on the bus.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus),
    % Apply the reward through the trace at a one-tenth learning rate.
    plasticity_engine_reward_step(Interfaces0, TracesTwo, Bus, 0.1, Interfaces),
    % The weight grew by the faded trace times the third factor times the rate: nine hundredths.
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    assertion(plasticity_test_close(Weight, 0.59)).

% Without dopamine the reward step changes nothing, however strong the trace.
test(no_dopamine_at_the_reward_step_means_no_learning) :-
    % A bus with no dopamine, so the third factor reads zero.
    neuromodulator_bus_new(Bus),
    % One transmissive interface with a full trace.
    Interfaces0 = [interface(a, b, 0.5, 1, transmissive)],
    plasticity_engine_reward_step(Interfaces0, [(a-b)-1], Bus, 0.1, Interfaces),
    % The weight is unchanged; the trace alone does not learn.
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    assertion(Weight =:= 0.5).

% A computational interface carries no trace and its weight never changes at the reward step.
test(a_computational_interface_never_learns_by_reward) :-
    % A bus carrying full dopamine.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus),
    % One computational interface, and an empty trace store as its constructor builds.
    Interfaces0 = [interface(a, b, 0.5, 1, computational)],
    plasticity_engine_trace_new(Interfaces0, Traces),
    assertion(Traces == []),
    % Step the trace and apply the reward.
    plasticity_engine_trace_step(Interfaces0, [a-1, b-1], 0.9, Traces, Traces),
    plasticity_engine_reward_step(Interfaces0, Traces, Bus, 0.1, Interfaces),
    % The computational weight is unchanged.
    Interfaces = [interface(a, b, Weight, 1, computational)],
    assertion(Weight =:= 0.5).

% A fading factor of one or more is refused by name: a trace that never fades is not a trace.
test(a_fading_factor_of_one_or_more_is_refused_by_name, error(domain_error(plasticity_engine_fading_factor, 1))) :-
    % A fading factor of exactly one must throw.
    plasticity_engine_trace_step([interface(a, b, 0.5, 1, transmissive)], [a-1, b-1], 1, [(a-b)-0], _).

% A negative fading factor is refused by name for the same reason.
test(a_negative_fading_factor_is_refused_by_name, error(domain_error(plasticity_engine_fading_factor, -0.1))) :-
    % A negative fading factor must throw.
    plasticity_engine_trace_step([interface(a, b, 0.5, 1, transmissive)], [a-1, b-1], -0.1, [(a-b)-0], _).

% A transmissive interface whose trace is missing from the store is refused aloud, never silently zeroed.
test(a_ghost_trace_is_refused_by_name_at_the_trace_step, error(existence_error(plasticity_engine_trace, a-b))) :-
    % The trace store is empty, so the interface's trace does not exist.
    plasticity_engine_trace_step([interface(a, b, 0.5, 1, transmissive)], [a-1, b-1], 0.9, [], _).

% The reward step refuses a ghost trace just as loudly as the trace step does.
test(a_ghost_trace_is_refused_by_name_at_the_reward_step, error(existence_error(plasticity_engine_trace, a-b))) :-
    % A bus carrying full dopamine, and an empty trace store.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus),
    plasticity_engine_reward_step([interface(a, b, 0.5, 1, transmissive)], [], Bus, 0.1, _).

% An unknown interface kind is refused by name, never silently carried or dropped.
test(an_unknown_interface_kind_is_refused_by_name_at_the_trace_step, error(domain_error(plasticity_engine_interface_kind, mystery))) :-
    % A kind no slice has defined must throw at the trace step.
    plasticity_engine_trace_step([interface(a, b, 0.5, 1, mystery)], [a-1, b-1], 0.9, [], _).

% The reward step refuses the unknown kind with the same voice.
test(an_unknown_interface_kind_is_refused_by_name_at_the_reward_step, error(domain_error(plasticity_engine_interface_kind, mystery))) :-
    % A bus carrying full dopamine.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus),
    % A kind no slice has defined must throw at the reward step.
    plasticity_engine_reward_step([interface(a, b, 0.5, 1, mystery)], [], Bus, 0.1, _).

% REVIEW PIN: an unbound interface kind is refused as uninstantiated, never silently bound and learned.
test(an_unbound_kind_is_refused_at_the_trace_step, error(instantiation_error)) :-
    % A variable kind must throw, not quietly become transmissive.
    plasticity_engine_trace_step([interface(a, b, 0.5, 1, _)], [a-1, b-1], 0.9, [(a-b)-0], _).

% REVIEW PIN: the reward step refuses the unbound kind with the same voice.
test(an_unbound_kind_is_refused_at_the_reward_step, error(instantiation_error)) :-
    % A bus carrying full dopamine.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus),
    % A variable kind must throw, not quietly become transmissive.
    plasticity_engine_reward_step([interface(a, b, 0.5, 1, _)], [(a-b)-0], Bus, 0.1, _).

% REVIEW PIN: a term that is not an interface at all is refused by name, never silently skipped.
test(a_malformed_interface_is_refused_at_the_trace_step, error(domain_error(plasticity_engine_interface, not_an_interface))) :-
    % A stray atom in the interface list must throw.
    plasticity_engine_trace_step([not_an_interface, interface(a, b, 0.5, 1, transmissive)], [a-1, b-1], 0.9, [(a-b)-0], _).

% REVIEW PIN: the reward step refuses the malformed term aloud instead of silently failing.
test(a_malformed_interface_is_refused_at_the_reward_step, error(domain_error(plasticity_engine_interface, not_an_interface))) :-
    % A bus carrying full dopamine.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus),
    % A stray atom in the interface list must throw, not merely fail.
    plasticity_engine_reward_step([not_an_interface], [], Bus, 0.1, _).

% REVIEW PIN: two transmissive interfaces over the same endpoints are refused, never double-counted.
test(a_duplicate_transmissive_interface_is_refused_by_name, error(domain_error(plasticity_engine_duplicate_interface, a-b))) :-
    % The same endpoint pair twice must throw.
    plasticity_engine_trace_step([interface(a, b, 0.5, 1, transmissive), interface(a, b, 0.7, 1, transmissive)],
                                 [a-1, b-1], 0.9, [(a-b)-0], _).

% REVIEW PIN: two traces under one key are refused, never resolved by first-one-wins.
test(a_duplicate_trace_key_is_refused_by_name, error(domain_error(plasticity_engine_duplicate_trace, a-b))) :-
    % The same trace key twice must throw.
    plasticity_engine_trace_step([interface(a, b, 0.5, 1, transmissive)], [a-1, b-1], 0.9, [(a-b)-0, (a-b)-1], _).

% REVIEW PIN: a trace whose interface is gone is refused aloud - the mirror of the ghost-trace refusal.
test(an_orphan_trace_is_refused_by_name, error(existence_error(plasticity_engine_interface, x-y))) :-
    % A trace for an endpoint pair no transmissive interface carries must throw.
    plasticity_engine_trace_step([interface(a, b, 0.5, 1, transmissive)], [a-1, b-1], 0.9, [(a-b)-0, (x-y)-7], _).

% Close the test block for the plasticity_engine pack.
:- end_tests(plasticity_engine).
