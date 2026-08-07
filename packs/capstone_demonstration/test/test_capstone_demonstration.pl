% Load the capstone_demonstration module under test from the library path.
:- use_module(library(capstone_demonstration)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).
% Reuse cognitive_cycle so the dynamics the story narrates can be checked independently of the narration.
:- use_module(library(cognitive_cycle), [
    % cognitive_cycle_run/4: run the whole mind for many ticks, for the independent dynamics checks.
    cognitive_cycle_run/4
]).
% Reuse other_minds so the story's minted attitude identifier can be reproduced independently.
:- use_module(library(other_minds), [
    % other_minds_reset/0: clear the theory-of-mind runtime before the reproduction fixture.
    other_minds_reset/0,
    % other_minds_world_fact_add/1: record konnectome's own world fact for the reproduction fixture.
    other_minds_world_fact_add/1,
    % other_minds_belief_attribute/2: attribute the false belief for the reproduction fixture.
    other_minds_belief_attribute/2,
    % other_minds_search_prediction_export/5: re-mint the same attitude record the story minted.
    other_minds_search_prediction_export/5
]).
% Reuse symbol_exchange so the story's grounded words and drive-coloured replies can be checked independently.
:- use_module(library(symbol_exchange), [
    % symbol_exchange_vocabulary/3: live the run and ground the standard two-word vocabulary.
    symbol_exchange_vocabulary/3,
    % symbol_exchange_reply/5: the pilot - the reply coloured by the mind's own drive state.
    symbol_exchange_reply/5
]).
% Reuse pretend_play so the quarantine the story narrates can be re-proven outside the narration.
:- use_module(library(category_formation), [
    % category_formation_learn/3: re-form the chapter's categories independently of the narration.
    category_formation_learn/3
]).
% Load the quantity model so the conservation verdicts can be re-measured independently.
:- use_module(library(quantity_model), [
    % quantity_model_represent/3: rebuild the chapter's represented amount.
    quantity_model_represent/3,
    % quantity_model_trial/4: re-run the chapter's trials outside the narration.
    quantity_model_trial/4,
    % quantity_model_record/4: re-mint the owned verdict by enacting the same trial.
    quantity_model_record/4
]).
% Load situation appraisal so the appraisals can be re-read independently.
:- use_module(library(situation_appraisal), [
    % situation_appraisal_appraise/3: re-read the drives' own error directly.
    situation_appraisal_appraise/3
]).
% Load arousal regulation so the settling can be re-run independently.
:- use_module(library(arousal_regulation), [
    % arousal_regulation_arouse/3: raise arousal on an empty bus.
    arousal_regulation_arouse/3,
    % arousal_regulation_level/2: read the settled level.
    arousal_regulation_level/2,
    % arousal_regulation_regulate/3: settle to baseline, counting ticks.
    arousal_regulation_regulate/3
]).
% Load pretend play for the quarantine checks.
:- use_module(library(pretend_play), [
    % pretend_play_reset/0: clear every reality before the reproduction fixture.
    pretend_play_reset/0,
    % pretend_play_transition_add/3: teach the one what-if transition the fixture pretends over.
    pretend_play_transition_add/3,
    % pretend_play_pretend/3: roll the pretend scene forward through the taught transition.
    pretend_play_pretend/3,
    % pretend_play_quarantined/1: the pretended fact is sealed in the imagined reality only.
    pretend_play_quarantined/1,
    % pretend_play_holds/2: check a fact against one named reality directly.
    pretend_play_holds/2,
    % pretend_play_promote/3: the guarded crossing whose refusal into observed the test reproduces.
    pretend_play_promote/3,
    % pretend_play_thought/3: re-mint the pretend thought's content-addressed identifier.
    pretend_play_thought/3
]).
% Reuse empathy so the social-pain numbers and the empathy trial can be checked independently.
:- use_module(library(empathy), [
    % empathy_social_connection_drive/1: the standard social drive term.
    empathy_social_connection_drive/1,
    % empathy_rejection/2: the social severance signal over the body.
    empathy_rejection/2,
    % empathy_modelled_distress/3: the only sanctioned constructor of a modelled distress.
    empathy_modelled_distress/3,
    % empathy_trial/5: the whole empathy trial - resonance, proposals, selection, applied help.
    empathy_trial/5,
    % empathy_distress_record/3: re-mint the shareable fears attitude the story prints.
    empathy_distress_record/3
]).
% Reuse drive_system so the shared-circuitry equivalence can be computed outside the narration.
:- use_module(library(drive_system), [
    % drive_system_error/3: the one predicate both pains pass through.
    drive_system_error/3
]).
% Reuse the simulated body so the seam chapter's episodes can be rebuilt outside the narration.
:- use_module(library(simulated_body), [
    % simulated_body_boot/1: boot the stand-in machine for the independent seam checks.
    simulated_body_boot/1,
    % simulated_body_show/4: show the camera the obstacle the story shows it.
    simulated_body_show/4,
    % simulated_body_drain/3: drain the battery to the story's episode charges.
    simulated_body_drain/3,
    % simulated_body_actuators/2: read the movement log, for the independent steering check.
    simulated_body_actuators/2
]).
% Reuse the body interface so the seam chapter's claims can be re-derived independently.
:- use_module(library(body_interface), [
    % body_interface_energy_drive/1: the drive that defends a full battery.
    body_interface_energy_drive/1,
    % body_interface_senses/2: the machine's sensors become the mind's senses, for the steering check.
    body_interface_senses/2,
    % body_interface_candidates/4: the candidate interface, for the exact-tie check.
    body_interface_candidates/4,
    % body_interface_sense_act_step/7: one closed pass, for the independent tie check.
    body_interface_sense_act_step/7,
    % body_interface_survival_run/5: the draining-battery run, for the independent rhythm check.
    body_interface_survival_run/5,
    % body_interface_record/4: re-mint the story's loop record by enacting the same pass.
    body_interface_record/4
]).
% Reuse the override controller so breath-beats-kindness can be re-proven directly.
:- use_module(library(override_controller), [
    % override_controller_arbitrate/4: a vital drive in distress seizes control from any released action.
    override_controller_arbitrate/4
]).

% capstone_demonstration_test_contains(+Story, +Fragment): some story line carries the fragment.
capstone_demonstration_test_contains(Story, Fragment) :-
    % Search the lines in order for the first one carrying the fragment.
    member(Line, Story),
    % The fragment appears anywhere inside the line.
    sub_string(Line, _, _, _, Fragment),
    % One carrying line is enough.
    !.

% capstone_demonstration_test_retraction_identifiers(+Story, -Identifiers): the distinct retraction identifiers the story carries.
capstone_demonstration_test_retraction_identifiers(Story, Identifiers) :-
    % Collect the sixty-four-character body of every retraction identifier printed anywhere in the story.
    findall(Hex,
            % Scan each line for the retraction scheme and read the identifier body that follows it.
            ( member(Line, Story),
              % Find an occurrence of the retraction scheme prefix.
              sub_string(Line, Before, _, _, "retraction:"),
              % The identifier body starts right after the eleven-character prefix.
              Start is Before + 11,
              % Read the sixty-four-character body; a line without room here simply does not match.
              sub_string(Line, Start, 64, _, Hex)
            ),
            Bodies),
    % Distinct identifiers only.
    sort(Bodies, Identifiers).

% capstone_demonstration_test_first_index(+Story, +Fragment, -Index): the position of the first line carrying the fragment.
capstone_demonstration_test_first_index(Story, Fragment, Index) :-
    % Walk the lines with their positions.
    nth0(Index, Story, Line),
    % The first line carrying the fragment wins.
    sub_string(Line, _, _, _, Fragment),
    % Commit to the first such position.
    !.

% Open the test block for the capstone_demonstration pack.
:- begin_tests(capstone_demonstration).

% The story is a non-empty list made entirely of text lines.
test(story_is_a_nonempty_list_of_text_lines) :-
    % Tell the story over ten ticks.
    capstone_demonstration_story(10, Story),
    % The story has lines.
    assertion(Story \== []),
    % Every line is a string of text.
    assertion(forall(member(Line, Story), string(Line))).

% The story is deterministic: told twice, it is the same story, word for word.
test(story_is_deterministic) :-
    % Tell the story once.
    capstone_demonstration_story(10, First),
    % Tell it again.
    capstone_demonstration_story(10, Second),
    % The two tellings are identical.
    assertion(First == Second).

% The heartbeat is narrated tick by tick: exactly one line per tick opens with the tick label.
test(story_narrates_every_tick) :-
    % Tell the story over ten ticks.
    capstone_demonstration_story(10, Story),
    % Collect every line that opens with the per-tick label.
    findall(Line, (member(Line, Story), string_concat("Tick ", _, Line)), TickLines),
    % There are exactly ten of them.
    assertion(length(TickLines, 10)).

% The heartbeat lines report the reward and the dopamine broadcast.
test(story_reports_reward_and_dopamine) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % The reward is reported.
    assertion(capstone_demonstration_test_contains(Story, "reward")),
    % The dopamine broadcast is reported.
    assertion(capstone_demonstration_test_contains(Story, "dopamine")).

% The story shows the body being regulated and names the monitored variable.
test(story_reports_the_regulated_body) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % The monitored body variable is named.
    assertion(capstone_demonstration_test_contains(Story, "temperature")),
    % The set-point the drive defends is named.
    assertion(capstone_demonstration_test_contains(Story, "37")).

% The story shows learning: the interface weight grew from its starting value.
test(story_reports_the_learned_weight) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % The narration states the weight grew from its boot value.
    assertion(capstone_demonstration_test_contains(Story, "grown from 0.5")).

% Independent dynamics check: the boot world really is driven to its set-point.
test(mind_regulates_body_to_set_point) :-
    % Boot the same world the story boots.
    capstone_demonstration_world(World0),
    % Run the whole mind for ten ticks, outside the narration.
    cognitive_cycle_run(World0, 10, WorldFinal, _Summaries),
    % Read the final body state.
    get_dict(body, WorldFinal, Body),
    % Read the monitored variable.
    memberchk(temperature-Temperature, Body),
    % The body settled at the drive's set-point.
    assertion(Temperature =:= 37).

% Independent dynamics check: the three-factor rule really grew the interface weight.
test(mind_learns_weight_above_boot_value) :-
    % Boot the same world the story boots.
    capstone_demonstration_world(World0),
    % Run the whole mind for ten ticks, outside the narration.
    cognitive_cycle_run(World0, 10, WorldFinal, _Summaries),
    % Read the final interfaces.
    get_dict(interfaces, WorldFinal, [interface(a, b, Weight, _, _)]),
    % The weight rose above its boot value of one half.
    assertion(Weight > 0.5).

% The confirmed forecast is narrated: signed error zero, and the stance superseded to observation.
test(story_covers_the_confirmed_forecast) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % The confirmed reveal carries no surprise.
    assertion(capstone_demonstration_test_contains(Story, "signed error 0.0")),
    % The simulation-graded stance is superseded to the stronger observation grade.
    assertion(capstone_demonstration_test_contains(Story, "superseded")).

% The disconfirmed forecast is narrated: signed error minus one, and the assertion retracted.
test(story_covers_the_surprise_and_retraction) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % The screen lifting on nothing carries the signed surprise.
    assertion(capstone_demonstration_test_contains(Story, "signed error -1.0")),
    % The wrong forecast's assertion is retracted on the record.
    assertion(capstone_demonstration_test_contains(Story, "retract")).

% The combined thought is narrated as a content-addressed causal relation object.
test(story_covers_the_combined_thought) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % The minted combination carries its content-addressed identifier scheme.
    assertion(capstone_demonstration_test_contains(Story, "causal_relation_object:")),
    % The chain of thought is narrated as one thought linking into the next.
    assertion(capstone_demonstration_test_contains(Story, "chain")).

% The false belief is narrated: the attitude record, the false place, and the true place all appear.
test(story_covers_the_false_belief) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % The minted belief carries the attitude identifier scheme.
    assertion(capstone_demonstration_test_contains(Story, "attitude:")),
    % Sally's false belief points at the basket.
    assertion(capstone_demonstration_test_contains(Story, "basket")),
    % The world's own record points at the box.
    assertion(capstone_demonstration_test_contains(Story, "box")).

% The Rule 25 distinction is narrated: the modelled holder and the signing source are different identities.
test(story_distinguishes_holder_from_source) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % The holder is a modelled individual.
    assertion(capstone_demonstration_test_contains(Story, "token_individual:")),
    % The signing source is konnectome's own public identity.
    assertion(capstone_demonstration_test_contains(Story, "ed25519:")).

% The story's minted attitude identifier is reproducible outside the story, byte for byte.
test(story_attitude_identifier_is_reproducible) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % Rebuild the same social scene outside the story.
    other_minds_reset,
    % Konnectome's own world record: the marble is really in the box.
    other_minds_world_fact_add(object_location(marble, box)),
    % Sally is attributed the false belief that the marble is in the basket.
    other_minds_belief_attribute(sally, object_location(marble, basket)),
    % The story's fixed simulation start is the export instant.
    capstone_demonstration_simulation_start(Start),
    % Re-mint the same attitude record independently.
    other_minds_search_prediction_export(sally, marble, Start, _Place, Record),
    % Read its content-addressed identifier.
    get_dict(id, Record, Identifier),
    % The story carries that very identifier.
    assertion(capstone_demonstration_test_contains(Story, Identifier)).

% The story tells the milestones in rung order and ends at the provenance layer.
test(story_respects_rung_order) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % Find where the heartbeat rung begins.
    capstone_demonstration_test_first_index(Story, "RUNG ZERO", RungZero),
    % Find where the prediction rung begins.
    capstone_demonstration_test_first_index(Story, "RUNG ONE", RungOne),
    % Find where the first-words rung begins.
    capstone_demonstration_test_first_index(Story, "RUNG TWO", RungTwo),
    % Find where the social rung begins.
    capstone_demonstration_test_first_index(Story, "RUNG FOUR", RungFour),
    % Find where the reasoning rung begins.
    capstone_demonstration_test_first_index(Story, "RUNG THREE", RungThree),
    % Find where the social rung's deepening begins.
    capstone_demonstration_test_first_index(Story, "DEEPENED", Deepened),
    % Find where the social rung's finish begins.
    capstone_demonstration_test_first_index(Story, "FINISHED", Finished),
    % Find where the provenance layer begins.
    capstone_demonstration_test_first_index(Story, "THE PROVENANCE LAYER", Provenance),
    % The heartbeat comes before the prediction.
    assertion(RungZero < RungOne),
    % The prediction comes before the first words.
    assertion(RungOne < RungTwo),
    % The first words come before the reasoning.
    assertion(RungTwo < RungThree),
    % The reasoning comes before the social milestone.
    assertion(RungThree < RungFour),
    % The false belief comes before the rung's deepening.
    assertion(RungFour < Deepened),
    % The deepening comes before the rung's finish.
    assertion(Deepened < Finished),
    % The provenance layer closes the story.
    assertion(Finished < Provenance).

% The story's take-backs are tellable apart from the records alone: the supersession's withdrawal, the
% cruel world's outright retraction, the misattributed distress's withdrawal, and the passed threat's
% withdrawal carry four DIFFERENT identifiers (the two-retraction form of this test was found by the
% slice-14 pre-merge adversarial review: with one shared instant two take-backs minted one identical
% record, because a retraction's reason is not identity-bearing; slice 18 deliberately raised the count
% to three when the empathy chapter's honest exit joined the telling; slice 23 deliberately raises it to
% four when the appraisal chapter's honest exit joins, and this comment records that the change was
% deliberate).
test(story_distinguishes_the_four_retractions) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % Collect every distinct retraction identifier the story prints.
    capstone_demonstration_test_retraction_identifiers(Story, Identifiers),
    % The kind world's withdrawal, the cruel world's retraction, the misattribution's withdrawal, and
    % the passed threat's withdrawal are four distinct records.
    assertion(length(Identifiers, 4)).

% The story claims only what is shown: the undemonstrated rungs and the unsigned records are named honestly.
test(story_marks_the_honest_limits) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % The undemonstrated rungs are declared, not implied to pass.
    assertion(capstone_demonstration_test_contains(Story, "not yet demonstrated")),
    % The deployment signing boundary is declared: the records ship unsigned.
    assertion(capstone_demonstration_test_contains(Story, "unsigned")).

% The runnable entry point prints the same story to the console.
test(run_prints_the_story) :-
    % Capture everything the default run prints.
    with_output_to(string(Printed), capstone_demonstration_run),
    % The heartbeat rung header was printed.
    assertion(sub_string(Printed, _, _, _, "RUNG ZERO")),
    % The provenance layer header was printed.
    assertion(sub_string(Printed, _, _, _, "THE PROVENANCE LAYER")).

% A tick count too small to drive the body home is refused as a hard error.
test(too_few_ticks_rejected, throws(error(capstone_demonstration_bad_ticks(_), _))) :-
    % Zero ticks cannot demonstrate a heartbeat.
    capstone_demonstration_story(0, _Story).

% A tick count that is not an integer is refused as a hard error.
test(non_integer_ticks_rejected, throws(error(capstone_demonstration_bad_ticks(_), _))) :-
    % A word is not a number of ticks.
    capstone_demonstration_story(five, _Story).

% The first words are narrated: the rung's header and both grounded words appear.
test(story_covers_the_first_words) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % The rung's header appears.
    assertion(capstone_demonstration_test_contains(Story, "RUNG TWO")),
    % The deficit word appears.
    assertion(capstone_demonstration_test_contains(Story, "warm")),
    % The satisfied word appears.
    assertion(capstone_demonstration_test_contains(Story, "settled")).

% The pilot is narrated: the same heard words draw different replies in different drive states.
test(story_replies_change_with_drive_state) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % The deficit-state reply names what the mind is, then what it seeks.
    assertion(capstone_demonstration_test_contains(Story, "it answers: warm settled.")),
    % The satisfied-state reply names only what the mind is.
    assertion(capstone_demonstration_test_contains(Story, "it answers: settled.")).

% Independent check: the vocabulary really is grounded only in conditions the mind lived.
test(mind_grounds_words_only_in_lived_conditions) :-
    % Boot the same world the story boots.
    capstone_demonstration_world(World0),
    % Live the run and ground the vocabulary outside the narration.
    symbol_exchange_vocabulary(World0, 10, Groundings),
    % Exactly the two grounded words, each in a lived condition.
    assertion(Groundings == [grounding(warm, in_deficit), grounding(settled, satisfied)]).

% Independent check: the drive-state discriminator really colours the reply.
test(mind_replies_differently_in_different_drive_states) :-
    % Boot the same world the story boots.
    capstone_demonstration_world(World0),
    % Ground the vocabulary outside the narration.
    symbol_exchange_vocabulary(World0, 10, Groundings),
    % Ask while the body runs warm.
    symbol_exchange_reply(Groundings, [drive(temperature, temperature, 37, none)], [temperature-40], [how, are, you], DeficitReply),
    % Ask the same words while the body sits at the set-point.
    symbol_exchange_reply(Groundings, [drive(temperature, temperature, 37, none)], [temperature-37], [how, are, you], SatisfiedReply),
    % In deficit the mind names its state and what it seeks.
    assertion(DeficitReply == [warm, settled]),
    % Satisfied it names its state alone.
    assertion(SatisfiedReply == [settled]),
    % The same heard words drew different replies in different drive states.
    assertion(DeficitReply \== SatisfiedReply).

% The pretend game is narrated: the quarantine and the refused crossing both appear.
test(story_covers_the_pretend_quarantine) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % The quarantine is named.
    assertion(capstone_demonstration_test_contains(Story, "quarantine")),
    % The refusal is quoted in the pack's own words.
    assertion(capstone_demonstration_test_contains(Story, "pretend may never be promoted into the observed record")).

% Independent check: pretend really never reaches the observed record.
test(pretend_never_reaches_the_observed_record) :-
    % Start the pretend runtime from a clean slate.
    pretend_play_reset,
    % Teach the one what-if transition the story pretends over.
    pretend_play_transition_add(settled, sun_beats_down, too_warm),
    % Roll the pretend scene forward.
    pretend_play_pretend(settled, [sun_beats_down], Trajectory),
    % The trajectory visited the pretended state.
    assertion(Trajectory == [settled, too_warm]),
    % The pretended fact is quarantined: imagined, and not observed.
    assertion(pretend_play_quarantined(visited(too_warm))),
    % The observed reality never holds the pretended fact.
    assertion(\+ pretend_play_holds(observed, visited(too_warm))),
    % The crossing into observed is refused by name.
    catch(pretend_play_promote(imagined, visited(too_warm), observed), Error, true),
    % The refusal carries the forbidden fact.
    assertion(Error = error(pretend_play_forbidden_promotion(visited(too_warm)), _)).

% The story's pretend thought identifier is reproducible outside the story, byte for byte.
test(story_pretend_thought_identifier_is_reproducible) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % Re-mint the same pretend thought independently.
    pretend_play_thought("sun_beats_down", "body_too_warm", Thought),
    % Read its content-addressed identifier.
    get_dict(id, Thought, Identifier),
    % The story carries that very identifier.
    assertion(capstone_demonstration_test_contains(Story, Identifier)).

% The social pain is narrated: the deepening's header and the defended belonging both appear.
test(story_covers_the_social_pain) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % The deepening's header appears.
    assertion(capstone_demonstration_test_contains(Story, "DEEPENED")),
    % The defended body variable is named.
    assertion(capstone_demonstration_test_contains(Story, "belonging")).

% The empathy trial is narrated: the released help and the breath override both appear.
test(story_covers_the_empathy_trial) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % The released help is named as the drives proposed it.
    assertion(capstone_demonstration_test_contains(Story, "reduce(social_connection)")),
    % Breath still overrides kindness.
    assertion(capstone_demonstration_test_contains(Story, "released(breathe)")).

% Independent check: a social severance and a physical thwarting of equal magnitude read equal through the identical predicate.
test(social_pain_equals_physical_pain) :-
    % A physical thwarting: one degree from the set-point.
    drive_system_error(drive(temperature, temperature, 37, none), [temperature-38], PhysicalError),
    % The standard social drive.
    empathy_social_connection_drive(SocialDrive),
    % Connection at the set-point carries no error.
    drive_system_error(SocialDrive, [belonging-1], ConnectedError),
    % The severance: belonging drops to zero.
    empathy_rejection([belonging-1], RejectedBody),
    % The social severance read through the very same predicate.
    drive_system_error(SocialDrive, RejectedBody, SocialError),
    % Connection satisfied the drive.
    assertion(ConnectedError =:= 0),
    % The two pains are equal, number for number.
    assertion(PhysicalError =:= SocialError).

% Independent check: modelled distress really flips the selection toward help.
test(empathy_flips_the_selection) :-
    % The standard social drive.
    empathy_social_connection_drive(SocialDrive),
    % Two drives compete: a mildly pressing temperature and a satisfied connection.
    Drives = [drive(temperature, temperature, 37, none), SocialDrive],
    % The shared body.
    Body = [temperature-37.5, belonging-1],
    % With Ana fine, the mind tends its own temperature.
    empathy_modelled_distress(ana, 0, NoDistress),
    % The calm trial.
    empathy_trial(NoDistress, Drives, Body, CalmOutcome, _CalmBody),
    % The mildly pressing temperature wins.
    assertion(CalmOutcome == released(reduce(temperature))),
    % With Ana in full distress, the selection flips.
    empathy_modelled_distress(ana, 1, FullDistress),
    % The empathy trial.
    empathy_trial(FullDistress, Drives, Body, HelpOutcome, HelpedBody),
    % The helping action is released - proposed by the drives, never invented.
    assertion(HelpOutcome == released(reduce(social_connection))),
    % The help restored belonging exactly to its set-point.
    assertion((memberchk(belonging-Belonging, HelpedBody), Belonging =:= 1)),
    % The temperature was left untouched by the help.
    assertion((memberchk(temperature-Temperature, HelpedBody), Temperature =:= 37.5)).

% Independent check: a fractional distress draws a proportionate help that lands belonging exactly at the set-point.
test(help_lands_belonging_at_the_set_point) :-
    % The standard social drive.
    empathy_social_connection_drive(SocialDrive),
    % A partial distress: level 0.4.
    empathy_modelled_distress(ana, 0.4, PartialDistress),
    % The trial over the social drive alone.
    empathy_trial(PartialDistress, [SocialDrive], [belonging-1], Outcome, Body),
    % The help was released.
    assertion(Outcome == released(reduce(social_connection))),
    % The help landed belonging exactly at the set-point - settled, never overshot.
    assertion((memberchk(belonging-Belonging, Body), Belonging =:= 1)).

% Independent check: breath still overrides kindness.
test(breath_still_overrides_kindness) :-
    % Respiration in distress above the threshold arbitrates against the released help.
    override_controller_arbitrate([override(respiration, 0, 0.9, breathe)], 0.5, released(reduce(social_connection)), Final),
    % Breath seizes control; social distress never outranks it.
    assertion(Final == released(breathe)).

% The story's minted fears-attitude identifier is reproducible outside the story, byte for byte.
test(story_empathy_record_identifier_is_reproducible) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % The story's fixed simulation start is the minting instant.
    capstone_demonstration_simulation_start(Start),
    % Re-mint the same fears attitude independently.
    empathy_distress_record("ana", Start, Record),
    % Read its content-addressed identifier.
    get_dict(id, Record, Identifier),
    % The story carries that very identifier.
    assertion(capstone_demonstration_test_contains(Story, Identifier)).

% The honest exit is narrated: the misattributed distress is retracted on the record.
test(story_retracts_the_misattributed_distress) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % The misattribution is named as the reason for the take-back.
    assertion(capstone_demonstration_test_contains(Story, "misattributed")).

% The epilogue no longer disclaims Rung Two, and now names the rung's remaining pilots honestly.
test(story_no_longer_disclaims_rung_two) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % Rung Two left the not-demonstrated list when the story learned its first words.
    assertion(\+ capstone_demonstration_test_contains(Story, "Rung Two (symbols and pretend play)")).

% Rung Three and Rung Four's pilots left the not-demonstrated list when the story learned to tell
% them at slice 23; only Rung Five remains, named with the guiding book's own real-machine demand.
test(story_disclaims_only_rung_five) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % Rung Three is no longer disclaimed - the story now tells it.
    assertion(\+ capstone_demonstration_test_contains(Story, "Rung Three (concrete reasoning)")),
    % The appraisal and regulation pilots are no longer disclaimed - the story now tells them.
    assertion(\+ capstone_demonstration_test_contains(Story, "nor are Rung Four's appraisal and regulation")),
    % Rung Five is still disclaimed, honestly.
    assertion(capstone_demonstration_test_contains(Story, "Rung Five (embodiment) is not yet demonstrated")),
    % And the disclaimer carries the book's own reason: the rung asks for a real machine.
    assertion(capstone_demonstration_test_contains(Story, "real machine")).

% The story covers the reasoning rung: the header, the named steps, the formed categories, and the
% conservation verdicts all appear in the telling.
test(story_covers_rung_three) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % The rung's header appears.
    assertion(capstone_demonstration_test_contains(Story, "RUNG THREE - THE CONCRETE REASONING")),
    % The named derivation steps appear.
    assertion(capstone_demonstration_test_contains(Story, "resting_is_above")),
    % The joining step appears.
    assertion(capstone_demonstration_test_contains(Story, "transitive_chain")),
    % The formed categories appear by their whole-word names.
    assertion(capstone_demonstration_test_contains(Story, "formed_category_1")),
    % The honest exile appears.
    assertion(capstone_demonstration_test_contains(Story, "outside_every_category")),
    % The book's conserving pour appears with its measured verdict.
    assertion(capstone_demonstration_test_contains(Story, "conserved(5)")),
    % The lossy pour appears with its measured verdict - the world over the name.
    assertion(capstone_demonstration_test_contains(Story, "changed(5, 4)")),
    % The causal discrimination appears.
    assertion(capstone_demonstration_test_contains(Story, "co-occurrence only")),
    % The plan appears.
    assertion(capstone_demonstration_test_contains(Story, "gather_wood")).

% The story covers the finished Rung Four: the appraisal owned as fears, the recorded
% satisfaction approximation, and the regulation resting exactly at baseline.
test(story_covers_the_appraisal_and_regulation) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % The finish's header appears.
    assertion(capstone_demonstration_test_contains(Story, "RUNG FOUR, FINISHED")),
    % The threat is owned as the standard's fears attitude.
    assertion(capstone_demonstration_test_contains(Story, "FEARS attitude")),
    % The satisfaction approximation is recorded, not hidden.
    assertion(capstone_demonstration_test_contains(Story, "no word for satisfaction")),
    % The regulation line lands exactly at baseline.
    assertion(capstone_demonstration_test_contains(Story, "EXACTLY at baseline")).

% INDEPENDENT DYNAMICS: the reasoning chapter's claims re-derived outside the narration - the
% story cannot grade its own homework.
test(reasoning_chapter_matches_independent_runs) :-
    % Re-form the chapter's categories independently.
    category_formation_learn([
        experience(apple, [color-red, kind-fruit, shape-round]),
        experience(cherry, [color-red, kind-fruit, shape-round]),
        experience(ball, [color-blue, kind-toy, shape-round]),
        experience(block, [color-blue, kind-toy, shape-square])
    ], 2, Categories),
    % The independent run forms the same two categories the story tells.
    assertion(Categories == [
        category(formed_category_1, [color-red, kind-fruit, shape-round], [apple, cherry]),
        category(formed_category_2, [color-blue, kind-toy], [ball, block])
    ]),
    % Re-run the chapter's conserving pour independently.
    quantity_model_represent(5, glass(short_wide), Water),
    quantity_model_trial(Water, pour(glass(tall_thin)), PourVerdict, _Poured),
    % The independent measurement agrees.
    assertion(PourVerdict == conserved(5)),
    % Re-run the chapter's lossy pour independently.
    quantity_model_trial(Water, pour_losing(glass(tall_thin), 1), LossyVerdict, _Spilt),
    % The independent measurement agrees: the model, not the name.
    assertion(LossyVerdict == changed(5, 4)).

% INDEPENDENT DYNAMICS: the appraisal is nothing but the drives' own error, re-read directly.
test(appraisal_reads_the_drives_own_error) :-
    % Appraise the too-warm boot body directly.
    situation_appraisal_appraise(drive(temperature, temperature, 37, none), [temperature-40], Hot),
    % Three degrees from the set-point is a threat at distance three.
    assertion(Hot == appraisal(threatened, 3)),
    % Appraise the settled body directly.
    situation_appraisal_appraise(drive(temperature, temperature, 37, none), [temperature-37], Settled),
    % At the set-point the goal is met.
    assertion(Settled == appraisal(satisfied, 0)).

% INDEPENDENT DYNAMICS: a full alarm settles exactly at baseline in eight halving ticks.
test(regulation_settles_exactly_at_baseline_in_eight_ticks) :-
    % Raise arousal to one on an empty bus.
    arousal_regulation_arouse([], 1.0, Aroused),
    % Regulate to rest, counting the ticks.
    arousal_regulation_regulate(Aroused, Rested, NumTicks),
    % Read the settled level.
    arousal_regulation_level(Rested, Level),
    % Exactly baseline, never overshot.
    assertion(Level =:= 0.0),
    % Eight ticks brought the alarm to rest.
    assertion(NumTicks =:= 8).

% The story's owned conservation verdict is reproducible: the record re-minted independently, by
% enacting the same trial, carries the identifier the story printed - byte for byte.
test(story_verdict_record_is_reproducible) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % The story's fixed simulation start stamps the independent re-mint.
    capstone_demonstration_simulation_start(Start),
    % Re-enact the same trial and re-mint the same record.
    quantity_model_represent(5, glass(short_wide), Water),
    quantity_model_record(Water, pour(glass(tall_thin)), Start, Record),
    % Read the re-minted identifier.
    get_dict(id, Record, Identifier),
    % The story printed that very identifier.
    assertion(capstone_demonstration_test_contains(Story, Identifier)).

% The whole story is deterministic: told twice in one process, it comes back byte-identical -
% no chapter's global-state reset (the category episode's store ownership included) leaks into
% another telling.
test(story_is_deterministic_across_two_tellings) :-
    % Tell the story once.
    capstone_demonstration_story(10, First),
    % Tell it again in the same process.
    capstone_demonstration_story(10, Second),
    % The two tellings are identical, line for line.
    assertion(First == Second).

% The story covers the body seam: the chapter's header, the felt hunger, the released steering,
% and the survival rhythm all appear in the telling.
test(story_covers_the_body_seam) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % The chapter's header appears.
    assertion(capstone_demonstration_test_contains(Story, "THE BODY SEAM")),
    % The book's sentence appears: a low battery is felt as hunger.
    assertion(capstone_demonstration_test_contains(Story, "FELT AS HUNGER")),
    % The steering release appears.
    assertion(capstone_demonstration_test_contains(Story, "released(steer_around)")),
    % The survival rhythm's self-driven recharge appears.
    assertion(capstone_demonstration_test_contains(Story, "OF ITS OWN ACCORD")),
    % The deliberate tie appears: the drives come before the reflexes.
    assertion(capstone_demonstration_test_contains(Story, "starving battery outranks a seen obstacle")).

% The seam chapter claims groundwork and refuses the rung, in its own words - and the epilogue
% still disclaims embodiment with the book's real-machine reason.
test(story_seam_claims_groundwork_not_the_rung) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % The chapter's own refusal appears.
    assertion(capstone_demonstration_test_contains(Story, "the rung is NOT claimed")),
    % The epilogue names the groundwork boundary explicitly.
    assertion(capstone_demonstration_test_contains(Story, "groundwork is not the rung")),
    % The epilogue's Rung Five disclaimer still stands, word for word.
    assertion(capstone_demonstration_test_contains(Story, "Rung Five (embodiment) is not yet demonstrated")).

% The seam chapter sits between the finished Rung Four and the provenance layer.
test(story_seam_chapter_sits_before_the_provenance_layer) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % Find where the social rung's finish begins.
    capstone_demonstration_test_first_index(Story, "FINISHED", Finished),
    % Find where the seam chapter begins.
    capstone_demonstration_test_first_index(Story, "THE BODY SEAM", BodySeam),
    % Find where the provenance layer begins.
    capstone_demonstration_test_first_index(Story, "THE PROVENANCE LAYER", Provenance),
    % The finish comes before the seam.
    assertion(Finished < BodySeam),
    % The seam comes before the provenance layer.
    assertion(BodySeam < Provenance).

% The story's minted loop-record identifier is reproducible outside the story, byte for byte -
% by ENACTING the same pass, because that is the only way the record can be minted at all.
test(story_loop_record_identifier_is_reproducible) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % Rebuild the same episode outside the story: the booted machine drained to a pressing half charge.
    simulated_body_boot(Booted),
    % Drain to the pressing half charge.
    simulated_body_drain(Booted, 0.5, HalfCharged),
    % The energy drive.
    body_interface_energy_drive(EnergyDrive),
    % The story's fixed simulation start is the minting instant.
    capstone_demonstration_simulation_start(Start),
    % Re-enact the same pass and re-mint the same record.
    body_interface_record(HalfCharged, [EnergyDrive], Start, Record),
    % Read the re-minted identifier.
    get_dict(id, Record, Identifier),
    % The story printed that very identifier.
    assertion(capstone_demonstration_test_contains(Story, Identifier)).

% INDEPENDENT DYNAMICS: the survival rhythm the story tells, re-run outside the narration.
test(seam_survival_rhythm_matches_independent_run) :-
    % Boot the stand-in machine.
    simulated_body_boot(Booted),
    % The energy drive.
    body_interface_energy_drive(EnergyDrive),
    % Six ticks of draining life, outside the narration.
    body_interface_survival_run(Booted, [EnergyDrive], 6, Trace, _BodyFinal),
    % The exact rhythm the story claims: hold at mild hunger, recharge at pressing, repeated.
    assertion(Trace == [tick(1, 0.75, nothing, 0.75),
                        tick(2, 0.5, released(reduce(energy)), 1.0),
                        tick(3, 0.75, nothing, 0.75),
                        tick(4, 0.5, released(reduce(energy)), 1.0),
                        tick(5, 0.75, nothing, 0.75),
                        tick(6, 0.5, released(reduce(energy)), 1.0)]).

% INDEPENDENT DYNAMICS: a half-empty battery and a half-degree thermal error read equal through
% the one predicate every pain passes through.
test(seam_hunger_equals_thermal_error) :-
    % The energy drive.
    body_interface_energy_drive(EnergyDrive),
    % The battery at half charge.
    drive_system_error(EnergyDrive, [battery_charge-0.5], HungerError),
    % The body half a degree from its defended set-point.
    drive_system_error(drive(temperature, temperature, 37, none), [temperature-36.5], ThermalError),
    % The two readings are equal, number for number.
    assertion(HungerError =:= ThermalError).

% INDEPENDENT DYNAMICS: at the exact salience tie the drives outrank the reflexes, re-run directly -
% and the tie is PROVEN exact, not assumed (a review finding: without the equality a drifted reflex
% salience would leave the outcome unchanged while falsifying the claimed tie).
test(seam_tie_break_prefers_the_drives) :-
    % Boot the stand-in machine.
    simulated_body_boot(Booted),
    % Starve the battery to empty - the energy error reaches the reflex's fixed salience.
    simulated_body_drain(Booted, 1.0, Starving),
    % Show the starving machine an obstacle.
    simulated_body_show(Starving, path_ahead, obstacle, StarvingAndBlocked),
    % The energy drive.
    body_interface_energy_drive(EnergyDrive),
    % The starving drive's own error - the drive side of the claimed tie.
    drive_system_error(EnergyDrive, [battery_charge-0.0], StarvingError),
    % The reflex's live salience, read through the public candidate interface: no drives, one obstacle.
    body_interface_candidates([percept(path_ahead, obstacle)], [], [], ReflexCandidates),
    % The reflex proposal alone stands, carrying its fixed salience.
    ReflexCandidates = [action(steer_around, ReflexSalience)],
    % The tie really is exact: the starving error equals the reflex salience.
    assertion(StarvingError =:= ReflexSalience),
    % One closed pass over the starving, blocked machine.
    body_interface_sense_act_step(StarvingAndBlocked, [EnergyDrive], [], _Body, _Drives, _Bus, Outcome),
    % The starving battery outranks the seen obstacle at equal salience.
    assertion(Outcome == released(reduce(energy))).

% INDEPENDENT DYNAMICS: the steering episode the story tells, re-run outside the narration - the
% one seam claim a review found graded only on the story's own output.
test(seam_steering_episode_matches_independent_run) :-
    % Boot the stand-in machine.
    simulated_body_boot(Booted),
    % Show the camera the obstacle.
    simulated_body_show(Booted, path_ahead, obstacle, Seen),
    % The energy drive.
    body_interface_energy_drive(EnergyDrive),
    % One closed pass of the loop over the seen obstacle, battery full.
    body_interface_sense_act_step(Seen, [EnergyDrive], [], Steered, _Drives, _Bus, Outcome),
    % The steering reflex was released.
    assertion(Outcome == released(steer_around)),
    % The actuator log carries the movement - the body really moved.
    simulated_body_actuators(Steered, Log),
    % Exactly the one steering movement.
    assertion(Log == [steer_around]),
    % Sense again through the moved body.
    body_interface_senses(Steered, PerceptsAfter),
    % The camera reads clear: acting changed what the machine will see next.
    assertion(PerceptsAfter == [percept(path_ahead, clear)]).

% Close the test block for the capstone_demonstration pack.
:- end_tests(capstone_demonstration).
