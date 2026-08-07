% Declare the category_formation module and the public interface of the formed-category trial.
:- module(category_formation, [
    % category_formation_learn/3: +Experiences, +MinimumShared, -Categories - form categories from experience.
    category_formation_learn/3,
    % category_formation_sort/3: +Experiences, +Categories, -Groups - sort objects into the mind's own categories.
    category_formation_sort/3,
    % category_formation_resort/3: +Experiences, +Property, -Groups - the flexible re-sort by a different property.
    category_formation_resort/3,
    % category_formation_record/4: +Experiences, +MinimumShared, +Instant, -Record - own the
    % conclusion by forming it: the record is minted from a learning episode enacted here.
    category_formation_record/4,
    % category_formation_stance/3: the mind's graded stance on its own conclusion - derivation, never observation.
    category_formation_stance/3
]).

% Reuse PrologAI's concept-formation engine - the inducer that coins a category from experience.
:- use_module(library(concept_formation), [
    % concept_formation_reset/0: forget all items, so each learning episode starts clean.
    concept_formation_reset/0,
    % concept_formation_observe/2: record one experienced item as a feature bundle.
    concept_formation_observe/2,
    % concept_formation_induce/2: induce concepts from the observed items by seed clustering.
    concept_formation_induce/2,
    % concept_formation_classify/3: which induced concept a feature bundle fits.
    concept_formation_classify/3
]).
% Reuse the sibling classifier for the flexible re-sort - the trial's second half, already built.
:- use_module(library(concrete_operations), [
    % concrete_operations_classify/3: sort a perceived collection by one chosen property.
    concrete_operations_classify/3
]).
% Reuse the record family so the formed categories can be owned on the record.
:- use_module(library(other_minds), [
    % other_minds_individual_record/3: mint the forming mind as a token individual.
    other_minds_individual_record/3,
    % other_minds_content_record/5: mint the conclusion as a state assertion.
    other_minds_content_record/5
]).
% Reuse the provenance scale so the conclusion is graded honestly.
:- use_module(library(self_provenance), [
    % self_provenance_assertion/5: assert about the conclusion, graded and weighted.
    self_provenance_assertion/5
]).
% Use the list library.
:- use_module(library(lists)).

/*  category_formation — the Rung Three classification trial, completed.

    THE BOOK'S CLAIM. The guiding book's classification trial asks for two
    halves: "sort a set of perceived objects into categories the System has
    formed from experience, and re-sort them by a different property on
    request, demonstrating flexible categorisation." Slice 21 built the second
    half (the flexible re-sort, in concrete_operations) and honestly deferred
    the first. This pack is the first half: the categories are FORMED by the
    mind, from the stream of its own experience, never handed down.

    THE ONE RULE THIS PACK ADDS: none. It is a thin reuse wrapper, the house
    pattern for realizing a faculty without raising an eleventh component. The
    inducer is PrologAI's concept_formation engine (observe feature bundles,
    seed-cluster them, coin a concept for every group of two or more items
    whose shared core meets a floor), reused unmodified. The flexible re-sort
    is the sibling concrete_operations classifier, reused unmodified. This
    pack only converts shapes, refuses malformed input by name, and renames
    the engine's terse concept identifiers (con_1, con_2, ...) to whole words
    (formed_category_1, formed_category_2, ...), per the Whole-Word System.

    HOW A CATEGORY IS FORMED. An experience is experience(Name, Properties),
    the Properties a list of Property-Value pairs, each key appearing once -
    the same shape the sibling classifier reads, so one collection serves both
    halves of the trial. Each learning episode resets the engine, observes
    every experience, induces with the caller's shared-pair floor, and resets
    again. The episode OWNS the engine's store: whatever any earlier caller
    left there is cleared at both ends, so nothing leaks INTO an episode and
    nothing leaks OUT of one - a bystander using the engine directly must not
    expect its items to survive a learning episode. A category is
    category(Identifier, DefiningCore, Members) - the core is the intension
    the members share, the members are the extension that earned it. The
    ordinals in the identifiers follow the engine's own deterministic seeding
    order, which takes experiences by sorted name - so renaming an experience
    can renumber the categories, deterministically.

    HONESTY AT THE EDGES. An object fitting no formed category is reported in
    a group named outside_every_category, never forced into a category it does
    not match; an object fitting several formed categories goes to the FIRST
    fitting category in the list, a deliberate deterministic tie-break; a lone
    experience forms no category (a category needs at least two members); and
    the re-sort's refusals surface under the reused classifier's own names
    (concrete_operations_unclassifiable and kin), because the re-sort IS that
    classifier - reuse, not reimplementation. The sorter takes hand-built
    categories only on the learner's own terms: a category with an empty or
    unsorted core, the reserved sentinel name, or a duplicated identifier is
    refused by name, because each of those would silently drive the sort off
    this header's claims.

    ON THE RECORD. The formation conclusion is owned BY FORMING IT: the record
    predicate enacts a learning episode itself and mints what that episode
    formed, so a hand-written category list cannot be owned as if it had been
    learned. The record is minted content-addressed through other_minds and
    graded "derivation" at weight 0.9 through self_provenance - the mind
    induced its categories from experience; it did not observe them ready-made.
*/

% category_formation_learn(+Experiences, +MinimumShared, -Categories): form categories from experience.
category_formation_learn(Experiences, MinimumShared, Categories) :-
    % The collection must arrive as a proper list before anything reads it.
    category_formation_check_collection(Experiences),
    % Every experience must be well-formed before any of them is observed.
    category_formation_check_experiences(Experiences),
    % Two experiences under one name would silently overwrite each other in the engine's store.
    category_formation_check_distinct_names(Experiences),
    % The shared-pair floor must be a positive integer.
    category_formation_check_minimum(MinimumShared),
    % Start the engine from a clean store, so no earlier episode leaks into this one.
    concept_formation_reset,
    % Observe every experience, each property-value bundle becoming one item.
    forall(member(experience(Name, Properties), Experiences),
           concept_formation_observe(Name, Properties)),
    % Induce the concepts by seed clustering over the observed items.
    concept_formation_induce(MinimumShared, Concepts),
    % Leave the engine's store as clean as it was found - the wrapper is a pure facade.
    concept_formation_reset,
    % Rename each induced concept's terse identifier to a whole-word category identifier.
    maplist(category_formation_rename_concept, Concepts, Categories).

% category_formation_rename_concept(+Concept, -Category): con_N becomes formed_category_N.
category_formation_rename_concept(concept(ConceptIdentifier, DefiningCore, Members),
                                  category(CategoryIdentifier, DefiningCore, Members)) :-
    % Strip the engine's terse prefix to recover the ordinal.
    atom_concat(con_, Ordinal, ConceptIdentifier),
    % Commit once the engine's naming scheme is recognized.
    !,
    % Rebuild the identifier from whole words, per the Whole-Word System.
    atom_concat(formed_category_, Ordinal, CategoryIdentifier).
% An identifier the wrapper cannot rename is refused by name, never a silent failure - if the
% engine's naming scheme ever changes, this boundary says so out loud.
category_formation_rename_concept(concept(ConceptIdentifier, _, _), _) :-
    % Refuse the unrecognized identifier rather than failing quietly.
    throw(error(category_formation_unrenamable_concept(ConceptIdentifier),
                context(category_formation_learn/3, "the reused engine minted an identifier outside its known naming scheme"))).

% category_formation_sort(+Experiences, +Categories, -Groups): sort objects into the mind's own categories.
category_formation_sort(Experiences, Categories, Groups) :-
    % The collection must arrive as a proper list before anything reads it.
    category_formation_check_collection(Experiences),
    % Every experience must be well-formed before any of them is classified.
    category_formation_check_experiences(Experiences),
    % Two experiences under one name would make the grouping ambiguous.
    category_formation_check_distinct_names(Experiences),
    % Every category must be well-formed before any object is matched against it.
    category_formation_check_categories(Categories),
    % Convert the categories back to the engine's concept shape, so its classifier can be reused.
    findall(concept(Identifier, DefiningCore, Members),
            member(category(Identifier, DefiningCore, Members), Categories),
            Concepts),
    % Decide, for each experience, which formed category it falls into - or none.
    findall(Name-Fate,
            (   member(experience(Name, Properties), Experiences),
                category_formation_fate(Properties, Concepts, Fate)
            ),
            Fates),
    % One group per formed category, members in the collection's own order.
    findall(group(Identifier, Members),
            (   member(category(Identifier, _, _), Categories),
                findall(Name, member(Name-Identifier, Fates), Members)
            ),
            CategoryGroups),
    % The objects fitting no category are gathered honestly, never forced into one.
    findall(Name, member(Name-outside_every_category, Fates), Outside),
    % The outside group appears only when it has members.
    (   Outside == []
    ->  Groups = CategoryGroups
    ;   append(CategoryGroups, [group(outside_every_category, Outside)], Groups)
    ).

% category_formation_fate(+Properties, +Concepts, -Fate): the first fitting category, or outside.
category_formation_fate(Properties, Concepts, Fate) :-
    % Reuse the engine's own classifier: the first concept whose defining core the bundle carries.
    (   concept_formation_classify(Properties, Concepts, Identifier)
    ->  Fate = Identifier
    ;   Fate = outside_every_category
    ).

% category_formation_resort(+Experiences, +Property, -Groups): the flexible re-sort on request.
category_formation_resort(Experiences, Property, Groups) :-
    % The collection must arrive as a proper list before anything reads it.
    category_formation_check_collection(Experiences),
    % Every experience must be well-formed before any of them is converted.
    category_formation_check_experiences(Experiences),
    % Two experiences under one name would make the re-sorted grouping ambiguous too.
    category_formation_check_distinct_names(Experiences),
    % Convert each experience to the sibling classifier's own object shape.
    findall(object(Name, Properties),
            member(experience(Name, Properties), Experiences),
            Objects),
    % The re-sort IS the sibling classifier, reused unmodified - its refusals surface by its names.
    concrete_operations_classify(Objects, Property, Groups).

% category_formation_check_collection(+Experiences): the collection is a proper list.
category_formation_check_collection(Experiences) :-
    % A proper list needs no further checking.
    (   is_list(Experiences)
    ->  true
    ;   throw(error(category_formation_not_a_collection(Experiences),
                    context(category_formation_learn/3, "the experiences must arrive as a proper list")))
    ).

% category_formation_check_experiences(+Experiences): every term is a well-formed experience/2.
category_formation_check_experiences(Experiences) :-
    % Walk every term and check its shape.
    forall(member(Term, Experiences), category_formation_check_experience(Term)).

% category_formation_check_experience(+Term): one term is a well-formed, fully-built experience/2.
category_formation_check_experience(experience(Name, Properties)) :-
    % The experience is named by an atom.
    atom(Name),
    % The properties are a proper list.
    is_list(Properties),
    % Every property is a fully-instantiated Property-Value pair - a half-built value would
    % unify its way into defining cores it does not truly share.
    forall(member(Pair, Properties), (nonvar(Pair), Pair = Property-Value, atom(Property), ground(Value))),
    % No property key appears twice - two values under one key would let the trial's two halves
    % contradict each other on the same collection, so the duplicate is refused by its own name.
    findall(Property, member(Property-_, Properties), Keys),
    % Sort without deduplication, so a duplicate key lands beside its twin.
    msort(Keys, SortedKeys),
    % Refuse the first duplicated key, if any.
    (   append(_, [DuplicateKey, DuplicateKey|_], SortedKeys)
    ->  throw(error(category_formation_duplicate_property(Name, DuplicateKey),
                    context(category_formation_learn/3, "one experience cannot carry two values under one property key")))
    ;   true
    ),
    % A well-formed experience needs no further checking.
    !.
% Anything else is refused by name, never silently skipped.
category_formation_check_experience(Term) :-
    % Refuse the malformed term rather than guessing at its meaning.
    throw(error(category_formation_malformed_experience(Term),
                context(category_formation_learn/3, "every experience must be experience(Name, PropertyValuePairs) with every value fully instantiated"))).

% category_formation_check_distinct_names(+Experiences): no two experiences share a name.
category_formation_check_distinct_names(Experiences) :-
    % Collect the names in order.
    findall(Name, member(experience(Name, _), Experiences), Names),
    % Sort without deduplication, so a duplicate lands beside its twin.
    msort(Names, Sorted),
    % Refuse the first duplicated name, if any.
    (   append(_, [Duplicate, Duplicate|_], Sorted)
    ->  throw(error(category_formation_duplicate_experience(Duplicate),
                    context(category_formation_learn/3, "two experiences under one name would overwrite each other")))
    ;   true
    ).

% category_formation_check_minimum(+MinimumShared): the shared-pair floor is a positive integer.
category_formation_check_minimum(MinimumShared) :-
    % A positive integer needs no further checking.
    (   integer(MinimumShared),
        MinimumShared >= 1
    ->  true
    ;   throw(error(category_formation_bad_minimum(MinimumShared),
                    context(category_formation_learn/3, "the shared-pair floor must be a positive integer")))
    ).

% category_formation_check_categories(+Categories): every term is a well-formed category/3.
category_formation_check_categories(Categories) :-
    % The categories must themselves arrive as a proper list.
    (   is_list(Categories)
    ->  true
    ;   throw(error(category_formation_not_a_collection(Categories),
                    context(category_formation_sort/3, "the categories must arrive as a proper list")))
    ),
    % Walk every term and check its shape.
    forall(member(Term, Categories), category_formation_check_category(Term)),
    % Collect the category identifiers in order.
    findall(Identifier, member(category(Identifier, _, _), Categories), Identifiers),
    % Sort without deduplication, so a duplicate lands beside its twin.
    msort(Identifiers, SortedIdentifiers),
    % Two categories under one identifier would duplicate a group and double-count its members.
    (   append(_, [Duplicate, Duplicate|_], SortedIdentifiers)
    ->  throw(error(category_formation_duplicate_category(Duplicate),
                    context(category_formation_sort/3, "two categories under one identifier would double-count their members")))
    ;   true
    ).

% category_formation_check_category(+Term): one term is a well-formed category/3.
category_formation_check_category(category(Identifier, DefiningCore, Members)) :-
    % The category is named by an atom.
    atom(Identifier),
    % The reserved sentinel name cannot name a category - it would collide with the honest
    % outside group and double-count its members.
    Identifier \== outside_every_category,
    % The defining core is a proper list.
    is_list(DefiningCore),
    % Every pair of the core is fully instantiated.
    ground(DefiningCore),
    % A category defined by nothing would swallow every object; an empty core is refused.
    DefiningCore \== [],
    % The matcher reads the core as an ordered set, so the core must BE the duplicate-free
    % sorted set the learner mints - an unsorted core would silently misclassify, never match.
    sort(DefiningCore, DefiningCore),
    % The members are a list of atoms.
    is_list(Members),
    % A well-formed category needs no further checking.
    !.
% Anything else is refused by name, never silently skipped.
category_formation_check_category(Term) :-
    % Refuse the malformed term rather than matching against it.
    throw(error(category_formation_malformed_category(Term),
                context(category_formation_sort/3, "every category must be category(Identifier, DefiningCore, Members)"))).

% category_formation_record(+Experiences, +MinimumShared, +Instant, -Record): own a conclusion
% BY FORMING IT. The record is minted from a learning episode this predicate itself enacts, so a
% hand-written category list cannot be owned as if it had been formed - the claim and the record
% cannot come apart, the lesson slice 21's review taught.
category_formation_record(Experiences, MinimumShared, Instant, Record) :-
    % Form the categories from the experiences, right here - the conclusion is enacted, not quoted.
    category_formation_learn(Experiences, MinimumShared, Categories),
    % Render the formed categories deterministically as the record's content.
    format(string(ConclusionText), "~w", [Categories]),
    % The forming mind is minted as a token individual - the holder of its own conclusion.
    other_minds_individual_record("agent", "konnectome", Individual),
    % Read the forming mind's content-addressed identifier.
    get_dict(id, Individual, HolderIdentifier),
    % The conclusion is minted as a state assertion carrying its formed content.
    other_minds_content_record(HolderIdentifier, "categories_formed_from_experience",
                               ConclusionText, Instant, Record).

% category_formation_stance(+Record, +Instant, -Stance): the mind stands behind its conclusion.
% The derivation grade fits an INDUCED conclusion exactly: the mind formed its categories from
% experience by a named clustering; it did not observe them ready-made. Grading an induction as
% observation would overstate the evidence.
category_formation_stance(Record, Instant, Stance) :-
    % Read the conclusion's content-addressed identifier.
    get_dict(id, Record, Identifier),
    % The stance is graded derivation: induced from experience, owned at a strong weight.
    self_provenance_assertion(Identifier, "derivation", 0.9, Instant, Stance).
