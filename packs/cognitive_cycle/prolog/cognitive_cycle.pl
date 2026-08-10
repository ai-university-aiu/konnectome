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
    % Read the fixed simulation start, for the observer's timestamps.
    cognitive_cycle_world_value(World0, simulation_start, SimulationStart),
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
    % STEP SIX: advance the tick counter.
    NextTick is Tick0 + 1,
    % The observer records this tick as a Causalontology token_occurrence.
    observer_record_tick(SimulationStart, NextTick, Record),
    % Assemble the new world with the updated pieces committed together, including the moved body
    % and the learning body's advanced trace and average stores.
    put_dict(_{tick: NextTick, body: Body1, drives: Drives1, bus: Bus1, activations: Activations1,
               interfaces: Interfaces2, traces: Traces1, averages: Averages1},
             World0, World),
    % The tick summary reports the tick number, the reward, the released action, and the recorded thought.
    Summary = tick_summary(NextTick, Reward, FinalOutcome, Record).

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
