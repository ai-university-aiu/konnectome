% Declare the quantity_model module and the public interface of the represented-quantity trial.
:- module(quantity_model, [
    % quantity_model_represent/3: +UnitCount, +Appearance, -Model - build a represented amount.
    quantity_model_represent/3,
    % quantity_model_measure/2: +Model, -Quantity - measure the amount by counting the model's units.
    quantity_model_measure/2,
    % quantity_model_transform/3: +Model, +Transformation, -NewModel - act on the represented world.
    quantity_model_transform/3,
    % quantity_model_conserved/3: +ModelBefore, +ModelAfter, -Verdict - compare two models by
    % measurement alone; it does not know or check what happened between them (trial/4 does).
    quantity_model_conserved/3,
    % quantity_model_trial/4: +Model, +Transformation, -Verdict, -NewModel - one whole conservation trial.
    quantity_model_trial/4,
    % quantity_model_record/4: +Model, +Transformation, +Instant, -Record - own the verdict by
    % enacting the trial: the record is minted from a trial run here, never from quoted text.
    quantity_model_record/4,
    % quantity_model_stance/3: the mind's graded stance on its own verdict - derivation, never observation.
    quantity_model_stance/3
]).

% Reuse the record family so the conservation verdict can be owned on the record.
:- use_module(library(other_minds), [
    % other_minds_individual_record/3: mint the measuring mind as a token individual.
    other_minds_individual_record/3,
    % other_minds_content_record/5: mint the verdict as a state assertion.
    other_minds_content_record/5
]).
% Reuse the provenance scale so the verdict is graded honestly.
:- use_module(library(self_provenance), [
    % self_provenance_assertion/5: assert about the verdict, graded and weighted.
    self_provenance_assertion/5
]).
% Use the list library.
:- use_module(library(lists)).

/*  quantity_model — the Rung Three conservation trial, completed.

    THE BOOK'S CLAIM. The guiding book's conservation trial: "confirm that the
    System understands a quantity is unchanged when only its appearance
    changes - the same water in a taller, thinner glass is still the same
    amount - which is ... a direct test of whether the System models the world
    rather than its mere surface." Slice 21 built the verdict SHAPE and
    honestly deferred the model: its verdict followed from a transformation's
    NAME on a closed list, which is exactly the surface. This pack is the
    model.

    THE REPRESENTED MODEL. An amount is represented_amount(Units, Appearance):
    the Units a list of individuated unit(N) terms - the model of how much
    world there is - and the Appearance a ground descriptor of how that world
    currently looks. A transformation acts on the representation: a pour, a
    spread, a reshape, or a rearrangement replaces the appearance and carries
    every unit across, one by one; an addition mints fresh units; a removal
    takes real units away. Measurement counts the units the model holds.

    THE VERDICT IS READ FROM THE MODEL, NEVER FROM THE NAME. The conservation
    verdict compares the measured quantity before and after - it never looks
    at what the transformation was called. The proof that this is a genuine
    upgrade over the closed name-list is the lossy pour: a transformation that
    CALLS itself a pour but spills a unit is judged changed, because the model
    kept the truth the surface hid. The taller, thinner glass conserves not
    because "pour" is on a list, but because the same five units are counted
    on both sides of it.

    THE ONE RULE THIS PACK ADDS: none - it is a thin pack in the house
    pattern, adding a representation and reading it, with no update rule.
    Reuse was weighed honestly: PrologAI's quantity pack counts and groups a
    PERCEIVED collection (histograms over colors, shapes, sizes); this trial
    needs a PERSISTED representation that transformations act on, which is a
    different instrument, so the small representation is native here and the
    record family and provenance scale are reused as everywhere else.

    TWO CONTRACTS, STATED PLAINLY. quantity_model_conserved/3 compares any
    two well-formed models by measurement alone: it does not know, and cannot
    check, whether any transformation connects them - handed two unrelated
    models of equal count it will say conserved, because measurement is all it
    claims. The TRIAL is quantity_model_trial/4, which enacts the
    transformation and compares the model against its own outcome; and the
    RECORD is minted only from a trial the record predicate itself enacts, so
    a hand-written verdict cannot be owned as if it had been measured.

    ON THE RECORD. The verdict is owned by enacting the trial: minted
    content-addressed through other_minds, graded "derivation" at weight 0.9
    through self_provenance - the mind measured its own model and compared;
    it did not observe the verdict ready-made.
*/

% quantity_model_represent(+UnitCount, +Appearance, -Model): build a represented amount.
quantity_model_represent(UnitCount, Appearance, represented_amount(Units, Appearance)) :-
    % The unit count must be a whole, non-negative number - there is no other kind of amount.
    (   integer(UnitCount),
        UnitCount >= 0
    ->  true
    ;   throw(error(quantity_model_bad_amount(UnitCount),
                    context(quantity_model_represent/3, "an amount is a non-negative whole number of units")))
    ),
    % The appearance must be fully built - the model represents a world, not a template.
    quantity_model_check_appearance(Appearance, quantity_model_represent/3),
    % Individuate the units: unit(1) through unit(UnitCount), each a thing the world contains.
    quantity_model_numbers_up_to(UnitCount, Numbers),
    % Wrap each number as a named unit.
    findall(unit(Number), member(Number, Numbers), Units).

% quantity_model_numbers_up_to(+Count, -Numbers): the numbers 1..Count, or the empty list for zero.
quantity_model_numbers_up_to(0, []) :-
    % Zero units is a valid amount with nothing to number.
    !.
quantity_model_numbers_up_to(Count, Numbers) :-
    % A positive count numbers its units from one.
    numlist(1, Count, Numbers).

% quantity_model_measure(+Model, -Quantity): measure the amount by counting the model's units.
quantity_model_measure(Model, Quantity) :-
    % Only a well-formed model can be measured.
    quantity_model_check_model(Model, quantity_model_measure/2),
    % Read the unit list.
    Model = represented_amount(Units, _Appearance),
    % The quantity IS the count of units the model holds - measurement reads the model.
    length(Units, Quantity).

% quantity_model_transform(+Model, +Transformation, -NewModel): act on the represented world.
quantity_model_transform(Model, Transformation, NewModel) :-
    % Only a well-formed model can be transformed.
    quantity_model_check_model(Model, quantity_model_transform/3),
    % An unbound transformation is unknown, not a template to unify into a pour.
    (   nonvar(Transformation)
    ->  true
    ;   throw(error(quantity_model_unknown_transformation(Transformation),
                    context(quantity_model_transform/3, "a transformation must arrive fully named")))
    ),
    % Dispatch on the transformation's shape.
    quantity_model_apply(Transformation, Model, NewModel).

% A pour moves the amount into a new container: the appearance changes, every unit is carried.
quantity_model_apply(pour(NewAppearance), represented_amount(Units, _Old),
                     represented_amount(Carried, NewAppearance)) :-
    % Commit to the pour once its shape matches.
    !,
    % The new appearance must be fully built.
    quantity_model_check_appearance(NewAppearance, quantity_model_transform/3),
    % Carry every unit across, one by one - nothing is lost in a clean pour.
    maplist(quantity_model_carry_unit, Units, Carried).
% A spread flattens the amount out: the appearance changes, every unit is carried.
quantity_model_apply(spread(NewAppearance), represented_amount(Units, _Old),
                     represented_amount(Carried, NewAppearance)) :-
    % Commit to the spread once its shape matches.
    !,
    % The new appearance must be fully built.
    quantity_model_check_appearance(NewAppearance, quantity_model_transform/3),
    % Carry every unit across, one by one.
    maplist(quantity_model_carry_unit, Units, Carried).
% A reshape remoulds the amount: the appearance changes, every unit is carried.
quantity_model_apply(reshape(NewAppearance), represented_amount(Units, _Old),
                     represented_amount(Carried, NewAppearance)) :-
    % Commit to the reshape once its shape matches.
    !,
    % The new appearance must be fully built.
    quantity_model_check_appearance(NewAppearance, quantity_model_transform/3),
    % Carry every unit across, one by one.
    maplist(quantity_model_carry_unit, Units, Carried).
% A rearrangement re-lays the amount out: the appearance changes, every unit is carried.
quantity_model_apply(rearrange(NewAppearance), represented_amount(Units, _Old),
                     represented_amount(Carried, NewAppearance)) :-
    % Commit to the rearrangement once its shape matches.
    !,
    % The new appearance must be fully built.
    quantity_model_check_appearance(NewAppearance, quantity_model_transform/3),
    % Carry every unit across, one by one.
    maplist(quantity_model_carry_unit, Units, Carried).
% An addition mints fresh units beyond the highest existing name.
quantity_model_apply(add(More), represented_amount(Units, Appearance),
                     represented_amount(NewUnits, Appearance)) :-
    % Commit to the addition once its shape matches.
    !,
    % The addition must bring a positive whole number of units.
    quantity_model_check_positive(More, add(More)),
    % Find the highest existing unit name, or zero when the model is empty.
    quantity_model_highest_unit(Units, Highest),
    % Number the newcomers past the highest existing name, so no unit is ever counted twice.
    FirstFresh is Highest + 1,
    % The last newcomer's name is the highest name plus the count added.
    LastFresh is Highest + More,
    % Enumerate the fresh names.
    numlist(FirstFresh, LastFresh, FreshNumbers),
    % Wrap each fresh number as a named unit.
    findall(unit(Number), member(Number, FreshNumbers), Fresh),
    % The model now holds the old units and the newcomers.
    append(Units, Fresh, NewUnits).
% A removal takes real units away from the end of the model.
quantity_model_apply(remove(Fewer), represented_amount(Units, Appearance),
                     represented_amount(Kept, Appearance)) :-
    % Commit to the removal once its shape matches.
    !,
    % The removal must take a positive whole number of units.
    quantity_model_check_positive(Fewer, remove(Fewer)),
    % Removing more than the model holds is refused, never silently clamped.
    quantity_model_take_from_end(Units, Fewer, Kept).
% A lossy pour changes the appearance AND spills real units - named honestly as both.
quantity_model_apply(pour_losing(NewAppearance, Spilt), represented_amount(Units, _Old),
                     represented_amount(Kept, NewAppearance)) :-
    % Commit to the lossy pour once its shape matches.
    !,
    % The new appearance must be fully built.
    quantity_model_check_appearance(NewAppearance, quantity_model_transform/3),
    % The spill must be a non-negative whole number of units - a minus-one spill would gain.
    (   integer(Spilt),
        Spilt >= 0
    ->  true
    ;   throw(error(quantity_model_bad_amount(Spilt),
                    context(quantity_model_transform/3, "a spill is a non-negative whole number of units")))
    ),
    % A lossy pour that loses nothing is a plain pour wearing the wrong name - refused, so the
    % transformation vocabulary stays honest.
    (   Spilt >= 1
    ->  true
    ;   throw(error(quantity_model_nothing_lost(pour_losing(NewAppearance, Spilt)),
                    context(quantity_model_transform/3, "a pour that loses nothing is a pour; name it so")))
    ),
    % Spilling more than the model holds is refused, never silently clamped.
    quantity_model_take_from_end(Units, Spilt, Kept).
% A transformation the model does not know is refused by name, never guessed at.
quantity_model_apply(Transformation, _Model, _NewModel) :-
    % Refuse the unknown transformation rather than inventing a judgement.
    throw(error(quantity_model_unknown_transformation(Transformation),
                context(quantity_model_transform/3, "only a transformation the model can enact can be judged"))).

% quantity_model_carry_unit(+Unit, -Unit): carry one unit across a transformation, unchanged.
quantity_model_carry_unit(unit(Number), unit(Number)).

% quantity_model_highest_unit(+Units, -Highest): the highest unit name, or zero when empty.
quantity_model_highest_unit([], 0) :-
    % An empty model has no highest unit.
    !.
quantity_model_highest_unit(Units, Highest) :-
    % Read every unit's number.
    findall(Number, member(unit(Number), Units), Numbers),
    % The highest name is the maximum.
    max_list(Numbers, Highest).

% quantity_model_take_from_end(+Units, +Taken, -Kept): drop the last Taken units, or refuse.
quantity_model_take_from_end(Units, Taken, Kept) :-
    % Count what the model holds.
    length(Units, Present),
    % Taking more than is present is refused by name.
    (   Taken =< Present
    ->  true
    ;   throw(error(quantity_model_removed_more_than_present(Present, Taken),
                    context(quantity_model_transform/3, "the model cannot lose units it does not hold")))
    ),
    % Keep the front of the list, dropping the last Taken units.
    KeptCount is Present - Taken,
    length(Kept, KeptCount),
    append(Kept, _Dropped, Units).

% quantity_model_check_positive(+Count, +Transformation): the count is a positive whole number.
quantity_model_check_positive(Count, _Transformation) :-
    % A positive whole number needs no further checking.
    integer(Count),
    Count >= 1,
    !.
quantity_model_check_positive(Count, _Transformation) :-
    % Refuse anything else by name.
    throw(error(quantity_model_bad_amount(Count),
                context(quantity_model_transform/3, "an addition or removal moves a positive whole number of units"))).

% quantity_model_conserved(+ModelBefore, +ModelAfter, -Verdict): the verdict, read from the model.
quantity_model_conserved(ModelBefore, ModelAfter, Verdict) :-
    % Only well-formed models can be compared.
    quantity_model_check_model(ModelBefore, quantity_model_conserved/3),
    % The after-model is held to the same shape.
    quantity_model_check_model(ModelAfter, quantity_model_conserved/3),
    % Measure the amount before.
    quantity_model_measure(ModelBefore, QuantityBefore),
    % Measure the amount after.
    quantity_model_measure(ModelAfter, QuantityAfter),
    % The verdict compares the two measurements - it never reads a transformation's name.
    (   QuantityBefore =:= QuantityAfter
    ->  Verdict = conserved(QuantityBefore)
    ;   Verdict = changed(QuantityBefore, QuantityAfter)
    ).

% quantity_model_trial(+Model, +Transformation, -Verdict, -NewModel): one whole conservation trial.
quantity_model_trial(Model, Transformation, Verdict, NewModel) :-
    % Enact the transformation on the represented world.
    quantity_model_transform(Model, Transformation, NewModel),
    % Read the verdict off the model, before against after.
    quantity_model_conserved(Model, NewModel, Verdict).

% quantity_model_check_model(+Term, +Where): the term is a well-formed represented amount.
quantity_model_check_model(represented_amount(Units, Appearance), _Where) :-
    % The units are a proper list.
    is_list(Units),
    % Every unit is a whole-numbered unit term.
    forall(member(Unit, Units), (nonvar(Unit), Unit = unit(Number), integer(Number))),
    % Every unit bears a distinct name - individuation is the invariant the whole model rests on,
    % so a hand-built model with one unit counted twice is refused, not measured.
    findall(Number, member(unit(Number), Units), Numbers),
    % Sort without deduplication, so a duplicated name lands beside its twin.
    msort(Numbers, SortedNumbers),
    % No name may appear twice.
    \+ append(_, [DuplicateNumber, DuplicateNumber|_], SortedNumbers),
    % The appearance is fully built.
    ground(Appearance),
    % A well-formed model needs no further checking.
    !.
% Anything else is refused by name wherever a model is expected.
quantity_model_check_model(Term, Where) :-
    % Refuse the malformed term rather than measuring nonsense.
    throw(error(quantity_model_malformed_amount(Term),
                context(Where, "a represented amount is represented_amount(Units, Appearance)"))).

% quantity_model_check_appearance(+Appearance, +Where): the appearance is fully built.
quantity_model_check_appearance(Appearance, _Where) :-
    % A fully-instantiated appearance needs no further checking.
    nonvar(Appearance),
    ground(Appearance),
    !.
% A half-built appearance is refused by name.
quantity_model_check_appearance(Appearance, Where) :-
    % Refuse the template rather than representing it as a world.
    throw(error(quantity_model_malformed_appearance(Appearance),
                context(Where, "an appearance describes how the world looks, so it must be fully built"))).

% quantity_model_record(+Model, +Transformation, +Instant, -Record): own a verdict BY ENACTING
% THE TRIAL. The record is minted from a trial this predicate itself runs, so a hand-written
% verdict cannot be owned as if it had been measured - the claim and the record cannot come
% apart, the lesson slice 21's review taught.
quantity_model_record(Model, Transformation, Instant, Record) :-
    % Run the whole trial, right here - the verdict is enacted, not quoted.
    quantity_model_trial(Model, Transformation, Verdict, _NewModel),
    % Render the measured verdict deterministically as the record's content.
    format(string(ConclusionText), "~w", [Verdict]),
    % The measuring mind is minted as a token individual - the holder of its own verdict.
    other_minds_individual_record("agent", "konnectome", Individual),
    % Read the measuring mind's content-addressed identifier.
    get_dict(id, Individual, HolderIdentifier),
    % The verdict is minted as a state assertion carrying its measured content.
    other_minds_content_record(HolderIdentifier, "the_conservation_verdict_as_measured",
                               ConclusionText, Instant, Record).

% quantity_model_stance(+Record, +Instant, -Stance): the mind stands behind its verdict.
% The derivation grade fits a MEASURED-AND-COMPARED verdict exactly: the mind read its own model
% and reasoned; it did not observe the verdict ready-made. Grading a derivation as observation
% would overstate the evidence.
quantity_model_stance(Record, Instant, Stance) :-
    % Read the verdict's content-addressed identifier.
    get_dict(id, Record, Identifier),
    % The stance is graded derivation: measured from the model, owned at a strong weight.
    self_provenance_assertion(Identifier, "derivation", 0.9, Instant, Stance).
