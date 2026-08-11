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

% ---------------------------------------------------------------------------
% DECISION-10 - THE SCALING FACTOR IS REFUSED, NEVER CLIPPED (slice 52, OBSERVATION-15)
% ---------------------------------------------------------------------------
%
% THE TEST THIS REPLACES ASSERTED THE DEFECT, AND THAT IS THE MOST IMPORTANT THING IN THIS BLOCK.
% It was called the_scaling_factor_floors_at_zero, it drove an overactive region to a negative raw
% factor, and it asserted that the resulting weight was exactly zero - "silenced, not inverted". It
% passed for nineteen slices. It was testing, faithfully and in detail, a behaviour the corpus
% forbids in as many words: "NEVER ADD OR CLIP INDIVIDUAL WEIGHTS, because multiplication alone
% leaves the relative code untouched."
%
% A TEST THAT PINS A DEFECT IS WORSE THAN NO TEST, because it converts the defect into a promise and
% makes the fix look like the regression. It is replaced rather than deleted, and this note stands in
% its place so the next reader knows the behaviour changed on purpose.

% A factor that is not strictly positive is refused aloud, naming the construct whose bound failed.
test(a_non_positive_scaling_factor_is_refused,
     throws(error(domain_error(plasticity_engine_scaling_factor(b), _), _))) :-
    % A wildly overactive region under a strong scaling rate computes a negative factor.
    Interfaces0 = [interface(a, b, 0.8, 1, transmissive)],
    % The old code clipped this to zero and carried on; it is now a named refusal.
    plasticity_engine_scaling_step(Interfaces0, [a-1, b-100], 0.5, 0.5, _Interfaces).

% THE REFUSAL NAMES THE RECEIVING CONSTRUCT, so a caller learns WHICH region's bound was impossible
% rather than merely that one was. With two loud regions the error names the one actually reached.
test(the_refusal_names_the_region_whose_bound_could_not_be_met,
     throws(error(domain_error(plasticity_engine_scaling_factor(c), _), _))) :-
    % b is comfortably within its bound; c is not.
    Interfaces0 = [interface(a, b, 0.8, 1, transmissive), interface(a, c, 0.8, 1, transmissive)],
    plasticity_engine_scaling_step(Interfaces0, [a-1, b-0.5, c-100], 0.5, 0.5, _Interfaces).

% A FACTOR OF EXACTLY ZERO IS REFUSED TOO, and this is the boundary the old floor sat exactly on.
% Zero was the one value the old code produced deliberately, and it is the value that does the damage:
% a weight multiplied by zero can never be lifted off zero by any later multiplication.
test(a_factor_of_exactly_zero_is_refused,
     throws(error(domain_error(plasticity_engine_scaling_factor(b), _), _))) :-
    % Rate 0.5, target 0.5, average 2.5 gives 1 + 0.5 * (0.5 - 2.5), which is exactly zero.
    Interfaces0 = [interface(a, b, 0.8, 1, transmissive)],
    plasticity_engine_scaling_step(Interfaces0, [a-1, b-2.5], 0.5, 0.5, _Interfaces).

% THE RELATIVE CODE IS PRESERVED, WHICH IS THE PROPERTY THE CORPUS SAYS MULTIPLICATION EXISTS FOR.
% Two weights into one loud region keep their ratio through a legal scaling. Under the old floor,
% a strong enough step set BOTH to zero and the ratio was destroyed for good.
test(a_legal_scaling_preserves_the_ratio_between_two_weights) :-
    % Two inputs to one over-active region, in a two-to-one ratio.
    Interfaces0 = [interface(a, b, 0.8, 1, transmissive), interface(c, b, 0.4, 1, transmissive)],
    % A legal step: the region is loud, but the factor stays strictly positive.
    plasticity_engine_scaling_step(Interfaces0, [a-1, c-1, b-1.5], 0.5, 0.5, Interfaces),
    % Both weights shrank.
    Interfaces = [interface(a, b, WeightA, 1, transmissive), interface(c, b, WeightC, 1, transmissive)],
    assertion(WeightA < 0.8),
    assertion(WeightC < 0.4),
    % And the two-to-one ratio survived, which is the whole point of scaling multiplicatively.
    assertion(plasticity_test_close(WeightA, 2 * WeightC)).

% AND A SCALED WEIGHT REMAINS RECOVERABLE, which the old behaviour made false. A quiet spell after a
% loud one grows the weights back; a weight trapped at zero never would.
test(a_weight_shrunk_by_scaling_can_grow_back) :-
    % One input to a loud region.
    Interfaces0 = [interface(a, b, 0.8, 1, transmissive)],
    % A loud step shrinks it.
    plasticity_engine_scaling_step(Interfaces0, [a-1, b-1.5], 0.5, 0.5, Shrunk),
    Shrunk = [interface(a, b, WeightShrunk, 1, transmissive)],
    assertion(WeightShrunk < 0.8),
    assertion(WeightShrunk > 0),
    % A quiet step grows it again, because it never reached the absorbing point.
    plasticity_engine_scaling_step(Shrunk, [a-1, b-0.0], 0.5, 0.5, Regrown),
    Regrown = [interface(a, b, WeightRegrown, 1, transmissive)],
    assertion(WeightRegrown > WeightShrunk).

% ---------------------------------------------------------------------------
% DECISION-12 - THE RENORMALISER'S DOMAIN IS THE EXCITATORY CONTACTS (slice 54)
% ---------------------------------------------------------------------------

% AN INHIBITORY CONTACT IS LEFT ALONE, which is the corpus's own domain: "every EXCITATORY synapse".
test(an_inhibitory_contact_is_not_scaled) :-
    % One excitatory and one inhibitory input to an over-active region.
    Interfaces0 = [interface(a, b, 0.8, 1, transmissive), interface(c, b, -0.6, 1, transmissive)],
    plasticity_engine_scaling_step(Interfaces0, [a-1, c-1, b-1.5], 0.5, 0.5, Interfaces),
    Interfaces = [interface(a, b, Excitatory, 1, transmissive),
                  interface(c, b, Inhibitory, 1, transmissive)],
    % The excitatory drive is scaled down, because the region is loud.
    assertion(Excitatory < 0.8),
    % The inhibitory contact stands exactly where it was.
    assertion(Inhibitory =:= -0.6).

% A WEIGHT OF EXACTLY ZERO IS LEFT ALONE, and the reason is that the question is empty rather than
% that konnectome picked a side: zero times any factor is zero.
test(a_zero_weight_is_left_alone) :-
    Interfaces0 = [interface(a, b, 0, 1, transmissive)],
    plasticity_engine_scaling_step(Interfaces0, [a-1, b-1.5], 0.5, 0.5, Interfaces),
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    assertion(Weight =:= 0).

% THE CONSEQUENCE, ASSERTED RATHER THAN DISCOVERED LATER. Scaling every weight by one factor
% multiplies the NET input by that factor and preserves the excitation-to-inhibition balance exactly.
% Restricting the domain gives that up on purpose: the excitatory drive shrinks while the inhibition
% stands, so the balance MOVES. This test exists so that the asymmetry is a pinned property of the
% build rather than something a later session meets as a surprise and "corrects".
test(restricting_the_domain_moves_the_excitation_inhibition_balance) :-
    % Net input before is eight tenths less six tenths, which is two tenths.
    Interfaces0 = [interface(a, b, 0.8, 1, transmissive), interface(c, b, -0.6, 1, transmissive)],
    plasticity_engine_scaling_step(Interfaces0, [a-1, c-1, b-1.5], 0.5, 0.5, Interfaces),
    Interfaces = [interface(a, b, Excitatory, 1, transmissive),
                  interface(c, b, Inhibitory, 1, transmissive)],
    Net is Excitatory + Inhibitory,
    % The bound has driven this construct NET NEGATIVE, which uniform scaling could never do.
    assertion(Net < 0),
    % And that is the mechanism rather than a fault: the excitatory half really was scaled.
    assertion(Excitatory > 0),
    assertion(Inhibitory =:= -0.6).

% AN ALL-EXCITATORY GRAPH SCALES EXACTLY AS IT ALWAYS DID, which is why no world konnectome runs
% today changes behaviour. Every weight in the repository is positive.
test(an_all_excitatory_graph_is_unaffected_by_the_domain_rule) :-
    Interfaces0 = [interface(a, b, 0.8, 1, transmissive), interface(c, b, 0.4, 1, transmissive)],
    plasticity_engine_scaling_step(Interfaces0, [a-1, c-1, b-1.5], 0.5, 0.5, Interfaces),
    Interfaces = [interface(a, b, WeightA, 1, transmissive),
                  interface(c, b, WeightC, 1, transmissive)],
    % Both scaled, and the ratio between them preserved, exactly as before this decision.
    assertion(WeightA < 0.8),
    assertion(WeightC < 0.4),
    assertion(plasticity_test_close(WeightA, 2 * WeightC)).

% AND AN INHIBITORY CONTACT CANNOT TRIGGER THE DECISION-10 REFUSAL, because it is never given a
% factor at all. A graph that would refuse on its excitatory edge still refuses; one whose only
% out-of-range edge is inhibitory passes untouched.
test(an_inhibitory_contact_alone_never_reaches_the_factor_refusal) :-
    % A region loud enough that a factor would be non-positive, but with only an inhibitory input.
    Interfaces0 = [interface(c, b, -0.6, 1, transmissive)],
    plasticity_engine_scaling_step(Interfaces0, [c-1, b-100], 0.5, 0.5, Interfaces),
    % No refusal, and the contact is unchanged.
    assertion(Interfaces == [interface(c, b, -0.6, 1, transmissive)]).

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

% SLICE 31: the learning step reads its third factor at the RECEIVING end's territory, not only globally.
test(the_step_reads_the_receiving_territory_level) :-
    % A bus whose diffuse dopamine field is one, but whose territory b holds only a half concentration.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus1),
    neuromodulator_bus_broadcast_territory(Bus1, dopamine, b, 0.5, Bus),
    % One transmissive interface delivering into territory b.
    Interfaces0 = [interface(a, b, 0.5, 1, transmissive)],
    % Both ends active together.
    plasticity_engine_step(Interfaces0, [a-1, b-1], Bus, 0.1, Interfaces),
    % The weight grew by the LOCAL half concentration, not the global one: 0.5 + 1*1*0.5*0.1 is 0.55.
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    assertion(plasticity_test_close(Weight, 0.55)).

% SLICE 31: a territory with no level of its own still learns by the diffuse global field.
test(a_territory_without_a_level_learns_by_the_diffuse_field) :-
    % A bus with a global dopamine level and a local level only in territory c.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus1),
    neuromodulator_bus_broadcast_territory(Bus1, dopamine, c, 0.25, Bus),
    % Two transmissive interfaces: one into the local territory c, one into the unmarked territory b.
    Interfaces0 = [interface(a, b, 0.5, 1, transmissive), interface(a, c, 0.5, 1, transmissive)],
    % All ends active together.
    plasticity_engine_step(Interfaces0, [a-1, b-1, c-1], Bus, 0.1, Interfaces),
    % Territory b reads the diffuse field of one; territory c reads its own quarter concentration.
    Interfaces = [interface(a, b, WeightB, 1, transmissive), interface(a, c, WeightC, 1, transmissive)],
    assertion(plasticity_test_close(WeightB, 0.6)),
    assertion(plasticity_test_close(WeightC, 0.525)).

% SLICE 31: a territory whose own concentration is zero does not learn, even under a global reward.
test(a_silent_territory_does_not_learn_under_a_global_reward) :-
    % A bus broadcasting full dopamine globally but explicitly silencing territory b.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus1),
    neuromodulator_bus_broadcast_territory(Bus1, dopamine, b, 0, Bus),
    % One transmissive interface into the silenced territory.
    Interfaces0 = [interface(a, b, 0.5, 1, transmissive)],
    % Both ends active together, yet the local chemistry says the moment did not matter here.
    plasticity_engine_step(Interfaces0, [a-1, b-1], Bus, 0.1, Interfaces),
    % The weight does not move: the local zero wins over the global one.
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    assertion(Weight =:= 0.5).

% SLICE 31: the reward step spends each trace at the RECEIVING end's territory concentration.
test(the_reward_step_reads_the_receiving_territory_level) :-
    % A bus whose diffuse dopamine field is one, but whose territory b holds only a half concentration.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus1),
    neuromodulator_bus_broadcast_territory(Bus1, dopamine, b, 0.5, Bus),
    % Two transmissive interfaces with full traces: one into territory b, one into the unmarked territory c.
    Interfaces0 = [interface(a, b, 0.5, 1, transmissive), interface(a, c, 0.5, 1, transmissive)],
    plasticity_engine_reward_step(Interfaces0, [(a-b)-1, (a-c)-1], Bus, 0.1, Interfaces),
    % Territory b learns by its local half; territory c learns by the diffuse field of one.
    Interfaces = [interface(a, b, WeightB, 1, transmissive), interface(a, c, WeightC, 1, transmissive)],
    assertion(plasticity_test_close(WeightB, 0.55)),
    assertion(plasticity_test_close(WeightC, 0.6)).

% SLICE 31: a silenced territory spends its trace into nothing, even under a global reward.
test(a_silent_territory_spends_its_trace_into_nothing) :-
    % A bus broadcasting full dopamine globally but explicitly silencing territory b.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus1),
    neuromodulator_bus_broadcast_territory(Bus1, dopamine, b, 0, Bus),
    % One transmissive interface with a full trace into the silenced territory.
    Interfaces0 = [interface(a, b, 0.5, 1, transmissive)],
    plasticity_engine_reward_step(Interfaces0, [(a-b)-1], Bus, 0.1, Interfaces),
    % The weight does not move: however strong the trace, the local chemistry reads zero.
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    assertion(Weight =:= 0.5).

% SLICE 31: a receiving name that is not a plain atom is refused by the bus's own guard at the step.
test(a_compound_receiving_name_is_refused_at_the_step, error(domain_error(neuromodulator_bus_territory, f(b)))) :-
    % A bus carrying full dopamine.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus),
    % A compound receiving name could alias a bus key, so the territory read must throw.
    plasticity_engine_step([interface(a, f(b), 0.5, 1, transmissive)], [a-1], Bus, 0.1, _).

% SLICE 31: the reward step refuses the compound receiving name with the same voice.
test(a_compound_receiving_name_is_refused_at_the_reward_step, error(domain_error(neuromodulator_bus_territory, f(b)))) :-
    % A bus carrying full dopamine.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus),
    % The territory read at the receiving end must throw before any weight moves.
    plasticity_engine_reward_step([interface(a, f(b), 0.5, 1, transmissive)], [(a-f(b))-1], Bus, 0.1, _).

% SLICE 31 REVIEW PIN: an unbound kind is refused at the live step, never silently treated as non-learning.
test(an_unbound_kind_is_refused_at_the_step, error(instantiation_error)) :-
    % A bus carrying full dopamine.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus),
    % A variable kind must throw, not quietly keep its weight.
    plasticity_engine_step([interface(a, b, 0.5, 1, _)], [a-1, b-1], Bus, 0.1, _).

% SLICE 31 REVIEW PIN: a term that is not an interface is refused at the live step, never silently failed past.
test(a_malformed_interface_is_refused_at_the_step, error(domain_error(plasticity_engine_interface, junk))) :-
    % A bus carrying full dopamine.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus),
    % A stray atom in the interface list must throw, not make the whole step quietly fail.
    plasticity_engine_step([junk], [a-1], Bus, 0.1, _).

% SLICE 31 REVIEW PIN: a duplicate transmissive interface is refused at the live step, never double-learned.
test(a_duplicate_interface_is_refused_at_the_step, error(domain_error(plasticity_engine_duplicate_interface, a-b))) :-
    % A bus carrying full dopamine.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus),
    % The same endpoint pair twice must throw, not learn the same coincidence twice.
    plasticity_engine_step([interface(a, b, 0.5, 1, transmissive), interface(a, b, 0.5, 1, transmissive)],
                           [a-1, b-1], Bus, 0.1, _).

% SLICE 33: a region with its own activity target is scaled toward it, not the global one.
test(a_region_with_its_own_target_is_scaled_toward_it) :-
    % One transmissive interface into b, whose average of one sits above its OWN target of zero.
    Interfaces0 = [interface(a, b, 0.8, 1, transmissive)],
    plasticity_engine_scaling_step_territory(Interfaces0, [a-1, b-1], [b-0], 0.5, 0.1, Interfaces),
    % The weight shrinks by the LOCAL target's factor: 0.8 times (1 + 0.1 times (0 - 1)) is 0.72, not the global 0.76.
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    assertion(plasticity_test_close(Weight, 0.72)).

% SLICE 33: a region without its own target defends the global target, the exact diffuse fallback.
test(a_region_without_its_own_target_defends_the_global) :-
    % Two transmissive interfaces: one into the unmarked territory b, one into c which owns a target of one.
    Interfaces0 = [interface(a, b, 0.8, 1, transmissive), interface(a, c, 0.8, 1, transmissive)],
    plasticity_engine_scaling_step_territory(Interfaces0, [a-1, b-1, c-1], [c-1], 0.5, 0.1, Interfaces),
    % Territory b falls back to the global half target: 0.8 times (1 + 0.1 times (0.5 - 1)) is 0.76.
    Interfaces = [interface(a, b, WeightB, 1, transmissive), interface(a, c, WeightC, 1, transmissive)],
    assertion(plasticity_test_close(WeightB, 0.76)),
    % Territory c sits exactly at its own target of one, so its incoming weight does not move.
    assertion(plasticity_test_close(WeightC, 0.8)).

% SLICE 33: an empty target store is the exact old global behaviour - the fallback is an identity.
test(an_empty_target_store_is_the_exact_global_behaviour) :-
    % One transmissive interface into an overactive region.
    Interfaces0 = [interface(a, b, 0.8, 1, transmissive)],
    % The old global step and the new territory step with an empty geography.
    plasticity_engine_scaling_step(Interfaces0, [a-1, b-1], 0.5, 0.1, InterfacesGlobal),
    plasticity_engine_scaling_step_territory(Interfaces0, [a-1, b-1], [], 0.5, 0.1, InterfacesEmpty),
    % The two answers are identical, term for term.
    assertion(InterfacesGlobal == InterfacesEmpty).

% SLICE 33: a malformed target pair is refused by name, never silently skipped.
test(a_malformed_target_pair_is_refused_by_name, error(domain_error(plasticity_engine_target_pair, junk))) :-
    % A bare atom in the target store must throw.
    plasticity_engine_scaling_step_territory([interface(a, b, 0.8, 1, transmissive)], [a-1, b-1], [b-0.5, junk], 0.5, 0.1, _).

% SLICE 33: a duplicate target key is refused by name, never resolved by first-one-wins.
test(a_duplicate_target_key_is_refused_by_name, error(domain_error(plasticity_engine_duplicate_target, b))) :-
    % The same territory twice in the target store must throw.
    plasticity_engine_scaling_step_territory([interface(a, b, 0.8, 1, transmissive)], [a-1, b-1], [b-0.5, b-0.6], 0.5, 0.1, _).

% SLICE 33: a negative per-territory target is refused with the activity target's own voice.
test(a_negative_territory_target_is_refused_by_name, error(domain_error(plasticity_engine_activity_target, -0.5))) :-
    % No territory can defend an impossible set-point, local or global alike.
    plasticity_engine_scaling_step_territory([interface(a, b, 0.8, 1, transmissive)], [a-1, b-1], [b-(-0.5)], 0.5, 0.1, _).

% SLICE 33: an unbound target store is refused as uninstantiated, never walked off a cliff.
test(an_unbound_target_store_is_refused, error(instantiation_error)) :-
    % An unbound store must throw at once, not overflow the stack.
    plasticity_engine_scaling_step_territory([interface(a, b, 0.8, 1, transmissive)], [a-1, b-1], _, 0.5, 0.1, _).

% SLICE 33 REVIEW PIN: an unbound per-territory target value is refused as uninstantiated, never under a wrong it cannot name.
test(an_unbound_territory_target_value_is_refused, error(instantiation_error)) :-
    % A target pair whose value is a variable must throw instantiation_error, not a nameless domain error.
    plasticity_engine_scaling_step_territory([interface(a, b, 0.8, 1, transmissive)], [a-1, b-1], [b-_], 0.5, 0.1, _).

% SLICE 33 REVIEW PIN: an unbound global target is refused as uninstantiated, with the same one verdict.
test(an_unbound_global_target_is_refused, error(instantiation_error)) :-
    % An unbound global target must throw instantiation_error, never a domain error carrying a variable.
    plasticity_engine_scaling_step([interface(a, b, 0.8, 1, transmissive)], [a-1, b-1], _, 0.1, _).

% SLICE 33 REVIEW PIN: an unbound scaling rate is refused as uninstantiated, with the same one verdict.
test(an_unbound_scaling_rate_is_refused, error(instantiation_error)) :-
    % An unbound rate must throw instantiation_error, never a domain error carrying a variable.
    plasticity_engine_scaling_step([interface(a, b, 0.8, 1, transmissive)], [a-1, b-1], 0.5, _, _).

% SLICE 33 REVIEW PIN, MIRRORED ROOT: an unbound fading factor is refused as uninstantiated too.
test(an_unbound_fading_factor_is_refused, error(instantiation_error)) :-
    % The same root pattern lived in the fading-factor check; the same guard now holds it.
    plasticity_engine_trace_step([interface(a, b, 0.5, 1, transmissive)], [a-1, b-1], _, [(a-b)-0], _).

% SLICE 33 REVIEW PIN, MIRRORED ROOT: an unbound smoothing factor is refused as uninstantiated too.
test(an_unbound_smoothing_factor_is_refused, error(instantiation_error)) :-
    % The same root pattern lived in the smoothing-factor check; the same guard now holds it.
    plasticity_engine_average_step([a-1], _, [a-0], _).

% SLICE 36: the reward-capture step - the corpus's tag-and-capture law made live. Capture is the
% delivery: a nonzero third factor at the receiving territory spends the trace into the weight AND
% consumes the tag, because a used address must expire so the synapse cannot wrongly capture a
% later, unrelated shipment (Layers 4-5 dossier, Chapters 5 and 6). A zero third factor ships no
% cargo: the weight stands and the tag stands, left to fade on its own clock.

% Capture spends the trace into the weight and consumes the tag in the same act.
test(capture_spends_the_trace_into_the_weight_and_consumes_the_tag) :-
    % A bus carrying a full dopamine reward.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus),
    % One transmissive interface with a starting weight of one half and a trace of nine tenths.
    plasticity_engine_reward_capture_step([interface(a, b, 0.5, 1, transmissive)], [(a-b)-0.9], Bus, 0.1, Interfaces, Traces),
    % The weight grew by the trace times the third factor times the rate: nine hundredths.
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    assertion(plasticity_test_close(Weight, 0.59)),
    % The spent tag is consumed to zero, never left to be captured twice.
    assertion(Traces == [(a-b)-0]).

% Without dopamine nothing ships, so the weight stands and the tag stands.
test(no_dopamine_ships_no_cargo_and_the_tag_stands) :-
    % A bus with no dopamine, so the third factor reads zero.
    neuromodulator_bus_new(Bus),
    % One transmissive interface with a full trace.
    plasticity_engine_reward_capture_step([interface(a, b, 0.5, 1, transmissive)], [(a-b)-1], Bus, 0.1, Interfaces, Traces),
    % The weight is unchanged; no cargo arrived.
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    assertion(Weight =:= 0.5),
    % The unspent tag survives, left to fade on its own clock.
    assertion(Traces == [(a-b)-1]).

% A computational interface carries no tag and is untouched by capture.
test(a_computational_interface_is_untouched_by_capture) :-
    % A bus carrying full dopamine.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus),
    % One computational interface beside one transmissive interface with a live tag.
    plasticity_engine_reward_capture_step([interface(a, b, 0.5, 1, computational), interface(b, c, 0.5, 1, transmissive)],
                                          [(b-c)-1], Bus, 0.1, Interfaces, Traces),
    % The computational weight is unchanged; the transmissive one captured.
    Interfaces = [interface(a, b, WeightComputational, 1, computational), interface(b, c, WeightTransmissive, 1, transmissive)],
    assertion(WeightComputational =:= 0.5),
    assertion(plasticity_test_close(WeightTransmissive, 0.6)),
    % Only the transmissive interface's tag exists, and it was consumed.
    assertion(Traces == [(b-c)-0]).

% Capture reads the third factor at the RECEIVING end's territory, local chemistry first.
test(capture_reads_the_receiving_territory) :-
    % A bus whose global dopamine is one but whose territory b holds one half.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus1),
    neuromodulator_bus_broadcast_territory(Bus1, dopamine, b, 0.5, Bus),
    % One transmissive interface into territory b with a full tag.
    plasticity_engine_reward_capture_step([interface(a, b, 0.5, 1, transmissive)], [(a-b)-1], Bus, 0.1, Interfaces, Traces),
    % The weight grew by the LOCAL half-strength dopamine, not the global one: five hundredths.
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    assertion(plasticity_test_close(Weight, 0.55)),
    % The tag was spent at the local level and is consumed.
    assertion(Traces == [(a-b)-0]).

% A territory holding zero dopamine over a live global field ships nothing to its own synapses.
test(a_zero_territory_over_a_live_global_keeps_its_tag) :-
    % A bus whose global dopamine is one but whose territory b holds exactly zero.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus1),
    neuromodulator_bus_broadcast_territory(Bus1, dopamine, b, 0, Bus),
    % One transmissive interface into the silenced territory, with a full tag.
    plasticity_engine_reward_capture_step([interface(a, b, 0.5, 1, transmissive)], [(a-b)-1], Bus, 0.1, Interfaces, Traces),
    % The local zero wins over the global one: the weight stands.
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    assertion(Weight =:= 0.5),
    % And the tag stands, unspent.
    assertion(Traces == [(a-b)-1]).

% The capture step refuses a ghost trace as loudly as its siblings do.
test(a_ghost_trace_is_refused_by_name_at_the_capture_step, error(existence_error(plasticity_engine_trace, a-b))) :-
    % A bus carrying dopamine.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus),
    % The trace store is empty, so the interface's tag does not exist.
    plasticity_engine_reward_capture_step([interface(a, b, 0.5, 1, transmissive)], [], Bus, 0.1, _, _).

% The capture step refuses an unknown interface kind with the shared perimeter's voice.
test(an_unknown_kind_is_refused_by_name_at_the_capture_step, error(domain_error(plasticity_engine_interface_kind, mystery))) :-
    % A bus carrying dopamine.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus),
    % A kind no slice has defined must throw at the capture step.
    plasticity_engine_reward_capture_step([interface(a, b, 0.5, 1, mystery)], [], Bus, 0.1, _, _).

% HOUSE VAR GUARD (the standing unbound-wrong-judgement lens, and Observation-5's shape): an unbound
% bus is refused as uninstantiated, never silently bound into an invented partial bus by the reads below.
test(an_unbound_bus_is_refused_at_the_capture_step, error(instantiation_error)) :-
    % An unbound bus cannot be judged, and must never be silently bound by the chemical reads.
    plasticity_engine_reward_capture_step([interface(a, b, 0.5, 1, transmissive)], [(a-b)-1], _, 0.1, _, _).

% Punishment is a shipment too: a negative third factor spends the tag downward and consumes it.
test(a_negative_third_factor_spends_the_tag_downward_and_consumes_it) :-
    % A bus carrying a full NEGATIVE dopamine level: the error rose, the tick punishes.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, -1, Bus),
    % One transmissive interface with a full tag.
    plasticity_engine_reward_capture_step([interface(a, b, 0.5, 1, transmissive)], [(a-b)-1], Bus, 0.1, Interfaces, Traces),
    % The weight fell by the tag times the signed third factor times the rate: to four tenths.
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    assertion(plasticity_test_close(Weight, 0.4)),
    % The punished tag is just as spent as a rewarded one.
    assertion(Traces == [(a-b)-0]).

% SLICE 36 REVIEW PIN: an unbound weight is refused aloud even on a rewardless tick.
test(an_unbound_weight_is_refused_at_the_capture_step_without_dopamine, error(instantiation_error)) :-
    % A bus with no dopamine: the zero branch must judge as loudly as the spending branch.
    neuromodulator_bus_new(Bus),
    plasticity_engine_reward_capture_step([interface(a, b, _, 1, transmissive)], [(a-b)-1], Bus, 0.1, _, _).

% SLICE 36 REVIEW PIN: an unbound learning rate is refused aloud even on a rewardless tick.
test(an_unbound_learning_rate_is_refused_at_the_capture_step_without_dopamine, error(instantiation_error)) :-
    % A bus with no dopamine: the rate is judged on every path, never only when cargo ships.
    neuromodulator_bus_new(Bus),
    plasticity_engine_reward_capture_step([interface(a, b, 0.5, 1, transmissive)], [(a-b)-1], Bus, _, _, _).

% SLICE 36 REVIEW PIN: an unbound trace value is refused aloud even on a rewardless tick.
test(an_unbound_trace_value_is_refused_at_the_capture_step_without_dopamine, error(instantiation_error)) :-
    % A bus with no dopamine: an unbound tag can be neither spent nor kept, only refused.
    neuromodulator_bus_new(Bus),
    plasticity_engine_reward_capture_step([interface(a, b, 0.5, 1, transmissive)], [(a-b)-_], Bus, 0.1, _, _).

% Close the test block for the plasticity_engine pack.
:- end_tests(plasticity_engine).
