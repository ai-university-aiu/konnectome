% Load the running_prediction module under test from the library path.
:- use_module(library(running_prediction)).
% Load the comparator whose copies and predictions this carrier holds.
:- use_module(library(efference_copy)).
% Load the scheduler, so the derived lag can be checked against the convention it is derived from.
:- use_module(library(tick_engine)).
% Load the stand-in machine that supplies the worlds the predictions are made in.
:- use_module(library(simulated_body)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% Open the test block for the running_prediction pack.
:- begin_tests(running_prediction).

% A helper: a booted machine with an obstacle standing in the path ahead.
running_prediction_test_blocked_body(Body) :-
    simulated_body_boot(Booted),
    simulated_body_show(Booted, path_ahead, obstacle, Body).

% A helper: the two predictions a steer around a real obstacle produces at the moment of issue.
% running_prediction_test_steer(-Copy, -Predicted, -NullPredicted): what the carrier would be handed.
running_prediction_test_steer(Copy, Predicted, NullPredicted) :-
    running_prediction_test_blocked_body(Body0),
    efference_copy_of(steer_around, Copy),
    efference_copy_forward_model(Copy, Body0, Predicted),
    efference_copy_of(hold_still, NullCopy),
    efference_copy_forward_model(NullCopy, Body0, NullPredicted).

% A helper: a carrier holding one steer, issued at the given tick.
% running_prediction_test_carrier(+Tick, -Carrier): a carrier with one prediction in it.
running_prediction_test_carrier(Tick, Carrier) :-
    running_prediction_new(Empty),
    running_prediction_test_steer(Copy, Predicted, NullPredicted),
    running_prediction_retain(Empty, Tick, Copy, Predicted, NullPredicted, Carrier).

% ---------------------------------------------------------------------------
% THE LAG IS DERIVED AND IS NOT WRITTEN DOWN
% ---------------------------------------------------------------------------

% The corpus states the sensory feedback lag in milliseconds, and this pack states it in the same unit.
test(the_lag_is_stated_in_the_corpus_own_unit) :-
    running_prediction_lag_milliseconds(Milliseconds),
    assertion(Milliseconds == 100).

% AND THE TICK COUNT IS COMPUTED FROM IT, NEVER WRITTEN. This test asserts the derivation rather than
% the answer: whatever the scheduler's convention says, the lag follows it.
test(the_lag_in_ticks_is_derived_from_the_convention_rather_than_written_down) :-
    running_prediction_lag_milliseconds(Milliseconds),
    tick_engine_ticks_from_milliseconds(Milliseconds, Expected),
    running_prediction_lag_ticks(Ticks),
    assertion(Ticks == Expected).

% Under DECISION-2's hundred ticks to the second, the corpus's hundred milliseconds is ten ticks
% exactly - which is checked here so that a later session restating the rate sees this test move.
test(the_corpus_lag_lands_exactly_on_a_tick_boundary_today) :-
    running_prediction_lag_ticks(Ticks),
    assertion(Ticks == 10),
    tick_engine_ticks_per_second(PerSecond),
    assertion(PerSecond == 100).

% A prediction issued at a tick comes due one full lag later.
test(a_prediction_comes_due_one_full_lag_after_it_was_issued) :-
    running_prediction_lag_ticks(Lag),
    running_prediction_due_tick(7, DueAt),
    assertion(DueAt =:= 7 + Lag).

% ---------------------------------------------------------------------------
% THE CARRIER HOLDS, AND HOLDS BOTH PREDICTIONS
% ---------------------------------------------------------------------------

% A new carrier holds nothing, and says so as an empty list rather than by failing.
test(a_new_carrier_holds_nothing) :-
    running_prediction_new(Carrier),
    running_prediction_holding(Carrier, Held),
    assertion(Held == []).

% A retained prediction is held, and is held with the tick it was issued at.
test(a_retained_prediction_is_held_with_the_tick_it_was_issued_at) :-
    running_prediction_test_carrier(3, Carrier),
    running_prediction_holding(Carrier, [Held]),
    assertion(Held = running_prediction_retained(3, _Copy, _Predicted, _NullPredicted)).

% THE CARRIER HOLDS BOTH PREDICTIONS AND THE REASON IS THAT BOTH BELONG TO THE MOMENT OF ISSUE.
% Recomputing the null prediction at release time would compute it from a world the command has
% already changed - which would answer a different question, plausibly.
test(the_carrier_holds_the_null_prediction_as_well_as_the_command_one) :-
    running_prediction_test_carrier(0, Carrier),
    running_prediction_lag_ticks(Lag),
    running_prediction_release(Carrier, Lag, [Released], _Stale, _Carrier),
    running_prediction_released_predictions(Released, Predicted, NullPredicted),
    % The steer predicts a clear path; doing nothing predicts the obstacle still standing there.
    assertion(memberchk(path_ahead-clear, Predicted)),
    assertion(memberchk(path_ahead-obstacle, NullPredicted)).

% Predictions are held in issue order, oldest at the front.
test(predictions_are_held_in_issue_order) :-
    running_prediction_test_carrier(1, One),
    running_prediction_test_steer(Copy, Predicted, NullPredicted),
    running_prediction_retain(One, 4, Copy, Predicted, NullPredicted, Two),
    running_prediction_holding(Two, Held),
    assertion(Held = [running_prediction_retained(1, _, _, _),
                      running_prediction_retained(4, _, _, _)]).

% ---------------------------------------------------------------------------
% RELEASE, AND THE THIRD OUTCOME
% ---------------------------------------------------------------------------

% A prediction whose reading has not arrived yet is still waiting, and is neither released nor stale.
test(a_prediction_whose_reading_has_not_arrived_is_still_waiting) :-
    running_prediction_test_carrier(0, Carrier0),
    running_prediction_release(Carrier0, 1, Released, Stale, Carrier),
    assertion(Released == []),
    assertion(Stale == []),
    running_prediction_holding(Carrier, Held),
    assertion(Held = [running_prediction_retained(0, _, _, _)]).

% A prediction whose reading has arrived is released, and leaves the carrier.
test(a_prediction_whose_reading_has_arrived_is_released_and_leaves_the_carrier) :-
    running_prediction_test_carrier(0, Carrier0),
    running_prediction_lag_ticks(Lag),
    running_prediction_release(Carrier0, Lag, [Released], Stale, Carrier),
    running_prediction_released_issued_at(Released, IssuedAt),
    assertion(IssuedAt == 0),
    assertion(Stale == []),
    running_prediction_holding(Carrier, Held),
    assertion(Held == []).

% A PREDICTION WHOSE MOMENT PASSED UNCONSUMED IS REPORTED STALE, NOT DROPPED. This is the supervisor's
% three-outcome discipline applied to a carrier: silence about a missed comparison is how a build comes
% to believe a carrier that lost something had nothing to carry.
test(a_prediction_nobody_released_in_time_is_reported_stale_and_not_dropped) :-
    running_prediction_test_carrier(0, Carrier0),
    running_prediction_lag_ticks(Lag),
    Late is Lag + 5,
    running_prediction_release(Carrier0, Late, Released, [Stale], Carrier),
    assertion(Released == []),
    assertion(Stale == running_prediction_stale(0, Lag)),
    % And it leaves the carrier, because holding it would make every later release stale as well.
    running_prediction_holding(Carrier, Held),
    assertion(Held == []).

% One release can carry all three outcomes at once, which is the case a two-outcome design would lose.
test(one_release_can_report_released_stale_and_waiting_together) :-
    running_prediction_lag_ticks(Lag),
    running_prediction_new(Empty),
    running_prediction_test_steer(Copy, Predicted, NullPredicted),
    % Issued long ago and never collected.
    running_prediction_retain(Empty, 0, Copy, Predicted, NullPredicted, One),
    % Issued so that it comes due exactly now.
    Now is Lag + 3,
    Due is Now - Lag,
    running_prediction_retain(One, Due, Copy, Predicted, NullPredicted, Two),
    % Issued now, so its reading has not arrived.
    running_prediction_retain(Two, Now, Copy, Predicted, NullPredicted, Three),
    running_prediction_release(Three, Now, Released, Stale, Carrier),
    assertion(Released = [running_prediction_released(Due, _)]),
    assertion(Stale == [running_prediction_stale(0, Lag)]),
    running_prediction_holding(Carrier, Held),
    assertion(Held = [running_prediction_retained(Now, _, _, _)]).

% ---------------------------------------------------------------------------
% WHAT THE CARRIER REFUSES
% ---------------------------------------------------------------------------

% TIME DOES NOT RUN BACKWARDS IN A CARRIER. A retention at or before the newest one held is refused
% rather than sorted into place, because sorting would hand a caller that lost its clock a plausible
% ordering back.
test(a_retention_that_does_not_advance_the_clock_is_refused,
     throws(error(domain_error(running_prediction_advancing_tick, 2-5), _))) :-
    running_prediction_test_carrier(5, Carrier),
    running_prediction_test_steer(Copy, Predicted, NullPredicted),
    running_prediction_retain(Carrier, 2, Copy, Predicted, NullPredicted, _Carrier).

% Two predictions retained at one tick are refused for the same reason: one command per tick.
test(two_retentions_at_one_tick_are_refused,
     throws(error(domain_error(running_prediction_advancing_tick, 5-5), _))) :-
    running_prediction_test_carrier(5, Carrier),
    running_prediction_test_steer(Copy, Predicted, NullPredicted),
    running_prediction_retain(Carrier, 5, Copy, Predicted, NullPredicted, _Carrier).

% ONLY A REAL EFFERENCE COPY MAY BE RETAINED, and the judgement is the copy pack's own - so this
% carrier never becomes a second authority on what a copy is.
test(a_term_that_is_not_an_efference_copy_is_refused_by_the_copy_pack_own_guard,
     throws(error(domain_error(efference_copy, some_other_thing), _))) :-
    running_prediction_new(Empty),
    running_prediction_retain(Empty, 0, some_other_thing, [], [], _Carrier).

% An unbound carrier would unify with the empty carrier and read as holding nothing.
test(an_unbound_carrier_is_refused,
     throws(error(instantiation_error, _))) :-
    running_prediction_holding(_Carrier, _Held).

% A term that is not a carrier is refused aloud, naming what arrived.
test(a_term_that_is_not_a_carrier_is_refused,
     throws(error(domain_error(running_prediction_carrier, some_other_thing), _))) :-
    running_prediction_holding(some_other_thing, _Held).

% An unbound tick would compare confidently against every held prediction.
test(an_unbound_release_tick_is_refused,
     throws(error(instantiation_error, _))) :-
    running_prediction_test_carrier(0, Carrier),
    running_prediction_release(Carrier, _Tick, _Released, _Stale, _Carrier).

% A negative tick is not a tick, and is refused rather than compared.
test(a_negative_tick_is_refused,
     throws(error(type_error(nonneg, -1), _))) :-
    running_prediction_new(Empty),
    running_prediction_test_steer(Copy, Predicted, NullPredicted),
    running_prediction_retain(Empty, -1, Copy, Predicted, NullPredicted, _Carrier).

% A prediction that is not a reading set is refused rather than stored.
test(a_prediction_that_is_not_a_reading_set_is_refused,
     throws(error(type_error(list, not_a_reading_set), _))) :-
    running_prediction_new(Empty),
    efference_copy_of(hold_still, Copy),
    running_prediction_retain(Empty, 0, Copy, not_a_reading_set, [], _Carrier).

% The null prediction is judged as strictly as the other, because a hole in it would make exclusivity
% a guess rather than a comparison.
test(a_null_prediction_that_is_a_hole_is_refused,
     throws(error(instantiation_error, _))) :-
    running_prediction_new(Empty),
    efference_copy_of(hold_still, Copy),
    running_prediction_retain(Empty, 0, Copy, [], _NullPredicted, _Carrier).

% A term that is not a release is refused aloud, naming what arrived.
test(a_term_that_is_not_a_release_is_refused,
     throws(error(domain_error(running_prediction_released, some_other_thing), _))) :-
    running_prediction_released_issued_at(some_other_thing, _IssuedAt).

% A carrier holding something that is not a retained prediction is refused rather than sorted.
test(a_carrier_holding_an_impostor_is_refused,
     throws(error(domain_error(running_prediction_retained, some_other_thing), _))) :-
    running_prediction_release(running_prediction_carrier([some_other_thing]), 0,
                               _Released, _Stale, _Carrier).

% Close the test block for the running_prediction pack.
:- end_tests(running_prediction).
