% Load the cognitive_cycle module under test from the library path.
:- use_module(library(cognitive_cycle)).
% Load the neuromodulator_bus module, used to read the broadcast dopamine level.
:- use_module(library(neuromodulator_bus)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% A fixed starting world, so every test is deterministic and reproducible.
cognitive_cycle_test_world(World) :-
    % A minimal but complete world: one drive, one two-construct connection, one candidate action.
    World = world{ tick: 0,
                   body: [temperature-40],
                   drives: [drive(temperature, temperature, 37, none)],
                   bus: [],
                   constructs: [construct(a, source), construct(b, relay(1))],
                   activations: [a-1, b-0],
                   interfaces: [interface(a, b, 0.5, 1, transmissive)],
                   candidates: [action(cool, 0.5)],
                   overrides: [],
                   override_threshold: 0.5,
                   learning_rate: 0.1,
                   simulation_start: "2026-07-20T00:00:00Z" }.

% Open the test block for the cognitive_cycle pack.
:- begin_tests(cognitive_cycle).

% One full tick runs all components in order, and across two ticks the reward drives learning.
test(one_full_tick_runs_all_components_and_learns) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(World0),
    % Run the first tick.
    cognitive_cycle_step(World0, World1, tick_summary(Tick1, Reward1, Action1, Record1)),
    % The tick counter advanced to one.
    assertion(Tick1 =:= 1),
    % The first tick has no previous error, so the reward is zero.
    assertion(Reward1 =:= 0),
    % With no override, the normal candidate action is released.
    assertion(Action1 == released(cool)),
    % The observer recorded a Causalontology token_occurrence.
    get_dict(id, Record1, Id1),
    % Confirm the record is a token_occurrence.
    assertion(sub_string(Id1, 0, _, _, "token_occurrence:")),
    % Move the body one step toward the set-point for the next tick.
    put_dict(body, World1, [temperature-39], World1b),
    % Run the second tick.
    cognitive_cycle_step(World1b, World2, tick_summary(Tick2, Reward2, _Action2, _Record2)),
    % The tick counter advanced to two.
    assertion(Tick2 =:= 2),
    % The drive error fell by one, so the reward is one.
    assertion(Reward2 =:= 1),
    % The reward was broadcast as dopamine on the bus.
    get_dict(bus, World2, Bus2),
    neuromodulator_bus_level(Bus2, dopamine, Dopamine2),
    % Confirm the dopamine equals the reward.
    assertion(Dopamine2 =:= 1),
    % The active connection learned: its weight grew above one half.
    get_dict(interfaces, World2, [interface(a, b, Weight2, 1, transmissive)]),
    % Confirm learning happened.
    assertion(Weight2 > 0.5).

% A vital drive in distress overrides the normal action (the safety property, end to end).
test(a_vital_drive_in_distress_overrides_the_normal_action) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(Base),
    % Add a respiration drive in distress.
    put_dict(overrides, Base, [override(respiration, 0, 0.9, breathe)], World0),
    % Run one tick.
    cognitive_cycle_step(World0, _World1, tick_summary(_Tick, _Reward, Action, _Record)),
    % Breathing overrides the normal cool action.
    assertion(Action == released(breathe)).

% Each tick records its own distinct Causalontology thought.
test(each_tick_records_a_distinct_thought) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(World0),
    % Run three ticks.
    cognitive_cycle_run(World0, 3, _WorldFinal, Summaries),
    % Collect the recorded identifiers.
    findall(Id, (member(tick_summary(_N, _R, _A, Record), Summaries), get_dict(id, Record, Id)), Ids),
    % There are three of them.
    assertion(length(Ids, 3)),
    % Deduplicate them.
    sort(Ids, Unique),
    % All three are distinct.
    assertion(length(Unique, 3)).

% The whole cycle is reproducible: the same world run twice yields the identical result.
test(the_cycle_is_reproducible) :-
    % Start from the fixed world.
    cognitive_cycle_test_world(World0),
    % Run it once.
    cognitive_cycle_run(World0, 3, WorldA, _SummariesA),
    % Run it again with the same inputs.
    cognitive_cycle_run(World0, 3, WorldB, _SummariesB),
    % The interfaces (learned weights) are identical.
    get_dict(interfaces, WorldA, InterfacesA),
    get_dict(interfaces, WorldB, InterfacesB),
    % Confirm the weights match.
    assertion(InterfacesA == InterfacesB),
    % The buses are identical.
    get_dict(bus, WorldA, BusA),
    get_dict(bus, WorldB, BusB),
    % Confirm the buses match.
    assertion(BusA == BusB).

% Close the test block for the cognitive_cycle pack.
:- end_tests(cognitive_cycle).
