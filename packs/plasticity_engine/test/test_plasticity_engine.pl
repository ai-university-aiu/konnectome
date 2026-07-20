% Load the plasticity_engine module under test from the library path.
:- use_module(library(plasticity_engine)).
% Load the neuromodulator_bus module, used to set the dopamine third factor.
:- use_module(library(neuromodulator_bus)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% Two numbers are close enough when their difference is within a tiny tolerance (floating-point safe).
plasticity_test_close(A, B) :-
    % Compare within a tolerance, since exact decimal fractions are not exact in binary floating point.
    abs(A - B) =< 1.0e-9.

% Open the test block for the plasticity_engine pack.
:- begin_tests(plasticity_engine).

% The weight change is the product of the two activities and the third factor, scaled by the rate.
test(weight_change_is_product_of_activities_and_third_factor) :-
    % Both ends fully active, full dopamine, one-tenth learning rate.
    plasticity_engine_weight_change(1, 1, 1, 0.1, ChangeOne),
    % The change is one-tenth.
    assertion(plasticity_test_close(ChangeOne, 0.1)),
    % Stronger activities and half dopamine.
    plasticity_engine_weight_change(2, 3, 0.5, 0.1, ChangeTwo),
    % The change is two times three, times one half, times one tenth, which is three tenths.
    assertion(plasticity_test_close(ChangeTwo, 0.3)).

% Coincident activity plus dopamine strengthens the connecting weight (the learning test of A4.4).
test(coincidence_and_dopamine_strengthen_the_weight) :-
    % A bus carrying a full dopamine reward.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus),
    % One transmissive interface with a starting weight of one half.
    Interfaces0 = [interface(a, b, 0.5, 1, transmissive)],
    % Both ends active together.
    plasticity_engine_step(Interfaces0, [a-1, b-1], Bus, 0.1, Interfaces),
    % Read back the learned interface.
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    % The weight grew by the three-factor change to six tenths.
    assertion(plasticity_test_close(Weight, 0.6)).

% Without dopamine there is no learning, even when both ends are active (the three-factor property).
test(no_dopamine_means_no_learning) :-
    % A bus with no dopamine, so the third factor reads zero.
    neuromodulator_bus_new(Bus),
    % One transmissive interface.
    Interfaces0 = [interface(a, b, 0.5, 1, transmissive)],
    % Both ends active, but no reward signal.
    plasticity_engine_step(Interfaces0, [a-1, b-1], Bus, 0.1, Interfaces),
    % Read back the interface.
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    % The weight is unchanged; coincidence alone does not learn.
    assertion(Weight =:= 0.5).

% If one end is silent there is no coincidence, so no learning, even with dopamine present.
test(an_inactive_end_means_no_learning) :-
    % A bus carrying full dopamine.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus),
    % One transmissive interface.
    Interfaces0 = [interface(a, b, 0.5, 1, transmissive)],
    % The receiving end is silent.
    plasticity_engine_step(Interfaces0, [a-1, b-0], Bus, 0.1, Interfaces),
    % Read back the interface.
    Interfaces = [interface(a, b, Weight, 1, transmissive)],
    % The weight is unchanged; both ends must fire together.
    assertion(Weight =:= 0.5).

% A computational interface does not learn; only transmissive weights change.
test(a_computational_interface_does_not_learn) :-
    % A bus carrying full dopamine and both ends active.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 1, Bus),
    % One computational interface.
    Interfaces0 = [interface(a, b, 0.5, 1, computational)],
    % Step the learning rule.
    plasticity_engine_step(Interfaces0, [a-1, b-1], Bus, 0.1, Interfaces),
    % Read back the interface.
    Interfaces = [interface(a, b, Weight, 1, computational)],
    % The computational weight is unchanged.
    assertion(Weight =:= 0.5).

% Close the test block for the plasticity_engine pack.
:- end_tests(plasticity_engine).
