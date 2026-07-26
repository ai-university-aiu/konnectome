% Load the self_provenance module under test from the library path.
:- use_module(library(self_provenance)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).
% Reuse other_minds to mint a REAL attitude record for the provenance layer to assert about.
:- use_module(library(other_minds), [
    % other_minds_reset/0: clear the theory-of-mind runtime before each social fixture.
    other_minds_reset/0,
    % other_minds_world_fact_add/1: record konnectome's own world fact (where the object really is).
    other_minds_world_fact_add/1,
    % other_minds_belief_attribute/2: attribute the false belief to the modelled agent.
    other_minds_belief_attribute/2,
    % other_minds_search_prediction_export/5: end the false-belief trial by exporting the attitude record.
    other_minds_search_prediction_export/5
]).
% Reuse prediction_loop to mint REAL predicted_occurrence and prediction_error records to assert about.
:- use_module(library(prediction_loop), [
    % prediction_loop_outcome_type/2: the reusable outcome occurrent identifier the forecast is about.
    prediction_loop_outcome_type/2,
    % prediction_loop_predictor/1: the predicting construct's own continuant identifier.
    prediction_loop_predictor/1,
    % prediction_loop_record_prediction/4: mint a forecast as a predicted_occurrence.
    prediction_loop_record_prediction/4,
    % prediction_loop_object_permanence_trial_records/5: the full glass-box trial, yielding a prediction_error.
    prediction_loop_object_permanence_trial_records/5
]).

% A fixed simulation start, so every minted instant and identifier is deterministic.
self_provenance_test_simulation_start("2026-01-01T00:00:00Z").

% self_provenance_test_hex64(-Hex): a well-formed 64-character lowercase-hex body for building test identifiers.
self_provenance_test_hex64(Hex) :-
    % Sixty-four character codes.
    length(Codes, 64),
    % Every one the lowercase letter a, which is a valid hexadecimal digit.
    maplist(=(0'a), Codes),
    % Assembled into a string.
    string_codes(Hex, Codes).

% self_provenance_test_instant(-Instant): tick zero's absolute instant, a fixed timestamp for the fixtures.
self_provenance_test_instant(Instant) :-
    % Use the fixed simulation start.
    self_provenance_test_simulation_start(Start),
    % Tick zero's instant is the simulation start itself.
    self_provenance_instant(Start, 0, Instant).

% self_provenance_test_attitude(-AttitudeRecord, -Place): mint Sally's false belief as a real attitude record.
self_provenance_test_attitude(AttitudeRecord, Place) :-
    % Start the social fixture from a clean runtime.
    other_minds_reset,
    % Konnectome's own world record: the marble is really in the box.
    other_minds_world_fact_add(object_location(marble, box)),
    % Sally is attributed the false belief that the marble is in the basket.
    other_minds_belief_attribute(sally, object_location(marble, basket)),
    % A fixed instant for the minted content.
    self_provenance_test_instant(Instant),
    % Export the false-belief trial's predicted search as a real, content-addressed attitude record.
    other_minds_search_prediction_export(sally, marble, Instant, Place, AttitudeRecord).

% self_provenance_test_forecast(-ForecastRecord): mint a tick-six forecast as a real predicted_occurrence record.
self_provenance_test_forecast(ForecastRecord) :-
    % Name the hidden object's presence as the forecast's occurrent type.
    prediction_loop_outcome_type("hidden_object_present", OccurrentTypeId),
    % Name the predicting construct.
    prediction_loop_predictor(PredictorId),
    % Mint the forecast of the object's presence at tick six, before any outcome exists.
    prediction_loop_record_prediction(OccurrentTypeId, 6, PredictorId, ForecastRecord).

% Open the test block for the self_provenance pack.
:- begin_tests(self_provenance).

% ---------------------------------------------------------------------------
% PART ONE - THE GRADES, THE SOURCE IDENTITY, AND THE TIMESTAMPS
% ---------------------------------------------------------------------------

% The six evidence grades carry the standard's strict strongest-to-weakest ranking.
test(the_six_grades_rank_strongest_to_weakest) :-
    % Intervention is the strongest ground.
    self_provenance_grade_rank(intervention, 6),
    % Observation ranks just below intervention.
    self_provenance_grade_rank(observation, 5),
    % A synthetic mind's model-based evidence (simulation) ranks below observation.
    self_provenance_grade_rank(simulation, 4),
    % Derivation ranks below a model run.
    self_provenance_grade_rank(derivation, 3),
    % A human hint ranks below a derivation.
    self_provenance_grade_rank(human_hint, 2),
    % An import is the weakest ground.
    self_provenance_grade_rank(imported, 1).

% One grade is stronger than another exactly when it outranks it, and an unknown grade has no rank.
test(grade_stronger_reflects_the_order_and_unknown_grades_are_rejected) :-
    % Observation outranks simulation.
    assertion(self_provenance_grade_stronger(observation, simulation)),
    % Simulation does not outrank observation.
    assertion(\+ self_provenance_grade_stronger(simulation, observation)),
    % A grade written as a string is accepted just like an atom.
    assertion(self_provenance_grade_stronger("intervention", "imported")),
    % A word that is not one of the six carries no rank at all.
    assertion(\+ self_provenance_grade_rank(guess, _)).

% Konnectome's source identity is a well-formed Ed25519-shaped key and is the same on every call.
test(the_source_identity_is_wellformed_and_deterministic) :-
    % Read the source identity twice.
    self_provenance_source(SourceOne),
    % Read it again.
    self_provenance_source(SourceTwo),
    % The identity never varies - it carries no secret and no randomness.
    assertion(SourceOne == SourceTwo),
    % Split the identity into its scheme and its hexadecimal body.
    split_string(SourceOne, ":", "", [Scheme, Hex]),
    % The scheme is the Ed25519 public-key scheme.
    assertion(Scheme == "ed25519"),
    % The body is a 64-character digest, the shape of an Ed25519 public key.
    string_length(Hex, 64).

% A tick's timestamp is a deterministic RFC 3339 instant advancing one second per tick.
test(instants_are_deterministic_rfc3339) :-
    % The fixed simulation start.
    self_provenance_test_simulation_start(Start),
    % Tick zero's instant is the simulation start itself.
    self_provenance_instant(Start, 0, InstantZero),
    % Which is the fixed start timestamp.
    assertion(InstantZero == "2026-01-01T00:00:00Z"),
    % Tick five advances five nominal seconds.
    self_provenance_instant(Start, 5, InstantFive),
    % Yielding the fifth-second instant.
    assertion(InstantFive == "2026-01-01T00:00:05Z").

% ---------------------------------------------------------------------------
% PART TWO - ASSERTING ABOUT THE MIND'S OWN MINTED RECORDS
% (this is the slice-12 non-closure being closed: a konnectome assertion now grades its own records)
% ---------------------------------------------------------------------------

% An assertion ABOUT an attitude validates and is content-addressed; the modelled HOLDER differs from the signing SOURCE (Rule 25).
test(an_assertion_about_an_attitude_distinguishes_holder_from_source) :-
    % Mint Sally's false belief as a real attitude record.
    self_provenance_test_attitude(AttitudeRecord, _Place),
    % Read the attitude's content-addressed identifier.
    get_dict(id, AttitudeRecord, AttitudeId),
    % A fixed instant for the assertion.
    self_provenance_test_instant(Instant),
    % The mind asserts, on observation, that Sally holds this belief.
    self_provenance_assertion(AttitudeId, "observation", 0.9, Instant, Assertion),
    % The assertion is a content-addressed assertion record.
    get_dict(id, Assertion, AssertionId),
    % Whose scheme is the assertion scheme.
    assertion(sub_string(AssertionId, 0, _, _, "assertion:")),
    % The assertion is about exactly the attitude just minted.
    assertion(get_dict(about, Assertion, AttitudeId)),
    % Read the attitude's holder (a modelled agent) and the assertion's source (a signing key).
    get_dict(holder, AttitudeRecord, HolderId),
    % The holder is a modelled token individual, not a cryptographic key.
    assertion(sub_string(HolderId, 0, _, _, "token_individual:")),
    % The source is konnectome's Ed25519 identity.
    get_dict(source, Assertion, Source),
    % Whose scheme is the Ed25519 scheme.
    assertion(sub_string(Source, 0, _, _, "ed25519:")),
    % And the holder and the source are demonstrably different things (Rule 25).
    assertion(HolderId \== Source).

% Minting the same assertion twice yields the identical identifier - the provenance record is reproducible.
test(an_assertion_is_deterministic) :-
    % Mint Sally's false belief.
    self_provenance_test_attitude(AttitudeRecord, _Place),
    % Read its identifier.
    get_dict(id, AttitudeRecord, AttitudeId),
    % A fixed instant.
    self_provenance_test_instant(Instant),
    % Assert about it once.
    self_provenance_assertion(AttitudeId, "observation", 0.9, Instant, AssertionOne),
    % Assert about it again with the same inputs.
    self_provenance_assertion(AttitudeId, "observation", 0.9, Instant, AssertionTwo),
    % Read both identifiers.
    get_dict(id, AssertionOne, IdOne),
    % Read the second identifier.
    get_dict(id, AssertionTwo, IdTwo),
    % Content addressing makes the two identical.
    assertion(IdOne == IdTwo).

% An assertion ABOUT a forecast is graded 'simulation' - a model-based forecast is model-based evidence.
test(an_assertion_about_a_forecast_is_graded_simulation) :-
    % Mint a tick-six forecast as a predicted_occurrence.
    self_provenance_test_forecast(ForecastRecord),
    % Read the forecast's identifier.
    get_dict(id, ForecastRecord, ForecastId),
    % Whose scheme is the predicted_occurrence scheme.
    assertion(sub_string(ForecastId, 0, _, _, "predicted_occurrence:")),
    % A fixed instant.
    self_provenance_test_instant(Instant),
    % The mind asserts its forecast, grading the evidence as simulation, with moderate confidence.
    self_provenance_assertion(ForecastId, "simulation", 0.6, Instant, Assertion),
    % The assertion is about the forecast.
    assertion(get_dict(about, Assertion, ForecastId)),
    % And carries the simulation grade.
    assertion(get_dict(evidence_type, Assertion, "simulation")).

% An assertion ABOUT a prediction_error can CITE the particular observed token that grounds it.
test(an_assertion_about_a_prediction_error_cites_the_observed_token) :-
    % Run the object-permanence trial where the object is present at the reveal.
    self_provenance_test_simulation_start(Start),
    % The trial mints the forecasts, the actual outcome, and the prediction_error pairing them.
    prediction_loop_object_permanence_trial_records(Start, [3, 4, 5], 6, present, Trial),
    % Read the prediction_error record.
    get_dict(error, Trial, ErrorRecord),
    % Read its identifier.
    get_dict(id, ErrorRecord, ErrorId),
    % Whose scheme is the prediction_error scheme.
    assertion(sub_string(ErrorId, 0, _, _, "prediction_error:")),
    % Read the actual observed outcome record.
    get_dict(outcome, Trial, Outcome),
    % Read the observed token_occurrence's identifier.
    get_dict(id, Outcome, ObservedId),
    % A fixed instant.
    self_provenance_test_instant(Instant),
    % The mind asserts, on observation, that the forecast matched reality, citing the observed token as its evidence.
    self_provenance_assertion_evidenced(ErrorId, "observation", 0.95, [ObservedId], Instant, Assertion),
    % The assertion is about the prediction_error.
    assertion(get_dict(about, Assertion, ErrorId)),
    % And cites exactly the observed token as its evidence.
    assertion(get_dict(evidenced_by, Assertion, [ObservedId])).

% ---------------------------------------------------------------------------
% PART THREE - THE GUARDS: a malformed assertion is refused before it is minted
% ---------------------------------------------------------------------------

% An evidence grade outside the standard's six is refused.
test(an_unknown_evidence_grade_is_refused, throws(error(self_provenance_bad_grade("guess"), _))) :-
    % Mint a forecast to assert about.
    self_provenance_test_forecast(ForecastRecord),
    % Read its identifier.
    get_dict(id, ForecastRecord, ForecastId),
    % A fixed instant.
    self_provenance_test_instant(Instant),
    % Asserting with a grade that is not one of the six is a hard refusal.
    self_provenance_assertion(ForecastId, "guess", 0.6, Instant, _).

% A confidence outside the unit interval is refused.
test(a_confidence_out_of_range_is_refused, throws(error(self_provenance_bad_confidence(1.5), _))) :-
    % Mint a forecast to assert about.
    self_provenance_test_forecast(ForecastRecord),
    % Read its identifier.
    get_dict(id, ForecastRecord, ForecastId),
    % A fixed instant.
    self_provenance_test_instant(Instant),
    % Asserting with a confidence above one is a hard refusal.
    self_provenance_assertion(ForecastId, "simulation", 1.5, Instant, _).

% A subject that is not a well-formed content identifier is refused.
test(a_malformed_subject_is_refused, throws(error(self_provenance_bad_about("not-an-identifier"), _))) :-
    % A fixed instant.
    self_provenance_test_instant(Instant),
    % Asserting about a string that is not a 'scheme:<64 hex>' identifier is a hard refusal.
    self_provenance_assertion("not-an-identifier", "simulation", 0.6, Instant, _).

% An assertion may not be ABOUT another provenance record; a scheme the standard's 'about' forbids is refused.
test(an_about_of_a_forbidden_scheme_is_refused, throws(error(self_provenance_bad_about(_), _))) :-
    % Build a well-formed 64-character hex body.
    self_provenance_test_hex64(Hex),
    % Form an identifier of the 'assertion' scheme, which the 'about' field forbids (only content kinds are allowed).
    string_concat("assertion:", Hex, ForbiddenAbout),
    % A fixed instant.
    self_provenance_test_instant(Instant),
    % Asserting about an assertion identifier is a hard refusal.
    self_provenance_assertion(ForbiddenAbout, "observation", 0.9, Instant, _).

% An 'evidenced_by' item that is not a token record is refused - only token records may be cited as evidence.
test(a_non_token_evidence_item_is_refused, throws(error(self_provenance_bad_evidence_item(_), _))) :-
    % Mint a real forecast to be the legitimate subject of the assertion.
    self_provenance_test_forecast(ForecastRecord),
    % Read its identifier.
    get_dict(id, ForecastRecord, ForecastId),
    % Build a well-formed 64-character hex body.
    self_provenance_test_hex64(Hex),
    % Form an attitude identifier, which may NOT be cited as evidence (an attitude is not a token record).
    string_concat("attitude:", Hex, NonTokenItem),
    % A fixed instant.
    self_provenance_test_instant(Instant),
    % Citing a non-token record as evidence is a hard refusal.
    self_provenance_assertion_evidenced(ForecastId, "observation", 0.9, [NonTokenItem], Instant, _).

% ---------------------------------------------------------------------------
% PART FOUR - THE SELF-CORRECTION LOOP: retracting and superseding one's own thoughts
% ---------------------------------------------------------------------------

% When a later tick proves a forecast wrong, the mind retracts its own assertion - the honest exit.
test(a_wrong_forecast_is_retracted) :-
    % Mint the tick-six forecast.
    self_provenance_test_forecast(ForecastRecord),
    % Read its identifier.
    get_dict(id, ForecastRecord, ForecastId),
    % A fixed instant.
    self_provenance_test_instant(Instant),
    % The mind asserts the forecast on simulation evidence.
    self_provenance_assertion(ForecastId, "simulation", 0.6, Instant, Assertion),
    % Run the trial where the screen lifts on NOTHING - the forecast was wrong.
    self_provenance_test_simulation_start(Start),
    % The absent reveal produces a signed surprise.
    prediction_loop_object_permanence_trial_records(Start, [3, 4, 5], 6, absent, Trial),
    % Read the signed error the comparator produced.
    get_dict(signed_error, Trial, SignedError),
    % A negative error means the object was expected but absent - the forecast is disconfirmed.
    assertion(SignedError =:= -1.0),
    % So the mind retracts its own assertion, giving an honest reason.
    self_provenance_retraction(Assertion, "object-permanence reveal contradicted the forecast", Instant, Retraction),
    % The retraction is a content-addressed retraction record.
    get_dict(id, Retraction, RetractionId),
    % Whose scheme is the retraction scheme.
    assertion(sub_string(RetractionId, 0, _, _, "retraction:")),
    % It withdraws exactly the assertion just made.
    get_dict(id, Assertion, AssertionId),
    % The retracts field points at that assertion.
    assertion(get_dict(retracts, Retraction, AssertionId)),
    % And the retraction is signed by the same source that made the assertion.
    get_dict(source, Assertion, Source),
    % The retraction's source matches the assertion's source (Rule 10).
    assertion(get_dict(source, Retraction, Source)).

% A retraction may not withdraw a foreign source's assertion - that would forge another mind's exit.
test(a_foreign_assertion_cannot_be_retracted, throws(error(self_provenance_foreign_retraction("ed25519:0000000000000000000000000000000000000000000000000000000000000000"), _))) :-
    % A fixed instant.
    self_provenance_test_instant(Instant),
    % Hand-craft an assertion whose source is NOT konnectome's own identity (a foreign Ed25519 key of all zeros).
    Foreign = _{type: "assertion", id: "assertion:0000000000000000000000000000000000000000000000000000000000000000", about: "attitude:1111111111111111111111111111111111111111111111111111111111111111", source: "ed25519:0000000000000000000000000000000000000000000000000000000000000000", evidence_type: "imported", confidence: 0.1, timestamp: Instant},
    % Attempting to retract a foreign assertion is a hard refusal.
    self_provenance_retraction(Foreign, "not mine to retract", Instant, _).

% A confirmed forecast is SUPERSEDED: the old stance is retracted and a stronger-graded stance restated about the same content.
test(a_confirmed_forecast_is_superseded_to_stronger_evidence) :-
    % Mint the tick-six forecast.
    self_provenance_test_forecast(ForecastRecord),
    % Read its identifier.
    get_dict(id, ForecastRecord, ForecastId),
    % A fixed instant.
    self_provenance_test_instant(Instant),
    % The mind first asserts the forecast on simulation evidence, before the outcome is known.
    self_provenance_assertion(ForecastId, "simulation", 0.6, Instant, Assertion),
    % The reveal shows the object present - the forecast is confirmed by observation.
    self_provenance_supersede(Assertion, "observation", 0.95, "forecast confirmed by observation", Instant, Retraction, NewAssertion),
    % The retraction withdraws the old assertion.
    get_dict(id, Assertion, OldId),
    % Pointing at the old assertion's identifier.
    assertion(get_dict(retracts, Retraction, OldId)),
    % The restated assertion is about the very same forecast.
    assertion(get_dict(about, NewAssertion, ForecastId)),
    % Now graded on observation, not merely simulation.
    assertion(get_dict(evidence_type, NewAssertion, "observation")),
    % Which is genuinely stronger evidence than the grade it replaced.
    assertion(self_provenance_grade_stronger(observation, simulation)),
    % And the restated assertion is a distinct record from the one withdrawn.
    get_dict(id, NewAssertion, NewId),
    % Its identifier differs from the retracted assertion's.
    assertion(NewId \== OldId).

% ---------------------------------------------------------------------------
% PART FIVE - THE HONEST NON-CLOSURE: a record is shareable and reproducible WITHOUT a signature
% (the cryptographic signature needs a private key, a secret barred from code; signing is deferred to deployment)
% ---------------------------------------------------------------------------

% An assertion carries no signature in code, yet is fully content-addressed and reproducible.
test(an_assertion_is_content_addressed_without_a_signature) :-
    % Mint a forecast to assert about.
    self_provenance_test_forecast(ForecastRecord),
    % Read its identifier.
    get_dict(id, ForecastRecord, ForecastId),
    % A fixed instant.
    self_provenance_test_instant(Instant),
    % Assert about the forecast.
    self_provenance_assertion(ForecastId, "simulation", 0.6, Instant, Assertion),
    % The minted record carries NO signature field - signing is a deployment-time act, never a secret in code.
    assertion(\+ get_dict(signature, Assertion, _)),
    % Yet it is fully content-addressed by its identity-bearing fields.
    get_dict(id, Assertion, AssertionId),
    % Whose scheme is the assertion scheme.
    assertion(sub_string(AssertionId, 0, _, _, "assertion:")),
    % And re-minting the identical assertion reproduces the identical identifier, signature or no signature.
    self_provenance_assertion(ForecastId, "simulation", 0.6, Instant, Again),
    % The second identifier equals the first.
    assertion(get_dict(id, Again, AssertionId)).

% Close the test block for the self_provenance pack.
:- end_tests(self_provenance).
