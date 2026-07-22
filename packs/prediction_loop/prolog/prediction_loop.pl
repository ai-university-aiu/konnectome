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
    prediction_loop_record_outcome/4
]).

% Import membership for reading expectations back out of the store.
:- use_module(library(lists), [member/2]).
% Import foldl for accumulating one expectation per hidden tick.
:- use_module(library(apply), [foldl/4]).
% Import the comparator archetype rule; konnectome reuses its own dynamical heart, it does not re-derive it.
:- use_module(library(archetype), [archetype_comparator/3]).
% Reuse PrologAI's Causalontology core to content-address a record; konnectome does not fork it.
:- use_module(library(causal_core), [causal_core_identify/3]).

% Prediction, at Rung One of the developmental ladder (Appendix 6), is object permanence: an object
% hidden behind a screen is still expected to be there, tick after tick, and the System is surprised -
% registers a prediction error - if the screen lifts and the object is gone. The RUNTIME half lives
% here: a small functional expectation store holds 'occurrent O expected at tick T' across ticks, and
% the comparator archetype rule (Appendix 2, Section A2.3) scores arrival against expectation as the
% signed difference, actual minus expected. What HAPPENED is minted for real as a Causalontology
% token_occurrence, mirroring the observer pack's minting pattern. The EXPORT half - recording the
% EXPECTATION itself as a first-class record distinct from the observation, and the signed graded
% discrepancy between them, as shareable, evidence-graded, content-addressed records - is NOT
% expressible in Causalontology 3.0.0: the closed list of eighteen kinds has no predicted_occurrence
% and no prediction_error kind, a forecast minted as a token_occurrence is indistinguishable from a
% report of fact, and no kind's identity fields offer the discrepancy a slot. The pack's test suite
% demonstrates that wall mechanically; the loop works, but its story cannot be shared.

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
