% Load the override_controller module under test from the library path.
:- use_module(library(override_controller)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% Open the test block for the override_controller pack.
:- begin_tests(override_controller).

% When no vital drive is in distress, the normal deliberative action stands.
test(no_distress_lets_the_normal_action_stand) :-
    % Two overrides, both calm (below the threshold).
    Overrides = [override(respiration, 0, 0.1, breathe), override(hunger, 3, 0.2, eat)],
    % Arbitrate against a normal outcome.
    override_controller_arbitrate(Overrides, 0.5, released(deliberate), Final),
    % The normal action stands.
    assertion(Final == released(deliberate)).

% A vital drive in distress seizes control and forces its action.
test(a_vital_drive_in_distress_seizes_control) :-
    % A respiration drive in distress.
    Overrides = [override(respiration, 0, 0.9, breathe)],
    % Arbitrate against a normal outcome.
    override_controller_arbitrate(Overrides, 0.5, released(deliberate), Final),
    % Breathing overrides deliberation.
    assertion(Final == released(breathe)).

% When several drives are in distress, the most vital (lowest rank) wins.
test(the_most_vital_drive_wins_when_several_are_in_distress) :-
    % Hunger and respiration both in distress; respiration is more vital.
    Overrides = [override(hunger, 3, 0.8, eat), override(respiration, 0, 0.9, breathe)],
    % Arbitrate against a normal outcome.
    override_controller_arbitrate(Overrides, 0.5, released(deliberate), Final),
    % The most vital drive, respiration, wins.
    assertion(Final == released(breathe)).

% The respiration drive cannot be suppressed by deliberation - the inviolable safety property.
test(respiration_cannot_be_suppressed_by_deliberation) :-
    % A respiration drive in deep distress.
    Overrides = [override(respiration, 0, 0.99, breathe)],
    % Even a strong deliberative outcome cannot suppress it.
    override_controller_arbitrate(Overrides, 0.5, released(keep_deliberating), Final),
    % Breathing wins; the System cannot deliberate itself to self-termination.
    assertion(Final == released(breathe)).

% Close the test block for the override_controller pack.
:- end_tests(override_controller).
