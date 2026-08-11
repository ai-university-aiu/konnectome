% Load the module under test from the library path.
:- use_module(library(body_interface)).
% Load the Prolog Unit test framework.
:- use_module(library(plunit)).
% Load the carrier, so the sensory feedback lag is READ from where it is derived, never written here.
:- use_module(library(running_prediction), [
    % running_prediction_lag_ticks/1: the corpus's hundred milliseconds, derived into ticks.
    running_prediction_lag_ticks/1
]).
% Load Wegner's three conditions so a judgement can be opened independently of the loop that made it.
:- use_module(library(apparent_causation), [
    % apparent_causation_judgement_conditions/2: read the three conditions out of a judgement.
    apparent_causation_judgement_conditions/2,
    % apparent_causation_judgement_verdict/2: read the authorship verdict out of a judgement.
    apparent_causation_judgement_verdict/2
]).
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

% ---------------------------------------------------------------------------
% SLICE 69 - THE WIRING, AND WHAT IT TELLS APART
% ---------------------------------------------------------------------------

% body_interface_test_lag(-Lag): the sensory feedback lag, read from the carrier that derives it
% rather than written down here. A test that wrote ten would pin this suite to a convention it does
% not own, and would go quietly wrong the day DECISION-2's tick rate is restated.
body_interface_test_lag(Lag) :-
    % The carrier derives the corpus's hundred milliseconds through the scheduler's one conversion.
    running_prediction_lag_ticks(Lag).

% THE SLICE'S OWN PROMISE, MEASURED RATHER THAN ASSERTED: the judged run and the plain run produce
% the SAME TRACE. Principle Four - a slice that promises to change no behaviour proves it against
% the previous build, and when the measurement finds a difference the difference is declared.
test(wiring_the_carrier_in_leaves_the_survival_trace_exactly_as_it_was) :-
    % Boot the machine.
    simulated_body_boot(Body0),
    % The energy drive.
    body_interface_energy_drive(Drive),
    % A run long enough to outlive the lag, so the comparison is not made over an idle carrier.
    body_interface_test_lag(Lag),
    % Four ticks past the lag, so both halves of the two-tick rhythm come due.
    NumTicks is Lag + 4,
    % The plain run, which is the predicate every existing caller uses.
    body_interface_survival_run(Body0, [Drive], NumTicks, PlainTrace, PlainFinal),
    % The judged run, which threads the carrier through the identical loop.
    body_interface_survival_run_judged(Body0, [Drive], NumTicks, JudgedTrace, _Predictions, JudgedFinal),
    % The traces are the same term, entry for entry.
    assertion(PlainTrace == JudgedTrace),
    % And the body the run leaves behind is the same body.
    assertion(PlainFinal == JudgedFinal).

% A RUN SHORTER THAN THE LAG JUDGES NOTHING, AND SAYS SO RATHER THAN LOOKING IDLE. The corpus's
% hundred-millisecond feedback lag is real, so a six-tick run has issued six predictions and had none
% of their readings arrive - and it reports six still waiting rather than an empty judgement list a
% reader could mistake for a wiring that does nothing.
test(a_run_shorter_than_the_lag_judges_nothing_and_is_still_holding_everything) :-
    % Boot the machine.
    simulated_body_boot(Body0),
    % The energy drive.
    body_interface_energy_drive(Drive),
    % Six ticks, which is fewer than the lag.
    body_interface_survival_run_judged(Body0, [Drive], 6, _Trace, Predictions, _BodyFinal),
    % The lag, so this test states the RELATION and not the numbers.
    body_interface_test_lag(Lag),
    % The premise of the test, checked rather than assumed.
    assertion(6 < Lag),
    % Nothing has come due, so nothing has been judged.
    body_interface_predictions_judged(Predictions, Judged),
    % No judgement at all.
    assertion(Judged == []),
    % And every one of the six is still held, named rather than silently absent.
    body_interface_predictions_waiting(Predictions, Waiting),
    % One retained prediction per lived tick.
    assertion(length(Waiting, 6)).

% THE DISCRIMINATION, AND IT IS THE WHOLE POINT OF THE SLICE. The mind holds still at mild hunger and
% recharges at pressing hunger, and the two get DIFFERENT VERDICTS. A wiring that returned the same
% verdict for both would have told nothing apart, however green its tests.
test(the_mind_is_the_author_of_its_recharges_and_not_of_its_stillness) :-
    % Boot the machine.
    simulated_body_boot(Body0),
    % The energy drive.
    body_interface_energy_drive(Drive),
    % The lag, from which both due ticks below are derived.
    body_interface_test_lag(Lag),
    % Four ticks past the lag, so the first two issues both come due inside the run.
    NumTicks is Lag + 4,
    % Live the judged run.
    body_interface_survival_run_judged(Body0, [Drive], NumTicks, _Trace, Predictions, _BodyFinal),
    % The judgements the run's releases produced.
    body_interface_predictions_judged(Predictions, Judged),
    % TICK ONE HELD STILL: its command predicted the world exactly as it already stood.
    FirstDue is 1 + Lag,
    % The judgement of the still tick, found by the tick it was issued at.
    memberchk(body_interface_judged(1, FirstDue, StillVerdict), Judged),
    % Read its three conditions.
    apparent_causation_judgement_conditions(StillVerdict, StillConditions),
    % THE PREDICTION MATCHED PERFECTLY - which is OBSERVATION-17's degenerate case, alive in the loop.
    assertion(memberchk(consistency(met), StillConditions)),
    % AND EXCLUSIVITY REFUSED IT ANYWAY, because doing nothing predicts what nothing predicts.
    assertion(memberchk(exclusivity(not_met(_Reason)), StillConditions)),
    % So no authorship is inferred: a perfect match, correctly denied the credit.
    apparent_causation_judgement_verdict(StillVerdict, StillOutcome),
    % The verdict names the condition that failed rather than merely saying no.
    assertion(StillOutcome = authorship_not_inferred([exclusivity(not_met(_))])),
    % TICK TWO RECHARGED: its command predicted a full battery where doing nothing predicted a drained one.
    SecondDue is 2 + Lag,
    % The judgement of the recharge tick.
    memberchk(body_interface_judged(2, SecondDue, RechargeVerdict), Judged),
    % Read its three conditions.
    apparent_causation_judgement_conditions(RechargeVerdict, RechargeConditions),
    % All three hold: the thought preceded the act, the reading matched it, and it made a difference.
    assertion(RechargeConditions == [priority(met), consistency(met), exclusivity(met)]),
    % So authorship IS inferred, which is the other half of the discrimination.
    apparent_causation_judgement_verdict(RechargeVerdict, RechargeOutcome),
    % The corpus's conjunction over three conditions that all held.
    assertion(RechargeOutcome == authorship_inferred).

% PRIORITY IS MET ACROSS A REAL GAP HERE, WHICH IS WHAT OBSERVATION-20's CLOSURE WAS FOR. In the
% closed pass the thought's tick and the action's tick are the same fact; in the carried pass they are
% two facts a full lag apart, and this test reads that lag off the judgement itself.
test(the_thought_and_the_judgement_stand_one_full_lag_apart) :-
    % Boot the machine.
    simulated_body_boot(Body0),
    % The energy drive.
    body_interface_energy_drive(Drive),
    % The lag.
    body_interface_test_lag(Lag),
    % A run that outlives it.
    NumTicks is Lag + 4,
    % Live the judged run.
    body_interface_survival_run_judged(Body0, [Drive], NumTicks, _Trace, Predictions, _BodyFinal),
    % The judgements, oldest first.
    body_interface_predictions_judged(Predictions, [First|_Rest]),
    % Every judgement carries both ends of the lag.
    assertion(First = body_interface_judged(_IssuedAt, _JudgedAt, _Verdict)),
    % Read the two ticks out of it.
    First = body_interface_judged(IssuedAt, JudgedAt, _Judgement),
    % The reading arrived one full lag after the command went out.
    assertion(JudgedAt - IssuedAt =:= Lag).

% NOTHING GOES STALE IN A LOOP THAT RELEASES EVERY TICK, AND THE EMPTY LIST IS ASSERTED RATHER THAN
% ASSUMED. The third outcome is threaded out on purpose: the day a caller drives this loop with a
% clock that skips a tick, a prediction will miss its due tick and be REPORTED rather than dropped.
test(a_loop_that_releases_every_tick_stales_nothing) :-
    % Boot the machine.
    simulated_body_boot(Body0),
    % The energy drive.
    body_interface_energy_drive(Drive),
    % The lag.
    body_interface_test_lag(Lag),
    % A run well past it, so plenty of predictions have come due and gone.
    NumTicks is Lag + 4,
    % Live the judged run.
    body_interface_survival_run_judged(Body0, [Drive], NumTicks, _Trace, Predictions, _BodyFinal),
    % No prediction missed its moment.
    body_interface_predictions_stale(Predictions, Stale),
    % The third outcome is empty, and is checked rather than left unread.
    assertion(Stale == []),
    % And nothing was lost either: the four that came due were judged and the rest are still held.
    body_interface_predictions_waiting(Predictions, Waiting),
    % A run of the lag plus four has judged four and is still holding exactly the lag's worth.
    assertion(length(Waiting, Lag)).

% A term that is not a judged run's predictions report is refused aloud, naming what arrived.
test(a_term_that_is_not_a_predictions_report_is_refused,
     throws(error(body_interface_not_a_predictions_report(some_other_thing), _))) :-
    % Read judgements out of something that is not a predictions report.
    body_interface_predictions_judged(some_other_thing, _Judged).

% An unbound predictions report would unify with the report term and read as three empty lists -
% which is exactly the shape of "this run judged nothing", answered confidently about no run at all.
test(an_unbound_predictions_report_is_refused,
     throws(error(instantiation_error, _))) :-
    % Read judgements out of a hole.
    body_interface_predictions_judged(_Predictions, _Judged).

% Close the body_interface test block.
:- end_tests(body_interface).
