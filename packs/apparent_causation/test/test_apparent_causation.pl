% Load the apparent_causation module under test from the library path.
:- use_module(library(apparent_causation)).
% Load the comparator pack whose degenerate case this pack closes.
:- use_module(library(efference_copy)).
% Load the stand-in machine that supplies the worlds these passes are run in.
:- use_module(library(simulated_body)).
% Load the carrier, because the carried pass is where priority stops being free.
:- use_module(library(running_prediction)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).
% Load list utilities used to inspect condition sets.
:- use_module(library(lists), [memberchk/2]).

% Open the test block for the apparent_causation pack.
:- begin_tests(apparent_causation).

% A helper: a booted machine with an obstacle standing in the path ahead.
apparent_causation_test_blocked_body(Body) :-
    simulated_body_boot(Booted),
    simulated_body_show(Booted, path_ahead, obstacle, Body).

% A helper: a booted machine whose battery has already been part-drained.
apparent_causation_test_drained_body(Body) :-
    simulated_body_boot(Booted),
    simulated_body_drain(Booted, 0.5, Body).

% ---------------------------------------------------------------------------
% THE THREE CONDITIONS THE CORPUS NAMES
% ---------------------------------------------------------------------------

% The corpus names three conditions in one sentence, and the pack names the same three in that order.
test(the_three_conditions_are_the_corpus_own_three_in_the_corpus_own_order) :-
    apparent_causation_conditions(Conditions),
    assertion(Conditions == [priority, consistency, exclusivity]).

% THE NULL COMMAND IS READ OUT OF THE BUILD, NOT DECLARED BY THIS PACK. hold_still is the command
% body_interface_command/2 already maps the selector's "nothing" outcome onto.
test(the_null_command_is_the_build_own_name_for_doing_nothing) :-
    apparent_causation_null_command(Null),
    assertion(Null == hold_still),
    % And it is a command the actuators actually carry, which the comparator's own guard proves.
    efference_copy_of(Null, Copy),
    assertion(Copy == efference_copy(hold_still)).

% ---------------------------------------------------------------------------
% PRIORITY - THE THOUGHT PRECEDES THE ACTION
% ---------------------------------------------------------------------------

% A thought recorded before an action meets the condition.
test(a_thought_recorded_before_an_action_meets_priority) :-
    apparent_causation_priority([wondered, moved], wondered, moved, Condition),
    assertion(Condition == priority(met)).

% A thought recorded AFTER the action does not, and the refusal names both events.
test(a_thought_recorded_after_the_action_does_not_meet_priority) :-
    apparent_causation_priority([moved, wondered], wondered, moved, Condition),
    assertion(Condition == priority(not_met(thought_did_not_precede_action(wondered, moved)))).

% AN EVENT CANNOT PRECEDE ITSELF, which a non-strict comparison would have let through.
test(an_event_does_not_precede_itself) :-
    apparent_causation_priority([moved], moved, moved, Condition),
    assertion(Condition == priority(not_met(thought_did_not_precede_action(moved, moved)))).

% A REPEATED EVENT IS READ AT ITS EARLIEST POSITION, so a thought that recurred after the action still
% counts as having preceded it - which is what "precedes" means about the first occurrence.
test(a_repeated_thought_is_read_at_its_earliest_position) :-
    apparent_causation_priority([wondered, moved, wondered], wondered, moved, Condition),
    assertion(Condition == priority(met)).

% A THOUGHT NOBODY RECORDED IS REFUSED RATHER THAN TREATED AS LATE. An unrecorded event read as
% absent-and-therefore-later would answer a question nothing asked.
test(a_thought_nobody_recorded_is_refused,
     throws(error(existence_error(apparent_causation_recorded_event, daydreamed), _))) :-
    apparent_causation_priority([moved], daydreamed, moved, _Condition).

% An unbound thought is refused, because the position walk would bind it to the first recorded event.
test(an_unbound_thought_is_refused,
     throws(error(instantiation_error, _))) :-
    apparent_causation_priority([wondered, moved], _Thought, moved, _Condition).

% An order that is not a list is refused rather than walked.
test(an_order_that_is_not_a_list_is_refused,
     throws(error(type_error(list, not_an_order), _))) :-
    apparent_causation_priority(not_an_order, wondered, moved, _Condition).

% ---------------------------------------------------------------------------
% CONSISTENCY - THE THOUGHT IS CONSISTENT WITH THE ACTION
% ---------------------------------------------------------------------------

% A cue with no departures is consistent: every channel read as the mind predicted.
test(a_cue_with_no_departures_is_consistent) :-
    apparent_causation_consistency(match_cue(matched(2), departed(0)), Condition),
    assertion(Condition == consistency(met)).

% A cue carrying a departure is not, and the reading carries how many channels departed.
test(a_cue_carrying_a_departure_is_not_consistent) :-
    apparent_causation_consistency(match_cue(matched(1), departed(1)), Condition),
    assertion(Condition == consistency(not_met(channels_departed(1)))).

% A term that is not the comparator's cue is refused aloud, naming what arrived.
test(a_term_that_is_not_a_match_cue_is_refused,
     throws(error(domain_error(apparent_causation_match_cue, some_other_thing), _))) :-
    apparent_causation_consistency(some_other_thing, _Condition).

% A cue carrying a hole where a count belongs is refused rather than compared against zero.
test(a_cue_with_a_hole_where_a_count_belongs_is_refused,
     throws(error(instantiation_error, _))) :-
    apparent_causation_consistency(match_cue(matched(2), departed(_Departed)), _Condition).

% ---------------------------------------------------------------------------
% EXCLUSIVITY - NO OTHER CAUSE IS APPARENT
% ---------------------------------------------------------------------------

% A command whose prediction differs from the null command's is exclusive.
test(a_command_that_predicts_a_difference_is_exclusive) :-
    apparent_causation_exclusivity([path_ahead-clear], [path_ahead-obstacle], Condition),
    assertion(Condition == exclusivity(met)).

% A command whose prediction is the world that already stands is NOT, and says why.
test(a_command_that_predicts_no_difference_is_not_exclusive) :-
    apparent_causation_exclusivity([path_ahead-clear], [path_ahead-clear], Condition),
    assertion(Condition == exclusivity(not_met(command_predicts_no_difference([path_ahead-clear])))).

% Two holes would unify and report a confident non-exclusivity, so a hole is refused first.
test(an_unbound_prediction_is_refused,
     throws(error(instantiation_error, _))) :-
    apparent_causation_exclusivity(_Predicted, [path_ahead-clear], _Condition).

% A prediction that is not a reading set is refused rather than compared.
test(a_prediction_that_is_not_a_reading_set_is_refused,
     throws(error(type_error(list, not_a_reading_set), _))) :-
    apparent_causation_exclusivity([path_ahead-clear], not_a_reading_set, _Condition).

% ---------------------------------------------------------------------------
% OBSERVATION-17'S CLOSER, IN THE EXACT TERMS THE OBSERVATION PINNED
% ---------------------------------------------------------------------------

% THE STEER AROUND A REAL OBSTACLE INFERS AUTHORSHIP. All three conditions hold: the copy preceded the
% command, every channel read as predicted, and the standing world does not explain a cleared path.
test(a_deliberate_steer_around_a_real_obstacle_infers_authorship) :-
    apparent_causation_test_blocked_body(Body0),
    apparent_causation_of_step(Body0, steer_around, still, Judgement),
    apparent_causation_judgement_verdict(Judgement, Verdict),
    assertion(Verdict == authorship_inferred).

% AND HOLDING STILL IN A STILL WORLD DOES NOT, WHICH IS THE WHOLE OF OBSERVATION-17. The comparator
% still awards it a perfect match; exclusivity is what refuses the authorship.
test(holding_still_in_a_still_world_does_not_infer_authorship) :-
    apparent_causation_test_blocked_body(Body0),
    apparent_causation_of_step(Body0, hold_still, still, Judgement),
    apparent_causation_judgement_conditions(Judgement, Conditions),
    % The match is still perfect - nothing about the comparator has been weakened.
    assertion(memberchk(consistency(met), Conditions)),
    % And the priority holds too, which OBSERVATION-20 records as carrying no information.
    assertion(memberchk(priority(met), Conditions)),
    % Exclusivity is the condition that fails, and it fails by name.
    assertion(memberchk(exclusivity(not_met(command_predicts_no_difference(_Predicted))), Conditions)),
    % So authorship is not inferred, and the verdict carries the reason it was not.
    apparent_causation_judgement_verdict(Judgement, Verdict),
    assertion(Verdict = authorship_not_inferred([exclusivity(not_met(_Why))])).

% THE TWO CASES SLICE 56 PROVED IDENTICAL ARE NOW DIFFERENT TERMS. That test asserted a term equality
% between the deliberate steer's cue and the null command's; this one asserts the inequality of the
% judgements built over them, which is what closing OBSERVATION-17 means.
test(doing_nothing_and_acting_successfully_no_longer_produce_the_same_judgement) :-
    apparent_causation_test_blocked_body(Body0),
    apparent_causation_of_step(Body0, steer_around, still, ActedJudgement),
    apparent_causation_of_step(Body0, hold_still, still, StillJudgement),
    % The comparator alone could not tell them apart. The three conditions can.
    assertion(ActedJudgement \== StillJudgement),
    % And the cues they were built over are still the same term, so nothing was fixed by weakening it.
    efference_copy_step(Body0, steer_around, still, _ActedBody, ActedReport),
    efference_copy_report_cue(ActedReport, ActedCue),
    efference_copy_step(Body0, hold_still, still, _StillBody, StillReport),
    efference_copy_report_cue(StillReport, StillCue),
    assertion(ActedCue == StillCue).

% AND THE RULE IS ABOUT THE DIFFERENCE A COMMAND MAKES, NOT ABOUT ITS NAME. A steer issued at an
% already-clear path is not the null command and is still not exclusive, which is the case a rule
% written to ban hold_still by name would have got wrong.
%
% THE CASE IS SHOWN AT THE FORWARD MODEL RATHER THAN THROUGH A FULL PASS, AND WHY IS THE INTERESTING
% PART: simulated_body_enact/3 REFUSES a steer with nothing to steer around, by name, so this
% degenerate command cannot reach the comparator at all. The exclusivity rule and a refusal the build
% has carried since the machine was written turn out to agree about the same case, arrived at from two
% directions - which is the strongest evidence available that the reading is not fitted to its example.
test(a_steer_at_an_already_clear_path_is_not_exclusive_either) :-
    simulated_body_boot(Body0),
    % The steer's own forward model, from a world whose path already reads clear.
    efference_copy_of(steer_around, Copy),
    efference_copy_forward_model(Copy, Body0, Predicted),
    % The null command's forward model, from the same world.
    apparent_causation_null_command(Null),
    efference_copy_of(Null, NullCopy),
    efference_copy_forward_model(NullCopy, Body0, NullPredicted),
    % They agree, so the standing world already explains everything the steer predicted.
    apparent_causation_exclusivity(Predicted, NullPredicted, Condition),
    assertion(Condition = exclusivity(not_met(command_predicts_no_difference(_Predicted)))).

% AND THE MACHINE ITSELF REFUSES THE ENACTMENT, which is recorded here rather than left implicit.
test(the_machine_itself_refuses_a_steer_with_nothing_to_steer_around,
     throws(error(simulated_body_nothing_to_steer_around, _))) :-
    simulated_body_boot(Body0),
    apparent_causation_of_step(Body0, steer_around, still, _Judgement).

% A recharge at a full battery is the same shape on the other channel: nothing the world was not
% already going to show.
test(a_recharge_at_a_full_battery_does_not_infer_authorship) :-
    simulated_body_boot(Body0),
    apparent_causation_of_step(Body0, recharge, still, Judgement),
    apparent_causation_judgement_verdict(Judgement, Verdict),
    assertion(Verdict = authorship_not_inferred([exclusivity(not_met(_Why))])).

% And a recharge at a drained battery does infer authorship, because it makes a difference.
test(a_recharge_at_a_drained_battery_infers_authorship) :-
    apparent_causation_test_drained_body(Body0),
    apparent_causation_of_step(Body0, recharge, still, Judgement),
    apparent_causation_judgement_verdict(Judgement, Verdict),
    assertion(Verdict == authorship_inferred).

% A WORLD THAT ACTS ON ITS OWN ACCOUNT BREAKS CONSISTENCY, which is the condition that was always
% going to carry that case. The steer is exclusive and prior, and still no authorship is inferred.
test(a_world_that_acts_on_its_own_account_breaks_consistency) :-
    apparent_causation_test_blocked_body(Body0),
    apparent_causation_of_step(Body0, steer_around, drain(0.25), Judgement),
    apparent_causation_judgement_conditions(Judgement, Conditions),
    assertion(memberchk(exclusivity(met), Conditions)),
    assertion(memberchk(consistency(not_met(channels_departed(1))), Conditions)),
    apparent_causation_judgement_verdict(Judgement, Verdict),
    assertion(Verdict = authorship_not_inferred([consistency(not_met(_Why))])).

% ---------------------------------------------------------------------------
% THE CONJUNCTION, AND NOTHING MORE THAN IT
% ---------------------------------------------------------------------------

% Three met conditions infer authorship - the corpus's own "and", and no weighting.
test(three_met_conditions_infer_authorship) :-
    apparent_causation_authorship([priority(met), consistency(met), exclusivity(met)], Verdict),
    assertion(Verdict == authorship_inferred).

% EVERY UNMET CONDITION IS CARRIED INTO THE VERDICT WITH ITS REASON, so a refusal says which of the
% three failed rather than only that one did.
test(every_unmet_condition_is_carried_into_the_verdict_with_its_reason) :-
    apparent_causation_authorship([priority(not_met(late)),
                                   consistency(met),
                                   exclusivity(not_met(no_difference))],
                                  Verdict),
    assertion(Verdict == authorship_not_inferred([priority(not_met(late)),
                                                  exclusivity(not_met(no_difference))])).

% A MISSING CONDITION IS NOT A MET ONE. A set that names only two of the three is refused aloud rather
% than read as a conjunction over whatever happened to be present.
test(a_missing_condition_is_refused_rather_than_read_as_met,
     throws(error(existence_error(apparent_causation_condition, exclusivity), _))) :-
    apparent_causation_authorship([priority(met), consistency(met)], _Verdict).

% A condition carrying a reading that is neither met nor not_met is refused rather than counted.
test(a_condition_with_an_unreadable_reading_is_refused,
     throws(error(domain_error(apparent_causation_condition_reading, probably), _))) :-
    apparent_causation_authorship([priority(probably), consistency(met), exclusivity(met)], _Verdict).

% A set of conditions that is not a list is refused rather than walked.
test(a_condition_set_that_is_not_a_list_is_refused,
     throws(error(type_error(list, not_a_condition_set), _))) :-
    apparent_causation_authorship(not_a_condition_set, _Verdict).

% ---------------------------------------------------------------------------
% READING A JUDGEMENT
% ---------------------------------------------------------------------------

% A judgement carries its three conditions in the corpus's order, beside the verdict they produced.
test(a_judgement_carries_its_conditions_in_the_corpus_order) :-
    apparent_causation_test_blocked_body(Body0),
    apparent_causation_of_step(Body0, steer_around, still, Judgement),
    apparent_causation_judgement_conditions(Judgement, [First, Second, Third]),
    assertion(First = priority(_P)),
    assertion(Second = consistency(_C)),
    assertion(Third = exclusivity(_E)).

% A term that is not a judgement is refused aloud, naming what arrived.
test(a_term_that_is_not_a_judgement_is_refused,
     throws(error(domain_error(apparent_causation_judgement, some_other_thing), _))) :-
    apparent_causation_judgement_verdict(some_other_thing, _Verdict).

% An unbound judgement is a hole and is refused before anything is read out of it.
test(an_unbound_judgement_is_refused,
     throws(error(instantiation_error, _))) :-
    apparent_causation_judgement_conditions(_Judgement, _Conditions).

% AN UNRECOGNISED COMMAND IS REFUSED BY THE COMPARATOR'S OWN GUARD, so this pack never becomes a
% second authority on what the actuators carry.
test(an_unrecognised_command_is_refused_by_the_comparator_own_guard,
     throws(error(domain_error(efference_copy_command, teleport), _))) :-
    simulated_body_boot(Body0),
    apparent_causation_of_step(Body0, teleport, still, _Judgement).

% ---------------------------------------------------------------------------
% THE CARRIED PASS, WHERE PRIORITY CAN FAIL (slice 67, OBSERVATION-20)
% ---------------------------------------------------------------------------

% A helper: a carrier holding one steer around a real obstacle, issued at the given tick.
% carried_release(+IssuedAt, +Now, -Released): retain a steer and release it when its reading arrives.
carried_release(IssuedAt, Now, Released) :-
    running_prediction_test_world(Copy, Predicted, NullPredicted),
    running_prediction_new(Empty),
    running_prediction_retain(Empty, IssuedAt, Copy, Predicted, NullPredicted, Carrier),
    running_prediction_release(Carrier, Now, [Released], _Stale, _Left).

% A helper: the two predictions a steer around a real obstacle produces at the moment of issue.
% running_prediction_test_world(-Copy, -Predicted, -NullPredicted): what the carrier is handed.
running_prediction_test_world(Copy, Predicted, NullPredicted) :-
    apparent_causation_test_blocked_body(Body0),
    efference_copy_of(steer_around, Copy),
    efference_copy_forward_model(Copy, Body0, Predicted),
    apparent_causation_null_command(Null),
    efference_copy_of(Null, NullCopy),
    efference_copy_forward_model(NullCopy, Body0, NullPredicted).

% THE CARRIED PASS INFERS AUTHORSHIP WHEN THE READING MATCHES WHAT WAS PREDICTED A LAG AGO. The thought
% was issued at tick 0, the reading arrived at tick 10, and the world did what the steer predicted.
test(a_carried_steer_whose_reading_matches_infers_authorship) :-
    running_prediction_lag_ticks(Lag),
    carried_release(0, Lag, Released),
    % The reading that arrived: the path is clear, and the battery is where it was.
    apparent_causation_of_released(Released, Lag,
                                   [path_ahead-clear, battery_charge-1.0], Judgement),
    apparent_causation_judgement_verdict(Judgement, Verdict),
    assertion(Verdict == authorship_inferred).

% AND THIS IS THE WHOLE OF OBSERVATION-20'S CLOSER: PRIORITY CAN NOW FAIL. A caller that presents a
% thought issued AFTER the action it is supposed to have caused gets a refusal, and the refusal names
% both ticks. In the closed pass this case cannot be constructed at all.
test(a_thought_issued_after_its_action_fails_priority_in_the_carried_pass) :-
    running_prediction_lag_ticks(Lag),
    % Build the release by hand at a later issue tick than the action tick it will be judged against.
    running_prediction_test_world(Copy, Predicted, NullPredicted),
    running_prediction_new(Empty),
    running_prediction_retain(Empty, 12, Copy, Predicted, NullPredicted, Carrier),
    Due is 12 + Lag,
    running_prediction_release(Carrier, Due, [Released], _Stale, _Left),
    % Judge it against an action tick EARLIER than the thought that is supposed to have caused it.
    apparent_causation_of_released(Released, 4, [path_ahead-clear, battery_charge-1.0], Judgement),
    apparent_causation_judgement_conditions(Judgement, Conditions),
    assertion(memberchk(priority(not_met(thought_did_not_precede_action(_T, _A))), Conditions)),
    apparent_causation_judgement_verdict(Judgement, Verdict),
    assertion(Verdict = authorship_not_inferred([priority(not_met(_Why))])).

% A THOUGHT SIMULTANEOUS WITH ITS ACTION IS NOT PRIORITY EITHER. The two event names collapse to one
% term and nothing precedes itself - which is the honest answer under a condition called PRIORITY.
test(a_thought_simultaneous_with_its_action_fails_priority) :-
    running_prediction_lag_ticks(Lag),
    carried_release(0, Lag, Released),
    apparent_causation_of_released(Released, 0, [path_ahead-clear, battery_charge-1.0], Judgement),
    apparent_causation_judgement_conditions(Judgement, Conditions),
    assertion(memberchk(priority(not_met(thought_did_not_precede_action(_T, _A))), Conditions)).

% THE CLOSED PASS'S PRIORITY IS STILL FREE AND THAT IS CORRECT RATHER THAN BROKEN, so this test pins
% the distinction: the same three conditions, judged two ways, and only one of them can discriminate on
% priority. A single closed pass takes the copy before it sends the command; there is no other order it
% could honestly record.
test(the_closed_pass_priority_is_still_free_by_design) :-
    apparent_causation_test_blocked_body(Body0),
    apparent_causation_of_step(Body0, steer_around, still, Judgement),
    apparent_causation_judgement_conditions(Judgement, Conditions),
    assertion(memberchk(priority(met), Conditions)).

% The carried pass still refuses authorship for a command that made no difference, exactly as the
% closed pass does - the exclusivity rule is one rule, read through one predicate.
test(a_carried_null_command_still_fails_exclusivity) :-
    running_prediction_lag_ticks(Lag),
    apparent_causation_test_blocked_body(Body0),
    apparent_causation_null_command(Null),
    efference_copy_of(Null, Copy),
    efference_copy_forward_model(Copy, Body0, Predicted),
    running_prediction_new(Empty),
    running_prediction_retain(Empty, 0, Copy, Predicted, Predicted, Carrier),
    running_prediction_release(Carrier, Lag, [Released], _Stale, _Left),
    apparent_causation_of_released(Released, Lag,
                                   [path_ahead-obstacle, battery_charge-1.0], Judgement),
    apparent_causation_judgement_verdict(Judgement, Verdict),
    assertion(Verdict = authorship_not_inferred([exclusivity(not_met(_Why))])).

% A reading that departs from what was predicted a lag ago breaks consistency, in the carried pass as
% in the closed one.
test(a_carried_reading_that_departs_breaks_consistency) :-
    running_prediction_lag_ticks(Lag),
    carried_release(0, Lag, Released),
    % The world put the obstacle back while the prediction was in flight.
    apparent_causation_of_released(Released, Lag,
                                   [path_ahead-obstacle, battery_charge-1.0], Judgement),
    apparent_causation_judgement_conditions(Judgement, Conditions),
    assertion(memberchk(consistency(not_met(channels_departed(1))), Conditions)).

% A term that is not a release is refused by the carrier's own guard, so this pack never becomes a
% second authority on what a release is.
test(a_carried_pass_over_something_that_is_not_a_release_is_refused,
     throws(error(domain_error(running_prediction_released, some_other_thing), _))) :-
    apparent_causation_of_released(some_other_thing, 0, [], _Judgement).

% An unbound action tick would compare confidently against the thought's tick.
test(an_unbound_action_tick_is_refused_in_the_carried_pass,
     throws(error(instantiation_error, _))) :-
    running_prediction_lag_ticks(Lag),
    carried_release(0, Lag, Released),
    apparent_causation_of_released(Released, _ActionTick, [path_ahead-clear, battery_charge-1.0],
                                   _Judgement).

% Close the test block for the apparent_causation pack.
:- end_tests(apparent_causation).
