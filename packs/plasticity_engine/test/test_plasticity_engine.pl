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

% A fresh average store carries a zero running average for every named construct.
test(a_new_average_store_is_zero_for_every_construct) :-
    % Two named constructs with current activities.
    plasticity_engine_average_new([a-1, b-0.5], Averages),
    % Each construct starts its running average at zero.
    assertion(Averages == [a-0, b-0]).

% One average tick moves each running average a smoothing step toward the current activity.
test(the_average_moves_toward_the_activity) :-
    % A zero average and a fully active construct, smoothed at one half.
    plasticity_engine_average_step([a-1], 0.5, [a-0], AveragesOne),
    % The average moves halfway to the activity.
    AveragesOne = [a-AverageOne],
    assertion(plasticity_test_close(AverageOne, 0.5)),
    % A second identical tick closes half the remaining distance.
    plasticity_engine_average_step([a-1], 0.5, AveragesOne, AveragesTwo),
    % The average now stands at three quarters.
    AveragesTwo = [a-AverageTwo],
    assertion(plasticity_test_close(AverageTwo, 0.75)).

% A construct absent from the activations counts as silent, exactly as the learning step counts it.
test(an_absent_activity_counts_as_silence_in_the_average) :-
    % The construct has an average but no listed activity this tick.
    plasticity_engine_average_step([], 0.5, [a-1], Averages),
    % The average decays toward zero.
    Averages = [a-Average],
    assertion(plasticity_test_close(Average, 0.5)).

% A smoothing factor of zero is refused by name: an average that never moves is not an average.
test(a_zero_smoothing_factor_is_refused_by_name, error(domain_error(plasticity_engine_smoothing_factor, 0))) :-
    % A zero smoothing factor must throw.
    plasticity_engine_average_step([a-1], 0, [a-0], _).

% A smoothing factor above one is refused by name: an average cannot overshoot its own signal.
test(a_smoothing_factor_above_one_is_refused_by_name, error(domain_error(plasticity_engine_smoothing_factor, 1.5))) :-
    % A smoothing factor above one must throw.
    plasticity_engine_average_step([a-1], 1.5, [a-0], _).

% A duplicate average key is refused, never resolved by first-one-wins.
test(a_duplicate_average_key_is_refused_by_name, error(domain_error(plasticity_engine_duplicate_average, a))) :-
    % The same construct twice in the average store must throw.
    plasticity_engine_average_step([a-1], 0.5, [a-0, a-1], _).

% An overactive region scales its incoming transmissive weights down.
test(an_overactive_region_scales_its_inputs_down) :-
    % One transmissive interface into b, whose average activity of one sits above the half target.
    Interfaces0 = [interface(a, b, 0.8, 1, transmissive)],
    plasticity_engine_scaling_step(Interfaces0, [a-1, b-1], 0.5, 0.1, Interfaces),
    % The weight shrinks by the scaling factor: 0.8 times (1 + 0.1 times (0.5 - 1)) is 0.76.
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    assertion(plasticity_test_close(Weight, 0.76)).

% An underactive region scales its incoming transmissive weights up.
test(an_underactive_region_scales_its_inputs_up) :-
    % One transmissive interface into b, whose zero average sits below the half target.
    Interfaces0 = [interface(a, b, 0.8, 1, transmissive)],
    plasticity_engine_scaling_step(Interfaces0, [a-1, b-0], 0.5, 0.1, Interfaces),
    % The weight grows by the scaling factor: 0.8 times (1 + 0.1 times (0.5 - 0)) is 0.84.
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    assertion(plasticity_test_close(Weight, 0.84)).

% A region exactly at its target leaves every incoming weight untouched.
test(a_region_at_target_leaves_its_inputs_untouched) :-
    % One transmissive interface into b, whose average sits exactly at the target.
    Interfaces0 = [interface(a, b, 0.8, 1, transmissive)],
    plasticity_engine_scaling_step(Interfaces0, [a-1, b-0.5], 0.5, 0.1, Interfaces),
    % The scaling factor is exactly one, so the weight does not move.
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    assertion(plasticity_test_close(Weight, 0.8)).

% Scaling is multiplicative and floors at zero: a weight can be silenced but never sign-flipped.
test(the_scaling_factor_floors_at_zero) :-
    % A wildly overactive region under a strong scaling rate would compute a negative factor.
    Interfaces0 = [interface(a, b, 0.8, 1, transmissive)],
    plasticity_engine_scaling_step(Interfaces0, [a-1, b-100], 0.5, 0.5, Interfaces),
    % The factor is floored at zero, so the weight is silenced, not inverted.
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    assertion(Weight =:= 0).

% A computational interface is untouched by homeostatic scaling.
test(a_computational_interface_is_untouched_by_scaling) :-
    % One computational interface into an overactive region.
    Interfaces0 = [interface(a, b, 0.8, 1, computational)],
    plasticity_engine_scaling_step(Interfaces0, [a-1, b-1], 0.5, 0.1, Interfaces),
    % The computational weight does not move.
    Interfaces = [interface(a, b, Weight, 1, computational)],
    assertion(Weight =:= 0.8).

% A receiving construct absent from the averages is refused aloud, never counted as silent.
test(a_ghost_average_is_refused_by_name_at_the_scaling_step, error(existence_error(plasticity_engine_average, b))) :-
    % The average store does not know the receiving end b.
    plasticity_engine_scaling_step([interface(a, b, 0.8, 1, transmissive)], [a-1], 0.5, 0.1, _).

% The scaling step refuses a malformed interface with the shared perimeter's voice.
test(a_malformed_interface_is_refused_at_the_scaling_step, error(domain_error(plasticity_engine_interface, not_an_interface))) :-
    % A stray atom in the interface list must throw.
    plasticity_engine_scaling_step([not_an_interface], [a-1, b-1], 0.5, 0.1, _).

% A scaling rate of one or more is refused by name: the bound must be slow, never an overcorrection.
test(a_scaling_rate_of_one_or_more_is_refused_by_name, error(domain_error(plasticity_engine_scaling_rate, 1))) :-
    % A scaling rate of one must throw.
    plasticity_engine_scaling_step([interface(a, b, 0.8, 1, transmissive)], [a-1, b-1], 0.5, 1, _).

% A negative scaling rate is refused by name: feedback that amplifies is not homeostasis.
test(a_negative_scaling_rate_is_refused_by_name, error(domain_error(plasticity_engine_scaling_rate, -0.1))) :-
    % A negative scaling rate must throw.
    plasticity_engine_scaling_step([interface(a, b, 0.8, 1, transmissive)], [a-1, b-1], 0.5, -0.1, _).

% A negative activity target is refused by name: a region cannot defend an impossible set-point.
test(a_negative_target_is_refused_by_name, error(domain_error(plasticity_engine_activity_target, -0.5))) :-
    % A negative target must throw.
    plasticity_engine_scaling_step([interface(a, b, 0.8, 1, transmissive)], [a-1, b-1], -0.5, 0.1, _).

% plasticity_test_bounded_run(+Ticks, +Interfaces0, -FinalWeight): learn and scale together for many ticks.
plasticity_test_bounded_run(0, [interface(_, _, Weight, _, _)], Weight) :- !.
% Each tick applies the fast three-factor learning and then the slow homeostatic bound.
plasticity_test_bounded_run(Ticks, Interfaces0, FinalWeight) :-
    % A bus carrying full dopamine every tick: relentless reward, the worst case for stability.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus),
    % Fast learning strengthens the weight while both ends stay fully active.
    plasticity_engine_step(Interfaces0, [a-1, b-1], Bus, 0.1, Learned),
    % Slow scaling pulls the overactive region's inputs back toward the half target.
    plasticity_engine_scaling_step(Learned, [a-1, b-1], 0.5, 0.1, Scaled),
    % Count the tick and continue.
    RemainingTicks is Ticks - 1,
    plasticity_test_bounded_run(RemainingTicks, Scaled, FinalWeight).

% The manuscript's promise made runnable: the slow bound keeps the fast learning from exploding.
test(homeostatic_scaling_bounds_a_relentlessly_rewarded_weight) :-
    % Fifty ticks of maximal coincidence and maximal dopamine, scaled every tick.
    plasticity_test_bounded_run(50, [interface(a, b, 0.5, 1, transmissive)], FinalWeight),
    % Unbounded learning would reach five and a half; the bound holds the weight below its fixed point of 1.9.
    assertion(FinalWeight < 1.9),
    % The weight neither explodes nor collapses: it climbs from a half toward the fixed point and stays.
    assertion(FinalWeight > 1.7).

% REVIEW PIN: a malformed average pair is refused by name at the average step, never silently failed past.
test(a_malformed_average_pair_is_refused_at_the_average_step, error(domain_error(plasticity_engine_average_pair, bogus))) :-
    % A bare atom in the average store must throw, not make the step quietly fail.
    plasticity_engine_average_step([a-1], 0.5, [a-0, bogus], _).

% REVIEW PIN: the scaling step refuses the same malformed store with the same voice - one store, one verdict.
test(a_malformed_average_pair_is_refused_at_the_scaling_step, error(domain_error(plasticity_engine_average_pair, junk))) :-
    % The store the average step refuses must never be silently accepted here.
    plasticity_engine_scaling_step([interface(a, b, 0.8, 1, transmissive)], [b-1, junk], 0.5, 0.1, _).

% REVIEW PIN: an unbound average store is refused as uninstantiated, never walked off a cliff.
test(an_unbound_average_store_is_refused_at_the_scaling_step, error(instantiation_error)) :-
    % An unbound store must throw at once, not overflow the stack.
    plasticity_engine_scaling_step([interface(a, b, 0.8, 1, transmissive)], _, 0.5, 0.1, _).

% REVIEW PIN: the constructor refuses a malformed activation pair - it never mints a store its consumers refuse.
test(a_malformed_activation_pair_is_refused_by_the_average_constructor, error(domain_error(plasticity_engine_activation_pair, junk))) :-
    % A bare atom among the activations must throw at construction.
    plasticity_engine_average_new([a-1, junk], _).

% REVIEW PIN: the constructor refuses a duplicate construct name for the same reason.
test(a_duplicate_activation_name_is_refused_by_the_average_constructor, error(domain_error(plasticity_engine_duplicate_activation, a))) :-
    % The same construct twice among the activations must throw at construction.
    plasticity_engine_average_new([a-1, a-2], _).

% REVIEW PIN, MIRRORED ROOT: a malformed trace pair is refused by name at the trace step too.
test(a_malformed_trace_pair_is_refused_at_the_trace_step, error(domain_error(plasticity_engine_trace_pair, junk))) :-
    % The shared store judgement covers the slice-28 trace store as well.
    plasticity_engine_trace_step([interface(a, b, 0.5, 1, transmissive)], [a-1, b-1], 0.9, [(a-b)-0, junk], _).

% REVIEW PIN, MIRRORED ROOT: the trace constructor refuses a duplicate transmissive interface at construction.
test(a_duplicate_interface_is_refused_by_the_trace_constructor, error(domain_error(plasticity_engine_duplicate_interface, a-b))) :-
    % The constructor must never mint duplicate trace keys for its consumers to refuse later.
    plasticity_engine_trace_new([interface(a, b, 0.5, 1, transmissive), interface(a, b, 0.7, 1, transmissive)], _).

% Close the test block for the plasticity_engine pack.
:- end_tests(plasticity_engine).
