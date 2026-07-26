% Load the pretend_play module under test from the library path.
:- use_module(library(pretend_play)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).
% Reuse thought_combination so the pretend thought's identifier can be reproduced independently.
:- use_module(library(thought_combination), [
    % thought_combination_atomic/3: re-mint the pretend thought's occurrents outside the pack.
    thought_combination_atomic/3,
    % thought_combination_combine/3: re-mint the pretend relation outside the pack.
    thought_combination_combine/3
]).

% A fixed instant, so every minted stance is deterministic.
pretend_play_test_instant("2026-07-26T00:00:00Z").

% pretend_play_test_scene: the standard pretend scene - a path the mind never lived, from settled to too warm.
pretend_play_test_scene :-
    % Start the pretend machinery from a clean slate.
    pretend_play_reset,
    % In pretend, a beating sun can carry the settled body back to too warm.
    pretend_play_transition_add(settled, sun_beats_down, too_warm).

% Open the test block for the pretend_play pack.
:- begin_tests(pretend_play).

% The five realities of the quarantine are the reused pack's own.
test(realities_are_the_five) :-
    % Ask for the realities.
    pretend_play_realities(Realities),
    % The five partitions, observed first.
    assertion(Realities == [observed, desired, expected, imagined, recalled]).

% Pretending rolls a scene forward through its transitions.
test(pretending_rolls_the_scene_forward) :-
    % The standard scene.
    pretend_play_test_scene,
    % Pretend the sun beats down on the settled body.
    pretend_play_pretend(settled, [sun_beats_down], Trajectory),
    % The pretend visits the settled start and the too-warm end.
    assertion(Trajectory == [settled, too_warm]).

% What is pretended is quarantined: imagined, and never observed.
test(pretending_is_quarantined) :-
    % The standard scene.
    pretend_play_test_scene,
    % Pretend the scene.
    pretend_play_pretend(settled, [sun_beats_down], _Trajectory),
    % The visited state is held in the imagined reality.
    assertion(pretend_play_quarantined(visited(too_warm))),
    % And it never touched the observed record.
    assertion(\+ pretend_play_holds(observed, visited(too_warm))).

% Pretending leaves the observed record entirely untouched.
test(pretending_never_writes_the_observed_record) :-
    % The standard scene.
    pretend_play_test_scene,
    % Pretend the scene.
    pretend_play_pretend(settled, [sun_beats_down], _Trajectory),
    % Nothing pretended holds in the observed reality.
    assertion(\+ pretend_play_holds(observed, visited(settled))),
    % Nothing at all was observed.
    assertion(\+ pretend_play_holds(observed, visited(too_warm))).

% A pretend fact may be promoted - deliberately - into the expected reality.
test(promotion_to_expected_is_deliberate_and_works) :-
    % The standard scene, pretended.
    pretend_play_test_scene,
    % Pretend the scene.
    pretend_play_pretend(settled, [sun_beats_down], _Trajectory),
    % Before promotion, the expectation does not hold.
    assertion(\+ pretend_play_holds(expected, visited(too_warm))),
    % Promote the pretend fact into expectation - a deliberate, auditable act.
    pretend_play_promote(imagined, visited(too_warm), expected),
    % Now the expectation holds.
    assertion(pretend_play_holds(expected, visited(too_warm))).

% Pretend may NEVER be promoted into the observed record: only the world's own reveal writes what was observed.
test(promotion_to_observed_is_refused, throws(error(pretend_play_forbidden_promotion(_), _))) :-
    % The standard scene, pretended.
    pretend_play_test_scene,
    % Pretend the scene.
    pretend_play_pretend(settled, [sun_beats_down], _Trajectory),
    % Promoting pretend into fact is the one crossing this pack refuses.
    pretend_play_promote(imagined, visited(too_warm), observed).

% Promoting a fact that was never pretended fails cleanly rather than inventing it.
test(promotion_of_an_unpretended_fact_fails) :-
    % A clean slate with nothing pretended.
    pretend_play_reset,
    % There is nothing to promote.
    assertion(\+ pretend_play_promote(imagined, visited(nowhere), expected)).

% The pretend thought is minted as a content-addressed causal relation object.
test(pretend_thought_is_minted_and_content_addressed) :-
    % Mint the pretend relation: the beating sun would carry the body to too warm.
    pretend_play_thought("sun_beats_down", "body_too_warm", Thought),
    % Read its identifier.
    get_dict(id, Thought, Identifier),
    % The identifier carries the causal relation object scheme.
    assertion(string_concat("causal_relation_object:", _, Identifier)).

% The pretend thought's identifier is reproducible outside the pack, byte for byte.
test(pretend_thought_identifier_is_reproducible) :-
    % Mint the pretend relation inside the pack.
    pretend_play_thought("sun_beats_down", "body_too_warm", Thought),
    % Read its identifier.
    get_dict(id, Thought, Identifier),
    % Re-mint the same relation outside the pack.
    thought_combination_atomic("sun_beats_down", "event", CauseIdentifier),
    % The effect occurrent.
    thought_combination_atomic("body_too_warm", "state", EffectIdentifier),
    % The same combination.
    thought_combination_combine([CauseIdentifier], [EffectIdentifier], Independent),
    % Read the independent identifier.
    get_dict(id, Independent, IndependentIdentifier),
    % The two mintings agree byte for byte.
    assertion(Identifier == IndependentIdentifier).

% The mind's stance on a pretend thought is graded simulation - pretend evidence is model-made evidence.
test(pretend_stance_is_graded_simulation) :-
    % Mint the pretend relation.
    pretend_play_thought("sun_beats_down", "body_too_warm", Thought),
    % The fixed instant.
    pretend_play_test_instant(Instant),
    % Take the stance.
    pretend_play_stance(Thought, Instant, Stance),
    % The stance is graded simulation.
    get_dict(evidence_type, Stance, Grade),
    % Pretend never outranks observation.
    assertion(Grade == "simulation").

% The stance is about the pretend thought itself.
test(pretend_stance_is_about_the_thought) :-
    % Mint the pretend relation.
    pretend_play_thought("sun_beats_down", "body_too_warm", Thought),
    % Read the thought's identifier.
    get_dict(id, Thought, Identifier),
    % The fixed instant.
    pretend_play_test_instant(Instant),
    % Take the stance.
    pretend_play_stance(Thought, Instant, Stance),
    % The stance's subject is the pretend thought.
    get_dict(about, Stance, About),
    % About and identifier agree.
    assertion(About == Identifier).

% Reset clears the pretend realities.
test(reset_clears_the_pretence) :-
    % The standard scene, pretended.
    pretend_play_test_scene,
    % Pretend the scene.
    pretend_play_pretend(settled, [sun_beats_down], _Trajectory),
    % Reset.
    pretend_play_reset,
    % The pretend fact is gone.
    assertion(\+ pretend_play_quarantined(visited(too_warm))).

% Close the test block for the pretend_play pack.
:- end_tests(pretend_play).
