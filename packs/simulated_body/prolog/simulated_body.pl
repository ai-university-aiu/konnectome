% Declare the simulated_body module and the public interface of the stand-in machine.
:- module(simulated_body, [
    % simulated_body_boot/1: boot the stand-in machine - camera clear, battery full, log empty.
    simulated_body_boot/1,
    % simulated_body_show/4: the world shows the camera something new.
    simulated_body_show/4,
    % simulated_body_camera/2: read the camera - what the machine currently sees.
    simulated_body_camera/2,
    % simulated_body_physical/2: read the physical state - what the machine currently is.
    simulated_body_physical/2,
    % simulated_body_actuators/2: read the movement log - what the machine has done, in order.
    simulated_body_actuators/2,
    % simulated_body_enact/3: drive one actuator command, changing the body honestly.
    simulated_body_enact/3,
    % simulated_body_drain/3: the physics tick - the battery empties as time passes.
    simulated_body_drain/3
]).

% Use the list library.
:- use_module(library(lists)).

/*  simulated_body — the honestly-named stand-in machine (Rung Five groundwork).

    WHAT THIS IS, AND WHAT IT IS NOT. The guiding book's Rung Five - the
    embodied rung - asks for a ROBOT BODY IN THE REAL WORLD: "perception in,
    action out, the loop closed through a real machine." No software pack can
    round itself up to that, and this one does not try: it is a SIMULATED
    body, named so in its own name, built so the body interface - the seam a
    real robot would one day plug into - can be built and tested today. The
    rung is NOT claimed; the capstone's honest-limits line still names
    embodiment, correctly, and keeps naming it.

    THE MACHINE, KEPT SMALL. The body is one term:
    simulated_body(camera(Seen), physical(State), actuators(Log)) - a camera
    reporting what stands in the path ahead, a physical state carrying the
    battery charge as a fraction of full, and an ordered log of every actuator
    command the machine has enacted, most recent last, so a test can watch
    that a movement really happened. Three actuator commands exist:
    steer_around (clears a seen obstacle - and is refused by name when the
    path is already clear, because a steer around nothing is a lie),
    recharge (fills the battery back to its full charge, capped there), and
    hold_still (does nothing but say so in the log). The physics is one
    predicate: a drain that lowers the charge and floors at empty - a battery
    cannot go below empty, and that floor is documented physics, not a silent
    clamp of a refused input (a NEGATIVE drain, which would charge the battery
    by stealth, is refused by name).

    THE ONE RULE THIS PACK ADDS: none - it is a world, not a mind. It imports
    no sibling and holds no state between calls; every predicate maps one body
    term to another, deterministically, so every trial over it replays
    byte-identically.
*/

% simulated_body_boot(-Body): boot the stand-in machine.
simulated_body_boot(simulated_body(camera([path_ahead-clear]),
                                   physical([battery_charge-1.0]),
                                   actuators([]))).

% simulated_body_show(+Body0, +Key, +Value, -Body): the world shows the camera something new.
simulated_body_show(Body0, Key, Value, simulated_body(camera(Camera), Physical, Actuators)) :-
    % Only a well-formed body can be shown anything.
    simulated_body_check(Body0, simulated_body_show/4),
    % What is shown must be fully named.
    ground(Key-Value),
    % Open the body.
    Body0 = simulated_body(camera(Camera0), Physical, Actuators),
    % Replace the key's reading with the new sight.
    simulated_body_put(Camera0, Key, Value, Camera).

% simulated_body_camera(+Body, -Camera): read what the machine currently sees.
simulated_body_camera(Body, Camera) :-
    % Only a well-formed body has a camera.
    simulated_body_check(Body, simulated_body_camera/2),
    % Open the camera.
    Body = simulated_body(camera(Camera), _Physical, _Actuators).

% simulated_body_physical(+Body, -Physical): read what the machine currently is.
simulated_body_physical(Body, Physical) :-
    % Only a well-formed body has a physical state.
    simulated_body_check(Body, simulated_body_physical/2),
    % Open the physical state.
    Body = simulated_body(_Camera, physical(Physical), _Actuators).

% simulated_body_actuators(+Body, -Log): read what the machine has done, in order.
simulated_body_actuators(Body, Log) :-
    % Only a well-formed body has a movement log.
    simulated_body_check(Body, simulated_body_actuators/2),
    % Open the log.
    Body = simulated_body(_Camera, _Physical, actuators(Log)).

% simulated_body_enact(+Body0, +Command, -Body): drive one actuator command.
simulated_body_enact(Body0, Command, Body) :-
    % Only a well-formed body can move.
    simulated_body_check(Body0, simulated_body_enact/3),
    % Drive the named actuator.
    simulated_body_drive(Command, Body0, Body).

% Steering around clears a seen obstacle and logs the movement.
simulated_body_drive(steer_around, simulated_body(camera(Camera0), Physical, actuators(Log0)),
                     simulated_body(camera(Camera), Physical, actuators(Log))) :-
    % Commit to the steer once its name matches.
    !,
    % A steer around nothing is a lie; the path must really hold an obstacle.
    (   memberchk(path_ahead-obstacle, Camera0)
    ->  true
    ;   throw(error(simulated_body_nothing_to_steer_around,
                    context(simulated_body_enact/3, "the path ahead is already clear")))
    ),
    % The movement takes the machine around the obstacle: the path reads clear again.
    simulated_body_put(Camera0, path_ahead, clear, Camera),
    % The movement is logged, most recent last.
    append(Log0, [steer_around], Log).
% Recharging fills the battery back to full, capped there, and logs the act.
simulated_body_drive(recharge, simulated_body(Camera, physical(Physical0), actuators(Log0)),
                     simulated_body(Camera, physical(Physical), actuators(Log))) :-
    % Commit to the recharge once its name matches.
    !,
    % The charger fills the battery to its full charge, never past it.
    simulated_body_put(Physical0, battery_charge, 1.0, Physical),
    % The act is logged, most recent last.
    append(Log0, [recharge], Log).
% Holding still changes nothing but the log.
simulated_body_drive(hold_still, simulated_body(Camera, Physical, actuators(Log0)),
                     simulated_body(Camera, Physical, actuators(Log))) :-
    % Commit to the stillness once its name matches.
    !,
    % Even doing nothing is logged, so the history stays whole.
    append(Log0, [hold_still], Log).
% A command the actuators do not carry is refused by name, never guessed at.
simulated_body_drive(Command, _Body0, _Body) :-
    % Refuse the unknown command rather than inventing a movement.
    throw(error(simulated_body_unknown_command(Command),
                context(simulated_body_enact/3, "the machine carries only steer_around, recharge, and hold_still"))).

% simulated_body_drain(+Body0, +Amount, -Body): the battery empties as time passes.
simulated_body_drain(Body0, Amount, simulated_body(Camera, physical(Physical), Actuators)) :-
    % Only a well-formed body can drain.
    simulated_body_check(Body0, simulated_body_drain/3),
    % A drain is a positive fraction of the full charge - a negative drain would charge by stealth.
    (   number(Amount),
        Amount > 0,
        Amount =< 1.0
    ->  true
    ;   throw(error(simulated_body_bad_drain(Amount),
                    context(simulated_body_drain/3, "a drain is a positive fraction of the full charge")))
    ),
    % Open the body.
    Body0 = simulated_body(Camera, physical(Physical0), Actuators),
    % Read the current charge.
    memberchk(battery_charge-Charge, Physical0),
    % The battery empties by the drained amount and floors at empty - documented physics.
    NewCharge is max(0.0, Charge - Amount),
    % Write the new charge.
    simulated_body_put(Physical0, battery_charge, NewCharge, Physical).

% simulated_body_put(+Pairs0, +Key, +Value, -Pairs): replace or add one key's value.
simulated_body_put([], Key, Value, [Key-Value]).
% Replace the matching key's value.
simulated_body_put([Key-_Old|Rest], Key, Value, [Key-Value|Rest]) :-
    % Commit once the key matches.
    !.
% Keep a non-matching pair and continue.
simulated_body_put([Other|Rest0], Key, Value, [Other|Rest]) :-
    % Walk past the pair that is not the key's.
    simulated_body_put(Rest0, Key, Value, Rest).

% simulated_body_check(+Term, +Where): the term is a well-formed simulated body.
simulated_body_check(simulated_body(camera(Camera), physical(Physical), actuators(Log)), _Where) :-
    % The camera readings are a proper list of fully-named pairs.
    is_list(Camera),
    % Every reading is ground.
    ground(Camera),
    % The physical state is a proper list of fully-named pairs.
    is_list(Physical),
    % Every reading is ground.
    ground(Physical),
    % The physical state carries a battery charge.
    memberchk(battery_charge-_Charge, Physical),
    % The movement log is a proper list.
    is_list(Log),
    % A well-formed body needs no further checking.
    !.
% Anything else is refused by name wherever a body is expected.
simulated_body_check(Term, Where) :-
    % Refuse the malformed term rather than sensing nonsense.
    throw(error(simulated_body_malformed_body(Term),
                context(Where, "a simulated body is simulated_body(camera(Seen), physical(State), actuators(Log))"))).
