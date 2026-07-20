% Load the drive_system module under test from the library path.
:- use_module(library(drive_system)).
% Load the neuromodulator_bus module, used to read the broadcast dopamine level.
:- use_module(library(neuromodulator_bus)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).
% Load membership for checking proposed actions.
:- use_module(library(lists), [memberchk/2]).

% Open the test block for the drive_system pack.
:- begin_tests(drive_system).

% Each drive proposes an action to reduce itself, with a salience equal to its error.
test(each_drive_proposes_to_reduce_itself_by_its_error) :-
    % Two fresh drives and a body away from both set-points.
    Drives = [drive(temperature, temperature, 37, none), drive(glucose, glucose, 100, none)],
    drive_system_proposals(Drives, [temperature-40, glucose-90], Candidates),
    % The temperature proposal carries its error of three.
    assertion(memberchk(action(reduce(temperature), 3), Candidates)),
    % The glucose proposal carries its error of ten.
    assertion(memberchk(action(reduce(glucose), 10), Candidates)).

% A reduce action moves the body one step toward the drive's set-point.
test(a_reduce_action_moves_the_body_toward_the_set_point) :-
    % A temperature drive and a body above its set-point.
    Drives = [drive(temperature, temperature, 37, none)],
    drive_system_apply_action(released(reduce(temperature)), Drives, [temperature-40], Body),
    % The body moved one step down toward the set-point.
    assertion(Body == [temperature-39]).

% A non-reduce action leaves the body unchanged.
test(a_non_reduce_action_leaves_the_body_unchanged) :-
    % A temperature drive and a body.
    Drives = [drive(temperature, temperature, 37, none)],
    drive_system_apply_action(released(breathe), Drives, [temperature-40], Body),
    % The body is unchanged by an unrelated action.
    assertion(Body == [temperature-40]).

% A body already at the set-point holds when its reduce action fires.
test(a_body_at_the_set_point_holds) :-
    % A temperature drive and a body exactly at the set-point.
    Drives = [drive(temperature, temperature, 37, none)],
    drive_system_apply_action(released(reduce(temperature)), Drives, [temperature-37], Body),
    % The body holds at the set-point.
    assertion(Body == [temperature-37]).

% A drive's error is the absolute distance of its monitored variable from its set-point.
test(error_is_absolute_distance_from_set_point) :-
    % A temperature drive with set-point thirty-seven, and a body reading of thirty-three.
    drive_system_error(drive(temperature, temperature, 37, none), [temperature-33], Error),
    % The error is the absolute distance, which is four.
    assertion(Error =:= 4).

% The first tick yields no spurious reward, because there is no previous error to improve on.
test(first_tick_yields_no_spurious_reward) :-
    % Start from an empty bus and a single fresh temperature drive.
    neuromodulator_bus_new(Bus0),
    Drives0 = [drive(temperature, temperature, 37, none)],
    % Step once with the body away from the set-point.
    drive_system_step(Drives0, [temperature-40], Bus0, _Drives1, Reward, Bus1),
    % The first tick's reward is zero.
    assertion(Reward =:= 0),
    % And the broadcast dopamine is zero too.
    neuromodulator_bus_level(Bus1, dopamine, Dopamine),
    % Confirm the dopamine level.
    assertion(Dopamine =:= 0).

% The reward equals the total reduction of drive error, and is broadcast as dopamine.
test(reward_equals_total_error_reduction_and_is_dopamine) :-
    % Start from an empty bus and a fresh temperature drive.
    neuromodulator_bus_new(Bus0),
    Drives0 = [drive(temperature, temperature, 37, none)],
    % First tick establishes the previous error at three (forty minus thirty-seven).
    drive_system_step(Drives0, [temperature-40], Bus0, Drives1, _Reward0, Bus1),
    % Second tick moves the body closer, to thirty-nine, so the error falls from three to two.
    drive_system_step(Drives1, [temperature-39], Bus1, _Drives2, Reward, Bus2),
    % The reward is the error reduction of one.
    assertion(Reward =:= 1),
    % The dopamine broadcast equals the reward.
    neuromodulator_bus_level(Bus2, dopamine, Dopamine),
    % Confirm the dopamine level.
    assertion(Dopamine =:= 1).

% Moving away from the set-point produces a negative reward.
test(moving_away_is_negative_reward) :-
    % Start from an empty bus and a fresh temperature drive.
    neuromodulator_bus_new(Bus0),
    Drives0 = [drive(temperature, temperature, 37, none)],
    % First tick establishes the previous error at three.
    drive_system_step(Drives0, [temperature-40], Bus0, Drives1, _Reward0, Bus1),
    % Second tick moves the body further away, to forty-two, so the error rises from three to five.
    drive_system_step(Drives1, [temperature-42], Bus1, _Drives2, Reward, _Bus2),
    % The reward is the negative reduction of minus two.
    assertion(Reward =:= -2).

% Several drives sum their reductions into one reward.
test(multiple_drives_sum_their_reductions) :-
    % Start from an empty bus and two fresh drives.
    neuromodulator_bus_new(Bus0),
    Drives0 = [drive(temperature, temperature, 37, none), drive(glucose, glucose, 100, none)],
    % First tick establishes previous errors of three and ten.
    drive_system_step(Drives0, [temperature-40, glucose-90], Bus0, Drives1, _Reward0, Bus1),
    % Second tick reduces temperature error by one and glucose error by five.
    drive_system_step(Drives1, [temperature-39, glucose-95], Bus1, _Drives2, Reward, _Bus2),
    % The reward is the sum of the two reductions, which is six.
    assertion(Reward =:= 6).

% Close the test block for the drive_system pack.
:- end_tests(drive_system).
