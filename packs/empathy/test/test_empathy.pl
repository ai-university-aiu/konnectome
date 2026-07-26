% Load the empathy module under test from the library path.
:- use_module(library(empathy)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).
% Reuse the drive system so the social-pain equivalence can be checked through the very same machinery.
:- use_module(library(drive_system), [
    % drive_system_error/3: the shared error computation both pains must pass through.
    drive_system_error/3,
    % drive_system_step/6: the shared step that turns thwarting into negative reward.
    drive_system_step/6,
    % drive_system_apply_action/4: the shared body response that lets help restore connection.
    drive_system_apply_action/4
]).
% Reuse the neuromodulator bus so the negative affect can be read off the shared broadcast.
:- use_module(library(neuromodulator_bus), [
    % neuromodulator_bus_level/3: read the dopamine level the shared step broadcast.
    neuromodulator_bus_level/3
]).
% Reuse the override controller so the safety ordering over social distress can be checked.
:- use_module(library(override_controller), [
    % override_controller_arbitrate/4: vital drives seize control; social distress must not outrank breath.
    override_controller_arbitrate/4
]).
% Reuse the action selector so the released help can be checked as a genuine, never-invented candidate.
:- use_module(library(action_selector), [
    % action_selector_is_candidate/2: the released action must be one of the proposed candidates.
    action_selector_is_candidate/2
]).

% A fixed instant, so every minted record is deterministic.
empathy_test_instant("2026-07-26T00:00:00Z").

% Open the test block for the empathy pack.
:- begin_tests(empathy).

% The social-connection drive is a well-formed drive defending belonging at its set-point of one.
test(social_connection_drive_is_well_formed) :-
    % Ask for the standard drive.
    empathy_social_connection_drive(Drive),
    % It watches belonging, defends one, and starts with no previous error.
    assertion(Drive == drive(social_connection, belonging, 1, none)).

% Rejection thwarts the defended set-point: the error rises through the same machinery as any drive.
test(rejection_thwarts_the_defended_set_point) :-
    % The standard drive.
    empathy_social_connection_drive(Drive),
    % A connected body carries no error.
    drive_system_error(Drive, [belonging-1], ConnectedError),
    % Reject: the belonging variable is severed.
    empathy_rejection([belonging-1], RejectedBody),
    % The rejected body carries a full error.
    drive_system_error(Drive, RejectedBody, RejectedError),
    % Connection satisfied the set-point.
    assertion(ConnectedError =:= 0),
    % Rejection violated it.
    assertion(RejectedError =:= 1).

% The social-pain claim itself: rejection registers through the IDENTICAL circuitry as physical pain.
test(social_pain_shares_the_physical_circuitry) :-
    % A physical drive thwarted by one unit: temperature one degree from its set-point.
    drive_system_error(drive(temperature, temperature, 37, none), [temperature-38], PhysicalError),
    % The social drive thwarted by one unit: belonging severed from its set-point.
    empathy_social_connection_drive(SocialDrive),
    % The same error predicate reads the social violation.
    drive_system_error(SocialDrive, [belonging-0], SocialError),
    % One machinery, one number: the broken heart and the broken arm share circuitry.
    assertion(PhysicalError =:= SocialError).

% Rejection produces a negative affect on the shared broadcast - the machine form of social pain.
test(rejection_yields_negative_affect) :-
    % A social drive whose previous tick was satisfied.
    Drives = [drive(social_connection, belonging, 1, 0)],
    % The tick after rejection: belonging severed.
    drive_system_step(Drives, [belonging-0], [], _Drives, Reward, Bus),
    % Moving away from the defended set-point earns a negative reward.
    assertion(Reward =:= -1),
    % And the negative reward is broadcast as dopamine on the shared bus.
    neuromodulator_bus_level(Bus, dopamine, Level),
    % The broadcast carries the pain.
    assertion(Level =:= -1).

% Restoration produces the opposite state - relief - through the same machinery.
test(restoration_yields_positive_affect) :-
    % A social drive whose previous tick was rejected.
    Drives = [drive(social_connection, belonging, 1, 1)],
    % The tick after restoration: belonging regained.
    drive_system_step(Drives, [belonging-1], [], _Drives, Reward, _Bus),
    % Moving back to the set-point earns a positive reward.
    assertion(Reward =:= 1).

% The safety ordering holds: a vital drive in distress still seizes control over social helping.
test(respiration_still_overrides_social_distress) :-
    % The respiration override in genuine distress.
    Overrides = [override(respiration, 0, 0.9, breathe)],
    % The normal outcome would have been the helping action.
    override_controller_arbitrate(Overrides, 0.5, released(reduce(social_connection)), Final),
    % Breath seizes control; social distress never outranks it.
    assertion(Final == released(breathe)).

% A modelled distress is a guarded value: its level must lie between zero and one.
test(modelled_distress_is_guarded, throws(error(empathy_bad_distress(_), _))) :-
    % A distress of two is not a level this model admits.
    empathy_modelled_distress(ana, 2, _Distress).

% Resonance: another agent's modelled distress moves the mind's OWN state through its own body.
test(resonance_moves_the_minds_own_state) :-
    % Ana is modelled in full distress.
    empathy_modelled_distress(ana, 1, Distress),
    % The mind's own body is connected.
    empathy_resonance(Distress, [belonging-1], Body),
    % Her modelled distress lowered the mind's own belonging.
    memberchk(belonging-Belonging, Body),
    % The resonance is felt as the mind's own social pain.
    assertion(Belonging =:= 0),
    % And the mind's own drive error rose accordingly.
    empathy_social_connection_drive(Drive),
    % The same shared machinery reads the resonated pain.
    drive_system_error(Drive, Body, Error),
    % Feeling with another is feeling.
    assertion(Error =:= 1).

% Resonance never drives the mind's belonging below the floor of zero.
test(resonance_floors_at_zero) :-
    % Ana is modelled in full distress.
    empathy_modelled_distress(ana, 1, Distress),
    % The mind's own belonging is already severed.
    empathy_resonance(Distress, [belonging-0], Body),
    % The floor holds.
    memberchk(belonging-Belonging, Body),
    % No state below zero.
    assertion(Belonging =:= 0).

% The resonance boundary re-validates: a hand-rolled negative level is refused by name, never obeyed
% (found by the slice-16 adversarial review: an unvalidated term could RAISE belonging above its set-point).
test(resonance_refuses_a_malformed_level, throws(error(empathy_bad_distress(_), _))) :-
    % A negative distress bypassing the constructor is still refused at the boundary.
    empathy_resonance(modelled_distress(ana, -3), [belonging-1], _Body).

% The resonance boundary refuses a term that is not a modelled distress at all, never failing silently.
test(resonance_refuses_a_malformed_term, throws(error(empathy_bad_distress_term(_), _))) :-
    % A term of the wrong shape is refused by name.
    empathy_resonance(distress(ana, 1), [belonging-1], _Body).

% A fractional distress draws a proportionate help that settles belonging AT its set-point
% (found by the same review: the old unit step overshot fractional distances, so help could harm;
% the drive machinery now caps its homeostatic step at the set-point).
test(fractional_distress_shapes_a_proportionate_help) :-
    % The standard social drive alone.
    empathy_social_connection_drive(SocialDrive),
    % Ana in partial distress.
    empathy_modelled_distress(ana, 0.4, Distress),
    % Run the trial from a connected body.
    empathy_trial(Distress, [SocialDrive], [belonging-1], Outcome, Body),
    % The partial pain still selects the helping action.
    assertion(Outcome == released(reduce(social_connection))),
    % And the help settles belonging exactly at the set-point - never past it.
    memberchk(belonging-Belonging, Body),
    % Settled, not overshot.
    assertion(Belonging =:= 1).

% The empathy trial: modelled distress shapes behaviour toward help, through selection, never invention.
test(empathy_trial_shapes_behaviour_toward_help) :-
    % The mind carries a mildly pressing physical drive and a satisfied social drive.
    empathy_social_connection_drive(SocialDrive),
    % Both drives together.
    Drives = [drive(temperature, temperature, 37, none), SocialDrive],
    % The body: temperature half a degree off, belonging connected.
    Body = [temperature-37.5, belonging-1],
    % Without any modelled distress, the pressing physical need wins the selection.
    empathy_modelled_distress(ana, 0, NoDistress),
    % Run the trial with no distress.
    empathy_trial(NoDistress, Drives, Body, CalmOutcome, _CalmBody),
    % The physical need won.
    assertion(CalmOutcome == released(reduce(temperature))),
    % With Ana modelled in full distress, the resonated social pain outweighs the physical need.
    empathy_modelled_distress(ana, 1, FullDistress),
    % Run the trial with full distress.
    empathy_trial(FullDistress, Drives, Body, HelpOutcome, HelpedBody),
    % The helping action won: her distress moved this mind toward help.
    assertion(HelpOutcome == released(reduce(social_connection))),
    % And the help was applied: the mind's own belonging moved back toward its set-point.
    memberchk(belonging-Belonging, HelpedBody),
    % Restoring connection is the help, for both.
    assertion(Belonging =:= 1).

% The released help is always one of the drives' own proposals - never invented.
test(help_is_never_invented) :-
    % The standard social drive.
    empathy_social_connection_drive(SocialDrive),
    % Ana in full distress.
    empathy_modelled_distress(ana, 1, Distress),
    % Run the trial, asking also for the candidates it selected from.
    empathy_trial_candidates(Distress, [SocialDrive], [belonging-1], Candidates, Outcome),
    % The released outcome is one of the proposed candidates.
    assertion(action_selector_is_candidate(Outcome, Candidates)).

% The modelled distress is minted as a shareable attitude record: Ana fears her connection severed.
test(distress_record_is_a_shareable_attitude) :-
    % The fixed instant.
    empathy_test_instant(Instant),
    % Mint Ana's modelled distress.
    empathy_distress_record("ana", Instant, Record),
    % It is an attitude record.
    get_dict(id, Record, Identifier),
    % The identifier carries the attitude scheme.
    assertion(string_concat("attitude:", _, Identifier)),
    % Its holder is the modelled agent, not the signing mind.
    get_dict(holder, Record, Holder),
    % The holder is a token individual.
    assertion(string_concat("token_individual:", _, Holder)),
    % The attitude type is fear - the affective attitude of the standard's own closed enumeration.
    get_dict(attitude_type, Record, Type),
    % Modelled distress is Ana fearing her connection severed.
    assertion(Type == "fears"),
    % And the mint is deterministic: told twice, the same content-addressed identifier.
    empathy_distress_record("ana", Instant, Again),
    % Read the second mint's identifier.
    get_dict(id, Again, AgainIdentifier),
    % Identifier for identifier.
    assertion(Identifier == AgainIdentifier).

% The mind stands behind its social attribution: an assertion graded observation.
test(attribution_stance_is_graded_observation) :-
    % The fixed instant.
    empathy_test_instant(Instant),
    % Mint Ana's modelled distress.
    empathy_distress_record("ana", Instant, Record),
    % Take the stance.
    empathy_attribution_stance(Record, Instant, Stance),
    % The stance is graded observation - the mind watched the rejection happen.
    get_dict(evidence_type, Stance, Grade),
    % Observation, honestly.
    assertion(Grade == "observation"),
    % And the stance is about the distress record itself.
    get_dict(about, Stance, About),
    % Subject and record agree.
    get_dict(id, Record, Identifier),
    % About the attribution.
    assertion(About == Identifier).

% A misattributed distress is retracted - the honest exit, over the mind's own social record.
test(misattribution_is_retracted) :-
    % The fixed instant.
    empathy_test_instant(Instant),
    % Mint Ana's modelled distress and stand behind it.
    empathy_distress_record("ana", Instant, Record),
    % The stance.
    empathy_attribution_stance(Record, Instant, Stance),
    % Ana turns out to be fine: the attribution is withdrawn under the same source.
    empathy_attribution_retract(Stance, "the modelled distress was misattributed; the agent is well", Instant, Retraction),
    % The retraction names what it withdraws.
    get_dict(retracts, Retraction, Retracts),
    % It withdraws the stance.
    get_dict(id, Stance, StanceIdentifier),
    % Rule 10: the same source takes it back.
    assertion(Retracts == StanceIdentifier).

% Close the test block for the empathy pack.
:- end_tests(empathy).
