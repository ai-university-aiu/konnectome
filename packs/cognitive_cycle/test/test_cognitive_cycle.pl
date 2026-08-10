% Load the cognitive_cycle module under test from the library path.
:- use_module(library(cognitive_cycle)).
% Load the neuromodulator_bus module, used to read the broadcast dopamine level.
:- use_module(library(neuromodulator_bus)).
% Load the two_process_governor module, used to boot the world's night watchman.
:- use_module(library(two_process_governor)).
% Load the list utilities used to gather recorded thought identifiers.
:- use_module(library(lists), [member/2]).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% A fixed starting world, so every test is deterministic and reproducible.
cognitive_cycle_test_world(World) :-
    % The default two-process governor: the day's watchman, holding online through a short test run.
    two_process_governor_new(Governor),
    % A minimal but complete world: one drive, one two-construct connection, the body away from set-point,
    % and since slice 32 the whole learning body's state - the trace store, the average store, and the
    % four constants that beat them - with the slow scaling bound armed but at rest (rate zero).
    World = world{ tick: 0,
                   body: [temperature-40],
                   drives: [drive(temperature, temperature, 37, none)],
                   bus: [],
                   constructs: [construct(a, source), construct(b, relay(1))],
                   activations: [a-1, b-0],
                   interfaces: [interface(a, b, 0.5, 1, transmissive)],
                   traces: [(a-b)-0],
                   averages: [a-0, b-0],
                   fading_factor: 0.6,
                   smoothing_factor: 0.2,
                   scaling_target: 0.5,
                   scaling_targets: [],
                   scaling_rate: 0.0,
                   overrides: [],
                   override_threshold: 0.5,
                   learning_rate: 0.1,
                   governor: Governor,
                   simulation_start: "2026-07-20T00:00:00Z" }.

% Open the test block for the cognitive_cycle pack.
:- begin_tests(cognitive_cycle).

% The closed loop drives the body to its set-point and learns along the way.
test(the_closed_loop_drives_the_body_to_its_set_point_and_learns) :-
    % Start from the fixed world (the body sits at forty, its set-point is thirty-seven).
    cognitive_cycle_test_world(World0),
    % Run six ticks: enough for the body to close the gap and settle.
    cognitive_cycle_run(World0, 6, WorldFinal, Summaries),
    % The body converged to its set-point, driven there by the released reduce action each tick.
    get_dict(body, WorldFinal, Body),
    % Confirm the body settled at the set-point.
    assertion(Body == [temperature-37]),
    % While the body improved, the reward flowed and the active connection learned.
    get_dict(interfaces, WorldFinal, [interface(a, b, Weight, 1, transmissive)]),
    % Confirm the weight grew above its starting one half.
    assertion(Weight > 0.5),
    % Each tick recorded its own distinct Causalontology thought.
    findall(Id, (member(tick_summary(_N, _R, _A, Record), Summaries), get_dict(id, Record, Id)), Ids),
    % Deduplicate the identifiers.
    sort(Ids, Unique),
    % All six are distinct.
    assertion(length(Unique, 6)).

% When the body improves, the reward becomes dopamine on the bus.
test(reward_becomes_dopamine_when_the_body_improves) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(World0),
    % Run two ticks.
    cognitive_cycle_run(World0, 2, World2, Summaries),
    % Bind the two tick summaries.
    Summaries = [tick_summary(1, Reward1, _A1, _R1), tick_summary(2, Reward2, _A2, _R2)],
    % The first tick has no previous error, so its reward is zero.
    assertion(Reward1 =:= 0),
    % The second tick's body improved by one, so its reward is one.
    assertion(Reward2 =:= 1),
    % That reward was broadcast as dopamine on the bus.
    get_dict(bus, World2, Bus2),
    neuromodulator_bus_level(Bus2, dopamine, Dopamine),
    % Confirm the dopamine equals the reward.
    assertion(Dopamine =:= 1).

% A vital drive in distress overrides the normal reduce action (the safety property, end to end).
test(a_vital_drive_in_distress_overrides_the_normal_action) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(Base),
    % Add a respiration drive in distress.
    put_dict(overrides, Base, [override(respiration, 0, 0.9, breathe)], World0),
    % Run one tick.
    cognitive_cycle_step(World0, _World1, tick_summary(_Tick, _Reward, Action, _Record)),
    % Breathing overrides the normal reduce action.
    assertion(Action == released(breathe)).

% The whole closed loop is reproducible: the same world run twice yields the identical result.
test(the_cycle_is_reproducible) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(World0),
    % Run it once.
    cognitive_cycle_run(World0, 4, WorldA, _SummariesA),
    % Run it again with the same inputs.
    cognitive_cycle_run(World0, 4, WorldB, _SummariesB),
    % The learned interfaces are identical.
    get_dict(interfaces, WorldA, InterfacesA),
    get_dict(interfaces, WorldB, InterfacesB),
    % Confirm the weights match.
    assertion(InterfacesA == InterfacesB),
    % The bodies are identical.
    get_dict(body, WorldA, BodyA),
    get_dict(body, WorldB, BodyB),
    % Confirm the bodies match.
    assertion(BodyA == BodyB).

% The live tick advances the eligibility-trace store: coincidence leaves its fading fingerprint.
test(the_live_tick_advances_the_trace_store) :-
    % Start from the fixed world, whose one trace sits at zero.
    cognitive_cycle_test_world(World0),
    % Run two ticks, enough for the relay end to wake and the coincidence to register.
    cognitive_cycle_run(World0, 2, WorldFinal, _Summaries),
    % Read the trace store the tick now carries.
    get_dict(traces, WorldFinal, Traces),
    % The one learnable interface's trace accumulated a positive coincidence.
    Traces = [(a-b)-Trace],
    % Confirm the trace rose above its starting zero.
    assertion(Trace > 0).

% The live tick moves the running averages toward each construct's activity.
test(the_live_tick_moves_the_running_averages) :-
    % Start from the fixed world, whose averages sit at zero.
    cognitive_cycle_test_world(World0),
    % Run three ticks, so the smoothing steps have something to smooth.
    cognitive_cycle_run(World0, 3, WorldFinal, _Summaries),
    % Read the average store the tick now carries.
    get_dict(averages, WorldFinal, Averages),
    % The source construct held its activity at one, so its average climbed toward one.
    memberchk(a-AverageOfSource, Averages),
    % Confirm the source's average rose above its starting zero.
    assertion(AverageOfSource > 0),
    % Confirm the average is still an average, not a copy: it has not overshot the activity.
    assertion(AverageOfSource =< 1).

% With the scaling rate at zero the slow bound is armed but at rest: the target cannot matter.
test(scaling_at_rest_leaves_the_weights_to_learning_alone) :-
    % Start from the fixed world, whose scaling rate is zero.
    cognitive_cycle_test_world(World0),
    % Make a twin world differing only in an absurd activity target.
    put_dict(scaling_target, World0, 1000, WorldAbsurd0),
    % Run both worlds the same four ticks.
    cognitive_cycle_run(World0, 4, WorldA, _SummariesA),
    cognitive_cycle_run(WorldAbsurd0, 4, WorldB, _SummariesB),
    % Read both final interface lists.
    get_dict(interfaces, WorldA, InterfacesA),
    get_dict(interfaces, WorldB, InterfacesB),
    % At rate zero the target is scenery: the learned weights are identical.
    assertion(InterfacesA == InterfacesB).

% With a live scaling rate the slow bound beats: a quiet region's incoming weight is pulled up.
test(a_live_scaling_rate_bends_the_weights) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(World0),
    % Make a twin world differing only in a live scaling rate.
    put_dict(scaling_rate, World0, 0.2, WorldLive0),
    % Run both worlds the same four ticks.
    cognitive_cycle_run(World0, 4, WorldRest, _SummariesRest),
    cognitive_cycle_run(WorldLive0, 4, WorldLive, _SummariesLive),
    % Read both final weights on the one learnable interface.
    get_dict(interfaces, WorldRest, [interface(a, b, WeightRest, 1, transmissive)]),
    get_dict(interfaces, WorldLive, [interface(a, b, WeightLive, 1, transmissive)]),
    % The live bound moved the weight where the resting bound could not.
    assertion(WeightLive =\= WeightRest),
    % The receiving relay sat below the one-half target, so its incoming weight was pulled UP.
    assertion(WeightLive > WeightRest).

% SLICE 33: a per-territory target bends its own region's weights harder than the global target.
test(a_territory_target_bends_its_own_region) :-
    % Start from the fixed world with a live scaling rate.
    cognitive_cycle_test_world(World0),
    put_dict(scaling_rate, World0, 0.2, WorldLive0),
    % Make a twin world differing only in a per-territory target of one for the quiet relay b.
    put_dict(scaling_targets, WorldLive0, [b-1], WorldTerritory0),
    % Run both worlds the same four ticks.
    cognitive_cycle_run(WorldLive0, 4, WorldGlobal, _SummariesGlobal),
    cognitive_cycle_run(WorldTerritory0, 4, WorldTerritory, _SummariesTerritory),
    % Read both final weights on the one learnable interface into b.
    get_dict(interfaces, WorldGlobal, [interface(a, b, WeightGlobal, 1, transmissive)]),
    get_dict(interfaces, WorldTerritory, [interface(a, b, WeightTerritory, 1, transmissive)]),
    % The relay sits below both targets, but its own higher target of one pulls its incoming weight up harder.
    assertion(WeightTerritory > WeightGlobal).

% SLICE 33: at rate zero even an absurd per-territory target is scenery - the at-rest identity holds.
test(a_territory_target_at_rest_changes_nothing) :-
    % Start from the fixed world, whose scaling rate is zero.
    cognitive_cycle_test_world(World0),
    % Make a twin world differing only in an absurd per-territory target for the relay.
    put_dict(scaling_targets, World0, [b-1000], WorldAbsurd0),
    % Run both worlds the same four ticks.
    cognitive_cycle_run(World0, 4, WorldA, _SummariesA),
    cognitive_cycle_run(WorldAbsurd0, 4, WorldB, _SummariesB),
    % Read both final interface lists.
    get_dict(interfaces, WorldA, InterfacesA),
    get_dict(interfaces, WorldB, InterfacesB),
    % At rate zero the geography is scenery: the learned weights are identical.
    assertion(InterfacesA == InterfacesB).

% A world missing any of the learning body's keys is refused aloud, never silently failed.
test(a_world_missing_a_learning_store_is_refused_aloud) :-
    % Every key the slice-32 tick reads must be present, or the tick refuses by name.
    forall(member(Key, [traces, averages, fading_factor, smoothing_factor, scaling_target, scaling_targets, scaling_rate]),
           ( % Start from the fixed world.
             cognitive_cycle_test_world(World0),
             % Remove exactly one of the learning body's keys.
             del_dict(Key, World0, _Value, WorldMissing),
             % The tick refuses the gutted world by the missing key's name.
             catch(cognitive_cycle_step(WorldMissing, _World, _Summary), error(Error, _), true),
             % Confirm the refusal names the key.
             Error == existence_error(cognitive_cycle_world_key, Key)
           )).

% SLICE 36: the reward step beats in the live tick - the tick spends the eligibility traces the
% moment its own drives declare a reward, and capture consumes the spent tags (the Layers 4-5
% dossier's tag-and-capture law, Chapters 5 and 6). Twin-world tellings, so each claim is a
% difference the wiring alone can make.

% A standing trace is spent into the weight on the first rewarded tick: the wiring is live.
test(the_live_tick_spends_a_standing_trace_when_reward_arrives) :-
    % Two twin worlds differing only in one pre-existing eligibility trace.
    cognitive_cycle_test_world(WorldZero0),
    put_dict(traces, WorldZero0, [(a-b)-5], WorldTagged0),
    % Run both twins two ticks: the first tick's reward is zero, the second tick's reward is one.
    cognitive_cycle_run(WorldZero0, 2, WorldZero, _SummariesZero),
    cognitive_cycle_run(WorldTagged0, 2, WorldTagged, _SummariesTagged),
    % Read both final weights on the one learnable interface.
    get_dict(interfaces, WorldZero, [interface(a, b, WeightZero, 1, transmissive)]),
    get_dict(interfaces, WorldTagged, [interface(a, b, WeightTagged, 1, transmissive)]),
    % The standing tag was spent into the weight when the reward arrived: the tagged twin learned more.
    assertion(WeightTagged > WeightZero).

% Capture consumes the spent tags: after one rewarded tick the twins' trace stores are identical.
test(the_live_tick_consumes_the_spent_tags) :-
    % The same two twin worlds, differing only in one pre-existing eligibility trace.
    cognitive_cycle_test_world(WorldZero0),
    put_dict(traces, WorldZero0, [(a-b)-5], WorldTagged0),
    % Run both twins two ticks, through the first rewarded tick.
    cognitive_cycle_run(WorldZero0, 2, WorldZero, _SummariesZero),
    cognitive_cycle_run(WorldTagged0, 2, WorldTagged, _SummariesTagged),
    % Read both final trace stores.
    get_dict(traces, WorldZero, TracesZero),
    get_dict(traces, WorldTagged, TracesTagged),
    % The rewarded tick consumed both histories, so only the same fresh coincidence remains in each.
    assertion(TracesZero == TracesTagged).

% A body already at its set-point rewards nothing, ships nothing, and spends nothing: the tag stands.
test(a_rewardless_tick_spends_no_tag) :-
    % Two twin worlds whose body already rests at its set-point, differing only in a standing tag.
    cognitive_cycle_test_world(Base),
    put_dict(body, Base, [temperature-37], WorldRest0),
    put_dict(traces, WorldRest0, [(a-b)-5], WorldRestTagged0),
    % Run both twins two ticks: every reward is zero, so no cargo ever ships.
    cognitive_cycle_run(WorldRest0, 2, WorldRest, _SummariesRest),
    cognitive_cycle_run(WorldRestTagged0, 2, WorldRestTagged, _SummariesRestTagged),
    % Read both final weights on the one learnable interface.
    get_dict(interfaces, WorldRest, [interface(a, b, WeightRest, 1, transmissive)]),
    get_dict(interfaces, WorldRestTagged, [interface(a, b, WeightRestTagged, 1, transmissive)]),
    % With no reward the standing tag buys nothing: the weights are identical.
    assertion(WeightRest =:= WeightRestTagged),
    % And the standing tag was not consumed - it fades on its own clock, twice by the fading factor.
    get_dict(traces, WorldRestTagged, TracesTagged),
    TracesTagged = [(a-b)-TraceTagged],
    get_dict(traces, WorldRest, [(a-b)-TraceZeroHistory]),
    % The tagged twin's trace still carries its faded history above the zero-history twin's.
    assertion(TraceTagged > TraceZeroHistory).

% A negative tick count is refused aloud, never answered by a silent failure (the slice-32 review pin).
test(a_negative_tick_count_is_refused_aloud,
     [ error(domain_error(cognitive_cycle_tick_count, -1)) ]) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(World0),
    % Time never runs backward: the run refuses the count by name.
    cognitive_cycle_run(World0, -1, _WorldFinal, _Summaries).

% A tick count that is not a whole number is refused aloud, never by a stray arithmetic error (review pin).
test(a_non_integer_tick_count_is_refused_aloud,
     [ error(domain_error(cognitive_cycle_tick_count, banana)) ]) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(World0),
    % Time moves in whole ticks: the run refuses the count by name.
    cognitive_cycle_run(World0, banana, _WorldFinal, _Summaries).

% SLICE 37: the two-process governor rides the live tick - the first legitimate thrower of the
% slice-35 switch. Each tick the governor reads the switch, advances the rising sleep pressure and
% the circadian day wave, and announces its selection back onto the bus for every subscriber.

% The default governor holds the short test day online: the switch reads online after a run.
test(the_default_governor_holds_a_short_day_online) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(World0),
    % Run six ticks, a short morning.
    cognitive_cycle_run(World0, 6, WorldFinal, _Summaries),
    % Read the switch off the final bus.
    get_dict(bus, WorldFinal, Bus),
    % The state the governor announced is the one every subscriber reads.
    neuromodulator_bus_operating_state(Bus, State),
    % Six ticks of debt cannot beat the default sixteen-point threshold: the day holds.
    assertion(State == online).

% The governor advances in the world: its pressure carries the run's whole waking debt.
test(the_governor_advances_in_the_world) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(World0),
    % Run six ticks.
    cognitive_cycle_run(World0, 6, WorldFinal, _Summaries),
    % Read the governor out of the final world.
    get_dict(governor, WorldFinal, Governor),
    % Read its standing sleep pressure.
    two_process_governor_pressure(Governor, Pressure),
    % Six online ticks at the default rise of one leave a debt of six.
    assertion(Pressure =:= 6).

% A fast-flipping governor throws the switch in the live tick: the first legitimate thrower throws.
test(the_tick_throws_the_switch_when_the_debt_wins) :-
    % Build a governor whose sleep threshold falls to a three-tick day, with no circadian opposition.
    two_process_governor_new(two_process_parameters(1, 2, 24, 0, 3, 0), FastGovernor),
    % Start from the fixed world carrying the fast governor.
    cognitive_cycle_test_world(Base),
    % Swap the watchman for the fast one.
    put_dict(governor, Base, FastGovernor, World0),
    % Run three ticks, exactly enough debt to reach the threshold.
    cognitive_cycle_run(World0, 3, WorldFinal, _Summaries),
    % Read the switch off the final bus.
    get_dict(bus, WorldFinal, Bus),
    % The state the governor announced is the one every subscriber reads.
    neuromodulator_bus_operating_state(Bus, State),
    % The debt won: the switch stands offline, thrown by the governor in the live tick.
    assertion(State == offline).

% The thrown switch changes nothing else this slice: the twin runs agree on every other world piece.
test(the_thrown_switch_moves_no_other_world_piece) :-
    % Build the same fast-flipping governor.
    two_process_governor_new(two_process_parameters(1, 2, 24, 0, 3, 0), FastGovernor),
    % The default twin.
    cognitive_cycle_test_world(WorldSlow0),
    % The fast twin, differing only in its watchman.
    cognitive_cycle_test_world(Base),
    % Swap the watchman for the fast one.
    put_dict(governor, Base, FastGovernor, WorldFast0),
    % Run the default twin four ticks.
    cognitive_cycle_run(WorldSlow0, 4, WorldSlow, _SummariesSlow),
    % Run the fast twin the same four ticks, through its flip.
    cognitive_cycle_run(WorldFast0, 4, WorldFast, _SummariesFast),
    % Read the default twin's body.
    get_dict(body, WorldSlow, Body),
    % The bodies agree: nothing downstream of the switch reads it yet.
    get_dict(body, WorldFast, Body),
    % Read the default twin's weights.
    get_dict(interfaces, WorldSlow, Interfaces),
    % The weights agree.
    get_dict(interfaces, WorldFast, Interfaces),
    % Read the default twin's traces.
    get_dict(traces, WorldSlow, Traces),
    % The traces agree.
    get_dict(traces, WorldFast, Traces),
    % Read the default twin's averages.
    get_dict(averages, WorldSlow, Averages),
    % The averages agree.
    get_dict(averages, WorldFast, Averages),
    % Read the default twin's activations.
    get_dict(activations, WorldSlow, Activations),
    % The activations agree.
    get_dict(activations, WorldFast, Activations).

% A world missing its governor is refused aloud, never silently run without a watchman.
test(a_world_missing_its_governor_is_refused_aloud) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(World0),
    % Remove the governor.
    del_dict(governor, World0, _Value, WorldMissing),
    % The tick refuses the gutted world by the missing key's name.
    catch(cognitive_cycle_step(WorldMissing, _World, _Summary), error(Error, _), true),
    % Confirm the refusal names the key.
    assertion(Error == existence_error(cognitive_cycle_world_key, governor)).

% Close the test block for the cognitive_cycle pack.
:- end_tests(cognitive_cycle).
