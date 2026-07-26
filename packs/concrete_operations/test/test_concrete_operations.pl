% Load the module under test from the library path.
:- use_module(library(concrete_operations)).
% Load the Prolog Unit test framework.
:- use_module(library(plunit)).

% concrete_operations_test_instant(-Instant): the fixed instant, so every minted record is deterministic.
concrete_operations_test_instant("2026-07-26T00:00:00Z").

% concrete_operations_test_tower(-OnFacts): the book's own smoke-test tower - a block on a cup on a table.
concrete_operations_test_tower([on(block, cup), on(cup, table)]).

% concrete_operations_test_objects(-Objects): a small perceived collection with two sortable properties each.
concrete_operations_test_objects([
    % A red round apple.
    object(apple, [color-red, shape-round, size-3]),
    % A red square brick.
    object(brick, [color-red, shape-square, size-6]),
    % A green round pea.
    object(pea, [color-green, shape-round, size-1])
]).

% concrete_operations_test_diamond_fact(+Level, -Fact): one support fact of the diamond lattice.
% The level rests on its left pillar.
concrete_operations_test_diamond_fact(Level, on(LevelName, LeftPillar)) :-
    % Name this level.
    atom_concat(level_, Level, LevelName),
    % Name its left pillar.
    atom_concat(left_, Level, LeftPillar).
% The level rests on its right pillar too.
concrete_operations_test_diamond_fact(Level, on(LevelName, RightPillar)) :-
    % Name this level.
    atom_concat(level_, Level, LevelName),
    % Name its right pillar.
    atom_concat(right_, Level, RightPillar).
% The left pillar rests on the next level down.
concrete_operations_test_diamond_fact(Level, on(LeftPillar, NextLevelName)) :-
    % Name the left pillar.
    atom_concat(left_, Level, LeftPillar),
    % The next level is one deeper.
    NextLevel is Level + 1,
    % Name the next level.
    atom_concat(level_, NextLevel, NextLevelName).
% The right pillar rests on the next level down.
concrete_operations_test_diamond_fact(Level, on(RightPillar, NextLevelName)) :-
    % Name the right pillar.
    atom_concat(right_, Level, RightPillar),
    % The next level is one deeper.
    NextLevel is Level + 1,
    % Name the next level.
    atom_concat(level_, NextLevel, NextLevelName).

% Open the concrete_operations test block.
:- begin_tests(concrete_operations).

% THE SMOKE TEST OF RUNG THREE, exactly as the book states it: the block is on the cup,
% the cup is on the table, therefore the block is above the table - with every step shown.
test(block_above_table_is_derived_with_steps_shown) :-
    % The book's tower: a block on a cup on a table.
    concrete_operations_test_tower(Tower),
    % Derive that the block stands above the table.
    concrete_operations_above(Tower, block, table, Steps),
    % Every derivation step is shown, in order, as a named, watchable operation.
    assertion(Steps == [
        step(resting_is_above, [on(block, cup)], above(block, cup)),
        step(resting_is_above, [on(cup, table)], above(cup, table)),
        step(transitive_chain, [above(block, cup), above(cup, table)], above(block, table))
    ]).

% Every step of a derivation is a named operation carrying its own inputs - nothing is an opaque leap.
test(every_step_is_named_and_carries_its_inputs) :-
    % The book's tower.
    concrete_operations_test_tower(Tower),
    % Derive the smoke-test conclusion.
    concrete_operations_above(Tower, block, table, Steps),
    % Each step is a step/3 term: a name, the facts it consumed, and the fact it produced.
    forall(member(Step, Steps), (
        % The step has the named shape.
        assertion(Step = step(_, _, _)),
        % Read the step's parts for the checks below - bindings made inside an assertion do not escape it.
        Step = step(Name, Inputs, _Output),
        % The operation name is a whole-word atom.
        assertion(atom(Name)),
        % The step consumed at least one input fact.
        assertion(Inputs = [_ | _])
    )).

% A taller tower still derives, one resting step per storey plus the chains.
test(four_storey_tower_derives_top_above_ground) :-
    % A four-storey tower.
    concrete_operations_above([on(a, b), on(b, c), on(c, d)], a, d, Steps),
    % The final step concludes the queried fact.
    last(Steps, step(transitive_chain, _, above(a, d))).

% A fact that does not follow is not derived - the deriver never invents support.
test(underived_fact_fails_cleanly, [fail]) :-
    % The book's tower.
    concrete_operations_test_tower(Tower),
    % The table is not above the block; the derivation must fail, not fabricate.
    concrete_operations_above(Tower, table, block, _Steps).

% A support cycle is a physical impossibility and is refused by name.
test(cyclic_support_is_refused, [throws(error(concrete_operations_cyclic_support(_), _))]) :-
    % Two objects each resting on the other cannot exist.
    concrete_operations_above([on(a, b), on(b, a)], a, b, _Steps).

% A malformed support fact is refused by name, never silently skipped.
test(malformed_support_fact_is_refused, [throws(error(concrete_operations_malformed_support(_), _))]) :-
    % The second fact is not an on/2 support fact.
    concrete_operations_above([on(a, b), beside(b, c)], a, c, _Steps).

% A support collection that is not a list at all is refused by name.
test(non_list_support_collection_is_refused, [throws(error(concrete_operations_malformed_collection(_), _))]) :-
    % A bare fact is not a collection of facts.
    concrete_operations_above(on(a, b), a, b, _Steps).

% A support collection with a malformed tail is refused by name, never half-read.
test(improper_support_list_is_refused, [throws(error(concrete_operations_malformed_collection(_), _))]) :-
    % The list ends in junk instead of an empty tail.
    concrete_operations_above([on(a, b) | junk], a, b, _Steps).

% A wide lattice of shared supports - many roads down through forty diamond pairs - is
% checked and derived without the walking multiplying road by road.
test(diamond_support_lattice_derives_quickly) :-
    % Build forty stacked diamonds: each level rests on two pillars that share the next level.
    numlist(0, 39, Levels),
    % Each level contributes three support facts: onto the left pillar, the right pillar, and down.
    findall(Fact,
            (   member(Level, Levels),
                concrete_operations_test_diamond_fact(Level, Fact)
            ),
            Facts),
    % The top of the lattice stands above its very bottom, and the answer arrives at once.
    concrete_operations_above(Facts, level_0, level_40, Steps),
    % The final step concludes the queried fact.
    last(Steps, step(transitive_chain, _, above(level_0, level_40))).

% Classification: the collection sorts into groups by color.
test(objects_classify_by_color) :-
    % The perceived collection.
    concrete_operations_test_objects(Objects),
    % Sort the collection by color.
    concrete_operations_classify(Objects, color, Groups),
    % Green holds the pea; red holds the apple and the brick; groups are in deterministic order.
    assertion(Groups == [group(green, [pea]), group(red, [apple, brick])]).

% Flexible re-classification: the SAME objects re-sort by a different property.
test(same_objects_reclassify_by_shape) :-
    % The same perceived collection.
    concrete_operations_test_objects(Objects),
    % Re-sort the collection by shape instead.
    concrete_operations_classify(Objects, shape, Groups),
    % Round holds the apple and the pea; square holds the brick.
    assertion(Groups == [group(round, [apple, pea]), group(square, [brick])]).

% An object missing the sorting property is refused by name.
test(unclassifiable_object_is_refused, [throws(error(concrete_operations_unclassifiable(stone, color), _))]) :-
    % The stone carries no color property.
    concrete_operations_classify([object(stone, [size-9])], color, _Groups).

% An object whose property value is unbound is refused by name - an unbound value would
% unify into every group and silently poison the sorting.
test(unbound_property_value_is_refused, [throws(error(concrete_operations_unclassifiable(ghost, color), _))]) :-
    % The ghost's color is an unbound variable.
    concrete_operations_classify([object(ghost, [color-_]), object(apple, [color-red])], color, _Groups).

% An object collection that is not a list at all is refused by name.
test(non_list_object_collection_is_refused, [throws(error(concrete_operations_malformed_collection(_), _))]) :-
    % A bare atom is not a collection of objects.
    concrete_operations_classify(not_a_list, color, _Groups).

% A term that is not an object at all is refused by name, never silently skipped.
test(malformed_object_is_refused, [throws(error(concrete_operations_malformed_object(_), _))]) :-
    % The second term is not an object/2.
    concrete_operations_classify([object(apple, [color-red]), pebble], color, _Groups).

% Seriation: the collection orders along the size dimension, smallest first.
test(objects_seriate_by_size) :-
    % The perceived collection.
    concrete_operations_test_objects(Objects),
    % Order the collection by size.
    concrete_operations_seriate(Objects, size, Ordered),
    % The pea (one), the apple (three), the brick (six).
    assertion(Ordered == [pea, apple, brick]).

% An object whose dimension is missing or not a number is refused by name.
test(unorderable_object_is_refused, [throws(error(concrete_operations_unorderable(cloud, size), _))]) :-
    % The cloud's size is not a number.
    concrete_operations_seriate([object(cloud, [size-fluffy])], size, _Ordered).

% Conservation, exactly as the book states it: water poured into a taller, thinner
% glass changes its look, not its amount.
test(poured_water_is_conserved) :-
    % Pour two hundred units of water into the taller, thinner glass.
    concrete_operations_conserve(200, pour, Verdict),
    % The amount is unchanged, and the verdict says why: the pour changed appearance only.
    assertion(Verdict == conserved(200, appearance_only(pour))).

% Adding really does change the amount - conservation never denies a real change.
test(added_amount_is_honestly_changed) :-
    % Add fifty units to two hundred.
    concrete_operations_conserve(200, add(50), Verdict),
    % The amount honestly grew, and the verdict names the real change.
    assertion(Verdict == changed(250, amount_change(add(50)))).

% Removing more than is present is a physical impossibility and is refused by name.
test(removing_more_than_present_is_refused, [throws(error(concrete_operations_removed_more_than_present(_, _), _))]) :-
    % Three hundred units cannot leave a two-hundred-unit amount.
    concrete_operations_conserve(200, remove(300), _Verdict).

% An amount that is not a non-negative number is refused by name.
test(malformed_amount_is_refused, [throws(error(concrete_operations_malformed_amount(_), _))]) :-
    % A negative amount of water does not exist.
    concrete_operations_conserve(-5, pour, _Verdict).

% A negative addition is refused under its own name - add is a known transformation whose
% argument is malformed, never an unknown transformation.
test(negative_addition_is_refused_by_its_own_name, [throws(error(concrete_operations_malformed_change(add(-5)), _))]) :-
    % Adding minus five is a malformed addition, not an unknown kind.
    concrete_operations_conserve(200, add(-5), _Verdict).

% A negative removal is refused under its own name, for the same honest reason.
test(negative_removal_is_refused_by_its_own_name, [throws(error(concrete_operations_malformed_change(remove(-5)), _))]) :-
    % Removing minus five is a malformed removal, not an unknown kind.
    concrete_operations_conserve(200, remove(-5), _Verdict).

% A transformation the enumeration does not know is refused by name, never guessed at.
test(unknown_transformation_is_refused, [throws(error(concrete_operations_unknown_transformation(vanish), _))]) :-
    % Vanishing is not a known transformation.
    concrete_operations_conserve(200, vanish, _Verdict).

% A derived conclusion is owned on the record, and the mind's stance on it is graded derivation -
% a conclusion is reasoned, not seen, and the record says so honestly.
test(conclusion_stance_is_graded_derivation) :-
    % The fixed instant stamps the record.
    concrete_operations_test_instant(Instant),
    % Own the smoke-test conclusion on the record.
    concrete_operations_record("the_block_stands_above_the_table", "above(block, table)", Instant, Record),
    % The mind grades its own conclusion.
    concrete_operations_stance(Record, Instant, Stance),
    % The stance is graded derivation, never observation - the mind reasoned it, it did not see it.
    get_dict(evidence_type, Stance, Grade),
    % The grade is derivation.
    assertion(Grade == "derivation"),
    % The stance is about the conclusion it grades.
    get_dict(about, Stance, About),
    % Read the conclusion's identifier.
    get_dict(id, Record, RecordIdentifier),
    % The stance names the conclusion, byte for byte.
    assertion(About == RecordIdentifier).

% The owned conclusion is content-addressed: the same conclusion, told twice, mints the same identifier.
test(owned_conclusion_is_reproducible) :-
    % The fixed instant stamps both tellings.
    concrete_operations_test_instant(Instant),
    % Mint the conclusion once.
    concrete_operations_record("the_block_stands_above_the_table", "above(block, table)", Instant, First),
    % Mint the byte-identical conclusion again.
    concrete_operations_record("the_block_stands_above_the_table", "above(block, table)", Instant, Second),
    % Read the first identifier.
    get_dict(id, First, FirstIdentifier),
    % Read the second identifier.
    get_dict(id, Second, SecondIdentifier),
    % Content-addressing makes the two identifiers identical.
    assertion(FirstIdentifier == SecondIdentifier).

% Close the concrete_operations test block.
:- end_tests(concrete_operations).
