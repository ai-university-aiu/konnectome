% Declare this file as the 'plasticity_engine' module and list the predicates it exports.
:- module(plasticity_engine, [
    % plasticity_engine_weight_change/5: the three-factor weight change for one interface.
    plasticity_engine_weight_change/5,
    % plasticity_engine_step/5: apply the learning rule to every learnable interface for one tick.
    plasticity_engine_step/5,
    % plasticity_engine_trace_new/2: a fresh zero eligibility trace per learnable interface.
    plasticity_engine_trace_new/2,
    % plasticity_engine_trace_step/5: fade every trace and add each interface's fresh coincidence.
    plasticity_engine_trace_step/5,
    % plasticity_engine_reward_step/5: turn each trace into a weight change through the third factor.
    plasticity_engine_reward_step/5
]).

% Import membership for reading activities, and maplist for updating every interface.
:- use_module(library(lists), [memberchk/2, member/2, append/3]).
% Import maplist for checking and updating every interface together.
:- use_module(library(apply), [maplist/2, maplist/4]).
% Reuse the neuromodulatory bus to read the dopamine level as the third factor.
:- use_module(library(neuromodulator_bus), [neuromodulator_bus_level/3]).

% The plasticity engine is Architecture Component 8: the three-factor learning rule of Section A2.5
% that makes the map alive. For each learnable (transmissive) interface, the weight change is the
% product of three factors - the sending end's recent activity, the receiving end's recent activity,
% and the current dopamine level (the third factor) - scaled by a learning rate. A connection
% strengthens only when its two ends are active TOGETHER and dopamine says the moment mattered.
% Interfaces are the connection-graph terms interface(From, To, Weight, Delay, Kind); the engine
% mutates the Weight of transmissive interfaces and leaves computational ones untouched.

% plasticity_engine_weight_change(+Sending, +Receiving, +ThirdFactor, +LearningRate, -WeightChange): the rule.
plasticity_engine_weight_change(Sending, Receiving, ThirdFactor, LearningRate, WeightChange) :-
    % The Hebbian coincidence is the product of the two ends' activities.
    Coincidence is Sending * Receiving,
    % The raw change multiplies the coincidence by the neuromodulatory third factor (dopamine).
    RawWeightChange is Coincidence * ThirdFactor,
    % The applied change scales the raw change by the learning rate.
    WeightChange is RawWeightChange * LearningRate.

% plasticity_engine_activation(+Activations, +Name, -Value): read a construct's activity, defaulting to zero.
plasticity_engine_activation(Activations, Name, Value) :-
    % Use the stored activity if present, otherwise treat an absent construct as silent.
    ( memberchk(Name-Found, Activations) -> Value = Found ; Value = 0 ).

% plasticity_engine_update_interface(+Activations, +ThirdFactor, +LearningRate, +Interface0, -Interface): learn one edge.
plasticity_engine_update_interface(Activations, ThirdFactor, LearningRate,
                                   interface(From, To, Weight0, Delay, Kind),
                                   interface(From, To, Weight, Delay, Kind)) :-
    % Only a transmissive interface learns; a computational one keeps its weight.
    ( Kind == transmissive
      -> plasticity_engine_activation(Activations, From, Sending),
         plasticity_engine_activation(Activations, To, Receiving),
         plasticity_engine_weight_change(Sending, Receiving, ThirdFactor, LearningRate, WeightChange),
         Weight is Weight0 + WeightChange
      ;  Weight = Weight0
    ).

% The eligibility trace of Section A2.6 is a fading memory of recent coincidence, one per learnable
% interface, so that a reward arriving a moment AFTER an action can still find the connection that
% earned it. Traces are an explicit stateless value beside the interfaces - a list of (From-To)-Trace
% pairs - built by plasticity_engine_trace_new, advanced each tick by plasticity_engine_trace_step
% (trace times a fading factor slightly less than one, plus the tick's fresh coincidence), and spent
% by plasticity_engine_reward_step (weight plus trace times dopamine times the learning rate). In the
% house voice of slice 27, every wrong is refused aloud through one shared refusal perimeter: a
% fading factor outside zero-inclusive-to-one-exclusive, a term that is not an interface, an unbound
% or unknown interface kind, a duplicate transmissive interface, a duplicate trace key, a learnable
% interface whose trace is missing (the ghost), and a trace whose interface is gone (the orphan)
% each throw by name, never answered by a silently wrong number or a silent failure.

% plasticity_engine_check_fading_factor(+FadingFactor): refuse a fading factor outside [0, 1) by name.
plasticity_engine_check_fading_factor(FadingFactor) :-
    % A trace must fade, so the factor lies at or above zero and strictly below one.
    (  number(FadingFactor), FadingFactor >= 0, FadingFactor < 1
    -> true
    % Anything else is refused aloud, never silently accepted.
    ;  throw(error(domain_error(plasticity_engine_fading_factor, FadingFactor), _))
    ).

% plasticity_engine_check_interface(+Term): refuse anything that is not a well-formed interface, by name.
plasticity_engine_check_interface(Term) :-
    % An unbound term cannot be judged, so it is refused as uninstantiated rather than silently bound.
    (  var(Term)
    -> throw(error(instantiation_error, _))
    % A term that is not an interface at all is refused by name, never silently skipped.
    ;  Term \= interface(_, _, _, _, _)
    -> throw(error(domain_error(plasticity_engine_interface, Term), _))
    % A well-shaped interface still needs its kind judged.
    ;  Term = interface(_, _, _, _, Kind),
       plasticity_engine_check_kind(Kind)
    ).

% plasticity_engine_check_kind(+Kind): refuse an interface kind no slice has defined, by name.
plasticity_engine_check_kind(Kind) :-
    % An unbound kind cannot be judged, and must never be silently bound by the check itself.
    (  var(Kind)
    -> throw(error(instantiation_error, _))
    % The connectome knows exactly two interface kinds.
    ;  memberchk(Kind, [transmissive, computational])
    -> true
    % An unknown kind is refused aloud, never silently carried or dropped.
    ;  throw(error(domain_error(plasticity_engine_interface_kind, Kind), _))
    ).

% plasticity_engine_transmissive_keys(+Interfaces, -Keys): the From-To key of each transmissive interface.
plasticity_engine_transmissive_keys(Interfaces, Keys) :-
    % Collect the endpoint pair of exactly the transmissive interfaces, in interface order.
    findall(From-To, member(interface(From, To, _, _, transmissive), Interfaces), Keys).

% plasticity_engine_check_no_duplicate(+Keys, +ErrorName): refuse a repeated key in a list, by name.
plasticity_engine_check_no_duplicate(Keys, ErrorName) :-
    % Sorting without removing duplicates puts any repeated key beside its twin.
    msort(Keys, Sorted),
    % A repeated key is refused aloud, never answered by a first-one-wins shrug.
    (  append(_, [Key, Key | _], Sorted)
    -> throw(error(domain_error(ErrorName, Key), _))
    ;  true
    ).

% plasticity_engine_check_topology(+Interfaces, +Traces): the shared refusal perimeter of both trace steps.
plasticity_engine_check_topology(Interfaces, Traces) :-
    % Every element of the interface list must be a well-formed interface of a known kind.
    maplist(plasticity_engine_check_interface, Interfaces),
    % Two transmissive interfaces over the same endpoints would double-count one coincidence.
    plasticity_engine_transmissive_keys(Interfaces, Keys),
    plasticity_engine_check_no_duplicate(Keys, plasticity_engine_duplicate_interface),
    % Read every key the trace store carries.
    findall(Key, member(Key-_, Traces), TraceKeys),
    % Two traces under one key would let the lookup silently ignore the second.
    plasticity_engine_check_no_duplicate(TraceKeys, plasticity_engine_duplicate_trace),
    % A trace whose interface is gone is refused aloud, the mirror of the ghost-trace refusal.
    forall(member(TraceKey, TraceKeys),
           (  memberchk(TraceKey, Keys)
           -> true
           ;  throw(error(existence_error(plasticity_engine_interface, TraceKey), _))
           )).

% plasticity_engine_trace_lookup(+Traces, +From, +To, -Trace): read one trace, refusing a ghost aloud.
plasticity_engine_trace_lookup(Traces, From, To, Trace) :-
    % Use the stored trace if present; a missing trace for a learnable interface is an error, never zero.
    (  memberchk((From-To)-Found, Traces)
    -> Trace = Found
    % Refuse the ghost by name so a vanished trace can never learn silently wrong.
    ;  throw(error(existence_error(plasticity_engine_trace, From-To), _))
    ).

% plasticity_engine_trace_new(+Interfaces, -Traces): a fresh zero trace per learnable interface.
plasticity_engine_trace_new(Interfaces, Traces) :-
    % Collect a zero-valued trace for exactly the transmissive interfaces, in interface order.
    findall((From-To)-0, member(interface(From, To, _, _, transmissive), Interfaces), Traces).

% plasticity_engine_trace_interface(+Activations, +FadingFactor, +Traces0, +Interface, -TracePair): one trace tick.
plasticity_engine_trace_interface(Activations, FadingFactor, Traces0,
                                  interface(From, To, _, _, transmissive),
                                  (From-To)-Trace) :-
    % Read the interface's current trace, refusing a ghost aloud.
    plasticity_engine_trace_lookup(Traces0, From, To, Trace0),
    % Read the two ends' activities, a silent absent end counting as zero exactly as the learning step does.
    plasticity_engine_activation(Activations, From, Sending),
    plasticity_engine_activation(Activations, To, Receiving),
    % The tick's fresh coincidence is the product of the two ends' activities.
    Coincidence is Sending * Receiving,
    % The new trace is the old trace faded by the factor, plus the fresh coincidence.
    Trace is Trace0 * FadingFactor + Coincidence.

% plasticity_engine_trace_step(+Interfaces, +Activations, +FadingFactor, +Traces0, -Traces): fade and accumulate.
plasticity_engine_trace_step(Interfaces, Activations, FadingFactor, Traces0, Traces) :-
    % Refuse a fading factor that would let a trace grow or never fade.
    plasticity_engine_check_fading_factor(FadingFactor),
    % Refuse every malformed interface, unknown kind, duplicate, ghost, and orphan before touching a trace.
    plasticity_engine_check_topology(Interfaces, Traces0),
    % Advance the trace of every transmissive interface; computational interfaces carry none.
    findall(TracePair,
            ( member(Interface, Interfaces),
              Interface = interface(_, _, _, _, transmissive),
              plasticity_engine_trace_interface(Activations, FadingFactor, Traces0, Interface, TracePair)
            ),
            Traces).

% plasticity_engine_reward_interface(+Traces, +ThirdFactor, +LearningRate, +Interface0, -Interface): spend one trace.
plasticity_engine_reward_interface(Traces, ThirdFactor, LearningRate,
                                   interface(From, To, Weight0, Delay, Kind),
                                   interface(From, To, Weight, Delay, Kind)) :-
    % Only a transmissive interface learns from its trace; a computational one keeps its weight.
    % (The kinds were already judged by the shared refusal perimeter before this predicate runs.)
    (  Kind == transmissive
    -> % Read the interface's trace, refusing a ghost aloud.
       plasticity_engine_trace_lookup(Traces, From, To, Trace),
       % The reward's weight change is the trace times the third factor times the learning rate.
       Weight is Weight0 + Trace * ThirdFactor * LearningRate
    ;  % A computational interface is untouched by reward.
       Weight = Weight0
    ).

% plasticity_engine_reward_step(+Interfaces0, +Traces, +Bus, +LearningRate, -Interfaces): the reward arrives.
plasticity_engine_reward_step(Interfaces0, Traces, Bus, LearningRate, Interfaces) :-
    % Refuse every malformed interface, unknown kind, duplicate, ghost, and orphan before spending a trace.
    plasticity_engine_check_topology(Interfaces0, Traces),
    % Read the current dopamine level from the bus as the third factor of learning.
    neuromodulator_bus_level(Bus, dopamine, ThirdFactor),
    % Spend every interface's trace into its weight by the three-factor rule.
    maplist(plasticity_engine_reward_interface(Traces, ThirdFactor, LearningRate),
            Interfaces0, Interfaces).

% plasticity_engine_step(+Interfaces0, +Activations, +Bus, +LearningRate, -Interfaces): learn for one tick.
plasticity_engine_step(Interfaces0, Activations, Bus, LearningRate, Interfaces) :-
    % Read the current dopamine level from the bus as the third factor of learning.
    neuromodulator_bus_level(Bus, dopamine, ThirdFactor),
    % Update every interface's weight by the three-factor rule.
    maplist(plasticity_engine_update_interface(Activations, ThirdFactor, LearningRate),
            Interfaces0, Interfaces).
