% Load the perturbation_interface module under test from the library path.
:- use_module(library(perturbation_interface)).
% Load the neuromodulator_bus module, used to build and read a bus.
:- use_module(library(neuromodulator_bus)).
% Load the plasticity_engine module, to show that depleting dopamine stops learning.
:- use_module(library(plasticity_engine)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% Open the test block for the perturbation_interface pack.
:- begin_tests(perturbation_interface).

% A lesion silences a construct, setting its activation to zero and leaving the rest untouched.
test(lesion_silences_a_construct) :-
    % Lesion construct a in a two-construct state.
    perturbation_interface_lesion([a-5, b-3], a, State),
    % The lesioned construct is silenced and the other is unchanged.
    assertion(State == [a-0, b-3]).

% Cutting a connection removes its interface from the graph.
test(cut_removes_the_connection) :-
    % A two-edge graph.
    Interfaces = [interface(a, b, 1, 1, transmissive), interface(b, c, 1, 1, transmissive)],
    % Cut the a-to-b connection.
    perturbation_interface_cut(Interfaces, a, b, Remaining),
    % Only the b-to-c connection remains.
    assertion(Remaining == [interface(b, c, 1, 1, transmissive)]).

% Shifting a neuromodulator sets its level directly, as a drug would.
test(shift_sets_a_neuromodulator_level) :-
    % A bus carrying full dopamine.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus1),
    % Deplete the dopamine to zero.
    perturbation_interface_shift(Bus1, dopamine, 0, Bus2),
    % The dopamine level is now zero.
    neuromodulator_bus_level(Bus2, dopamine, Level),
    % Confirm the depleted level.
    assertion(Level =:= 0).

% Depleting dopamine halts three-factor learning - a Parkinson-flavoured trial.
test(depleting_dopamine_stops_learning) :-
    % A bus carrying a full dopamine reward.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, BusRewarded),
    % A drug depletes the dopamine to zero.
    perturbation_interface_shift(BusRewarded, dopamine, 0, BusDepleted),
    % One transmissive interface with both ends active.
    Interfaces0 = [interface(a, b, 0.5, 1, transmissive)],
    % Attempt to learn under the depleted bus.
    plasticity_engine_step(Interfaces0, [a-1, b-1], BusDepleted, 0.1, Interfaces),
    % Read back the interface.
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    % With no dopamine there is no learning; the weight is unchanged.
    assertion(Weight =:= 0.5).

% Close the test block for the perturbation_interface pack.
:- end_tests(perturbation_interface).
