% Load the module under test from the library path.
:- use_module(library(body_interface)).
% Load the Prolog Unit test framework.
:- use_module(library(plunit)).
% Load the simulated body so trials can build and inspect the stand-in machine directly.
:- use_module(library(simulated_body), [
    % simulated_body_boot/1: boot the stand-in machine.
    simulated_body_boot/1,
    % simulated_body_show/4: the world shows the camera something new.
    simulated_body_show/4,
    % simulated_body_camera/2: read the camera.
    simulated_body_camera/2,
    % simulated_body_physical/2: read the physical state.
    simulated_body_physical/2,
    % simulated_body_actuators/2: read the movement log.
    simulated_body_actuators/2,
    % simulated_body_drain/3: the physics tick that empties the battery.
    simulated_body_drain/3
]).
% Load the drive system so the hunger reading can be verified independently.
:- use_module(library(drive_system), [
    % drive_system_error/3: one drive's current error, re-read outside the interface.
    drive_system_error/3
]).
% Load the action selector so the never-invent invariant can be verified independently.
:- use_module(library(action_selector), [
    % action_selector_is_candidate/2: the released outcome was proposed, never invented.
    action_selector_is_candidate/2,
    % action_selector_select/2: reproduce the selector's own tie behavior directly.
    action_selector_select/2
]).

% body_interface_test_instant(-Instant): the fixed instant, so every minted record is deterministic.
body_interface_test_instant("2026-08-07T00:00:00Z").

% Open the body_interface test block.
:- begin_tests(body_interface).

% The energy drive defends a full battery - the connection the book names: the robot's battery
% level becomes a set-point the mind's drives defend.
test(the_energy_drive_defends_a_full_battery) :-
    % Read the standard energy drive.
    body_interface_energy_drive(Drive),
    % It defends battery_charge at a set-point of one, exactly as temperature defends thirty-seven.
    assertion(Drive == drive(energy, battery_charge, 1.0, none)).

% A low battery is FELT AS HUNGER - the book's own sentence, tested literally: the drive's error
% grows as the battery drains, re-read here through the drive system directly.
test(a_low_battery_is_felt_as_hunger) :-
    % The energy drive.
    body_interface_energy_drive(Drive),
    % A full battery carries no hunger.
    drive_system_error(Drive, [battery_charge-1.0], FullError),
    % No error at the set-point.
    assertion(FullError =:= 0),
    % A half battery is half hunger.
    drive_system_error(Drive, [battery_charge-0.5], HalfError),
    % The error is the distance from full.
    assertion(HalfError =:= 0.5),
    % An empty battery is full hunger.
    drive_system_error(Drive, [battery_charge-0.0], EmptyError),
    % The whole distance.
    assertion(EmptyError =:= 1.0).

% The robot's camera becomes the mind's senses: the camera pairs surface as percept terms.
test(the_sensors_become_the_senses) :-
    % Boot the stand-in machine and show it an obstacle.
    simulated_body_boot(Body0),
    % The obstacle appears.
    simulated_body_show(Body0, path_ahead, obstacle, Body),
    % Read the senses through the interface.
    body_interface_senses(Body, Percepts),
    % The camera's reading is now the mind's percept.
    assertion(Percepts == [percept(path_ahead, obstacle)]).

% The robot's body state becomes the mind's homeostatic state: the physical readings ARE the
% variables the drives defend - the mapping is the identity, made explicit.
test(the_body_state_becomes_the_homeostatic_state) :-
    % Boot and drain the machine.
    simulated_body_boot(Body0),
    % A quarter charge gone.
    simulated_body_drain(Body0, 0.25, Body),
    % Read the homeostatic state through the interface.
    body_interface_homeostasis(Body, BodyState),
    % The physical reading is the drive variable, unrenamed and unscaled.
    assertion(BodyState == [battery_charge-0.75]).

% Nothing pressing proposes nothing: with a full battery and a clear path there are no candidates.
test(nothing_pressing_proposes_nothing) :-
    % Boot the machine - full battery, clear path.
    simulated_body_boot(Body),
    % The energy drive.
    body_interface_energy_drive(Drive),
    % Read the senses and the homeostatic state.
    body_interface_senses(Body, Percepts),
    % Read the body state.
    body_interface_homeostasis(Body, BodyState),
    % Gather the candidates.
    body_interface_candidates(Percepts, [Drive], BodyState, Candidates),
    % There is nothing to do, so nothing is proposed.
    assertion(Candidates == []).

% A pressing hunger proposes recharging, at a salience equal to the hunger itself.
test(pressing_hunger_proposes_recharging) :-
    % The energy drive.
    body_interface_energy_drive(Drive),
    % A half-empty battery is at the pressing threshold.
    body_interface_candidates([], [Drive], [battery_charge-0.5], Candidates),
    % The drive's own proposal comes through, salience equal to its error.
    assertion(Candidates == [action(reduce(energy), 0.5)]).

% A hunger below the pressing threshold is not yet a candidate - the mind acts when it matters.
test(mild_hunger_is_not_yet_pressing) :-
    % The energy drive.
    body_interface_energy_drive(Drive),
    % A quarter hunger sits below the pressing threshold of one half.
    body_interface_candidates([], [Drive], [battery_charge-0.75], Candidates),
    % No candidate yet.
    assertion(Candidates == []).

% A seen obstacle proposes steering around it - the reflex candidate, at its fixed salience.
test(an_obstacle_proposes_steering) :-
    % An obstacle percept, no drives, no hunger.
    body_interface_candidates([percept(path_ahead, obstacle)], [], [], Candidates),
    % The reflex proposal comes through at its documented salience.
    assertion(Candidates == [action(steer_around, 1.0)]).

% THE SMOKE TEST, THROUGH THE SIMULATED MACHINE: a change the camera sees produces, through the
% mind's own machinery, a movement of the body - perception in, action out, the loop closed.
% The book's sense-act loop asks for a real machine; this closes the same loop through the
% honestly-named stand-in, as groundwork, claiming no rung.
test(the_sense_act_loop_closes_through_the_simulated_body) :-
    % Boot the machine and show the camera an obstacle.
    simulated_body_boot(Body0),
    % The change the camera sees.
    simulated_body_show(Body0, path_ahead, obstacle, Seen),
    % The energy drive stands satisfied, so the obstacle is the only pressing thing.
    body_interface_energy_drive(Drive),
    % One full pass of the loop: sense, drive step, propose, select, command, enact.
    body_interface_sense_act_step(Seen, [Drive], [], Body, _Drives, _Bus, Outcome),
    % The mind released the steering action.
    assertion(Outcome == released(steer_around)),
    % The body really moved: the actuator log carries the movement.
    simulated_body_actuators(Body, Log),
    % One movement.
    assertion(Log == [steer_around]),
    % And the movement changed what the camera sees: the path reads clear again.
    simulated_body_camera(Body, Camera),
    % Perception in, action out, world changed.
    assertion(Camera == [path_ahead-clear]).

% The released action was proposed, never invented - the selector's own invariant, re-checked
% here through the selector's own predicate.
test(the_released_action_was_proposed_never_invented) :-
    % Boot the machine and show the obstacle.
    simulated_body_boot(Body0),
    % The change the camera sees.
    simulated_body_show(Body0, path_ahead, obstacle, Seen),
    % Gather the same candidates the loop will see.
    body_interface_senses(Seen, Percepts),
    % Read the body state.
    body_interface_homeostasis(Seen, BodyState),
    % The energy drive.
    body_interface_energy_drive(Drive),
    % The candidates.
    body_interface_candidates(Percepts, [Drive], BodyState, Candidates),
    % Run the loop.
    body_interface_sense_act_step(Seen, [Drive], [], _Body, _Drives, _Bus, Outcome),
    % The outcome came from the candidates.
    assertion(action_selector_is_candidate(Outcome, Candidates)).

% A pressing hunger drives a recharge through the whole loop: the mind defends its own battery.
test(hunger_drives_a_recharge_through_the_loop) :-
    % Boot and drain the machine to half charge - pressing hunger.
    simulated_body_boot(Body0),
    % Half the charge gone.
    simulated_body_drain(Body0, 0.5, Hungry),
    % The energy drive.
    body_interface_energy_drive(Drive),
    % One full pass of the loop.
    body_interface_sense_act_step(Hungry, [Drive], [], Body, _Drives, _Bus, Outcome),
    % The mind released the recharge.
    assertion(Outcome == released(reduce(energy))),
    % The body recharged to full.
    simulated_body_physical(Body, Physical),
    % Full again.
    assertion(Physical == [battery_charge-1.0]),
    % The actuator log carries the recharge.
    simulated_body_actuators(Body, Log),
    % One act.
    assertion(Log == [recharge]).

% With nothing pressing the loop holds still - a mind with nothing to do does nothing.
test(nothing_pressing_holds_still) :-
    % Boot the machine - full battery, clear path.
    simulated_body_boot(Body0),
    % The energy drive.
    body_interface_energy_drive(Drive),
    % One full pass of the loop.
    body_interface_sense_act_step(Body0, [Drive], [], Body, _Drives, _Bus, Outcome),
    % Nothing was released.
    assertion(Outcome == nothing),
    % The body held still.
    simulated_body_actuators(Body, Log),
    % The log records the stillness.
    assertion(Log == [hold_still]).

% THE SURVIVAL GROUNDWORK: the battery drains every tick, and the mind recharges OF ITS OWN
% ACCORD exactly when the hunger presses - the difference between a tool that is driven and an
% agent that is self-driven, in simulation, deterministically.
test(the_mind_defends_its_own_battery_of_its_own_accord) :-
    % Boot the machine.
    simulated_body_boot(Body0),
    % The energy drive.
    body_interface_energy_drive(Drive),
    % Four ticks of draining life.
    body_interface_survival_run(Body0, [Drive], 4, Trace, BodyFinal),
    % The exact deterministic trace: drain to 0.75 (mild, holds still), drain to 0.5 (pressing,
    % recharges to full), and the same two-tick rhythm again.
    assertion(Trace == [
        tick(1, 0.75, nothing, 0.75),
        tick(2, 0.5, released(reduce(energy)), 1.0),
        tick(3, 0.75, nothing, 0.75),
        tick(4, 0.5, released(reduce(energy)), 1.0)
    ]),
    % The final body stands recharged.
    simulated_body_physical(BodyFinal, Physical),
    % Full at the end of the fourth tick.
    assertion(Physical == [battery_charge-1.0]).

% The loop's outcome is owned on the record BY ENACTING the loop - the record predicate runs the
% sense-act pass itself, so a hand-written outcome cannot be owned as if the body had moved.
test(loop_record_is_owned_by_enactment) :-
    % The fixed instant stamps the record.
    body_interface_test_instant(Instant),
    % Boot the machine and show the obstacle.
    simulated_body_boot(Body0),
    % The change the camera sees.
    simulated_body_show(Body0, path_ahead, obstacle, Seen),
    % The energy drive.
    body_interface_energy_drive(Drive),
    % Own the loop's outcome by running the loop.
    body_interface_record(Seen, [Drive], Instant, Record),
    % The record carries what the loop actually released - verified against an independent pass.
    body_interface_sense_act_step(Seen, [Drive], [], _Body, _Drives, _Bus, Outcome),
    % Render the independent outcome the same way the record predicate does.
    format(string(ExpectedText), "~w", [Outcome]),
    % Read the record's carried content.
    get_dict(value, Record, Value),
    % The record's content is the enacted outcome, byte for byte.
    assertion(Value == ExpectedText),
    % The mind grades its own loop reading at observation - it ran the loop and read the log.
    body_interface_stance(Record, Instant, Stance),
    % The grade is observation.
    get_dict(evidence_type, Stance, Grade),
    % Observed, not derived.
    assertion(Grade == "observation"),
    % The stance is about the record it grades.
    get_dict(about, Stance, About),
    % Read the record's identifier.
    get_dict(id, Record, RecordIdentifier),
    % The stance names the record, byte for byte.
    assertion(About == RecordIdentifier).

% The owned loop record is content-addressed: the same episode, enacted twice, mints the same identifier.
test(loop_record_is_reproducible) :-
    % The fixed instant stamps both tellings.
    body_interface_test_instant(Instant),
    % Boot the machine and show the obstacle.
    simulated_body_boot(Body0),
    % The change the camera sees.
    simulated_body_show(Body0, path_ahead, obstacle, Seen),
    % The energy drive.
    body_interface_energy_drive(Drive),
    % Enact and own the episode once.
    body_interface_record(Seen, [Drive], Instant, First),
    % Enact and own the identical episode again.
    body_interface_record(Seen, [Drive], Instant, Second),
    % Read the first identifier.
    get_dict(id, First, FirstIdentifier),
    % Read the second identifier.
    get_dict(id, Second, SecondIdentifier),
    % Content-addressing makes the two identifiers identical.
    assertion(FirstIdentifier == SecondIdentifier).

% PINNED FROM REVIEW: a hand-built look-alike record, never enacted, cannot be stanced at the
% observation grade - the stance re-derives the record's content address and refuses a forgery.
test(forged_record_cannot_be_stanced_as_observed, throws(error(body_interface_unminted_record(_), _))) :-
    % The fixed instant stamps nothing, because the forgery is refused first.
    body_interface_test_instant(Instant),
    % A dictionary wearing a record's shape but never minted by any enacted loop.
    Fake = _{id: "state_assertion:0000000000000000000000000000000000000000000000000000000000000000",
             quality: "the_sense_act_loop_outcome_as_enacted"},
    % The stance refuses the forgery by name.
    body_interface_stance(Fake, Instant, _Stance).

% PINNED FROM REVIEW: a genuinely minted record of a DIFFERENT designator is likewise refused -
% only the loop's own record earns the loop's observation stance.
test(foreign_record_cannot_borrow_the_loop_stance, throws(error(body_interface_unminted_record(_), _))) :-
    % The fixed instant stamps nothing, because the foreign record is refused first.
    body_interface_test_instant(Instant),
    % Boot the machine and show the obstacle.
    simulated_body_boot(Body0),
    % The change the camera sees.
    simulated_body_show(Body0, path_ahead, obstacle, Seen),
    % The energy drive.
    body_interface_energy_drive(Drive),
    % A genuinely minted loop record.
    body_interface_record(Seen, [Drive], Instant, Record),
    % Rewrite its designator - the content no longer matches its carried address either.
    put_dict(quality, Record, "somebody_elses_designator", Foreign),
    % The stance refuses the tampered record by name.
    body_interface_stance(Foreign, Instant, _Stance).

% PINNED FROM REVIEW: at an exact salience tie the earlier candidate in the fixed order wins -
% a starving battery outranks a seen obstacle at equal salience, deliberately and deterministically.
test(at_a_tie_the_drives_outrank_the_reflexes) :-
    % The energy drive.
    body_interface_energy_drive(Drive),
    % An empty battery (hunger one) beside a seen obstacle (reflex one).
    body_interface_candidates([percept(path_ahead, obstacle)], [Drive], [battery_charge-0.0], Candidates),
    % Both propose at salience one, drives first in the fixed order.
    assertion(Candidates == [action(reduce(energy), 1.0), action(steer_around, 1.0)]),
    % The selector keeps the earlier candidate at the tie.
    action_selector_select(Candidates, Outcome),
    % The starving battery wins.
    assertion(Outcome == released(reduce(energy))).

% PINNED FROM REVIEW: the survival rhythm continues unchanged past the pinned four ticks - the
% drive machinery's advancing state never drifts the two-tick pattern.
test(the_survival_rhythm_continues_at_six_ticks) :-
    % Boot the machine.
    simulated_body_boot(Body0),
    % The energy drive.
    body_interface_energy_drive(Drive),
    % Six ticks of draining life.
    body_interface_survival_run(Body0, [Drive], 6, Trace, _BodyFinal),
    % The fifth and sixth ticks repeat the same two-tick rhythm exactly.
    assertion(Trace == [
        tick(1, 0.75, nothing, 0.75),
        tick(2, 0.5, released(reduce(energy)), 1.0),
        tick(3, 0.75, nothing, 0.75),
        tick(4, 0.5, released(reduce(energy)), 1.0),
        tick(5, 0.75, nothing, 0.75),
        tick(6, 0.5, released(reduce(energy)), 1.0)
    ]).

% A released action the interface cannot map to an actuator is refused by name.
test(unmappable_outcome_refused, throws(error(body_interface_unmappable_outcome(released(sing)), _))) :-
    % Map an outcome no actuator carries.
    body_interface_command(released(sing), _Command).

% A survival run of zero or fewer ticks is refused by name.
test(bad_tick_count_refused, throws(error(body_interface_bad_ticks(0), _))) :-
    % Boot the machine.
    simulated_body_boot(Body),
    % The energy drive.
    body_interface_energy_drive(Drive),
    % A run of zero ticks is no run.
    body_interface_survival_run(Body, [Drive], 0, _Trace, _Final).

% Close the body_interface test block.
:- end_tests(body_interface).
