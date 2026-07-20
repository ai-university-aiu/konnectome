% Declare this file as the 'plasticity_engine' module and list the predicates it exports.
:- module(plasticity_engine, [
    % plasticity_engine_weight_change/5: the three-factor weight change for one interface.
    plasticity_engine_weight_change/5,
    % plasticity_engine_step/5: apply the learning rule to every learnable interface for one tick.
    plasticity_engine_step/5
]).

% Import membership for reading activities, and maplist for updating every interface.
:- use_module(library(lists), [memberchk/2]).
% Import maplist for updating every interface together.
:- use_module(library(apply), [maplist/4]).
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

% plasticity_engine_step(+Interfaces0, +Activations, +Bus, +LearningRate, -Interfaces): learn for one tick.
plasticity_engine_step(Interfaces0, Activations, Bus, LearningRate, Interfaces) :-
    % Read the current dopamine level from the bus as the third factor of learning.
    neuromodulator_bus_level(Bus, dopamine, ThirdFactor),
    % Update every interface's weight by the three-factor rule.
    maplist(plasticity_engine_update_interface(Activations, ThirdFactor, LearningRate),
            Interfaces0, Interfaces).
