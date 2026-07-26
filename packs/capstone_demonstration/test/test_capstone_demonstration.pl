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
    % Find where the social rung's deepening begins.
    capstone_demonstration_test_first_index(Story, "DEEPENED", Deepened),
    % Find where the provenance layer begins.
    capstone_demonstration_test_first_index(Story, "THE PROVENANCE LAYER", Provenance),
    % The heartbeat comes before the prediction.
    assertion(RungZero < RungOne),
    % The prediction comes before the first words.
    assertion(RungOne < RungTwo),
    % The first words come before the social milestone.
    assertion(RungTwo < RungFour),
    % The false belief comes before the rung's deepening.
    assertion(RungFour < Deepened),
    % The provenance layer closes the story.
    assertion(Deepened < Provenance).

% The story's take-backs are tellable apart from the records alone: the supersession's withdrawal, the
% cruel world's outright retraction, and the misattributed distress's withdrawal carry three DIFFERENT
% identifiers (the two-retraction form of this test was found by the slice-14 pre-merge adversarial review:
% with one shared instant two take-backs minted one identical record, because a retraction's reason is not
% identity-bearing; slice 18 deliberately raises the count to three when the empathy chapter's honest exit
% joined the telling, and this comment records that the change was deliberate).
test(story_distinguishes_the_three_retractions) :-
    % Tell the story.
    capstone_demonstration_story(10, Story),
    % Collect every distinct retraction identifier the story prints.
    capstone_demonstration_test_retraction_identifiers(Story, Identifiers),
    % The kind world's withdrawal, the cruel world's retraction, and the misattribution's withdrawal are three distinct records.
    assertion(length(Identifiers, 3)).

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
    assertion(\+ capstone_demonstration_test_contains(Story, "Rung Two (symbols and pretend play)")),
    % The rung's remaining pilots are named as still pending.
    assertion(capstone_demonstration_test_contains(Story, "appraisal and regulation")).

% Close the test block for the capstone_demonstration pack.
:- end_tests(capstone_demonstration).
