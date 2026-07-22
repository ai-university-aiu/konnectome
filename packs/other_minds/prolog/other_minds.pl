% Declare this file as the 'other_minds' module and list the predicates it exports.
:- module(other_minds, [
    % other_minds_reset/0: forget the recorded world and every attributed belief.
    other_minds_reset/0,
    % other_minds_world_fact_add/1: record a fact of konnectome's own world.
    other_minds_world_fact_add/1,
    % other_minds_world_fact/1: query what konnectome's own record holds true.
    other_minds_world_fact/1,
    % other_minds_belief_attribute/2: attribute a belief to another agent.
    other_minds_belief_attribute/2,
    % other_minds_believes/2: query what another agent is modelled as believing.
    other_minds_believes/2,
    % other_minds_false_belief/2: a belief an agent holds that konnectome's world record contradicts.
    other_minds_false_belief/2,
    % other_minds_nested_attribute/3: record that one agent believes another agent believes a fact.
    other_minds_nested_attribute/3,
    % other_minds_nested_believes/3: query a nested attribution, a model of another mind's model.
    other_minds_nested_believes/3,
    % other_minds_predict_search/3: predict where an agent will look for an object.
    other_minds_predict_search/3,
    % other_minds_individual_record/3: mint a modelled individual as a content-addressed token_individual.
    other_minds_individual_record/3,
    % other_minds_content_record/5: mint a believed content as a content-addressed state_assertion.
    other_minds_content_record/5
]).

% Reuse PrologAI's theory-of-mind runtime for belief attribution; konnectome does not fork it.
:- use_module(library(theory_of_mind), [
    % theory_of_mind_reset/0: clear the runtime's world and belief stores.
    theory_of_mind_reset/0,
    % theory_of_mind_truth_add/1: record a ground-truth fact of the world.
    theory_of_mind_truth_add/1,
    % theory_of_mind_true/1: query the recorded ground truth.
    theory_of_mind_true/1,
    % theory_of_mind_belief_add/2: record what an agent believes.
    theory_of_mind_belief_add/2,
    % theory_of_mind_believes/2: query what an agent believes.
    theory_of_mind_believes/2,
    % theory_of_mind_false_belief/2: a held belief the recorded truth contradicts.
    theory_of_mind_false_belief/2
]).
% Reuse PrologAI's Causalontology core to content-address a record; konnectome does not fork it.
:- use_module(library(causal_core), [causal_core_identify/3]).

% Modelling other minds is the great social milestone of Rung Four, the emotional and social rung of
% the developmental ladder: konnectome attributes to another agent a belief that can differ from
% konnectome's own record of the world - including a FALSE belief, the classic trial in which an
% agent will look for an object where the agent believes it is, not where it actually is - and a
% NESTED attribution, konnectome's model of the other agent's model. The RUNTIME half below is fully
% expressible today by reusing PrologAI's theory_of_mind pack unchanged. The EXPORT half - recording
% an attribution as a shareable, signed, evidence-graded, content-addressed Causalontology record so
% a second mind or repository can receive it - is NOT expressible in Causalontology 3.0.0, which has
% no attitude, belief, desire, or intention kind. This pack's test suite demonstrates that wall
% mechanically; the two minting helpers at the bottom mint only the EXPRESSIBLE ingredients of an
% attribution (the modelled individual and the believed content), never the attitude that joins them.
% A world fact or belief about where an object sits takes the term shape object_location(Object, Place).

% other_minds_reset/0: forget the recorded world and every attributed belief.
other_minds_reset :-
    % Delegate to the reused theory-of-mind runtime, which clears its world and belief stores.
    theory_of_mind_reset.

% other_minds_world_fact_add(+Fact): record a fact of konnectome's own world.
other_minds_world_fact_add(Fact) :-
    % Konnectome's own record of the world is the runtime's ground-truth store.
    theory_of_mind_truth_add(Fact).

% other_minds_world_fact(?Fact): query what konnectome's own record holds true.
other_minds_world_fact(Fact) :-
    % Read the ground-truth store.
    theory_of_mind_true(Fact).

% other_minds_belief_attribute(+Agent, +Fact): attribute a belief to another agent.
other_minds_belief_attribute(Agent, Fact) :-
    % The attributed belief lives in the runtime's belief store, kept apart from the world itself.
    theory_of_mind_belief_add(Agent, Fact).

% other_minds_believes(?Agent, ?Fact): query what another agent is modelled as believing.
other_minds_believes(Agent, Fact) :-
    % Read the attributed belief back from the belief store.
    theory_of_mind_believes(Agent, Fact).

% other_minds_false_belief(?Agent, ?Fact): a belief an agent holds that konnectome's world record contradicts.
other_minds_false_belief(Agent, Fact) :-
    % A false belief is a held belief that is absent from the ground-truth store.
    theory_of_mind_false_belief(Agent, Fact).

% other_minds_nested_attribute(+Observer, +Target, +Fact): the observer believes the target believes the fact.
other_minds_nested_attribute(Observer, Target, Fact) :-
    % A nested attribution is itself a belief of the observer whose content is another mind's belief.
    theory_of_mind_belief_add(Observer, believes(Target, Fact)).

% other_minds_nested_believes(?Observer, ?Target, ?Fact): query a nested attribution, a model of another mind's model.
other_minds_nested_believes(Observer, Target, Fact) :-
    % Read the observer's belief about the target's belief.
    theory_of_mind_believes(Observer, believes(Target, Fact)).

% other_minds_predict_search(+Agent, +Object, -Place): predict where the agent will look for the object.
other_minds_predict_search(Agent, Object, Place) :-
    % An agent searches where the agent BELIEVES the object is; belief guides action, not the world.
    other_minds_believes(Agent, object_location(Object, Place)).

% other_minds_individual_record(+Label, +Designator, -Record): mint a modelled individual as a token_individual.
other_minds_individual_record(Label, Designator, Record) :-
    % The individual's kind is a Causalontology continuant (a thing that persists) named by its label.
    ContinuantBase = _{type: "continuant", label: Label, category: "object"},
    % Content-address the kind; the same label always mints the same identifier.
    causal_core_identify(ContinuantBase, continuant, ContinuantId),
    % The individual itself is a token_individual: one particular bearer of that kind, picked out by name.
    Base = _{type: "token_individual", instantiates: ContinuantId, designator: Designator},
    % Content-address it over its identity-bearing fields (instantiates and designator).
    causal_core_identify(Base, token_individual, Id),
    % Attach the identifier, yielding the complete stored record.
    put_dict(id, Base, Id, Record).

% other_minds_content_record(+SubjectId, +Quality, +Value, +Instant, -Record): mint a believed content as a state_assertion.
other_minds_content_record(SubjectId, Quality, Value, Instant, Record) :-
    % A believed content, stated of the world, is a Causalontology state_assertion of a quality's value over an interval.
    Base = _{type: "state_assertion", subject: SubjectId, quality: Quality, value: Value, interval: _{start: Instant}},
    % Content-address it over its identity-bearing fields (subject, quality, value, interval).
    causal_core_identify(Base, state_assertion, Id),
    % Attach the identifier, yielding the complete stored record.
    put_dict(id, Base, Id, Record).
