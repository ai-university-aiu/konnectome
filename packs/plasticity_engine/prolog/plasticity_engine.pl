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
    plasticity_engine_reward_step/5,
    % plasticity_engine_average_new/2: a fresh zero running average per named construct.
    plasticity_engine_average_new/2,
    % plasticity_engine_average_step/4: move every running average a smoothing step toward its activity.
    plasticity_engine_average_step/4,
    % plasticity_engine_scaling_step/5: scale each region's incoming weights toward its activity target.
    plasticity_engine_scaling_step/5
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
    % Judge the trace store's shape, unbound tails, and duplicate keys aloud (the shared root of slice 29's review).
    plasticity_engine_check_store(Traces, plasticity_engine_trace_pair, plasticity_engine_duplicate_trace),
    % Read every key the now-judged trace store carries.
    findall(Key, member(Key-_, Traces), TraceKeys),
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
    % A constructor must never mint a store its own consumers refuse: judge the interfaces first.
    maplist(plasticity_engine_check_interface, Interfaces),
    % Refuse duplicate transmissive endpoints before they become duplicate trace keys.
    plasticity_engine_transmissive_keys(Interfaces, Keys),
    plasticity_engine_check_no_duplicate(Keys, plasticity_engine_duplicate_interface),
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

% Homeostatic scaling is the manuscript's slow negative feedback on plasticity itself (Chapter 10 and
% the closing line of Section A2.5): each region continuously adjusts its overall incoming connection
% strengths to keep its average activity near a target - too active and all its inputs are scaled
% down, too quiet and they are scaled up - so the fast three-factor learning can never explode. The
% running averages are an explicit stateless value beside the interfaces, in the trace-store style: a
% list of Name-Average pairs, built at zero by plasticity_engine_average_new, moved each tick by
% plasticity_engine_average_step (an exponential moving average under a smoothing factor), and spent
% by plasticity_engine_scaling_step, which multiplies each incoming transmissive weight by one plus
% the scaling rate times the target-minus-average error of its RECEIVING end, flooring the factor at
% zero so a weight can be silenced but never sign-flipped. Refusals aloud, as ever: a smoothing
% factor outside zero-exclusive-to-one-inclusive, a scaling rate outside zero-inclusive-to-one-
% exclusive, a negative activity target, a duplicate average key, and a receiving construct absent
% from the averages each throw by name.

% plasticity_engine_check_smoothing_factor(+SmoothingFactor): refuse a smoothing factor outside (0, 1] by name.
plasticity_engine_check_smoothing_factor(SmoothingFactor) :-
    % An average must move but may not overshoot, so the factor lies above zero and at most one.
    (  number(SmoothingFactor), SmoothingFactor > 0, SmoothingFactor =< 1
    -> true
    % Anything else is refused aloud, never silently accepted.
    ;  throw(error(domain_error(plasticity_engine_smoothing_factor, SmoothingFactor), _))
    ).

% plasticity_engine_check_scaling_rate(+ScalingRate): refuse a scaling rate outside [0, 1) by name.
plasticity_engine_check_scaling_rate(ScalingRate) :-
    % The bound must be slow, so the rate lies at or above zero and strictly below one.
    (  number(ScalingRate), ScalingRate >= 0, ScalingRate < 1
    -> true
    % Anything else is refused aloud, never silently accepted.
    ;  throw(error(domain_error(plasticity_engine_scaling_rate, ScalingRate), _))
    ).

% plasticity_engine_check_activity_target(+Target): refuse a negative activity target by name.
plasticity_engine_check_activity_target(Target) :-
    % A region defends a real activity level, so the target lies at or above zero.
    (  number(Target), Target >= 0
    -> true
    % Anything else is refused aloud, never silently accepted.
    ;  throw(error(domain_error(plasticity_engine_activity_target, Target), _))
    ).

% plasticity_engine_check_store(+Store, +PairErrorName, +DuplicateErrorName): judge a whole keyed store aloud.
plasticity_engine_check_store(Store, PairErrorName, DuplicateErrorName) :-
    % Walk the store refusing an unbound tail and every malformed pair, collecting the keys in order.
    plasticity_engine_store_keys(Store, PairErrorName, Keys),
    % Two entries under one key would let the lookup silently ignore the second.
    plasticity_engine_check_no_duplicate(Keys, DuplicateErrorName).

% plasticity_engine_store_keys(+Store, +PairErrorName, -Keys): the keys of a store, every wrong refused aloud.
plasticity_engine_store_keys(Store, PairErrorName, Keys) :-
    % An unbound store or tail cannot be judged and must never be walked off a cliff.
    (  var(Store)
    -> throw(error(instantiation_error, _))
    % The empty store carries no keys.
    ;  Store == []
    -> Keys = []
    % A well-formed head contributes its key and the walk continues.
    ;  Store = [Pair | Rest]
    -> (  nonvar(Pair), Pair = Key-_, nonvar(Key)
       -> Keys = [Key | RestKeys],
          plasticity_engine_store_keys(Rest, PairErrorName, RestKeys)
       % A malformed pair is refused by name, never silently skipped.
       ;  throw(error(domain_error(PairErrorName, Pair), _))
       )
    % A store that is not a list at all is refused as a malformed pair of itself.
    ;  throw(error(domain_error(PairErrorName, Store), _))
    ).

% plasticity_engine_check_averages(+Averages): refuse a malformed pair or duplicate key in the average store.
plasticity_engine_check_averages(Averages) :-
    % One judgement for shape, unbound tails, and duplicates alike.
    plasticity_engine_check_store(Averages, plasticity_engine_average_pair, plasticity_engine_duplicate_average).

% plasticity_engine_average_lookup(+Averages, +Name, -Average): read one average, refusing a ghost aloud.
plasticity_engine_average_lookup(Averages, Name, Average) :-
    % Use the stored average if present; a missing average for a receiving region is an error, never zero.
    (  memberchk(Name-Found, Averages)
    -> Average = Found
    % Refuse the ghost by name so a forgotten region can never be scaled silently wrong.
    ;  throw(error(existence_error(plasticity_engine_average, Name), _))
    ).

% plasticity_engine_average_new(+Activations, -Averages): a fresh zero running average per construct.
plasticity_engine_average_new(Activations, Averages) :-
    % A constructor must never mint a store its own consumers refuse: judge the activations first.
    plasticity_engine_check_store(Activations, plasticity_engine_activation_pair, plasticity_engine_duplicate_activation),
    % Collect a zero-valued average for every named construct, in activation order.
    findall(Name-0, member(Name-_, Activations), Averages).

% plasticity_engine_average_one(+Activations, +SmoothingFactor, +AveragePair0, -AveragePair): one average tick.
plasticity_engine_average_one(Activations, SmoothingFactor, Name-Average0, Name-Average) :-
    % Read the construct's current activity, a silent absent construct counting as zero, as ever.
    plasticity_engine_activation(Activations, Name, Activity),
    % Move the running average a smoothing step toward the current activity.
    Average is Average0 * (1 - SmoothingFactor) + Activity * SmoothingFactor.

% plasticity_engine_average_step(+Activations, +SmoothingFactor, +Averages0, -Averages): move every average.
plasticity_engine_average_step(Activations, SmoothingFactor, Averages0, Averages) :-
    % Refuse a smoothing factor that would freeze or overshoot the average.
    plasticity_engine_check_smoothing_factor(SmoothingFactor),
    % Refuse a duplicate key before touching a single average.
    plasticity_engine_check_averages(Averages0),
    % Move each construct's running average toward its current activity.
    maplist(plasticity_engine_average_one(Activations, SmoothingFactor), Averages0, Averages).

% plasticity_engine_scale_interface(+Averages, +Target, +ScalingRate, +Interface0, -Interface): scale one edge.
plasticity_engine_scale_interface(Averages, Target, ScalingRate,
                                  interface(From, To, Weight0, Delay, Kind),
                                  interface(From, To, Weight, Delay, Kind)) :-
    % Only a transmissive interface is scaled; a computational one keeps its weight.
    % (The kinds were already judged by the shared refusal perimeter before this predicate runs.)
    (  Kind == transmissive
    -> % Read the receiving region's running average, refusing a ghost aloud.
       plasticity_engine_average_lookup(Averages, To, Average),
       % The raw factor grows a quiet region's inputs and shrinks a loud one's.
       RawFactor is 1 + ScalingRate * (Target - Average),
       % The factor floors at zero: a weight can be silenced but never sign-flipped.
       Factor is max(0, RawFactor),
       % Scaling is multiplicative, as synaptic scaling is.
       Weight is Weight0 * Factor
    ;  % A computational interface is untouched by the bound.
       Weight = Weight0
    ).

% plasticity_engine_scaling_step(+Interfaces0, +Averages, +Target, +ScalingRate, -Interfaces): the slow bound.
plasticity_engine_scaling_step(Interfaces0, Averages, Target, ScalingRate, Interfaces) :-
    % Refuse a target no region could defend and a rate that would overcorrect.
    plasticity_engine_check_activity_target(Target),
    plasticity_engine_check_scaling_rate(ScalingRate),
    % Refuse every malformed interface, unknown kind, and duplicate before touching a weight.
    maplist(plasticity_engine_check_interface, Interfaces0),
    plasticity_engine_transmissive_keys(Interfaces0, Keys),
    plasticity_engine_check_no_duplicate(Keys, plasticity_engine_duplicate_interface),
    % Refuse a duplicate average key before reading a single average.
    plasticity_engine_check_averages(Averages),
    % Scale every region's incoming transmissive weights toward its activity target.
    maplist(plasticity_engine_scale_interface(Averages, Target, ScalingRate),
            Interfaces0, Interfaces).

% plasticity_engine_step(+Interfaces0, +Activations, +Bus, +LearningRate, -Interfaces): learn for one tick.
plasticity_engine_step(Interfaces0, Activations, Bus, LearningRate, Interfaces) :-
    % Read the current dopamine level from the bus as the third factor of learning.
    neuromodulator_bus_level(Bus, dopamine, ThirdFactor),
    % Update every interface's weight by the three-factor rule.
    maplist(plasticity_engine_update_interface(Activations, ThirdFactor, LearningRate),
            Interfaces0, Interfaces).
