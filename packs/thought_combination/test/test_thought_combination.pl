% Load the thought_combination module under test from the library path.
:- use_module(library(thought_combination)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% A small fixture of atomic thoughts used across the tests.
thought_combination_test_kitchen(Heat, Place, Baked, Eat, HungerReduced) :-
    % Applying heat is a process.
    thought_combination_atomic("apply_heat", "process", Heat),
    % Placing the raw chicken is a process.
    thought_combination_atomic("place_raw_chicken", "process", Place),
    % The chicken being baked is a state.
    thought_combination_atomic("chicken_is_baked", "state", Baked),
    % Eating the food is a process.
    thought_combination_atomic("eat_food", "process", Eat),
    % Hunger being reduced is a state.
    thought_combination_atomic("hunger_reduced", "state", HungerReduced).

% Open the test block for the thought_combination pack.
:- begin_tests(thought_combination).

% An atomic thought is a content-addressed Causalontology occurrent.
test(an_atomic_thought_is_a_content_addressed_occurrent) :-
    % Mint an atomic thought.
    thought_combination_atomic("apply_heat", "process", Id),
    % Its identifier carries the occurrent scheme prefix.
    assertion(sub_string(Id, 0, _, _, "occurrent:")).

% Combining two thoughts mints a Causal Relation Object over exactly those causes and effect.
test(combining_two_thoughts_mints_a_causal_relation_object) :-
    % Build the kitchen thoughts.
    thought_combination_test_kitchen(Heat, Place, Baked, _Eat, _Hunger),
    % Combine heat and placing the chicken into the chicken being baked.
    thought_combination_combine([Heat, Place], [Baked], Cro),
    % Its identifier carries the causal_relation_object scheme prefix.
    thought_combination_id(Cro, Id),
    % Confirm the identifier prefix.
    assertion(sub_string(Id, 0, _, _, "causal_relation_object:")),
    % Its causes are exactly the two input thoughts.
    get_dict(causes, Cro, Causes),
    % Confirm the causes.
    assertion(Causes == [Heat, Place]),
    % Its effects are exactly the one output thought.
    get_dict(effects, Cro, Effects),
    % Confirm the effects.
    assertion(Effects == [Baked]).

% The same combination, minted twice, has the identical content-addressed identifier.
test(a_combination_is_reproducible) :-
    % Build the kitchen thoughts.
    thought_combination_test_kitchen(Heat, Place, Baked, _Eat, _Hunger),
    % Combine once.
    thought_combination_combine([Heat, Place], [Baked], CroA),
    % Combine again.
    thought_combination_combine([Heat, Place], [Baked], CroB),
    % Read both identifiers.
    thought_combination_id(CroA, IdA),
    thought_combination_id(CroB, IdB),
    % They are identical, which is exactly what content-addressing guarantees.
    assertion(IdA == IdB).

% Causes and effects must be occurrents: a non-occurrent cause is rejected.
test(a_non_occurrent_cause_is_rejected) :-
    % A baked-chicken effect to combine into.
    thought_combination_test_kitchen(_Heat, _Place, Baked, _Eat, _Hunger),
    % A continuant identifier is not a valid cause, so the combination fails.
    assertion(\+ thought_combination_combine(["continuant:0000", Baked], [Baked], _Cro)).

% An empty cause set is rejected.
test(an_empty_cause_set_is_rejected) :-
    % A baked-chicken effect.
    thought_combination_test_kitchen(_Heat, _Place, Baked, _Eat, _Hunger),
    % A combination with no causes fails.
    assertion(\+ thought_combination_combine([], [Baked], _Cro)).

% A modality changes the identity, so a modal combination is a distinct object.
test(a_modality_changes_the_identity) :-
    % Build the kitchen thoughts.
    thought_combination_test_kitchen(Heat, Place, Baked, _Eat, _Hunger),
    % A bare combination.
    thought_combination_combine([Heat, Place], [Baked], Bare),
    % The same combination, but marked sufficient.
    thought_combination_combine_modal([Heat, Place], [Baked], "sufficient", Modal),
    % Read both identifiers.
    thought_combination_id(Bare, BareId),
    thought_combination_id(Modal, ModalId),
    % The modal combination has its own, different identity.
    assertion(BareId \== ModalId).

% A chain of thought: one combination's effect is a cause of the next.
test(a_chain_of_thought_links_effect_to_cause) :-
    % Build the kitchen thoughts.
    thought_combination_test_kitchen(Heat, Place, Baked, Eat, Hunger),
    % Link one: heat and placing the chicken produce the baked chicken.
    thought_combination_combine([Heat, Place], [Baked], LinkOne),
    % Link two: the baked chicken and eating it produce reduced hunger.
    thought_combination_combine([Baked, Eat], [Hunger], LinkTwo),
    % The effect of link one is a cause of link two, so they chain.
    assertion(thought_combination_links(LinkOne, LinkTwo)),
    % An unrelated combination does not chain from link one.
    thought_combination_combine([Eat], [Hunger], Unrelated),
    % Link one does not link to the unrelated combination.
    assertion(\+ thought_combination_links(LinkOne, Unrelated)).

% Close the test block for the thought_combination pack.
:- end_tests(thought_combination).
