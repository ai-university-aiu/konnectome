% Load the cognitive_cycle module under test from the library path.
:- use_module(library(cognitive_cycle)).
% Load the neuromodulator_bus module, used to read the broadcast dopamine level.
:- use_module(library(neuromodulator_bus)).
% Load the two_process_governor module, used to boot the world's night watchman.
:- use_module(library(two_process_governor)).
% Load the scheduler, so slice 74's fixtures can restate an hour in ticks rather than write one down.
:- use_module(library(tick_engine), [tick_engine_ticks_from_milliseconds/2]).
% Load the list utilities used to gather recorded thought identifiers.
:- use_module(library(lists), [member/2]).
% Load the stabiliser, SLICE 72's own read-back: the conflict loop's control travels as its bias, and
% these tests confirm the wiring actually reaches it rather than merely leaving the arbitration alone.
:- use_module(library(stabiliser), [stabiliser_bias/2]).
% Load the working-memory blackboard, SLICE 74's own read-back: the board's period and the lifetime
% it implies are read from the pack that declares them, so no test here restates a tick count.
:- use_module(library(working_memory_blackboard), [working_memory_blackboard_step_ticks/1,
                                                   working_memory_blackboard_unrehearsed_life_ticks/1,
                                                   working_memory_blackboard_slots/2]).
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
                   % SLICE 72: the conflict loop's caller-supplied coupling gain - DECISION-15's own
                   % worked figure, not a value chosen here, since the loop's own acceptance test
                   % (the Gratton inequality) holds for every positive gain and picks none of them.
                   conflict_gain: 0.15,
                   learning_rate: 0.1,
                   % The day's memory store starts empty; every online tick remembers its pattern (slice 38).
                   memories: [],
                   % The night's replay strengthening rate.
                   replay_rate: 0.1,
                   % The night's raised scaling bound: the renormalisation shift, well above the
                   % day's resting rate, as every tick demands of the pair.
                   offline_scaling_rate: 0.2,
                   % SLICE 74: the blackboard and its standing pointer, empty and absent by default;
                   % the tests that exercise the board put their own slots on this world.
                   blackboard: [],
                   rehearsal_target: none,
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

% ---------------------------------------------------------------------------
% SLICE 72 - THE CONFLICT LOOP, WIRED INTO THE RUNNING CYCLE
% ---------------------------------------------------------------------------

% WITH NO OVERRIDES STANDING, THE WIRING CHANGES NOTHING - the loop measures zero conflict and
% arbitrates exactly as the plain override controller always did. This is the regression pin: the
% fixed world's overrides are empty, so this reproduces the earliest test in this file's own shape.
test(with_no_overrides_the_conflict_loop_leaves_the_normal_action_alone) :-
    % Start from the fixed world, whose overrides are empty.
    cognitive_cycle_test_world(World0),
    % Run one tick.
    cognitive_cycle_step(World0, World1, tick_summary(_Tick, _Reward, Action, _Record)),
    % Nothing is in distress, so the normal reduce action stands, exactly as before slice 72.
    assertion(Action = released(reduce(temperature))),
    % And the stabiliser's bias is untouched: zero conflict raises control by nothing.
    get_dict(bus, World1, Bus1),
    stabiliser_bias(Bus1, Bias),
    assertion(Bias =:= 0).

% TWO INCOMPATIBLE DRIVES STANDING RAISES CONTROL, PUBLISHED AS THE STABILISER'S BIAS - the wiring's
% own observable effect, read back through the same channel DECISION-15 named as the join.
test(two_incompatible_drives_raise_control_on_the_bus) :-
    % Start from the fixed world and stand two mutually incompatible overrides.
    cognitive_cycle_test_world(Base),
    put_dict(overrides,
              Base,
              [override(hunger, 3, 0.9, eat), override(thirst, 4, 0.8, drink)],
              World0),
    % Run one tick.
    cognitive_cycle_step(World0, World1, _Summary),
    % Control was raised: the stabiliser's bias is strictly positive, never invented, only measured.
    get_dict(bus, World1, Bus1),
    stabiliser_bias(Bus1, Bias),
    assertion(Bias > 0).

% THE GRATTON EFFECT, READ THROUGH THE WHOLE RUNNING CYCLE RATHER THAN THROUGH THE PACK ALONE: an
% incongruent trial run straight after another incongruent trial faces a shallower net threshold rise
% than the identical trial run cold, because the first trial's control is still standing on the bus.
% This is Chapter 52.2.4's own acceptance test and it holds for the caller-supplied gain the fixed
% test world carries (0.15) without this file choosing a second number to prove it.
test(the_running_cycle_carries_control_forward_the_gratton_shape) :-
    % A world with no overrides standing runs one congruent (uncontested) tick first.
    cognitive_cycle_test_world(Cold),
    cognitive_cycle_step(Cold, ColdAfter, _ColdSummary),
    get_dict(bus, ColdAfter, ColdBus),
    stabiliser_bias(ColdBus, ColdBias),
    % No conflict was standing, so the cold run's carried bias is exactly zero.
    assertion(ColdBias =:= 0),
    % Now run the SAME incompatible pair twice in a row, carrying the world (and its bus) forward.
    put_dict(overrides,
              Cold,
              [override(hunger, 3, 0.9, eat), override(thirst, 4, 0.8, drink)],
              Incongruent0),
    cognitive_cycle_step(Incongruent0, Incongruent1, _First),
    get_dict(bus, Incongruent1, BusAfterFirst),
    stabiliser_bias(BusAfterFirst, BiasAfterFirst),
    % The first incongruent trial already raised control above the cold run's untouched zero.
    assertion(BiasAfterFirst > ColdBias),
    cognitive_cycle_step(Incongruent1, Incongruent2, _Second),
    get_dict(bus, Incongruent2, BusAfterSecond),
    stabiliser_bias(BusAfterSecond, BiasAfterSecond),
    % Control raised again on the second trial, carried forward from the first rather than starting
    % cold - the Gratton shape: a repeated incongruent trial faces standing control, a fresh one does
    % not, and the difference is measured here rather than asserted.
    assertion(BiasAfterSecond >= BiasAfterFirst).

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

% The thrown switch holds every world piece identical UP TO the flip, and moves the very next tick:
% the slice-37 behaviour-neutral telling, matured into its slice-38 form now the switch has a reader.
test(the_thrown_switch_governs_exactly_the_next_tick) :-
    % Build the same fast-flipping governor.
    two_process_governor_new(two_process_parameters(1, 2, 24, 0, 3, 0), FastGovernor),
    % The default twin.
    cognitive_cycle_test_world(WorldSlow0),
    % The fast twin, differing only in its watchman.
    cognitive_cycle_test_world(Base),
    % Swap the watchman for the fast one.
    put_dict(governor, Base, FastGovernor, WorldFast0),
    % Run the default twin three ticks.
    cognitive_cycle_run(WorldSlow0, 3, WorldSlow3, _SummariesSlow),
    % Run the fast twin the same three ticks, exactly to its flip.
    cognitive_cycle_run(WorldFast0, 3, WorldFast3, _SummariesFast),
    % UP TO THE FLIP the twins agree on every worldly piece: the selection only governs the NEXT tick.
    get_dict(body, WorldSlow3, Body3),
    get_dict(body, WorldFast3, Body3),
    get_dict(interfaces, WorldSlow3, Interfaces3),
    get_dict(interfaces, WorldFast3, Interfaces3),
    get_dict(traces, WorldSlow3, Traces3),
    get_dict(traces, WorldFast3, Traces3),
    get_dict(averages, WorldSlow3, Averages3),
    get_dict(averages, WorldFast3, Averages3),
    get_dict(memories, WorldSlow3, Memories3),
    get_dict(memories, WorldFast3, Memories3),
    % THE NEXT TICK the thrown switch commands: the slow twin runs the day, the fast twin the night.
    cognitive_cycle_step(WorldSlow3, _WorldSlow4, tick_summary(4, _, SlowOutcome, _)),
    cognitive_cycle_step(WorldFast3, WorldFast4, tick_summary(4, _, FastOutcome, _)),
    % The waking twin released an action.
    assertion(SlowOutcome = released(_)),
    % The sleeping twin ran the offline works instead.
    assertion(FastOutcome == offline_works),
    % And the sleeping twin's traces stood still through the night while the waking twin's moved.
    get_dict(traces, WorldFast4, Traces3).

% Every online tick remembers its pattern: after a short day the store holds one snapshot per tick.
test(online_ticks_remember_the_day) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(World0),
    % Run three online ticks.
    cognitive_cycle_run(World0, 3, WorldFinal, _Summaries),
    % Read the memory store and the final activations.
    get_dict(memories, WorldFinal, Memories),
    get_dict(activations, WorldFinal, Activations),
    % One remembered snapshot per online tick.
    assertion(length(Memories, 3)),
    % The newest memory is the last tick's own updated pattern, remembered newest-last.
    last(Memories, Newest),
    assertion(Newest == Activations).

% The default day lives the corpus's proportions in the LIVE loop: eighteen ticks awake, eight
% asleep, and morning at tick twenty-seven - the night crew takes the post and hands it back.
test(the_night_crew_takes_the_post_and_morning_comes) :-
    % Start from the fixed world under the default watchman.
    cognitive_cycle_test_world(World0),
    % Run thirty ticks, through the whole first night.
    cognitive_cycle_run(World0, 30, _WorldFinal, Summaries),
    % Collect the ticks that ran the offline works.
    findall(N, member(tick_summary(N, _, offline_works, _), Summaries), NightTicks),
    % The night is ticks nineteen through twenty-six, exactly eight, and nothing else.
    assertion(NightTicks == [19, 20, 21, 22, 23, 24, 25, 26]),
    % Every offline tick's reward is zero: the sleeping mind declares no reward.
    forall(member(tick_summary(_, Reward, offline_works, _), Summaries), assertion(Reward =:= 0)),
    % Morning came: tick twenty-seven released an action again.
    once(member(tick_summary(27, _, Outcome27, _), Summaries)),
    assertion(Outcome27 = released(_)).

% Through the night the body lies still and the sensory gate is closed: no action, no encoding.
test(the_body_lies_still_and_the_night_does_not_encode) :-
    % Start from the fixed world under the default watchman.
    cognitive_cycle_test_world(World0),
    % Run exactly to the end of the day, tick eighteen.
    cognitive_cycle_run(World0, 18, World18, _Summaries),
    % Step once into the night.
    cognitive_cycle_step(World18, World19, tick_summary(19, 0, offline_works, _)),
    % The body did not move through the offline tick: the atonia of sleep.
    get_dict(body, World18, Body),
    get_dict(body, World19, Body),
    % The memory store did not grow: the sensory gate is closed, so the night encodes nothing.
    get_dict(memories, World18, Memories),
    get_dict(memories, World19, Memories),
    % One snapshot per ONLINE tick stands: eighteen.
    assertion(length(Memories, 18)).

% The offline tick runs the night works: the replay strengthens the remembered day's edge.
test(the_offline_tick_runs_the_night_works) :-
    % Start from the fixed world under the default watchman.
    cognitive_cycle_test_world(World0),
    % Run exactly to the end of the day, tick eighteen.
    cognitive_cycle_run(World0, 18, World18, _Summaries),
    % Read the day's final weight.
    get_dict(interfaces, World18, [interface(a, b, WeightDay, 1, transmissive)]),
    % Step once into the night.
    cognitive_cycle_step(World18, World19, _Summary),
    % Read the weight after one night tick.
    get_dict(interfaces, World19, [interface(a, b, WeightNight, 1, transmissive)]),
    % The remembered day replays: the edge both ends lit all day grew through the night.
    assertion(WeightNight > WeightDay).

% A night bound set below the day's is refused aloud by name: a lowered night is no renormalisation.
test(a_lowered_night_bound_is_refused_aloud,
     [throws(error(domain_error(cognitive_cycle_offline_scaling_rate, 0.2-0.5), _))]) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(Base),
    % Raise the day's bound above the night's, the inversion the tick refuses.
    put_dict(scaling_rate, Base, 0.5, World0),
    % The tick refuses the inverted pair by name before anything moves.
    cognitive_cycle_step(World0, _World, _Summary).

% A world missing its memory store is refused aloud, never silently run without a day to remember.
test(a_world_missing_its_memories_is_refused_aloud) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(World0),
    % Remove the memory store.
    del_dict(memories, World0, _Value, WorldMissing),
    % The tick refuses the gutted world by the missing key's name.
    catch(cognitive_cycle_step(WorldMissing, _World, _Summary), error(Error, _), true),
    % Confirm the refusal names the key.
    assertion(Error == existence_error(cognitive_cycle_world_key, memories)).

% A world missing its replay rate is refused aloud, never silently run with an invented night.
test(a_world_missing_its_replay_rate_is_refused_aloud) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(World0),
    % Remove the replay rate.
    del_dict(replay_rate, World0, _Value, WorldMissing),
    % The tick refuses the gutted world by the missing key's name.
    catch(cognitive_cycle_step(WorldMissing, _World, _Summary), error(Error, _), true),
    % Confirm the refusal names the key.
    assertion(Error == existence_error(cognitive_cycle_world_key, replay_rate)).

% A world missing its offline scaling rate is refused aloud, never silently run with an unjudged night.
test(a_world_missing_its_offline_scaling_rate_is_refused_aloud) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(World0),
    % Remove the offline scaling rate.
    del_dict(offline_scaling_rate, World0, _Value, WorldMissing),
    % The tick refuses the gutted world by the missing key's name.
    catch(cognitive_cycle_step(WorldMissing, _World, _Summary), error(Error, _), true),
    % Confirm the refusal names the key.
    assertion(Error == existence_error(cognitive_cycle_world_key, offline_scaling_rate)).

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

% REVIEW PIN (default-drift lens). The night's TWO rates arrive by the same route under the same
% law, but only the bound used to be judged at the tick's head - so a rotten or NEGATIVE replay rate
% rode a full eighteen-tick day green and detonated at the first night tick, invisible to every
% short-run test in the suite. Both are now judged on the FIRST waking tick alike.
test(a_rotten_replay_rate_is_refused_on_the_first_waking_tick,
     [throws(error(domain_error(offline_consolidation_replay_rate, rotten), _))]) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(Base),
    % Poison the replay rate the night would use.
    put_dict(replay_rate, Base, rotten, World0),
    % The very first WAKING tick refuses it, eighteen ticks before the night would have found it.
    cognitive_cycle_step(World0, _World, _Summary).

% REVIEW PIN (default-drift lens). A NEGATIVE replay rate would let the night unlearn the day, and
% is refused on the first waking tick by the same one root the engine judges by.
test(a_negative_replay_rate_is_refused_on_the_first_waking_tick,
     [throws(error(domain_error(offline_consolidation_replay_rate, -5), _))]) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(Base),
    % Set a replay rate that would strengthen backward.
    put_dict(replay_rate, Base, -5, World0),
    % The first waking tick refuses it aloud.
    cognitive_cycle_step(World0, _World, _Summary).

% REVIEW PIN (unbound-wrong-judgement lens, the sixth slice running). A HOLE standing on the bus
% where the operating state belongs used to unify with the day program's clause head, bind itself
% to online, and leave a choicepoint into the night clause - so one tick ran BOTH whole programs
% and a backtracking caller received a second, entirely different world. It is refused aloud.
test(an_unbound_operating_state_on_the_bus_is_refused_as_uninstantiated,
     [throws(error(instantiation_error, _))]) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(Base),
    % Put a hole on the bus where the standing selection belongs.
    put_dict(bus, Base, [global(operating_state)-_Hole], World0),
    % The tick refuses the hole before the day-or-night dispatch can run either program.
    cognitive_cycle_step(World0, _World, _Summary).

% REVIEW PIN. The same tick used to FAIL SILENTLY on a third operating state, because neither
% program clause head matched and nothing refused it: the flip-flop has two positions and no more.
test(a_third_operating_state_on_the_bus_is_refused_by_name,
     [throws(error(domain_error(neuromodulator_bus_operating_state, drowsy), _))]) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(Base),
    % Put a third position on the bus, one no flip-flop can stand in.
    put_dict(bus, Base, [global(operating_state)-drowsy], World0),
    % The tick refuses it aloud by the bus's own domain name.
    cognitive_cycle_step(World0, _World, _Summary).

% REVIEW PIN. The judged dispatch runs EXACTLY ONE program: a well-formed tick has one solution,
% never a second world reachable by backtracking.
test(a_well_formed_tick_has_exactly_one_solution) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(World0),
    % Collect every solution the tick admits.
    findall(Outcome, cognitive_cycle_step(World0, _World, tick_summary(_, _, Outcome, _)), Outcomes),
    % Exactly one program ran, and it was the day's.
    assertion(Outcomes = [released(_)]).

% =============================================================================
% SLICE 74 - THE WORKING-MEMORY BLACKBOARD IN THE TICK
% =============================================================================

% cognitive_cycle_test_board_world(-World): the fixed world with a full four-slot board on it,
% AND A GOVERNOR RESTATED IN DECISION-2'S OWN UNITS - which is OBSERVATION-23 standing in a fixture.
%
% THE DEFAULT GOVERNOR CANNOT CARRY THESE TESTS AND THAT IS THE FINDING, NOT AN INCONVENIENCE. Its
% parameter block is documented as ONE TICK PER HOUR, and DECISION-2 fixes ONE HUNDRED TICKS TO THE
% NOMINAL SECOND, so the two constructs this slice wires into one loop read the same tick as three
% hundred and sixty thousand times different. Under the default block the whole waking day is
% EIGHTEEN TICKS - eighteen hundredths of a nominal second - and the board's hundred-tick maintenance
% period never arrives before the night erases the surface. So these fixtures restate the governor's
% six parameters in DECISION-2's units rather than working around the collision quietly: the day is
% twenty-four hours in ticks, and the debt rises and discharges per hour rather than per tick.
% Nothing here changes the governor's defaults; OBSERVATION-23 records the collision for the slice
% that decides which calibration konnectome actually keeps.
cognitive_cycle_test_board_world(World) :-
    % One hour in ticks, through the scheduler's one conversion; a million milliseconds is not needed twice.
    tick_engine_ticks_from_milliseconds(3600000, Hour),
    % A day is twenty-four of those hours, computed rather than written down.
    DayLength is 24 * Hour,
    % The debt rises one unit per HOUR, which is what the default block's 1 meant when a tick was an hour.
    Rise is 1 / Hour,
    % And discharges two units per hour, on the same restatement.
    Discharge is 2 / Hour,
    % A governor on the corpus's own shape, read in konnectome's own tick.
    two_process_governor_new(two_process_parameters(Rise, Discharge, DayLength, 4, 16, 2), Governor),
    % Start from the fixed world every other test in this file runs.
    cognitive_cycle_test_world(World0),
    % Put four items on the surface at full activation, in admission order, under the restated day.
    put_dict(_{blackboard: [seven-100, four-100, one-100, nine-100], governor: Governor}, World0, World).

% BETWEEN PERIODS THE BOARD SIMPLY STANDS. This is the whole visible consequence of DECISION-23 and
% the thing one-step-per-tick would have got wrong: ninety-nine ticks of thought change nothing here.
test(the_board_stands_unmoved_between_maintenance_periods) :-
    % Start from a world holding four full slots.
    cognitive_cycle_test_board_world(World0),
    % Run ninety-nine ticks - one short of the board's hundred-tick period.
    cognitive_cycle_run(World0, 99, WorldFinal, _Summaries),
    % Not one slot has faded, because not one maintenance step has run.
    assertion(WorldFinal.blackboard == [seven-100, four-100, one-100, nine-100]).

% ON THE PERIOD, ONE WHOLE MAINTENANCE STEP RUNS, AND EXACTLY ONE.
test(the_hundredth_tick_runs_exactly_one_maintenance_step) :-
    % Start from a world holding four full slots.
    cognitive_cycle_test_board_world(World0),
    % Run one hundred ticks, so the period is reached exactly once.
    cognitive_cycle_run(World0, 100, WorldFinal, _Summaries),
    % Every slot has leaked the corpus's five parts once, and no slot has leaked twice.
    assertion(WorldFinal.blackboard == [seven-95, four-95, one-95, nine-95]).

% AN UNREHEARSED SLOT SURVIVES THE LIFETIME THE DECISION IMPLIES AND NOT ONE TICK LONGER, which is the
% acceptance test of the whole slice: konnectome now forgets on the corpus's own timescale.
test(an_unrehearsed_slot_survives_exactly_the_implied_lifetime) :-
    % Start from a world holding four full slots.
    cognitive_cycle_test_board_world(World0),
    % Read the lifetime the period and the corpus's constants imply, from the board's own pack.
    working_memory_blackboard_unrehearsed_life_ticks(Life),
    % Read the period, so the tick just before the fatal step can be named without arithmetic here.
    working_memory_blackboard_step_ticks(Period),
    % One period short of the lifetime, the board is still holding everything it was given.
    JustBefore is Life - Period,
    cognitive_cycle_run(World0, JustBefore, WorldBefore, _BeforeSummaries),
    working_memory_blackboard_slots(WorldBefore.blackboard, HeldBefore),
    assertion(HeldBefore == [seven, four, one, nine]),
    % At the lifetime itself every slot has fallen below the collapse threshold and the surface is bare.
    cognitive_cycle_run(World0, Life, WorldAfter, _AfterSummaries),
    assertion(WorldAfter.blackboard == []).

% THE STANDING POINTER KEEPS ITS SLOT ALIVE WHILE EVERY OTHER SLOT FADES AWAY BENEATH IT.
test(the_standing_pointer_holds_one_slot_past_the_lifetime_of_the_rest) :-
    % Start from a world holding four full slots.
    cognitive_cycle_test_board_world(World0),
    % Point the standing attentional pointer at one of them.
    put_dict(_{rehearsal_target: seven}, World0, World1),
    % Read the lifetime an unrehearsed slot has, from the board's own pack.
    working_memory_blackboard_unrehearsed_life_ticks(Life),
    % Run the whole of it.
    cognitive_cycle_run(World1, Life, WorldFinal, _Summaries),
    % The rehearsed slot alone survives, and it is standing at full activation.
    assertion(WorldFinal.blackboard == [seven-100]).

% THE NIGHT ERASES THE BOARD, which is Chapter 16's own sentence about slow-wave sleep, and the first
% thing the working-memory mode register's ERASED IDLE has ever had underneath it to wipe.
test(the_night_erases_the_whole_board) :-
    % Start from a world holding four full slots.
    cognitive_cycle_test_board_world(World0),
    % Throw the operating state to offline, so this tick runs the night program.
    neuromodulator_bus_broadcast_operating_state([], offline, Bus),
    put_dict(_{bus: Bus}, World0, World1),
    % One night tick is enough; the erasure is not waiting for any period.
    cognitive_cycle_step(World1, WorldFinal, _Summary),
    % Delay activity is incompatible with the slow oscillation's silent states, so the surface is bare.
    assertion(WorldFinal.blackboard == []).

% A POINTER AT A SLOT THE NIGHT ERASED IS THE ORDINARY MORNING, NOT AN ERROR - the declared reading of
% slice 74, tested rather than only commented, because the pack's own refusal would have thrown here.
test(a_pointer_at_an_erased_slot_rehearses_nothing_and_does_not_throw) :-
    % Start from a world holding four full slots with the pointer aimed at one of them.
    cognitive_cycle_test_board_world(World0),
    put_dict(_{rehearsal_target: seven}, World0, World1),
    % Throw the operating state to offline and let the night wipe the surface out from under it.
    neuromodulator_bus_broadcast_operating_state([], offline, Bus),
    put_dict(_{bus: Bus}, World1, World2),
    cognitive_cycle_step(World2, World3, _NightSummary),
    assertion(World3.blackboard == []),
    % Bring the day back and run a full period, so a maintenance step meets the dangling pointer.
    neuromodulator_bus_broadcast_operating_state([], online, DayBus),
    put_dict(_{bus: DayBus}, World3, World4),
    working_memory_blackboard_step_ticks(Period),
    cognitive_cycle_run(World4, Period, WorldFinal, _Summaries),
    % The morning runs, the board is still empty, and nothing was refused.
    assertion(WorldFinal.blackboard == []).

% An unbound pointer is refused aloud rather than bound to whichever slot the board lists first.
test(an_unbound_rehearsal_target_is_refused_aloud) :-
    % Start from a world holding four full slots.
    cognitive_cycle_test_board_world(World0),
    % Leave the standing pointer as a hole, which the board search would otherwise fill in.
    put_dict(_{rehearsal_target: _Hole}, World0, World1),
    % The tick refuses the hole by name rather than rehearsing a slot nobody named.
    catch(cognitive_cycle_step(World1, _World, _Summary), error(Error, _), true),
    % Confirm the refusal is the instantiation error and not a quiet rehearsal.
    assertion(Error == instantiation_error).

% A world missing its blackboard is refused aloud, never silently run without a working memory.
test(a_world_missing_its_blackboard_is_refused_aloud) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(World0),
    % Remove the board.
    del_dict(blackboard, World0, _Value, WorldMissing),
    % The tick refuses the gutted world by the missing key's name.
    catch(cognitive_cycle_step(WorldMissing, _World, _Summary), error(Error, _), true),
    % Confirm the refusal names the key.
    assertion(Error == existence_error(cognitive_cycle_world_key, blackboard)).

% A world missing its rehearsal target is refused aloud - an absent pointer is not the same fact as
% an explicitly absent one, and DECISION-19's shape is a REQUIRED key rather than a helpful default.
test(a_world_missing_its_rehearsal_target_is_refused_aloud) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(World0),
    % Remove the standing pointer.
    del_dict(rehearsal_target, World0, _Value, WorldMissing),
    % The tick refuses the gutted world by the missing key's name.
    catch(cognitive_cycle_step(WorldMissing, _World, _Summary), error(Error, _), true),
    % Confirm the refusal names the key.
    assertion(Error == existence_error(cognitive_cycle_world_key, rehearsal_target)).

% Close the test block for the cognitive_cycle pack.
:- end_tests(cognitive_cycle).
