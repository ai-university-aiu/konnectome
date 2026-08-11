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
% Reuse the two-process governor: the boot world seats the night watchman the slice-37 tick requires,
% and from slice 51 the story also ASKS THAT WATCHMAN HOW ITS NIGHT WENT.
:- use_module(library(two_process_governor), [
    % two_process_governor_new/1: a fresh default governor, at midnight with no debt.
    two_process_governor_new/1,
    % two_process_governor_step/4: advance both processes one tick and select the operating state.
    two_process_governor_step/4,
    % two_process_governor_day_length/2: the governor's own day, in ticks, read from its own parameters.
    two_process_governor_day_length/2,
    % two_process_governor_watch_window/2: the window a watchdog measures this governor over (DECISION-6).
    two_process_governor_watch_window/2,
    % two_process_governor_watch/3: the join - a history of poles judged into a supervisor's report.
    two_process_governor_watch/3
]).
% Reuse the watchdog: the pack that turns a history of poles into readings, and that refuses to
% report a window the history does not yet span (DECISION-4).
:- use_module(library(watchdog), [
    % watchdog_history_new/1: an empty history, which has seen nothing and measures nothing.
    watchdog_history_new/1,
    % watchdog_observe/4: record what pole the governor stood in at one ordinal tick.
    watchdog_observe/4,
    % watchdog_history_span/2: how many ticks the history covers, first to last inclusive.
    watchdog_history_span/2,
    % watchdog_window_measured/2: whether the history yet spans a window of the asked-for length.
    watchdog_window_measured/2,
    % watchdog_flips_in_window/3: how many times the pole changed inside the trailing window.
    watchdog_flips_in_window/3,
    % watchdog_history_current/3: the newest tick and the pole standing at it.
    watchdog_history_current/3
]).
% Reuse the supervisor: the judge that keeps warnings, clean regimes and UNWATCHED ones apart.
:- use_module(library(supervisor), [
    % supervisor_report_warnings/2: the warnings a report carries.
    supervisor_report_warnings/2,
    % supervisor_report_unwatched/2: the fault regimes no watchdog reported on.
    supervisor_report_unwatched/2
]).
% Reuse thought combination: minting thoughts and combining them into a chain of thought.
:- use_module(library(thought_combination), [
    % thought_combination_atomic/3: mint one atomic thought as a content-addressed occurrent.
    thought_combination_atomic/3,
    % thought_combination_combine/3: combine causes and effects into a causal relation object.
    thought_combination_combine/3,
    % thought_combination_links/2: check that one combination's effect is the next one's cause.
    thought_combination_links/2,
    % thought_combination_id/2: read a causal record's content-addressed identifier.
    thought_combination_id/2
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
% Reuse the concrete operations: the reasoning rung's smoke inference and seriation trial.
:- use_module(library(concrete_operations), [
    % concrete_operations_above/4: derive that one object stands above another, every step shown.
    concrete_operations_above/4,
    % concrete_operations_seriate/3: order perceived objects along a numeric dimension.
    concrete_operations_seriate/3
]).
% Reuse cause and effect: the reasoning rung's causal discrimination and means-end planning.
:- use_module(library(cause_and_effect), [
    % cause_and_effect_discriminate/4: a genuine cause told from mere co-occurrence, by the record.
    cause_and_effect_discriminate/4,
    % cause_and_effect_plan/4: the shortest means-end plan, each step justified by its states.
    cause_and_effect_plan/4
]).
% Reuse category formation: the reasoning rung's categories formed from the mind's own experience.
:- use_module(library(category_formation), [
    % category_formation_learn/3: form categories from a stream of experiences.
    category_formation_learn/3,
    % category_formation_sort/3: sort objects into the mind's own formed categories.
    category_formation_sort/3,
    % category_formation_resort/3: the flexible re-sort by a different property on request.
    category_formation_resort/3
]).
% Reuse the quantity model: the reasoning rung's conservation verdict, read by re-measuring.
:- use_module(library(quantity_model), [
    % quantity_model_represent/3: represent an amount as individuated units plus an appearance.
    quantity_model_represent/3,
    % quantity_model_trial/4: one whole conservation trial - transform, then re-measure.
    quantity_model_trial/4,
    % quantity_model_record/4: own the verdict by enacting the trial.
    quantity_model_record/4
]).
% Reuse situation appraisal: Rung Four's appraisal pilot - good or bad for the mind's OWN goals.
:- use_module(library(situation_appraisal), [
    % situation_appraisal_appraise/3: appraise a situation against one drive's defended set-point.
    situation_appraisal_appraise/3,
    % situation_appraisal_appraise_change/4: appraise what a situation does to a goal.
    situation_appraisal_appraise_change/4,
    % situation_appraisal_record/4: own the appraisal as an attitude of the standard's enumeration.
    situation_appraisal_record/4,
    % situation_appraisal_stance/3: the mind's observation-graded stance on its own appraisal.
    situation_appraisal_stance/3,
    % situation_appraisal_retract/4: withdraw an appraisal the world proved wrong.
    situation_appraisal_retract/4
]).
% Reuse arousal regulation: Rung Four's regulation pilot - arousal brought back to baseline.
:- use_module(library(arousal_regulation), [
    % arousal_regulation_arouse/3: raise arousal - a norepinephrine level written onto the bus.
    arousal_regulation_arouse/3,
    % arousal_regulation_level/2: read the current arousal level off the bus.
    arousal_regulation_level/2,
    % arousal_regulation_step/2: one regulation tick - halve the remaining distance to baseline.
    arousal_regulation_step/2,
    % arousal_regulation_regulate/3: regulate until arousal settles exactly at baseline.
    arousal_regulation_regulate/3
]).
% Reuse the simulated body: the honestly-named stand-in machine the seam chapter tells through.
:- use_module(library(simulated_body), [
    % simulated_body_boot/1: boot the stand-in machine - camera clear, battery full, log empty.
    simulated_body_boot/1,
    % simulated_body_show/4: the world shows the camera something new.
    simulated_body_show/4,
    % simulated_body_actuators/2: read the movement log - the receipt that the body really moved.
    simulated_body_actuators/2,
    % simulated_body_drain/3: the physics tick that empties the battery.
    simulated_body_drain/3
]).
% Reuse the body interface: the three connections of Rung Five's groundwork, told and not claimed.
:- use_module(library(body_interface), [
    % body_interface_energy_drive/1: the drive that defends a full battery - low battery felt as hunger.
    body_interface_energy_drive/1,
    % body_interface_senses/2: the machine's sensors become the mind's senses.
    body_interface_senses/2,
    % body_interface_candidates/4: the pressing drives and the seen reflexes propose; nothing else does.
    body_interface_candidates/4,
    % body_interface_sense_act_step/7: one closed pass - sense, step, propose, select, command, enact.
    body_interface_sense_act_step/7,
    % body_interface_survival_run/5: the draining-battery run the mind survives of its own accord.
    body_interface_survival_run/5,
    % body_interface_record/4: own the loop's outcome by enacting the loop.
    body_interface_record/4,
    % body_interface_stance/3: the mind's observation-graded stance on its own enacted loop.
    body_interface_stance/3
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
% It is the Demonstration phase of the DSPARCD method made runnable: one deterministic story,
% told in rung order - the heartbeat and the regulated body (Rung Zero), the object-permanence
% forecast and its signed surprise (Rung One), a combined thought, the first grounded words and
% the pretend game under quarantine (Rung Two), the concrete reasoning with every step shown
% (Rung Three: the inference as data, seriation, categories the mind formed from its own
% experience, the conservation verdict read by re-measuring a represented model, cause told from
% co-occurrence by the record, and the shortest plan), the false belief attributed to another
% mind (Rung Four), the rung's deepening - the social pain and the empathy trial - the rung's
% finish - the appraisal of a situation against the mind's own goals, and arousal regulated back
% to baseline - and the provenance layer standing behind and, when the world disagrees, honestly
% disowning the mind's own stances. Between the finished Rung Four and the provenance layer the
% story now also tells Rung Five's GROUNDWORK - the body seam's three connections, the sense-act
% pass, the felt hunger, and the survival rhythm, all through the honestly-named simulated
% stand-in - while claiming, in the chapter's own words, that groundwork is not the rung.
% Since slice 34 the heartbeat's slow homeostatic bound runs LIVE in the told story: the boot
% world carries a slow scaling rate of 0.05 and a one-entry target geography giving the relay b
% its own activity mark of 0.8 above the diffuse 0.5, and the rung's closing lines tell the
% bound's work beside a rest twin - the same ticks re-lived at rate zero - so the difference is
% shown, never merely asserted.
% Since slice 51 Rung Zero also CLOSES: the story asks its own night watchman whether the night was
% healthy, which it had never done although the watchman, the watchdog and the wiring between them
% had all existed for six slices. The answer comes in two tellings, in the same twin idiom. The night
% the story actually told is reported NOT-YET-MEASURED, because ten heartbeat ticks do not span the
% governor's own day and a watchdog that cannot see a whole window will not call one clean; and then
% the same governor is lived out to a full day so the reader sees the verdict the watch gives when it
% has the history to give one, with the crossings it counted printed beside it.
% The story claims only what is shown: the rung not yet
% demonstrated is named as such, and the records are declared unsigned, because the signing key
% is a secret this code may never hold.

% capstone_demonstration_simulation_start(-Start): the fixed simulation start instant.
capstone_demonstration_simulation_start("2026-07-26T00:00:00Z").

% capstone_demonstration_default_ticks(-NumTicks): the default heartbeat length of the story.
capstone_demonstration_default_ticks(10).

% capstone_demonstration_world(-World): the boot world - a small body, one drive, one learnable interface.
capstone_demonstration_world(World) :-
    % The story's fixed simulation start stamps every minted record.
    capstone_demonstration_simulation_start(Start),
    % The default two-process governor watches the story's day: at one tick per hour its sixteen-point
    % sleep threshold stands far beyond the ten-tick heartbeat, so the whole told story runs online
    % and the slice-34 closing guards stand exactly as the capstone's live world pinned them.
    two_process_governor_new(Governor),
    % The world starts at tick zero with a too-warm body, one temperature drive defending
    % thirty-seven, an empty bus, a source construct feeding a relay through one learnable
    % transmissive interface, the learning body's trace and average stores at zero with the
    % slow scaling bound LIVE since slice 34 - the diffuse mark at one half, the relay b
    % defending its own mark of 0.8, and the slow rate at 0.05 - and the respiration
    % override armed but at rest.
    World = world{
        tick: 0,
        body: [temperature-40],
        drives: [drive(temperature, temperature, 37, none)],
        bus: [],
        constructs: [construct(a, source), construct(b, relay(1))],
        activations: [a-1, b-0],
        interfaces: [interface(a, b, 0.5, 1, transmissive)],
        traces: [(a-b)-0],
        averages: [a-0, b-0],
        fading_factor: 0.6,
        smoothing_factor: 0.2,
        scaling_target: 0.5,
        scaling_targets: [b-0.8],
        scaling_rate: 0.05,
        overrides: [override(respiration, 0, 0.0, breathe)],
        override_threshold: 0.5,
        learning_rate: 0.1,
        % The day's memory store starts empty; every online tick remembers its pattern (slice 38).
        memories: [],
        % The night's replay strengthening rate.
        replay_rate: 0.1,
        % The night's raised scaling bound, at or above the day's rate as the tick demands.
        offline_scaling_rate: 0.1,
        governor: Governor,
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
    % Rung Zero, closed: the night watchman is asked how the night went, and answers honestly.
    capstone_demonstration_night_watch_lines(NumTicks, World0, NightWatch),
    % Rung One: the object-permanence forecast, confirmed and surprised.
    capstone_demonstration_prediction_lines(Prediction),
    % The combined thought: a chain of thought as content-addressed records.
    capstone_demonstration_thought_lines(Thought),
    % Rung Two: the first grounded words, and the pretend game under quarantine.
    capstone_demonstration_first_words_lines(FirstWords),
    % Rung Three: the concrete reasoning, every step shown.
    capstone_demonstration_reasoning_lines(Reasoning),
    % Rung Four: the false belief attributed to another mind, exported as an attitude record.
    capstone_demonstration_social_lines(AttitudeRecord, Social),
    % Rung Four, deepened: the social pain and the empathy trial.
    capstone_demonstration_empathy_lines(Empathy),
    % Rung Four, finished: the appraisal and the regulation.
    capstone_demonstration_feeling_lines(Feeling),
    % Rung Five's groundwork: the body seam told through the honestly-named stand-in, the rung not claimed.
    capstone_demonstration_body_seam_lines(BodySeam),
    % The provenance layer: the mind grades, supersedes, and retracts its own stances.
    capstone_demonstration_provenance_lines(AttitudeRecord, Provenance),
    % The honest limits: what this story does not claim.
    capstone_demonstration_epilogue_lines(Epilogue),
    % The story is the sections joined in rung order.
    append([Title, Heartbeat, NightWatch, Prediction, Thought, FirstWords, Reasoning, Social, Empathy, Feeling, BodySeam, Provenance, Epilogue], Story).

% capstone_demonstration_check_ticks(+NumTicks): the tick count must be an integer of at least six.
% An unbound count cannot be judged, and must never be refused under a wrong it cannot name
% (the slice-34 review's root: the same var guard slice 33 laid in the numeric-constant checks).
capstone_demonstration_check_ticks(NumTicks) :-
    % The unbound count is refused as uninstantiated - the house answer to a hole where a value should be.
    var(NumTicks),
    % Refuse it aloud before any judgement pretends to name it.
    throw(error(instantiation_error, context(capstone_demonstration_story/2, "the tick count is unbound"))).
% A bound count is judged on its own value.
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

% ---------------------------------------------------------------------------
% THE NIGHT WATCH (konnectome build slice 51)
% ---------------------------------------------------------------------------
%
% THE DEMONSTRATION DEBT THIS CLOSES, IN ONE SENTENCE: konnectome has had a watchman since slice 37,
% a watchdog since slice 45 and a governor wired to it since slice 47, and its own told story could
% not say whether its night was healthy. The machinery was all built. Nobody had called it.
%
% AND THE FIRST THING THE STORY LEARNED BY CALLING IT IS THAT IT CANNOT ANSWER, WHICH IS THE POINT.
% The capstone's heartbeat is ten ticks. The governor's day - read from the governor's own parameters
% under DECISION-6, never written here as a number - is longer than that. A watchdog whose history
% does not span its window reports NOT-YET-MEASURED and never reports CLEAN, which is DECISION-4, and
% it is the whole reason this section is worth having: a story that ran ten ticks and printed "the
% night was healthy" would have been telling a reader something it had no way to know.
%
% SO THE SECTION TELLS BOTH, IN THE REST-TWIN IDIOM THIS CAPSTONE ALREADY USES FOR THE SLOW BOUND.
% First the honest verdict on the night the story actually lived, which is that it is unmeasured and
% why. Then the same governor DELIBERATELY LIVED OUT TO A FULL DAY, so the reader sees the verdict the
% watch gives when it has enough history to give one. Lengthening the telling is the change Part Six
% asked for; shortening the window to make the short story answerable was the alternative and it is
% exactly the thing DECISION-4 exists to forbid.
%
% THE NIGHT LIVED HERE IS THE STORY'S OWN NIGHT AND NOT A FIXTURE. The governor stepped below is the
% one the boot world seats, advanced by the same two_process_governor_step/4 the cognitive cycle
% advances it with, from the same starting pole. A separately-parameterised governor would have been
% easier to write and would have demonstrated nothing about this mind.

% capstone_demonstration_governor_history(+Governor0, +State0, +Tick, +NumTicks, +History0, -Governor,
% -History): live the governor forward, recording the pole it stood in at each ordinal tick.
% An exhausted count leaves the governor and the history where they stand.
capstone_demonstration_governor_history(Governor, _State, Tick, NumTicks, History, Governor, History) :-
    % The walk stops the moment it has lived every tick it was asked for.
    Tick > NumTicks,
    % Committing here rather than falling through keeps the recursion from re-entering at the end.
    !.
% Each remaining tick advances both processes, selects a pole, and records it under its ordinal.
capstone_demonstration_governor_history(Governor0, State0, Tick, NumTicks, History0, Governor, History) :-
    % Advance the whole scheduler exactly as the cognitive cycle advances it.
    two_process_governor_step(Governor0, State0, Governor1, State1),
    % Record the pole the governor stands in at this ordinal tick; the watchdog refuses a tick that
    % does not run strictly forwards, so this walk cannot silently double-count or rewrite a tick.
    watchdog_observe(History0, Tick, State1, History1),
    % Live the next tick.
    NextTick is Tick + 1,
    capstone_demonstration_governor_history(Governor1, State1, NextTick, NumTicks, History1, Governor, History).

% capstone_demonstration_night_verdict_lines(+History, +Window, +Governor, -Lines): the watch's own
% words about one stretch of night, whichever way the verdict falls.
capstone_demonstration_night_verdict_lines(History, Window, Governor, Lines) :-
    % How much night this history actually covers.
    watchdog_history_span(History, Span),
    % Ask the watchman. The report keeps warnings, clean regimes and unwatched ones apart, and an
    % unspanned window yields no readings at all, so BOTH regimes come back unwatched.
    two_process_governor_watch(Governor, History, Report),
    % The warnings the report carries, if any.
    supervisor_report_warnings(Report, Warnings),
    % The regimes no watchdog reported on.
    supervisor_report_unwatched(Report, Unwatched),
    % Tell the verdict in the shape the watch gave it, never in a shape the story preferred.
    (   watchdog_window_measured(History, Window)
    ->  % The history reaches all the way back across the window, so a verdict is available.
        (   Warnings == []
        ->  format(string(VerdictLine),
                   "VERDICT: the night was healthy. Over ~w ticks of history against a ~w-tick window, the watchman raised no warning: the switch neither chattered nor locked.",
                   [Span, Window])
        ;   format(string(VerdictLine),
                   "VERDICT: the night was NOT healthy. Over ~w ticks of history against a ~w-tick window, the watchman raised: ~w.",
                   [Span, Window, Warnings])
        ),
        % Name what remains unwatched even in a measured window, rather than letting silence imply none.
        format(string(UnwatchedLine),
               "Fault regimes still unwatched in this telling: ~w.", [Unwatched])
    ;   % The history is shorter than the window, so DECISION-4 forbids a clean verdict.
        format(string(VerdictLine),
               "VERDICT: NOT YET MEASURED. The history spans ~w ticks and the window is the governor's own ~w-tick day, so the watchman has not seen a whole day and will not call one clean.",
               [Span, Window]),
        % And it names both regimes as unwatched rather than reporting nothing at all.
        format(string(UnwatchedLine),
               "Both fault regimes come back unwatched, by name: ~w. An unspanned window yields no readings, and no readings is not the same fact as no faults.",
               [Unwatched])
    ),
    % SHOW THE READINGS THE VERDICT WAS MADE FROM, so "healthy" is a thing a reader can check rather
    % than a thing this story asserts. The two quantities the watchman actually judged are the number
    % of crossings inside the window and the pole the switch ended on.
    watchdog_flips_in_window(History, Window, Flips),
    watchdog_history_current(History, LastTick, LastPole),
    format(string(ReadingLine),
           "The readings behind that verdict: ~w crossing(s) of the sleep-wake switch inside the window, and at tick ~w the switch stands ~w.",
           [Flips, LastTick, LastPole]),
    % The three lines, in the order a reader wants them.
    Lines = [VerdictLine, ReadingLine, UnwatchedLine].

% capstone_demonstration_night_watch_lines(+NumTicks, +World0, -Lines): Rung Zero's night, watched.
capstone_demonstration_night_watch_lines(NumTicks, World0, Lines) :-
    % Read the story's own night watchman out of the boot world.
    get_dict(governor, World0, Governor),
    % Read the window this governor is measured over - its own day, from its own parameters. This is
    % DECISION-6 and it is why no number appears in this section's source.
    two_process_governor_watch_window(Governor, Window),
    % Read the same day again under its plain name, so the prose and the window cannot disagree.
    two_process_governor_day_length(Governor, DayLength),
    % An empty history, which has seen nothing and measures nothing.
    watchdog_history_new(Empty),
    % LIVE THE NIGHT THE STORY ACTUALLY TOLD: the boot governor, from the waking pole the bus starts
    % at, for exactly the heartbeat the reader just watched.
    capstone_demonstration_governor_history(Governor, online, 1, NumTicks, Empty, _ToldGovernor, ToldHistory),
    % The watch's verdict on it.
    capstone_demonstration_night_verdict_lines(ToldHistory, Window, Governor, ToldVerdict),
    % AND LIVE IT OUT TO A WHOLE DAY, deliberately, so the reader also sees a verdict the watch can
    % actually give. The length is the governor's day and not a number chosen to make this work.
    capstone_demonstration_governor_history(Governor, online, 1, DayLength, Empty, _FullGovernor, FullHistory),
    % The watch's verdict on that.
    capstone_demonstration_night_verdict_lines(FullHistory, Window, Governor, FullVerdict),
    % The heading and the two tellings.
    format(string(WindowLine),
           "The watchman's window is not a constant: it is this governor's own day, ~w ticks, read from the governor's own parameters.",
           [Window]),
    format(string(ToldLine),
           "FIRST, THE NIGHT THIS STORY TOLD - the ~w heartbeat ticks above, asked of the watchman.",
           [NumTicks]),
    format(string(FullLine),
           "SECOND, THE SAME GOVERNOR LIVED OUT TO A WHOLE DAY - ~w ticks, so the window is spanned and the watchman can answer.",
           [DayLength]),
    % Assemble the section.
    append([["",
             "RUNG ZERO, CLOSED: WAS THE NIGHT HEALTHY?",
             "The mind has had a night watchman since the tick learned to sleep, and a watchdog to judge it. Until now this story never asked either one.",
             WindowLine,
             "",
             ToldLine],
            ToldVerdict,
            ["",
             FullLine],
            FullVerdict],
           Lines).

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
    % Boot the rest twin: the same world with the bound at rest - rate zero, no geography.
    capstone_demonstration_world(BootWorld),
    % Put the bound to rest and drop the geography, leaving everything else exactly as booted.
    put_dict(_{scaling_rate: 0.0, scaling_targets: []}, BootWorld, RestWorld),
    % Live the same ticks with the bound at rest, so the difference is the bound's alone.
    cognitive_cycle_run(RestWorld, NumTicks, RestFinal, _RestSummaries),
    % Read the rest twin's final weight.
    get_dict(interfaces, RestFinal, [interface(a, b, RestWeight, _, _)]),
    % The story only claims the pull the twin runs really show: the live weight stands above the rest one.
    Weight > RestWeight,
    % The body's closing line.
    format(string(BodyLine),
           "After ~w ticks the body's temperature stands at ~w - the set-point the drive defends.",
           [NumTicks, Temperature]),
    % The learning's closing line: the fast rule beneath, the slow bound above.
    format(string(WeightLine),
           "The interface from a to b now carries weight ~w - grown from 0.5 by the three-factor rule, then pulled further by the live bound toward the mark b's own territory defends.",
           [Weight]),
    % The twin's closing line: the bound's work shown by the difference, never merely asserted.
    format(string(TwinLine),
           "Told again with the bound at rest - rate zero, no geography - the same ~w ticks land the weight at ~w: the difference is the bound's own work, checkable by re-running both worlds.",
           [NumTicks, RestWeight]),
    % The rung's header, boot lines, tick lines, and closing lines in order.
    append([
        [
            "",
            "RUNG ZERO - THE HEARTBEAT AND THE REGULATED BODY",
            "The mind boots with its body too warm: temperature 40 against a defended set-point of 37.",
            "One drive watches that variable; a source construct feeds a relay through one learnable interface of weight 0.5.",
            "The slow homeostatic bound runs LIVE: the world's diffuse activity mark is 0.5, the relay b defends its own mark of 0.8, and each tick scales b's incoming weight toward that mark at the slow rate 0.05.",
            "The respiration override stands armed at rest (distress 0.0, threshold 0.5): safety is wired in, and today it never needs to seize control."
        ],
        TickLines,
        [BodyLine, WeightLine, TwinLine]
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

% capstone_demonstration_reasoning_lines(-Lines): Rung Three narrated - the concrete reasoning, every step shown.
capstone_demonstration_reasoning_lines(Lines) :-
    % The smoke inference: the block on the cup on the table, derived with every step returned as data.
    concrete_operations_above([on(block, cup), on(cup, table)], block, table, Steps),
    % The story only claims the derivation the engine returned: three named steps, nothing hidden.
    Steps == [step(resting_is_above, [on(block, cup)], above(block, cup)),
              step(resting_is_above, [on(cup, table)], above(cup, table)),
              step(transitive_chain, [above(block, cup), above(cup, table)], above(block, table))],
    % Seriation: three objects ordered along their size dimension.
    concrete_operations_seriate([object(pea, [size-1]), object(apple, [size-3]), object(brick, [size-6])],
                                size, Ordered),
    % The story only claims the order the trial produced.
    Ordered == [pea, apple, brick],
    % The mind's experiences: two red round fruits, a blue round toy, a blue square toy.
    Experiences = [
        experience(apple, [color-red, kind-fruit, shape-round]),
        experience(cherry, [color-red, kind-fruit, shape-round]),
        experience(ball, [color-blue, kind-toy, shape-round]),
        experience(block, [color-blue, kind-toy, shape-square])
    ],
    % The mind forms its own categories from that experience.
    category_formation_learn(Experiences, 2, Categories),
    % The story only claims the categories the mind formed: two, with their defining cores.
    Categories == [category(formed_category_1, [color-red, kind-fruit, shape-round], [apple, cherry]),
                   category(formed_category_2, [color-blue, kind-toy], [ball, block])],
    % A newcomer that fits nothing is sorted honestly outside every category.
    category_formation_sort([experience(pencil, [color-yellow, kind-tool, shape-long])], Categories, SortGroups),
    % The story only claims the honest exile the sorter reported.
    SortGroups == [group(formed_category_1, []), group(formed_category_2, []),
                   group(outside_every_category, [pencil])],
    % The flexible re-sort on request: the same four objects, by shape instead.
    category_formation_resort(Experiences, shape, ResortGroups),
    % The story only claims the crossing partition the re-sort produced: a fruit and a toy share a group.
    ResortGroups == [group(round, [apple, cherry, ball]), group(square, [block])],
    % The book's own conservation trial: five units of water in a short wide glass.
    quantity_model_represent(5, glass(short_wide), Water),
    % Poured into a taller, thinner glass - and the verdict is read by re-measuring the model.
    quantity_model_trial(Water, pour(glass(tall_thin)), PourVerdict, _Poured),
    % The story only claims the measurement: the same five units on both sides of the pour.
    PourVerdict == conserved(5),
    % The lossy pour: named like a pour, but it spills one unit on the way.
    quantity_model_trial(Water, pour_losing(glass(tall_thin), 1), LossyVerdict, _Spilt),
    % The story only claims what the model counted: five before, four after - the name lied, the model did not.
    LossyVerdict == changed(5, 4),
    % The story's fixed simulation start stamps the verdict's record.
    capstone_demonstration_simulation_start(Start),
    % The conservation verdict is owned by enacting the trial - the record predicate runs the pour itself.
    quantity_model_record(Water, pour(glass(tall_thin)), Start, VerdictRecord),
    % Read the owned verdict's content-addressed identifier.
    get_dict(id, VerdictRecord, VerdictIdentifier),
    % The causal trial's two events, minted as content-addressed thoughts.
    thought_combination_atomic("the_sun_shines", "event", Sun),
    % The stone warming, minted the same way.
    thought_combination_atomic("the_stone_warms", "event", Stone),
    % The genuine causal record: the shining causes the warming.
    thought_combination_combine([Sun], [Stone], CausalRecord),
    % Read the causal record's identifier - the evidence the discrimination will cite.
    thought_combination_id(CausalRecord, CausalIdentifier),
    % Cause or co-occurrence? Answered by the record.
    cause_and_effect_discriminate([CausalRecord], Sun, Stone, CauseFinding),
    % The story only claims the finding and its cited evidence.
    CauseFinding == genuine_cause([CausalIdentifier]),
    % The rooster and the sunrise: two events with no record between them.
    thought_combination_atomic("the_rooster_crows", "event", Rooster),
    % The sun rising, minted the same way.
    thought_combination_atomic("the_sun_rises", "event", Sunrise),
    % The same question, over the same evidence store, with no linking record.
    cause_and_effect_discriminate([CausalRecord], Rooster, Sunrise, CoincidenceFinding),
    % The story only claims the honest answer: co-occurrence only.
    CoincidenceFinding == co_occurrence_only,
    % The planning trial: a bare camp, a fed goal, three known actions.
    cause_and_effect_plan([action(gather_wood, bare, stocked),
                           action(light_the_fire, stocked, warm),
                           action(cook_the_meal, warm, fed)], bare, fed, Plan),
    % The story only claims the shortest plan the search found, each step justified by its states.
    Plan == [step(apply_action, gather_wood, from(bare), to(stocked)),
             step(apply_action, light_the_fire, from(stocked), to(warm)),
             step(apply_action, cook_the_meal, from(warm), to(fed))],
    % The owned verdict's line.
    format(string(VerdictLine),
           "The conserved verdict is owned by ENACTING the pour - the record predicate runs the trial itself and mints ~w; a hand-written verdict cannot be owned at all.",
           [VerdictIdentifier]),
    % The causal evidence's line.
    format(string(CauseLine),
           "The sun shines and the stone warms, and a causal record links them: genuine cause, evidence ~w. The rooster crows and the sun rises, with no record between them: co-occurrence only.",
           [CausalIdentifier]),
    % The rung's lines in order.
    Lines = [
        "",
        "RUNG THREE - THE CONCRETE REASONING, EVERY STEP SHOWN",
        "The block rests on the cup and the cup rests on the table, so the block stands above the table - and the derivation itself comes back as data:",
        "  step resting_is_above consumes on(block, cup) and produces above(block, cup);",
        "  step resting_is_above consumes on(cup, table) and produces above(cup, table);",
        "  step transitive_chain joins the two and produces above(block, table). Nothing hidden between premise and conclusion.",
        "A pea, an apple, and a brick seriate by size: pea, apple, brick.",
        "Four experiences - two red round fruits, a blue round toy, a blue square toy - and the mind FORMS its own two categories: formed_category_1 (red, fruit, round: apple, cherry) and formed_category_2 (blue, toy: ball, block). Nobody handed them down.",
        "A yellow pencil fits neither and is reported outside_every_category - never forced into the nearest group.",
        "Re-sorted by shape on request, the same objects cross their own categories: round holds a fruit and a toy together - flexible categorisation, on demand.",
        "Five units of water pour from a short wide glass into a tall thin one: conserved(5) - not because pour is on a safe list, but because the model re-counts the same five units on both sides.",
        "A lossy pour - named like a pour, spilling one unit - is judged changed(5, 4): the name said appearance-only, the world said otherwise, and the mind sided with the world.",
        VerdictLine,
        CauseLine,
        "And from a bare camp to a fed one, the shortest plan chains gather_wood, light_the_fire, cook_the_meal - each step justified by the state it leaves and the state it reaches."
    ].

% capstone_demonstration_feeling_lines(-Lines): Rung Four finished - the appraisal and the regulation.
capstone_demonstration_feeling_lines(Lines) :-
    % The one temperature drive the whole story has defended.
    Drive = drive(temperature, temperature, 37, none),
    % The too-warm boot body, appraised against the mind's own goal.
    situation_appraisal_appraise(Drive, [temperature-40], HotAppraisal),
    % The story only claims the appraisal the drives' own error produced: threatened, at distance three.
    HotAppraisal == appraisal(threatened, 3),
    % The regulated body, appraised the same way.
    situation_appraisal_appraise(Drive, [temperature-37], SettledAppraisal),
    % The story only claims the satisfaction the numbers show: at the set-point, error zero.
    SettledAppraisal == appraisal(satisfied, 0),
    % A situation that cools the body from forty to thirty-eight, appraised as a change.
    situation_appraisal_appraise_change(Drive, [temperature-40], [temperature-38], CoolingAppraisal),
    % The story only claims the good turn the error drop shows: two degrees closer to the goal.
    CoolingAppraisal == appraisal(good, 2),
    % A situation that heats the settled body to thirty-nine, appraised as a change.
    situation_appraisal_appraise_change(Drive, [temperature-37], [temperature-39], HeatingAppraisal),
    % The story only claims the bad turn the error rise shows.
    HeatingAppraisal == appraisal(bad, 2),
    % The story's fixed simulation start stamps the appraisal records.
    capstone_demonstration_simulation_start(Start),
    % The threat is owned on the record as the standard's own fears attitude.
    situation_appraisal_record("the_body_stands_three_degrees_too_warm", threatened, Start, ThreatRecord),
    % The attitude really is fears.
    get_dict(attitude_type, ThreatRecord, "fears"),
    % Read the threat attitude's content-addressed identifier.
    get_dict(id, ThreatRecord, ThreatIdentifier),
    % The satisfaction is owned too - as a desire to keep the met goal, the enumeration's nearest home.
    situation_appraisal_record("the_body_rests_at_its_set_point", satisfied, Start, SatisfiedRecord),
    % The attitude really is desires - the closed enumeration has no word for satisfaction.
    get_dict(attitude_type, SatisfiedRecord, "desires"),
    % The mind's stance on its own threat appraisal: observation grade - it read its own true error.
    situation_appraisal_stance(ThreatRecord, Start, ThreatStance),
    % The stance really carries the observation grade.
    get_dict(evidence_type, ThreatStance, "observation"),
    % Read the stance's content-addressed identifier.
    get_dict(id, ThreatStance, ThreatStanceIdentifier),
    % The world cools on its own: the appraised threat is withdrawn - the honest exit, again.
    situation_appraisal_retract(ThreatStance, "the body cooled to its set-point; the threat passed", Start, ThreatRetraction),
    % The withdrawal really targets the stance.
    get_dict(retracts, ThreatRetraction, ThreatStanceIdentifier),
    % Read the withdrawal's content-addressed identifier.
    get_dict(id, ThreatRetraction, ThreatRetractionIdentifier),
    % An alarm: arousal raised to one - norepinephrine on the same shared bus dopamine rides.
    arousal_regulation_arouse([], 1.0, ArousedBus),
    % The story only claims the level the bus carries.
    arousal_regulation_level(ArousedBus, ArousedLevel),
    % Aroused fully.
    ArousedLevel =:= 1.0,
    % One regulation tick: halve the remaining distance to baseline.
    arousal_regulation_step(ArousedBus, CalmerBus),
    % Read the level after one tick.
    arousal_regulation_level(CalmerBus, CalmerLevel),
    % The story only claims the halving the step performed.
    CalmerLevel =:= 0.5,
    % Regulate to rest: tick until arousal settles exactly at baseline, counting the ticks.
    arousal_regulation_regulate(ArousedBus, RestedBus, SettleTicks),
    % Read the settled level.
    arousal_regulation_level(RestedBus, RestedLevel),
    % The story only claims the exact landing: baseline, never overshot.
    RestedLevel =:= 0.0,
    % Eight ticks bring a full alarm to rest.
    SettleTicks =:= 8,
    % The threat record's line.
    format(string(ThreatLine),
           "The too-warm boot body appraises as threatened at distance 3, owned as the standard's FEARS attitude: ~w, held at observation grade by ~w.",
           [ThreatIdentifier, ThreatStanceIdentifier]),
    % The honest-exit line.
    format(string(RetractionLine),
           "The body cools on its own, so the appraised threat is withdrawn: ~w - the same honest exit every mistaken stance takes.",
           [ThreatRetractionIdentifier]),
    % The regulation line.
    format(string(RegulationLine),
           "An alarm raises arousal to ~w - norepinephrine on the same shared bus dopamine rides. One tick later it stands at ~w, each tick halving the remaining distance, and after ~w ticks it rests EXACTLY at baseline 0.0 - settled, never overshot.",
           [ArousedLevel, CalmerLevel, SettleTicks]),
    % The rung's lines in order.
    Lines = [
        "",
        "RUNG FOUR, FINISHED - THE APPRAISAL AND THE REGULATION",
        "An appraisal here is nothing but the drives' own set-point error, read as good or bad for the mind's OWN goals.",
        ThreatLine,
        "The settled body appraises as satisfied - owned as a DESIRE to keep the met goal, because the standard's closed attitude enumeration has no word for satisfaction; the approximation is recorded, not hidden (ledger Observation-4).",
        "A situation that cools the body two degrees appraises as good(2); one that heats it two degrees appraises as bad(2) - the same predicate, both directions, no special cases.",
        RetractionLine,
        RegulationLine
    ].

% capstone_demonstration_body_seam_lines(-Lines): Rung Five's groundwork narrated - the body seam
% told through the honestly-named simulated stand-in, guard-then-tell, and the rung NOT claimed:
% every sentence below sits beneath a strict live check, and the chapter's own words keep the
% rung on the honest-limits list, because the guiding book's text asks for a real machine.
capstone_demonstration_body_seam_lines(Lines) :-
    % Boot the stand-in machine: camera clear, battery full, log empty.
    simulated_body_boot(Booted),
    % The world shows the camera an obstacle in the path ahead.
    simulated_body_show(Booted, path_ahead, obstacle, Seen),
    % The machine's sensors become the mind's senses.
    body_interface_senses(Seen, Percepts),
    % The story only claims the percept the camera carried, unchanged.
    Percepts == [percept(path_ahead, obstacle)],
    % The energy drive that defends a full battery.
    body_interface_energy_drive(EnergyDrive),
    % One closed pass of the loop over the seen obstacle, battery full.
    body_interface_sense_act_step(Seen, [EnergyDrive], [], Steered, _DrivesAfter, _BusAfter, SteerOutcome),
    % The story only claims the release the selector made: the steering reflex.
    SteerOutcome == released(steer_around),
    % Read the actuator log - the receipt that the body really moved.
    simulated_body_actuators(Steered, SteerLog),
    % The story only claims the movement the log carries.
    SteerLog == [steer_around],
    % Sense again through the moved body.
    body_interface_senses(Steered, PerceptsAfter),
    % The story only claims what the camera now reads: the path is clear - acting changed the seeing.
    PerceptsAfter == [percept(path_ahead, clear)],
    % A battery at half charge, read through the one error predicate every pain passes through.
    drive_system_error(EnergyDrive, [battery_charge-0.5], HungerError),
    % The story only claims the pressing magnitude the engine feels: exactly one half.
    HungerError =:= 0.5,
    % A battery at three-quarter charge, read through the same predicate - the mild hunger.
    drive_system_error(EnergyDrive, [battery_charge-0.75], MildHungerError),
    % The story only claims the mild magnitude the engine feels: exactly one quarter.
    MildHungerError =:= 0.25,
    % A body half a degree from its defended thirty-seven, read through the identical predicate.
    drive_system_error(drive(temperature, temperature, 37, none), [temperature-36.5], ThermalError),
    % The story only claims the equivalence the numbers show: the two readings are equal.
    HungerError =:= ThermalError,
    % The survival groundwork: six ticks of draining life over the booted machine.
    simulated_body_boot(SurvivalStart),
    % Live the run - each tick drains a quarter charge, and the mind answers of its own accord.
    body_interface_survival_run(SurvivalStart, [EnergyDrive], 6, Trace, _SurvivalFinal),
    % The story only claims the exact rhythm the run produced: hold at mild hunger, recharge at pressing.
    Trace == [tick(1, 0.75, nothing, 0.75),
              tick(2, 0.5, released(reduce(energy)), 1.0),
              tick(3, 0.75, nothing, 0.75),
              tick(4, 0.5, released(reduce(energy)), 1.0),
              tick(5, 0.75, nothing, 0.75),
              tick(6, 0.5, released(reduce(energy)), 1.0)],
    % The one deliberate tie: a starving battery against a seen obstacle at equal salience.
    simulated_body_drain(Booted, 1.0, Starving),
    % The world shows the starving machine the same obstacle.
    simulated_body_show(Starving, path_ahead, obstacle, StarvingAndBlocked),
    % Read the starving drive's own error - the drive side of the claimed tie.
    drive_system_error(EnergyDrive, [battery_charge-0.0], StarvingError),
    % Read the reflex's live salience through the public candidate interface: no drives, one obstacle.
    body_interface_candidates([percept(path_ahead, obstacle)], [], [], ReflexCandidates),
    % The reflex proposal alone stands, carrying its fixed salience.
    ReflexCandidates = [action(steer_around, ReflexSalience)],
    % The story only claims a tie that is exact: the starving error equals the reflex salience.
    StarvingError =:= ReflexSalience,
    % One closed pass over the starving, blocked machine.
    body_interface_sense_act_step(StarvingAndBlocked, [EnergyDrive], [], _TieBody, _TieDrives, _TieBus, TieOutcome),
    % The story only claims the tie-break the selector made: the drives come before the reflexes.
    TieOutcome == released(reduce(energy)),
    % The record's episode: the booted machine drained to a pressing half charge.
    simulated_body_drain(Booted, 0.5, HalfCharged),
    % The story's fixed simulation start stamps the seam's records.
    capstone_demonstration_simulation_start(Start),
    % The loop's outcome is owned BY ENACTING THE LOOP - the record predicate runs the pass itself.
    body_interface_record(HalfCharged, [EnergyDrive], Start, LoopRecord),
    % Read what the enacted pass released, straight from the record's own content.
    get_dict(value, LoopRecord, LoopValue),
    % The story only claims the release the enacted pass made: the recharge.
    LoopValue == "released(reduce(energy))",
    % Read the loop record's content-addressed identifier.
    get_dict(id, LoopRecord, LoopIdentifier),
    % The mind's stance on its own enacted loop - granted only after the record proves it was minted.
    body_interface_stance(LoopRecord, Start, LoopStance),
    % The stance really carries the observation grade: the mind ran the loop and read the log.
    get_dict(evidence_type, LoopStance, "observation"),
    % Read the stance's content-addressed identifier.
    get_dict(id, LoopStance, LoopStanceIdentifier),
    % The live forgery probe: a hand-built look-alike, never enacted, offered for the same grade.
    catch(body_interface_stance(_{id: "forged_look_alike"}, Start, _ForgedStance),
          error(body_interface_unminted_record(_), _),
          ForgeryRefused = true),
    % The story only claims the refusal that really fired: the forgery earns no grade.
    ForgeryRefused == true,
    % The hunger equivalence's line.
    format(string(HungerLine),
           "A battery at half charge and a body half a degree from thirty-seven read the same through the identical predicate: error ~w equals error ~w - a low battery is FELT AS HUNGER by the same drive_system_error every other pain passes through.",
           [HungerError, ThermalError]),
    % The record's line.
    format(string(RecordLine),
           "The loop's outcome is owned BY ENACTING THE LOOP - the record predicate runs the pass itself and mints ~w, its content the enacted release ~w.",
           [LoopIdentifier, LoopValue]),
    % The stance's line.
    format(string(StanceLine),
           "The mind stands behind its enacted loop at observation grade - it ran the pass and read its own actuator log - as ~w, and only a record that PROVES it was genuinely minted can earn that grade.",
           [LoopStanceIdentifier]),
    % The chapter's lines in order.
    Lines = [
        "",
        "THE BODY SEAM - RUNG FIVE'S GROUNDWORK, TOLD AND NOT CLAIMED",
        "There is no real machine here, and this chapter does not pretend one: the guiding book closes the sense-act loop through a real machine, so embodiment stays on the honest-limits list below.",
        "What can be told honestly is the seam - the book's three connections, built and tested through the honestly-named simulated stand-in a real robot would one day replace.",
        "Shown an obstacle, the machine's camera becomes the mind's senses unchanged: percept(path_ahead, obstacle).",
        "One closed pass runs sense, drive step, proposal, selection, command, enactment: the steering reflex is released - released(steer_around) - the actuator log carries the movement, and the camera reads clear again: acting changed what the machine will see next.",
        HungerLine,
        "Left alone with a battery draining a quarter charge per tick, the mind holds still at a mild hunger of 0.25 and recharges OF ITS OWN ACCORD at the pressing 0.5 - hold at 0.75, recharge to full, and the same two-tick rhythm again and again, with nothing outside the mind commanding the act.",
        "At an exact salience tie a starving battery outranks a seen obstacle - released(reduce(energy)) - because the drives come before the reflexes, deliberately and deterministically.",
        RecordLine,
        StanceLine,
        "All of this is groundwork: the seam is built, tested, and told - and the rung is NOT claimed. Reaching, navigation, and true survival wait for a machine that is real."
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
        "Rung Five (embodiment) is not yet demonstrated - the guiding book's own text asks for a real machine - and this story does not claim it.",
        "The body-seam chapter above is that rung's GROUNDWORK - three connections tested through an honestly-named simulated stand-in - and groundwork is not the rung: this story does not promote it.",
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
