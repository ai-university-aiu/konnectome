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
    other_minds_content_record/5,
    % other_minds_attitude_record/4: mint an attribution as a content-addressed attitude.
    other_minds_attitude_record/4,
    % other_minds_nested_attitude_records/5: mint a two-level attribution as two attitudes, the outer about the inner.
    other_minds_nested_attitude_records/5,
    % other_minds_search_prediction_export/5: end the false-belief trial by exporting its prediction as an attitude record.
    other_minds_search_prediction_export/5
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
% expressible by reusing PrologAI's theory_of_mind pack unchanged. The EXPORT half - recording an
% attribution as a shareable, content-addressed Causalontology record so a second mind or repository
% can receive it - was NOT expressible when this pack was first built: Causalontology 3.0.0 had no
% attitude kind, and that finding was recorded as Wall-1 (2026-07-22) and ROUTED through the gated
% change order rather than worked around. Causalontology 4.0.0 plus causal_core 1.1.0 CLOSED the
% wall by adding the attitude kind (identity fields: holder, attitude_type, content), whose content
% is quarantined by semantics Rule 25 - an attitude records a mind, never a fact, so a false belief
% raises no conflict and is first-class and shareable, and a content may name another attitude,
% giving nesting a home. The minting predicates at the bottom now export the WHOLE attribution: the
% modelled individual, the believed content, the attitude that joins them, the nested attitude, and
% the false-belief trial's own predicted-search result. A world fact or belief about where an
% object sits takes the term shape object_location(Object, Place).

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

% other_minds_attitude_record(+HolderId, +AttitudeType, +ContentId, -Record): mint an attribution as a content-addressed attitude.
% This is the export Wall-1 demanded: unmintable under Causalontology 3.0.0, minted here under 4.0.0 and causal_core 1.1.0.
other_minds_attitude_record(HolderId, AttitudeType, ContentId, Record) :-
    % An attribution is a Causalontology attitude: a holder (the modelled mind), an attitude type, and a content reference.
    Base = _{type: "attitude", holder: HolderId, attitude_type: AttitudeType, content: ContentId},
    % Content-address it over its identity-bearing fields (holder, attitude_type, content).
    causal_core_identify(Base, attitude, Id),
    % Attach the identifier, yielding the complete stored record.
    put_dict(id, Base, Id, Record).

% other_minds_nested_attitude_records(+OuterHolderId, +InnerHolderId, +ContentId, -InnerRecord, -OuterRecord): mint a two-level attribution.
other_minds_nested_attitude_records(OuterHolderId, InnerHolderId, ContentId, InnerRecord, OuterRecord) :-
    % Mint the inner attitude first: the inner holder believes the content.
    other_minds_attitude_record(InnerHolderId, "believes", ContentId, InnerRecord),
    % Read the inner attitude's identifier; Rule 25 lets an attitude's content reference another attitude.
    get_dict(id, InnerRecord, InnerId),
    % Mint the outer attitude about the inner one: the outer holder believes that the inner holder believes the content.
    other_minds_attitude_record(OuterHolderId, "believes", InnerId, OuterRecord).

% other_minds_search_prediction_export(+Agent, +Object, +Instant, -Place, -Record): end the false-belief trial by exporting its result.
other_minds_search_prediction_export(Agent, Object, Instant, Place, Record) :-
    % Ask the runtime where the agent will search: the place the agent BELIEVES the object is, not where it actually is.
    other_minds_predict_search(Agent, Object, Place),
    % Render the agent's name as a string designator for minting.
    atom_string(Agent, AgentDesignator),
    % Mint the agent, the holder of the exported belief, as a content-addressed token_individual.
    other_minds_individual_record("agent", AgentDesignator, HolderRecord),
    % Read the holder's identifier.
    get_dict(id, HolderRecord, HolderId),
    % Render the object's name as a string designator for minting.
    atom_string(Object, ObjectDesignator),
    % Mint the object the belief is about as a content-addressed token_individual.
    other_minds_individual_record(ObjectDesignator, ObjectDesignator, ObjectRecord),
    % Read the object's identifier.
    get_dict(id, ObjectRecord, ObjectId),
    % Render the believed place as the string value of the object's location quality.
    atom_string(Place, PlaceValue),
    % Mint the believed content - the object sits at the believed place - as a content-addressed state_assertion.
    other_minds_content_record(ObjectId, "location", PlaceValue, Instant, ContentRecord),
    % Read the content's identifier.
    get_dict(id, ContentRecord, ContentId),
    % Mint the trial's result: the attribution itself, a real, shareable, content-addressed attitude record.
    other_minds_attitude_record(HolderId, "believes", ContentId, Record).
