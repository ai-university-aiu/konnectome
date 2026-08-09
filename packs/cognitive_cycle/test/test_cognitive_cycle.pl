% Load the cognitive_cycle module under test from the library path.
:- use_module(library(cognitive_cycle)).
% Load the neuromodulator_bus module, used to read the broadcast dopamine level.
:- use_module(library(neuromodulator_bus)).
% Load the list utilities used to gather recorded thought identifiers.
:- use_module(library(lists), [member/2]).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% A fixed starting world, so every test is deterministic and reproducible.
cognitive_cycle_test_world(World) :-
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

% Close the test block for the cognitive_cycle pack.
:- end_tests(cognitive_cycle).
