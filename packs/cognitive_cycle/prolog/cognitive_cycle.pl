% Declare this file as the 'cognitive_cycle' module and list the predicates it exports.
:- module(cognitive_cycle, [
    % cognitive_cycle_step/3: run one whole tick across all ten components, in the Section A3.3 order.
    cognitive_cycle_step/3,
    % cognitive_cycle_run/4: run the whole mind for a chosen number of ticks.
    cognitive_cycle_run/4
]).

% Import reverse for returning the tick summaries in order.
:- use_module(library(lists), [reverse/2]).
% Reuse the drive system: it reads the body, computes the reward, and broadcasts it as dopamine.
:- use_module(library(drive_system), [drive_system_step/6]).
% Reuse the connection graph: it runs the two-pass synchronous construct update.
:- use_module(library(connection_graph), [connection_graph_step/4]).
% Reuse the action selector: it releases exactly one candidate action.
:- use_module(library(action_selector), [action_selector_select/2]).
% Reuse the override controller: a vital drive in distress may seize control.
:- use_module(library(override_controller), [override_controller_arbitrate/4]).
% Reuse the plasticity engine: it learns from the new activity and the dopamine.
:- use_module(library(plasticity_engine), [plasticity_engine_step/5]).
% Reuse the observer: it records the tick as a Causalontology token_occurrence.
:- use_module(library(observer), [observer_record_tick/3]).

% The cognitive cycle wires all ten architecture components into one running tick, in the exact order
% of Section A3.3: the drives compute the reward and the bus broadcasts it as dopamine; the two-pass
% synchronous update advances every construct; the action selector releases one action under the
% override controller; the plasticity engine learns from what just happened; and the observer records
% the tick. The world is held as a dict carrying the body, drives, bus, constructs, activations,
% interfaces, candidate actions, overrides, and the run's parameters. This is the loop of the mind.

% cognitive_cycle_step(+World0, -World, -Summary): run one whole tick and report what happened.
cognitive_cycle_step(World0, World, Summary) :-
    % Read the current tick count.
    get_dict(tick, World0, Tick0),
    % Read the body state the drives monitor.
    get_dict(body, World0, Body),
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
    % Read the candidate actions proposed this tick.
    get_dict(candidates, World0, Candidates),
    % Read the vital-drive overrides.
    get_dict(overrides, World0, Overrides),
    % Read the override distress threshold.
    get_dict(override_threshold, World0, Threshold),
    % Read the learning rate.
    get_dict(learning_rate, World0, LearningRate),
    % Read the fixed simulation start, for the observer's timestamps.
    get_dict(simulation_start, World0, SimulationStart),
    % STEP ONE (A3.3): the drives read the body, compute the reward, and broadcast it as dopamine.
    drive_system_step(Drives0, Body, Bus0, Drives1, Reward, Bus1),
    % STEP TWO: the two-pass synchronous update advances every construct over the connection graph.
    connection_graph_step(Interfaces0, Constructs, Activations0, Activations1),
    % STEP THREE: the action selector releases one action, then the override controller may seize control.
    action_selector_select(Candidates, NormalOutcome),
    % The override controller resolves control, letting a vital drive in distress preempt.
    override_controller_arbitrate(Overrides, Threshold, NormalOutcome, FinalOutcome),
    % STEP FOUR: the plasticity engine learns from the new activations and the dopamine on the bus.
    plasticity_engine_step(Interfaces0, Activations1, Bus1, LearningRate, Interfaces1),
    % STEP FIVE: advance the tick counter.
    NextTick is Tick0 + 1,
    % The observer records this tick as a Causalontology token_occurrence.
    observer_record_tick(SimulationStart, NextTick, Record),
    % Assemble the new world with the updated pieces committed together.
    put_dict(_{tick: NextTick, drives: Drives1, bus: Bus1, activations: Activations1, interfaces: Interfaces1},
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
