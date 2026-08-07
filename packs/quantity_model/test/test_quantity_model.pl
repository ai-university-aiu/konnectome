% Load the module under test from the library path.
:- use_module(library(quantity_model)).
% Load the Prolog Unit test framework.
:- use_module(library(plunit)).

% quantity_model_test_instant(-Instant): the fixed instant, so every minted record is deterministic.
quantity_model_test_instant("2026-08-07T00:00:00Z").

% Open the quantity_model test block.
:- begin_tests(quantity_model).

% A represented amount is built from individuated units plus an appearance: the units ARE the
% model of the world; the appearance is only how the world currently looks.
test(representation_carries_individuated_units) :-
    % Represent three units of water in a short wide glass.
    quantity_model_represent(3, glass(short_wide), Model),
    % The model holds three named units and the given appearance.
    assertion(Model == represented_amount([unit(1), unit(2), unit(3)], glass(short_wide))).

% Measuring reads the model - it counts the units the model actually holds.
test(measurement_reads_the_model) :-
    % Represent three units.
    quantity_model_represent(3, glass(short_wide), Model),
    % Measure the represented amount.
    quantity_model_measure(Model, Quantity),
    % Three units measure three.
    assertion(Quantity =:= 3).

% THE BOOK'S OWN TRIAL: the same water in a taller, thinner glass is still the same amount.
% The verdict comes from re-measuring the model after the pour - never from the pour's name.
test(the_taller_thinner_glass_conserves) :-
    % Represent five units of water in a short wide glass.
    quantity_model_represent(5, glass(short_wide), Before),
    % Pour the water into a taller, thinner glass.
    quantity_model_transform(Before, pour(glass(tall_thin)), After),
    % The appearance really changed.
    assertion(After = represented_amount(_, glass(tall_thin))),
    % Compare the measured quantity before and after.
    quantity_model_conserved(Before, After, Verdict),
    % The amount is unchanged: five units measured before, five measured after.
    assertion(Verdict == conserved(5)).

% A pour carries every individual unit across - the model shows WHY the amount is conserved.
test(a_pour_carries_every_unit) :-
    % Represent five units.
    quantity_model_represent(5, glass(short_wide), Before),
    % Pour into the taller glass.
    quantity_model_transform(Before, pour(glass(tall_thin)), After),
    % Read the unit list before the pour.
    Before = represented_amount(UnitsBefore, _),
    % Read the unit list after the pour.
    After = represented_amount(UnitsAfter, _),
    % The very same units, one by one.
    assertion(UnitsBefore == UnitsAfter).

% The other appearance-only transformations also conserve, each judged by measurement.
test(spreading_reshaping_rearranging_conserve) :-
    % Represent four units of clay in a ball.
    quantity_model_represent(4, lump(ball_shaped), Clay),
    % Spread the clay flat.
    quantity_model_transform(Clay, spread(lump(flat_and_wide)), Spread),
    % Reshape it into a sausage.
    quantity_model_transform(Spread, reshape(lump(sausage_shaped)), Reshaped),
    % Rearrange it into three small heaps... of the same clay.
    quantity_model_transform(Reshaped, rearrange(lump(three_small_heaps)), Rearranged),
    % Every step conserved the measured amount.
    quantity_model_conserved(Clay, Rearranged, Verdict),
    % Four units in, four units out.
    assertion(Verdict == conserved(4)).

% A real addition changes the measured amount, and the verdict says so honestly.
test(adding_changes_the_measured_amount) :-
    % Represent three units.
    quantity_model_represent(3, bowl(round), Before),
    % Add two more units.
    quantity_model_transform(Before, add(2), After),
    % Compare the measurements.
    quantity_model_conserved(Before, After, Verdict),
    % Three before, five after.
    assertion(Verdict == changed(3, 5)).

% Added units take fresh names beyond the highest existing one - no unit is ever counted twice.
test(added_units_take_fresh_names) :-
    % Represent three units.
    quantity_model_represent(3, bowl(round), Before),
    % Add two more.
    quantity_model_transform(Before, add(2), After),
    % Read the unit list after the addition.
    After = represented_amount(Units, _),
    % The two newcomers continue the numbering.
    assertion(Units == [unit(1), unit(2), unit(3), unit(4), unit(5)]).

% A real removal changes the measured amount, and the verdict says so honestly.
test(removing_changes_the_measured_amount) :-
    % Represent three units.
    quantity_model_represent(3, bowl(round), Before),
    % Remove one unit.
    quantity_model_transform(Before, remove(1), After),
    % Compare the measurements.
    quantity_model_conserved(Before, After, Verdict),
    % Three before, two after.
    assertion(Verdict == changed(3, 2)).

% THE SURFACE-VERSUS-MODEL TEST: a transformation that CALLS itself a pour but spills a unit is
% judged changed, because the verdict reads the model, not the transformation's name. This is the
% exact upgrade over a closed name-list: the name says appearance-only; the world says otherwise;
% the model sides with the world.
test(a_lossy_pour_is_judged_by_the_model_not_the_name) :-
    % Represent five units.
    quantity_model_represent(5, glass(short_wide), Before),
    % Pour into the taller glass, spilling one unit on the way.
    quantity_model_transform(Before, pour_losing(glass(tall_thin), 1), After),
    % The appearance changed just as a clean pour's would.
    assertion(After = represented_amount(_, glass(tall_thin))),
    % Compare the measurements.
    quantity_model_conserved(Before, After, Verdict),
    % The model kept the truth: five before, four after.
    assertion(Verdict == changed(5, 4)).

% Nothing is a valid amount too: zero units pour without loss and conserve at zero.
test(zero_units_conserve_at_zero) :-
    % Represent an empty glass.
    quantity_model_represent(0, glass(short_wide), Before),
    % Pour the nothing into the taller glass.
    quantity_model_transform(Before, pour(glass(tall_thin)), After),
    % Compare the measurements.
    quantity_model_conserved(Before, After, Verdict),
    % Zero before, zero after.
    assertion(Verdict == conserved(0)).

% The trial predicate composes transform and comparison, and returns both verdict and outcome
% model - verified here against the manual composition, independently.
test(the_trial_composes_transform_and_comparison) :-
    % Represent five units.
    quantity_model_represent(5, glass(short_wide), Model),
    % Run the whole trial in one step.
    quantity_model_trial(Model, pour(glass(tall_thin)), Verdict, After),
    % Recompose the same trial's transformation by hand.
    quantity_model_transform(Model, pour(glass(tall_thin)), ManualAfter),
    % Recompose the same trial's comparison by hand.
    quantity_model_conserved(Model, ManualAfter, ManualVerdict),
    % The trial and the manual composition agree exactly.
    assertion(Verdict == ManualVerdict),
    % And the outcome models agree exactly.
    assertion(After == ManualAfter).

% Representing the same amount twice yields byte-identical models - determinism.
test(representation_is_deterministic) :-
    % Represent five units once.
    quantity_model_represent(5, glass(short_wide), First),
    % Represent the same five units again.
    quantity_model_represent(5, glass(short_wide), Second),
    % The two models are identical.
    assertion(First == Second).

% A negative unit count is refused by name - there is no such amount.
test(negative_amount_refused, throws(error(quantity_model_bad_amount(-1), _))) :-
    % Represent minus one unit.
    quantity_model_represent(-1, glass(short_wide), _Model).

% A non-integer unit count is refused by name.
test(non_integer_amount_refused, throws(error(quantity_model_bad_amount(some), _))) :-
    % Represent a vague amount.
    quantity_model_represent(some, glass(short_wide), _Model).

% A half-built appearance is refused by name - the model represents a world, not a template.
test(half_built_appearance_refused, throws(error(quantity_model_malformed_appearance(glass(_)), _))) :-
    % The glass's shape is left unbound.
    quantity_model_represent(3, glass(_Unbound), _Model).

% Removing more units than the model holds is refused by name, never silently clamped.
test(removing_more_than_present_refused, throws(error(quantity_model_removed_more_than_present(3, 5), _))) :-
    % Represent three units.
    quantity_model_represent(3, bowl(round), Model),
    % Try to remove five.
    quantity_model_transform(Model, remove(5), _After).

% Spilling more units than the model holds is refused by the same name.
test(spilling_more_than_present_refused, throws(error(quantity_model_removed_more_than_present(3, 4), _))) :-
    % Represent three units.
    quantity_model_represent(3, glass(short_wide), Model),
    % Try to spill four on the way to the taller glass.
    quantity_model_transform(Model, pour_losing(glass(tall_thin), 4), _After).

% A lossy pour that loses nothing is a plain pour wearing the wrong name - refused by name so the
% transformation vocabulary stays honest.
test(lossless_lossy_pour_refused, throws(error(quantity_model_nothing_lost(pour_losing(glass(tall_thin), 0)), _))) :-
    % Represent three units.
    quantity_model_represent(3, glass(short_wide), Model),
    % A pour_losing that spills zero units.
    quantity_model_transform(Model, pour_losing(glass(tall_thin), 0), _After).

% A transformation the model does not know is refused by name, never guessed at.
test(unknown_transformation_refused, throws(error(quantity_model_unknown_transformation(evaporate), _))) :-
    % Represent three units.
    quantity_model_represent(3, glass(short_wide), Model),
    % Evaporation is not in the model's vocabulary.
    quantity_model_transform(Model, evaporate, _After).

% A term that is not a represented amount is refused by name wherever a model is expected.
test(malformed_model_refused_by_transform, throws(error(quantity_model_malformed_amount(not_a_model), _))) :-
    % Transform something that is not a model.
    quantity_model_transform(not_a_model, pour(glass(tall_thin)), _After).

% The comparison likewise refuses a non-model by name.
test(malformed_model_refused_by_comparison, throws(error(quantity_model_malformed_amount(nonsense), _))) :-
    % Represent a real model for one side.
    quantity_model_represent(3, glass(short_wide), Model),
    % Compare it against nonsense.
    quantity_model_conserved(Model, nonsense, _Verdict).

% The conservation verdict is owned BY ENACTING THE TRIAL: the record predicate runs the trial
% itself, and the mind's stance on the measured outcome is graded derivation - the mind measured
% and compared; it did not observe the verdict ready-made.
test(conservation_stance_is_graded_derivation) :-
    % The fixed instant stamps the record.
    quantity_model_test_instant(Instant),
    % Represent the book's five units of water.
    quantity_model_represent(5, glass(short_wide), Model),
    % Own the verdict by enacting the pour trial.
    quantity_model_record(Model, pour(glass(tall_thin)), Instant, Record),
    % The record carries what the trial actually measured - verified against an independent run.
    quantity_model_trial(Model, pour(glass(tall_thin)), Verdict, _After),
    % Render the independent verdict the same way the record predicate does.
    format(string(ExpectedText), "~w", [Verdict]),
    % Read the record's carried content.
    get_dict(value, Record, Value),
    % The record's content is the measured verdict, byte for byte.
    assertion(Value == ExpectedText),
    % The mind grades its own verdict.
    quantity_model_stance(Record, Instant, Stance),
    % The stance is graded derivation, never observation.
    get_dict(evidence_type, Stance, Grade),
    % The grade is derivation.
    assertion(Grade == "derivation"),
    % The stance is about the verdict it grades.
    get_dict(about, Stance, About),
    % Read the verdict's identifier.
    get_dict(id, Record, RecordIdentifier),
    % The stance names the verdict, byte for byte.
    assertion(About == RecordIdentifier).

% The owned verdict is content-addressed: the same trial, enacted twice, mints the same identifier.
test(owned_verdict_is_reproducible) :-
    % The fixed instant stamps both tellings.
    quantity_model_test_instant(Instant),
    % Represent the same five units for both trials.
    quantity_model_represent(5, glass(short_wide), Model),
    % Enact and own the trial once.
    quantity_model_record(Model, pour(glass(tall_thin)), Instant, First),
    % Enact and own the identical trial again.
    quantity_model_record(Model, pour(glass(tall_thin)), Instant, Second),
    % Read the first identifier.
    get_dict(id, First, FirstIdentifier),
    % Read the second identifier.
    get_dict(id, Second, SecondIdentifier),
    % Content-addressing makes the two identifiers identical.
    assertion(FirstIdentifier == SecondIdentifier).

% A refused transformation poisons the record path too: the record is only mintable by a trial,
% so the trial's own refusals guard it.
test(record_refuses_what_the_trial_refuses, throws(error(quantity_model_unknown_transformation(evaporate), _))) :-
    % The fixed instant stamps nothing, because the trial refuses first.
    quantity_model_test_instant(Instant),
    % Represent three units.
    quantity_model_represent(3, glass(short_wide), Model),
    % Try to own a trial the model cannot enact.
    quantity_model_record(Model, evaporate, Instant, _Record).

% PINNED FROM REVIEW: a hand-built model with one unit counted twice is refused, not measured -
% individuation is the invariant the whole model rests on.
test(duplicate_unit_names_refused, throws(error(quantity_model_malformed_amount(represented_amount([unit(1), unit(1)], glass(g))), _))) :-
    % Measure a model whose two units share one name.
    quantity_model_measure(represented_amount([unit(1), unit(1)], glass(g)), _Quantity).

% PINNED FROM REVIEW: an unbound transformation is unknown, not a template that unifies into a pour.
test(unbound_transformation_refused, throws(error(quantity_model_unknown_transformation(_), _))) :-
    % Represent three units.
    quantity_model_represent(3, glass(short_wide), Model),
    % Transform by an unbound variable.
    quantity_model_transform(Model, _Unbound, _After).

% PINNED FROM REVIEW: a minus-one spill would GAIN a unit; it is refused as a bad amount, not
% waved through as a pour that lost nothing.
test(negative_spill_refused, throws(error(quantity_model_bad_amount(-1), _))) :-
    % Represent three units.
    quantity_model_represent(3, glass(short_wide), Model),
    % A pour that claims to spill minus one unit.
    quantity_model_transform(Model, pour_losing(glass(tall_thin), -1), _After).

% PINNED FROM REVIEW: adding to an empty model numbers its newcomers from one.
test(adding_to_an_empty_model_numbers_from_one) :-
    % Represent an empty bowl.
    quantity_model_represent(0, bowl(round), Empty),
    % Add two units to it.
    quantity_model_transform(Empty, add(2), After),
    % The newcomers are numbered from one.
    assertion(After == represented_amount([unit(1), unit(2)], bowl(round))).

% PINNED FROM REVIEW, stated as the contract it is: conserved/3 compares by measurement alone
% and does not know what happened between its two models - two unrelated models of equal count
% compare as conserved. The TRIAL and the RECORD are the predicates that tie a verdict to an
% enacted transformation; this test pins the boundary so no reader mistakes it.
test(comparison_alone_does_not_certify_a_trial) :-
    % Five units of water.
    quantity_model_represent(5, glass(short_wide), Water),
    % Five utterly unrelated units of sand.
    quantity_model_represent(5, heap(sand), Sand),
    % Comparison by measurement alone calls them conserved - that is all it claims.
    quantity_model_conserved(Water, Sand, Verdict),
    % The verdict is the measured equality, nothing more.
    assertion(Verdict == conserved(5)).

% Close the quantity_model test block.
:- end_tests(quantity_model).
