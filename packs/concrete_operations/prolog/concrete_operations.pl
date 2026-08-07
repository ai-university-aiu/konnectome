% Declare the concrete_operations module and the public interface of the Rung Three logic trials.
:- module(concrete_operations, [
    % concrete_operations_above/4: derive that one object stands above another, every step shown.
    concrete_operations_above/4,
    % concrete_operations_classify/3: sort perceived objects into groups by a chosen property.
    concrete_operations_classify/3,
    % concrete_operations_seriate/3: order perceived objects along a numeric dimension.
    concrete_operations_seriate/3,
    % concrete_operations_conserve/3: judge whether a transformation changed an amount or only its
    % look - BY ITS NAME on a closed enumeration; for the book's conservation trial itself, the
    % sibling quantity_model reads the verdict from a represented model and supersedes this.
    concrete_operations_conserve/3,
    % concrete_operations_record/4: own a derived conclusion on the record.
    concrete_operations_record/4,
    % concrete_operations_stance/3: the mind's graded stance on its own conclusion - derivation, never observation.
    concrete_operations_stance/3
]).

% Import list membership for reading facts and properties.
:- use_module(library(lists), [member/2, memberchk/2, append/3]).
% Reuse other minds: the same record family that minted a belief mints a derived conclusion.
:- use_module(library(other_minds), [
    % other_minds_individual_record/3: mint the reasoning mind as a token individual.
    other_minds_individual_record/3,
    % other_minds_content_record/5: mint the conclusion as a state assertion.
    other_minds_content_record/5
]).
% Reuse self provenance: the mind grades its conclusion honestly as reasoned, not seen.
:- use_module(library(self_provenance), [
    % self_provenance_assertion/5: assert about the conclusion, graded and weighted.
    self_provenance_assertion/5
]).

% The concrete_operations pack opens Rung Three - the concrete-reasoning rung, the book's
% concrete operational stage - on its LOGIC side. It realizes the rung's smoke test in full and
% opens three of its pilot trials, each claim sized honestly. TRANSITIVE INFERENCE (the smoke
% test, realized in full): the block is on the cup, the cup is on the table, therefore the block
% is above the table - with every derivation step a named, watchable operation, never an opaque
% leap. CLASSIFICATION (this pack's half: the flexible re-sort over a chosen property; the trial's
% other half - categories the mind FORMED FROM EXPERIENCE - was deferred at slice 21 and is now
% realized by the sibling pack category_formation, which forms the categories by reused concept
% induction and REUSES this pack's classifier for the re-sort). SERIATION (opened): a collection
% is ordered along a numeric dimension. CONSERVATION (this pack's half: the verdict shape over a
% closed enumeration of transformation names - honest but surface-bound, since the verdict follows
% from the name; the trial's other half - a genuine represented model of quantity under changing
% appearance, whose verdict is read by re-measuring the model - was deferred at slice 21 and is
% now realized by the sibling pack quantity_model, which supersedes this schematic verdict for the
% book's trial). The pack adds no new Causalontology kind and no eleventh component: a derived
% conclusion is owned through the record family other_minds already mints, and the mind's stance
% on it is graded through self_provenance at the scale's own DERIVATION grade - a conclusion is
% reasoned, not seen, and the record says so. The causal trials of the rung live in the sibling
% pack cause_and_effect.

% concrete_operations_check_collection(+Term, +Where): the collection argument is a proper list.
concrete_operations_check_collection(Term, Where) :-
    % A proper list is the only accepted collection shape.
    (   is_list(Term)
    ->  true
    ;   throw(error(concrete_operations_malformed_collection(Term),
                    context(Where, "a collection must be a proper list")))
    ).

% concrete_operations_above(+OnFacts, +Upper, +Lower, -Steps): derive above(Upper, Lower), steps shown.
concrete_operations_above(OnFacts, Upper, Lower, Steps) :-
    % The facts must arrive as a proper list before anything reads them.
    concrete_operations_check_collection(OnFacts, concrete_operations_above/4),
    % Every support fact must be well-formed before any reasoning starts.
    concrete_operations_check_supports(OnFacts),
    % A support cycle is a physical impossibility and is refused before any reasoning starts.
    concrete_operations_check_acyclic(OnFacts),
    % Derive the queried fact, collecting every named step along the way; the first complete
    % derivation found is THE derivation shown, so the answer is deterministic.
    once(concrete_operations_derive_above(OnFacts, Upper, Lower, Steps)).

% concrete_operations_check_supports(+OnFacts): every fact is a well-formed on/2 support fact.
concrete_operations_check_supports(OnFacts) :-
    % Walk every fact and check its shape.
    forall(member(Fact, OnFacts), concrete_operations_check_support(Fact)).

% concrete_operations_check_support(+Fact): one fact is a well-formed on/2 support fact.
concrete_operations_check_support(on(Upper, Lower)) :-
    % The resting object is named by an atom.
    atom(Upper),
    % The supporting object is named by an atom.
    atom(Lower),
    % A well-formed support fact needs no further checking.
    !.
% Anything that is not a well-formed on/2 support fact is refused by name.
concrete_operations_check_support(Fact) :-
    % Refuse the malformed fact rather than silently skipping it.
    throw(error(concrete_operations_malformed_support(Fact),
                context(concrete_operations_above/4, "every support fact must be on(Upper, Lower) over atoms"))).

% concrete_operations_check_acyclic(+OnFacts): no object transitively supports itself.
% The walk carries a shared set of objects already proven cycle-free across all starts, so a
% lattice of shared supports is walked once per object, never once per path - the check stays
% fast on exactly the many-pathed configurations that would otherwise multiply the walking.
concrete_operations_check_acyclic(OnFacts) :-
    % Every resting object is a starting point for a downward walk.
    findall(Object, member(on(Object, _), OnFacts), Objects),
    % Walk them all, threading the shared proven-clear set through.
    concrete_operations_walk_all(Objects, OnFacts, [], _ProvenClear).

% concrete_operations_walk_all(+Objects, +OnFacts, +ProvenClear0, -ProvenClear): walk every start.
% No starting points remain: the proven-clear set is final.
concrete_operations_walk_all([], _OnFacts, ProvenClear, ProvenClear).
% Walk one starting point, then the rest, carrying the growing proven-clear set.
concrete_operations_walk_all([Object | Rest], OnFacts, ProvenClear0, ProvenClear) :-
    % Walk downward from this object along a fresh path.
    concrete_operations_walk_down(Object, OnFacts, [], ProvenClear0, ProvenClear1),
    % Continue with the remaining starting points.
    concrete_operations_walk_all(Rest, OnFacts, ProvenClear1, ProvenClear).

% concrete_operations_walk_down(+Object, +OnFacts, +Path, +ProvenClear0, -ProvenClear): one walk.
concrete_operations_walk_down(Object, OnFacts, Path, ProvenClear0, ProvenClear) :-
    % An object already proven cycle-free needs no second walk.
    (   memberchk(Object, ProvenClear0)
    ->  ProvenClear = ProvenClear0
    % An object already on the current downward path is a support cycle.
    ;   memberchk(Object, Path)
    ->  throw(error(concrete_operations_cyclic_support(Object),
                    context(concrete_operations_above/4, "a support cycle is a physical impossibility")))
    % A fresh object is walked below, then joins the proven-clear set.
    ;   findall(Below, member(on(Object, Below), OnFacts), Belows),
        % Walk everything the object rests on, along the extended path.
        concrete_operations_walk_each(Belows, OnFacts, [Object | Path], ProvenClear0, ProvenClear1),
        % The object's whole underside is clear, so the object is clear.
        ProvenClear = [Object | ProvenClear1]
    ).

% concrete_operations_walk_each(+Belows, +OnFacts, +Path, +ProvenClear0, -ProvenClear): walk siblings.
% No supports remain below: the proven-clear set passes through.
concrete_operations_walk_each([], _OnFacts, _Path, ProvenClear, ProvenClear).
% Walk one support, then its siblings, carrying the growing proven-clear set.
concrete_operations_walk_each([Below | Rest], OnFacts, Path, ProvenClear0, ProvenClear) :-
    % Walk down through this support.
    concrete_operations_walk_down(Below, OnFacts, Path, ProvenClear0, ProvenClear1),
    % Continue with the sibling supports.
    concrete_operations_walk_each(Rest, OnFacts, Path, ProvenClear1, ProvenClear).

% concrete_operations_derive_above(+OnFacts, +Upper, +Lower, -Steps): the two named operations of the derivation.
% The base operation: an object resting directly on another stands above it.
concrete_operations_derive_above(OnFacts, Upper, Lower, [step(resting_is_above, [on(Upper, Lower)], above(Upper, Lower))]) :-
    % The direct support fact is on the table of facts.
    memberchk(on(Upper, Lower), OnFacts),
    % A direct fact needs no chain.
    !.
% The chaining operation: resting on a middle object that stands above the target.
concrete_operations_derive_above(OnFacts, Upper, Lower, Steps) :-
    % The upper object rests on some middle object.
    member(on(Upper, Middle), OnFacts),
    % Derive that the middle object stands above the target, steps shown.
    concrete_operations_derive_above(OnFacts, Middle, Lower, MiddleSteps),
    % Name the resting step that lifts the direct fact into an above fact.
    RestingStep = step(resting_is_above, [on(Upper, Middle)], above(Upper, Middle)),
    % Name the chaining step that joins the two above facts.
    ChainStep = step(transitive_chain, [above(Upper, Middle), above(Middle, Lower)], above(Upper, Lower)),
    % The full derivation: the resting step, the middle derivation, then the chain that concludes.
    append([RestingStep | MiddleSteps], [ChainStep], Steps).

% concrete_operations_classify(+Objects, +Property, -Groups): sort a perceived collection by one property.
concrete_operations_classify(Objects, Property, Groups) :-
    % The collection must arrive as a proper list before anything reads it.
    concrete_operations_check_collection(Objects, concrete_operations_classify/3),
    % Every object must be well-formed before any sorting starts.
    concrete_operations_check_objects(Objects),
    % Read every object's value for the sorting property, refusing any object that lacks it.
    findall(Value-Name,
            (   member(object(Name, Properties), Objects),
                concrete_operations_property_value(Name, Properties, Property, Value)
            ),
            Pairs),
    % The distinct values, in deterministic sorted order, name the groups.
    findall(Value, member(Value-_, Pairs), Values),
    % Deduplicate the values while sorting them.
    sort(Values, GroupValues),
    % Each group holds its members in the collection's own order, gathered by strict equality -
    % never by unification, so no value can lend itself to a group it does not exactly match.
    findall(group(GroupValue, Members),
            (   member(GroupValue, GroupValues),
                findall(Name, (member(Value-Name, Pairs), Value == GroupValue), Members)
            ),
            Groups).

% concrete_operations_check_objects(+Objects): every term is a well-formed object/2.
concrete_operations_check_objects(Objects) :-
    % Walk every term and check its shape.
    forall(member(Term, Objects), concrete_operations_check_object(Term)).

% concrete_operations_check_object(+Term): one term is a well-formed object/2.
concrete_operations_check_object(object(Name, Properties)) :-
    % The object is named by an atom.
    atom(Name),
    % The properties are a list.
    is_list(Properties),
    % A well-formed object needs no further checking.
    !.
% Anything that is not a well-formed object/2 is refused by name.
concrete_operations_check_object(Term) :-
    % Refuse the malformed term rather than silently skipping it.
    throw(error(concrete_operations_malformed_object(Term),
                context(concrete_operations_classify/3, "every perceived object must be object(Name, Properties)"))).

% concrete_operations_property_value(+Name, +Properties, +Property, -Value): one object's value for a property.
concrete_operations_property_value(Name, Properties, Property, Value) :-
    % The object either carries a fully-instantiated value for the property or is refused by name -
    % an unbound or half-built value would unify into groups it does not belong to.
    (   memberchk(Property-Value, Properties),
        ground(Value)
    ->  true
    ;   throw(error(concrete_operations_unclassifiable(Name, Property),
                    context(concrete_operations_classify/3, "an object without a fully-instantiated value on the sorting property cannot be classified by it")))
    ).

% concrete_operations_seriate(+Objects, +Dimension, -Ordered): order a collection along a numeric dimension.
concrete_operations_seriate(Objects, Dimension, Ordered) :-
    % The collection must arrive as a proper list before anything reads it.
    concrete_operations_check_collection(Objects, concrete_operations_seriate/3),
    % Every object must be well-formed before any ordering starts.
    concrete_operations_check_objects(Objects),
    % Read every object's numeric value for the dimension, refusing any object without one.
    findall(Value-Name,
            (   member(object(Name, Properties), Objects),
                concrete_operations_dimension_value(Name, Properties, Dimension, Value)
            ),
            Pairs),
    % Order by the dimension, smallest first, ties resolved by name for determinism.
    msort(Pairs, SortedPairs),
    % The ordered collection is the names alone, in their ordered places.
    findall(Name, member(_-Name, SortedPairs), Ordered).

% concrete_operations_dimension_value(+Name, +Properties, +Dimension, -Value): one object's numeric dimension value.
concrete_operations_dimension_value(Name, Properties, Dimension, Value) :-
    % The object either carries a numeric value for the dimension or is refused by name.
    (   memberchk(Dimension-Value, Properties),
        number(Value)
    ->  true
    ;   throw(error(concrete_operations_unorderable(Name, Dimension),
                    context(concrete_operations_seriate/3, "an object without a numeric value on the dimension cannot be ordered along it")))
    ).

% concrete_operations_appearance_only(+Kind): the closed enumeration of appearance-only transformations.
% Pouring into a different glass changes the look, not the amount.
concrete_operations_appearance_only(pour).
% Spreading a collection out changes the look, not the amount.
concrete_operations_appearance_only(spread).
% Reshaping a lump changes the look, not the amount.
concrete_operations_appearance_only(reshape).
% Rearranging a row changes the look, not the amount.
concrete_operations_appearance_only(rearrange).

% concrete_operations_conserve(+Amount, +Transformation, -Verdict): what a transformation did to an amount.
% SUPERSEDED FOR THE BOOK'S TRIAL: this verdict follows from the transformation's NAME on a closed
% enumeration - the surface. The sibling pack quantity_model reads the verdict by re-measuring a
% represented model, and is the one the conservation trial rests on since build slice 22.
concrete_operations_conserve(Amount, Transformation, Verdict) :-
    % The amount must be a real, non-negative quantity before any judging starts.
    concrete_operations_check_amount(Amount),
    % Judge the transformation against the closed enumeration.
    concrete_operations_transform(Amount, Transformation, Verdict).

% concrete_operations_check_amount(+Amount): the amount is a non-negative number.
concrete_operations_check_amount(Amount) :-
    % The amount is a number and not below zero.
    (   number(Amount),
        Amount >= 0
    ->  true
    ;   throw(error(concrete_operations_malformed_amount(Amount),
                    context(concrete_operations_conserve/3, "an amount is a non-negative number")))
    ).

% concrete_operations_transform(+Amount, +Transformation, -Verdict): one transformation, judged.
% An appearance-only transformation conserves the amount, and the verdict says why.
concrete_operations_transform(Amount, Kind, conserved(Amount, appearance_only(Kind))) :-
    % The transformation is on the appearance-only enumeration.
    concrete_operations_appearance_only(Kind),
    % A conserved amount needs no arithmetic.
    !.
% Adding really changes the amount, and the verdict honestly names the change. The clause
% commits on the add shape itself, so a malformed addition is refused under its own name -
% never misread as an unknown transformation, which add is not.
concrete_operations_transform(Amount, add(More), Verdict) :-
    % An addition is a real change, recognised by its shape.
    !,
    % The added quantity is a non-negative number, or the addition is refused by name.
    (   number(More),
        More >= 0
    ->  NewAmount is Amount + More,
        Verdict = changed(NewAmount, amount_change(add(More)))
    ;   throw(error(concrete_operations_malformed_change(add(More)),
                    context(concrete_operations_conserve/3, "an addition carries a non-negative number")))
    ).
% Removing really changes the amount - but never below what is present. The clause commits on
% the remove shape itself, so a malformed removal is refused under its own name.
concrete_operations_transform(Amount, remove(Less), Verdict) :-
    % A removal is a real change, recognised by its shape.
    !,
    % The removed quantity is a non-negative number, or the removal is refused by name.
    (   number(Less),
        Less >= 0
    ->  % Removing more than is present is a physical impossibility and is refused by name.
        (   Less > Amount
        ->  throw(error(concrete_operations_removed_more_than_present(Less, Amount),
                        context(concrete_operations_conserve/3, "more cannot be removed than is present")))
        ;   NewAmount is Amount - Less,
            Verdict = changed(NewAmount, amount_change(remove(Less)))
        )
    ;   throw(error(concrete_operations_malformed_change(remove(Less)),
                    context(concrete_operations_conserve/3, "a removal carries a non-negative number")))
    ).
% A transformation the enumeration does not know is refused by name, never guessed at.
concrete_operations_transform(_Amount, Kind, _Verdict) :-
    % Refuse the unknown transformation rather than inventing a judgement.
    throw(error(concrete_operations_unknown_transformation(Kind),
                context(concrete_operations_conserve/3, "only a transformation on the closed enumeration can be judged"))).

% concrete_operations_record(+ConclusionDesignator, +ConclusionText, +Instant, -Record): own a conclusion.
concrete_operations_record(ConclusionDesignator, ConclusionText, Instant, Record) :-
    % The reasoning mind is minted as a token individual - the holder of its own conclusion.
    other_minds_individual_record("agent", "konnectome", Individual),
    % Read the reasoning mind's content-addressed identifier.
    get_dict(id, Individual, HolderIdentifier),
    % The conclusion is minted as a state assertion carrying its derived content.
    other_minds_content_record(HolderIdentifier, ConclusionDesignator, ConclusionText, Instant, Record).

% concrete_operations_stance(+Record, +Instant, -Stance): the mind stands behind its conclusion.
% The derivation grade fits a REASONED conclusion exactly: the mind derived it from premises by
% named operations; it did not observe it. Grading a derivation as observation would overstate
% the evidence, and the scale's own derivation grade exists for precisely this record.
concrete_operations_stance(Record, Instant, Stance) :-
    % Read the conclusion's content-addressed identifier.
    get_dict(id, Record, Identifier),
    % The stance is graded derivation: valid steps from true premises, owned at a strong weight.
    self_provenance_assertion(Identifier, "derivation", 0.9, Instant, Stance).
