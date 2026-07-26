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

% capstone_demonstration_test_contains(+Story, +Fragment): some story line carries the fragment.
capstone_demonstration_test_contains(Story, Fragment) :-
    % Search the lines in order for the first one carrying the fragment.
    member(Line, Story),
    % The fragment appears anywhere inside the line.
    sub_string(Line, _, _, _, Fragment),
    % One carrying line is enough.
    !.

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
    % Find where the social rung begins.
    capstone_demonstration_test_first_index(Story, "RUNG FOUR", RungFour),
    % Find where the provenance layer begins.
    capstone_demonstration_test_first_index(Story, "THE PROVENANCE LAYER", Provenance),
    % The heartbeat comes before the prediction.
    assertion(RungZero < RungOne),
    % The prediction comes before the social milestone.
    assertion(RungOne < RungFour),
    % The provenance layer closes the story.
    assertion(RungFour < Provenance).

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

% Close the test block for the capstone_demonstration pack.
:- end_tests(capstone_demonstration).
