% Load the neuromodulator_bus module under test from the library path.
:- use_module(library(neuromodulator_bus)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% Open the test block for the neuromodulator_bus pack.
:- begin_tests(neuromodulator_bus).

% An empty bus reads every modulator as zero.
test(empty_bus_reads_zero) :-
    % Make a fresh empty bus.
    neuromodulator_bus_new(Bus),
    % Any modulator reads as zero on it.
    neuromodulator_bus_level(Bus, dopamine, Level),
    % Confirm the level is zero.
    assertion(Level =:= 0).

% A broadcast level can be read back.
test(broadcast_then_read) :-
    % Start from an empty bus.
    neuromodulator_bus_new(Bus0),
    % Broadcast a dopamine level.
    neuromodulator_bus_broadcast(Bus0, dopamine, 0.7, Bus1),
    % Read it back.
    neuromodulator_bus_level(Bus1, dopamine, Level),
    % Confirm the read level matches the broadcast.
    assertion(Level =:= 0.7).

% A newer broadcast overwrites the older level for the same modulator.
test(newest_broadcast_wins) :-
    % Start from an empty bus.
    neuromodulator_bus_new(Bus0),
    % Broadcast an initial dopamine level.
    neuromodulator_bus_broadcast(Bus0, dopamine, 0.2, Bus1),
    % Broadcast a newer dopamine level.
    neuromodulator_bus_broadcast(Bus1, dopamine, 0.9, Bus2),
    % Read the level.
    neuromodulator_bus_level(Bus2, dopamine, Level),
    % Confirm the newest broadcast is the one read.
    assertion(Level =:= 0.9).

% Different modulators are held independently.
test(modulators_are_independent) :-
    % Start from an empty bus.
    neuromodulator_bus_new(Bus0),
    % Broadcast dopamine.
    neuromodulator_bus_broadcast(Bus0, dopamine, 0.5, Bus1),
    % Broadcast norepinephrine.
    neuromodulator_bus_broadcast(Bus1, norepinephrine, 0.3, Bus2),
    % Read dopamine.
    neuromodulator_bus_level(Bus2, dopamine, Dopamine),
    % Read norepinephrine.
    neuromodulator_bus_level(Bus2, norepinephrine, Norepinephrine),
    % Confirm both are held independently.
    assertion(Dopamine =:= 0.5),
    % Confirm the second modulator too.
    assertion(Norepinephrine =:= 0.3).

% Close the test block for the neuromodulator_bus pack.
:- end_tests(neuromodulator_bus).
