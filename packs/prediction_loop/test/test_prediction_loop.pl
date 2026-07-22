% Load the prediction_loop module under test from the library path.
:- use_module(library(prediction_loop)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).
% Reuse PrologAI's Causalontology core directly, so the closure tests question the standard itself.
:- use_module(library(causal_core), [causal_core_identity_fields/2, causal_core_identify/3]).
% Import membership checking for inspecting identity-field lists and reason lists.
:- use_module(library(lists), [member/2, memberchk/2]).

% A fixed simulation start, so every minted instant and identifier is deterministic.
prediction_loop_test_simulation_start("2026-01-01T00:00:00Z").

% The hidden object's presence occurrent, minted deterministically for reuse across tests.
prediction_loop_test_hidden_object(OccurrentId) :-
    % The same label always mints the same content-addressed identifier.
    prediction_loop_outcome_type("hidden_object_present", OccurrentId).

% One token_occurrence body for tick seven, assembled from the pack's own minting helpers.
prediction_loop_test_tick_seven_occurrence(Base) :-
    % Use the fixed simulation start.
    prediction_loop_test_simulation_start(SimulationStart),
    % Use the hidden object's occurrent type.
    prediction_loop_test_hidden_object(OccurrentTypeId),
    % Compute tick seven's absolute instant.
    prediction_loop_tick_instant(SimulationStart, 7, InstantString),
    % Assemble the bare token_occurrence body, before any identifier is attached.
    Base = _{type: "token_occurrence", instantiates: OccurrentTypeId, interval: _{start: InstantString}}.

% One tick-seven forecast record, minted through the pack's own export half.
prediction_loop_test_tick_seven_prediction(Record) :-
    % Use the hidden object's occurrent type.
    prediction_loop_test_hidden_object(OccurrentTypeId),
    % Use the predicting construct's own identifier.
    prediction_loop_predictor(PredictorId),
    % Mint the forecast of the hidden object's presence at tick seven, before any outcome exists.
    prediction_loop_record_prediction(OccurrentTypeId, 7, PredictorId, Record).

% Open the test block for the prediction_loop pack.
:- begin_tests(prediction_loop).

% ---------------------------------------------------------------------------
% PART ONE - THE RUNTIME: the loop that was always expressible
% ---------------------------------------------------------------------------

% An expectation recorded at one tick is still held many ticks later.
test(an_expectation_recorded_early_is_still_held_many_ticks_later) :-
    % Name the hidden object.
    prediction_loop_test_hidden_object(OccurrentId),
    % Start from the empty store.
    prediction_loop_store_empty(EmptyStore),
    % Before anything is expected, the store holds nothing.
    assertion(\+ prediction_loop_expected(EmptyStore, OccurrentId, 7, _)),
    % At tick three, expect the object at tick seven.
    prediction_loop_expect(EmptyStore, OccurrentId, 7, StoreAtThree),
    % Other expectations pile up as the ticks pass.
    prediction_loop_expect(StoreAtThree, OccurrentId, 5, StoreAtFour),
    % And keep piling up.
    prediction_loop_expect(StoreAtFour, OccurrentId, 6, StoreAtFive),
    % The tick-seven expectation, recorded at tick three, is still held.
    assertion(prediction_loop_expected(StoreAtFive, OccurrentId, 7, 1.0)).

% An occurrent that was never expected yields no comparison at all.
test(an_occurrent_never_expected_yields_no_comparison) :-
    % Name the hidden object.
    prediction_loop_test_hidden_object(OccurrentId),
    % Start from the empty store.
    prediction_loop_store_empty(EmptyStore),
    % Expect the object at tick seven only.
    prediction_loop_expect(EmptyStore, OccurrentId, 7, Store),
    % A different occurrent has no expectation, so the comparator has nothing to compare.
    prediction_loop_outcome_type("unrelated_noise", UnrelatedId),
    % No comparison for the unexpected occurrent.
    assertion(\+ prediction_loop_compare(Store, UnrelatedId, 7, 1.0, _)),
    % No comparison at a tick with no expectation either.
    assertion(\+ prediction_loop_compare(Store, OccurrentId, 9, 1.0, _)).

% The object-permanence trial: a present reveal matches the expectation, so the error is zero.
test(the_object_permanence_trial_registers_zero_error_when_the_object_is_revealed_present) :-
    % Hide the object across ticks three to six, reveal it present at tick seven.
    prediction_loop_object_permanence_trial([3, 4, 5, 6], 7, present, SignedError),
    % Reality matched the expectation, so there is no surprise.
    assertion(SignedError =:= 0.0).

% The object-permanence trial: an absent reveal contradicts the expectation - a signed surprise.
test(the_object_permanence_trial_registers_a_signed_surprise_when_the_object_is_revealed_absent) :-
    % Hide the object across ticks three to six, reveal it absent at tick seven.
    prediction_loop_object_permanence_trial([3, 4, 5, 6], 7, absent, SignedError),
    % The signed error is the actual (zero) minus the expected (one): a full negative surprise.
    assertion(SignedError =:= -1.0),
    % The sign carries the direction: less arrived than was expected.
    assertion(SignedError < 0.0).

% A graded expectation yields a graded signed error, in both directions.
test(a_graded_expectation_yields_a_graded_signed_error_in_both_directions) :-
    % Name the hidden object.
    prediction_loop_test_hidden_object(OccurrentId),
    % Start from the empty store.
    prediction_loop_store_empty(EmptyStore),
    % Expect only a quarter of full presence at tick two.
    prediction_loop_expect_magnitude(EmptyStore, OccurrentId, 2, 0.25, LowStore),
    % Full presence arrives: the surprise is positive, three quarters more than expected.
    prediction_loop_compare(LowStore, OccurrentId, 2, 1.0, PositiveError),
    % Confirm the positive graded error.
    assertion(PositiveError =:= 0.75),
    % Expect three quarters of full presence at tick three.
    prediction_loop_expect_magnitude(EmptyStore, OccurrentId, 3, 0.75, HighStore),
    % Nothing arrives: the non-arrival comparator scores the miss.
    prediction_loop_compare_absent(HighStore, OccurrentId, 3, NegativeError),
    % Confirm the negative graded error.
    assertion(NegativeError =:= -0.75).

% What actually happened is minted as a reproducible, content-addressed token_occurrence.
test(the_actual_outcome_is_minted_as_a_reproducible_token_occurrence) :-
    % Use the fixed simulation start.
    prediction_loop_test_simulation_start(SimulationStart),
    % Mint the reveal outcome at tick seven.
    prediction_loop_record_outcome(SimulationStart, 7, "screen_lifted", RecordA),
    % Mint the same outcome again.
    prediction_loop_record_outcome(SimulationStart, 7, "screen_lifted", RecordB),
    % Read the first identifier.
    get_dict(id, RecordA, IdA),
    % Read the second identifier.
    get_dict(id, RecordB, IdB),
    % Its identifier carries the token_occurrence scheme prefix.
    assertion(sub_string(IdA, 0, _, _, "token_occurrence:")),
    % The same content always mints the same identifier: content addressing at work.
    assertion(IdA == IdB),
    % The record declares its Causalontology kind.
    get_dict(type, RecordA, Type),
    % Confirm the kind.
    assertion(Type == "token_occurrence").

% ---------------------------------------------------------------------------
% PART TWO - THE EXPORT HALF (new in slice 12): the records Wall-2 demanded,
% mintable since Causalontology 4.0.0 grew the kind list to twenty-one and
% causal_core 1.1.0 learned to content-address the arrivals.
% ---------------------------------------------------------------------------

% A forecast is minted BEFORE the outcome, and is distinguishable from any report by its very kind.
test(a_forecast_is_minted_before_the_outcome_and_differs_from_any_report_of_fact) :-
    % Mint the tick-seven forecast once.
    prediction_loop_test_tick_seven_prediction(PredictionA),
    % Mint the identical forecast again.
    prediction_loop_test_tick_seven_prediction(PredictionB),
    % Read the first forecast's identifier.
    get_dict(id, PredictionA, PredictedIdA),
    % Read the second forecast's identifier.
    get_dict(id, PredictionB, PredictedIdB),
    % The forecast identifier carries the predicted_occurrence scheme prefix.
    assertion(sub_string(PredictedIdA, 0, _, _, "predicted_occurrence:")),
    % The same forecast content always mints the same identifier: content addressing at work.
    assertion(PredictedIdA == PredictedIdB),
    % The record declares its Causalontology kind.
    get_dict(type, PredictionA, Type),
    % Confirm the kind.
    assertion(Type == "predicted_occurrence"),
    % Read the predicted interval back out of the record.
    get_dict(interval, PredictionA, Interval),
    % The interval carries the ordinal dimension: the integer tick the arrival is expected at.
    assertion(get_dict(start_tick, Interval, 7)),
    % And ONLY the ordinal dimension: no wall-clock start rides along (Rule 24 kept it out).
    assertion(\+ get_dict(start, Interval, _)),
    % Now mint the same tick-seven content as a report of fact, a token_occurrence.
    prediction_loop_test_simulation_start(SimulationStart),
    % The report of the same happening at the same tick.
    prediction_loop_record_outcome(SimulationStart, 7, "hidden_object_present", Report),
    % Read the report's identifier.
    get_dict(id, Report, ReportId),
    % The forecast's identifier differs from the report's: a forecast is no longer mistakable for a fact.
    assertion(PredictedIdA \== ReportId).

% The optional strength is identity-bearing when present: a graded forecast differs from a full one.
test(an_optional_strength_is_identity_bearing_when_present) :-
    % Name the hidden object.
    prediction_loop_test_hidden_object(OccurrentTypeId),
    % Name the predicting construct.
    prediction_loop_predictor(PredictorId),
    % Mint a strength-free forecast for tick seven.
    prediction_loop_record_prediction(OccurrentTypeId, 7, PredictorId, PlainPrediction),
    % Mint a graded forecast for the same tick, carrying a quarter strength.
    prediction_loop_record_prediction_strength(OccurrentTypeId, 7, PredictorId, 0.25, GradedPrediction),
    % Read the strength-free identifier.
    get_dict(id, PlainPrediction, PlainId),
    % Read the graded identifier.
    get_dict(id, GradedPrediction, GradedId),
    % Both are minted under the predicted_occurrence scheme.
    assertion(sub_string(GradedId, 0, _, _, "predicted_occurrence:")),
    % The strength is identity-bearing, so the two forecasts have distinct identities.
    assertion(PlainId \== GradedId),
    % The graded record carries its strength for any reader to see.
    assertion(get_dict(strength, GradedPrediction, 0.25)).

% The prediction_error pairs the forecast with the observation and carries the signed discrepancy.
test(the_prediction_error_pairs_forecast_and_observation_with_the_signed_discrepancy) :-
    % Mint the tick-seven forecast.
    prediction_loop_test_tick_seven_prediction(Prediction),
    % Read the forecast's identifier.
    get_dict(id, Prediction, PredictedId),
    % Mint what actually happened at tick seven.
    prediction_loop_test_simulation_start(SimulationStart),
    % The observed arrival, as a token_occurrence.
    prediction_loop_record_outcome(SimulationStart, 7, "hidden_object_present", Outcome),
    % Read the observed outcome's identifier.
    get_dict(id, Outcome, ObservedId),
    % Pair them: reality matched the forecast, so the comparator's signed number is zero.
    prediction_loop_record_prediction_error(PredictedId, ObservedId, 0.0, FulfilledError),
    % Read the fulfilled error's identifier.
    get_dict(id, FulfilledError, FulfilledId),
    % The error identifier carries the prediction_error scheme prefix.
    assertion(sub_string(FulfilledId, 0, _, _, "prediction_error:")),
    % The error names the forecast it grades.
    assertion(get_dict(predicted, FulfilledError, PredictedId)),
    % The error names the observation that graded it.
    assertion(get_dict(observed, FulfilledError, ObservedId)),
    % The error carries the comparator's signed number.
    assertion(get_dict(discrepancy, FulfilledError, 0.0)),
    % Now the unfulfilled case: nothing arrived, so there is no observation to name.
    prediction_loop_record_prediction_error(PredictedId, absent, -1.0, UnfulfilledError),
    % Read the unfulfilled error's identifier.
    get_dict(id, UnfulfilledError, UnfulfilledId),
    % The unfulfilled error is minted under the same scheme.
    assertion(sub_string(UnfulfilledId, 0, _, _, "prediction_error:")),
    % Its observed slot stays absent: a non-happening is recorded as the absence of an observation.
    assertion(\+ get_dict(observed, UnfulfilledError, _)),
    % The observed slot is identity-bearing when present, so the two errors have distinct identities.
    assertion(FulfilledId \== UnfulfilledId).

% The glass-box trial, reveal present: every step ends as a record, and the discrepancy is zero.
test(the_glass_box_trial_reveal_present_ends_in_a_zero_discrepancy_record_naming_the_outcome) :-
    % Use the fixed simulation start.
    prediction_loop_test_simulation_start(SimulationStart),
    % Hide the object across ticks three to six, reveal it present at tick seven, glass-box.
    prediction_loop_object_permanence_trial_records(SimulationStart, [3, 4, 5, 6], 7, present, Trial),
    % Read the minted forecasts.
    get_dict(predictions, Trial, Predictions),
    % One forecast per held tick: four hidden ticks plus the reveal tick.
    assertion(length(Predictions, 5)),
    % Every forecast is a real predicted_occurrence record.
    assertion(forall(member(P, Predictions), (get_dict(id, P, PId), sub_string(PId, 0, _, _, "predicted_occurrence:")))),
    % Read the observed outcome.
    get_dict(outcome, Trial, Outcome),
    % What happened is a real token_occurrence record.
    get_dict(id, Outcome, OutcomeId),
    % Confirm its scheme prefix.
    assertion(sub_string(OutcomeId, 0, _, _, "token_occurrence:")),
    % Read the minted error.
    get_dict(error, Trial, ErrorRecord),
    % Reality matched the forecast, so the recorded discrepancy is zero.
    get_dict(discrepancy, ErrorRecord, Discrepancy),
    % Confirm the zero discrepancy.
    assertion(Discrepancy =:= 0.0),
    % The error names the observed outcome.
    assertion(get_dict(observed, ErrorRecord, OutcomeId)),
    % The runtime comparator's number and the recorded discrepancy are one and the same.
    assertion(get_dict(signed_error, Trial, Discrepancy)).

% The glass-box trial, reveal absent: the surprise is recorded with no observation at all.
test(the_glass_box_trial_reveal_absent_ends_in_a_negative_discrepancy_record_with_no_observation) :-
    % Use the fixed simulation start.
    prediction_loop_test_simulation_start(SimulationStart),
    % Hide the object across ticks three to six, reveal it absent at tick seven, glass-box.
    prediction_loop_object_permanence_trial_records(SimulationStart, [3, 4, 5, 6], 7, absent, Trial),
    % Nothing happened at the reveal, so no token_occurrence was minted.
    assertion(get_dict(outcome, Trial, absent)),
    % Read the minted error.
    get_dict(error, Trial, ErrorRecord),
    % Read the error's identifier.
    get_dict(id, ErrorRecord, ErrorId),
    % The surprise is a real prediction_error record.
    assertion(sub_string(ErrorId, 0, _, _, "prediction_error:")),
    % Its observed slot stays absent: the non-happening is told by the absence itself.
    assertion(\+ get_dict(observed, ErrorRecord, _)),
    % Read the recorded discrepancy.
    get_dict(discrepancy, ErrorRecord, Discrepancy),
    % The full negative surprise: the actual (zero) minus the expected (one).
    assertion(Discrepancy =:= -1.0),
    % The sign carries the direction: less arrived than was expected.
    assertion(Discrepancy < 0.0).

% Rule 24, demonstrated locally: a predicted interval carrying BOTH temporal dimensions is refused.
test(rule_twenty_four_a_predicted_interval_carrying_both_dimensions_raises_dimension_conflict) :-
    % Name the hidden object.
    prediction_loop_test_hidden_object(OccurrentTypeId),
    % Name the predicting construct.
    prediction_loop_predictor(PredictorId),
    % An interval that illegally carries a wall-clock start AND an ordinal start_tick.
    BadInterval = _{start: "2026-01-01T00:00:07Z", start_tick: 7},
    % Try to mint the ill-dimensioned forecast, catching the refusal that must come.
    catch(
        % The minting attempt; reaching the marker would mean nothing was raised.
        ( prediction_loop_record_prediction_interval(OccurrentTypeId, BadInterval, PredictorId, _),
          % The no-refusal marker.
          Raised = none ),
        % The pack raises causal_core's own semantic reasons.
        error(prediction_loop_refused_prediction(Reasons), _),
        % Keep the reasons for inspection.
        Raised = Reasons ),
    % The refusal happened.
    assertion(Raised \== none),
    % And its wording is causal_core's Rule 24 dimension_conflict semantic error.
    assertion(once(( member(Reason, Raised), sub_string(Reason, _, _, _, "dimension_conflict") ))).

% ---------------------------------------------------------------------------
% PART THREE - THE WALL CLOSURE (Wall-2 of the konnectome ledger). At 3.0.0
% these four tests DEMONSTRATED the wall: the export half of the predictive
% loop was not expressible, and the assertions asserted the failures. The wall
% was hit on 2026-07-22, routed through the gated Causalontology change order,
% and CLOSED the same day by Causalontology 4.0.0 (twenty-one kinds) plus
% causal_core 1.1.0. Where a test asserted a kind's ABSENCE it now asserts
% PRESENCE and a full round-trip; whatever remains true by permanent design is
% kept and named as design, not as a wall.
% ---------------------------------------------------------------------------

% Wall face one, CLOSED: the kind list grew from eighteen to twenty-one, and both prediction kinds are in it.
test(wall_closure_the_kind_list_now_holds_twenty_one_kinds_including_both_prediction_kinds) :-
    % Enumerate every kind the standard's identity table defines.
    findall(Kind, causal_core_identity_fields(Kind, _), Kinds),
    % Count them.
    length(Kinds, KindCount),
    % At 3.0.0 this list was closed at eighteen; Causalontology 4.0.0 closed Wall-2 by growing it to twenty-one.
    assertion(KindCount == 21),
    % predicted_occurrence, absent at 3.0.0, is now among them.
    assertion(memberchk(predicted_occurrence, Kinds)),
    % prediction_error, absent at 3.0.0, is now among them too.
    assertion(memberchk(prediction_error, Kinds)),
    % The identity table now has a row for predicted_occurrence: what, when, who foresaw it, how strongly.
    assertion(causal_core_identity_fields(predicted_occurrence, [instantiates, interval, predictor, strength])),
    % And a row for prediction_error: the forecast graded, the observation (optional), the signed number.
    assertion(causal_core_identity_fields(prediction_error, [predicted, observed, discrepancy])),
    % Content addressing, which refused these kinds at 3.0.0, now mints them: a full forecast round-trip.
    prediction_loop_test_tick_seven_prediction(Prediction),
    % Read the minted forecast's identifier.
    get_dict(id, Prediction, PredictedId),
    % Confirm the predicted_occurrence scheme prefix.
    assertion(sub_string(PredictedId, 0, _, _, "predicted_occurrence:")),
    % And a full error round-trip: the unfulfilled surprise as a real record.
    prediction_loop_record_prediction_error(PredictedId, absent, -1.0, ErrorRecord),
    % Read the minted error's identifier.
    get_dict(id, ErrorRecord, ErrorId),
    % Confirm the prediction_error scheme prefix.
    assertion(sub_string(ErrorId, 0, _, _, "prediction_error:")).

% Wall face two, CLOSED: a forecast no longer needs a marker inside token_occurrence - it has its own kind.
test(wall_closure_a_forecast_now_mints_under_its_own_kind_and_no_longer_shares_the_report_identifier) :-
    % Build the tick-seven occurrence body meant as 'what happened at tick seven' - the report of fact.
    prediction_loop_test_tick_seven_occurrence(Report),
    % Content-address the report.
    causal_core_identify(Report, token_occurrence, ReportId),
    % At 3.0.0 the only way to say 'what I expect at tick seven' was this same body under this same kind,
    % and the identifiers came out IDENTICAL; that indistinguishability was the heart of Wall-2. Since
    % Causalontology 4.0.0 the forecast mints under its own kind instead:
    prediction_loop_test_tick_seven_prediction(Prediction),
    % Read the forecast's identifier.
    get_dict(id, Prediction, PredictedId),
    % The forecast and the report of the same happening now carry DIFFERENT identifiers.
    assertion(PredictedId \== ReportId),
    % The difference is visible in the very scheme: the forecast says what it is.
    assertion(sub_string(PredictedId, 0, _, _, "predicted_occurrence:")),
    % And the report says what it is.
    assertion(sub_string(ReportId, 0, _, _, "token_occurrence:")),
    % PERMANENT DESIGN, kept from the slice-11 test: token_occurrence's identity fields are still exactly
    % these five - a report records what happened, and needs no predicted marker, because the forecast
    % now lives in its own kind rather than in a marker no hash could see.
    causal_core_identity_fields(token_occurrence, IdentityFields),
    % Confirm the unchanged five.
    assertion(IdentityFields == [instantiates, interval, participants, locus, observer]),
    % Still no predicted marker among them - by design, not by wall.
    assertion(\+ memberchk(predicted, IdentityFields)),
    % And a non-identity marker smuggled into a report still cannot change its identifier - by design:
    put_dict(predicted, Report, true, MarkedReport),
    % Content-address the marked report.
    causal_core_identify(MarkedReport, token_occurrence, MarkedReportId),
    % Content addressing still sees only identity-bearing fields.
    assertion(MarkedReportId == ReportId).

% Wall face three, CLOSED: the signed discrepancy now has an identity slot of its own.
test(wall_closure_the_signed_discrepancy_now_has_a_home_in_the_prediction_error_kind) :-
    % At 3.0.0 the sweep over all eighteen kinds found no discrepancy slot anywhere; the twenty-first
    % kind of Causalontology 4.0.0 is that slot's home:
    causal_core_identity_fields(prediction_error, ErrorFields),
    % The discrepancy is identity-bearing in its own kind.
    assertion(memberchk(discrepancy, ErrorFields)),
    % So is the forecast it grades.
    assertion(memberchk(predicted, ErrorFields)),
    % And the optional observation that graded it.
    assertion(memberchk(observed, ErrorFields)),
    % PERMANENT DESIGN, kept from the slice-11 test: token_causal_claim's identity fields are unchanged -
    % the discrepancy was never meant to squat there, and now it does not have to.
    causal_core_identity_fields(token_causal_claim, ClaimFields),
    % Confirm the unchanged claim fields.
    assertion(ClaimFields == [causes, effects, covering_law, actual_delay, counterfactual]),
    % Still no discrepancy slot in the claim - by design, not by wall.
    assertion(\+ memberchk(discrepancy, ClaimFields)),
    % PERMANENT DESIGN, kept from the slice-11 test: token_occurrence still records only what HAPPENED -
    % no occurred flag.
    causal_core_identity_fields(token_occurrence, OccurrenceFields),
    % No occurred flag among them.
    assertion(\+ memberchk(occurred, OccurrenceFields)),
    % No absent flag either.
    assertion(\+ memberchk(absent, OccurrenceFields)),
    % The non-happening a failed forecast names is now told the right way instead: a prediction_error
    % whose observed slot stays absent. Round-trip both shapes and confirm the absence is identity-bearing.
    prediction_loop_test_tick_seven_prediction(Prediction),
    % Read the forecast's identifier.
    get_dict(id, Prediction, PredictedId),
    % The unfulfilled error: no observation at all.
    prediction_loop_record_prediction_error(PredictedId, absent, -1.0, UnfulfilledError),
    % A fulfilled sibling naming a real observation.
    prediction_loop_test_simulation_start(SimulationStart),
    % Mint the observed arrival.
    prediction_loop_record_outcome(SimulationStart, 7, "hidden_object_present", Outcome),
    % Read the observation's identifier.
    get_dict(id, Outcome, ObservedId),
    % The fulfilled error names it.
    prediction_loop_record_prediction_error(PredictedId, ObservedId, 0.0, FulfilledError),
    % Read the unfulfilled identifier.
    get_dict(id, UnfulfilledError, UnfulfilledId),
    % Read the fulfilled identifier.
    get_dict(id, FulfilledError, FulfilledId),
    % Presence versus absence of the observation changes the record's very identity.
    assertion(UnfulfilledId \== FulfilledId).

% Wall face four, CLOSED: the comparator's number no longer dies each tick - it becomes a shareable record.
test(wall_closure_the_comparator_number_now_outlives_the_tick_as_a_content_addressed_record) :-
    % THE LOOP STILL WORKS: the runtime registers the full negative surprise when the object is gone.
    prediction_loop_object_permanence_trial([3, 4, 5, 6], 7, absent, SignedError),
    % The number exists, this tick, inside this runtime - exactly as at slice 11.
    assertion(SignedError =:= -1.0),
    % AND NOW ITS STORY EXPORTS: the same trial, run glass-box, ends the number in a real record.
    prediction_loop_test_simulation_start(SimulationStart),
    % Run the glass-box trial once.
    prediction_loop_object_permanence_trial_records(SimulationStart, [3, 4, 5, 6], 7, absent, TrialA),
    % Run the identical glass-box trial again.
    prediction_loop_object_permanence_trial_records(SimulationStart, [3, 4, 5, 6], 7, absent, TrialB),
    % Read the first run's error record.
    get_dict(error, TrialA, ErrorA),
    % Read the second run's error record.
    get_dict(error, TrialB, ErrorB),
    % Read the first error identifier.
    get_dict(id, ErrorA, ErrorIdA),
    % Read the second error identifier.
    get_dict(id, ErrorB, ErrorIdB),
    % The surprise is minted under the prediction_error scheme.
    assertion(sub_string(ErrorIdA, 0, _, _, "prediction_error:")),
    % The same surprise always mints the same identifier: shareable, reproducible, evidence-gradable.
    assertion(ErrorIdA == ErrorIdB),
    % The record carries the comparator's number itself.
    assertion(get_dict(discrepancy, ErrorA, -1.0)),
    % PERMANENT DESIGN, kept from the slice-11 test: smuggling the number into a token_occurrence as a
    % stray field still cannot change that record's identity - non-identity fields stay invisible to the
    % hash. That was never the wall; the wall was having no kind whose identity the number BELONGS to.
    prediction_loop_record_outcome(SimulationStart, 7, "screen_lifted", Outcome),
    % Read the outcome's identifier.
    get_dict(id, Outcome, OutcomeId),
    % Attach the signed error to the outcome record as a stray field.
    put_dict(prediction_error, Outcome, "-1.0", CarryingOutcome),
    % Content-address the record that tries to carry the error.
    causal_core_identify(CarryingOutcome, token_occurrence, CarryingOutcomeId),
    % The stray field is not identity-bearing, so the identifier is unchanged - by design, not by wall.
    assertion(CarryingOutcomeId == OutcomeId).

% Close the test block for the prediction_loop pack.
:- end_tests(prediction_loop).
