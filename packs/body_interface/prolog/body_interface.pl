% Declare the body_interface module and the public interface of the Rung Five groundwork.
:- module(body_interface, [
    % body_interface_energy_drive/1: the drive that defends a full battery - low battery felt as hunger.
    body_interface_energy_drive/1,
    % body_interface_senses/2: the machine's sensors become the mind's senses.
    body_interface_senses/2,
    % body_interface_homeostasis/2: the machine's body state becomes the mind's homeostatic state.
    body_interface_homeostasis/2,
    % body_interface_candidates/4: the pressing drives and the seen reflexes propose; nothing else does.
    body_interface_candidates/4,
    % body_interface_command/2: map the mind's released outcome to the actuator that enacts it.
    body_interface_command/2,
    % body_interface_sense_act_step/7: one closed pass - sense, step, propose, select, command, enact.
    body_interface_sense_act_step/7,
    % body_interface_survival_run/5: the draining-battery run the mind survives of its own accord.
    body_interface_survival_run/5,
    % body_interface_record/4: own the loop's outcome by enacting the loop.
    body_interface_record/4,
    % body_interface_stance/3: the mind's observation-graded stance on its own enacted loop.
    body_interface_stance/3
]).

% Reuse the simulated body: the honestly-named stand-in machine the interface closes its loop through.
:- use_module(library(simulated_body), [
    % simulated_body_camera/2: read the machine's camera.
    simulated_body_camera/2,
    % simulated_body_physical/2: read the machine's physical state.
    simulated_body_physical/2,
    % simulated_body_enact/3: drive one actuator command.
    simulated_body_enact/3,
    % simulated_body_drain/3: the physics tick that empties the battery.
    simulated_body_drain/3
]).
% Reuse the drive system: the set-point machinery that makes a low battery FELT as hunger.
:- use_module(library(drive_system), [
    % drive_system_step/6: one tick of the unchanged drive machinery, reward and broadcast included.
    drive_system_step/6,
    % drive_system_proposals/3: each drive proposes reducing itself, salience equal to its error.
    drive_system_proposals/3
]).
% Reuse the action selector: exactly one action released, proposed and never invented.
:- use_module(library(action_selector), [
    % action_selector_select/2: release exactly one candidate action, or nothing.
    action_selector_select/2
]).
% Reuse the record family so the loop's outcome can be owned on the record.
:- use_module(library(other_minds), [
    % other_minds_individual_record/3: mint the embodied-in-simulation mind as a token individual.
    other_minds_individual_record/3,
    % other_minds_content_record/5: mint the loop's outcome as a state assertion.
    other_minds_content_record/5
]).
% Reuse the provenance scale so the loop reading is graded honestly.
:- use_module(library(self_provenance), [
    % self_provenance_assertion/5: assert about the loop's record, graded and weighted.
    self_provenance_assertion/5
]).
% Reuse PrologAI's Causalontology core so a stanced record can be proven genuinely minted.
:- use_module(library(causal_core), [
    % causal_core_identify/3: re-derive a record's content address from its own content.
    causal_core_identify/3
]).
% Use the list library.
:- use_module(library(lists)).

/*  body_interface — Rung Five OPENED AS GROUNDWORK, and the rung NOT claimed.

    THE BOOK'S CLAIM, AND THIS PACK'S HONEST DISTANCE FROM IT. The guiding
    book's Rung Five names three connections: "the robot's sensors ... become
    the System's senses"; "the robot's body state ... becomes the System's
    homeostatic state ... so that a low battery is felt as hunger"; and "the
    robot's actuators ... become the System's means of acting." Its smoke test
    is the sense-act loop, "closed through a real machine", and its fullest
    trial is homeostatic survival - a robot defending its own body state "of
    its own accord ... the difference between a tool that is driven and an
    agent that is self-driven." THERE IS NO REAL MACHINE HERE. This pack
    builds the three connections as the seam a real robot would one day plug
    into, and closes the same loop through the honestly-named simulated_body
    stand-in. That is GROUNDWORK for the rung - the interface built and tested
    - and it is all this pack claims: the rung itself stays on the capstone's
    honest-limits list, with the book's real-machine reason, until a real
    machine stands on the other side of this seam.

    THE THREE CONNECTIONS, AS BUILT. Senses: the camera's readings surface as
    percept terms, unchanged. Homeostasis: the machine's physical state IS the
    body state the drives defend - an identity mapping made explicit - and the
    energy drive defends battery_charge at a set-point of one exactly as the
    temperature drive defends thirty-seven, so a draining battery is read as a
    growing hunger by the same drive_system_error every other pain passes
    through. Action: the mind's released outcome maps to the actuator that
    enacts it - reduce(energy) to the recharger, the steering reflex to the
    steering - and an outcome no actuator carries is refused by name.

    THE TWO MAPPING CONSTANTS, DECLARED. This pack adds no update rule; it
    adds two named constants of the mapping. The PRESSING THRESHOLD (one
    half): a drive proposal below it is not yet a candidate, so a mind with
    nothing pressing does nothing - and a zero-error proposal never reaches
    the selector at all. The REFLEX SALIENCE (one): a seen obstacle proposes
    steering at a fixed salience, a percept-to-proposal seam kept as small as
    a reflex. Selection stays the action selector's own: one released action,
    proposed and never invented - and at an exact salience TIE the selector
    keeps the earlier candidate in the fixed order, so a starving battery
    outranks a seen obstacle at equal salience: the drives come before the
    reflexes deliberately, and a test pins that tie.

    ON THE RECORD. The loop's outcome is owned BY ENACTING THE LOOP: the
    record predicate runs the sense-act pass itself and mints what that pass
    released, so a hand-written outcome cannot be owned as if the body had
    moved. The stance is graded OBSERVATION at 0.8: the mind ran its own loop
    and read its own actuator log - an actual, lived pass, not a projection
    (a projected or imagined pass would be simulation-graded evidence).
*/

% body_interface_energy_drive(-Drive): the drive that defends a full battery.
body_interface_energy_drive(drive(energy, battery_charge, 1.0, none)).

% body_interface_pressing_threshold(-Threshold): below this error, a drive proposal is not yet pressing.
body_interface_pressing_threshold(0.5).

% body_interface_reflex_salience(-Salience): the fixed salience of a seen-obstacle steering proposal.
body_interface_reflex_salience(1.0).

% body_interface_drain_per_tick(-Amount): the binary-exact charge one survival tick drains.
body_interface_drain_per_tick(0.25).

% body_interface_senses(+Body, -Percepts): the machine's sensors become the mind's senses.
body_interface_senses(Body, Percepts) :-
    % Read the camera through the machine's own interface.
    simulated_body_camera(Body, Camera),
    % Each camera reading surfaces as one percept, unchanged.
    findall(percept(Key, Value), member(Key-Value, Camera), Percepts).

% body_interface_homeostasis(+Body, -BodyState): the machine's body state becomes the mind's.
body_interface_homeostasis(Body, BodyState) :-
    % The physical state IS the homeostatic state - the identity mapping, made explicit.
    simulated_body_physical(Body, BodyState).

% body_interface_candidates(+Percepts, +Drives, +BodyState, -Candidates): who proposes what.
body_interface_candidates(Percepts, Drives, BodyState, Candidates) :-
    % Every drive proposes reducing itself, salience equal to its error - the reused machinery.
    drive_system_proposals(Drives, BodyState, Proposals),
    % Only a pressing proposal becomes a candidate: nothing pressing proposes nothing.
    body_interface_pressing_threshold(Threshold),
    % Keep the proposals at or above the pressing threshold.
    include(body_interface_pressing(Threshold), Proposals, Pressing),
    % A seen obstacle proposes the steering reflex at its fixed salience.
    body_interface_reflex_salience(Salience),
    % Gather one steering proposal per seen obstacle.
    findall(action(steer_around, Salience),
            member(percept(path_ahead, obstacle), Percepts),
            Reflexes),
    % The drives' candidates come first, the reflexes after - a fixed, documented order.
    append(Pressing, Reflexes, Candidates).

% body_interface_pressing(+Threshold, +Proposal): the proposal's salience reaches the threshold.
body_interface_pressing(Threshold, action(_Name, Salience)) :-
    % A pressing proposal carries at least the threshold's salience.
    Salience >= Threshold.

% body_interface_command(+Outcome, -Command): map the released outcome to its actuator.
% The mind's recharge intention drives the recharger.
body_interface_command(released(reduce(energy)), recharge) :-
    % Commit once the outcome matches.
    !.
% The mind's steering release drives the steering.
body_interface_command(released(steer_around), steer_around) :-
    % Commit once the outcome matches.
    !.
% Nothing released holds the machine still - and says so in the log.
body_interface_command(nothing, hold_still) :-
    % Commit once the outcome matches.
    !.
% An outcome no actuator carries is refused by name, never guessed at.
body_interface_command(Outcome, _Command) :-
    % Refuse the unmappable outcome rather than inventing a movement.
    throw(error(body_interface_unmappable_outcome(Outcome),
                context(body_interface_command/2, "only recharge, steering, and stillness have actuators"))).

% body_interface_sense_act_step(+Body0, +Drives0, +Bus0, -Body, -Drives, -Bus, -Outcome):
% one closed pass of the loop - sense, drive step, propose, select, command, enact.
body_interface_sense_act_step(Body0, Drives0, Bus0, Body, Drives, Bus, Outcome) :-
    % PERCEPTION IN: the machine's sensors become the mind's senses.
    body_interface_senses(Body0, Percepts),
    % The machine's body state becomes the mind's homeostatic state.
    body_interface_homeostasis(Body0, BodyState),
    % One tick of the unchanged drive machinery: reward computed, dopamine broadcast.
    drive_system_step(Drives0, BodyState, Bus0, Drives, _Reward, Bus),
    % The pressing drives and the seen reflexes propose.
    body_interface_candidates(Percepts, Drives, BodyState, Candidates),
    % The selector releases exactly one action - proposed, never invented - or nothing.
    action_selector_select(Candidates, Outcome),
    % The released outcome maps to the actuator that enacts it.
    body_interface_command(Outcome, Command),
    % ACTION OUT: the machine moves, and the movement is logged.
    simulated_body_enact(Body0, Command, Body).

% body_interface_survival_run(+Body0, +Drives0, +NumTicks, -Trace, -BodyFinal): the draining-
% battery run - each tick the battery drains, and the mind defends it of its own accord.
body_interface_survival_run(Body0, Drives0, NumTicks, Trace, BodyFinal) :-
    % A run is a positive whole number of ticks.
    (   integer(NumTicks),
        NumTicks >= 1
    ->  true
    ;   throw(error(body_interface_bad_ticks(NumTicks),
                    context(body_interface_survival_run/5, "a survival run is a positive whole number of ticks")))
    ),
    % Live the ticks from the first.
    body_interface_survival_ticks(1, NumTicks, Body0, Drives0, [], Trace, BodyFinal).

% body_interface_survival_ticks(+Tick, +NumTicks, +Body0, +Drives0, +Bus0, -Trace, -BodyFinal):
% live one tick after another until the run's last.
body_interface_survival_ticks(Tick, NumTicks, Body0, _Drives0, _Bus0, [], Body0) :-
    % Past the last tick, the run is over and the body stands as it stands.
    Tick > NumTicks,
    % The run ends here.
    !.
% Within the run, each tick drains the battery, lives one loop pass, and records a trace entry.
body_interface_survival_ticks(Tick, NumTicks, Body0, Drives0, Bus0, [Entry|Trace], BodyFinal) :-
    % PHYSICS: time passes and the battery drains by the tick's fixed amount.
    body_interface_drain_per_tick(Drain),
    % The battery empties a little.
    simulated_body_drain(Body0, Drain, Drained),
    % Read the charge the mind will feel.
    body_interface_homeostasis(Drained, StateAfterDrain),
    % The charge after the drain.
    memberchk(battery_charge-ChargeAfterDrain, StateAfterDrain),
    % One closed pass of the loop over the drained body.
    body_interface_sense_act_step(Drained, Drives0, Bus0, Body, Drives, Bus, Outcome),
    % Read the charge the pass left behind.
    body_interface_homeostasis(Body, StateAfterAct),
    % The charge after the act.
    memberchk(battery_charge-ChargeAfterAct, StateAfterAct),
    % One glass-box trace entry per lived tick.
    Entry = tick(Tick, ChargeAfterDrain, Outcome, ChargeAfterAct),
    % Live the next tick.
    NextTick is Tick + 1,
    % Continue the run.
    body_interface_survival_ticks(NextTick, NumTicks, Body, Drives, Bus, Trace, BodyFinal).

% body_interface_record(+Body0, +Drives0, +Instant, -Record): own the loop's outcome BY ENACTING
% THE LOOP - the record is minted from a pass this predicate itself runs, so a hand-written
% outcome cannot be owned as if the body had moved.
body_interface_record(Body0, Drives0, Instant, Record) :-
    % Run the sense-act pass, right here - the outcome is enacted, not quoted.
    body_interface_sense_act_step(Body0, Drives0, [], _Body, _Drives, _Bus, Outcome),
    % Render the enacted outcome deterministically as the record's content.
    format(string(OutcomeText), "~w", [Outcome]),
    % The embodied-in-simulation mind is minted as a token individual - the holder of its own reading.
    other_minds_individual_record("agent", "konnectome", Individual),
    % Read the mind's content-addressed identifier.
    get_dict(id, Individual, HolderIdentifier),
    % The loop's outcome is minted as a state assertion carrying its enacted content.
    other_minds_content_record(HolderIdentifier, "the_sense_act_loop_outcome_as_enacted",
                               OutcomeText, Instant, Record).

% body_interface_stance(+Record, +Instant, -Stance): the mind stands behind its loop reading.
% The observation grade fits an ENACTED, lived pass exactly: the mind ran its own loop and read
% its own actuator log. A projected or imagined pass would be simulation-graded evidence; this
% pack grades only passes it actually ran - and it PROVES the record was really minted before
% granting that grade: a hand-built look-alike, never enacted, must not be stanced as observed.
body_interface_stance(Record, Instant, Stance) :-
    % Only a genuinely minted loop record can be stanced at the observation grade.
    body_interface_check_minted(Record, Identifier),
    % The stance is graded observation: the mind ran the loop and read the log.
    self_provenance_assertion(Identifier, "observation", 0.8, Instant, Stance).

% body_interface_check_minted(+Record, -Identifier): the record's content address re-derives from
% its own content, and it carries this pack's own loop designator - a forgery is refused by name.
body_interface_check_minted(Record, Identifier) :-
    % The record must be a dictionary carrying an identifier at all.
    is_dict(Record),
    % Read the carried identifier.
    get_dict(id, Record, Identifier),
    % The record must carry this pack's own loop designator - no other record earns this stance.
    get_dict(quality, Record, "the_sense_act_loop_outcome_as_enacted"),
    % Strip the carried identifier to recover the content the address must derive from.
    del_dict(id, Record, _Carried, Body),
    % Re-derive the content address from the record's own content.
    causal_core_identify(Body, state_assertion, RederivedIdentifier),
    % The carried and re-derived addresses must match, byte for byte.
    Identifier == RederivedIdentifier,
    % A genuinely minted record needs no further checking.
    !.
% Anything else is refused by name - the claim and the stance may not come apart.
body_interface_check_minted(Record, _Identifier) :-
    % Refuse the forgery rather than granting it the observation grade.
    throw(error(body_interface_unminted_record(Record),
                context(body_interface_stance/3, "only a genuinely minted loop record can be stanced as observed"))).
