% Load the efference_copy module under test from the library path.
:- use_module(library(efference_copy)).
% Load the stand-in machine the comparator predicts and senses.
:- use_module(library(simulated_body)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).
% Load list utilities used to inspect reading sets.
:- use_module(library(lists), [memberchk/2]).

% Open the test block for the efference_copy pack.
:- begin_tests(efference_copy).

% A helper: a booted machine with an obstacle standing in the path ahead.
efference_copy_test_blocked_body(Body) :-
    simulated_body_boot(Booted),
    simulated_body_show(Booted, path_ahead, obstacle, Body).

% A helper: a booted machine whose battery has already been part-drained.
efference_copy_test_drained_body(Body) :-
    simulated_body_boot(Booted),
    simulated_body_drain(Booted, 0.5, Body).

% ---------------------------------------------------------------------------
% THE COPY IS A DUPLICATE, NOT A DIVERSION
% ---------------------------------------------------------------------------

% The copy carries the command it duplicates, and the command is readable back out of it.
test(the_copy_carries_the_command_it_duplicates) :-
    efference_copy_of(recharge, Copy),
    efference_copy_command(Copy, Command),
    assertion(Command == recharge).

% THE COMMAND STILL REACHES THE ACTUATOR. The corpus's word is "an internal DUPLICATE of that
% command", so the machine must move exactly as it would have without the copy being taken.
test(the_command_still_reaches_the_actuator) :-
    efference_copy_test_drained_body(Body0),
    efference_copy_step(Body0, recharge, still, Body, _Report),
    % The movement is in the machine's own log.
    simulated_body_actuators(Body, Log),
    assertion(Log == [recharge]),
    % And the battery really is full again.
    simulated_body_physical(Body, Physical),
    assertion(memberchk(battery_charge-1.0, Physical)).

% ---------------------------------------------------------------------------
% THE FORWARD MODEL IS A TRANSCRIPTION OF THE MACHINE'S OWN PHYSICS
% ---------------------------------------------------------------------------

% Recharging is predicted to fill the battery to its full charge, which is the machine's own clause.
test(the_forward_model_predicts_a_full_battery_after_a_recharge) :-
    efference_copy_test_drained_body(Body0),
    efference_copy_of(recharge, Copy),
    efference_copy_forward_model(Copy, Body0, Predicted),
    assertion(memberchk(battery_charge-1.0, Predicted)),
    % And it predicts nothing about the path, which the recharger does not touch.
    assertion(memberchk(path_ahead-clear, Predicted)).

% Steering around is predicted to clear the path, which is the machine's own clause.
test(the_forward_model_predicts_a_clear_path_after_a_steer) :-
    efference_copy_test_blocked_body(Body0),
    efference_copy_of(steer_around, Copy),
    efference_copy_forward_model(Copy, Body0, Predicted),
    assertion(memberchk(path_ahead-clear, Predicted)).

% AND THE MODEL IS RIGHT, WHICH IS THE POINT OF A TRANSCRIPTION. The prediction and the world agree
% exactly when the world does nothing of its own.
test(the_forward_model_agrees_with_the_machine_when_the_world_is_still) :-
    efference_copy_test_blocked_body(Body0),
    efference_copy_step(Body0, steer_around, still, _Body, Report),
    efference_copy_report_cue(Report, Cue),
    % Both declared channels matched.
    assertion(Cue == match_cue(matched(2), departed(0))).

% ---------------------------------------------------------------------------
% ATTENUATION - REPORT ONLY WHAT THE WORLD DID
% ---------------------------------------------------------------------------

% A FULLY PREDICTED PASS REPORTS NOTHING AT ALL. This is the chapter's "which is why you cannot tickle
% yourself", falling out of the subtraction rather than being a special case.
test(a_fully_predicted_pass_reports_no_sensation_whatever) :-
    efference_copy_test_blocked_body(Body0),
    efference_copy_step(Body0, steer_around, still, _Body, Report),
    efference_copy_report_attenuated(Report, Attenuated),
    % Nothing survives the subtraction.
    assertion(Attenuated == []).

% AND WHAT THE WORLD DID SURVIVES IT EXACTLY. The drain is not in the mind's command and not in its
% prediction, so the residual carries the world's contribution and nothing else.
test(the_attenuated_reading_is_exactly_what_the_world_did) :-
    efference_copy_test_drained_body(Body0),
    % Recharge, and let time pass by exactly a quarter of a full charge afterwards.
    efference_copy_step(Body0, recharge, drain(0.25), _Body, Report),
    efference_copy_report_attenuated(Report, Attenuated),
    % The prediction was a full battery; the world took a quarter of it away.
    assertion(Attenuated == [battery_charge- -0.25]),
    % The path, which neither the mind nor the world touched, is fully cancelled and absent.
    assertion(\+ memberchk(path_ahead-_Anything, Attenuated)).

% The residual names which channel departed and by how much, in the comparator's own signed form.
test(the_residual_is_signed_and_names_its_own_channel) :-
    efference_copy_test_drained_body(Body0),
    efference_copy_step(Body0, recharge, drain(0.25), _Body, Report),
    efference_copy_report_residuals(Report, Residuals),
    assertion(memberchk(residual(path_ahead, matched), Residuals)),
    assertion(memberchk(residual(battery_charge, departed_by(-0.25)), Residuals)).

% AN EXTERNALLY CAUSED EVENT ON A SYMBOLIC CHANNEL DEPARTS BY NAME, AND NO DISTANCE IS INVENTED
% BETWEEN TWO NAMES.
test(a_symbolic_channel_departs_by_name_and_carries_no_magnitude) :-
    simulated_body_boot(Body0),
    % Hold still while the world puts an obstacle in the path.
    efference_copy_step(Body0, hold_still, shows(path_ahead, obstacle), _Body, Report),
    efference_copy_report_residuals(Report, Residuals),
    assertion(memberchk(residual(path_ahead, departed(clear, obstacle)), Residuals)),
    % And what survives is what the world actually shows.
    efference_copy_report_attenuated(Report, Attenuated),
    assertion(memberchk(path_ahead-obstacle, Attenuated)).

% ---------------------------------------------------------------------------
% OBSERVATION-17 - THE NULL COMMAND SCORES A PERFECT MATCH
% ---------------------------------------------------------------------------

% THE MACHINE DOES NOTHING, THE WORLD DOES NOTHING, AND THE COMPARATOR RETURNS ITS HIGHEST POSSIBLE
% SCORE. A comparator-only sense of agency would award maximum authorship for doing nothing, and this
% test pins that so a later session meets a recorded finding rather than a comfortable number.
test(the_null_command_scores_the_highest_match_the_mechanism_can_produce) :-
    efference_copy_test_blocked_body(Body0),
    efference_copy_step(Body0, hold_still, still, _Body, Report),
    efference_copy_report_cue(Report, Cue),
    % Every declared channel matched - the same score a successful, deliberate steer earns.
    assertion(Cue == match_cue(matched(2), departed(0))),
    % And nothing at all is reported upward.
    efference_copy_report_attenuated(Report, Attenuated),
    assertion(Attenuated == []).

% AND THE SCORE IS INDISTINGUISHABLE FROM A REAL ACT'S, WHICH IS WHY THE CUE IS NOT A VERDICT.
% The deliberate steer and the null command produce the SAME cue term.
test(doing_nothing_and_acting_successfully_produce_the_same_cue) :-
    efference_copy_test_blocked_body(Body0),
    % A real act: the machine steers around a real obstacle and clears it.
    efference_copy_step(Body0, steer_around, still, _ActedBody, ActedReport),
    efference_copy_report_cue(ActedReport, ActedCue),
    % A null act: the machine holds still and the world holds still with it.
    efference_copy_step(Body0, hold_still, still, _StillBody, StillReport),
    efference_copy_report_cue(StillReport, StillCue),
    % The comparator cannot tell them apart, and says so by returning the same term.
    assertion(ActedCue == StillCue).

% ---------------------------------------------------------------------------
% DECISION-13 - THE VERDICT IS REFUSED ALOUD, IN THE CODE
% ---------------------------------------------------------------------------

% A VERDICT OF AGENCY IS NOT A COMPARATOR OUTPUT, AND ASKING FOR ONE THROWS BY NAME. Chapter 63.2.1's
% own closing sentence and Chapter 63.2.4's cue-integration framing are what this refusal cites.
test(a_verdict_of_agency_is_refused_aloud,
     throws(error(efference_copy_agency_is_not_a_comparator_output(_Cue), _Context))) :-
    efference_copy_test_blocked_body(Body0),
    efference_copy_step(Body0, steer_around, still, _Body, Report),
    efference_copy_report_cue(Report, Cue),
    efference_copy_agency_judgement(Cue, _Verdict).

% THE CUE CARRIES COUNTS AND NOT A TAG, which is DECISION-13 as a property of the term rather than a
% paragraph a reader skims.
test(the_cue_carries_counts_and_never_a_tag) :-
    efference_copy_test_drained_body(Body0),
    efference_copy_step(Body0, recharge, drain(0.25), _Body, Report),
    efference_copy_report_cue(Report, Cue),
    assertion(Cue = match_cue(matched(_M), departed(_D))),
    % Neither of the chapter's two tags appears anywhere in the cue.
    assertion(\+ sub_term(self_produced, Cue)),
    assertion(\+ sub_term(externally_caused, Cue)).

% ---------------------------------------------------------------------------
% THE REFUSALS
% ---------------------------------------------------------------------------

% An unbound command is refused rather than copied from whatever it unifies with.
test(an_unbound_command_is_refused,
     throws(error(instantiation_error, _))) :-
    efference_copy_of(_Hole, _Copy).

% A command the actuators do not carry is refused by name, never predicted for.
test(a_command_the_actuators_do_not_carry_is_refused,
     throws(error(domain_error(efference_copy_command, fly), _))) :-
    efference_copy_of(fly, _Copy).

% AN UNRECOGNISED WORLD EVENT IS REFUSED RATHER THAN READ AS STILLNESS, because a world event silently
% dropped would credit the mind with a world it never predicted.
test(an_unrecognised_world_event_is_refused,
     throws(error(domain_error(efference_copy_world_event, earthquake), _))) :-
    simulated_body_boot(Body0),
    efference_copy_step(Body0, hold_still, earthquake, _Body, _Report).

% Two reading sets covering different channels are refused rather than compared position by position.
test(two_misaligned_reading_sets_are_refused,
     throws(error(domain_error(efference_copy_aligned_channels, _Pair), _))) :-
    efference_copy_residuals([path_ahead-clear], [battery_charge-1.0], _Residuals).

% A term that is not a copy is refused aloud, naming what arrived.
test(a_term_that_is_not_a_copy_is_refused,
     throws(error(domain_error(efference_copy, some_other_thing), _))) :-
    efference_copy_command(some_other_thing, _Command).

% A term that is not a report is refused aloud, naming what arrived.
test(a_term_that_is_not_a_report_is_refused,
     throws(error(domain_error(efference_copy_report, some_other_thing), _))) :-
    efference_copy_report_cue(some_other_thing, _Cue).

% Close the test block for the efference_copy pack.
:- end_tests(efference_copy).
