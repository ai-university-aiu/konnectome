% Load the neuromodulator_bus module under test from the library path.
:- use_module(library(neuromodulator_bus)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).

% Open the test block for the neuromodulator_bus pack.
:- begin_tests(neuromodulator_bus).

% An empty bus reads every modulator as zero.
test(empty_bus_reads_zero) :-
    % Make a fresh empty bus.
    neuromodulator_bus_new(Bus),
    % Any modulator reads as zero on it.
    neuromodulator_bus_level(Bus, dopamine, Level),
    % Confirm the level is zero.
    assertion(Level =:= 0).

% A broadcast level can be read back.
test(broadcast_then_read) :-
    % Start from an empty bus.
    neuromodulator_bus_new(Bus0),
    % Broadcast a dopamine level.
    neuromodulator_bus_broadcast(Bus0, dopamine, 0.7, Bus1),
    % Read it back.
    neuromodulator_bus_level(Bus1, dopamine, Level),
    % Confirm the read level matches the broadcast.
    assertion(Level =:= 0.7).

% A newer broadcast overwrites the older level for the same modulator.
test(newest_broadcast_wins) :-
    % Start from an empty bus.
    neuromodulator_bus_new(Bus0),
    % Broadcast an initial dopamine level.
    neuromodulator_bus_broadcast(Bus0, dopamine, 0.2, Bus1),
    % Broadcast a newer dopamine level.
    neuromodulator_bus_broadcast(Bus1, dopamine, 0.9, Bus2),
    % Read the level.
    neuromodulator_bus_level(Bus2, dopamine, Level),
    % Confirm the newest broadcast is the one read.
    assertion(Level =:= 0.9).

% Different modulators are held independently.
test(modulators_are_independent) :-
    % Start from an empty bus.
    neuromodulator_bus_new(Bus0),
    % Broadcast dopamine.
    neuromodulator_bus_broadcast(Bus0, dopamine, 0.5, Bus1),
    % Broadcast norepinephrine.
    neuromodulator_bus_broadcast(Bus1, norepinephrine, 0.3, Bus2),
    % Read dopamine.
    neuromodulator_bus_level(Bus2, dopamine, Dopamine),
    % Read norepinephrine.
    neuromodulator_bus_level(Bus2, norepinephrine, Norepinephrine),
    % Confirm both are held independently.
    assertion(Dopamine =:= 0.5),
    % Confirm the second modulator too.
    assertion(Norepinephrine =:= 0.3).

% A territory broadcast is read back at that territory's level.
test(a_territory_broadcast_is_read_at_its_territory) :-
    % Broadcast dopamine into the striatum territory alone.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast_territory(Bus0, dopamine, striatum, 0.7, Bus),
    % The striatum reads its own level.
    neuromodulator_bus_level_territory(Bus, dopamine, striatum, Level),
    % The territory level is the broadcast one.
    assertion(Level =:= 0.7).

% A territory without its own level falls back to the global broadcast, the diffuse field.
test(an_unset_territory_falls_back_to_the_global_level) :-
    % Broadcast dopamine globally only.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 0.4, Bus),
    % A territory with no level of its own reads the global one.
    neuromodulator_bus_level_territory(Bus, dopamine, cortex, Level),
    % The fallback is the global level.
    assertion(Level =:= 0.4).

% A territory level overrides the global level for that territory alone.
test(a_territory_level_overrides_the_global_level_locally) :-
    % Broadcast dopamine globally, then higher into the striatum.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 0.4, Bus1),
    neuromodulator_bus_broadcast_territory(Bus1, dopamine, striatum, 0.9, Bus),
    % The striatum reads its own level; the cortex reads the global one.
    neuromodulator_bus_level_territory(Bus, dopamine, striatum, Striatum),
    neuromodulator_bus_level_territory(Bus, dopamine, cortex, Cortex),
    % The override is local, the field elsewhere untouched.
    assertion(Striatum =:= 0.9),
    assertion(Cortex =:= 0.4).

% With neither a territory nor a global level, a territory reads silence.
test(an_empty_bus_reads_zero_in_every_territory) :-
    % An empty bus.
    neuromodulator_bus_new(Bus),
    % Any territory reads zero.
    neuromodulator_bus_level_territory(Bus, dopamine, striatum, Level),
    % Silence.
    assertion(Level =:= 0).

% A newer territory broadcast replaces the older one; the newest always wins.
test(a_newer_territory_broadcast_replaces_the_older) :-
    % Two broadcasts into the same territory.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast_territory(Bus0, dopamine, striatum, 0.2, Bus1),
    neuromodulator_bus_broadcast_territory(Bus1, dopamine, striatum, 0.8, Bus),
    % The territory reads the newest level.
    neuromodulator_bus_level_territory(Bus, dopamine, striatum, Level),
    % The newest broadcast won.
    assertion(Level =:= 0.8).

% A territory broadcast never disturbs the global level, and the global read never sees territories.
test(a_territory_broadcast_leaves_the_global_level_untouched) :-
    % A global level, then a different territory level.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 0.4, Bus1),
    neuromodulator_bus_broadcast_territory(Bus1, dopamine, striatum, 0.9, Bus),
    % The global read still returns the global broadcast.
    neuromodulator_bus_level(Bus, dopamine, Global),
    % The diffuse field is what it was.
    assertion(Global =:= 0.4).

% REVIEW PIN: an unbound modulator is refused as uninstantiated, never silently bound to a bus entry.
test(an_unbound_modulator_is_refused_at_the_global_read, error(instantiation_error)) :-
    % A variable modulator must throw, not invent an answer.
    neuromodulator_bus_new(Bus),
    neuromodulator_bus_level(Bus, _, _).

% REVIEW PIN: the territory read refuses the unbound modulator with the same voice.
test(an_unbound_modulator_is_refused_at_the_territory_read, error(instantiation_error)) :-
    % A variable modulator must throw here too.
    neuromodulator_bus_new(Bus),
    neuromodulator_bus_level_territory(Bus, _, striatum, _).

% REVIEW PIN: a compound modulator name is refused by name - the two key shapes can never collide.
test(a_compound_modulator_is_refused_by_name, error(domain_error(neuromodulator_bus_modulator, territory(dopamine, striatum)))) :-
    % A territory-shaped term posing as a modulator must throw, never alias a territory entry.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, territory(dopamine, striatum), 0.1, _).

% REVIEW PIN: an unbound territory is refused as uninstantiated at the territory broadcast.
test(an_unbound_territory_is_refused_at_the_territory_broadcast, error(instantiation_error)) :-
    % A variable territory must throw.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast_territory(Bus0, dopamine, _, 0.5, _).

% A fresh bus operates online: the default is today's behaviour, no broadcast needed.
test(a_fresh_bus_operates_online) :-
    % An empty bus, on which no state was ever broadcast.
    neuromodulator_bus_new(Bus),
    % Read the global operating state.
    neuromodulator_bus_operating_state(Bus, State),
    % The default is online - the waking state the whole build has always run in.
    assertion(State == online).

% A broadcast offline state is read back by every subscriber.
test(a_broadcast_offline_state_is_read_back) :-
    % Broadcast the offline state onto the bus.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast_operating_state(Bus0, offline, Bus),
    % Read the state back.
    neuromodulator_bus_operating_state(Bus, State),
    % The announcement arrived.
    assertion(State == offline).

% The state snaps back: a newer online broadcast replaces the older offline one.
test(a_newer_state_broadcast_replaces_the_older) :-
    % Throw the switch to offline and then back to online.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast_operating_state(Bus0, offline, Bus1),
    neuromodulator_bus_broadcast_operating_state(Bus1, online, Bus),
    % Read the state.
    neuromodulator_bus_operating_state(Bus, State),
    % The newest broadcast won, as it does for every level on this bus.
    assertion(State == online).

% REVIEW PIN: there is no halfway - a state that is neither online nor offline is refused by name.
test(a_halfway_state_is_refused_by_name, error(domain_error(neuromodulator_bus_operating_state, drowsy))) :-
    % The flip-flop spends no time between its two positions; a third value must throw.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast_operating_state(Bus0, drowsy, _).

% REVIEW PIN: an unbound state is refused as uninstantiated, never under a wrong naming a variable.
test(an_unbound_state_is_refused_at_the_broadcast, error(instantiation_error)) :-
    % A variable state must throw before any judgement pretends to name it.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast_operating_state(Bus0, _, _).

% A state broadcast never disturbs the modulator levels beside it.
test(a_state_broadcast_leaves_modulator_levels_untouched) :-
    % A dopamine level, then a state broadcast on the same bus.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, dopamine, 0.4, Bus1),
    neuromodulator_bus_broadcast_territory(Bus1, dopamine, striatum, 0.9, Bus2),
    neuromodulator_bus_broadcast_operating_state(Bus2, offline, Bus),
    % The global and territory levels read exactly as before.
    neuromodulator_bus_level(Bus, dopamine, Global),
    neuromodulator_bus_level_territory(Bus, dopamine, striatum, Striatum),
    % The chemical field is untouched by the state announcement.
    assertion(Global =:= 0.4),
    assertion(Striatum =:= 0.9).

% A modulator broadcast never disturbs the operating state beside it.
test(a_modulator_broadcast_leaves_the_operating_state_untouched) :-
    % A state broadcast, then modulator broadcasts on the same bus.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast_operating_state(Bus0, offline, Bus1),
    neuromodulator_bus_broadcast(Bus1, dopamine, 0.4, Bus2),
    neuromodulator_bus_broadcast_territory(Bus2, dopamine, striatum, 0.9, Bus),
    % The state still reads offline.
    neuromodulator_bus_operating_state(Bus, State),
    % The announcement outlived the chemical traffic.
    assertion(State == offline).

% REVIEW PIN: a state-shaped term posing as a modulator is refused - the third key shape cannot alias.
test(a_state_shaped_term_is_refused_as_a_modulator, error(domain_error(neuromodulator_bus_modulator, global(operating_state)))) :-
    % The state's own key shape must throw at the modulator broadcast, never collide in silence.
    neuromodulator_bus_new(Bus0),
    neuromodulator_bus_broadcast(Bus0, global(operating_state), 0.1, _).

% REVIEW PIN: an unbound bus is refused at the state read, never silently bound by the lookup.
test(an_unbound_bus_is_refused_at_the_state_read, error(instantiation_error)) :-
    % A variable bus must throw; a lookup that invented a bus would invent a state with it.
    neuromodulator_bus_operating_state(_, _).

% Close the test block for the neuromodulator_bus pack.
:- end_tests(neuromodulator_bus).
