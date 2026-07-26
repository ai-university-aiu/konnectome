% Declare the capstone_demonstration module and the small public interface of the capstone.
:- module(capstone_demonstration, [
    % capstone_demonstration_simulation_start/1: the fixed simulation start, so every telling is deterministic.
    capstone_demonstration_simulation_start/1,
    % capstone_demonstration_default_ticks/1: the default number of heartbeat ticks the story runs.
    capstone_demonstration_default_ticks/1,
    % capstone_demonstration_world/1: the boot world the story starts the mind from.
    capstone_demonstration_world/1,
    % capstone_demonstration_story/2: tell the whole glass-box story as a list of text lines.
    capstone_demonstration_story/2,
    % capstone_demonstration_run/0: print the story with the default tick count.
    capstone_demonstration_run/0,
    % capstone_demonstration_run/1: print the story with a chosen tick count.
    capstone_demonstration_run/1
]).

% Reuse the cognitive cycle: the one predicate that runs the whole ten-component mind for many ticks.
:- use_module(library(cognitive_cycle), [
    % cognitive_cycle_run/4: run the mind from a boot world for a number of ticks, yielding per-tick summaries.
    cognitive_cycle_run/4
]).
% Reuse thought combination: minting thoughts and combining them into a chain of thought.
:- use_module(library(thought_combination), [
    % thought_combination_atomic/3: mint one atomic thought as a content-addressed occurrent.
    thought_combination_atomic/3,
    % thought_combination_combine/3: combine causes and effects into a causal relation object.
    thought_combination_combine/3,
    % thought_combination_links/2: check that one combination's effect is the next one's cause.
    thought_combination_links/2
]).
% Reuse other minds: the false-belief trial and its export as a shareable attitude record.
:- use_module(library(other_minds), [
    % other_minds_reset/0: clear the theory-of-mind runtime before the social scene.
    other_minds_reset/0,
    % other_minds_world_fact_add/1: record konnectome's own world fact.
    other_minds_world_fact_add/1,
    % other_minds_belief_attribute/2: attribute a belief to a modelled agent.
    other_minds_belief_attribute/2,
    % other_minds_nested_attribute/3: model one agent's model of another agent's belief.
    other_minds_nested_attribute/3,
    % other_minds_false_belief/2: check an attributed belief contradicts the world's own record.
    other_minds_false_belief/2,
    % other_minds_search_prediction_export/5: export the trial's predicted search as an attitude record.
    other_minds_search_prediction_export/5
]).
% Reuse the prediction loop: the object-permanence trial and the minting of forecasts.
:- use_module(library(prediction_loop), [
    % prediction_loop_object_permanence_trial_records/5: the full glass-box trial with minted records.
    prediction_loop_object_permanence_trial_records/5,
    % prediction_loop_outcome_type/2: the reusable outcome occurrent a forecast is about.
    prediction_loop_outcome_type/2,
    % prediction_loop_predictor/1: the predicting construct's own continuant identifier.
    prediction_loop_predictor/1,
    % prediction_loop_record_prediction/4: mint one forecast as a predicted_occurrence record.
    prediction_loop_record_prediction/4
]).
% Reuse self provenance: the mind grading, superseding, and retracting its own assertions.
:- use_module(library(self_provenance), [
    % self_provenance_source/1: konnectome's own public, secret-free signing identity.
    self_provenance_source/1,
    % self_provenance_instant/3: a tick's absolute instant from the simulation start.
    self_provenance_instant/3,
    % self_provenance_assertion/5: assert about one of the mind's own records, graded and weighted.
    self_provenance_assertion/5,
    % self_provenance_retraction/4: withdraw a prior assertion under the same source.
    self_provenance_retraction/4,
    % self_provenance_supersede/7: retract a stance and restate it under a new evidence grade.
    self_provenance_supersede/7
]).
% Reuse the list library for membership checks over body state.
:- use_module(library(lists), [
    % memberchk/2: find the monitored variable inside the body state list.
    memberchk/2,
    % append/2: join the story's sections into one list of lines.
    append/2,
    % last/2: the reveal-tick forecast is the last of the trial's minted predictions.
    last/2
]).

% The capstone demonstration boots the whole mind and lets its own records tell what happened.
% It is the Demonstration phase of the SPARCD method made runnable: one deterministic story,
% told in rung order - the heartbeat and the regulated body (Rung Zero), the object-permanence
% forecast and its signed surprise (Rung One), a combined thought, the false belief attributed
% to another mind (Rung Four), and the provenance layer standing behind and, when the world
% disagrees, honestly disowning the mind's own stances. The story claims only what is shown:
% the rungs not yet demonstrated are named as such, and the records are declared unsigned,
% because the signing key is a secret this code may never hold.

% capstone_demonstration_simulation_start(-Start): the fixed simulation start instant.
capstone_demonstration_simulation_start("2026-07-26T00:00:00Z").

% capstone_demonstration_default_ticks(-NumTicks): the default heartbeat length of the story.
capstone_demonstration_default_ticks(10).

% capstone_demonstration_world(-World): the boot world - a small body, one drive, one learnable interface.
capstone_demonstration_world(World) :-
    % The story's fixed simulation start stamps every minted record.
    capstone_demonstration_simulation_start(Start),
    % The world starts at tick zero with a too-warm body, one temperature drive defending
    % thirty-seven, an empty bus, a source construct feeding a relay through one learnable
    % transmissive interface, and the respiration override armed but at rest.
    World = world{
        tick: 0,
        body: [temperature-40],
        drives: [drive(temperature, temperature, 37, none)],
        bus: [],
        constructs: [construct(a, source), construct(b, relay(1))],
        activations: [a-1, b-0],
        interfaces: [interface(a, b, 0.5, 1, transmissive)],
        overrides: [override(respiration, 0, 0.0, breathe)],
        override_threshold: 0.5,
        learning_rate: 0.1,
        simulation_start: Start
    }.

% capstone_demonstration_story(+NumTicks, -Story): tell the whole glass-box story over NumTicks heartbeats.
capstone_demonstration_story(NumTicks, Story) :-
    % Refuse a tick count that cannot carry the demonstration.
    capstone_demonstration_check_ticks(NumTicks),
    % Boot the mind's world.
    capstone_demonstration_world(World0),
    % Run the whole mind for the requested number of ticks.
    cognitive_cycle_run(World0, NumTicks, WorldFinal, Summaries),
    % The title names the demonstration.
    capstone_demonstration_title_lines(Title),
    % Rung Zero: the heartbeat, the reward, the learning, and the regulated body.
    capstone_demonstration_heartbeat_lines(NumTicks, WorldFinal, Summaries, Heartbeat),
    % Rung One: the object-permanence forecast, confirmed and surprised.
    capstone_demonstration_prediction_lines(Prediction),
    % The combined thought: a chain of thought as content-addressed records.
    capstone_demonstration_thought_lines(Thought),
    % Rung Four: the false belief attributed to another mind, exported as an attitude record.
    capstone_demonstration_social_lines(AttitudeRecord, Social),
    % The provenance layer: the mind grades, supersedes, and retracts its own stances.
    capstone_demonstration_provenance_lines(AttitudeRecord, Provenance),
    % The honest limits: what this story does not claim.
    capstone_demonstration_epilogue_lines(Epilogue),
    % The story is the sections joined in rung order.
    append([Title, Heartbeat, Prediction, Thought, Social, Provenance, Epilogue], Story).

% capstone_demonstration_check_ticks(+NumTicks): the tick count must be an integer of at least six.
capstone_demonstration_check_ticks(NumTicks) :-
    % A whole number of at least six heartbeats carries the demonstration.
    integer(NumTicks),
    % Six is the least count that regulates the body and grows the weight.
    NumTicks >= 6,
    % A good count is accepted.
    !.
% Any other tick count is refused as a hard error.
capstone_demonstration_check_ticks(NumTicks) :-
    % Refuse with a named, inspectable error.
    throw(error(capstone_demonstration_bad_ticks(NumTicks),
                context(capstone_demonstration_story/2, "the tick count must be an integer of at least six"))).

% capstone_demonstration_title_lines(-Lines): the story's title.
capstone_demonstration_title_lines(Lines) :-
    % The title and its one-line promise.
    Lines = [
        "KONNECTOME - THE CAPSTONE DEMONSTRATION",
        "The glass-box story of one small mind, told by the mind's own records."
    ].

% capstone_demonstration_heartbeat_lines(+NumTicks, +WorldFinal, +Summaries, -Lines): Rung Zero narrated.
capstone_demonstration_heartbeat_lines(NumTicks, WorldFinal, Summaries, Lines) :-
    % Narrate every tick the mind lived.
    capstone_demonstration_tick_lines(Summaries, TickLines),
    % Read the final body state.
    get_dict(body, WorldFinal, Body),
    % Read the regulated variable.
    memberchk(temperature-Temperature, Body),
    % The story only claims regulation the run achieved.
    Temperature =:= 37,
    % Read the learned interfaces.
    get_dict(interfaces, WorldFinal, [interface(a, b, Weight, _, _)]),
    % The story only claims learning the run achieved.
    Weight > 0.5,
    % The body's closing line.
    format(string(BodyLine),
           "After ~w ticks the body's temperature stands at ~w - the set-point the drive defends.",
           [NumTicks, Temperature]),
    % The learning's closing line.
    format(string(WeightLine),
           "The interface from a to b now carries weight ~w, grown from 0.5 by the three-factor rule.",
           [Weight]),
    % The rung's header, boot lines, tick lines, and closing lines in order.
    append([
        [
            "",
            "RUNG ZERO - THE HEARTBEAT AND THE REGULATED BODY",
            "The mind boots with its body too warm: temperature 40 against a defended set-point of 37.",
            "One drive watches that variable; a source construct feeds a relay through one learnable interface of weight 0.5.",
            "The respiration override stands armed at rest (distress 0.0, threshold 0.5): safety is wired in, and today it never needs to seize control."
        ],
        TickLines,
        [BodyLine, WeightLine]
    ], Lines).

% capstone_demonstration_tick_lines(+Summaries, -Lines): one glass-box line per lived tick.
capstone_demonstration_tick_lines([], []).
% Each tick summary becomes one line naming the reward, the dopamine broadcast, the action, and the record.
capstone_demonstration_tick_lines([tick_summary(Number, Reward, Outcome, Record)|Rest], [Line|Lines]) :-
    % Read the tick's content-addressed observer record identifier.
    get_dict(id, Record, Identifier),
    % The tick's one line: the reward is broadcast as dopamine, one action is released, one record minted.
    format(string(Line),
           "Tick ~w: reward ~w, broadcast as dopamine ~w; action ~w; recorded as ~w.",
           [Number, Reward, Reward, Outcome, Identifier]),
    % Narrate the remaining ticks.
    capstone_demonstration_tick_lines(Rest, Lines).

% capstone_demonstration_prediction_lines(-Lines): Rung One narrated - the forecast confirmed and surprised.
capstone_demonstration_prediction_lines(Lines) :-
    % The story's fixed simulation start stamps the trial's records.
    capstone_demonstration_simulation_start(Start),
    % The kind world: the object is hidden over ticks three to five and revealed present at tick six.
    prediction_loop_object_permanence_trial_records(Start, [3, 4, 5], 6, present, Confirmed),
    % Read the confirmed trial's signed error.
    get_dict(signed_error, Confirmed, ConfirmedError),
    % Read the trial's minted forecasts.
    get_dict(predictions, Confirmed, ForecastRecords),
    % The reveal-tick forecast - the one the trial's error record grades - is the last minted.
    last(ForecastRecords, RevealForecast),
    % Read that forecast's content-addressed identifier.
    get_dict(id, RevealForecast, ForecastIdentifier),
    % Read the confirmed trial's observed outcome record.
    get_dict(outcome, Confirmed, OutcomeRecord),
    % Read the outcome's content-addressed identifier.
    get_dict(id, OutcomeRecord, OutcomeIdentifier),
    % The cruel world: the same hiding, but the screen lifts on nothing at tick six.
    prediction_loop_object_permanence_trial_records(Start, [3, 4, 5], 6, absent, Surprised),
    % Read the surprised trial's signed error.
    get_dict(signed_error, Surprised, SurprisedError),
    % Read the surprised trial's prediction_error record.
    get_dict(error, Surprised, SurpriseErrorRecord),
    % Read that record's content-addressed identifier.
    get_dict(id, SurpriseErrorRecord, SurpriseErrorIdentifier),
    % The confirmed reveal's line.
    format(string(ConfirmedLine),
           "At tick 6 the screen lifts and the object is there: outcome ~w, signed error ~w - no surprise.",
           [OutcomeIdentifier, ConfirmedError]),
    % The forecast's line, naming the reveal-tick forecast the error record will grade.
    format(string(ForecastLine),
           "While the object is hidden the mind holds a forecast for the reveal on the record: ~w.",
           [ForecastIdentifier]),
    % The surprised reveal's line.
    format(string(SurprisedLine),
           "Told again crueler, the screen lifts on nothing: signed error ~w, minted as ~w - the machine form of surprise.",
           [SurprisedError, SurpriseErrorIdentifier]),
    % The rung's lines in order.
    Lines = [
        "",
        "RUNG ONE - OBJECT PERMANENCE: THE FORECAST AND THE SURPRISE",
        "An object is hidden behind a screen at ticks 3, 4, and 5; the mind expects it to go on existing.",
        ForecastLine,
        ConfirmedLine,
        SurprisedLine
    ].

% capstone_demonstration_thought_lines(-Lines): a combined thought narrated as a chain of records.
capstone_demonstration_thought_lines(Lines) :-
    % Mint the atomic thought of rain as an event occurrent.
    thought_combination_atomic("rain", "event", RainIdentifier),
    % Mint the atomic thought of wet ground as a state occurrent.
    thought_combination_atomic("wet_ground", "state", WetIdentifier),
    % Mint the atomic thought of a slippery path as a state occurrent.
    thought_combination_atomic("slippery_path", "state", SlipperyIdentifier),
    % Combine rain causing wet ground into one causal relation object.
    thought_combination_combine([RainIdentifier], [WetIdentifier], FirstThought),
    % Combine wet ground causing a slippery path into a second causal relation object.
    thought_combination_combine([WetIdentifier], [SlipperyIdentifier], SecondThought),
    % The two combinations really do link into a chain of thought.
    thought_combination_links(FirstThought, SecondThought),
    % Read the first combination's content-addressed identifier.
    get_dict(id, FirstThought, FirstIdentifier),
    % Read the second combination's content-addressed identifier.
    get_dict(id, SecondThought, SecondIdentifier),
    % The first combination's line.
    format(string(FirstLine),
           "Rain causes wet ground, minted as ~w.",
           [FirstIdentifier]),
    % The second combination's line.
    format(string(SecondLine),
           "Wet ground causes a slippery path, minted as ~w.",
           [SecondIdentifier]),
    % The section's lines in order.
    Lines = [
        "",
        "THE COMBINED THOUGHT - A CHAIN OF THOUGHT AS RECORDS",
        FirstLine,
        SecondLine,
        "The first thought's effect is the second thought's cause: a chain of thought, checkable from the records alone."
    ].

% capstone_demonstration_social_lines(-AttitudeRecord, -Lines): Rung Four narrated - the false belief.
capstone_demonstration_social_lines(AttitudeRecord, Lines) :-
    % Start the social scene from a clean runtime.
    other_minds_reset,
    % Konnectome's own world record: the marble is really in the box.
    other_minds_world_fact_add(object_location(marble, box)),
    % Sally is attributed the belief that the marble is in the basket.
    other_minds_belief_attribute(sally, object_location(marble, basket)),
    % Konnectome also models itself modelling Sally's belief - the nested attribution.
    other_minds_nested_attribute(konnectome, sally, object_location(marble, basket)),
    % Sally's attributed belief really is false against the world's own record.
    other_minds_false_belief(sally, object_location(marble, basket)),
    % The story's fixed simulation start is the export instant.
    capstone_demonstration_simulation_start(Start),
    % Export the trial's predicted search as a shareable, content-addressed attitude record.
    other_minds_search_prediction_export(sally, marble, Start, Place, AttitudeRecord),
    % Read the attitude's content-addressed identifier.
    get_dict(id, AttitudeRecord, AttitudeIdentifier),
    % Read the modelled holder's identifier.
    get_dict(holder, AttitudeRecord, HolderIdentifier),
    % The prediction's line.
    format(string(SearchLine),
           "Asked where Sally will search, the mind answers from her belief, not from the world: the ~w.",
           [Place]),
    % The export's line.
    format(string(ExportLine),
           "The attribution is minted as ~w, its holder the modelled agent ~w.",
           [AttitudeIdentifier, HolderIdentifier]),
    % The rung's lines in order.
    Lines = [
        "",
        "RUNG FOUR - THE FALSE BELIEF: MODELLING ANOTHER MIND",
        "The marble really sits in the box - the world's own record says so.",
        "Sally last saw it in the basket, so the mind attributes to her a belief the world contradicts - and holds both records at once, in quarantine, without poisoning its own.",
        "The mind even nests the model: konnectome models konnectome modelling Sally's belief.",
        SearchLine,
        ExportLine
    ].

% capstone_demonstration_provenance_social_stance(+AttitudeIdentifier, -SocialAssertionIdentifier): the mind stands behind its attribution.
capstone_demonstration_provenance_social_stance(AttitudeIdentifier, SocialAssertionIdentifier) :-
    % The story's fixed simulation start stamps the stance.
    capstone_demonstration_simulation_start(Start),
    % The social assertion is stamped at the trial's own instant, tick zero.
    self_provenance_instant(Start, 0, SocialInstant),
    % The mind asserts its own attribution on observation evidence with high confidence.
    self_provenance_assertion(AttitudeIdentifier, "observation", 0.9, SocialInstant, SocialAssertion),
    % Read the social assertion's identifier.
    get_dict(id, SocialAssertion, SocialAssertionIdentifier).

% capstone_demonstration_provenance_forecast_stances(-ForecastIdentifier, -ForecastAssertionIdentifier, -SupersedeRetractionIdentifier, -UpgradedAssertionIdentifier, -RetractionIdentifier): the forecast asserted, upgraded, and disowned.
capstone_demonstration_provenance_forecast_stances(ForecastIdentifier, ForecastAssertionIdentifier,
                                                   SupersedeRetractionIdentifier, UpgradedAssertionIdentifier,
                                                   RetractionIdentifier) :-
    % The story's fixed simulation start stamps the stances.
    capstone_demonstration_simulation_start(Start),
    % The forecast the provenance acts are about: the reusable outcome occurrent.
    prediction_loop_outcome_type("hidden_object_present", OutcomeTypeIdentifier),
    % The predicting construct's own identifier.
    prediction_loop_predictor(PredictorIdentifier),
    % Mint the reveal-tick forecast as a predicted_occurrence record - the very record Rung One displayed.
    prediction_loop_record_prediction(OutcomeTypeIdentifier, 6, PredictorIdentifier, Forecast),
    % Read the forecast's identifier.
    get_dict(id, Forecast, ForecastIdentifier),
    % The forecast's assertion is stamped at the reveal tick's instant.
    self_provenance_instant(Start, 6, ForecastInstant),
    % The mind asserts its forecast on simulation evidence - a model-based forecast is model-based evidence.
    self_provenance_assertion(ForecastIdentifier, "simulation", 0.6, ForecastInstant, ForecastAssertion),
    % Read the forecast assertion's identifier.
    get_dict(id, ForecastAssertion, ForecastAssertionIdentifier),
    % In the kind world the reveal confirms the forecast, so the stance is superseded to observation at the reveal instant.
    self_provenance_supersede(ForecastAssertion, "observation", 0.95,
                              "the object-permanence reveal confirmed the forecast",
                              ForecastInstant, SupersedeRetraction, UpgradedAssertion),
    % Read the superseding retraction's identifier.
    get_dict(id, SupersedeRetraction, SupersedeRetractionIdentifier),
    % Read the upgraded assertion's identifier.
    get_dict(id, UpgradedAssertion, UpgradedAssertionIdentifier),
    % The cruel world's retraction is stamped one tick AFTER the reveal - the mind meets the surprise, then disowns
    % the claim - and the later timestamp gives this retraction its own identity, distinct from the supersession's
    % withdrawal, so the two worlds' acts are tellable apart from the records alone.
    self_provenance_instant(Start, 7, RetractionInstant),
    % In the cruel world the reveal contradicts the forecast, so the assertion is retracted outright.
    self_provenance_retraction(ForecastAssertion,
                               "the object-permanence reveal contradicted the forecast",
                               RetractionInstant, Retraction),
    % Read the retraction's identifier.
    get_dict(id, Retraction, RetractionIdentifier).

% capstone_demonstration_provenance_lines(+AttitudeRecord, -Lines): the provenance layer narrated.
capstone_demonstration_provenance_lines(AttitudeRecord, Lines) :-
    % Konnectome's own public signing identity.
    self_provenance_source(Source),
    % Read the attitude's content-addressed identifier.
    get_dict(id, AttitudeRecord, AttitudeIdentifier),
    % Read the attitude's modelled holder.
    get_dict(holder, AttitudeRecord, HolderIdentifier),
    % Mint the social stance.
    capstone_demonstration_provenance_social_stance(AttitudeIdentifier, SocialAssertionIdentifier),
    % Mint the forecast stances: asserted, superseded in the kind world, retracted in the cruel one.
    capstone_demonstration_provenance_forecast_stances(ForecastIdentifier, ForecastAssertionIdentifier,
                                                       SupersedeRetractionIdentifier, UpgradedAssertionIdentifier,
                                                       RetractionIdentifier),
    % The signing line.
    format(string(SourceLine),
           "Every stance below is made under the mind's own public identity ~w - Rule 25 kept: the modelled holder ~w and the signing source are different identities.",
           [Source, HolderIdentifier]),
    % The social assertion's line.
    format(string(SocialLine),
           "The mind stands behind its attribution: assertion ~w, graded observation, confidence 0.9.",
           [SocialAssertionIdentifier]),
    % The forecast assertion's line.
    format(string(ForecastLine),
           "It stands behind its forecast more humbly: assertion ~w about ~w, graded simulation, confidence 0.6.",
           [ForecastAssertionIdentifier, ForecastIdentifier]),
    % The supersession's line.
    format(string(SupersedeLine),
           "When the reveal confirms it, the stance is superseded: retraction ~w withdraws the old grade and assertion ~w restates it on observation evidence, confidence 0.95.",
           [SupersedeRetractionIdentifier, UpgradedAssertionIdentifier]),
    % The retraction's line.
    format(string(RetractionLine),
           "When the reveal contradicts it, the mind retracts: ~w withdraws the forecast's assertion, signed by the same source - the honest exit, on the record.",
           [RetractionIdentifier]),
    % The layer's lines in order.
    Lines = [
        "",
        "THE PROVENANCE LAYER - THE MIND STANDS BEHIND ITS THOUGHTS",
        SourceLine,
        SocialLine,
        ForecastLine,
        SupersedeLine,
        RetractionLine
    ].

% capstone_demonstration_epilogue_lines(-Lines): the honest limits, claimed plainly.
capstone_demonstration_epilogue_lines(Lines) :-
    % The story claims only what it showed.
    Lines = [
        "",
        "WHAT IS HONESTLY NOT DEMONSTRATED",
        "Rung Two (symbols and pretend play), Rung Three (concrete reasoning), and Rung Five (embodiment) are not yet demonstrated, and this story does not claim them.",
        "Every record above is content-addressed and shareable, but unsigned: the Ed25519 private key is a secret barred from this code, so signing is a deployment act, and a strict consumer quarantines these records until the key-holder signs them.",
        "This has been the whole of the mind, told by its own records. Nothing above is claimed that a reader cannot re-mint, re-run, and check."
    ].

% capstone_demonstration_run: print the story with the default tick count.
capstone_demonstration_run :-
    % The default heartbeat length.
    capstone_demonstration_default_ticks(NumTicks),
    % Print the story at that length.
    capstone_demonstration_run(NumTicks).

% capstone_demonstration_run(+NumTicks): print the story, one line at a time.
capstone_demonstration_run(NumTicks) :-
    % Tell the story.
    capstone_demonstration_story(NumTicks, Story),
    % Print every line in order.
    capstone_demonstration_print_lines(Story).

% capstone_demonstration_print_lines(+Lines): print each line followed by a newline.
capstone_demonstration_print_lines([]).
% Print the first line, then the rest.
capstone_demonstration_print_lines([Line|Rest]) :-
    % One line, one newline.
    format("~w~n", [Line]),
    % The rest in order.
    capstone_demonstration_print_lines(Rest).
