% Declare this file as the 'cognitive_cycle' module and list the predicates it exports.
:- module(cognitive_cycle, [
    % cognitive_cycle_step/3: run one whole tick across all ten components, in the Section A3.3 order.
    cognitive_cycle_step/3,
    % cognitive_cycle_run/4: run the whole mind for a chosen number of ticks.
    cognitive_cycle_run/4
]).

% Import reverse for returning the tick summaries in order.
:- use_module(library(lists), [reverse/2]).
% Reuse the drive system: it computes the reward, proposes actions, and moves the body in response.
:- use_module(library(drive_system), [drive_system_step/6, drive_system_proposals/3, drive_system_apply_action/4]).
% Reuse the connection graph's bus-modulated update, so relay gains are set by the neuromodulators.
:- use_module(library(connection_graph), [connection_graph_step_modulated/5]).
% Reuse the action selector: it releases exactly one candidate action.
:- use_module(library(action_selector), [action_selector_select/2]).
% Reuse the override controller: a vital drive in distress may seize control.
:- use_module(library(override_controller), [override_controller_arbitrate/4]).
% Reuse the plasticity engine: the fast three-factor learning, the fading traces, the running
% averages, and the slow homeostatic bound - the whole learning body, beating in the live tick.
:- use_module(library(plasticity_engine), [plasticity_engine_step/5,
                                           plasticity_engine_reward_capture_step/6,
                                           plasticity_engine_trace_step/5,
                                           plasticity_engine_average_step/4,
                                           plasticity_engine_scaling_step_territory/6]).
% Reuse the two-process governor: the night watchman that schedules the slice-35 switch.
:- use_module(library(two_process_governor), [two_process_governor_step/4]).
% Reuse the offline consolidation engine: the night crew the thrown switch now commands.
:- use_module(library(offline_consolidation), [offline_consolidation_remember/3,
                                               offline_consolidation_night_step/8,
                                               offline_consolidation_check_replay_rate/1]).
% Reuse the bus's switch: the tick reads the standing selection and announces the governor's next one.
:- use_module(library(neuromodulator_bus), [neuromodulator_bus_operating_state/2,
                                            neuromodulator_bus_broadcast_operating_state/3,
                                            neuromodulator_bus_check_operating_state/1]).
% Reuse the observer: it records the tick as a Causalontology token_occurrence.
:- use_module(library(observer), [observer_record_tick/3]).

% The cognitive cycle wires all ten architecture components into one running tick, in the exact order
% of Section A3.3, and now closes the sensorimotor loop: the drives compute the reward and the bus
% broadcasts it as dopamine; the regions (the drives) PROPOSE actions in proportion to their error;
% the two-pass synchronous update advances every construct with relay gains set by the bus; the action
% selector releases one action under the override controller; the plasticity engine learns; the BODY
% RESPONDS as the released action moves it toward what it needs; and the observer records the tick. The
% world is held as a dict, and this is the loop of the mind, now closing on the body it acts upon.
% Since slice 32 the tick carries the learning engine's WHOLE body: the world dict also holds the
% eligibility-trace store (slice 28), the running-average store (slice 29), the four constants
% that beat them (the fading factor, the smoothing factor, the scaling target, and the scaling rate),
% and since slice 33 the per-territory target geography (scaling_targets, empty meaning every region
% defends the global target),
% so every tick fades and refreshes the traces, moves the averages, and applies the slow homeostatic
% bound after the fast learning - the Section A2.5-and-A2.6 machinery live in the loop, not waiting
% for a caller to remember it. Since slice 36 the reward step's caller is the tick itself: the
% drives declare the tick's reward and broadcast it as dopamine, and the reward-capture step spends
% the standing eligibility traces into the weights the moment that dopamine is nonzero, consuming
% the spent tags (the Layers 4-5 tag-and-capture law) - so trace lifetime belongs to the loop that
% decides a reward has arrived, which is exactly what the old deliberate deferral was waiting for.
% Capture runs on the traces as they stood at the tick's start, BEFORE this tick's fresh
% coincidence is folded in, so a reward one tick late finds the trace that earned it and this
% tick's own coincidence is never double-counted against this tick's own reward.
% Since slice 37 the tick also carries the NIGHT WATCHMAN: the world holds the two-process
% governor (Layer 11 Chapters 11, 13, 14, 15), and at the tick's end - after the body has
% responded, before the observer records - the governor reads the standing operating state off
% the bus, advances the rising sleep pressure and the circadian day wave one tick, and the tick
% announces the governor's selection back onto the bus (the Chapter 16 announcement service).
% This is the FIRST LEGITIMATE THROWER of the slice-35 switch.
% Since slice 38 the tick is also the switch's FIRST LEGITIMATE READER: the standing operating
% state, read off the bus at the tick's opening, chooses between two whole programs. An ONLINE
% tick runs the day exactly as slice 37 left it, and then REMEMBERS - the tick's updated
% activation pattern is appended to the world's memory store, the hippocampal day of Layer 11
% Chapter 6 in its simplest honest form. An OFFLINE tick closes the sensory gate: no drive step,
% no proposals, no graph update, no action, no fast learning, no capture, and an unmoved body
% (the atonia of sleep); instead the NIGHT WORKS run (Chapter 7): one interleaved replay round
% over the remembered day, then the slow homeostatic bound at the world's RAISED offline scaling
% rate - the renormalisation shift. The timing law holds as slice 37 wrote it: the selection made
% from a tick's completed day governs the NEXT tick's opening state, so the state read at the
% opening is the one the previous tick announced. DECLARED SIMPLIFICATIONS: through an offline
% tick the activations, traces, averages, drives, and body all stand as the day left them (the
% night neither writes nor spends tags, and the bound judges the day's standing averages), and
% the memory store is unbounded within a run. The world dict gained THREE required keys, each
% refused aloud by name when missing: memories (the day's snapshot store), replay_rate (the
% night's strengthening dose per offline tick), and offline_scaling_rate (the raised bound). BOTH
% night rates are judged on EVERY tick, waking or sleeping alike, so a rotten or negative one
% cannot ride a whole day unseen and detonate at nightfall; and a night bound set BELOW the day's
% is refused by name - a lowered night would be no renormalisation at all, the inverted-hysteresis
% refusal's sibling. The operating state read off the bus is judged against the bus's OWN domain
% before the dispatch, so exactly one program can ever run and no hole can run both.

% cognitive_cycle_world_value(+World, +Key, -Value): read one world key, refusing a missing key aloud.
cognitive_cycle_world_value(World, Key, Value) :-
    % Use the stored value if present; a world missing a key the tick needs is an error, never a silent failure.
    (  get_dict(Key, World, Found)
    -> Value = Found
    % Refuse the gutted world by the missing key's name, so a stale world can never half-run a tick.
    ;  throw(error(existence_error(cognitive_cycle_world_key, Key), _))
    ).

% cognitive_cycle_step(+World0, -World, -Summary): run one whole tick and report what happened.
cognitive_cycle_step(World0, World, Summary) :-
    % Read the current tick count.
    cognitive_cycle_world_value(World0, tick, Tick0),
    % Read the body state the drives monitor and the actions move.
    cognitive_cycle_world_value(World0, body, Body0),
    % Read the current drives.
    cognitive_cycle_world_value(World0, drives, Drives0),
    % Read the neuromodulatory bus.
    cognitive_cycle_world_value(World0, bus, Bus0),
    % Read the constructs (the registry of what updates each tick).
    cognitive_cycle_world_value(World0, constructs, Constructs),
    % Read the current construct activations.
    cognitive_cycle_world_value(World0, activations, Activations0),
    % Read the connection graph's interfaces.
    cognitive_cycle_world_value(World0, interfaces, Interfaces0),
    % Read the eligibility-trace store the tick advances.
    cognitive_cycle_world_value(World0, traces, Traces0),
    % Read the running-average store the tick advances.
    cognitive_cycle_world_value(World0, averages, Averages0),
    % Read the fading factor that lets every trace forget.
    cognitive_cycle_world_value(World0, fading_factor, FadingFactor),
    % Read the smoothing factor that paces every running average.
    cognitive_cycle_world_value(World0, smoothing_factor, SmoothingFactor),
    % Read the global activity target each region's slow bound defends by default.
    cognitive_cycle_world_value(World0, scaling_target, ScalingTarget),
    % Read the per-territory target geography (empty means every region defends the global target).
    cognitive_cycle_world_value(World0, scaling_targets, ScalingTargets),
    % Read the scaling rate of the slow bound (zero means armed but at rest).
    cognitive_cycle_world_value(World0, scaling_rate, ScalingRate),
    % Read the vital-drive overrides.
    cognitive_cycle_world_value(World0, overrides, Overrides),
    % Read the override distress threshold.
    cognitive_cycle_world_value(World0, override_threshold, Threshold),
    % Read the learning rate.
    cognitive_cycle_world_value(World0, learning_rate, LearningRate),
    % Read the two-process governor, the night watchman of the operating state.
    cognitive_cycle_world_value(World0, governor, Governor0),
    % Read the memory store the day fills and the night replays (slice 38).
    cognitive_cycle_world_value(World0, memories, Memories0),
    % Read the night's replay strengthening rate.
    cognitive_cycle_world_value(World0, replay_rate, ReplayRate),
    % Read the night's raised scaling rate, the renormalisation shift's steeper bound.
    cognitive_cycle_world_value(World0, offline_scaling_rate, OfflineScalingRate),
    % Read the fixed simulation start, for the observer's timestamps.
    cognitive_cycle_world_value(World0, simulation_start, SimulationStart),
    % Refuse a night bound set below the day's, at every tick, waking or sleeping alike.
    cognitive_cycle_check_offline_scaling_rate(OfflineScalingRate, ScalingRate),
    % REVIEW FIX (default-drift lens): the night's two rates arrive by the same route and are
    % documented under the same law, but only the bound was judged at the tick's head - so a rotten
    % or NEGATIVE replay rate (the night unlearning the day) rode a full eighteen-tick day green and
    % detonated at the first night tick. Both night rates are now judged on every tick alike.
    offline_consolidation_check_replay_rate(ReplayRate),
    % THE FIRST LEGITIMATE READ (slice 38): the standing selection the previous tick announced
    % chooses this tick's whole program, the waking default when unset.
    neuromodulator_bus_operating_state(Bus0, OperatingState0),
    % REVIEW FIX (unbound-wrong-judgement lens, the SIXTH slice running): the bus returns whatever
    % stands on it WITHOUT judging it, and the two program clauses judge only by head unification -
    % so a hole on the bus used to unify with the online head, bind itself to online, and leave a
    % choicepoint into the night clause, running BOTH whole programs and handing a backtracking
    % caller a second, entirely different world; and an out-of-domain state matched neither head and
    % failed the whole tick SILENTLY. The bus's own domain check refuses both aloud, before the
    % dispatch, so exactly one program can ever run.
    neuromodulator_bus_check_operating_state(OperatingState0),
    % Run the day program or the night program under the standing state.
    cognitive_cycle_program(OperatingState0, Body0, Drives0, Bus0, Constructs, Activations0,
                            Interfaces0, Traces0, Averages0, Memories0,
                            FadingFactor, SmoothingFactor, ScalingTarget, ScalingTargets,
                            ScalingRate, OfflineScalingRate, ReplayRate,
                            Overrides, Threshold, LearningRate,
                            Body1, Drives1, Bus1, Activations1, Interfaces2, Traces1, Averages1,
                            Memories1, Reward, FinalOutcome),
    % Both processes move one tick and the flip-flop selects the next operating state (slice 37);
    % the selection made from this completed day governs the NEXT tick's opening state.
    two_process_governor_step(Governor0, OperatingState0, Governor1, OperatingState1),
    % The tick announces the governor's selection to every subscriber - the first legitimate thrower.
    neuromodulator_bus_broadcast_operating_state(Bus1, OperatingState1, Bus2),
    % STEP SIX: advance the tick counter.
    NextTick is Tick0 + 1,
    % The observer records this tick as a Causalontology token_occurrence.
    observer_record_tick(SimulationStart, NextTick, Record),
    % Assemble the new world with the updated pieces committed together, including the moved body,
    % the learning body's advanced trace and average stores, and the day's remembered patterns.
    put_dict(_{tick: NextTick, body: Body1, drives: Drives1, bus: Bus2, activations: Activations1,
               interfaces: Interfaces2, traces: Traces1, averages: Averages1, governor: Governor1,
               memories: Memories1},
             World0, World),
    % The tick summary reports the tick number, the reward, the released action, and the recorded thought.
    Summary = tick_summary(NextTick, Reward, FinalOutcome, Record).

% cognitive_cycle_check_offline_scaling_rate(+OfflineRate, +WakingRate): refuse a lowered night bound.
cognitive_cycle_check_offline_scaling_rate(OfflineRate, WakingRate) :-
    % An unbound night rate cannot be judged, and must never be silently bound by the comparison.
    (  var(OfflineRate)
    -> throw(error(instantiation_error, _))
    ;  true
    ),
    % An unbound day rate cannot be judged either, on the same standing lens.
    (  var(WakingRate)
    -> throw(error(instantiation_error, _))
    ;  true
    ),
    % The night's bound is RAISED, at or above the day's: a lowered night is refused by name,
    % the inverted-hysteresis refusal's sibling (both rates judged as numbers on the way).
    (  number(OfflineRate), number(WakingRate), OfflineRate >= WakingRate
    -> true
    ;  throw(error(domain_error(cognitive_cycle_offline_scaling_rate, OfflineRate-WakingRate), _))
    ).

% cognitive_cycle_program(+State, ...): the day program awake, the night program asleep (slice 38).
% THE DAY PROGRAM: the whole slice-37 waking tick, unchanged, and then the day remembers itself.
cognitive_cycle_program(online, Body0, Drives0, Bus0, Constructs, Activations0,
                        Interfaces0, Traces0, Averages0, Memories0,
                        FadingFactor, SmoothingFactor, ScalingTarget, ScalingTargets,
                        ScalingRate, _OfflineScalingRate, _ReplayRate,
                        Overrides, Threshold, LearningRate,
                        Body1, Drives1, Bus1, Activations1, Interfaces2, Traces1, Averages1,
                        Memories1, Reward, FinalOutcome) :-
    % STEP ONE (A3.3): the drives read the body, compute the reward, and broadcast it as dopamine.
    drive_system_step(Drives0, Body0, Bus0, Drives1, Reward, Bus1),
    % The regions propose actions: each drive proposes to reduce itself, biased by its current error.
    drive_system_proposals(Drives0, Body0, Candidates),
    % STEP TWO: the two-pass synchronous update advances every construct, with relay gains set by the bus.
    connection_graph_step_modulated(Interfaces0, Constructs, Activations0, Bus1, Activations1),
    % STEP THREE: the action selector releases one proposed action, then the override controller may seize control.
    action_selector_select(Candidates, NormalOutcome),
    % The override controller resolves control, letting a vital drive in distress preempt.
    override_controller_arbitrate(Overrides, Threshold, NormalOutcome, FinalOutcome),
    % STEP FOUR: the plasticity engine learns from the new activations and the dopamine on the bus.
    plasticity_engine_step(Interfaces0, Activations1, Bus1, LearningRate, Interfaces1),
    % The reward the drives just declared spends the standing eligibility traces into the weights,
    % and capture consumes the spent tags (slice 36, the Layers 4-5 tag-and-capture law made live).
    plasticity_engine_reward_capture_step(Interfaces1, Traces0, Bus1, LearningRate, InterfacesCaptured, TracesCaptured),
    % The eligibility traces fade one step and absorb this tick's fresh coincidences (slice 28, live).
    plasticity_engine_trace_step(InterfacesCaptured, Activations1, FadingFactor, TracesCaptured, Traces1),
    % The running averages move one smoothing step toward this tick's activities (slice 29, live).
    plasticity_engine_average_step(Activations1, SmoothingFactor, Averages0, Averages1),
    % The slow homeostatic bound scales each region's incoming weights toward the target its own
    % territory defends, the global target as the diffuse fallback (slice 29 live, slice 33 geography).
    plasticity_engine_scaling_step_territory(InterfacesCaptured, Averages1, ScalingTargets, ScalingTarget, ScalingRate, Interfaces2),
    % STEP FIVE: the body responds - the released action moves the body toward what it needs.
    drive_system_apply_action(FinalOutcome, Drives0, Body0, Body1),
    % THE DAY REMEMBERS ITSELF (slice 38): the tick's updated pattern joins the hippocampal day,
    % newest last, for the night crew to replay when the watchman calls the dark hours.
    offline_consolidation_remember(Memories0, Activations1, Memories1).
% THE NIGHT PROGRAM: the sensory gate closes, the body lies still, and the night works run.
cognitive_cycle_program(offline, Body0, Drives0, Bus0, _Constructs, Activations0,
                        Interfaces0, Traces0, Averages0, Memories0,
                        _FadingFactor, _SmoothingFactor, ScalingTarget, ScalingTargets,
                        _ScalingRate, OfflineScalingRate, ReplayRate,
                        _Overrides, _Threshold, _LearningRate,
                        Body0, Drives0, Bus0, Activations0, Interfaces2, Traces0, Averages0,
                        Memories0, 0, offline_works) :-
    % THE NIGHT WORKS (Chapter 7): one interleaved replay round over the remembered day, then the
    % slow bound at the raised offline rate, judging the day's standing averages - install the new
    % without erasing the old, and renormalise what the day potentiated.
    offline_consolidation_night_step(Interfaces0, Memories0, ReplayRate, Averages0, ScalingTargets,
                                     ScalingTarget, OfflineScalingRate, Interfaces2).

% cognitive_cycle_check_tick_count(+NumTicks): refuse a tick count time could not run, by name.
cognitive_cycle_check_tick_count(NumTicks) :-
    % An unbound count cannot be judged, and must never be silently bound by the check itself.
    (  var(NumTicks)
    -> throw(error(instantiation_error, _))
    % Time moves forward in whole ticks, so the count is an integer at or above zero.
    ;  integer(NumTicks), NumTicks >= 0
    -> true
    % Anything else is refused aloud, never answered by a silent failure or a stray arithmetic error
    % (the slice-32 review's finding: the run's old comment CLAIMED refusal while the code just failed).
    ;  throw(error(domain_error(cognitive_cycle_tick_count, NumTicks), _))
    ).

% cognitive_cycle_run(+World0, +NumTicks, -WorldFinal, -Summaries): run the mind for NumTicks ticks.
cognitive_cycle_run(World0, NumTicks, WorldFinal, Summaries) :-
    % Refuse a negative, fractional, unbound, or non-numeric tick count aloud; time never runs backward.
    cognitive_cycle_check_tick_count(NumTicks),
    % Drive the loop from zero with an empty summary accumulator.
    cognitive_cycle_loop(0, NumTicks, World0, [], SummariesReversed, WorldFinal),
    % Reverse the summaries so the earliest tick comes first.
    reverse(SummariesReversed, Summaries).

% cognitive_cycle_loop(+Count, +NumTicks, +World, +Acc, -Summaries, -WorldFinal): the run loop.
% Base case: stop once the requested number of ticks has run.
cognitive_cycle_loop(Count, NumTicks, World, Acc, Acc, World) :-
    % Stop when the count has reached the requested number of ticks.
    Count >= NumTicks,
    % Commit to the base case.
    !.
% Recursive case: run one tick and continue.
cognitive_cycle_loop(Count, NumTicks, World0, Acc, Summaries, WorldFinal) :-
    % Continue only while ticks remain.
    Count < NumTicks,
    % Run one whole tick.
    cognitive_cycle_step(World0, World1, Summary),
    % Advance the loop counter.
    NextCount is Count + 1,
    % Continue with this tick's summary prepended.
    cognitive_cycle_loop(NextCount, NumTicks, World1, [Summary|Acc], Summaries, WorldFinal).
