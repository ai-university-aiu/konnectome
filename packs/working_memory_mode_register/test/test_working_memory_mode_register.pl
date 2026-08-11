% Load the working_memory_mode_register module under test from the library path.
:- use_module(library(working_memory_mode_register)).
% Load slice 39's formalism, so the register can be checked THROUGH the shared checker.
:- use_module(library(mode_register)).
% Load slice 46's master register, so the downward assignment can be driven end to end.
:- use_module(library(master_register)).
% Load slice 41's mode-throw channel, so what reaches the bus can be read back off it.
:- use_module(library(neuromodulator_bus)).
% Load the board this is a register OF, so the singleton claim can be checked against its own pack.
:- use_module(library(working_memory_blackboard)).
% Load the Prolog Unit (PLUnit) testing framework.
:- use_module(library(plunit)).
% Load list utilities used for membership and ordering assertions.
:- use_module(library(lists), [memberchk/2, nth0/3]).

% Open the test block for the working_memory_mode_register pack.
:- begin_tests(working_memory_mode_register).

% ---------------------------------------------------------------------------
% THE CHAPTER'S FOUR ENTRIES, IN THE CHAPTER'S OWN ORDER
% ---------------------------------------------------------------------------

% The register holds four modes, which is Entry 16's own count.
test(register_holds_the_chapters_four_modes) :-
    % Read the declared size.
    working_memory_mode_register_size(Size),
    % Confirm it is four.
    assertion(Size =:= 4).

% The four formal names are the chapter's four, in the chapter's own order.
test(the_four_names_are_the_chapters_own_in_order) :-
    % Read the roster.
    working_memory_mode_register_modes(Names),
    % Confirm the order is the chapter's, entry by entry, rather than merely the same set.
    assertion(Names == [robust_maintenance, gated_updating, erased_idle, ungoverned_flicker]).

% Every entry carries the chapter's coined name, always prefixed "the", in the three-field shape.
test(every_entry_carries_the_corpus_coined_name) :-
    % Read the register block.
    working_memory_mode_register_entries(Entries),
    % Confirm each coined name is the one the chapter prints.
    assertion(memberchk(mode_entry(robust_maintenance, 'The Held Chalk', _), Entries)),
    assertion(memberchk(mode_entry(gated_updating, 'The Fresh Slate', _), Entries)),
    assertion(memberchk(mode_entry(erased_idle, 'The Wiped Board', _), Entries)),
    assertion(memberchk(mode_entry(ungoverned_flicker, 'The Doodling Board', _), Entries)).

% Every entry carries exactly three fields, which is the formalism's rule since slice 39.
test(every_entry_has_exactly_three_fields) :-
    % Read the register block.
    working_memory_mode_register_entries(Entries),
    % Confirm no entry has grown a fourth field.
    forall(member(Entry, Entries),
           assertion(Entry = mode_entry(_Formal, _Coined, _Gloss))).

% ---------------------------------------------------------------------------
% THE AUTOMATON IS JUDGED BY THE SHARED CHECKER, NOT BY THIS PACK
% ---------------------------------------------------------------------------

% The whole automaton passes slice 39's checker, which is what makes this a register rather than a list.
test(the_automaton_passes_the_shared_checker) :-
    % Build the automaton; the constructor judges every block on the way out.
    working_memory_mode_register_automaton(Automaton),
    % Judge it again explicitly, so the check is visible in the suite rather than implied.
    mode_register_check(Automaton).

% The register block read back through the shared reader is the same block this pack declares.
test(the_shared_reader_sees_this_packs_register) :-
    % Build the automaton.
    working_memory_mode_register_automaton(Automaton),
    % Read its modes through the shared reader.
    mode_register_modes(Automaton, ThroughShared),
    % Read them through this pack.
    working_memory_mode_register_modes(Direct),
    % Confirm the two agree, so the pack cannot drift out from under the formalism.
    assertion(ThroughShared == Direct).

% ---------------------------------------------------------------------------
% THE PER-MODE TRANSFER FUNCTIONS
% ---------------------------------------------------------------------------

% Each mode's rule is the two-field posture read off the chapter's per-mode prose.
test(each_mode_carries_the_chapters_posture) :-
    % Robust Maintenance holds what is written and admits nothing.
    working_memory_mode_register_transfer(robust_maintenance, Robust),
    assertion(Robust == wm_posture(held, refused)),
    % Gated Updating holds what is written and runs its gate.
    working_memory_mode_register_transfer(gated_updating, Gated),
    assertion(Gated == wm_posture(held, gated)),
    % Erased Idle carries nothing at all.
    working_memory_mode_register_transfer(erased_idle, Erased),
    assertion(Erased == wm_posture(wiped, refused)),
    % Ungoverned Flicker holds what arrives and has no gate deciding it.
    working_memory_mode_register_transfer(ungoverned_flicker, Flicker),
    assertion(Flicker == wm_posture(held, ungoverned)).

% REFUSED AND UNGOVERNED ARE DIFFERENT FACTS AND NEVER SHARE AN ANSWER. A gate held shut and no gate
% at all are the chapter's two different claims, and a register that collapsed them would say the
% dream board is a well-maintained board.
test(a_shut_gate_and_an_absent_gate_are_different_answers) :-
    % Read the two postures whose surfaces agree.
    working_memory_mode_register_transfer(robust_maintenance, wm_posture(_, RobustGate)),
    working_memory_mode_register_transfer(ungoverned_flicker, wm_posture(_, FlickerGate)),
    % Both hold their surface, so only the admission field distinguishes them - and it must.
    assertion(RobustGate \== FlickerGate).

% NO CONSTANT IS RESTATED HERE. The chapter's numbers live one pack down, and a register that carried
% one would be a second place for it to drift.
test(the_register_restates_no_blackboard_constant) :-
    % Read every rule the register holds.
    working_memory_mode_register_automaton(Automaton),
    mode_register_entries(Automaton, Entries),
    % Confirm no entry's gloss or rule is a number by checking the transfer block holds only postures.
    forall(member(mode_entry(Formal, _, _), Entries),
           (   working_memory_mode_register_transfer(Formal, Rule),
               assertion(Rule = wm_posture(_Surface, _Admission))
           )).

% A rule cannot be read for a mode this register does not declare, and the refusal comes from the
% shared checker rather than from this pack.
test(a_mode_the_register_does_not_hold_is_refused,
     throws(error(existence_error(mode_entry, sleepwalking), _))) :-
    % A mode nobody declared has no rule, and saying so is not the same as having no rule.
    working_memory_mode_register_transfer(sleepwalking, _Rule).

% An unbound mode key is refused rather than bound to whichever mode is declared first.
test(an_unbound_mode_key_is_refused,
     throws(error(instantiation_error, _))) :-
    % A hole would otherwise be answered with Robust Maintenance's rule, confidently and wrongly.
    working_memory_mode_register_transfer(_Hole, _Rule).

% ---------------------------------------------------------------------------
% THE TRANSITION TABLE, AND OBSERVATION-14
% ---------------------------------------------------------------------------

% The waking cycle is the board's own, under the agency the chapter names.
test(the_waking_cycle_is_self_selected) :-
    % Read the table.
    working_memory_mode_register_transitions(Transitions),
    % Both edges of the cycle are declared, and both under the board's own agency.
    assertion(memberchk(transition(_, robust_maintenance, gated_updating, _, self_selected), Transitions)),
    assertion(memberchk(transition(_, gated_updating, robust_maintenance, _, self_selected), Transitions)).

% The sleep chain is thrown from above, and it is a CHAIN rather than two independent edges.
test(the_sleep_transition_is_a_chain_and_is_thrown) :-
    % Read the table.
    working_memory_mode_register_transitions(Transitions),
    % Each waking mode goes to Erased Idle, never straight to the flicker.
    assertion(memberchk(transition(_, robust_maintenance, erased_idle, _, thrown_from_above), Transitions)),
    assertion(memberchk(transition(_, gated_updating, erased_idle, _, thrown_from_above), Transitions)),
    % And Erased Idle is where the second link starts, which is the chapter's own ordering.
    assertion(memberchk(transition(_, erased_idle, ungoverned_flicker, _, thrown_from_above), Transitions)),
    % THE EDGE THE CHAIN DOES NOT LICENSE IS ABSENT: waking never goes straight to the dream board.
    assertion(\+ memberchk(transition(_, robust_maintenance, ungoverned_flicker, _, _), Transitions)),
    assertion(\+ memberchk(transition(_, gated_updating, ungoverned_flicker, _, _), Transitions)).

% OBSERVATION-14 ASSERTED AS SOMETHING THAT PASSES. The chapter's acute-stress row names no
% destination, so it is not in this table, and the self-loop a builder would reach for is not either.
% This test exists so the next reader MEETS the refusal rather than skimming a paragraph about it.
test(the_acute_stress_row_is_not_transcribed_as_a_self_loop) :-
    % Read the table.
    working_memory_mode_register_transitions(Transitions),
    % Read the roster.
    working_memory_mode_register_modes(Names),
    % NO MODE HAS AN EDGE TO ITSELF. A self-loop would make the departure lookup answer "stress sends
    % you to the mode you are in", which is a confident answer to a question whose true answer is that
    % stress sends the board nowhere and makes it worse where it stands.
    forall(member(Mode, Names),
           assertion(\+ memberchk(transition(_, Mode, Mode, _, _), Transitions))),
    % And no row carries the trigger, under any shape.
    assertion(\+ memberchk(transition(acute_stress, _, _, _, _), Transitions)).

% Two agencies really do write rows into one table, which is why slice 41 keyed the departure lookup
% on agency. Robust Maintenance leaves under both, to two different places.
test(one_mode_departs_differently_under_two_agencies) :-
    % Build the automaton, which stands in Robust Maintenance.
    working_memory_mode_register_automaton(Automaton),
    % The board's own agency takes it to updating.
    mode_register_departure(Automaton, self_selected, SelfDestination),
    assertion(SelfDestination == gated_updating),
    % A throw from above takes it to erasure - the same departure mode, a different answer.
    mode_register_departure(Automaton, thrown_from_above, ThrownDestination),
    assertion(ThrownDestination == erased_idle).

% ---------------------------------------------------------------------------
% THE FAULT BLOCK
% ---------------------------------------------------------------------------

% The chapter's two boundary signatures are watched and neither is admitted as a mode.
test(both_boundary_signatures_are_watched_and_neither_is_a_mode) :-
    % Read the fault block.
    working_memory_mode_register_faults(Faults),
    % Both signatures are present as faults.
    assertion(memberchk(fault(gate_stuck_shut, perseveration, _), Faults)),
    assertion(memberchk(fault(gate_stuck_open, distractibility, _), Faults)),
    % And neither has crept into the register, which is slice 42's rule holding one chapter later.
    working_memory_mode_register_modes(Names),
    assertion(\+ memberchk(perseveration, Names)),
    assertion(\+ memberchk(distractibility, Names)).

% Both faults carry the same three watchdogs, because the chapter offers the list to both together.
test(both_faults_carry_the_chapters_three_watchdogs) :-
    % Read the fault block.
    working_memory_mode_register_faults(Faults),
    % Read each row's watchdog list.
    memberchk(fault(gate_stuck_shut, _, ShutWatchdogs), Faults),
    memberchk(fault(gate_stuck_open, _, OpenWatchdogs), Faults),
    % The chapter's own three, in its own order.
    assertion(ShutWatchdogs == [inverted_u_self_limiting_envelope,
                                noradrenergic_network_reset,
                                parietal_normalisation]),
    % And the same list for both, rather than one invented apiece.
    assertion(OpenWatchdogs == ShutWatchdogs).

% ---------------------------------------------------------------------------
% DECISION-9 - THE FIRST REAL DOWNWARD ASSIGNMENT
% ---------------------------------------------------------------------------

% THE TABLE THAT WAS EMPTY AT SLICE 46 NOW HAS ROWS. This is the proof that slice 46's table was empty
% for the reason slice 46 gave: the obstacle was multiplicity, and the blackboard is a singleton.
test(the_downward_assignment_table_now_has_rows) :-
    % Read what slow-wave sleep assigns.
    master_register_downward_assignment(global_state(offline, slow_wave_sleep), Assignments),
    % It assigns the board its erased mode, by name.
    assertion(memberchk(assign(working_memory_blackboard, erased_idle), Assignments)).

% Each of the two sleep states the chapter speaks about assigns its own mode.
test(each_spoken_sleep_state_assigns_its_own_mode) :-
    % Slow-wave sleep wipes the board.
    working_memory_mode_register_assigned_mode(global_state(offline, slow_wave_sleep), Deep),
    assertion(Deep == erased_idle),
    % REM leaves it ungoverned - a different mode, not a stronger version of the same one.
    working_memory_mode_register_assigned_mode(global_state(offline, rapid_eye_movement), Rem),
    assertion(Rem == ungoverned_flicker).

% NO WAKING STATE ASSIGNS ANYTHING, AND THAT IS THE REFUSAL RATHER THAN A GAP. The chapter gives the
% waking transition to the board's own agency, so a downward row for a waking state would overwrite a
% choice the corpus says is not the global state's to make.
test(no_waking_state_assigns_the_board_a_mode) :-
    % The reserved answer meaning nothing is throwing.
    working_memory_mode_register_self_governed(Silence),
    % Every one of the master register's four waking sub-modes leaves the board alone.
    master_register_sub_modes(online, WakingSubModes),
    forall(member(SubMode, WakingSubModes),
           (   working_memory_mode_register_assigned_mode(global_state(online, SubMode), Mode),
               assertion(Mode == Silence)
           )).

% THE TWO SLEEP SUB-MODES THE CHAPTER IS SILENT ABOUT GET NO ROW, and the silence reads back as
% silence rather than as a mode.
test(the_unspoken_sleep_states_are_answered_with_silence) :-
    % The reserved answer.
    working_memory_mode_register_self_governed(Silence),
    % Sleep onset is a state the master register holds and this chapter never mentions.
    working_memory_mode_register_assigned_mode(global_state(offline, sleep_onset), Onset),
    assertion(Onset == Silence),
    % So is spindled light sleep.
    working_memory_mode_register_assigned_mode(global_state(offline, spindled_light_sleep), Spindled),
    assertion(Spindled == Silence).

% A STATE NOBODY HOLDS AND A STATE THAT ASSIGNS NOTHING ARE DIFFERENT FACTS. Slice 49 paid to learn
% this one grain down and it is enforced here too: a foreign state is refused aloud, never answered
% with the silence a real-but-unspoken state gets.
test(a_state_the_register_does_not_hold_is_refused_rather_than_answered,
     throws(error(domain_error(master_register_sub_mode_of_pole(offline), daydreaming), _))) :-
    % A sub-mode the master register never declared is not a state whose row is missing.
    working_memory_mode_register_assigned_mode(global_state(offline, daydreaming), _Mode).

% ---------------------------------------------------------------------------
% THE ASSIGNMENT REALLY REACHES THE BUS
% ---------------------------------------------------------------------------

% END TO END, THROUGH THE MECHANISM SLICE 46 BUILT AND PROVED AGAINST A FIXTURE: announcing deep sleep
% and applying its assignment leaves the board's mode standing on the mode-throw channel.
test(announcing_deep_sleep_throws_the_erased_mode_at_the_board) :-
    % A fresh bus.
    neuromodulator_bus_new(Bus0),
    % Announce the state through the register that judges it against the roster.
    master_register_announce(Bus0, global_state(offline, slow_wave_sleep), Bus1),
    % Apply its downward assignment, which walks the table onto the throw channel.
    master_register_assign_downward(Bus1, global_state(offline, slow_wave_sleep), Bus),
    % Read the board's mode back off the bus through its own register.
    working_memory_mode_register_mode_on_bus(Bus, Mode),
    % The board is standing in the mode the chapter says deep sleep puts it in.
    assertion(Mode == erased_idle).

% The same route, for the other spoken state.
test(announcing_rem_throws_the_ungoverned_mode_at_the_board) :-
    % A fresh bus.
    neuromodulator_bus_new(Bus0),
    % Apply the REM assignment.
    master_register_assign_downward(Bus0, global_state(offline, rapid_eye_movement), Bus),
    % Read the board's mode back.
    working_memory_mode_register_mode_on_bus(Bus, Mode),
    % The gate is gone, and the surface is not wiped.
    assertion(Mode == ungoverned_flicker),
    working_memory_mode_register_transfer(Mode, wm_posture(Surface, Admission)),
    assertion(Surface == held),
    assertion(Admission == ungoverned).

% A WAKING ANNOUNCEMENT LEAVES THE CHANNEL SILENT, so the board goes on governing itself.
test(a_waking_announcement_leaves_the_board_self_governed) :-
    % A fresh bus.
    neuromodulator_bus_new(Bus0),
    % Apply waking's downward assignment, which has no row for the board.
    master_register_assign_downward(Bus0, global_state(online, alert_task_engaged), Bus),
    % Read the board's mode back.
    working_memory_mode_register_mode_on_bus(Bus, Mode),
    % The answer is the reserved silence, never a mode.
    working_memory_mode_register_self_governed(Silence),
    assertion(Mode == Silence).

% A SILENT BUS IS NEVER READ AS A DEFAULT MODE. This is the default-drift lens, asserted rather than
% argued: nothing has announced anything at all, and the answer is still not a mode.
test(an_untouched_bus_answers_self_governed_and_not_a_mode) :-
    % A bus nobody has written to.
    neuromodulator_bus_new(Bus),
    % Read the board's mode.
    working_memory_mode_register_mode_on_bus(Bus, Mode),
    % The reserved silence, and specifically NOT the automaton's starting position.
    working_memory_mode_register_self_governed(Silence),
    assertion(Mode == Silence),
    assertion(Mode \== robust_maintenance).

% THE AUTOMATON'S STARTING POSITION IS NOT A DEFAULT, AND NOTHING READS IT AS ONE. The current-mode
% slot exists because the formalism refuses a term without one; the mode a caller GETS comes off the
% bus. This test pins the two apart so a later slice cannot quietly promote the slot into a default.
test(the_starting_position_is_not_what_a_caller_gets) :-
    % The automaton stands in the chapter's first entry.
    working_memory_mode_register_automaton(Automaton),
    mode_register_current(Automaton, Standing),
    assertion(Standing == robust_maintenance),
    % A caller reading an untouched bus does not get it.
    neuromodulator_bus_new(Bus),
    working_memory_mode_register_mode_on_bus(Bus, FromBus),
    assertion(FromBus \== Standing).

% A THROW NAMING A MODE THIS BOARD DOES NOT HAVE IS REFUSED ALOUD rather than passed on. The channel
% guarantees a well-formed atom and only this register knows which atoms are its modes.
test(a_throw_of_a_foreign_mode_is_refused,
     throws(error(existence_error(working_memory_mode_register_mode, spindling), _))) :-
    % A fresh bus.
    neuromodulator_bus_new(Bus0),
    % Something throws a mode that belongs to a different construct's register entirely.
    neuromodulator_bus_throw_mode(Bus0, working_memory_blackboard, spindling, Bus),
    % Reading it back through this register refuses it by name.
    working_memory_mode_register_mode_on_bus(Bus, _Mode).

% ---------------------------------------------------------------------------
% THE SINGLETON CLAIM, WHICH IS DECISION-9'S WHOLE WARRANT
% ---------------------------------------------------------------------------

% The construct this register addresses is the blackboard pack's own name, so the address a reader
% checks and the pack a reader opens are the same word.
test(the_addressed_construct_is_the_blackboard_pack) :-
    % Read the addressed name.
    working_memory_mode_register_construct(Name),
    % It is the pack that builds the surface.
    assertion(Name == working_memory_blackboard),
    % And that pack really does build one surface with the corpus's capacity on it, which is the
    % singleton claim's checkable half: one shared surface, not one per reader.
    working_memory_blackboard_capacity(Capacity),
    assertion(Capacity =:= 4).

% EVERY ROW IN THE WHOLE DOWNWARD ASSIGNMENT TABLE ADDRESSES THIS ONE SINGLETON. If a later slice adds
% a row aimed at a construct KIND, this test is where slice 46's objection comes back to be argued
% again rather than being inherited by accident.
test(every_row_in_the_table_addresses_a_declared_singleton) :-
    % The one name this build has so far argued is a singleton.
    working_memory_mode_register_construct(Singleton),
    % Walk every state the master register holds and every row each one assigns.
    master_register_entries(Entries),
    forall(member(mode_entry(GlobalState, _Formal, _Does), Entries),
           (   master_register_downward_assignment(GlobalState, Assignments),
               forall(member(assign(Addressed, _Mode), Assignments),
                      assertion(Addressed == Singleton))
           )).

% EVERY MODE THE TABLE THROWS IS A MODE THIS REGISTER DECLARES. A row assigning a mode the board does
% not have would publish an instruction nothing could obey, and it would do it in silence.
test(every_mode_the_table_throws_is_a_mode_this_register_holds) :-
    % Read the roster.
    working_memory_mode_register_modes(Names),
    % Walk every state's rows.
    master_register_entries(Entries),
    forall(member(mode_entry(GlobalState, _Formal, _Does), Entries),
           (   master_register_downward_assignment(GlobalState, Assignments),
               forall(member(assign(_Addressed, Mode), Assignments),
                      assertion(memberchk(Mode, Names)))
           )).

% Close the test block for the working_memory_mode_register pack.
:- end_tests(working_memory_mode_register).
