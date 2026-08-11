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

% ---------------------------------------------------------------------------
% THE MODE THROW (konnectome build slice 41)
% ---------------------------------------------------------------------------

% A channel nobody has written reads back the reserved silence name, never a mode and never a failure.
test(an_unwritten_throw_channel_reads_as_silence) :-
    % Make a fresh empty bus.
    neuromodulator_bus_new(Bus),
    % Read the throw standing at a construct kind nobody has addressed.
    neuromodulator_bus_thrown_mode(Bus, gate, Mode),
    % Silence has a name of its own, so a reader can never mistake it for an instruction.
    assertion(Mode == no_mode_thrown).

% A thrown mode can be read back by every construct of the kind it was thrown at.
test(throw_then_read) :-
    % Start from an empty bus.
    neuromodulator_bus_new(Bus0),
    % Throw a mode at a construct kind.
    neuromodulator_bus_throw_mode(Bus0, gate, closed, Bus1),
    % Read it back.
    neuromodulator_bus_thrown_mode(Bus1, gate, Mode),
    % The mode read is the mode thrown.
    assertion(Mode == closed).

% The newest throw replaces the older one, exactly as the newest level replaces the older level.
test(newest_throw_wins) :-
    % Start from an empty bus.
    neuromodulator_bus_new(Bus0),
    % Throw one mode.
    neuromodulator_bus_throw_mode(Bus0, gate, closed, Bus1),
    % Throw another at the same kind.
    neuromodulator_bus_throw_mode(Bus1, gate, open, Bus2),
    % Read the standing throw.
    neuromodulator_bus_thrown_mode(Bus2, gate, Mode),
    % Exactly one throw stands per kind, and it is the newest - so two sources cannot both be obeyed.
    assertion(Mode == open).

% A throw at one kind is invisible to every other kind: a broadcast is addressed, not universal.
test(a_throw_reaches_only_the_kind_it_names) :-
    % Start from an empty bus.
    neuromodulator_bus_new(Bus0),
    % Throw a mode at the gate kind.
    neuromodulator_bus_throw_mode(Bus0, gate, closed, Bus1),
    % Read the throw standing at a different kind.
    neuromodulator_bus_thrown_mode(Bus1, relay, Mode),
    % That kind hears silence, because nobody threw anything at it.
    assertion(Mode == no_mode_thrown).

% Withdrawing a throw returns the kind to its own self-selection.
test(release_returns_the_channel_to_silence) :-
    % Start from an empty bus.
    neuromodulator_bus_new(Bus0),
    % Throw a mode.
    neuromodulator_bus_throw_mode(Bus0, gate, closed, Bus1),
    % Withdraw it.
    neuromodulator_bus_release_mode_throw(Bus1, gate, Bus2),
    % Read the channel.
    neuromodulator_bus_thrown_mode(Bus2, gate, Mode),
    % It is silent again, so a command preempts while it stands and no longer.
    assertion(Mode == no_mode_thrown).

% Withdrawing a throw nobody made leaves the bus exactly as it was, rather than refusing.
test(releasing_an_unwritten_throw_is_harmless) :-
    % Start from an empty bus.
    neuromodulator_bus_new(Bus0),
    % Broadcast a level, so the bus is not empty.
    neuromodulator_bus_broadcast(Bus0, dopamine, 0.4, Bus1),
    % Withdraw a throw that was never made.
    neuromodulator_bus_release_mode_throw(Bus1, gate, Bus2),
    % Nothing else on the bus moved.
    assertion(Bus2 == Bus1).

% THE KEY-SHAPE ALIASING LENS: the throw's key is a FOURTH shape and cannot be reached by the other
% three, nor they by it. The throw is deliberately aimed at a kind SHARING ITS NAME with a modulator
% already on the bus, which is the arrangement that would expose a collision if one existed.
test(the_throw_key_cannot_alias_the_other_three_channels) :-
    % Start from an empty bus.
    neuromodulator_bus_new(Bus0),
    % A modulator level.
    neuromodulator_bus_broadcast(Bus0, dopamine, 0.7, Bus1),
    % A level in one territory.
    neuromodulator_bus_broadcast_territory(Bus1, dopamine, striatum, 0.2, Bus2),
    % The global operating state.
    neuromodulator_bus_broadcast_operating_state(Bus2, offline, Bus3),
    % And a mode thrown at a construct kind whose name is the modulator's own.
    neuromodulator_bus_throw_mode(Bus3, dopamine, closed, Bus4),
    % The modulator level is untouched by the throw that shares its name.
    neuromodulator_bus_level(Bus4, dopamine, Level),
    % And reads back exactly what was broadcast.
    assertion(Level =:= 0.7),
    % The territory level is untouched.
    neuromodulator_bus_level_territory(Bus4, dopamine, striatum, Local),
    % And reads back exactly what was broadcast there.
    assertion(Local =:= 0.2),
    % The operating state is untouched.
    neuromodulator_bus_operating_state(Bus4, State),
    % And still reads offline.
    assertion(State == offline),
    % And the throw reads back its own value, neither a level nor a state.
    neuromodulator_bus_thrown_mode(Bus4, dopamine, Mode),
    % Four channels, one bus, no collision.
    assertion(Mode == closed).

% The reserved silence name may not be THROWN, or a command would read back as no command at all.
test(throwing_the_reserved_silence_name_is_refused,
     error(domain_error(neuromodulator_bus_thrown_mode, no_mode_thrown))) :-
    % Start from an empty bus.
    neuromodulator_bus_new(Bus0),
    % Try to throw the name that means silence.
    neuromodulator_bus_throw_mode(Bus0, gate, no_mode_thrown, _Bus).

% A compound is refused as a thrown mode, so no key shape can be smuggled in as a command.
test(a_compound_thrown_mode_is_refused,
     error(domain_error(neuromodulator_bus_thrown_mode, mode_throw(gate)))) :-
    % Start from an empty bus.
    neuromodulator_bus_new(Bus0),
    % Try to throw the channel's own key shape as if it were a mode.
    neuromodulator_bus_throw_mode(Bus0, gate, mode_throw(gate), _Bus).

% An unbound thrown mode is refused before it can be written as a value nobody chose.
test(an_unbound_thrown_mode_is_refused, error(instantiation_error)) :-
    % Start from an empty bus.
    neuromodulator_bus_new(Bus0),
    % Try to throw a hole.
    neuromodulator_bus_throw_mode(Bus0, gate, _Hole, _Bus).

% An unbound construct kind is refused at the write, never bound into a key nobody addressed.
test(an_unbound_construct_kind_is_refused_at_the_throw, error(instantiation_error)) :-
    % Start from an empty bus.
    neuromodulator_bus_new(Bus0),
    % Try to throw at no kind at all.
    neuromodulator_bus_throw_mode(Bus0, _Hole, closed, _Bus).

% REVIEW PIN, the unbound-wrong-judgement lens: an unbound construct kind is refused at the READ too,
% because a lookup would otherwise bind it to whichever kind the bus happens to list first and hand
% back that kind's command to a caller who addressed nobody.
test(an_unbound_construct_kind_is_refused_at_the_throw_read, error(instantiation_error)) :-
    % Start from an empty bus.
    neuromodulator_bus_new(Bus0),
    % Write a throw, so a lookup would have something to bind an unbound kind to.
    neuromodulator_bus_throw_mode(Bus0, gate, closed, Bus1),
    % Try to read the throw standing at no kind at all.
    neuromodulator_bus_thrown_mode(Bus1, _Hole, _Mode).

% REVIEW PIN: an unbound bus is refused at the throw read, exactly as it is at the state read.
test(an_unbound_bus_is_refused_at_the_throw_read, error(instantiation_error)) :-
    % A variable bus must throw; a lookup that invented a bus would invent a command with it.
    neuromodulator_bus_thrown_mode(_, gate, _).

% THE ROSTER IS EXACTLY THE CORPUS'S SIX, IN CHAPTER 16'S OWN ORDER.
test(the_roster_is_the_corpus_six_in_order) :-
    % Collect every channel the roster carries, in declaration order.
    findall(Channel, neuromodulator_bus_channel(Channel), Channels),
    % Confirm the roster is Chapter 16's list, with norepinephrine carrying the noradrenaline channel.
    assertion(Channels == [norepinephrine, serotonin, acetylcholine, histamine, dopamine, orexin]).

% The roster carries six channels and not five, which is the corpus's own arithmetic: five plus orexin.
test(the_roster_carries_six_channels) :-
    % Count the roster.
    findall(Channel, neuromodulator_bus_channel(Channel), Channels),
    % Confirm the count is six.
    length(Channels, Count),
    % Confirm the corpus's own count.
    assertion(Count =:= 6).

% Every channel on the roster has exactly one role, one source and one cognitive tag.
test(every_channel_has_one_role_one_source_and_one_tag) :-
    % Walk the roster, which the first test has already proved non-empty.
    forall(neuromodulator_bus_channel(Channel),
           % Each of the three tables answers this channel exactly once.
           (   findall(Role, neuromodulator_bus_channel_role(Channel, Role), Roles),
               findall(Source, neuromodulator_bus_channel_source(Channel, Source), Sources),
               findall(Tag, neuromodulator_bus_channel_cognitive(Channel, Tag), Tags),
               length(Roles, 1),
               length(Sources, 1),
               length(Tags, 1)
           )).

% No table names a channel the roster does not carry, which is the other direction of the same check.
test(no_table_names_a_channel_the_roster_does_not_carry) :-
    % Every role row names a roster member.
    forall(neuromodulator_bus_channel_role(Channel, _Role), neuromodulator_bus_channel(Channel)),
    % Every source row names a roster member.
    forall(neuromodulator_bus_channel_source(SourceChannel, _Source), neuromodulator_bus_channel(SourceChannel)),
    % Every cognitive row names a roster member.
    forall(neuromodulator_bus_channel_cognitive(TagChannel, _Tag), neuromodulator_bus_channel(TagChannel)).

% The roles are the Layer 10 systems volume's own chapter subtitles.
test(the_roles_are_the_corpus_chapter_subtitles) :-
    % Dopamine is the Reward-Teaching Broadcast, chapter 31.
    neuromodulator_bus_channel_role(dopamine, Reward),
    % Norepinephrine carries chapter 32's Gain-and-Reset Broadcast.
    neuromodulator_bus_channel_role(norepinephrine, Gain),
    % Orexin is chapter 36's Sleep-Wake Stabiliser.
    neuromodulator_bus_channel_role(orexin, Stabiliser),
    % Confirm all three are the corpus's own words.
    assertion(Reward == reward_teaching_broadcast),
    % Confirm the second.
    assertion(Gain == gain_and_reset_broadcast),
    % Confirm the third.
    assertion(Stabiliser == sleep_wake_stabiliser).

% The corpus's COG and NON-COG tags are carried through unaltered: four cognitive, two not.
test(the_cognitive_tags_are_the_corpus_four_and_two) :-
    % Collect the channels the corpus tags cognitive.
    findall(Channel, neuromodulator_bus_channel_cognitive(Channel, cognitive), Cognitive),
    % Collect the two the corpus tags NON-COG.
    findall(Other, neuromodulator_bus_channel_cognitive(Other, non_cognitive), NonCognitive),
    % Confirm the cognitive four are the corpus's chapters 31 to 34.
    assertion(Cognitive == [norepinephrine, serotonin, acetylcholine, dopamine]),
    % Confirm the non-cognitive two are chapters 35 and 36.
    assertion(NonCognitive == [histamine, orexin]).

% DECISION-7, FIRST HALF: the corpus's own word resolves onto the roster's name.
test(the_corpus_name_resolves_onto_the_running_channel) :-
    % Resolve the corpus's spelling.
    neuromodulator_bus_channel_named(noradrenaline, Channel),
    % Confirm it lands on the channel the machine has broadcast since slice 19.
    assertion(Channel == norepinephrine).

% A roster name resolves to itself, so a caller may pass either word through one lookup.
test(a_roster_name_resolves_to_itself) :-
    % Resolve a name the roster already carries.
    neuromodulator_bus_channel_named(acetylcholine, Channel),
    % Confirm the resolution is the identity.
    assertion(Channel == acetylcholine).

% THE POINT OF THE RESOLUTION, PINNED: the corpus's word must never reach the bus as a second key.
% A caller who resolves first reads the level that is really there; a caller who did not would have
% been told, in silence, that a live channel was at zero.
test(the_corpus_name_reaches_the_level_the_running_channel_carries) :-
    % Start from an empty bus.
    neuromodulator_bus_new(Bus0),
    % Arousal broadcasts under konnectome's own name for the channel, as it has since slice 19.
    neuromodulator_bus_broadcast(Bus0, norepinephrine, 0.4, Bus1),
    % A caller written from the corpus resolves the corpus's word first.
    neuromodulator_bus_channel_named(noradrenaline, Channel),
    % Read the level under the resolved name.
    neuromodulator_bus_level(Bus1, Channel, Resolved),
    % Read the level the unresolved corpus word would have found.
    neuromodulator_bus_level(Bus1, noradrenaline, Unresolved),
    % Confirm the resolved read finds the level that is really there.
    assertion(Resolved =:= 0.4),
    % Confirm the unresolved read would have answered a plausible zero, which is why the lookup exists.
    assertion(Unresolved =:= 0).

% A name that is neither a roster name nor the corpus's own is refused aloud rather than resolved.
test(an_unknown_name_is_refused_at_the_resolution, error(domain_error(neuromodulator_bus_channel, _))) :-
    % Adrenaline is a real molecule and is not one of this bus's six channels.
    neuromodulator_bus_channel_named(adrenaline, _Channel).

% An unbound name is refused at the resolution, never bound to whichever channel is listed first.
test(an_unbound_name_is_refused_at_the_resolution, error(instantiation_error)) :-
    % A hole cannot be resolved; resolving it would invent a channel for a caller who named none.
    neuromodulator_bus_channel_named(_Hole, _Channel).

% The offered check accepts every roster member.
test(the_check_accepts_every_roster_member) :-
    % Every channel the roster carries passes its own check.
    forall(neuromodulator_bus_channel(Channel), neuromodulator_bus_check_channel(Channel)).

% The offered check refuses a name the roster does not carry, by the roster's own name.
test(the_check_refuses_a_name_the_roster_does_not_carry, error(domain_error(neuromodulator_bus_channel, _))) :-
    % stability_bias is a real, running bus key and is NOT a neuromodulator - see the test below.
    neuromodulator_bus_check_channel(stability_bias).

% THE FINDING THIS SLICE REFUSED TO ENFORCE, PINNED AS A TEST: THE KEYSPACE IS A NAMESPACE AND NOT A
% ROSTER. stabiliser publishes its stability bias under an atom key on this same channel shape, and a
% roster enforced on write would have refused a correct, running, tested caller.
test(a_non_channel_key_still_broadcasts_and_reads) :-
    % Start from an empty bus.
    neuromodulator_bus_new(Bus0),
    % Write the stabiliser's key, which is not on the roster and never was a neuromodulator.
    neuromodulator_bus_broadcast(Bus0, stability_bias, 7, Bus1),
    % Read it back.
    neuromodulator_bus_level(Bus1, stability_bias, Level),
    % Confirm the write and the read are exactly what they were before a roster existed.
    assertion(Level =:= 7).

% AND THE DECLARATION-ORDER LENS, ARRIVING AT CLAUSE SELECTION AS IT DID IN SLICE 45: a keyed read of
% the roster must be deterministic, not merely correct on its first answer.
test(a_keyed_roster_read_leaves_no_choice_point) :-
    % Read one channel's role and ask whether anything was left behind.
    neuromodulator_bus_channel_role(orexin, _Role),
    % Confirm the read was deterministic - a second answer would mean the table can be re-entered.
    deterministic(Deterministic),
    % Confirm it.
    assertion(Deterministic == true).

% A bare pole may not be announced on the widened channel, because the widened announcement promises
% a sub-mode as well, and a reader of the widened state would otherwise get a term of the wrong shape.
test(a_bare_pole_is_refused_as_a_widened_global_state,
     error(domain_error(neuromodulator_bus_global_state, online))) :-
    % A fresh bus.
    neuromodulator_bus_new(Bus0),
    % Announcing the pole alone on the widened channel must be refused by name.
    neuromodulator_bus_broadcast_global_state(Bus0, online, _Bus).

% Close the test block for the neuromodulator_bus pack.
:- end_tests(neuromodulator_bus).
