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
% Reuse symbol exchange: the first grounded words and the drive-coloured reply.
:- use_module(library(symbol_exchange), [
    % symbol_exchange_vocabulary/3: live the run and ground the standard two-word vocabulary.
    symbol_exchange_vocabulary/3,
    % symbol_exchange_reply/5: the pilot - the reply coloured by the mind's own drive state.
    symbol_exchange_reply/5
]).
% Reuse pretend play: the pretend game sealed inside the five-reality quarantine.
:- use_module(library(pretend_play), [
    % pretend_play_reset/0: clear every reality before the pretend scene.
    pretend_play_reset/0,
    % pretend_play_transition_add/3: teach the one what-if transition the scene pretends over.
    pretend_play_transition_add/3,
    % pretend_play_pretend/3: roll the pretend scene forward through the taught transitions.
    pretend_play_pretend/3,
    % pretend_play_quarantined/1: the pretended fact is sealed in the imagined reality only.
    pretend_play_quarantined/1,
    % pretend_play_holds/2: check a fact against one named reality directly.
    pretend_play_holds/2,
    % pretend_play_promote/3: the guarded crossing - auditable between quarantined realities, refused into observed.
    pretend_play_promote/3,
    % pretend_play_thought/3: mint the pretend relation as a content-addressed thought.
    pretend_play_thought/3,
    % pretend_play_stance/3: the mind's simulation-graded stance on a pretend thought.
    pretend_play_stance/3
]).
% Reuse empathy: the social pain, the empathy trial, and the retractable social attribution.
:- use_module(library(empathy), [
    % empathy_social_connection_drive/1: the standard social drive defending belonging.
    empathy_social_connection_drive/1,
    % empathy_rejection/2: the social severance signal over the body.
    empathy_rejection/2,
    % empathy_modelled_distress/3: the only sanctioned constructor of a modelled distress.
    empathy_modelled_distress/3,
    % empathy_resonance/3: modelled distress resonating into the mind's own belonging.
    empathy_resonance/3,
    % empathy_trial/5: the whole empathy trial - resonance, proposals, selection, applied help.
    empathy_trial/5,
    % empathy_trial_candidates/5: the trial up to selection, exposing the candidates.
    empathy_trial_candidates/5,
    % empathy_distress_record/3: the modelled distress minted as a shareable fears attitude.
    empathy_distress_record/3,
    % empathy_attribution_stance/3: the mind's observation-graded stance on its own attribution.
    empathy_attribution_stance/3,
    % empathy_attribution_retract/4: the honest exit when the attribution was mistaken.
    empathy_attribution_retract/4
]).
% Reuse the drive system: the one error predicate both pains pass through, and the shared step.
:- use_module(library(drive_system), [
    % drive_system_error/3: the absolute distance of a monitored variable from its set-point.
    drive_system_error/3,
    % drive_system_step/6: one tick of the unchanged drive machinery, reward and broadcast included.
    drive_system_step/6
]).
% Reuse the neuromodulator bus: reading the dopamine broadcast off the shared bus.
:- use_module(library(neuromodulator_bus), [
    % neuromodulator_bus_level/3: the level of one neuromodulator on the bus.
    neuromodulator_bus_level/3
]).
% Reuse the override controller: breath still overrides kindness.
:- use_module(library(override_controller), [
    % override_controller_arbitrate/4: a vital drive in distress seizes control from any released action.
    override_controller_arbitrate/4
]).
% Reuse the action selector: the released help must appear among the candidates.
:- use_module(library(action_selector), [
    % action_selector_is_candidate/2: the released outcome was proposed, never invented.
    action_selector_is_candidate/2
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
% forecast and its signed surprise (Rung One), a combined thought, the first grounded words and
% the pretend game under quarantine (Rung Two), the false belief attributed to another mind
% (Rung Four), the rung's deepening - the social pain and the empathy trial - and the provenance
% layer standing behind and, when the world disagrees, honestly disowning the mind's own stances.
% The story claims only what is shown: the rungs not yet demonstrated are named as such, and the
% records are declared unsigned, because the signing key is a secret this code may never hold.

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
    % Rung Two: the first grounded words, and the pretend game under quarantine.
    capstone_demonstration_first_words_lines(FirstWords),
    % Rung Four: the false belief attributed to another mind, exported as an attitude record.
    capstone_demonstration_social_lines(AttitudeRecord, Social),
    % Rung Four, deepened: the social pain and the empathy trial.
    capstone_demonstration_empathy_lines(Empathy),
    % The provenance layer: the mind grades, supersedes, and retracts its own stances.
    capstone_demonstration_provenance_lines(AttitudeRecord, Provenance),
    % The honest limits: what this story does not claim.
    capstone_demonstration_epilogue_lines(Epilogue),
    % The story is the sections joined in rung order.
    append([Title, Heartbeat, Prediction, Thought, FirstWords, Social, Empathy, Provenance, Epilogue], Story).

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

% capstone_demonstration_first_words_lines(-Lines): Rung Two narrated - the first words, and the pretend game.
capstone_demonstration_first_words_lines(Lines) :-
    % The words grow from the same boot world the heartbeat lived.
    capstone_demonstration_world(World0),
    % Live ten ticks and ground the standard two-word vocabulary in the conditions actually lived.
    symbol_exchange_vocabulary(World0, 10, Groundings),
    % The story only claims the grounding the run achieved: both words, each in a lived condition.
    Groundings == [grounding(warm, in_deficit), grounding(settled, satisfied)],
    % Read the two groundings for the narration.
    Groundings = [grounding(DeficitWord, DeficitCondition), grounding(SatisfiedWord, SatisfiedCondition)],
    % The pilot's drive: the same temperature drive the heartbeat runs on.
    ReplyDrives = [drive(temperature, temperature, 37, none)],
    % Ask while the body runs warm.
    symbol_exchange_reply(Groundings, ReplyDrives, [temperature-40], [how, are, you], DeficitReply),
    % Ask the same words while the body sits at the set-point.
    symbol_exchange_reply(Groundings, ReplyDrives, [temperature-37], [how, are, you], SatisfiedReply),
    % The story only claims the discriminator the run achieved: in deficit, the state word then the sought word.
    DeficitReply == [warm, settled],
    % Satisfied, the state word alone.
    SatisfiedReply == [settled],
    % The same heard words really drew different replies in different drive states.
    DeficitReply \== SatisfiedReply,
    % Join the deficit reply's words for the narration.
    atomic_list_concat(DeficitReply, " ", DeficitText),
    % Join the satisfied reply's words for the narration.
    atomic_list_concat(SatisfiedReply, " ", SatisfiedText),
    % Start the pretend runtime from a clean slate, so the telling is deterministic.
    pretend_play_reset,
    % Teach the one what-if transition the scene pretends over.
    pretend_play_transition_add(settled, sun_beats_down, too_warm),
    % Roll the pretend scene forward through the taught transition.
    pretend_play_pretend(settled, [sun_beats_down], Trajectory),
    % The story only claims the trajectory the pretend achieved.
    Trajectory == [settled, too_warm],
    % The pretended state is sealed in the imagined reality only.
    pretend_play_quarantined(visited(too_warm)),
    % The observed record never holds the pretended state.
    \+ pretend_play_holds(observed, visited(too_warm)),
    % A deliberate, auditable crossing carries the pretended state into expectation.
    pretend_play_promote(imagined, visited(too_warm), expected),
    % The crossing really happened.
    pretend_play_holds(expected, visited(too_warm)),
    % The crossing into observed is refused by name - the story shows the refusal, never the success.
    catch(pretend_play_promote(imagined, visited(too_warm), observed),
          error(pretend_play_forbidden_promotion(visited(too_warm)), _),
          Refused = true),
    % The refusal really fired.
    Refused == true,
    % Even after the auditable crossing and the refused one, the observed record still holds nothing pretended.
    \+ pretend_play_holds(observed, visited(too_warm)),
    % Mint the pretend relation as a content-addressed thought.
    pretend_play_thought("sun_beats_down", "body_too_warm", PretendThought),
    % Read the pretend thought's content-addressed identifier.
    get_dict(id, PretendThought, PretendIdentifier),
    % The story's fixed simulation start stamps the stance.
    capstone_demonstration_simulation_start(Start),
    % The mind's stance on its pretend thought is graded simulation, never observation.
    pretend_play_stance(PretendThought, Start, PretendStance),
    % The stance really carries the simulation grade.
    get_dict(evidence_type, PretendStance, "simulation"),
    % The stance really is about the pretend thought.
    get_dict(about, PretendStance, PretendIdentifier),
    % Read the stance's content-addressed identifier.
    get_dict(id, PretendStance, StanceIdentifier),
    % The grounding's line.
    format(string(GroundingLine),
           "Living ten ticks from its too-warm boot, the mind lives both of its conditions and grounds two words in them: ~w in ~w, and ~w in ~w.",
           [DeficitWord, DeficitCondition, SatisfiedWord, SatisfiedCondition]),
    % The deficit reply's line.
    format(string(DeficitLine),
           "In deficit - its temperature at 40 against the defended 37 - it answers: ~w.",
           [DeficitText]),
    % The satisfied reply's line.
    format(string(SatisfiedLine),
           "Satisfied - its temperature at the set-point - it answers: ~w.",
           [SatisfiedText]),
    % The pretend trajectory's line.
    format(string(TrajectoryLine),
           "Pretending the sun beats down on a settled body, the scene rolls forward: ~w - and every visited state is sealed in the imagined reality.",
           [Trajectory]),
    % The pretend thought's line.
    format(string(ThoughtLine),
           "The pretend thought - sun beats down causes body too warm - is minted as ~w.",
           [PretendIdentifier]),
    % The stance's line.
    format(string(StanceLine),
           "The mind's stance on it is graded simulation at confidence 0.5, minted as ~w: pretend evidence never outranks observation.",
           [StanceIdentifier]),
    % The rung's lines in order.
    Lines = [
        "",
        "RUNG TWO - THE FIRST WORDS, AND PRETENDING WITHOUT LYING",
        "Words are not labels pasted on things: a word may be grounded only in a condition the mind actually lived.",
        GroundingLine,
        "Asked the same heard words twice - how, are, you - the reply is coloured by the drive state, not by a script.",
        DeficitLine,
        SatisfiedLine,
        "Then the mind pretends, without lying: the pretend game runs inside the five-reality quarantine.",
        TrajectoryLine,
        "A deliberate, auditable crossing may carry a pretended state into expectation - and here it does.",
        "But the crossing into the observed record is refused outright, in the pack's own words: pretend may never be promoted into the observed record.",
        ThoughtLine,
        StanceLine
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

% capstone_demonstration_empathy_lines(-Lines): Rung Four deepened - the social pain and the empathy trial.
capstone_demonstration_empathy_lines(Lines) :-
    % A physical thwarting: the body one degree from its defended set-point.
    drive_system_error(drive(temperature, temperature, 37, none), [temperature-38], PhysicalError),
    % The standard social drive: belonging defended at a set-point of one.
    empathy_social_connection_drive(SocialDrive),
    % Connection at the set-point carries no error.
    drive_system_error(SocialDrive, [belonging-1], ConnectedError),
    % The story only claims the satisfaction the numbers show.
    ConnectedError =:= 0,
    % The severance: a rejection drops belonging to zero.
    empathy_rejection([belonging-1], RejectedBody),
    % The social severance read through the very same predicate as the physical thwarting.
    drive_system_error(SocialDrive, RejectedBody, SocialError),
    % The story only claims the equivalence the numbers show: the two pains are equal.
    PhysicalError =:= SocialError,
    % One tick of the unchanged drive machinery over the severed connection.
    drive_system_step([drive(social_connection, belonging, 1, 0)], [belonging-0], [], _PainDrives, PainReward, PainBus),
    % The story only claims the pain the machinery produced.
    PainReward =:= -1,
    % The pain is broadcast as dopamine on the shared bus.
    neuromodulator_bus_level(PainBus, dopamine, PainLevel),
    % The story only claims the broadcast the bus carries.
    PainLevel =:= -1,
    % One tick of the same machinery over the restored connection.
    drive_system_step([drive(social_connection, belonging, 1, 1)], [belonging-1], [], _ReliefDrives, ReliefReward, _ReliefBus),
    % The story only claims the relief the machinery produced.
    ReliefReward =:= 1,
    % Two drives compete in the trial: a mildly pressing temperature and a satisfied connection.
    TrialDrives = [drive(temperature, temperature, 37, none), SocialDrive],
    % The shared body the trial starts from.
    TrialBody = [temperature-37.5, belonging-1],
    % With Ana fine, there is no distress to model.
    empathy_modelled_distress(ana, 0, NoDistress),
    % The calm trial.
    empathy_trial(NoDistress, TrialDrives, TrialBody, CalmOutcome, _CalmBody),
    % The story only claims the calm selection the trial made: the mind tends its own temperature.
    CalmOutcome == released(reduce(temperature)),
    % With Ana in full distress, the mind models her trouble.
    empathy_modelled_distress(ana, 1, FullDistress),
    % Resonance alone: modelling her distress lowers the mind's OWN belonging.
    empathy_resonance(FullDistress, [belonging-1], ResonatedBody),
    % The story only claims the resonance the machinery produced.
    ResonatedBody == [belonging-0],
    % The empathy trial: resonance, proposals, selection, applied help.
    empathy_trial(FullDistress, TrialDrives, TrialBody, HelpOutcome, HelpedBody),
    % The story only claims the flip the trial made: the helping action is released.
    HelpOutcome == released(reduce(social_connection)),
    % The help restored belonging exactly to its set-point.
    memberchk(belonging-HelpedBelonging, HelpedBody),
    % Settled at the set-point, never past it.
    HelpedBelonging =:= 1,
    % The help left the temperature untouched.
    memberchk(temperature-HelpedTemperature, HelpedBody),
    % The other drive's variable is exactly where it stood.
    HelpedTemperature =:= 37.5,
    % The trial up to selection, exposing the candidates the drives proposed.
    empathy_trial_candidates(FullDistress, TrialDrives, TrialBody, Candidates, CandidateOutcome),
    % The released help appears among the candidates: proposed by the drives, never invented.
    action_selector_is_candidate(CandidateOutcome, Candidates),
    % A partial distress: level 0.4.
    empathy_modelled_distress(ana, 0.4, PartialDistress),
    % The trial over the social drive alone.
    empathy_trial(PartialDistress, [SocialDrive], [belonging-1], PartialOutcome, PartialBody),
    % The proportionate help was released.
    PartialOutcome == released(reduce(social_connection)),
    % Read where the help landed belonging.
    memberchk(belonging-LandedBelonging, PartialBody),
    % The story only claims the landing the capped step achieved: exactly at the set-point.
    LandedBelonging =:= 1,
    % Respiration in distress arbitrates against the released help.
    override_controller_arbitrate([override(respiration, 0, 0.9, breathe)], 0.5, released(reduce(social_connection)), BreathOutcome),
    % The story only claims the override the arbiter made: breath wins.
    BreathOutcome == released(breathe),
    % The story's fixed simulation start stamps the social records.
    capstone_demonstration_simulation_start(Start),
    % The modelled distress is owned on the record as a shareable fears attitude.
    empathy_distress_record("ana", Start, DistressRecord),
    % The attitude really is the standard's fears attitude.
    get_dict(attitude_type, DistressRecord, "fears"),
    % Read the attitude's content-addressed identifier.
    get_dict(id, DistressRecord, DistressIdentifier),
    % The mind's stance on its own attribution: observation grade, confidence 0.8.
    empathy_attribution_stance(DistressRecord, Start, AttributionStance),
    % The stance really carries the observation grade.
    get_dict(evidence_type, AttributionStance, "observation"),
    % Read the stance's content-addressed identifier.
    get_dict(id, AttributionStance, AttributionStanceIdentifier),
    % Ana turns out to be fine: the misattributed distress is withdrawn.
    empathy_attribution_retract(AttributionStance,
                                "the modelled distress was misattributed; the agent is well",
                                Start, AttributionRetraction),
    % The withdrawal really targets the stance.
    get_dict(retracts, AttributionRetraction, AttributionStanceIdentifier),
    % Read the withdrawal's content-addressed identifier.
    get_dict(id, AttributionRetraction, AttributionRetractionIdentifier),
    % The equivalence's line.
    format(string(EquivalenceLine),
           "A physical thwarting of one degree and a social severance of one unit read the same through the identical predicate: error ~w equals error ~w.",
           [PhysicalError, SocialError]),
    % The pain and relief line.
    format(string(PainLine),
           "One tick after the severance the unchanged machinery answers with reward ~w, broadcast as dopamine ~w - machine social pain; restored, it answers with reward ~w - machine relief.",
           [PainReward, PainLevel, ReliefReward]),
    % The calm trial's line.
    format(string(CalmLine),
           "With Ana fine, the mind tends its own mildly pressing temperature: ~w.",
           [CalmOutcome]),
    % The flip's line.
    format(string(FlipLine),
           "With Ana in full distress the selection flips and the helping action is released - ~w - proposed by the drives, never invented, restoring belonging to ~w.",
           [HelpOutcome, HelpedBelonging]),
    % The proportionate help's line.
    format(string(PartialLine),
           "A partial distress of 0.4 draws a proportionate help that lands belonging exactly at ~w - settled at the set-point, never past it.",
           [LandedBelonging]),
    % The override's line.
    format(string(BreathLine),
           "And breath still overrides kindness: with respiration in distress, the arbiter answers ~w.",
           [BreathOutcome]),
    % The record's line.
    format(string(RecordLine),
           "The social read is owned on the record: Ana FEARS her connection severed, minted as ~w, held at observation grade by assertion ~w.",
           [DistressIdentifier, AttributionStanceIdentifier]),
    % The honest exit's line.
    format(string(RetractionLine),
           "Ana turns out to be fine, so the misattributed distress is withdrawn: ~w - the honest exit, over a claim about another's heart.",
           [AttributionRetractionIdentifier]),
    % The deepening's lines in order.
    Lines = [
        "",
        "RUNG FOUR, DEEPENED - THE SOCIAL PAIN AND THE EMPATHY TRIAL",
        "A rejection is not a metaphor here: the social_connection drive defends a body variable called belonging at a set-point of 1, exactly as the temperature drive defends 37.",
        EquivalenceLine,
        PainLine,
        "Modelling Ana in full distress lowers the mind's OWN belonging - it feels worse because she does.",
        CalmLine,
        FlipLine,
        PartialLine,
        BreathLine,
        RecordLine,
        RetractionLine
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
        "Rung Three (concrete reasoning) and Rung Five (embodiment) are not yet demonstrated - nor are Rung Four's appraisal and regulation pilots - and this story does not claim them.",
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
