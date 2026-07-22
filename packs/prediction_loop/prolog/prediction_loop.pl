% Declare this file as the 'prediction_loop' module and list the predicates it exports.
:- module(prediction_loop, [
    % prediction_loop_store_empty/1: the empty expectation store, before anything is expected.
    prediction_loop_store_empty/1,
    % prediction_loop_expect/4: hold 'occurrent O is expected at tick T' (full presence) across ticks.
    prediction_loop_expect/4,
    % prediction_loop_expect_magnitude/5: hold a graded expectation with an explicit expected magnitude.
    prediction_loop_expect_magnitude/5,
    % prediction_loop_expected/4: read an expectation back out of the store, however many ticks later.
    prediction_loop_expected/4,
    % prediction_loop_compare/5: the comparator step on arrival - the signed error, actual minus expected.
    prediction_loop_compare/5,
    % prediction_loop_compare_absent/4: the comparator step on non-arrival - the actual magnitude is zero.
    prediction_loop_compare_absent/4,
    % prediction_loop_object_permanence_trial/4: the Rung One trial - hide, hold, reveal, and score the surprise.
    prediction_loop_object_permanence_trial/4,
    % prediction_loop_outcome_type/2: mint (deterministically) a reusable outcome occurrent identifier.
    prediction_loop_outcome_type/2,
    % prediction_loop_tick_instant/3: the deterministic absolute instant of a numbered tick.
    prediction_loop_tick_instant/3,
    % prediction_loop_record_outcome/4: record what ACTUALLY happened as a Causalontology token_occurrence.
    prediction_loop_record_outcome/4,
    % prediction_loop_predictor/1: the predicting construct's own content-addressed continuant identifier.
    prediction_loop_predictor/1,
    % prediction_loop_record_prediction/4: mint a forecast BEFORE the outcome, as a predicted_occurrence at an ordinal start_tick.
    prediction_loop_record_prediction/4,
    % prediction_loop_record_prediction_strength/5: mint a graded forecast carrying the optional, identity-bearing strength.
    prediction_loop_record_prediction_strength/5,
    % prediction_loop_record_prediction_interval/4: mint a forecast over an explicit interval, gated by Rule 24.
    prediction_loop_record_prediction_interval/4,
    % prediction_loop_record_prediction_error/4: mint the prediction_error pairing forecast and observation (or its absence).
    prediction_loop_record_prediction_error/4,
    % prediction_loop_object_permanence_trial_records/5: the Rung One trial run fully glass-box, every step a real record.
    prediction_loop_object_permanence_trial_records/5
]).

% Import membership, list concatenation, and last-element access for the store and the glass-box trial.
:- use_module(library(lists), [member/2, append/3, last/2]).
% Import foldl for accumulating one expectation per hidden tick, and maplist for minting one forecast per held tick.
:- use_module(library(apply), [foldl/4, maplist/3]).
% Import the comparator archetype rule; konnectome reuses its own dynamical heart, it does not re-derive it.
:- use_module(library(archetype), [archetype_comparator/3]).
% Reuse PrologAI's Causalontology core to content-address records and check local semantics; konnectome does not fork it.
:- use_module(library(causal_core), [causal_core_identify/3, causal_core_validate_semantics/3]).

% Prediction, at Rung One of the developmental ladder (Appendix 6), is object permanence: an object
% hidden behind a screen is still expected to be there, tick after tick, and the System is surprised -
% registers a prediction error - if the screen lifts and the object is gone. The RUNTIME half lives
% here: a small functional expectation store holds 'occurrent O expected at tick T' across ticks, and
% the comparator archetype rule (Appendix 2, Section A2.3) scores arrival against expectation as the
% signed difference, actual minus expected. What HAPPENED is minted for real as a Causalontology
% token_occurrence, mirroring the observer pack's minting pattern. The EXPORT half - recording the
% EXPECTATION itself as a first-class record distinct from the observation, and the signed graded
% discrepancy between them - was NOT expressible in Causalontology 3.0.0, whose closed list of
% eighteen kinds had no predicted_occurrence and no prediction_error kind; the slice-11 test suite
% demonstrated that wall mechanically, and it was recorded as Wall-2 of the konnectome ledger
% (hit 2026-07-22 at Causalontology 3.0.0). The wall was routed through the gated Causalontology
% change order and CLOSED by Causalontology 4.0.0 - the kind list grew to twenty-one, gaining
% predicted_occurrence and prediction_error - together with causal_core 1.1.0, which
% content-addresses the new kinds and checks Rule 24 locally. This slice-12 delivery is the export
% half Wall-2 demanded: a forecast is minted BEFORE the outcome as a predicted_occurrence carrying
% the ordinal start_tick dimension (Rule 24 gated), what actually happened is minted as a
% token_occurrence exactly as before, and the comparator's signed number is minted as the
% prediction_error pairing them - the loop's whole story is now shareable, content-addressed record
% by record, and a forecast is distinguishable from a report by its very kind.

% ---------------------------------------------------------------------------
% THE EXPECTATION STORE - holding 'occurrent O expected at tick T' across ticks
% ---------------------------------------------------------------------------

% prediction_loop_store_empty(-Store): the empty expectation store, before anything is expected.
prediction_loop_store_empty(Store) :-
    % With nothing yet expected, the store is the empty list.
    Store = [].

% prediction_loop_expect(+StoreIn, +OccurrentId, +TickNumber, -StoreOut): expect full presence at tick T.
prediction_loop_expect(StoreIn, OccurrentId, TickNumber, StoreOut) :-
    % Full presence is the expected magnitude one.
    prediction_loop_expect_magnitude(StoreIn, OccurrentId, TickNumber, 1.0, StoreOut).

% prediction_loop_expect_magnitude(+StoreIn, +OccurrentId, +TickNumber, +ExpectedMagnitude, -StoreOut): graded.
prediction_loop_expect_magnitude(StoreIn, OccurrentId, TickNumber, ExpectedMagnitude, StoreOut) :-
    % Assemble the expectation: which occurrent, at which tick, at what expected magnitude.
    Expectation = _{occurrent: OccurrentId, tick: TickNumber, magnitude: ExpectedMagnitude},
    % Hold it at the front of the store; the store persists across ticks in the caller's hands.
    StoreOut = [Expectation | StoreIn].

% prediction_loop_expected(+Store, ?OccurrentId, ?TickNumber, ?ExpectedMagnitude): read an expectation back.
prediction_loop_expected(Store, OccurrentId, TickNumber, ExpectedMagnitude) :-
    % Find an expectation held in the store.
    member(Expectation, Store),
    % Match the expected occurrent.
    get_dict(occurrent, Expectation, OccurrentId),
    % Match the tick it is expected at.
    get_dict(tick, Expectation, TickNumber),
    % Read the expected magnitude.
    get_dict(magnitude, Expectation, ExpectedMagnitude).

% ---------------------------------------------------------------------------
% THE COMPARATOR STEP - arrival (or non-arrival) against the held expectation
% ---------------------------------------------------------------------------

% prediction_loop_compare(+Store, +OccurrentId, +TickNumber, +ActualMagnitude, -SignedError): score arrival.
prediction_loop_compare(Store, OccurrentId, TickNumber, ActualMagnitude, SignedError) :-
    % Look up the most recently held expectation for this occurrent at this tick, committing to it
    % deterministically; with no expectation held there is no comparison at all.
    once(prediction_loop_expected(Store, OccurrentId, TickNumber, ExpectedMagnitude)),
    % Apply the comparator archetype rule: the signed error is the actual minus the expected.
    archetype_comparator(ExpectedMagnitude, ActualMagnitude, SignedError).

% prediction_loop_compare_absent(+Store, +OccurrentId, +TickNumber, -SignedError): score non-arrival.
prediction_loop_compare_absent(Store, OccurrentId, TickNumber, SignedError) :-
    % Nothing arrived, so the actual magnitude is zero and the error is minus the expectation.
    prediction_loop_compare(Store, OccurrentId, TickNumber, 0.0, SignedError).

% ---------------------------------------------------------------------------
% THE OBJECT-PERMANENCE TRIAL (Rung One, Appendix 6) - hide, hold, reveal, score
% ---------------------------------------------------------------------------

% prediction_loop_reveal_magnitude_(?RevealOutcome, ?ActualMagnitude): the two ways a reveal can go.
% A present object arrives at full magnitude.
prediction_loop_reveal_magnitude_(present, 1.0).
% An absent object arrives at zero magnitude.
prediction_loop_reveal_magnitude_(absent, 0.0).

% prediction_loop_hold_hidden_(+OccurrentId, +TickNumber, +StoreIn, -StoreOut): one hidden tick's holding step.
prediction_loop_hold_hidden_(OccurrentId, TickNumber, StoreIn, StoreOut) :-
    % While the object is hidden, keep expecting its full presence at this tick.
    prediction_loop_expect(StoreIn, OccurrentId, TickNumber, StoreOut).

% prediction_loop_object_permanence_trial(+HiddenTickNumbers, +RevealTickNumber, +RevealOutcome, -SignedError):
% the central Rung One pilot test - the object goes behind the screen, the expectation is held each
% tick while hidden, and the reveal is scored: zero error when present, a signed surprise when absent.
prediction_loop_object_permanence_trial(HiddenTickNumbers, RevealTickNumber, RevealOutcome, SignedError) :-
    % Name the hidden object's presence as a reusable, content-addressed occurrent.
    prediction_loop_outcome_type("hidden_object_present", OccurrentId),
    % Start from the empty expectation store.
    prediction_loop_store_empty(EmptyStore),
    % Hold the expectation across every tick the object stays hidden.
    foldl(prediction_loop_hold_hidden_(OccurrentId), HiddenTickNumbers, EmptyStore, HeldStore),
    % Still expect the object at the tick the screen lifts.
    prediction_loop_expect(HeldStore, OccurrentId, RevealTickNumber, RevealStore),
    % Read what the reveal actually delivers: full presence or nothing.
    prediction_loop_reveal_magnitude_(RevealOutcome, ActualMagnitude),
    % Score the reveal against the held expectation: the signed error is the surprise.
    prediction_loop_compare(RevealStore, OccurrentId, RevealTickNumber, ActualMagnitude, SignedError).

% ---------------------------------------------------------------------------
% MINTING WHAT HAPPENED - the actual outcome as a Causalontology token_occurrence
% (mirrors the observer pack's minting pattern; only what HAPPENED is mintable)
% ---------------------------------------------------------------------------

% prediction_loop_outcome_type(+Label, -OccurrentTypeId): mint a reusable outcome occurrent identifier.
prediction_loop_outcome_type(Label, OccurrentTypeId) :-
    % Build the outcome occurrent as a Causalontology record: an event kind of happening.
    OutcomeType = _{type: "occurrent", label: Label, category: "event"},
    % Content-address it; the identifier is the same on every run because the content is fixed.
    causal_core_identify(OutcomeType, occurrent, OccurrentTypeId).

% prediction_loop_tick_instant(+SimulationStart, +TickNumber, -InstantString): tick N's absolute instant.
prediction_loop_tick_instant(SimulationStart, TickNumber, InstantString) :-
    % Parse the simulation start, an RFC 3339 timestamp, into a POSIX second count.
    parse_time(SimulationStart, iso_8601, BaseStamp),
    % Advance the clock by one nominal second per ordinal tick, keeping whole seconds.
    Stamp is truncate(BaseStamp) + TickNumber,
    % Express that instant back in Coordinated Universal Time.
    stamp_date_time(Stamp, DateTime, 'UTC'),
    % Format it as an RFC 3339 timestamp with the mandatory trailing Z.
    format_time(string(InstantString), "%Y-%m-%dT%H:%M:%SZ", DateTime).

% prediction_loop_record_outcome(+SimulationStart, +TickNumber, +Label, -Record): mint what actually happened.
prediction_loop_record_outcome(SimulationStart, TickNumber, Label, Record) :-
    % Get the outcome occurrent type identifier for this labelled happening.
    prediction_loop_outcome_type(Label, OccurrentTypeId),
    % Compute the tick's absolute instant from the fixed simulation start.
    prediction_loop_tick_instant(SimulationStart, TickNumber, InstantString),
    % Build the token_occurrence: it instantiates the outcome type and starts at its instant.
    Base = _{type: "token_occurrence", instantiates: OccurrentTypeId, interval: _{start: InstantString}},
    % Content-address it over its identity-bearing fields (instantiates and interval).
    causal_core_identify(Base, token_occurrence, Id),
    % Attach the identifier, yielding the complete stored record.
    put_dict(id, Base, Id, Record).

% ---------------------------------------------------------------------------
% MINTING WHAT IS EXPECTED - the forecast as a Causalontology predicted_occurrence
% (the export half Wall-2 demanded; expressible since Causalontology 4.0.0 and
% causal_core 1.1.0; a forecast now differs from a report by its very kind)
% ---------------------------------------------------------------------------

% prediction_loop_predictor(-PredictorId): the predicting construct's own continuant identifier.
prediction_loop_predictor(PredictorId) :-
    % Build the modeled construct doing the predicting - the expectation store itself - as a continuant.
    Predictor = _{type: "continuant", label: "prediction_loop_expectation_store", category: "system"},
    % Content-address it; the same construct always mints the same identifier.
    causal_core_identify(Predictor, continuant, PredictorId).

% prediction_loop_checked_prediction_(+Base, -Record): the Rule 24 gate, then the minting step.
prediction_loop_checked_prediction_(Base, Record) :-
    % Ask causal_core's local semantic rules (Rule 24) to judge the predicted interval's temporal dimensions.
    causal_core_validate_semantics(Base, predicted_occurrence, Reasons),
    % An empty reason list is a clean bill of health.
    (   Reasons == []
    % With clean semantics, minting proceeds.
    ->  true
    % Any reason is a hard refusal, raised carrying the core's own wording (for example dimension_conflict).
    ;   throw(error(prediction_loop_refused_prediction(Reasons), context(prediction_loop_checked_prediction_/2, "causal_core refused the predicted_occurrence")))
    ),
    % Content-address the forecast over its identity-bearing fields (instantiates, interval, predictor, strength).
    causal_core_identify(Base, predicted_occurrence, Id),
    % Attach the identifier, yielding the complete stored record.
    put_dict(id, Base, Id, Record).

% prediction_loop_record_prediction_interval(+OccurrentTypeId, +Interval, +PredictorId, -Record): explicit interval.
prediction_loop_record_prediction_interval(OccurrentTypeId, Interval, PredictorId, Record) :-
    % Build the predicted_occurrence: what is expected, over which interval, foreseen by whom.
    Base = _{type: "predicted_occurrence", instantiates: OccurrentTypeId, interval: Interval, predictor: PredictorId},
    % Gate it through Rule 24 and mint it.
    prediction_loop_checked_prediction_(Base, Record).

% prediction_loop_record_prediction(+OccurrentTypeId, +TickNumber, +PredictorId, -Record): a tick-dimensioned forecast.
prediction_loop_record_prediction(OccurrentTypeId, TickNumber, PredictorId, Record) :-
    % The predicted interval carries only the ordinal dimension: the integer tick the arrival is expected at.
    Interval = _{start_tick: TickNumber},
    % Gate and mint through the explicit-interval path.
    prediction_loop_record_prediction_interval(OccurrentTypeId, Interval, PredictorId, Record).

% prediction_loop_record_prediction_strength(+OccurrentTypeId, +TickNumber, +PredictorId, +Strength, -Record): graded.
prediction_loop_record_prediction_strength(OccurrentTypeId, TickNumber, PredictorId, Strength, Record) :-
    % Build the graded predicted_occurrence; the optional strength is identity-bearing when present.
    Base = _{type: "predicted_occurrence", instantiates: OccurrentTypeId, interval: _{start_tick: TickNumber}, predictor: PredictorId, strength: Strength},
    % Gate it through Rule 24 and mint it.
    prediction_loop_checked_prediction_(Base, Record).

% ---------------------------------------------------------------------------
% MINTING THE SURPRISE - the comparator's signed number as a prediction_error
% ---------------------------------------------------------------------------

% prediction_loop_error_base_(+ObservedOutcome, +PredictedId, +Discrepancy, -Base): the error's body,
% dispatched on whether an observation arrived; the cut commits to the unfulfilled shape for absent.
prediction_loop_error_base_(absent, PredictedId, Discrepancy, Base) :-
    % Commit: the atom absent means the unfulfilled case, never an identifier.
    !,
    % Nothing was observed, so the observed slot stays absent: only the forecast and the signed number.
    Base = _{type: "prediction_error", predicted: PredictedId, discrepancy: Discrepancy}.
prediction_loop_error_base_(ObservedId, PredictedId, Discrepancy, Base) :-
    % A real observation arrived: pair the forecast with the observed token_occurrence and the signed number.
    Base = _{type: "prediction_error", predicted: PredictedId, observed: ObservedId, discrepancy: Discrepancy}.

% prediction_loop_record_prediction_error(+PredictedId, +ObservedOutcome, +Discrepancy, -Record): pair the
% forecast with what arrived; ObservedOutcome is the observed token_occurrence's identifier, or the
% atom absent when nothing arrived (the unfulfilled case - the reveal of a gone object).
prediction_loop_record_prediction_error(PredictedId, ObservedOutcome, Discrepancy, Record) :-
    % Build the error's body, with or without an observed slot.
    prediction_loop_error_base_(ObservedOutcome, PredictedId, Discrepancy, Base),
    % Content-address the error over its identity-bearing fields (predicted, observed, discrepancy).
    causal_core_identify(Base, prediction_error, Id),
    % Attach the identifier, yielding the complete stored record.
    put_dict(id, Base, Id, Record).

% ---------------------------------------------------------------------------
% THE GLASS-BOX TRIAL - object permanence with every step a real record
% ---------------------------------------------------------------------------

% prediction_loop_predict_at_(+OccurrentTypeId, +PredictorId, +TickNumber, -Record): one held tick's forecast.
prediction_loop_predict_at_(OccurrentTypeId, PredictorId, TickNumber, Record) :-
    % Each tick the expectation is held, that expectation is minted as its own forecast record.
    prediction_loop_record_prediction(OccurrentTypeId, TickNumber, PredictorId, Record).

% prediction_loop_reveal_records_(+RevealOutcome, +SimulationStart, +RevealTickNumber, +PredictedId,
% +SignedError, -Outcome, -ErrorRecord): the reveal's records, one clause per way the reveal can go.
prediction_loop_reveal_records_(present, SimulationStart, RevealTickNumber, PredictedId, SignedError, Outcome, ErrorRecord) :-
    % The screen lifted on the object: mint what actually happened as a token_occurrence, exactly as before.
    prediction_loop_record_outcome(SimulationStart, RevealTickNumber, "hidden_object_present", Outcome),
    % Read the observed outcome's identifier.
    get_dict(id, Outcome, ObservedId),
    % Pair forecast and observation with the comparator's signed number (zero when reality matched).
    prediction_loop_record_prediction_error(PredictedId, ObservedId, SignedError, ErrorRecord).
prediction_loop_reveal_records_(absent, _SimulationStart, _RevealTickNumber, PredictedId, SignedError, absent, ErrorRecord) :-
    % Nothing happened, so nothing is minted as having happened: the error's observed slot stays absent.
    prediction_loop_record_prediction_error(PredictedId, absent, SignedError, ErrorRecord).

% prediction_loop_object_permanence_trial_records(+SimulationStart, +HiddenTickNumbers, +RevealTickNumber,
% +RevealOutcome, -Trial): the Rung One trial run fully glass-box - every held expectation, the reveal,
% and the surprise all end as real, content-addressed Causalontology records the mind can share.
prediction_loop_object_permanence_trial_records(SimulationStart, HiddenTickNumbers, RevealTickNumber, RevealOutcome, Trial) :-
    % Run the runtime trial exactly as before: hold the expectation each tick and score the reveal.
    prediction_loop_object_permanence_trial(HiddenTickNumbers, RevealTickNumber, RevealOutcome, SignedError),
    % Name the hidden object's presence as the same content-addressed occurrent the runtime used.
    prediction_loop_outcome_type("hidden_object_present", OccurrentTypeId),
    % Name the predicting construct.
    prediction_loop_predictor(PredictorId),
    % The expectation is held at every hidden tick, and still at the tick the screen lifts.
    append(HiddenTickNumbers, [RevealTickNumber], PredictedTickNumbers),
    % Mint one predicted_occurrence per held tick - all of them BEFORE any outcome exists.
    maplist(prediction_loop_predict_at_(OccurrentTypeId, PredictorId), PredictedTickNumbers, PredictionRecords),
    % The reveal-tick forecast is the one the error will grade.
    last(PredictionRecords, RevealPrediction),
    % Read the graded forecast's identifier.
    get_dict(id, RevealPrediction, PredictedId),
    % Observe the reveal (or its absence) and mint the prediction_error pairing.
    prediction_loop_reveal_records_(RevealOutcome, SimulationStart, RevealTickNumber, PredictedId, SignedError, Outcome, ErrorRecord),
    % Assemble the whole glass-box story: the forecasts, the outcome (or absent), the error, and the raw number.
    Trial = _{predictions: PredictionRecords, outcome: Outcome, error: ErrorRecord, signed_error: SignedError}.
