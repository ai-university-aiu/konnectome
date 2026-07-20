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
% Reuse the plasticity engine: it learns from the new activity and the dopamine.
:- use_module(library(plasticity_engine), [plasticity_engine_step/5]).
% Reuse the observer: it records the tick as a Causalontology token_occurrence.
:- use_module(library(observer), [observer_record_tick/3]).

% The cognitive cycle wires all ten architecture components into one running tick, in the exact order
% of Section A3.3, and now closes the sensorimotor loop: the drives compute the reward and the bus
% broadcasts it as dopamine; the regions (the drives) PROPOSE actions in proportion to their error;
% the two-pass synchronous update advances every construct with relay gains set by the bus; the action
% selector releases one action under the override controller; the plasticity engine learns; the BODY
% RESPONDS as the released action moves it toward what it needs; and the observer records the tick. The
% world is held as a dict, and this is the loop of the mind, now closing on the body it acts upon.

% cognitive_cycle_step(+World0, -World, -Summary): run one whole tick and report what happened.
cognitive_cycle_step(World0, World, Summary) :-
    % Read the current tick count.
    get_dict(tick, World0, Tick0),
    % Read the body state the drives monitor and the actions move.
    get_dict(body, World0, Body0),
    % Read the current drives.
    get_dict(drives, World0, Drives0),
    % Read the neuromodulatory bus.
    get_dict(bus, World0, Bus0),
    % Read the constructs (the registry of what updates each tick).
    get_dict(constructs, World0, Constructs),
    % Read the current construct activations.
    get_dict(activations, World0, Activations0),
    % Read the connection graph's interfaces.
    get_dict(interfaces, World0, Interfaces0),
    % Read the vital-drive overrides.
    get_dict(overrides, World0, Overrides),
    % Read the override distress threshold.
    get_dict(override_threshold, World0, Threshold),
    % Read the learning rate.
    get_dict(learning_rate, World0, LearningRate),
    % Read the fixed simulation start, for the observer's timestamps.
    get_dict(simulation_start, World0, SimulationStart),
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
    % STEP FIVE: the body responds - the released action moves the body toward what it needs.
    drive_system_apply_action(FinalOutcome, Drives0, Body0, Body1),
    % STEP SIX: advance the tick counter.
    NextTick is Tick0 + 1,
    % The observer records this tick as a Causalontology token_occurrence.
    observer_record_tick(SimulationStart, NextTick, Record),
    % Assemble the new world with the updated pieces committed together, including the moved body.
    put_dict(_{tick: NextTick, body: Body1, drives: Drives1, bus: Bus1, activations: Activations1, interfaces: Interfaces1},
             World0, World),
    % The tick summary reports the tick number, the reward, the released action, and the recorded thought.
    Summary = tick_summary(NextTick, Reward, FinalOutcome, Record).

% cognitive_cycle_run(+World0, +NumTicks, -WorldFinal, -Summaries): run the mind for NumTicks ticks.
cognitive_cycle_run(World0, NumTicks, WorldFinal, Summaries) :-
    % Refuse a negative tick count; time never runs backward.
    NumTicks >= 0,
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
