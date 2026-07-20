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
    % A minimal but complete world: one drive, one two-construct connection, the body away from set-point.
    World = world{ tick: 0,
                   body: [temperature-40],
                   drives: [drive(temperature, temperature, 37, none)],
                   bus: [],
                   constructs: [construct(a, source), construct(b, relay(1))],
                   activations: [a-1, b-0],
                   interfaces: [interface(a, b, 0.5, 1, transmissive)],
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

% Close the test block for the cognitive_cycle pack.
:- end_tests(cognitive_cycle).
