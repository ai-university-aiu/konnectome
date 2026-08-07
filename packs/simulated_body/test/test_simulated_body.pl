% Load the module under test from the library path.
:- use_module(library(simulated_body)).
% Load the Prolog Unit test framework.
:- use_module(library(plunit)).

% Open the simulated_body test block.
:- begin_tests(simulated_body).

% The booted body carries a camera seeing a clear path, a full battery, and an empty actuator log.
test(boot_shape) :-
    % Boot the simulated body.
    simulated_body_boot(Body),
    % The boot state is exactly the documented one.
    assertion(Body == simulated_body(camera([path_ahead-clear]),
                                     physical([battery_charge-1.0]),
                                     actuators([]))).

% Booting twice yields byte-identical bodies - determinism.
test(boot_is_deterministic) :-
    % Boot once.
    simulated_body_boot(First),
    % Boot again.
    simulated_body_boot(Second),
    % The two boots are identical.
    assertion(First == Second).

% The world can show the camera something new - an obstacle appears in the path.
test(the_world_shows_the_camera_an_obstacle) :-
    % Boot the body.
    simulated_body_boot(Body0),
    % An obstacle appears in the camera's view.
    simulated_body_show(Body0, path_ahead, obstacle, Body),
    % The camera now reports the obstacle.
    simulated_body_camera(Body, Camera),
    % The path ahead reads obstacle.
    assertion(Camera == [path_ahead-obstacle]).

% The camera and the physical state are readable - perception in.
test(sensors_are_readable) :-
    % Boot the body.
    simulated_body_boot(Body),
    % Read the camera.
    simulated_body_camera(Body, Camera),
    % The path is clear at boot.
    assertion(Camera == [path_ahead-clear]),
    % Read the physical state.
    simulated_body_physical(Body, Physical),
    % The battery is full at boot.
    assertion(Physical == [battery_charge-1.0]).

% Steering around an obstacle clears the path and logs the movement - action out.
test(steering_clears_the_obstacle_and_logs_the_movement) :-
    % Boot the body and show an obstacle.
    simulated_body_boot(Body0),
    % The obstacle appears.
    simulated_body_show(Body0, path_ahead, obstacle, Seen),
    % The body steers around it.
    simulated_body_enact(Seen, steer_around, Body),
    % The camera reads clear again - the movement changed what will be seen.
    simulated_body_camera(Body, Camera),
    % The path ahead is clear.
    assertion(Camera == [path_ahead-clear]),
    % The actuator log carries the movement.
    simulated_body_actuators(Body, Log),
    % Exactly one movement was made.
    assertion(Log == [steer_around]).

% Steering with a clear path is refused by name - there is nothing to steer around.
test(steering_with_a_clear_path_refused, throws(error(simulated_body_nothing_to_steer_around, _))) :-
    % Boot the body - the path is clear.
    simulated_body_boot(Body),
    % Try to steer anyway.
    simulated_body_enact(Body, steer_around, _After).

% Recharging fills the battery back to full, capped there, and logs the act.
test(recharging_fills_the_battery_to_full) :-
    % Boot and drain the body.
    simulated_body_boot(Body0),
    % Drain half the charge.
    simulated_body_drain(Body0, 0.5, Drained),
    % Recharge.
    simulated_body_enact(Drained, recharge, Body),
    % Read the physical state.
    simulated_body_physical(Body, Physical),
    % The battery is full again, exactly.
    assertion(Physical == [battery_charge-1.0]),
    % The actuator log carries the recharge.
    simulated_body_actuators(Body, Log),
    % Exactly one act was made.
    assertion(Log == [recharge]).

% Holding still moves nothing and changes nothing but the log.
test(holding_still_only_logs) :-
    % Boot the body.
    simulated_body_boot(Body0),
    % Hold still.
    simulated_body_enact(Body0, hold_still, Body),
    % The camera is unchanged.
    simulated_body_camera(Body, Camera),
    % Still clear.
    assertion(Camera == [path_ahead-clear]),
    % The physical state is unchanged.
    simulated_body_physical(Body, Physical),
    % Still full.
    assertion(Physical == [battery_charge-1.0]),
    % Only the log grew.
    simulated_body_actuators(Body, Log),
    % One held-still entry.
    assertion(Log == [hold_still]).

% The actuator log is ordered, most recent last - the body's own movement history.
test(the_actuator_log_keeps_order) :-
    % Boot the body.
    simulated_body_boot(Body0),
    % Hold still, then recharge after a drain.
    simulated_body_enact(Body0, hold_still, Held),
    % Drain a little.
    simulated_body_drain(Held, 0.25, Drained),
    % Recharge.
    simulated_body_enact(Drained, recharge, Body),
    % The log carries both acts in order.
    simulated_body_actuators(Body, Log),
    % Held still first, recharged second.
    assertion(Log == [hold_still, recharge]).

% Draining lowers the battery by exactly the drained amount.
test(draining_lowers_the_battery) :-
    % Boot the body.
    simulated_body_boot(Body0),
    % Drain a binary-exact quarter charge.
    simulated_body_drain(Body0, 0.25, Body),
    % Read the physical state.
    simulated_body_physical(Body, Physical),
    % Three quarters remain, exactly.
    assertion(Physical == [battery_charge-0.75]).

% A battery cannot go below empty: a drain past zero floors at zero, honestly documented physics.
test(draining_floors_at_empty) :-
    % Boot the body.
    simulated_body_boot(Body0),
    % Drain more than the battery holds.
    simulated_body_drain(Body0, 0.75, Low),
    % Drain past empty.
    simulated_body_drain(Low, 0.75, Body),
    % Read the physical state.
    simulated_body_physical(Body, Physical),
    % The battery rests at empty, never below.
    assertion(Physical == [battery_charge-0.0]).

% A drain that is not a positive number within one charge is refused by name.
test(bad_drain_refused, throws(error(simulated_body_bad_drain(-0.1), _))) :-
    % Boot the body.
    simulated_body_boot(Body),
    % A negative drain would charge the battery by stealth.
    simulated_body_drain(Body, -0.1, _After).

% A command the body's actuators do not know is refused by name, never guessed at.
test(unknown_command_refused, throws(error(simulated_body_unknown_command(fly), _))) :-
    % Boot the body.
    simulated_body_boot(Body),
    % The body has no wings.
    simulated_body_enact(Body, fly, _After).

% A term that is not a simulated body is refused by name wherever a body is expected.
test(malformed_body_refused, throws(error(simulated_body_malformed_body(not_a_body), _))) :-
    % Sense something that is not a body.
    simulated_body_camera(not_a_body, _Camera).

% PINNED FROM REVIEW: showing something to a malformed body is refused by the same name as
% every other malformed-body use.
test(showing_a_malformed_body_refused, throws(error(simulated_body_malformed_body(not_a_body), _))) :-
    % Show an obstacle to something that is not a body.
    simulated_body_show(not_a_body, path_ahead, obstacle, _After).

% PINNED FROM REVIEW: a drain of exactly the full charge is a legal drain that empties the battery.
test(a_full_drain_empties_the_battery_exactly) :-
    % Boot the body.
    simulated_body_boot(Body0),
    % Drain the whole charge.
    simulated_body_drain(Body0, 1.0, Body),
    % Read the physical state.
    simulated_body_physical(Body, Physical),
    % Empty, exactly.
    assertion(Physical == [battery_charge-0.0]).

% Close the simulated_body test block.
:- end_tests(simulated_body).
