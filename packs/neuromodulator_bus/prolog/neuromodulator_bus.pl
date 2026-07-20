% Declare this file as the 'neuromodulator_bus' module and list the predicates it exports.
:- module(neuromodulator_bus, [
    % neuromodulator_bus_new/1: an empty bus, every modulator level at zero.
    neuromodulator_bus_new/1,
    % neuromodulator_bus_broadcast/4: a source writes a modulator's level for everyone to read.
    neuromodulator_bus_broadcast/4,
    % neuromodulator_bus_level/3: read one modulator's current level.
    neuromodulator_bus_level/3
]).

% Import membership for reading a level from the bus.
:- use_module(library(lists), [memberchk/2]).
% Import exclude for replacing a modulator's old level when a new one is broadcast.
:- use_module(library(apply), [exclude/3]).

% The neuromodulatory bus is Architecture Component 4: a broadcast channel of global brain-chemical
% levels (dopamine, norepinephrine, and the rest). It is the one place the architecture permits a
% global value: source nuclei write it, and every construct's update and learning rule read it.
% The bus is an ordered list of Modulator-Level pairs; an absent modulator reads as level zero.

% neuromodulator_bus_new(-Bus): an empty bus, on which every modulator reads as zero.
neuromodulator_bus_new([]).

% neuromodulator_bus_level(+Bus, +Modulator, -Level): read a modulator's current broadcast level.
neuromodulator_bus_level(Bus, Modulator, Level) :-
    % Return the stored level if present, otherwise zero.
    ( memberchk(Modulator-Found, Bus) -> Level = Found ; Level = 0 ).

% neuromodulator_bus_matches(+Modulator, +Pair): the pair carries this modulator's level.
neuromodulator_bus_matches(Modulator, Modulator-_Level).

% neuromodulator_bus_broadcast(+Bus0, +Modulator, +Level, -Bus): a source writes a modulator's level.
neuromodulator_bus_broadcast(Bus0, Modulator, Level, Bus) :-
    % Drop any existing level for this modulator so the newest broadcast wins.
    exclude(neuromodulator_bus_matches(Modulator), Bus0, Without),
    % Add the new level and keep the bus in a canonical sorted order.
    keysort([Modulator-Level|Without], Bus).
