% Load the prediction_loop module under test from the library path.
:- use_module(library(prediction_loop)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).
% Reuse PrologAI's Causalontology core directly, so the wall demonstrations question the standard itself.
:- use_module(library(causal_core), [causal_core_identity_fields/2, causal_core_identify/3]).
% Import membership checking for inspecting identity-field lists.
:- use_module(library(lists), [memberchk/2]).

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

% Open the test block for the prediction_loop pack.
:- begin_tests(prediction_loop).

% ---------------------------------------------------------------------------
% PART ONE - THE RUNTIME: the loop that IS expressible today
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
% PART TWO - THE WALL DEMONSTRATIONS (Wall-2 of the konnectome ledger):
% the EXPORT half of the predictive loop is NOT expressible in Causalontology
% 3.0.0. Each test mechanically demonstrates one face of the wall, and the
% demonstrations are GREEN because the assertions assert that the failures occur.
% ---------------------------------------------------------------------------

% Wall face one: the closed list of eighteen kinds contains no prediction kind at all.
test(wall_demonstration_the_closed_kind_list_has_no_predicted_occurrence_and_no_prediction_error_kind) :-
    % Enumerate every kind the standard's identity table defines.
    findall(Kind, causal_core_identity_fields(Kind, _), Kinds),
    % Count them.
    length(Kinds, KindCount),
    % The list is closed at exactly eighteen kinds.
    assertion(KindCount == 18),
    % predicted_occurrence is not among them.
    assertion(\+ memberchk(predicted_occurrence, Kinds)),
    % prediction_error is not among them either.
    assertion(\+ memberchk(prediction_error, Kinds)),
    % The identity table has no row for predicted_occurrence.
    assertion(\+ causal_core_identity_fields(predicted_occurrence, _)),
    % The identity table has no row for prediction_error.
    assertion(\+ causal_core_identity_fields(prediction_error, _)),
    % Content addressing refuses a dict claiming the predicted_occurrence kind: no identity fields, no identifier.
    assertion(\+ causal_core_identify(_{type: "predicted_occurrence", occurrent: "occurrent:0000", tick: "7"}, predicted_occurrence, _)),
    % Content addressing refuses a dict claiming the prediction_error kind for the same reason.
    assertion(\+ causal_core_identify(_{type: "prediction_error", expected: "1.0", actual: "0.0", magnitude: "-1.0"}, prediction_error, _)).

% Wall face two: a forecast minted as a token_occurrence is indistinguishable from a report of fact.
test(wall_demonstration_a_forecast_and_a_report_with_the_same_content_share_one_identifier) :-
    % Build the tick-seven occurrence body ONCE MEANT AS 'what I expect at tick seven'.
    prediction_loop_test_tick_seven_occurrence(Forecast),
    % Build the identical body AGAIN MEANT AS 'what happened at tick seven'.
    prediction_loop_test_tick_seven_occurrence(Report),
    % Content-address the forecast.
    causal_core_identify(Forecast, token_occurrence, ForecastId),
    % Content-address the report.
    causal_core_identify(Report, token_occurrence, ReportId),
    % The standard cannot tell a forecast from a report: the identifiers are IDENTICAL.
    assertion(ForecastId == ReportId),
    % Read token_occurrence's identity-bearing fields from the standard.
    causal_core_identity_fields(token_occurrence, IdentityFields),
    % They are exactly these five - and none of them can mark 'this is expected, not observed'.
    assertion(IdentityFields == [instantiates, interval, participants, locus, observer]),
    % There is no predicted marker among the identity fields.
    assertion(\+ memberchk(predicted, IdentityFields)),
    % There is no expected marker among the identity fields either.
    assertion(\+ memberchk(expected, IdentityFields)),
    % Now try to mark the forecast anyway: add predicted true to the dict.
    put_dict(predicted, Forecast, true, MarkedForecast),
    % Content-address the marked forecast.
    causal_core_identify(MarkedForecast, token_occurrence, MarkedForecastId),
    % The marker is not identity-bearing, so it is invisible: STILL the same identifier as the report.
    assertion(MarkedForecastId == ReportId).

% Wall face three: the signed discrepancy has no identity slot in any of the eighteen kinds.
test(wall_demonstration_the_signed_discrepancy_has_no_home_in_any_of_the_eighteen_kinds) :-
    % Read the token_causal_claim's identity-bearing fields, the nearest candidate home.
    causal_core_identity_fields(token_causal_claim, ClaimFields),
    % They are exactly these five: causes, effects, covering law, actual delay, counterfactual.
    assertion(ClaimFields == [causes, effects, covering_law, actual_delay, counterfactual]),
    % No discrepancy slot.
    assertion(\+ memberchk(discrepancy, ClaimFields)),
    % No prediction_error slot.
    assertion(\+ memberchk(prediction_error, ClaimFields)),
    % No expected slot to hold the forecast side of the pair.
    assertion(\+ memberchk(expected, ClaimFields)),
    % Its causes and effects must name token-tier things that HAPPENED; a failed prediction names a
    % non-happening, and token_occurrence's identity fields offer no way to record one:
    causal_core_identity_fields(token_occurrence, OccurrenceFields),
    % No occurred flag.
    assertion(\+ memberchk(occurred, OccurrenceFields)),
    % No absent flag.
    assertion(\+ memberchk(absent, OccurrenceFields)),
    % No negated flag.
    assertion(\+ memberchk(negated, OccurrenceFields)),
    % Sweep the WHOLE closed kind list: no kind anywhere carries a discrepancy identity slot.
    assertion(forall(causal_core_identity_fields(_, Fields), \+ memberchk(discrepancy, Fields))),
    % And no kind anywhere carries a prediction_error identity slot.
    assertion(forall(causal_core_identity_fields(_, Fields), \+ memberchk(prediction_error, Fields))).

% Wall face four: the comparator's number is computed each tick, and dies each tick - no kind can carry it.
test(wall_demonstration_the_comparator_number_is_computed_each_tick_but_no_kind_can_carry_it) :-
    % THE LOOP WORKS: the runtime registers the full negative surprise when the object is gone.
    prediction_loop_object_permanence_trial([3, 4, 5, 6], 7, absent, SignedError),
    % The number exists, this tick, inside this runtime.
    assertion(SignedError =:= -1.0),
    % What HAPPENED at the reveal - the lifted screen - is mintable for real.
    prediction_loop_test_simulation_start(SimulationStart),
    % Mint the actual outcome as a token_occurrence.
    prediction_loop_record_outcome(SimulationStart, 7, "screen_lifted", Outcome),
    % Read its content-addressed identifier.
    get_dict(id, Outcome, OutcomeId),
    % Confirm the token_occurrence scheme prefix: the observation exports fine.
    assertion(sub_string(OutcomeId, 0, _, _, "token_occurrence:")),
    % ITS STORY CANNOT: attach the signed error to the outcome record as a field.
    put_dict(prediction_error, Outcome, "-1.0", CarryingOutcome),
    % Content-address the record that tries to carry the error.
    causal_core_identify(CarryingOutcome, token_occurrence, CarryingOutcomeId),
    % The error field is not identity-bearing, so content addressing cannot see it: the identifier is unchanged.
    assertion(CarryingOutcomeId == OutcomeId),
    % And the sweep from wall face three already showed no kind offers the number an identity slot,
    % so the comparator's number cannot become an evidence-gradable record in ANY of the eighteen kinds.
    assertion(forall(causal_core_identity_fields(_, Fields), \+ memberchk(prediction_error, Fields))).

% Close the test block for the prediction_loop pack.
:- end_tests(prediction_loop).
