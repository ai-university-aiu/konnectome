% Declare this file as the 'perturbation_interface' module and list the predicates it exports.
:- module(perturbation_interface, [
    % perturbation_interface_lesion/3: silence a construct by setting its activation to zero.
    perturbation_interface_lesion/3,
    % perturbation_interface_cut/4: cut a connection by removing its interface.
    perturbation_interface_cut/4,
    % perturbation_interface_shift/4: shift a neuromodulator level, as a drug would.
    perturbation_interface_shift/4
]).

% Import exclude for removing a construct's value and for cutting interfaces.
:- use_module(library(apply), [exclude/3]).
% Reuse the neuromodulatory bus to shift a modulator level.
:- use_module(library(neuromodulator_bus), [neuromodulator_bus_broadcast/4]).

% The perturbation interface is Architecture Component 10: it lets an experimenter administer a
% simulated disease or drug by lesioning a construct (silencing it), cutting an interface (removing a
% connection), or shifting a neuromodulator level (for example, depleting dopamine to model
% Parkinson's disease). It changes nothing on its own; it only injects an experimenter's intervention.

% perturbation_interface_is_named(+Name, +Pair): the state pair belongs to this construct.
perturbation_interface_is_named(Name, Name-_Value).

% perturbation_interface_lesion(+State0, +ConstructName, -State): silence a construct (set it to zero).
perturbation_interface_lesion(State0, ConstructName, State) :-
    % Remove the construct's current value from the state.
    exclude(perturbation_interface_is_named(ConstructName), State0, Without),
    % Reinsert it at zero activation and keep the state canonical.
    keysort([ConstructName-0 | Without], State).

% perturbation_interface_is_edge(+From, +To, +Interface): the interface runs from From to To.
perturbation_interface_is_edge(From, To, interface(From, To, _Weight, _Delay, _Kind)).

% perturbation_interface_cut(+Interfaces0, +From, +To, -Interfaces): cut the connection from From to To.
perturbation_interface_cut(Interfaces0, From, To, Interfaces) :-
    % Remove every interface running from From to To.
    exclude(perturbation_interface_is_edge(From, To), Interfaces0, Interfaces).

% perturbation_interface_shift(+Bus0, +Modulator, +Level, -Bus): set a neuromodulator level directly.
perturbation_interface_shift(Bus0, Modulator, Level, Bus) :-
    % Broadcast the new level onto the bus, as administering a drug would.
    neuromodulator_bus_broadcast(Bus0, Modulator, Level, Bus).
