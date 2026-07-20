% Declare this file as the 'thought_combination' module and list the predicates it exports.
:- module(thought_combination, [
    % thought_combination_atomic/3: mint an atomic thought as a content-addressed Causalontology occurrent.
    thought_combination_atomic/3,
    % thought_combination_combine/3: combine input thoughts into one Causal Relation Object.
    thought_combination_combine/3,
    % thought_combination_combine_modal/4: combine, carrying a modality (necessary, sufficient, and so on).
    thought_combination_combine_modal/4,
    % thought_combination_id/2: read a combination's content-addressed identifier.
    thought_combination_id/2,
    % thought_combination_links/2: whether one combination's effect is a cause of another (a chain of thought).
    thought_combination_links/2
]).

% Import membership for reading and checking cause and effect identifiers.
:- use_module(library(lists), [member/2, memberchk/2]).
% Reuse PrologAI's Causalontology core to content-address a record; konnectome does not fork it.
:- use_module(library(causal_core), [causal_core_identify/3]).

% Combining thoughts, in Causalontology, is minting a Causal Relation Object (CRO) - a reified,
% content-addressed, immutable cause-and-effect record whose causes are the input thoughts and whose
% effects are the output thought. An atomic thought is an occurrent (an event or process type). A
% combination references occurrents only, carries no strength or weight (those live on a separate
% signed assertion), and is named by the fingerprint of its own content. Because a CRO references its
% occurrents rather than embedding them, one CRO's effect can be reused as another's cause: that is a
% chain of thought, and a branching, converging set of them is a tree of thought (a directed acyclic
% graph). konnectome mints these by reusing causal_core; it does not touch the frozen ontology.

% thought_combination_atomic(+Label, +Category, -OccurrentId): mint an atomic thought as an occurrent.
thought_combination_atomic(Label, Category, OccurrentId) :-
    % An atomic thought is a Causalontology occurrent: an event or process type, named by its content.
    Occurrent = _{type: "occurrent", label: Label, category: Category},
    % Content-address it; the same thought always mints the same identifier.
    causal_core_identify(Occurrent, occurrent, OccurrentId).

% thought_combination_is_occurrent(+Id): the identifier is an occurrent identifier.
thought_combination_is_occurrent(Id) :-
    % A cause or effect must carry the occurrent scheme prefix, never a noun, a token, or free text.
    sub_string(Id, 0, _, _, "occurrent:").

% thought_combination_validate(+Causes, +Effects): the causes and effects are non-empty occurrent lists.
thought_combination_validate(Causes, Effects) :-
    % There is at least one cause (the combination's input set).
    Causes = [_ | _],
    % There is at least one effect (the combination's output set).
    Effects = [_ | _],
    % Every cause is an occurrent identifier.
    forall(member(Cause, Causes), thought_combination_is_occurrent(Cause)),
    % Every effect is an occurrent identifier.
    forall(member(Effect, Effects), thought_combination_is_occurrent(Effect)).

% thought_combination_combine(+Causes, +Effects, -Cro): combine input thoughts into one Causal Relation Object.
thought_combination_combine(Causes, Effects, Cro) :-
    % Refuse an ill-formed combination: causes and effects must be non-empty occurrent lists.
    thought_combination_validate(Causes, Effects),
    % Assemble the bare Causal Relation Object body.
    Base = _{type: "causal_relation_object", causes: Causes, effects: Effects},
    % Content-address it over its identity-bearing fields (causes and effects).
    causal_core_identify(Base, causal_relation_object, Id),
    % Attach the identifier, yielding the complete combined thought.
    put_dict(id, Base, Id, Cro).

% thought_combination_combine_modal(+Causes, +Effects, +Modality, -Cro): combine, carrying a modality.
thought_combination_combine_modal(Causes, Effects, Modality, Cro) :-
    % Refuse an ill-formed combination as above.
    thought_combination_validate(Causes, Effects),
    % Assemble the Causal Relation Object body with its modality label for the whole relation.
    Base = _{type: "causal_relation_object", causes: Causes, effects: Effects, modality: Modality},
    % Content-address it; the modality is identity-bearing, so a modal combination has its own identity.
    causal_core_identify(Base, causal_relation_object, Id),
    % Attach the identifier, yielding the complete combined thought.
    put_dict(id, Base, Id, Cro).

% thought_combination_id(+Cro, -Id): read a combination's content-addressed identifier.
thought_combination_id(Cro, Id) :-
    % The identifier lives under the id key of the combined thought.
    get_dict(id, Cro, Id).

% thought_combination_links(+CroA, +CroB): one combination's effect is a cause of another (a chain of thought).
thought_combination_links(CroA, CroB) :-
    % Read the effects of the earlier combination.
    get_dict(effects, CroA, EffectsA),
    % Read the causes of the later combination.
    get_dict(causes, CroB, CausesB),
    % Some effect of the earlier combination is a cause of the later one.
    member(Effect, EffectsA),
    % Confirm that effect appears among the later combination's causes.
    memberchk(Effect, CausesB).
