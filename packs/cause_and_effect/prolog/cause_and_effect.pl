% Declare the cause_and_effect module and the public interface of the Rung Three causal trials.
:- module(cause_and_effect, [
    % cause_and_effect_discriminate/4: genuine cause, reverse cause, or mere co-occurrence - by the record.
    cause_and_effect_discriminate/4,
    % cause_and_effect_plan/4: compose the shortest action sequence from a start state to a goal state.
    cause_and_effect_plan/4,
    % cause_and_effect_intend/4: own a composed plan on the record as the standard's intends attitude.
    cause_and_effect_intend/4,
    % cause_and_effect_stance/3: the mind's graded stance on its own intention - derivation, never observation.
    cause_and_effect_stance/3
]).

% Import list membership, reversal, and appending for the guarded searches.
:- use_module(library(lists), [member/2, memberchk/2, reverse/2, append/3]).
% Reuse PrologAI's Causalontology core to re-derive a record's content address; konnectome does not fork it.
:- use_module(library(causal_core), [causal_core_identify/3]).
% Reuse other minds: the same record family that minted a belief mints an owned intention.
:- use_module(library(other_minds), [
    % other_minds_individual_record/3: mint the planning mind as a token individual.
    other_minds_individual_record/3,
    % other_minds_content_record/5: mint the plan as a state assertion.
    other_minds_content_record/5,
    % other_minds_attitude_record/4: mint the intention as an attitude of the standard's enumeration.
    other_minds_attitude_record/4
]).
% Reuse self provenance: the mind grades its intention honestly as reasoned, not seen.
:- use_module(library(self_provenance), [
    % self_provenance_assertion/5: assert about the intention, graded and weighted.
    self_provenance_assertion/5
]).

% The cause_and_effect pack opens Rung Three - the concrete-reasoning rung - on its CAUSAL side.
% It realizes the rung's two causal pilot trials. CAUSAL DISCRIMINATION: genuine cause is
% distinguished from mere co-occurrence BY THE RECORD - the mind answers "cause" only when a
% minted Causal Relation Object (or an unbroken chain of them) carries the question's two events,
% and the justification it gives is the chain of record identifiers itself, the glass box naming
% its evidence; two events seen together a thousand mornings without a record stay co-occurrence,
% and a record pointing the other way is reported as the reverse, never silently flipped. And
% "minted" is checked, not trusted: every record offered as evidence must re-derive its own
% content address from its own content, so a hand-written look-alike is refused by name rather
% than accepted as proof - the claim that causation is answered by the record means nothing if
% any dict shaped like a record can answer it.
% MEANS-END PLANNING: a short action sequence is composed from known state transitions to reach
% a given goal state - breadth-first, so the shortest plan wins; every step named and justified
% by the states it leaves and reaches; and the finished plan is owned on the record as the
% standard's own INTENDS attitude, graded at the scale's DERIVATION grade, because a plan is
% reasoned, not observed. The pack adds no new Causalontology kind and no eleventh component;
% the logic trials of the rung live in the sibling pack concrete_operations.

% cause_and_effect_discriminate(+CausalRecords, +CauseCandidate, +EffectCandidate, -Finding): by the record.
cause_and_effect_discriminate(CausalRecords, CauseCandidate, EffectCandidate, Finding) :-
    % Every supposed causal record must be a real minted record before any search starts.
    cause_and_effect_check_records(CausalRecords),
    % The cause candidate must be a minted event.
    cause_and_effect_check_event(CauseCandidate),
    % The effect candidate must be a minted event.
    cause_and_effect_check_event(EffectCandidate),
    % A forward chain proves genuine cause; a backward chain reveals the reverse; neither leaves co-occurrence.
    (   cause_and_effect_chain(CausalRecords, CauseCandidate, EffectCandidate, [CauseCandidate], Chain)
    ->  Finding = genuine_cause(Chain)
    ;   cause_and_effect_chain(CausalRecords, EffectCandidate, CauseCandidate, [EffectCandidate], Chain)
    ->  Finding = reverse_cause(Chain)
    ;   Finding = co_occurrence_only
    ).

% cause_and_effect_check_records(+CausalRecords): every term is a real minted causal record.
cause_and_effect_check_records(CausalRecords) :-
    % Walk every term and check its shape.
    forall(member(Term, CausalRecords), cause_and_effect_check_record(Term)).

% cause_and_effect_check_record(+Term): one term is a real minted causal record.
cause_and_effect_check_record(Term) :-
    % A minted causal record is a dict carrying an identifier, causes, and effects.
    is_dict(Term),
    % It carries its content-addressed identifier.
    get_dict(id, Term, Identifier),
    % It carries its causes as a proper list.
    get_dict(causes, Term, Causes),
    % The causes are a proper list.
    is_list(Causes),
    % It carries its effects as a proper list.
    get_dict(effects, Term, Effects),
    % The effects are a proper list.
    is_list(Effects),
    % Every cause is a minted event identifier - the same test the question's candidates pass.
    forall(member(Cause, Causes), cause_and_effect_is_event_identifier(Cause)),
    % Every effect is a minted event identifier.
    forall(member(Effect, Effects), cause_and_effect_is_event_identifier(Effect)),
    % The record's shape is sound; its minting is verified separately so a forgery gets its own name.
    !,
    % A record is EVIDENCE only if it was truly minted: its identifier must be re-derivable from its
    % own content. A look-alike dict with a hand-written identifier is a forgery, not a record.
    cause_and_effect_check_minted(Term, Identifier).
% Anything else is refused by name, never silently skipped.
cause_and_effect_check_record(Term) :-
    % Refuse the malformed record rather than searching over it.
    throw(error(cause_and_effect_malformed_record(Term),
                context(cause_and_effect_discriminate/4, "every causal record must be a minted Causal Relation Object"))).

% cause_and_effect_is_event_identifier(+Term): the term is a minted event identifier.
cause_and_effect_is_event_identifier(Term) :-
    % A minted event identifier is a string carrying the occurrent scheme prefix.
    string(Term),
    % The prefix names the scheme.
    sub_string(Term, 0, _, _, "occurrent:").

% cause_and_effect_check_minted(+Record, +Identifier): the record's identifier is re-derivable.
cause_and_effect_check_minted(Record, Identifier) :-
    % Strip the carried identifier and re-derive the content address from the record's own body.
    del_dict(id, Record, _, Body),
    % Re-derive the content address the way thought combination minted it.
    causal_core_identify(Body, causal_relation_object, RederivedIdentifier),
    % A record whose carried identifier does not match its own content is a forgery, refused by name.
    (   Identifier == RederivedIdentifier
    ->  true
    ;   throw(error(cause_and_effect_unminted_record(Identifier),
                    context(cause_and_effect_discriminate/4, "a causal record's identifier must re-derive from its own content")))
    ).

% cause_and_effect_check_event(+Candidate): the candidate is a minted event identifier.
cause_and_effect_check_event(Candidate) :-
    % The candidate passes the same identifier test every record element passes.
    cause_and_effect_is_event_identifier(Candidate),
    % A minted event needs no further checking.
    !.
% Anything else is refused by name.
cause_and_effect_check_event(Candidate) :-
    % Refuse the non-event rather than guessing what it names.
    throw(error(cause_and_effect_not_an_event(Candidate),
                context(cause_and_effect_discriminate/4, "causation is asked between minted events, never free text"))).

% cause_and_effect_chain(+CausalRecords, +From, +To, +Visited, -Chain): an unbroken chain of records.
cause_and_effect_chain(CausalRecords, From, To, Visited, [RecordIdentifier | RestOfChain]) :-
    % Take a record whose causes carry the current event.
    member(Record, CausalRecords),
    % The record's causes include where the chain now stands.
    get_dict(causes, Record, Causes),
    % The current event is among them.
    memberchk(From, Causes),
    % The record's effects are where the chain can step next.
    get_dict(effects, Record, Effects),
    % Step to one of the record's effects.
    member(Next, Effects),
    % The step is justified by the record's own identifier.
    get_dict(id, Record, RecordIdentifier),
    % Reaching the target closes the chain - even when the target is where the chain began, so a
    % record honestly stating that an event causes itself is honoured; otherwise the guarded
    % search never revisits an event, so a causal loop still terminates.
    (   Next == To
    ->  RestOfChain = []
    ;   \+ memberchk(Next, Visited),
        cause_and_effect_chain(CausalRecords, Next, To, [Next | Visited], RestOfChain)
    ).

% cause_and_effect_plan(+Actions, +Start, +Goal, -Plan): the shortest action sequence to the goal.
cause_and_effect_plan(Actions, Start, Goal, Plan) :-
    % The start must be a named state - an unbound start would let the planner invent one.
    cause_and_effect_check_state(Start),
    % The goal must be a named state.
    cause_and_effect_check_state(Goal),
    % Every action must be well-formed before any planning starts.
    cause_and_effect_check_actions(Actions),
    % A goal already at hand needs no action; otherwise search breadth-first for the shortest road.
    (   Start == Goal
    ->  Plan = []
    ;   cause_and_effect_search([Start-[]], [Start], Actions, Goal, ReversedPlan),
        reverse(ReversedPlan, Plan)
    ).

% cause_and_effect_check_state(+Term): the term names a state.
cause_and_effect_check_state(Term) :-
    % A state is named by an atom - nothing unbound, nothing structured.
    (   atom(Term)
    ->  true
    ;   throw(error(cause_and_effect_malformed_state(Term),
                    context(cause_and_effect_plan/4, "a start or goal state must be a named atom")))
    ).

% cause_and_effect_check_actions(+Actions): every term is a well-formed action/3.
cause_and_effect_check_actions(Actions) :-
    % Walk every term and check its shape.
    forall(member(Term, Actions), cause_and_effect_check_action(Term)).

% cause_and_effect_check_action(+Term): one term is a well-formed action/3.
cause_and_effect_check_action(action(Name, From, To)) :-
    % The action is named by an atom.
    atom(Name),
    % The state it leaves is an atom.
    atom(From),
    % The state it reaches is an atom.
    atom(To),
    % A well-formed action needs no further checking.
    !.
% Anything else is refused by name, never silently skipped.
cause_and_effect_check_action(Term) :-
    % Refuse the malformed action rather than planning over it.
    throw(error(cause_and_effect_malformed_action(Term),
                context(cause_and_effect_plan/4, "every known action must be action(Name, FromState, ToState) over atoms"))).

% cause_and_effect_search(+Queue, +Visited, +Actions, +Goal, -ReversedPlan): breadth-first, shortest wins.
cause_and_effect_search([State-StepsSoFar | _RestOfQueue], _Visited, _Actions, Goal, StepsSoFar) :-
    % The front of the queue stands at the goal: the steps that carried it here are the plan.
    State == Goal,
    % The first plan found breadth-first is a shortest plan.
    !.
% Otherwise expand the front state by every applicable action and keep searching.
cause_and_effect_search([State-StepsSoFar | RestOfQueue], Visited, Actions, Goal, ReversedPlan) :-
    % Collect every unvisited state one applicable action reaches from here, each with its justified step.
    findall(Next-[step(apply_action, Name, from(State), to(Next)) | StepsSoFar],
            (   member(action(Name, State, Next), Actions),
                \+ memberchk(Next, Visited)
            ),
            Expansions),
    % The newly reached states join the visited set, so no state is enqueued twice.
    findall(Next, member(Next-_, Expansions), NewlyReached),
    % Extend the visited set.
    append(Visited, NewlyReached, NewVisited),
    % The expansions join the back of the queue - breadth first.
    append(RestOfQueue, Expansions, NewQueue),
    % A non-empty queue keeps searching; an empty one fails cleanly - no road is invented.
    NewQueue = [_ | _],
    % Continue the search over the extended queue.
    cause_and_effect_search(NewQueue, NewVisited, Actions, Goal, ReversedPlan).

% cause_and_effect_intend(+Plan, +GoalDesignator, +Instant, -Record): own a plan as an intention.
% An empty plan is nothing to commit to, and intending it is refused by name.
cause_and_effect_intend([], _GoalDesignator, _Instant, _Record) :-
    % Refuse the empty intention rather than minting a commitment to nothing.
    throw(error(cause_and_effect_empty_intention,
                context(cause_and_effect_intend/4, "a plan with no step is nothing to intend"))).
% A real plan is owned as the standard's own intends attitude.
cause_and_effect_intend(Plan, GoalDesignator, Instant, Record) :-
    % Every step of a real plan is checked by name and shape - a junk step is refused, never skipped.
    forall(member(Step, Plan), cause_and_effect_check_step(Step)),
    % Read the plan's action names, in order.
    findall(Name, member(step(apply_action, Name, _From, _To), Plan), Names),
    % Render the plan as its spoken sequence of actions.
    atomic_list_concat(Names, ' then ', PlanAtom),
    % The record family carries strings.
    atom_string(PlanAtom, PlanText),
    % The planning mind is minted as a token individual - the holder of its own intention.
    other_minds_individual_record("agent", "konnectome", Individual),
    % Read the planning mind's content-addressed identifier.
    get_dict(id, Individual, HolderIdentifier),
    % The plan is minted as a state assertion carrying its action sequence.
    other_minds_content_record(HolderIdentifier, GoalDesignator, PlanText, Instant, Content),
    % Read the plan content's identifier.
    get_dict(id, Content, ContentIdentifier),
    % The intention is the mind holding the standard's own intends attitude toward its plan.
    other_minds_attitude_record(HolderIdentifier, "intends", ContentIdentifier, Record).

% cause_and_effect_check_step(+Term): one term is a fully justified plan step.
cause_and_effect_check_step(step(apply_action, Name, from(FromState), to(ToState))) :-
    % The step's action is named by an atom.
    atom(Name),
    % The state it leaves is a named atom.
    atom(FromState),
    % The state it reaches is a named atom.
    atom(ToState),
    % A fully justified step needs no further checking.
    !.
% Anything else is refused by name, never silently skipped.
cause_and_effect_check_step(Term) :-
    % Refuse the malformed step rather than committing to a plan that never was one.
    throw(error(cause_and_effect_malformed_step(Term),
                context(cause_and_effect_intend/4, "every step of an intended plan must be step(apply_action, Name, from(State), to(State)) over atoms"))).

% cause_and_effect_stance(+Record, +Instant, -Stance): the mind stands behind its intention.
% The derivation grade fits a composed plan exactly: means-end reasoning produced it from known
% transitions; the mind did not observe its own future. Grading a plan as observation would
% overstate the evidence, and the scale's own derivation grade exists for precisely this record.
cause_and_effect_stance(Record, Instant, Stance) :-
    % Read the intention's content-addressed identifier.
    get_dict(id, Record, Identifier),
    % The stance is graded derivation: a reasoned commitment, owned at a strong weight.
    self_provenance_assertion(Identifier, "derivation", 0.9, Instant, Stance).
