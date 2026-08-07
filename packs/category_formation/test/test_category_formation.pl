% Load the module under test from the library path.
:- use_module(library(category_formation)).
% Load the Prolog Unit test framework.
:- use_module(library(plunit)).
% Load the sibling classifier so the flexible re-sort can be verified independently of the wrapper.
:- use_module(library(concrete_operations), [concrete_operations_classify/3]).

% category_formation_test_instant(-Instant): the fixed instant, so every minted record is deterministic.
category_formation_test_instant("2026-08-07T00:00:00Z").

% category_formation_test_experiences(-Experiences): a small stream of perceived objects, each a bundle
% of property-value pairs, from which the mind can form two natural categories on its own.
category_formation_test_experiences([
    % A red round fruit.
    experience(apple, [color-red, kind-fruit, shape-round]),
    % Another red round fruit.
    experience(cherry, [color-red, kind-fruit, shape-round]),
    % A blue round toy.
    experience(ball, [color-blue, kind-toy, shape-round]),
    % A blue square toy.
    experience(block, [color-blue, kind-toy, shape-square])
]).

% Open the category_formation test block.
:- begin_tests(category_formation).

% The mind forms its own categories from the stream of experience: two groups emerge, each named,
% each carrying the defining core its members share - categories FORMED, not handed down.
test(categories_are_formed_from_experience) :-
    % Take the experience stream.
    category_formation_test_experiences(Experiences),
    % Form categories requiring at least two shared property-value pairs.
    category_formation_learn(Experiences, 2, Categories),
    % Exactly the two natural categories emerge, in deterministic order, with their defining cores.
    assertion(Categories == [
        category(formed_category_1, [color-red, kind-fruit, shape-round], [apple, cherry]),
        category(formed_category_2, [color-blue, kind-toy], [ball, block])
    ]).

% Each category's defining core really is shared by every member - verified here independently,
% against the raw experiences, not by trusting the wrapper's own answer.
test(defining_core_is_truly_shared) :-
    % Take the experience stream.
    category_formation_test_experiences(Experiences),
    % Form the categories.
    category_formation_learn(Experiences, 2, Categories),
    % Every member of every category carries every pair of its category's defining core.
    forall(member(category(_, Core, Members), Categories),
           forall(member(Member, Members),
                  (   member(experience(Member, Properties), Experiences),
                      forall(member(Pair, Core), memberchk(Pair, Properties))
                  ))).

% Forming categories twice from the same experience yields byte-identical categories - determinism.
test(formation_is_deterministic) :-
    % Take the experience stream.
    category_formation_test_experiences(Experiences),
    % Form the categories once.
    category_formation_learn(Experiences, 2, First),
    % Form them again from the same stream.
    category_formation_learn(Experiences, 2, Second),
    % The two answers are identical.
    assertion(First == Second).

% The mind sorts perceived objects into the categories it formed itself - the book's classification
% trial, first half: sorting into categories the System has formed from experience.
test(sorting_into_own_formed_categories) :-
    % Take the experience stream.
    category_formation_test_experiences(Experiences),
    % Form the categories from it.
    category_formation_learn(Experiences, 2, Categories),
    % A new fruit and an unclassifiable pencil join the collection to be sorted.
    append(Experiences, [
        experience(tomato, [color-red, kind-fruit, shape-round]),
        experience(pencil, [color-yellow, kind-tool, shape-long])
    ], Collection),
    % Sort the collection into the mind's own categories.
    category_formation_sort(Collection, Categories, Groups),
    % Each member lands in the category whose defining core its properties carry; the pencil,
    % fitting no formed category, is reported honestly rather than forced into one.
    assertion(Groups == [
        group(formed_category_1, [apple, cherry, tomato]),
        group(formed_category_2, [ball, block]),
        group(outside_every_category, [pencil])
    ]).

% When every object fits a category, no outside_every_category group is invented.
test(no_outside_group_when_everything_fits) :-
    % Take the experience stream.
    category_formation_test_experiences(Experiences),
    % Form the categories from it.
    category_formation_learn(Experiences, 2, Categories),
    % Sort exactly the founding experiences.
    category_formation_sort(Experiences, Categories, Groups),
    % Only the two formed groups appear.
    assertion(Groups == [
        group(formed_category_1, [apple, cherry]),
        group(formed_category_2, [ball, block])
    ]).

% The flexible re-sort on request - the book's classification trial, second half: the same objects,
% re-sorted by a DIFFERENT property, yield a different partition than the formed categories did.
test(resort_by_a_different_property_on_request) :-
    % Take the experience stream.
    category_formation_test_experiences(Experiences),
    % Re-sort the same objects by shape on request.
    category_formation_resort(Experiences, shape, Groups),
    % The shape partition crosses the formed-category partition: the round group mixes a fruit
    % and a toy - flexible categorisation, demonstrated.
    assertion(Groups == [
        group(round, [apple, cherry, ball]),
        group(square, [block])
    ]).

% The re-sort is genuine reuse of the sibling classifier, not a reimplementation: calling the
% reused engine directly on the same collection gives the identical answer.
test(resort_agrees_with_the_reused_classifier) :-
    % Take the experience stream.
    category_formation_test_experiences(Experiences),
    % Re-sort through the wrapper.
    category_formation_resort(Experiences, color, WrapperGroups),
    % Convert each experience to the classifier's own object shape.
    findall(object(Name, Properties),
            member(experience(Name, Properties), Experiences),
            Objects),
    % Classify directly through the reused engine.
    concrete_operations_classify(Objects, color, EngineGroups),
    % The wrapper and the engine agree exactly.
    assertion(WrapperGroups == EngineGroups).

% A lone experience shares nothing with anyone: no category can form, and the honest answer is
% an empty category list, not an invented group of one.
test(one_experience_forms_no_category) :-
    % Form categories from a single experience.
    category_formation_learn([experience(apple, [color-red])], 1, Categories),
    % No category of fewer than two members is ever coined.
    assertion(Categories == []).

% Two experiences that share too little never merge into a category under the floor.
test(too_little_shared_forms_no_category) :-
    % Two experiences sharing only one pair, under a floor of two.
    category_formation_learn([
        experience(apple, [color-red, kind-fruit]),
        experience(ball, [color-red, kind-toy])
    ], 2, Categories),
    % No category forms.
    assertion(Categories == []).

% A collection that is not a proper list is refused by name, never walked.
test(non_list_experiences_refused, throws(error(category_formation_not_a_collection(not_a_list), _))) :-
    % Hand the learner a non-list.
    category_formation_learn(not_a_list, 2, _Categories).

% A malformed experience term is refused by name, never silently skipped.
test(malformed_experience_refused, throws(error(category_formation_malformed_experience(banana), _))) :-
    % One element is not an experience/2 term at all.
    category_formation_learn([experience(apple, [color-red]), banana], 2, _Categories).

% An experience with a half-built property value is refused by name - an unbound value would
% unify its way into cores it does not truly share.
test(half_built_experience_refused, throws(error(category_formation_malformed_experience(experience(ghost, _)), _))) :-
    % One property value is left unbound.
    category_formation_learn([experience(ghost, [color-_Unbound])], 2, _Categories).

% Two experiences under the same name would silently overwrite one another in the store; the
% duplicate is refused by name instead.
test(duplicate_experience_name_refused, throws(error(category_formation_duplicate_experience(apple), _))) :-
    % The same name arrives twice.
    category_formation_learn([
        experience(apple, [color-red]),
        experience(apple, [color-green])
    ], 2, _Categories).

% A shared-pair floor that is not a positive integer is refused by name.
test(bad_minimum_refused, throws(error(category_formation_bad_minimum(0), _))) :-
    % Zero shared pairs is no floor at all.
    category_formation_test_experiences(Experiences),
    category_formation_learn(Experiences, 0, _Categories).

% A malformed category term handed to the sorter is refused by name.
test(malformed_category_refused, throws(error(category_formation_malformed_category(nonsense), _))) :-
    % Take the experience stream.
    category_formation_test_experiences(Experiences),
    % Hand the sorter a list holding a non-category term.
    category_formation_sort(Experiences, [nonsense], _Groups).

% The formed categories are owned BY FORMING THEM: the record predicate enacts the learning
% episode itself, and the mind's stance on the outcome is graded derivation - the mind induced
% its categories from experience, it did not observe them ready-made.
test(formed_categories_stance_is_graded_derivation) :-
    % The fixed instant stamps the record.
    category_formation_test_instant(Instant),
    % Take the experience stream.
    category_formation_test_experiences(Experiences),
    % Own the formation conclusion by enacting the learning episode.
    category_formation_record(Experiences, 2, Instant, Record),
    % The record carries what the episode actually formed - verified against an independent run.
    category_formation_learn(Experiences, 2, Categories),
    % Render the independent outcome the same way the record predicate does.
    format(string(ExpectedText), "~w", [Categories]),
    % Read the record's carried content.
    get_dict(value, Record, Value),
    % The record's content is the enacted outcome, byte for byte.
    assertion(Value == ExpectedText),
    % The mind grades its own conclusion.
    category_formation_stance(Record, Instant, Stance),
    % The stance is graded derivation, never observation.
    get_dict(evidence_type, Stance, Grade),
    % The grade is derivation.
    assertion(Grade == "derivation"),
    % The stance is about the conclusion it grades.
    get_dict(about, Stance, About),
    % Read the conclusion's identifier.
    get_dict(id, Record, RecordIdentifier),
    % The stance names the conclusion, byte for byte.
    assertion(About == RecordIdentifier).

% The owned conclusion is content-addressed: the same episode, enacted twice, mints the same identifier.
test(owned_conclusion_is_reproducible) :-
    % The fixed instant stamps both tellings.
    category_formation_test_instant(Instant),
    % Take the experience stream.
    category_formation_test_experiences(Experiences),
    % Enact and own the episode once.
    category_formation_record(Experiences, 2, Instant, First),
    % Enact and own the identical episode again.
    category_formation_record(Experiences, 2, Instant, Second),
    % Read the first identifier.
    get_dict(id, First, FirstIdentifier),
    % Read the second identifier.
    get_dict(id, Second, SecondIdentifier),
    % Content-addressing makes the two identifiers identical.
    assertion(FirstIdentifier == SecondIdentifier).

% A malformed experience poisons the record path too: the record is only mintable by a learning
% episode, so the episode's own refusals guard it.
test(record_refuses_what_learning_refuses, throws(error(category_formation_malformed_experience(banana), _))) :-
    % The fixed instant stamps nothing, because the episode refuses first.
    category_formation_test_instant(Instant),
    % Try to own an episode over a malformed stream.
    category_formation_record([banana], 2, Instant, _Record).

% PINNED FROM REVIEW: a hand-built category whose core is not the learner's sorted, duplicate-free
% set is refused by name - an unsorted core would silently misclassify, never match.
test(unsorted_core_refused, throws(error(category_formation_malformed_category(category(formed_category_1, [shape-round, color-red], [apple])), _))) :-
    % Sort against a category whose core pairs arrive out of order.
    category_formation_sort([experience(apple, [color-red, shape-round])],
                            [category(formed_category_1, [shape-round, color-red], [apple])],
                            _Groups).

% PINNED FROM REVIEW: a category defined by nothing would swallow every object; it is refused.
test(empty_core_refused, throws(error(category_formation_malformed_category(category(catch_all, [], [])), _))) :-
    % Sort against a category with an empty defining core.
    category_formation_sort([experience(apple, [color-red])],
                            [category(catch_all, [], [])],
                            _Groups).

% PINNED FROM REVIEW: the reserved sentinel name cannot name a category - it would collide with
% the honest outside group and double-count members.
test(reserved_sentinel_name_refused, throws(error(category_formation_malformed_category(category(outside_every_category, [color-red], [])), _))) :-
    % Sort against a category wearing the sentinel's name.
    category_formation_sort([experience(apple, [color-red])],
                            [category(outside_every_category, [color-red], [])],
                            _Groups).

% PINNED FROM REVIEW: two categories under one identifier would double-count their members.
test(duplicate_category_identifier_refused, throws(error(category_formation_duplicate_category(formed_category_1), _))) :-
    % Sort against two categories sharing one identifier.
    category_formation_sort([experience(apple, [color-red])],
                            [category(formed_category_1, [color-red], [apple]),
                             category(formed_category_1, [color-red], [apple])],
                            _Groups).

% PINNED FROM REVIEW: the re-sort refuses duplicate experience names exactly as the sorter does -
% a doubled name would yield a doubled group member.
test(resort_refuses_duplicate_names, throws(error(category_formation_duplicate_experience(apple), _))) :-
    % Re-sort a collection carrying the same name twice.
    category_formation_resort([experience(apple, [color-red]),
                               experience(apple, [color-blue])], color, _Groups).

% PINNED FROM REVIEW: one experience cannot carry two values under one property key - the two
% halves of the trial would contradict each other on the same collection.
test(duplicate_property_key_refused, throws(error(category_formation_duplicate_property(muddle, color), _))) :-
    % An experience claiming to be both red and blue.
    category_formation_learn([experience(muddle, [color-red, color-blue])], 1, _Categories).

% PINNED FROM REVIEW: a category's Members field plays no part in sorting - membership is decided
% by the defining core alone, so even a category carrying a wrong member list sorts correctly.
test(sorting_ignores_the_members_field) :-
    % A category whose recorded members are plainly wrong.
    category_formation_sort([experience(apple, [color-red])],
                            [category(formed_category_1, [color-red], [somebody_else])],
                            Groups),
    % The sort reads the core, not the member list: apple fits, somebody_else is not consulted.
    assertion(Groups == [group(formed_category_1, [apple])]).

% PINNED FROM REVIEW: the re-sort's refusals surface under the reused classifier's own name -
% the re-sort IS concrete_operations_classify, and its glass box stays visible through the wrapper.
test(resort_surfaces_the_reused_classifier_refusal, throws(error(concrete_operations_unclassifiable(apple, size), _))) :-
    % Re-sort by a property the experience does not carry.
    category_formation_resort([experience(apple, [color-red])], size, _Groups).

% Close the category_formation test block.
:- end_tests(category_formation).
